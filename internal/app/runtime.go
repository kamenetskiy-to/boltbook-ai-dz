package app

import (
	"context"
	"fmt"
	"os"
	"strings"
	"time"

	"boltbook-ai-dz/internal/boltbook"
	"boltbook-ai-dz/internal/broker"
	"boltbook-ai-dz/internal/codexcli"
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
	fixerService := fixer.NewService(store, client, logger, cfg.FixerAgentName)
	if cfg.FixerCodexEnabled {
		fixerService.WithResponseDrafter(codexResponseDrafter{
			client: codexcli.Client{
				CommandPath: cfg.CodexCLIPath,
				HomeDir:     cfg.CodexHome,
				Model:       cfg.CodexModel,
				Timeout:     cfg.CodexTimeout,
			},
		})
	}

	return &Runtime{
		Config:        cfg,
		Store:         store,
		Client:        client,
		FakeClient:    fakeClient,
		BrokerService: broker.NewService(store, client, logger, cfg.BrokerAgentName),
		FixerService:  fixerService,
	}, nil
}

func (r *Runtime) Close() error {
	return r.Store.Close()
}

func (r *Runtime) EnsureDefaultPortfolio(ctx context.Context) error {
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
				SourceURL: "https://boltbook.ai/u/" + r.Config.FixerAgentName,
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
	return r.BrokerService.AddPortfolio(ctx, portfolio)
}

func (r *Runtime) SeedDemoData(ctx context.Context) error {
	if r.FakeClient == nil {
		return fmt.Errorf("demo seed requires fake Boltbook client mode")
	}
	if err := r.EnsureDefaultPortfolio(ctx); err != nil {
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
			boltbook.LiveClientOptions{
				BrokerIntakeFromFeed:     cfg.BrokerIntakeFromFeed,
				BrokerIntakeFromSubmolts: cfg.BrokerIntakeFromSubmolts,
				BrokerIntakeFromSearch:   cfg.BrokerIntakeFromSearch,
				FixerSearchQueries:       cfg.FixerSearchQueries,
				FixerInboxFromDMs:        cfg.FixerInboxFromDMs,
			},
		)
		if err != nil {
			return nil, nil, err
		}
		return client, nil, nil
	default:
		return nil, nil, fmt.Errorf("unsupported BOLTBOOK_CLIENT_MODE %q", cfg.BoltbookClientMode)
	}
}

type codexResponseDrafter struct {
	client codexcli.Client
}

func (d codexResponseDrafter) DraftFixerResponse(ctx context.Context, lead domain.InboundLead, fallbackDecision domain.ResponseDecision, fallbackMessage string) (fixer.ResponseDraft, error) {
	draft, err := d.client.DraftFixerResponse(ctx, lead, fallbackDecision, fallbackMessage)
	if err != nil {
		return fixer.ResponseDraft{}, err
	}
	return fixer.ResponseDraft{
		Decision: draft.Decision,
		Message:  draft.Message,
	}, nil
}
