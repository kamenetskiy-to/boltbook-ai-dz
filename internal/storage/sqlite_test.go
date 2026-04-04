package storage_test

import (
	"context"
	"fmt"
	"path/filepath"
	"sync"
	"testing"
	"time"

	"boltbook-ai-dz/internal/domain"
	"boltbook-ai-dz/internal/storage"
)

func TestStoreRoundTripsExecutorTaskAndTransport(t *testing.T) {
	ctx := context.Background()
	store, err := storage.Open(filepath.Join(t.TempDir(), "boltbook.db"))
	if err != nil {
		t.Fatal(err)
	}
	defer store.Close()

	executor := domain.ExecutorPortfolio{
		ExecutorID:        "fixer",
		BoltbookAgentName: "fixer",
		DisplayName:       "Fixer",
		CapabilityTags:    []string{"golang"},
		ServiceModes:      []string{"lead_intake"},
		TransportPreferences: []domain.TransportMode{
			domain.TransportModePublicComment,
		},
		AvailabilityState: domain.AvailabilityActive,
		CreatedAt:         time.Now().UTC(),
		UpdatedAt:         time.Now().UTC(),
	}
	if err := store.UpsertExecutor(ctx, executor); err != nil {
		t.Fatal(err)
	}

	executors, err := store.ListActiveExecutors(ctx)
	if err != nil {
		t.Fatal(err)
	}
	if len(executors) != 1 || executors[0].ExecutorID != "fixer" {
		t.Fatalf("unexpected executors: %+v", executors)
	}

	task := domain.Task{
		TaskID:             "task_1",
		SourceType:         domain.SourceTypeManualSeed,
		RequesterAgentName: "operator",
		Title:              "test",
		Body:               "body",
		DeliveryPreference: domain.DeliveryPreferencePublicFirst,
		Status:             domain.TaskStatusNew,
		IngestedAt:         time.Now().UTC(),
	}
	if err := store.CreateTask(ctx, task); err != nil {
		t.Fatal(err)
	}
	if err := store.UpdateTaskStatus(ctx, task.TaskID, domain.TaskStatusContacted); err != nil {
		t.Fatal(err)
	}

	loaded, err := store.GetTask(ctx, task.TaskID)
	if err != nil {
		t.Fatal(err)
	}
	if loaded.Status != domain.TaskStatusContacted {
		t.Fatalf("expected updated task status, got %s", loaded.Status)
	}

	action := domain.TransportAction{
		TransportID:     "transport_1",
		TaskID:          task.TaskID,
		HandoffID:       "handoff_1",
		AttemptedMode:   domain.TransportModePublicComment,
		TargetAgentName: "fixer",
		Outcome:         domain.TransportOutcomeSent,
		ProviderRef:     "comment_1",
		AttemptedAt:     time.Now().UTC(),
	}
	if err := store.SaveTransportAction(ctx, action); err != nil {
		t.Fatal(err)
	}
	actions, err := store.ListTransportActions(ctx, task.TaskID)
	if err != nil {
		t.Fatal(err)
	}
	if len(actions) != 1 || actions[0].ProviderRef != "comment_1" {
		t.Fatalf("unexpected transport actions: %+v", actions)
	}
}

func TestStoreConcurrentWritersShareFile(t *testing.T) {
	ctx := context.Background()
	dbPath := filepath.Join(t.TempDir(), "boltbook.db")

	storeA, err := storage.Open(dbPath)
	if err != nil {
		t.Fatal(err)
	}
	defer storeA.Close()

	storeB, err := storage.Open(dbPath)
	if err != nil {
		t.Fatal(err)
	}
	defer storeB.Close()

	start := make(chan struct{})
	errCh := make(chan error, 2)
	var wg sync.WaitGroup

	runWriter := func(prefix string, store *storage.Store) {
		defer wg.Done()
		<-start
		for i := 0; i < 25; i++ {
			err := store.SaveRunHistory(ctx, domain.RunHistory{
				RunID:     fmt.Sprintf("%s_%d", prefix, i),
				Component: prefix,
				Status:    "completed",
				StartedAt: time.Now().UTC(),
				EndedAt:   time.Now().UTC(),
				Examined:  i,
				Processed: i,
			})
			if err != nil {
				errCh <- err
				return
			}
		}
	}

	wg.Add(2)
	go runWriter("broker", storeA)
	go runWriter("fixer", storeB)
	close(start)
	wg.Wait()
	close(errCh)

	for err := range errCh {
		if err != nil {
			t.Fatalf("concurrent writer error: %v", err)
		}
	}
}
