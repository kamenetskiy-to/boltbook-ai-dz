package fixer

import (
	"context"
	"io"
	"log/slog"
	"testing"

	"boltbook-ai-dz/internal/boltbook"
	"boltbook-ai-dz/internal/domain"
	"boltbook-ai-dz/internal/storage"
)

type stubDrafter struct {
	draft ResponseDraft
	err   error
}

func (s stubDrafter) DraftFixerResponse(_ context.Context, _ domain.InboundLead, _ domain.ResponseDecision, _ string) (ResponseDraft, error) {
	return s.draft, s.err
}

func TestHandleLeadUsesCodexDraftWhenAvailable(t *testing.T) {
	t.Parallel()

	store, err := storage.Open(":memory:")
	if err != nil {
		t.Fatal(err)
	}
	defer store.Close()

	client := boltbook.NewFakeClient("broker", "fixer")
	service := NewService(store, client, slog.New(slog.NewTextHandler(io.Discard, nil)), "fixer").WithResponseDrafter(stubDrafter{
		draft: ResponseDraft{
			Decision: domain.ResponseDecisionRequestClarify,
			Message:  "Need the target runtime, MCP surface, and success criteria before estimating.",
		},
	})

	response, err := service.HandleLead(context.Background(), domain.InboundLead{
		LeadID:          "lead-1",
		TaskID:          "task-1",
		SourceMode:      domain.TransportModePublicComment,
		BrokerAgentName: "broker",
		TargetAgentName: "fixer",
		Body:            "Need help implementing an MCP-based runtime.",
	})
	if err != nil {
		t.Fatal(err)
	}
	if response.Decision != domain.ResponseDecisionRequestClarify {
		t.Fatalf("expected drafted decision, got %q", response.Decision)
	}
	if response.Message != "Need the target runtime, MCP surface, and success criteria before estimating." {
		t.Fatalf("expected drafted message, got %q", response.Message)
	}
}

func TestHandleLeadFallsBackWhenCodexDraftFails(t *testing.T) {
	t.Parallel()

	store, err := storage.Open(":memory:")
	if err != nil {
		t.Fatal(err)
	}
	defer store.Close()

	client := boltbook.NewFakeClient("broker", "fixer")
	service := NewService(store, client, slog.New(slog.NewTextHandler(io.Discard, nil)), "fixer").WithResponseDrafter(stubDrafter{
		err: context.DeadlineExceeded,
	})

	response, err := service.HandleLead(context.Background(), domain.InboundLead{
		LeadID:          "lead-1",
		TaskID:          "task-1",
		SourceMode:      domain.TransportModePublicComment,
		BrokerAgentName: "broker",
		TargetAgentName: "fixer",
		Body:            "Need timeline and estimate for a Go MCP task.",
	})
	if err != nil {
		t.Fatal(err)
	}
	if response.Decision != domain.ResponseDecisionPreliminaryEstimate {
		t.Fatalf("expected fallback decision, got %q", response.Decision)
	}
	if response.Message == "" {
		t.Fatalf("expected fallback message to be preserved")
	}
}
