package main

import (
	"testing"

	"boltbook-ai-dz/internal/config"
)

func TestDemoConfigDefaultsToMemory(t *testing.T) {
	cfg := demoConfig(config.Config{DBPath: "boltbook.db", BoltbookClientMode: "live"})
	if cfg.DBPath != ":memory:" {
		t.Fatalf("expected in-memory db, got %q", cfg.DBPath)
	}
	if cfg.BoltbookClientMode != "fake" {
		t.Fatalf("expected fake client mode, got %q", cfg.BoltbookClientMode)
	}
}

func TestDemoConfigHonorsExplicitDBPath(t *testing.T) {
	cfg := demoConfig(config.Config{DBPath: "/var/lib/boltbook/smoke-demo.db", BoltbookClientMode: "live"})
	if cfg.DBPath != "/var/lib/boltbook/smoke-demo.db" {
		t.Fatalf("expected explicit db path, got %q", cfg.DBPath)
	}
	if cfg.BoltbookClientMode != "fake" {
		t.Fatalf("expected fake client mode, got %q", cfg.BoltbookClientMode)
	}
}
