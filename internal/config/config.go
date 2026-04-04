package config

import (
	"fmt"
	"log/slog"
	"os"
	"strconv"
	"strings"
	"time"
)

type Config struct {
	BrokerAgentName     string
	FixerAgentName      string
	BoltbookClientMode  string
	BoltbookAPIKey      string
	BoltbookAPIBaseURL  string
	BoltbookSubmolt     string
	BoltbookIntakeLimit int
	BrokerIntakeFromFeed     bool
	BrokerIntakeFromSubmolts bool
	BrokerIntakeFromSearch   bool
	FixerSearchQueries       []string
	FixerInboxFromDMs        bool
	FixerCodexEnabled   bool
	CodexCLIPath        string
	CodexHome           string
	CodexModel          string
	CodexTimeout        time.Duration
	DBPath              string
	BrokerPollInterval  time.Duration
	FixerPollInterval   time.Duration
	LogLevel            slog.Level
	WatchedSubmolts     []string
	SearchQueries       []string
	DryRun              bool
	RunOnce             bool
}

func Load() (Config, error) {
	cfg := Config{
		BrokerAgentName:    envOr("BOLTBOOK_BROKER_AGENT_NAME", "boltbook_broker"),
		FixerAgentName:     envOr("BOLTBOOK_FIXER_AGENT_NAME", "fixer"),
		BoltbookClientMode: envOr("BOLTBOOK_CLIENT_MODE", "fake"),
		BoltbookAPIKey:     strings.TrimSpace(os.Getenv("BOLTBOOK_API_KEY")),
		BoltbookAPIBaseURL: envOr("BOLTBOOK_API_BASE_URL", "https://api.boltbook.ai"),
		BoltbookSubmolt:    envOr("BOLTBOOK_DEFAULT_SUBMOLT", "general"),
		BrokerIntakeFromFeed:     envBoolOr("BOLTBOOK_BROKER_INTAKE_FROM_FEED", true),
		BrokerIntakeFromSubmolts: envBoolOr("BOLTBOOK_BROKER_INTAKE_FROM_SUBMOLTS", true),
		BrokerIntakeFromSearch:   envBoolOr("BOLTBOOK_BROKER_INTAKE_FROM_SEARCH", true),
		FixerSearchQueries:       splitCSV(os.Getenv("BOLTBOOK_FIXER_SEARCH_QUERIES")),
		FixerInboxFromDMs:        envBoolOr("BOLTBOOK_FIXER_INBOX_FROM_DMS", true),
		FixerCodexEnabled:  parseBool(os.Getenv("BOLTBOOK_FIXER_CODEX_ENABLED")),
		CodexCLIPath:       envOr("BOLTBOOK_CODEX_CLI_PATH", "codex"),
		CodexHome:          strings.TrimSpace(os.Getenv("BOLTBOOK_CODEX_HOME")),
		CodexModel:         envOr("BOLTBOOK_CODEX_MODEL", "gpt-5.3-codex-spark"),
		DBPath:             envOr("BOLTBOOK_DB_PATH", "boltbook.db"),
		WatchedSubmolts:    splitCSV(os.Getenv("BOLTBOOK_WATCHED_SUBMOLTS")),
		SearchQueries:      splitCSV(os.Getenv("BOLTBOOK_SEARCH_QUERIES")),
		DryRun:             parseBool(os.Getenv("BOLTBOOK_DRY_RUN")),
		RunOnce:            parseBool(os.Getenv("BOLTBOOK_RUN_ONCE")),
	}

	var err error
	if cfg.BrokerPollInterval, err = parseDurationEnv("BOLTBOOK_BROKER_POLL_INTERVAL", 30*time.Second); err != nil {
		return Config{}, err
	}
	if cfg.FixerPollInterval, err = parseDurationEnv("BOLTBOOK_FIXER_POLL_INTERVAL", 45*time.Second); err != nil {
		return Config{}, err
	}
	if cfg.CodexTimeout, err = parseDurationEnv("BOLTBOOK_CODEX_TIMEOUT", 45*time.Second); err != nil {
		return Config{}, err
	}
	if cfg.LogLevel, err = parseLogLevel(envOr("BOLTBOOK_LOG_LEVEL", "info")); err != nil {
		return Config{}, err
	}
	if cfg.BoltbookIntakeLimit, err = parseIntEnv("BOLTBOOK_INTAKE_LIMIT", 20); err != nil {
		return Config{}, err
	}
	return cfg, nil
}

func envOr(key, fallback string) string {
	if value := strings.TrimSpace(os.Getenv(key)); value != "" {
		return value
	}
	return fallback
}

func splitCSV(raw string) []string {
	if strings.TrimSpace(raw) == "" {
		return nil
	}
	parts := strings.Split(raw, ",")
	out := make([]string, 0, len(parts))
	for _, part := range parts {
		part = strings.TrimSpace(part)
		if part != "" {
			out = append(out, part)
		}
	}
	return out
}

func parseBool(raw string) bool {
	ok, _ := strconv.ParseBool(strings.TrimSpace(raw))
	return ok
}

func envBoolOr(key string, fallback bool) bool {
	raw := strings.TrimSpace(os.Getenv(key))
	if raw == "" {
		return fallback
	}
	return parseBool(raw)
}

func parseDurationEnv(key string, fallback time.Duration) (time.Duration, error) {
	raw := strings.TrimSpace(os.Getenv(key))
	if raw == "" {
		return fallback, nil
	}
	d, err := time.ParseDuration(raw)
	if err != nil {
		return 0, fmt.Errorf("%s: %w", key, err)
	}
	return d, nil
}

func parseIntEnv(key string, fallback int) (int, error) {
	raw := strings.TrimSpace(os.Getenv(key))
	if raw == "" {
		return fallback, nil
	}
	value, err := strconv.Atoi(raw)
	if err != nil {
		return 0, fmt.Errorf("%s: %w", key, err)
	}
	if value <= 0 {
		return 0, fmt.Errorf("%s: must be > 0", key)
	}
	return value, nil
}

func parseLogLevel(raw string) (slog.Level, error) {
	switch strings.ToLower(strings.TrimSpace(raw)) {
	case "debug":
		return slog.LevelDebug, nil
	case "info":
		return slog.LevelInfo, nil
	case "warn":
		return slog.LevelWarn, nil
	case "error":
		return slog.LevelError, nil
	default:
		return 0, fmt.Errorf("unsupported log level %q", raw)
	}
}
