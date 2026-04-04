package domain

import "time"

type AvailabilityState string

const (
	AvailabilityActive   AvailabilityState = "active"
	AvailabilityInactive AvailabilityState = "inactive"
)

type TaskStatus string

const (
	TaskStatusNew           TaskStatus = "new"
	TaskStatusMatched       TaskStatus = "matched"
	TaskStatusContacted     TaskStatus = "contacted"
	TaskStatusAwaitingReply TaskStatus = "awaiting_reply"
	TaskStatusClosed        TaskStatus = "closed"
	TaskStatusDeferred      TaskStatus = "deferred"
)

type TransportMode string

const (
	TransportModePublicComment TransportMode = "public_comment"
	TransportModePublicPost    TransportMode = "public_post"
	TransportModeDMRequest     TransportMode = "dm_request"
	TransportModeDMMessage     TransportMode = "approved_dm_conversation"
)

type TransportOutcome string

const (
	TransportOutcomeSent             TransportOutcome = "sent"
	TransportOutcomeFailed           TransportOutcome = "failed"
	TransportOutcomeDeferred         TransportOutcome = "deferred"
	TransportOutcomeAwaitingApproval TransportOutcome = "awaiting_approval"
)

type SourceType string

const (
	SourceTypeBoltbookPost    SourceType = "boltbook_post"
	SourceTypeBoltbookMention SourceType = "boltbook_mention"
	SourceTypeManualSeed      SourceType = "manual_seed"
)

type DeliveryPreference string

const (
	DeliveryPreferencePublicFirst DeliveryPreference = "public_first"
	DeliveryPreferenceFlexible    DeliveryPreference = "flexible"
)

type ResponseDecision string

const (
	ResponseDecisionAcknowledgeFit      ResponseDecision = "acknowledge_fit"
	ResponseDecisionRequestClarify      ResponseDecision = "request_clarification"
	ResponseDecisionPreliminaryEstimate ResponseDecision = "rough_estimate"
)

type PortfolioEvidence struct {
	Kind      string `json:"kind"`
	SourceURL string `json:"source_url"`
	Excerpt   string `json:"excerpt"`
}

type TrustSignals struct {
	OperatorCurated bool      `json:"operator_curated"`
	LastValidatedAt time.Time `json:"last_validated_at"`
}

type ExecutorPortfolio struct {
	ExecutorID           string              `json:"executor_id"`
	BoltbookAgentName    string              `json:"boltbook_agent_name"`
	DisplayName          string              `json:"display_name"`
	Summary              string              `json:"summary"`
	CapabilityTags       []string            `json:"capability_tags"`
	ServiceModes         []string            `json:"service_modes"`
	TransportPreferences []TransportMode     `json:"transport_preferences"`
	AvailabilityState    AvailabilityState   `json:"availability_state"`
	PortfolioEvidence    []PortfolioEvidence `json:"portfolio_evidence"`
	TrustSignals         TrustSignals        `json:"trust_signals"`
	CreatedAt            time.Time           `json:"created_at"`
	UpdatedAt            time.Time           `json:"updated_at"`
}

type SourceRef struct {
	PostID     string `json:"post_id,omitempty"`
	URL        string `json:"url,omitempty"`
	AuthorName string `json:"author_name,omitempty"`
	ThreadID   string `json:"thread_id,omitempty"`
}

type Task struct {
	TaskID             string             `json:"task_id"`
	SourceType         SourceType         `json:"source_type"`
	SourceRef          SourceRef          `json:"source_ref"`
	RequesterAgentName string             `json:"requester_agent_name"`
	Title              string             `json:"title"`
	Body               string             `json:"body"`
	TaskTags           []string           `json:"task_tags"`
	DeliveryPreference DeliveryPreference `json:"delivery_preference"`
	Status             TaskStatus         `json:"status"`
	IngestedAt         time.Time          `json:"ingested_at"`
}

type MatchCandidate struct {
	Rank       int      `json:"rank"`
	ExecutorID string   `json:"executor_id"`
	Score      float64  `json:"score"`
	FitSummary string   `json:"fit_summary"`
	FitReasons []string `json:"fit_reasons"`
	Risks      []string `json:"risks"`
}

type MatchResult struct {
	ResultID        string           `json:"result_id"`
	TaskID          string           `json:"task_id"`
	GeneratedAt     time.Time        `json:"generated_at"`
	Candidates      []MatchCandidate `json:"candidates"`
	SelectionReason string           `json:"selection_reason"`
}

type BrokerRecommendation struct {
	Score      float64 `json:"score"`
	FitSummary string  `json:"fit_summary"`
}

type TaskContext struct {
	Title    string   `json:"title"`
	Body     string   `json:"body"`
	TaskTags []string `json:"task_tags"`
}

type TransportPlan struct {
	PrimaryMode   TransportMode   `json:"primary_mode"`
	FallbackModes []TransportMode `json:"fallback_modes"`
}

type Colloquium struct {
	Mode       string   `json:"mode"`
	Evaluators []string `json:"evaluators"`
	Aggregator string   `json:"aggregator"`
}

type Handoff struct {
	HandoffID            string               `json:"handoff_id"`
	TaskID               string               `json:"task_id"`
	SelectedExecutorID   string               `json:"selected_executor_id"`
	BrokerRecommendation BrokerRecommendation `json:"broker_recommendation"`
	TaskContext          TaskContext          `json:"task_context"`
	TransportPlan        TransportPlan        `json:"transport_plan"`
	Colloquium           Colloquium           `json:"colloquium"`
	CreatedAt            time.Time            `json:"created_at"`
}

type TargetRef struct {
	PostID         string `json:"post_id,omitempty"`
	PostURL        string `json:"post_url,omitempty"`
	ThreadID       string `json:"thread_id,omitempty"`
	ConversationID string `json:"conversation_id,omitempty"`
}

type TransportAction struct {
	TransportID           string           `json:"transport_id"`
	TaskID                string           `json:"task_id"`
	HandoffID             string           `json:"handoff_id"`
	AttemptedMode         TransportMode    `json:"attempted_mode"`
	TargetAgentName       string           `json:"target_agent_name"`
	TargetRef             TargetRef        `json:"target_ref"`
	RequestPayloadExcerpt string           `json:"request_payload_excerpt"`
	Outcome               TransportOutcome `json:"outcome"`
	ProviderStatusCode    int              `json:"provider_status_code"`
	ProviderRef           string           `json:"provider_ref"`
	AttemptedAt           time.Time        `json:"attempted_at"`
}

type RunHistory struct {
	RunID     string    `json:"run_id"`
	Component string    `json:"component"`
	Status    string    `json:"status"`
	StartedAt time.Time `json:"started_at"`
	EndedAt   time.Time `json:"ended_at"`
	Examined  int       `json:"examined"`
	Processed int       `json:"processed"`
	ErrorText string    `json:"error_text,omitempty"`
}

type StructuredLog struct {
	LogID       string    `json:"log_id"`
	RunID       string    `json:"run_id"`
	Component   string    `json:"component"`
	Level       string    `json:"level"`
	Event       string    `json:"event"`
	TaskID      string    `json:"task_id,omitempty"`
	ExecutorID  string    `json:"executor_id,omitempty"`
	HandoffID   string    `json:"handoff_id,omitempty"`
	TransportID string    `json:"transport_id,omitempty"`
	Message     string    `json:"message"`
	Timestamp   time.Time `json:"timestamp"`
}

type InboundLead struct {
	LeadID          string        `json:"lead_id"`
	TaskID          string        `json:"task_id"`
	HandoffID       string        `json:"handoff_id"`
	SourceMode      TransportMode `json:"source_mode"`
	BrokerAgentName string        `json:"broker_agent_name"`
	TargetAgentName string        `json:"target_agent_name"`
	Body            string        `json:"body"`
	ThreadRef       TargetRef     `json:"thread_ref"`
	ReceivedAt      time.Time     `json:"received_at"`
}

type FixerResponseAction struct {
	ResponseID         string           `json:"response_id"`
	LeadID             string           `json:"lead_id"`
	TaskID             string           `json:"task_id"`
	Decision           ResponseDecision `json:"decision"`
	Message            string           `json:"message"`
	ResponseMode       TransportMode    `json:"response_mode"`
	ProviderStatusCode int              `json:"provider_status_code"`
	ProviderRef        string           `json:"provider_ref"`
	RespondedAt        time.Time        `json:"responded_at"`
}
