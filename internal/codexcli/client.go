package codexcli

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"boltbook-ai-dz/internal/domain"
)

type ResponseDraft struct {
	Decision domain.ResponseDecision `json:"decision"`
	Message  string                  `json:"message"`
}

type Client struct {
	CommandPath string
	HomeDir     string
	Model       string
	Timeout     time.Duration
}

func (c Client) DraftFixerResponse(ctx context.Context, lead domain.InboundLead, fallbackDecision domain.ResponseDecision, fallbackMessage string) (ResponseDraft, error) {
	if strings.TrimSpace(c.CommandPath) == "" {
		return ResponseDraft{}, fmt.Errorf("codex command path is required")
	}
	if strings.TrimSpace(c.HomeDir) == "" {
		return ResponseDraft{}, fmt.Errorf("codex home is required")
	}
	if strings.TrimSpace(c.Model) == "" {
		return ResponseDraft{}, fmt.Errorf("codex model is required")
	}

	timeout := c.Timeout
	if timeout <= 0 {
		timeout = 45 * time.Second
	}
	runCtx, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()

	tempDir, err := os.MkdirTemp("", "boltbook-codex-*")
	if err != nil {
		return ResponseDraft{}, err
	}
	defer os.RemoveAll(tempDir)

	outputPath := filepath.Join(tempDir, "response.json")
	schemaPath := filepath.Join(tempDir, "schema.json")
	if err := os.WriteFile(schemaPath, []byte(responseSchema), 0o600); err != nil {
		return ResponseDraft{}, err
	}

	args := []string{
		"exec",
		"--skip-git-repo-check",
		"--sandbox", "read-only",
		"--color", "never",
		"--model", c.Model,
		"--output-schema", schemaPath,
		"--output-last-message", outputPath,
		buildPrompt(lead, fallbackDecision, fallbackMessage),
	}

	cmd := exec.CommandContext(runCtx, c.CommandPath, args...)
	cmd.Env = append(os.Environ(), "HOME="+c.HomeDir)
	output, err := cmd.CombinedOutput()
	if err != nil {
		return ResponseDraft{}, fmt.Errorf("codex exec failed: %w: %s", err, strings.TrimSpace(string(output)))
	}

	raw, err := os.ReadFile(outputPath)
	if err != nil {
		return ResponseDraft{}, fmt.Errorf("read codex output: %w", err)
	}

	var draft ResponseDraft
	if err := json.Unmarshal(raw, &draft); err != nil {
		return ResponseDraft{}, fmt.Errorf("decode codex output: %w", err)
	}
	if draft.Decision == "" {
		return ResponseDraft{}, fmt.Errorf("codex output missing decision")
	}
	if strings.TrimSpace(draft.Message) == "" {
		return ResponseDraft{}, fmt.Errorf("codex output missing message")
	}
	return draft, nil
}

func buildPrompt(lead domain.InboundLead, fallbackDecision domain.ResponseDecision, fallbackMessage string) string {
	return fmt.Sprintf(`You are drafting a short Boltbook Fixer lead response.
Return a JSON object with exactly these keys:
- "decision": one of "acknowledge_fit", "request_clarification", "rough_estimate"
- "message": a single short plain-text response under 280 characters

Constraints:
- Be concrete and professional.
- Do not invent capabilities beyond Go implementation, debugging, MCP integration, SQLite, deployment, and clarification/rough estimate.
- Preserve the current deterministic intent unless the lead strongly suggests another allowed decision.
- No markdown, no emojis, no greeting, no signature.

Lead body:
%s

Lead source mode: %s
Broker agent: %s
Target agent: %s

Deterministic fallback decision: %s
Deterministic fallback message: %s
`, lead.Body, lead.SourceMode, lead.BrokerAgentName, lead.TargetAgentName, fallbackDecision, fallbackMessage)
}

const responseSchema = `{
  "type": "object",
  "additionalProperties": false,
  "required": ["decision", "message"],
  "properties": {
    "decision": {
      "type": "string",
      "enum": ["acknowledge_fit", "request_clarification", "rough_estimate"]
    },
    "message": {
      "type": "string",
      "minLength": 1,
      "maxLength": 280
    }
  }
}`
