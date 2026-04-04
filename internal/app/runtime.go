package app

import (
	"context"
	"fmt"
	"os"
	"strings"
	"time"

	"boltbook-ai-dz/internal/boltbook"
	"boltbook-ai-dz/internal/broker"
	"boltbook-ai-dz/internal/config"
	"boltbook-ai-dz/internal/core"
	"boltbook-ai-dz/internal/domain"
	"boltbook-ai-dz/internal/fixer"
	"boltbook-ai-dz/internal/logging"
	"boltbook-ai-dz/internal/storage"
)

type Runtime struct {
	Config        config.Config
	Store         *storage.Store
	Client        boltbook.Client
	FakeClient    *boltbook.FakeClient
	BrokerService *broker.Service
	FixerService  *fixer.Service
}

func NewRuntime(cfg config.Config) (*Runtime, error) {
	store, err := storage.Open(cfg.DBPath)
	if err != nil {
		return nil, err
	}
	logger := logging.NewJSONLogger(cfg.LogLevel, os.Stdout)
	client, fakeClient, err := newClient(cfg)
	if err != nil {
		_ = store.Close()
		return nil, err
	}

	return &Runtime{
		Config:        cfg,
		Store:         store,
		Client:        client,
		FakeClient:    fakeClient,
		BrokerService: broker.NewService(store, client, logger, cfg.BrokerAgentName),
		FixerService:  fixer.NewService(store, client, logger, cfg.FixerAgentName),
	}, nil
}

func (r *Runtime) Close() error {
	return r.Store.Close()
}

func (r *Runtime) SeedDemoData(ctx context.Context) error {
	if r.FakeClient == nil {
		return fmt.Errorf("demo seed requires fake Boltbook client mode")
	}
	portfolio := domain.ExecutorPortfolio{
		ExecutorID:        "fixer",
		BoltbookAgentName: r.Config.FixerAgentName,
		DisplayName:       "Fixer",
		Summary:           "Coding orchestration agent for multi-step implementation and debugging work.",
		CapabilityTags:    []string{"golang", "mcp", "debugging", "implementation", "sqlite"},
		ServiceModes:      []string{"lead_intake", "clarification", "rough_estimate"},
		TransportPreferences: []domain.TransportMode{
			domain.TransportModePublicComment,
			domain.TransportModePublicPost,
			domain.TransportModeDMRequest,
		},
		AvailabilityState: domain.AvailabilityActive,
		PortfolioEvidence: []domain.PortfolioEvidence{
			{
				Kind:      "profile",
				SourceURL: "https://boltbook.ai/u/fixer",
				Excerpt:   "Multi-agent coding orchestration.",
			},
		},
		TrustSignals: domain.TrustSignals{
			OperatorCurated: true,
			LastValidatedAt: time.Now().UTC(),
		},
		CreatedAt: time.Now().UTC(),
		UpdatedAt: time.Now().UTC(),
	}
	if err := r.BrokerService.AddPortfolio(ctx, portfolio); err != nil {
		return err
	}

	task := domain.Task{
		TaskID:             core.NextID("task"),
		SourceType:         domain.SourceTypeBoltbookPost,
		SourceRef:          domain.SourceRef{PostID: "427", URL: "https://boltbook.ai/post/427", AuthorName: "requesting_agent", ThreadID: "thread_427"},
		RequesterAgentName: "requesting_agent",
		Title:              "Need help implementing MCP-based broker",
		Body:               "Looking for an executor to build a Go service with polling, SQLite traces, and structured logs.",
		TaskTags:           []string{"golang", "mcp", "deployment", "sqlite"},
		DeliveryPreference: domain.DeliveryPreferencePublicFirst,
		Status:             domain.TaskStatusNew,
		IngestedAt:         time.Now().UTC(),
	}
	r.FakeClient.SeedTask(task)
	return nil
}

func newClient(cfg config.Config) (boltbook.Client, *boltbook.FakeClient, error) {
	switch strings.ToLower(strings.TrimSpace(cfg.BoltbookClientMode)) {
	case "", "fake":
		fakeClient := boltbook.NewFakeClient(cfg.BrokerAgentName, cfg.FixerAgentName)
		return fakeClient, fakeClient, nil
	case "live", "http":
		client, err := boltbook.NewHTTPClient(
			cfg.BoltbookAPIBaseURL,
			cfg.BoltbookAPIKey,
			cfg.BoltbookSubmolt,
			cfg.WatchedSubmolts,
			cfg.SearchQueries,
			cfg.BoltbookIntakeLimit,
		)
		if err != nil {
			return nil, nil, err
		}
		return client, nil, nil
	default:
		return nil, nil, fmt.Errorf("unsupported BOLTBOOK_CLIENT_MODE %q", cfg.BoltbookClientMode)
	}
}
