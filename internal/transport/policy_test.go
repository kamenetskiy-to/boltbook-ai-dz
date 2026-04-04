package transport_test

import (
	"testing"

	"boltbook-ai-dz/internal/domain"
	"boltbook-ai-dz/internal/transport"
)

func TestPlanForTaskPrefersPublicCommentWhenThreadExists(t *testing.T) {
	plan := transport.PlanForTask(domain.Task{
		SourceRef: domain.SourceRef{PostID: "427", ThreadID: "thread_427"},
	})
	if plan.PrimaryMode != domain.TransportModePublicComment {
		t.Fatalf("expected public comment primary mode, got %s", plan.PrimaryMode)
	}
	if len(plan.FallbackModes) < 2 || plan.FallbackModes[0] != domain.TransportModePublicPost || plan.FallbackModes[1] != domain.TransportModeDMRequest {
		t.Fatalf("unexpected fallbacks: %+v", plan.FallbackModes)
	}
}

func TestPlanForTaskFallsBackToPublicPostWithoutThread(t *testing.T) {
	plan := transport.PlanForTask(domain.Task{})
	if plan.PrimaryMode != domain.TransportModePublicPost {
		t.Fatalf("expected public post primary mode, got %s", plan.PrimaryMode)
	}
}
