package main

import (
	"context"
	"log"
	"time"

	"boltbook-ai-dz/internal/app"
	"boltbook-ai-dz/internal/config"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		log.Fatal(err)
	}
	runtime, err := app.NewRuntime(cfg)
	if err != nil {
		log.Fatal(err)
	}
	defer runtime.Close()

	ctx := context.Background()
	if err := runtime.EnsureDefaultPortfolio(ctx); err != nil {
		log.Fatal(err)
	}
	if cfg.DryRun {
		if err := runtime.SeedDemoData(ctx); err != nil {
			log.Fatal(err)
		}
	}
	if cfg.RunOnce {
		if err := runtime.BrokerService.RunCycle(ctx); err != nil {
			log.Fatal(err)
		}
		return
	}

	ticker := time.NewTicker(cfg.BrokerPollInterval)
	defer ticker.Stop()
	for {
		if err := runtime.BrokerService.RunCycle(ctx); err != nil {
			log.Fatal(err)
		}
		<-ticker.C
	}
}
