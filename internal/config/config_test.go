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
	t.Setenv("BOLTBOOK_CODEX_TIMEOUT", "")
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

func TestLoadCodexConfig(t *testing.T) {
	t.Setenv("BOLTBOOK_RUN_ONCE", "")
	t.Setenv("BOLTBOOK_BROKER_POLL_INTERVAL", "")
	t.Setenv("BOLTBOOK_FIXER_POLL_INTERVAL", "")
	t.Setenv("BOLTBOOK_CODEX_TIMEOUT", "90s")
	t.Setenv("BOLTBOOK_LOG_LEVEL", "")
	t.Setenv("BOLTBOOK_INTAKE_LIMIT", "")
	t.Setenv("BOLTBOOK_FIXER_CODEX_ENABLED", "true")
	t.Setenv("BOLTBOOK_CODEX_CLI_PATH", "/usr/local/bin/codex")
	t.Setenv("BOLTBOOK_CODEX_HOME", "/var/lib/boltbook")
	t.Setenv("BOLTBOOK_CODEX_MODEL", "gpt-5.3-codex-spark")

	cfg, err := Load()
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}
	if !cfg.FixerCodexEnabled {
		t.Fatalf("expected FixerCodexEnabled to be true")
	}
	if cfg.CodexCLIPath != "/usr/local/bin/codex" {
		t.Fatalf("unexpected codex path: %q", cfg.CodexCLIPath)
	}
	if cfg.CodexHome != "/var/lib/boltbook" {
		t.Fatalf("unexpected codex home: %q", cfg.CodexHome)
	}
	if cfg.CodexModel != "gpt-5.3-codex-spark" {
		t.Fatalf("unexpected codex model: %q", cfg.CodexModel)
	}
	if cfg.CodexTimeout.Seconds() != 90 {
		t.Fatalf("unexpected codex timeout: %v", cfg.CodexTimeout)
	}
}

func TestLoadTargetedLiveControls(t *testing.T) {
	t.Setenv("BOLTBOOK_BROKER_INTAKE_FROM_FEED", "false")
	t.Setenv("BOLTBOOK_BROKER_INTAKE_FROM_SUBMOLTS", "false")
	t.Setenv("BOLTBOOK_BROKER_INTAKE_FROM_SEARCH", "true")
	t.Setenv("BOLTBOOK_FIXER_SEARCH_QUERIES", "trace-token")
	t.Setenv("BOLTBOOK_FIXER_INBOX_FROM_DMS", "false")
	t.Setenv("BOLTBOOK_BROKER_POLL_INTERVAL", "")
	t.Setenv("BOLTBOOK_FIXER_POLL_INTERVAL", "")
	t.Setenv("BOLTBOOK_CODEX_TIMEOUT", "")
	t.Setenv("BOLTBOOK_LOG_LEVEL", "")
	t.Setenv("BOLTBOOK_INTAKE_LIMIT", "")

	cfg, err := Load()
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}
	if cfg.BrokerIntakeFromFeed {
		t.Fatalf("expected broker feed polling to be disabled")
	}
	if cfg.BrokerIntakeFromSubmolts {
		t.Fatalf("expected broker submolt polling to be disabled")
	}
	if !cfg.BrokerIntakeFromSearch {
		t.Fatalf("expected broker search polling to remain enabled")
	}
	if len(cfg.FixerSearchQueries) != 1 || cfg.FixerSearchQueries[0] != "trace-token" {
		t.Fatalf("unexpected fixer search queries: %+v", cfg.FixerSearchQueries)
	}
	if cfg.FixerInboxFromDMs {
		t.Fatalf("expected fixer DM intake to be disabled")
	}
}

func TestLoadPresentationAgentNameDefaultAndOverride(t *testing.T) {
	t.Setenv("BOLTBOOK_BROKER_POLL_INTERVAL", "")
	t.Setenv("BOLTBOOK_FIXER_POLL_INTERVAL", "")
	t.Setenv("BOLTBOOK_CODEX_TIMEOUT", "")
	t.Setenv("BOLTBOOK_LOG_LEVEL", "")
	t.Setenv("BOLTBOOK_INTAKE_LIMIT", "")

	cfg, err := Load()
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}
	if cfg.PresentationAgentName != "presentation_generator" {
		t.Fatalf("expected default presentation agent name, got %q", cfg.PresentationAgentName)
	}

	t.Setenv("BOLTBOOK_PRESENTATION_AGENT_NAME", "decksmith")
	cfg, err = Load()
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}
	if cfg.PresentationAgentName != "decksmith" {
		t.Fatalf("expected overridden presentation agent name, got %q", cfg.PresentationAgentName)
	}
}
