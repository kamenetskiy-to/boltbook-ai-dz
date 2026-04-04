package storage

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"

	_ "modernc.org/sqlite"

	"boltbook-ai-dz/internal/domain"
)

type Store struct {
	db *sql.DB
}

func Open(path string) (*Store, error) {
	dsn := fmt.Sprintf("%s?_busy_timeout=5000&_foreign_keys=on&_journal_mode=WAL", path)
	db, err := sql.Open("sqlite", dsn)
	if err != nil {
		return nil, err
	}
	db.SetMaxOpenConns(1)
	db.SetMaxIdleConns(1)

	store := &Store{db: db}
	if err := store.configure(context.Background()); err != nil {
		_ = db.Close()
		return nil, err
	}
	if err := store.init(context.Background()); err != nil {
		_ = db.Close()
		return nil, err
	}
	return store, nil
}

func (s *Store) Close() error {
	return s.db.Close()
}

func (s *Store) configure(ctx context.Context) error {
	stmts := []string{
		`PRAGMA busy_timeout = 15000;`,
		`PRAGMA foreign_keys = ON;`,
		`PRAGMA journal_mode = WAL;`,
		`PRAGMA synchronous = NORMAL;`,
	}
	for _, stmt := range stmts {
		if _, err := s.db.ExecContext(ctx, stmt); err != nil {
			return err
		}
	}
	return nil
}

func (s *Store) init(ctx context.Context) error {
	stmts := []string{
		`CREATE TABLE IF NOT EXISTS executors (
			executor_id TEXT PRIMARY KEY,
			boltbook_agent_name TEXT NOT NULL,
			display_name TEXT NOT NULL,
			availability_state TEXT NOT NULL,
			capability_tags_json TEXT NOT NULL,
			service_modes_json TEXT NOT NULL,
			transport_preferences_json TEXT NOT NULL,
			payload_json TEXT NOT NULL,
			updated_at TIMESTAMP NOT NULL
		);`,
		`CREATE TABLE IF NOT EXISTS tasks (
			task_id TEXT PRIMARY KEY,
			status TEXT NOT NULL,
			source_type TEXT NOT NULL,
			requester_agent_name TEXT NOT NULL,
			title TEXT NOT NULL,
			body TEXT NOT NULL,
			delivery_preference TEXT NOT NULL,
			task_tags_json TEXT NOT NULL,
			source_ref_json TEXT NOT NULL,
			payload_json TEXT NOT NULL,
			ingested_at TIMESTAMP NOT NULL
		);`,
		`CREATE TABLE IF NOT EXISTS match_results (
			result_id TEXT PRIMARY KEY,
			task_id TEXT NOT NULL,
			generated_at TIMESTAMP NOT NULL,
			payload_json TEXT NOT NULL
		);`,
		`CREATE TABLE IF NOT EXISTS handoffs (
			handoff_id TEXT PRIMARY KEY,
			task_id TEXT NOT NULL,
			selected_executor_id TEXT NOT NULL,
			created_at TIMESTAMP NOT NULL,
			payload_json TEXT NOT NULL
		);`,
		`CREATE TABLE IF NOT EXISTS transport_actions (
			transport_id TEXT PRIMARY KEY,
			task_id TEXT NOT NULL,
			handoff_id TEXT NOT NULL,
			attempted_mode TEXT NOT NULL,
			target_agent_name TEXT NOT NULL,
			outcome TEXT NOT NULL,
			provider_ref TEXT NOT NULL,
			attempted_at TIMESTAMP NOT NULL,
			payload_json TEXT NOT NULL
		);`,
		`CREATE TABLE IF NOT EXISTS run_history (
			run_id TEXT PRIMARY KEY,
			component TEXT NOT NULL,
			status TEXT NOT NULL,
			started_at TIMESTAMP NOT NULL,
			ended_at TIMESTAMP NOT NULL,
			examined INTEGER NOT NULL,
			processed INTEGER NOT NULL,
			error_text TEXT NOT NULL
		);`,
		`CREATE TABLE IF NOT EXISTS structured_logs (
			log_id TEXT PRIMARY KEY,
			component TEXT NOT NULL,
			run_id TEXT NOT NULL,
			level TEXT NOT NULL,
			event TEXT NOT NULL,
			task_id TEXT NOT NULL,
			executor_id TEXT NOT NULL,
			handoff_id TEXT NOT NULL,
			transport_id TEXT NOT NULL,
			message TEXT NOT NULL,
			timestamp TIMESTAMP NOT NULL,
			payload_json TEXT NOT NULL
		);`,
		`CREATE TABLE IF NOT EXISTS fixer_response_actions (
			response_id TEXT PRIMARY KEY,
			lead_id TEXT NOT NULL,
			task_id TEXT NOT NULL,
			decision TEXT NOT NULL,
			response_mode TEXT NOT NULL,
			provider_ref TEXT NOT NULL,
			responded_at TIMESTAMP NOT NULL,
			payload_json TEXT NOT NULL
		);`,
	}
	for _, stmt := range stmts {
		if _, err := s.db.ExecContext(ctx, stmt); err != nil {
			return err
		}
	}
	return nil
}

func (s *Store) UpsertExecutor(ctx context.Context, executor domain.ExecutorPortfolio) error {
	payload, err := marshal(executor)
	if err != nil {
		return err
	}
	if executor.UpdatedAt.IsZero() {
		executor.UpdatedAt = time.Now().UTC()
	}
	_, err = s.db.ExecContext(ctx, `
		INSERT INTO executors (executor_id, boltbook_agent_name, display_name, availability_state, capability_tags_json, service_modes_json, transport_preferences_json, payload_json, updated_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
		ON CONFLICT(executor_id) DO UPDATE SET
			boltbook_agent_name=excluded.boltbook_agent_name,
			display_name=excluded.display_name,
			availability_state=excluded.availability_state,
			capability_tags_json=excluded.capability_tags_json,
			service_modes_json=excluded.service_modes_json,
			transport_preferences_json=excluded.transport_preferences_json,
			payload_json=excluded.payload_json,
			updated_at=excluded.updated_at
	`, executor.ExecutorID, executor.BoltbookAgentName, executor.DisplayName, executor.AvailabilityState, mustJSON(executor.CapabilityTags), mustJSON(executor.ServiceModes), mustJSON(executor.TransportPreferences), payload, executor.UpdatedAt)
	return err
}

func (s *Store) ListActiveExecutors(ctx context.Context) ([]domain.ExecutorPortfolio, error) {
	rows, err := s.db.QueryContext(ctx, `SELECT payload_json FROM executors WHERE availability_state = ? ORDER BY updated_at DESC`, domain.AvailabilityActive)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var out []domain.ExecutorPortfolio
	for rows.Next() {
		var payload string
		if err := rows.Scan(&payload); err != nil {
			return nil, err
		}
		var executor domain.ExecutorPortfolio
		if err := json.Unmarshal([]byte(payload), &executor); err != nil {
			return nil, err
		}
		out = append(out, executor)
	}
	return out, rows.Err()
}

func (s *Store) CreateTask(ctx context.Context, task domain.Task) error {
	payload, err := marshal(task)
	if err != nil {
		return err
	}
	_, err = s.db.ExecContext(ctx, `
		INSERT INTO tasks (task_id, status, source_type, requester_agent_name, title, body, delivery_preference, task_tags_json, source_ref_json, payload_json, ingested_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		ON CONFLICT(task_id) DO NOTHING
	`, task.TaskID, task.Status, task.SourceType, task.RequesterAgentName, task.Title, task.Body, task.DeliveryPreference, mustJSON(task.TaskTags), mustJSON(task.SourceRef), payload, task.IngestedAt)
	return err
}

func (s *Store) GetTask(ctx context.Context, taskID string) (domain.Task, error) {
	var payload string
	err := s.db.QueryRowContext(ctx, `SELECT payload_json FROM tasks WHERE task_id = ?`, taskID).Scan(&payload)
	if err != nil {
		return domain.Task{}, err
	}
	var task domain.Task
	if err := json.Unmarshal([]byte(payload), &task); err != nil {
		return domain.Task{}, err
	}
	return task, nil
}

func (s *Store) ListTasksByStatus(ctx context.Context, statuses ...domain.TaskStatus) ([]domain.Task, error) {
	if len(statuses) == 0 {
		return nil, errors.New("at least one status is required")
	}
	placeholders := make([]string, 0, len(statuses))
	args := make([]any, 0, len(statuses))
	for _, status := range statuses {
		placeholders = append(placeholders, "?")
		args = append(args, status)
	}
	query := fmt.Sprintf(`SELECT payload_json FROM tasks WHERE status IN (%s) ORDER BY ingested_at ASC`, strings.Join(placeholders, ","))
	rows, err := s.db.QueryContext(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var out []domain.Task
	for rows.Next() {
		var payload string
		if err := rows.Scan(&payload); err != nil {
			return nil, err
		}
		var task domain.Task
		if err := json.Unmarshal([]byte(payload), &task); err != nil {
			return nil, err
		}
		out = append(out, task)
	}
	return out, rows.Err()
}

func (s *Store) UpdateTaskStatus(ctx context.Context, taskID string, status domain.TaskStatus) error {
	task, err := s.GetTask(ctx, taskID)
	if err != nil {
		return err
	}
	task.Status = status
	payload, err := marshal(task)
	if err != nil {
		return err
	}
	_, err = s.db.ExecContext(ctx, `UPDATE tasks SET status = ?, payload_json = ? WHERE task_id = ?`, status, payload, taskID)
	return err
}

func (s *Store) SaveMatchResult(ctx context.Context, result domain.MatchResult) error {
	payload, err := marshal(result)
	if err != nil {
		return err
	}
	_, err = s.db.ExecContext(ctx, `INSERT INTO match_results (result_id, task_id, generated_at, payload_json) VALUES (?, ?, ?, ?)`, result.ResultID, result.TaskID, result.GeneratedAt, payload)
	return err
}

func (s *Store) SaveHandoff(ctx context.Context, handoff domain.Handoff) error {
	payload, err := marshal(handoff)
	if err != nil {
		return err
	}
	_, err = s.db.ExecContext(ctx, `INSERT INTO handoffs (handoff_id, task_id, selected_executor_id, created_at, payload_json) VALUES (?, ?, ?, ?, ?)`, handoff.HandoffID, handoff.TaskID, handoff.SelectedExecutorID, handoff.CreatedAt, payload)
	return err
}

func (s *Store) GetHandoff(ctx context.Context, handoffID string) (domain.Handoff, error) {
	var payload string
	err := s.db.QueryRowContext(ctx, `SELECT payload_json FROM handoffs WHERE handoff_id = ?`, handoffID).Scan(&payload)
	if err != nil {
		return domain.Handoff{}, err
	}
	var handoff domain.Handoff
	if err := json.Unmarshal([]byte(payload), &handoff); err != nil {
		return domain.Handoff{}, err
	}
	return handoff, nil
}

func (s *Store) SaveTransportAction(ctx context.Context, action domain.TransportAction) error {
	payload, err := marshal(action)
	if err != nil {
		return err
	}
	_, err = s.db.ExecContext(ctx, `INSERT INTO transport_actions (transport_id, task_id, handoff_id, attempted_mode, target_agent_name, outcome, provider_ref, attempted_at, payload_json) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`, action.TransportID, action.TaskID, action.HandoffID, action.AttemptedMode, action.TargetAgentName, action.Outcome, action.ProviderRef, action.AttemptedAt, payload)
	return err
}

func (s *Store) ListTransportActions(ctx context.Context, taskID string) ([]domain.TransportAction, error) {
	rows, err := s.db.QueryContext(ctx, `SELECT payload_json FROM transport_actions WHERE task_id = ? ORDER BY attempted_at ASC`, taskID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []domain.TransportAction
	for rows.Next() {
		var payload string
		if err := rows.Scan(&payload); err != nil {
			return nil, err
		}
		var action domain.TransportAction
		if err := json.Unmarshal([]byte(payload), &action); err != nil {
			return nil, err
		}
		out = append(out, action)
	}
	return out, rows.Err()
}

func (s *Store) SaveRunHistory(ctx context.Context, run domain.RunHistory) error {
	_, err := s.db.ExecContext(ctx, `INSERT INTO run_history (run_id, component, status, started_at, ended_at, examined, processed, error_text) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`, run.RunID, run.Component, run.Status, run.StartedAt, run.EndedAt, run.Examined, run.Processed, run.ErrorText)
	return err
}

func (s *Store) SaveStructuredLog(ctx context.Context, record domain.StructuredLog) error {
	payload, err := marshal(record)
	if err != nil {
		return err
	}
	_, err = s.db.ExecContext(ctx, `INSERT INTO structured_logs (log_id, component, run_id, level, event, task_id, executor_id, handoff_id, transport_id, message, timestamp, payload_json) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`, record.LogID, record.Component, record.RunID, record.Level, record.Event, record.TaskID, record.ExecutorID, record.HandoffID, record.TransportID, record.Message, record.Timestamp, payload)
	return err
}

func (s *Store) SaveFixerResponse(ctx context.Context, action domain.FixerResponseAction) error {
	payload, err := marshal(action)
	if err != nil {
		return err
	}
	_, err = s.db.ExecContext(ctx, `INSERT INTO fixer_response_actions (response_id, lead_id, task_id, decision, response_mode, provider_ref, responded_at, payload_json) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`, action.ResponseID, action.LeadID, action.TaskID, action.Decision, action.ResponseMode, action.ProviderRef, action.RespondedAt, payload)
	return err
}

func (s *Store) ListFixerResponses(ctx context.Context) ([]domain.FixerResponseAction, error) {
	rows, err := s.db.QueryContext(ctx, `SELECT payload_json FROM fixer_response_actions ORDER BY responded_at ASC`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []domain.FixerResponseAction
	for rows.Next() {
		var payload string
		if err := rows.Scan(&payload); err != nil {
			return nil, err
		}
		var action domain.FixerResponseAction
		if err := json.Unmarshal([]byte(payload), &action); err != nil {
			return nil, err
		}
		out = append(out, action)
	}
	return out, rows.Err()
}

func marshal(v any) (string, error) {
	data, err := json.Marshal(v)
	if err != nil {
		return "", err
	}
	return string(data), nil
}

func mustJSON(v any) string {
	data, err := json.Marshal(v)
	if err != nil {
		panic(err)
	}
	return string(data)
}
