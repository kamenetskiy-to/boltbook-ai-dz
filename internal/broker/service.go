package broker

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"strings"
	"time"

	"boltbook-ai-dz/internal/boltbook"
	"boltbook-ai-dz/internal/core"
	"boltbook-ai-dz/internal/domain"
	"boltbook-ai-dz/internal/matching"
	"boltbook-ai-dz/internal/storage"
	"boltbook-ai-dz/internal/transport"
)

type Service struct {
	store       *storage.Store
	client      boltbook.Client
	logger      *slog.Logger
	brokerAgent string
}

func NewService(store *storage.Store, client boltbook.Client, logger *slog.Logger, brokerAgent string) *Service {
	return &Service{store: store, client: client, logger: logger, brokerAgent: brokerAgent}
}

func (s *Service) RunCycle(ctx context.Context) error {
	runID := core.NextID("broker_run")
	started := time.Now().UTC()
	examined := 0
	processed := 0
	var runErr error

	s.log(ctx, runID, "info", "loop_started", domain.StructuredLog{
		LogID:     core.NextID("log"),
		RunID:     runID,
		Component: "broker",
		Level:     "info",
		Event:     "loop_started",
		Message:   "Broker cycle started.",
		Timestamp: started,
	})

	defer func() {
		status := "completed"
		errorText := ""
		if runErr != nil {
			status = "failed"
			errorText = runErr.Error()
		}
		ended := time.Now().UTC()
		_ = s.store.SaveRunHistory(ctx, domain.RunHistory{
			RunID:     runID,
			Component: "broker",
			Status:    status,
			StartedAt: started,
			EndedAt:   ended,
			Examined:  examined,
			Processed: processed,
			ErrorText: errorText,
		})
		s.log(ctx, runID, "info", "loop_finished", domain.StructuredLog{
			LogID:     core.NextID("log"),
			RunID:     runID,
			Component: "broker",
			Level:     "info",
			Event:     "loop_finished",
			Message:   fmt.Sprintf("Broker cycle finished with status=%s examined=%d processed=%d.", status, examined, processed),
			Timestamp: ended,
		})
	}()

	discovered, err := s.client.PollBrokerIntake(ctx, s.brokerAgent)
	if err != nil {
		runErr = err
		return err
	}
	for _, task := range discovered {
		if task.IngestedAt.IsZero() {
			task.IngestedAt = time.Now().UTC()
		}
		if task.Status == "" {
			task.Status = domain.TaskStatusNew
		}
		if err := s.store.CreateTask(ctx, task); err != nil {
			runErr = err
			return err
		}
	}

	tasks, err := s.store.ListTasksByStatus(ctx, domain.TaskStatusNew, domain.TaskStatusDeferred)
	if err != nil {
		runErr = err
		return err
	}
	examined = len(tasks)

	for _, task := range tasks {
		if err := s.processTask(ctx, runID, task); err != nil {
			runErr = err
			return err
		}
		processed++
	}

	return nil
}

func (s *Service) AddPortfolio(ctx context.Context, executor domain.ExecutorPortfolio) error {
	if executor.ExecutorID == "" {
		return errors.New("executor_id is required")
	}
	now := time.Now().UTC()
	if executor.CreatedAt.IsZero() {
		executor.CreatedAt = now
	}
	executor.UpdatedAt = now
	if executor.AvailabilityState == "" {
		executor.AvailabilityState = domain.AvailabilityActive
	}
	return s.store.UpsertExecutor(ctx, executor)
}

func (s *Service) UpdatePortfolio(ctx context.Context, executor domain.ExecutorPortfolio) error {
	return s.AddPortfolio(ctx, executor)
}

func (s *Service) MatchAgentsTop5(ctx context.Context, task domain.Task) (domain.MatchResult, error) {
	executors, err := s.store.ListActiveExecutors(ctx)
	if err != nil {
		return domain.MatchResult{}, err
	}
	return matching.Rank(task, executors), nil
}

func (s *Service) CreateConsensusHandoff(ctx context.Context, task domain.Task) (domain.Handoff, error) {
	match, err := s.MatchAgentsTop5(ctx, task)
	if err != nil {
		return domain.Handoff{}, err
	}
	if len(match.Candidates) == 0 {
		return domain.Handoff{}, errors.New("no executor candidates available")
	}
	candidate := match.Candidates[0]
	handoff := domain.Handoff{
		HandoffID:          core.NextID("handoff"),
		TaskID:             task.TaskID,
		SelectedExecutorID: candidate.ExecutorID,
		BrokerRecommendation: domain.BrokerRecommendation{
			Score:      candidate.Score,
			FitSummary: candidate.FitSummary,
		},
		TaskContext: domain.TaskContext{
			Title:    task.Title,
			Body:     task.Body,
			TaskTags: task.TaskTags,
		},
		TransportPlan: transport.PlanForTask(task),
		Colloquium: domain.Colloquium{
			Mode:       "mock",
			Evaluators: []string{"topic_fit", "execution_fit", "risk_check"},
			Aggregator: "weighted_merge_v1",
		},
		CreatedAt: time.Now().UTC(),
	}
	return handoff, nil
}

func (s *Service) NotifySelectedAgentDemo(ctx context.Context, task domain.Task, handoff domain.Handoff) (domain.TransportAction, error) {
	executors, err := s.store.ListActiveExecutors(ctx)
	if err != nil {
		return domain.TransportAction{}, err
	}
	var target domain.ExecutorPortfolio
	found := false
	for _, executor := range executors {
		if executor.ExecutorID == handoff.SelectedExecutorID {
			target = executor
			found = true
			break
		}
	}
	if !found {
		return domain.TransportAction{}, fmt.Errorf("selected executor %q not found", handoff.SelectedExecutorID)
	}

	body := fmt.Sprintf("%s looks like the best fit for %q. %s", target.DisplayName, task.Title, handoff.BrokerRecommendation.FitSummary)
	modes := append([]domain.TransportMode{handoff.TransportPlan.PrimaryMode}, handoff.TransportPlan.FallbackModes...)
	var lastErr error
	for _, mode := range modes {
		action, err := s.tryTransport(ctx, mode, task, handoff, target, body)
		if err == nil {
			return action, nil
		}
		lastErr = err
		failed := domain.TransportAction{
			TransportID:           core.NextID("transport"),
			TaskID:                task.TaskID,
			HandoffID:             handoff.HandoffID,
			AttemptedMode:         mode,
			TargetAgentName:       target.BoltbookAgentName,
			RequestPayloadExcerpt: excerpt(body),
			Outcome:               domain.TransportOutcomeFailed,
			ProviderStatusCode:    0,
			ProviderRef:           "",
			AttemptedAt:           time.Now().UTC(),
		}
		_ = s.store.SaveTransportAction(ctx, failed)
		s.log(ctx, handoff.HandoffID, "warn", "transport_failed", domain.StructuredLog{
			LogID:       core.NextID("log"),
			RunID:       handoff.HandoffID,
			Component:   "broker",
			Level:       "warn",
			Event:       "transport_failed",
			TaskID:      task.TaskID,
			ExecutorID:  target.ExecutorID,
			HandoffID:   handoff.HandoffID,
			TransportID: failed.TransportID,
			Message:     fmt.Sprintf("Transport %s failed: %v", mode, err),
			Timestamp:   time.Now().UTC(),
		})
	}
	if lastErr == nil {
		lastErr = errors.New("no transport modes were available")
	}
	return domain.TransportAction{}, lastErr
}

func (s *Service) processTask(ctx context.Context, runID string, task domain.Task) error {
	match, err := s.MatchAgentsTop5(ctx, task)
	if err != nil {
		return err
	}
	if err := s.store.SaveMatchResult(ctx, match); err != nil {
		return err
	}
	if err := s.store.UpdateTaskStatus(ctx, task.TaskID, domain.TaskStatusMatched); err != nil {
		return err
	}

	handoff, err := s.CreateConsensusHandoff(ctx, task)
	if err != nil {
		return err
	}
	if err := s.store.SaveHandoff(ctx, handoff); err != nil {
		return err
	}

	action, err := s.NotifySelectedAgentDemo(ctx, task, handoff)
	if err != nil {
		if updateErr := s.store.UpdateTaskStatus(ctx, task.TaskID, domain.TaskStatusDeferred); updateErr != nil {
			return errors.Join(err, updateErr)
		}
		return err
	}
	if err := s.store.SaveTransportAction(ctx, action); err != nil {
		return err
	}

	nextStatus := domain.TaskStatusContacted
	if action.Outcome == domain.TransportOutcomeAwaitingApproval {
		nextStatus = domain.TaskStatusAwaitingReply
	}
	if err := s.store.UpdateTaskStatus(ctx, task.TaskID, nextStatus); err != nil {
		return err
	}

	s.log(ctx, runID, "info", "task_matched", domain.StructuredLog{
		LogID:       core.NextID("log"),
		RunID:       runID,
		Component:   "broker",
		Level:       "info",
		Event:       "task_matched",
		TaskID:      task.TaskID,
		ExecutorID:  handoff.SelectedExecutorID,
		HandoffID:   handoff.HandoffID,
		TransportID: action.TransportID,
		Message:     fmt.Sprintf("Matched task to %s and executed %s.", handoff.SelectedExecutorID, action.AttemptedMode),
		Timestamp:   time.Now().UTC(),
	})

	return nil
}

func (s *Service) tryTransport(ctx context.Context, mode domain.TransportMode, task domain.Task, handoff domain.Handoff, target domain.ExecutorPortfolio, body string) (domain.TransportAction, error) {
	var (
		result  boltbook.SendResult
		err     error
		outcome domain.TransportOutcome
		ref     domain.TargetRef
	)

	switch mode {
	case domain.TransportModePublicComment:
		result, err = s.client.SendPublicReply(ctx, task, target.BoltbookAgentName, body)
		ref = domain.TargetRef{PostID: task.SourceRef.PostID, PostURL: task.SourceRef.URL, ThreadID: firstNonEmpty(result.ProviderRef, task.SourceRef.ThreadID)}
		outcome = domain.TransportOutcomeSent
	case domain.TransportModePublicPost:
		result, err = s.client.CreatePublicPost(ctx, task, target.BoltbookAgentName, body)
		ref = domain.TargetRef{PostID: result.ProviderRef, PostURL: postURL(result.ProviderRef), ThreadID: result.ProviderRef}
		outcome = domain.TransportOutcomeSent
	case domain.TransportModeDMRequest:
		result, err = s.client.OpenDMRequest(ctx, task, target.BoltbookAgentName, body)
		ref = domain.TargetRef{ConversationID: result.ProviderRef}
		outcome = domain.TransportOutcomeAwaitingApproval
	case domain.TransportModeDMMessage:
		lead := domain.InboundLead{TaskID: task.TaskID, ThreadRef: domain.TargetRef{ConversationID: task.SourceRef.ThreadID}}
		result, err = s.client.SendDMMessage(ctx, lead, body)
		ref = domain.TargetRef{ConversationID: result.ProviderRef}
		outcome = domain.TransportOutcomeSent
	default:
		return domain.TransportAction{}, fmt.Errorf("unsupported transport mode %q", mode)
	}
	if err != nil {
		return domain.TransportAction{}, err
	}

	return domain.TransportAction{
		TransportID:           core.NextID("transport"),
		TaskID:                task.TaskID,
		HandoffID:             handoff.HandoffID,
		AttemptedMode:         mode,
		TargetAgentName:       target.BoltbookAgentName,
		TargetRef:             ref,
		RequestPayloadExcerpt: excerpt(body),
		Outcome:               outcome,
		ProviderStatusCode:    result.StatusCode,
		ProviderRef:           result.ProviderRef,
		AttemptedAt:           time.Now().UTC(),
	}, nil
}

func (s *Service) log(ctx context.Context, runID, level, event string, record domain.StructuredLog) {
	if record.Timestamp.IsZero() {
		record.Timestamp = time.Now().UTC()
	}
	if record.LogID == "" {
		record.LogID = core.NextID("log")
	}
	record.RunID = runID
	record.Event = event
	if err := s.store.SaveStructuredLog(ctx, record); err != nil {
		s.logger.Error("persist structured log", "error", err, "event", event)
	}
	s.logger.Log(ctx, parseLevel(level), record.Message,
		"component", record.Component,
		"run_id", record.RunID,
		"event", record.Event,
		"task_id", record.TaskID,
		"executor_id", record.ExecutorID,
		"handoff_id", record.HandoffID,
		"transport_id", record.TransportID,
	)
}

func parseLevel(level string) slog.Level {
	switch strings.ToLower(level) {
	case "debug":
		return slog.LevelDebug
	case "warn":
		return slog.LevelWarn
	case "error":
		return slog.LevelError
	default:
		return slog.LevelInfo
	}
}

func excerpt(text string) string {
	if len(text) <= 180 {
		return text
	}
	return text[:177] + "..."
}

func postURL(postID string) string {
	if postID == "" {
		return ""
	}
	return fmt.Sprintf("https://boltbook.ai/post/%s", postID)
}

func firstNonEmpty(values ...string) string {
	for _, value := range values {
		if value != "" {
			return value
		}
	}
	return ""
}
