package boltbook

import (
	"context"
	"errors"
	"fmt"
	"sync"
	"time"

	"boltbook-ai-dz/internal/core"
	"boltbook-ai-dz/internal/domain"
)

type SendResult struct {
	StatusCode  int
	ProviderRef string
}

type Client interface {
	PollBrokerIntake(ctx context.Context, brokerAgent string) ([]domain.Task, error)
	PollFixerInbox(ctx context.Context, fixerAgent string) ([]domain.InboundLead, error)
	SendPublicReply(ctx context.Context, task domain.Task, targetAgent string, body string) (SendResult, error)
	CreatePublicPost(ctx context.Context, task domain.Task, targetAgent string, body string) (SendResult, error)
	OpenDMRequest(ctx context.Context, task domain.Task, targetAgent string, body string) (SendResult, error)
	SendDMMessage(ctx context.Context, lead domain.InboundLead, body string) (SendResult, error)
	RespondToLead(ctx context.Context, lead domain.InboundLead, decision domain.ResponseDecision, body string) (SendResult, error)
}

type FakeClient struct {
	mu           sync.Mutex
	tasks        []domain.Task
	pendingLeads []domain.InboundLead
	pendingTasks map[string]struct{}
	failures     map[domain.TransportMode]int
	brokerAgent  string
	fixerAgent   string
}

func NewFakeClient(brokerAgent, fixerAgent string) *FakeClient {
	return &FakeClient{
		pendingTasks: make(map[string]struct{}),
		failures:     make(map[domain.TransportMode]int),
		brokerAgent:  brokerAgent,
		fixerAgent:   fixerAgent,
	}
}

func (f *FakeClient) SeedTask(task domain.Task) {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.tasks = append(f.tasks, task)
	f.pendingTasks[task.TaskID] = struct{}{}
}

func (f *FakeClient) FailNext(mode domain.TransportMode, count int) {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.failures[mode] = count
}

func (f *FakeClient) PollBrokerIntake(_ context.Context, _ string) ([]domain.Task, error) {
	f.mu.Lock()
	defer f.mu.Unlock()

	var out []domain.Task
	for _, task := range f.tasks {
		if _, ok := f.pendingTasks[task.TaskID]; !ok {
			continue
		}
		out = append(out, task)
		delete(f.pendingTasks, task.TaskID)
	}
	return out, nil
}

func (f *FakeClient) PollFixerInbox(_ context.Context, fixerAgent string) ([]domain.InboundLead, error) {
	f.mu.Lock()
	defer f.mu.Unlock()

	var remaining []domain.InboundLead
	var out []domain.InboundLead
	for _, lead := range f.pendingLeads {
		if lead.TargetAgentName == fixerAgent {
			out = append(out, lead)
			continue
		}
		remaining = append(remaining, lead)
	}
	f.pendingLeads = remaining
	return out, nil
}

func (f *FakeClient) SendPublicReply(_ context.Context, task domain.Task, targetAgent string, body string) (SendResult, error) {
	if task.SourceRef.PostID == "" && task.SourceRef.ThreadID == "" {
		return SendResult{}, errors.New("task has no public thread reference")
	}
	if err := f.consumeFailure(domain.TransportModePublicComment); err != nil {
		return SendResult{}, err
	}
	result := SendResult{StatusCode: 201, ProviderRef: core.NextID("comment")}
	f.enqueueLead(task, targetAgent, domain.TransportModePublicComment, body, domain.TargetRef{
		PostID:   task.SourceRef.PostID,
		PostURL:  task.SourceRef.URL,
		ThreadID: firstNonEmpty(result.ProviderRef, task.SourceRef.ThreadID),
	})
	return result, nil
}

func (f *FakeClient) CreatePublicPost(_ context.Context, task domain.Task, targetAgent string, body string) (SendResult, error) {
	if err := f.consumeFailure(domain.TransportModePublicPost); err != nil {
		return SendResult{}, err
	}
	result := SendResult{StatusCode: 201, ProviderRef: core.NextID("post")}
	f.enqueueLead(task, targetAgent, domain.TransportModePublicPost, body, domain.TargetRef{
		PostID:   result.ProviderRef,
		PostURL:  fmt.Sprintf("https://boltbook.ai/post/%s", result.ProviderRef),
		ThreadID: result.ProviderRef,
	})
	return result, nil
}

func (f *FakeClient) OpenDMRequest(_ context.Context, _ domain.Task, _ string, _ string) (SendResult, error) {
	if err := f.consumeFailure(domain.TransportModeDMRequest); err != nil {
		return SendResult{}, err
	}
	return SendResult{StatusCode: 202, ProviderRef: core.NextID("dmreq")}, nil
}

func (f *FakeClient) SendDMMessage(_ context.Context, lead domain.InboundLead, body string) (SendResult, error) {
	if err := f.consumeFailure(domain.TransportModeDMMessage); err != nil {
		return SendResult{}, err
	}
	result := SendResult{StatusCode: 201, ProviderRef: core.NextID("dm")}
	f.enqueueLead(domain.Task{TaskID: lead.TaskID}, lead.TargetAgentName, domain.TransportModeDMMessage, body, domain.TargetRef{
		ConversationID: firstNonEmpty(lead.ThreadRef.ConversationID, result.ProviderRef),
	})
	return result, nil
}

func (f *FakeClient) RespondToLead(_ context.Context, lead domain.InboundLead, decision domain.ResponseDecision, _ string) (SendResult, error) {
	mode := lead.SourceMode
	if mode == "" {
		mode = domain.TransportModePublicComment
	}
	if err := f.consumeFailure(mode); err != nil {
		return SendResult{}, err
	}
	return SendResult{StatusCode: 201, ProviderRef: core.NextID(string(decision))}, nil
}

func (f *FakeClient) enqueueLead(task domain.Task, targetAgent string, mode domain.TransportMode, body string, ref domain.TargetRef) {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.pendingLeads = append(f.pendingLeads, domain.InboundLead{
		LeadID:          core.NextID("lead"),
		TaskID:          task.TaskID,
		HandoffID:       "",
		SourceMode:      mode,
		BrokerAgentName: f.brokerAgent,
		TargetAgentName: targetAgent,
		Body:            body,
		ThreadRef:       ref,
		ReceivedAt:      time.Now().UTC(),
	})
}

func (f *FakeClient) consumeFailure(mode domain.TransportMode) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	if remaining := f.failures[mode]; remaining > 0 {
		f.failures[mode] = remaining - 1
		return fmt.Errorf("%s transport is temporarily unavailable", mode)
	}
	return nil
}

func firstNonEmpty(values ...string) string {
	for _, value := range values {
		if value != "" {
			return value
		}
	}
	return ""
}
