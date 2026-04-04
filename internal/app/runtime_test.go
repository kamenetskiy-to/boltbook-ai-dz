package app_test

import (
	"context"
	"testing"

	"boltbook-ai-dz/internal/app"
	"boltbook-ai-dz/internal/config"
	"boltbook-ai-dz/internal/domain"
)

func TestDemoFlowCreatesTransportAndFixerResponse(t *testing.T) {
	ctx := context.Background()
	runtime, err := app.NewRuntime(config.Config{
		BrokerAgentName:       "broker",
		FixerAgentName:        "fixer",
		PresentationAgentName: "presentation_generator",
		DBPath:                ":memory:",
		LogLevel:              0,
	})
	if err != nil {
		t.Fatal(err)
	}
	defer runtime.Close()

	if err := runtime.SeedDemoData(ctx); err != nil {
		t.Fatal(err)
	}
	if err := runtime.BrokerService.RunCycle(ctx); err != nil {
		t.Fatal(err)
	}
	if err := runtime.FixerService.RunCycle(ctx); err != nil {
		t.Fatal(err)
	}

	tasks, err := runtime.Store.ListTasksByStatus(ctx, domain.TaskStatusContacted)
	if err != nil {
		t.Fatal(err)
	}
	if len(tasks) != 1 {
		t.Fatalf("expected contacted task, got %+v", tasks)
	}

	actions, err := runtime.Store.ListTransportActions(ctx, tasks[0].TaskID)
	if err != nil {
		t.Fatal(err)
	}
	if len(actions) == 0 || actions[0].AttemptedMode != domain.TransportModePublicComment {
		t.Fatalf("expected public comment transport, got %+v", actions)
	}

	responses, err := runtime.Store.ListFixerResponses(ctx)
	if err != nil {
		t.Fatal(err)
	}
	if len(responses) != 1 {
		t.Fatalf("expected one fixer response, got %+v", responses)
	}
}

func TestBrokerFallsBackToPublicPostWhenCommentFails(t *testing.T) {
	ctx := context.Background()
	runtime, err := app.NewRuntime(config.Config{
		BrokerAgentName:       "broker",
		FixerAgentName:        "fixer",
		PresentationAgentName: "presentation_generator",
		DBPath:                ":memory:",
		LogLevel:              0,
	})
	if err != nil {
		t.Fatal(err)
	}
	defer runtime.Close()

	if err := runtime.SeedDemoData(ctx); err != nil {
		t.Fatal(err)
	}
	runtime.FakeClient.FailNext(domain.TransportModePublicComment, 1)

	if err := runtime.BrokerService.RunCycle(ctx); err != nil {
		t.Fatal(err)
	}

	tasks, err := runtime.Store.ListTasksByStatus(ctx, domain.TaskStatusContacted)
	if err != nil {
		t.Fatal(err)
	}
	if len(tasks) != 1 {
		t.Fatalf("expected contacted task after fallback, got %+v", tasks)
	}

	actions, err := runtime.Store.ListTransportActions(ctx, tasks[0].TaskID)
	if err != nil {
		t.Fatal(err)
	}
	if len(actions) != 2 {
		t.Fatalf("expected failed comment plus successful post, got %+v", actions)
	}
	if actions[0].Outcome != domain.TransportOutcomeFailed || actions[1].AttemptedMode != domain.TransportModePublicPost {
		t.Fatalf("unexpected action sequence: %+v", actions)
	}
}

func TestEnsureDefaultPortfolioSeedsDefaultExecutors(t *testing.T) {
	ctx := context.Background()
	runtime, err := app.NewRuntime(config.Config{
		BrokerAgentName:       "broker",
		FixerAgentName:        "fixer_live",
		PresentationAgentName: "presentation_live",
		DBPath:                ":memory:",
		LogLevel:              0,
	})
	if err != nil {
		t.Fatal(err)
	}
	defer runtime.Close()

	if err := runtime.EnsureDefaultPortfolio(ctx); err != nil {
		t.Fatal(err)
	}

	executors, err := runtime.Store.ListActiveExecutors(ctx)
	if err != nil {
		t.Fatal(err)
	}
	if len(executors) != 2 {
		t.Fatalf("expected two executors, got %+v", executors)
	}
	got := map[string]string{}
	for _, executor := range executors {
		got[executor.ExecutorID] = executor.BoltbookAgentName
	}
	if got["fixer"] != "fixer_live" {
		t.Fatalf("expected fixer agent name to be seeded from config, got %+v", got)
	}
	if got["presentation_generator"] != "presentation_live" {
		t.Fatalf("expected presentation agent name to be seeded from config, got %+v", got)
	}
}
