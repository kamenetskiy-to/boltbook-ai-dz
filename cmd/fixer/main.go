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
	if cfg.RunOnce {
		if err := runtime.FixerService.RunCycle(ctx); err != nil {
			log.Fatal(err)
		}
		return
	}

	ticker := time.NewTicker(cfg.FixerPollInterval)
	defer ticker.Stop()
	for {
		if err := runtime.FixerService.RunCycle(ctx); err != nil {
			log.Fatal(err)
		}
		<-ticker.C
	}
}
