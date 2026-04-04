package fixer

import (
	"context"
	"fmt"
	"log/slog"
	"strings"
	"time"

	"boltbook-ai-dz/internal/boltbook"
	"boltbook-ai-dz/internal/core"
	"boltbook-ai-dz/internal/domain"
	"boltbook-ai-dz/internal/storage"
)

type responseDrafter interface {
	DraftFixerResponse(ctx context.Context, lead domain.InboundLead, fallbackDecision domain.ResponseDecision, fallbackMessage string) (ResponseDraft, error)
}

type ResponseDraft struct {
	Decision domain.ResponseDecision
	Message  string
}

type Service struct {
	store      *storage.Store
	client     boltbook.Client
	logger     *slog.Logger
	fixerAgent string
	drafter    responseDrafter
}

func NewService(store *storage.Store, client boltbook.Client, logger *slog.Logger, fixerAgent string) *Service {
	return &Service{store: store, client: client, logger: logger, fixerAgent: fixerAgent}
}

func (s *Service) WithResponseDrafter(drafter responseDrafter) *Service {
	s.drafter = drafter
	return s
}

func (s *Service) RunCycle(ctx context.Context) error {
	runID := core.NextID("fixer_run")
	started := time.Now().UTC()
	leads, err := s.client.PollFixerInbox(ctx, s.fixerAgent)
	if err != nil {
		return err
	}

	s.log(ctx, runID, "info", "loop_started", domain.StructuredLog{
		LogID:     core.NextID("log"),
		RunID:     runID,
		Component: "fixer",
		Level:     "info",
		Event:     "loop_started",
		Message:   "Fixer cycle started.",
		Timestamp: started,
	})

	processed := 0
	var runErr error
	for _, lead := range leads {
		if err := s.handleLead(ctx, runID, lead); err != nil {
			runErr = err
			break
		}
		processed++
	}

	status := "completed"
	errorText := ""
	if runErr != nil {
		status = "failed"
		errorText = runErr.Error()
	}
	ended := time.Now().UTC()
	_ = s.store.SaveRunHistory(ctx, domain.RunHistory{
		RunID:     runID,
		Component: "fixer",
		Status:    status,
		StartedAt: started,
		EndedAt:   ended,
		Examined:  len(leads),
		Processed: processed,
		ErrorText: errorText,
	})
	s.log(ctx, runID, "info", "loop_finished", domain.StructuredLog{
		LogID:     core.NextID("log"),
		RunID:     runID,
		Component: "fixer",
		Level:     "info",
		Event:     "loop_finished",
		Message:   fmt.Sprintf("Fixer cycle finished with status=%s examined=%d processed=%d.", status, len(leads), processed),
		Timestamp: ended,
	})

	return runErr
}

func (s *Service) HandleLead(ctx context.Context, lead domain.InboundLead) (domain.FixerResponseAction, error) {
	decision, message := decideLeadResponse(lead)
	if s.drafter != nil {
		draft, err := s.drafter.DraftFixerResponse(ctx, lead, decision, message)
		if err != nil {
			s.logger.Warn("codex fixer draft failed", "error", err, "lead_id", lead.LeadID)
		} else {
			decision = draft.Decision
			message = draft.Message
		}
	}
	result, err := s.client.RespondToLead(ctx, lead, decision, message)
	if err != nil {
		return domain.FixerResponseAction{}, err
	}

	response := domain.FixerResponseAction{
		ResponseID:         core.NextID("response"),
		LeadID:             lead.LeadID,
		TaskID:             lead.TaskID,
		Decision:           decision,
		Message:            message,
		ResponseMode:       responseModeForLead(lead),
		ProviderStatusCode: result.StatusCode,
		ProviderRef:        result.ProviderRef,
		RespondedAt:        time.Now().UTC(),
	}
	return response, s.store.SaveFixerResponse(ctx, response)
}

func (s *Service) handleLead(ctx context.Context, runID string, lead domain.InboundLead) error {
	response, err := s.HandleLead(ctx, lead)
	if err != nil {
		return err
	}
	s.log(ctx, runID, "info", "lead_responded", domain.StructuredLog{
		LogID:     core.NextID("log"),
		RunID:     runID,
		Component: "fixer",
		Level:     "info",
		Event:     "lead_responded",
		TaskID:    lead.TaskID,
		Message:   fmt.Sprintf("Responded to lead %s with %s.", lead.LeadID, response.Decision),
		Timestamp: time.Now().UTC(),
	})
	return nil
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
	)
}

func decideLeadResponse(lead domain.InboundLead) (domain.ResponseDecision, string) {
	body := strings.ToLower(lead.Body)
	switch {
	case strings.Contains(body, "clarify") || strings.Contains(body, "scope"):
		return domain.ResponseDecisionRequestClarify, "Fixer can likely help, but needs a tighter scope, target runtime, and success criteria before estimating."
	case strings.Contains(body, "estimate") || strings.Contains(body, "timeline"):
		return domain.ResponseDecisionPreliminaryEstimate, "Fixer is a plausible fit. Initial expectation: confirm constraints, shape the implementation slice, then return a rough build estimate."
	default:
		return domain.ResponseDecisionAcknowledgeFit, "Fixer looks aligned with the implementation work and can start with a clarification pass plus a concrete next-step plan."
	}
}

func responseModeForLead(lead domain.InboundLead) domain.TransportMode {
	if lead.SourceMode == domain.TransportModeDMRequest || lead.SourceMode == domain.TransportModeDMMessage {
		return domain.TransportModeDMMessage
	}
	return lead.SourceMode
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
