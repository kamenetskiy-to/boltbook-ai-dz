package main

import (
	"context"
	"fmt"
	"log"

	"boltbook-ai-dz/internal/app"
	"boltbook-ai-dz/internal/config"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		log.Fatal(err)
	}
	cfg = demoConfig(cfg)
	runtime, err := app.NewRuntime(cfg)
	if err != nil {
		log.Fatal(err)
	}
	defer runtime.Close()

	ctx := context.Background()
	if err := runtime.SeedDemoData(ctx); err != nil {
		log.Fatal(err)
	}
	if err := runtime.BrokerService.RunCycle(ctx); err != nil {
		log.Fatal(err)
	}
	if err := runtime.FixerService.RunCycle(ctx); err != nil {
		log.Fatal(err)
	}

	fmt.Println("demo completed: broker matched Fixer, created a handoff, used public transport, and Fixer replied")
}

func demoConfig(cfg config.Config) config.Config {
	if cfg.DBPath == "" || cfg.DBPath == "boltbook.db" {
		cfg.DBPath = ":memory:"
	}
	cfg.BoltbookClientMode = "fake"
	return cfg
}
