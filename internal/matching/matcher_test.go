package matching_test

import (
	"testing"
	"time"

	"boltbook-ai-dz/internal/domain"
	"boltbook-ai-dz/internal/matching"
)

func TestRankPrefersStrongCapabilityOverlap(t *testing.T) {
	task := domain.Task{
		TaskID:             "task_1",
		Title:              "Go MCP broker",
		TaskTags:           []string{"golang", "mcp", "sqlite"},
		DeliveryPreference: domain.DeliveryPreferencePublicFirst,
	}

	result := matching.Rank(task, []domain.ExecutorPortfolio{
		{
			ExecutorID:           "weak",
			DisplayName:          "Weak",
			Summary:              "Generalist.",
			CapabilityTags:       []string{"python"},
			ServiceModes:         []string{"lead_intake"},
			TransportPreferences: []domain.TransportMode{domain.TransportModeDMRequest},
			AvailabilityState:    domain.AvailabilityActive,
		},
		{
			ExecutorID:           "fixer",
			DisplayName:          "Fixer",
			Summary:              "Implementation-heavy MCP and debugging executor.",
			CapabilityTags:       []string{"golang", "mcp", "sqlite"},
			ServiceModes:         []string{"lead_intake", "rough_estimate"},
			TransportPreferences: []domain.TransportMode{domain.TransportModePublicComment, domain.TransportModePublicPost},
			AvailabilityState:    domain.AvailabilityActive,
			TrustSignals: domain.TrustSignals{
				OperatorCurated: true,
				LastValidatedAt: time.Now().UTC(),
			},
		},
	})

	if len(result.Candidates) != 2 {
		t.Fatalf("expected 2 candidates, got %d", len(result.Candidates))
	}
	if got := result.Candidates[0].ExecutorID; got != "fixer" {
		t.Fatalf("expected fixer to rank first, got %s", got)
	}
	if result.Candidates[0].Score <= result.Candidates[1].Score {
		t.Fatalf("expected first score to be greater than second: %+v", result.Candidates)
	}
}
