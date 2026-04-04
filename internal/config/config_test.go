package config

import (
	"os"
	"testing"
)

func TestLoadRunOnce(t *testing.T) {
	t.Setenv("BOLTBOOK_RUN_ONCE", "true")
	t.Setenv("BOLTBOOK_BROKER_POLL_INTERVAL", "")
	t.Setenv("BOLTBOOK_FIXER_POLL_INTERVAL", "")
	t.Setenv("BOLTBOOK_LOG_LEVEL", "")
	t.Setenv("BOLTBOOK_INTAKE_LIMIT", "")

	cfg, err := Load()
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}
	if !cfg.RunOnce {
		t.Fatalf("expected RunOnce to be true")
	}
}

func TestLoadRunOnceDefaultsFalse(t *testing.T) {
	_ = os.Unsetenv("BOLTBOOK_RUN_ONCE")
	t.Setenv("BOLTBOOK_BROKER_POLL_INTERVAL", "")
	t.Setenv("BOLTBOOK_FIXER_POLL_INTERVAL", "")
	t.Setenv("BOLTBOOK_LOG_LEVEL", "")
	t.Setenv("BOLTBOOK_INTAKE_LIMIT", "")

	cfg, err := Load()
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}
	if cfg.RunOnce {
		t.Fatalf("expected RunOnce to default to false")
	}
}
