package boltbook

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"path"
	"strconv"
	"strings"
	"sync"
	"time"

	"boltbook-ai-dz/internal/core"
	"boltbook-ai-dz/internal/domain"
)

const defaultIntakeLimit = 20

type APIError struct {
	Method string
	Path   string
	Status int
	Body   string
}

func (e *APIError) Error() string {
	return fmt.Sprintf("boltbook API %s %s returned %d: %s", e.Method, e.Path, e.Status, strings.TrimSpace(e.Body))
}

type HTTPClient struct {
	baseURL         string
	siteURL         string
	apiKey          string
	defaultSubmolt  string
	watchedSubmolts []string
	searchQueries   []string
	intakeLimit     int
	httpClient      *http.Client
	brokerIntakeFromFeed     bool
	brokerIntakeFromSubmolts bool
	brokerIntakeFromSearch   bool
	fixerSearchQueries       []string
	fixerInboxFromDMs        bool

	mu        sync.Mutex
	seenTasks map[string]struct{}
	seenLeads map[string]struct{}
}

type LiveClientOptions struct {
	BrokerIntakeFromFeed     bool
	BrokerIntakeFromSubmolts bool
	BrokerIntakeFromSearch   bool
	FixerSearchQueries       []string
	FixerInboxFromDMs        bool
}

func NewHTTPClient(baseURL, apiKey, defaultSubmolt string, watchedSubmolts, searchQueries []string, intakeLimit int, options LiveClientOptions) (*HTTPClient, error) {
	baseURL = strings.TrimRight(strings.TrimSpace(baseURL), "/")
	if baseURL == "" {
		return nil, errors.New("boltbook API base URL is required")
	}
	if strings.TrimSpace(apiKey) == "" {
		return nil, errors.New("BOLTBOOK_API_KEY is required in live mode")
	}
	if intakeLimit <= 0 {
		intakeLimit = defaultIntakeLimit
	}
	if strings.TrimSpace(defaultSubmolt) == "" {
		defaultSubmolt = "general"
	}
	options = normalizeLiveClientOptions(options)
	return &HTTPClient{
		baseURL:         baseURL,
		siteURL:         deriveSiteURL(baseURL),
		apiKey:          strings.TrimSpace(apiKey),
		defaultSubmolt:  strings.TrimSpace(defaultSubmolt),
		watchedSubmolts: append([]string(nil), watchedSubmolts...),
		searchQueries:   append([]string(nil), searchQueries...),
		intakeLimit:     intakeLimit,
		brokerIntakeFromFeed:     options.BrokerIntakeFromFeed,
		brokerIntakeFromSubmolts: options.BrokerIntakeFromSubmolts,
		brokerIntakeFromSearch:   options.BrokerIntakeFromSearch,
		fixerSearchQueries:       append([]string(nil), options.FixerSearchQueries...),
		fixerInboxFromDMs:        options.FixerInboxFromDMs,
		httpClient: &http.Client{
			Timeout: 15 * time.Second,
		},
		seenTasks: make(map[string]struct{}),
		seenLeads: make(map[string]struct{}),
	}, nil
}

func (c *HTTPClient) PollBrokerIntake(ctx context.Context, brokerAgent string) ([]domain.Task, error) {
	var discovered []domain.Task

	if c.brokerIntakeFromFeed {
		feed, err := c.getFeed(ctx)
		if err != nil {
			return nil, err
		}
		for _, post := range feed.Posts {
			task, ok := c.taskFromPost(post, brokerAgent)
			if ok {
				discovered = append(discovered, task)
			}
		}
	}

	if c.brokerIntakeFromSubmolts {
		for _, submolt := range c.watchedSubmolts {
			feed, err := c.getSubmoltFeed(ctx, submolt)
			if err != nil {
				if isIgnorableSubmoltError(err) {
					continue
				}
				return nil, err
			}
			for _, post := range feed.Posts {
				task, ok := c.taskFromPost(post, brokerAgent)
				if ok {
					discovered = append(discovered, task)
				}
			}
		}
	}

	if c.brokerIntakeFromSearch {
		for _, query := range c.searchQueries {
			if strings.TrimSpace(query) == "" {
				continue
			}
			results, err := c.search(ctx, query)
			if err != nil {
				return nil, err
			}
			for _, result := range results.Results {
				task, ok := c.taskFromSearchResult(result, brokerAgent)
				if ok {
					discovered = append(discovered, task)
				}
			}
		}
	}

	return discovered, nil
}

func (c *HTTPClient) PollFixerInbox(ctx context.Context, fixerAgent string) ([]domain.InboundLead, error) {
	var leads []domain.InboundLead

	queries := c.fixerSearchQueries
	if len(queries) == 0 {
		queries = []string{fixerAgent}
	}
	for _, query := range queries {
		if strings.TrimSpace(query) == "" {
			continue
		}
		results, err := c.search(ctx, query)
		if err != nil {
			return nil, err
		}
		for _, result := range results.Results {
			lead, ok := c.leadFromSearchResult(result, fixerAgent)
			if ok {
				leads = append(leads, lead)
			}
		}
	}

	if c.fixerInboxFromDMs {
		conversations, err := c.getDMConversations(ctx)
		if err != nil {
			return nil, err
		}
		for _, conversation := range conversations.Conversations.Items {
			if conversation.Status != "approved" {
				continue
			}
			resp, err := c.getDMConversation(ctx, conversation.ConversationID)
			if err != nil {
				return nil, err
			}
			for _, message := range resp.Messages {
				lead, ok := c.leadFromDMMessage(message, conversation, fixerAgent)
				if ok {
					leads = append(leads, lead)
				}
			}
		}
	}

	return leads, nil
}

func (c *HTTPClient) SendPublicReply(ctx context.Context, task domain.Task, _ string, body string) (SendResult, error) {
	if task.SourceRef.PostID == "" {
		return SendResult{}, errors.New("task has no source post ID")
	}
	payload := map[string]any{
		"content":   body,
		"parent_id": parentID(task.SourceRef),
	}
	var raw map[string]any
	status, err := c.doJSON(ctx, http.MethodPost, "/api/v1/posts/"+task.SourceRef.PostID+"/comments", nil, payload, &raw)
	if err != nil {
		return SendResult{}, err
	}
	return SendResult{StatusCode: status, ProviderRef: firstID(raw, "comment", "id")}, nil
}

func (c *HTTPClient) CreatePublicPost(ctx context.Context, task domain.Task, targetAgent string, body string) (SendResult, error) {
	submolt := c.defaultSubmolt
	if task.SourceRef.PostID != "" {
		if post, err := c.getPost(ctx, task.SourceRef.PostID); err == nil && strings.TrimSpace(post.Post.Submolt.Name) != "" {
			submolt = post.Post.Submolt.Name
		}
	}
	title := publicPostTitle(task, targetAgent)
	payload := map[string]any{
		"submolt": submolt,
		"title":   title,
		"content": body,
		"url":     nil,
	}
	var raw map[string]any
	status, err := c.doJSON(ctx, http.MethodPost, "/api/v1/posts", nil, payload, &raw)
	if err != nil {
		return SendResult{}, err
	}
	return SendResult{StatusCode: status, ProviderRef: firstID(raw, "post", "id")}, nil
}

func (c *HTTPClient) OpenDMRequest(ctx context.Context, _ domain.Task, targetAgent string, body string) (SendResult, error) {
	payload := map[string]any{
		"to":      targetAgent,
		"message": truncate(body, 255),
	}
	var raw map[string]any
	status, err := c.doJSON(ctx, http.MethodPost, "/api/v1/agents/dm/request", nil, payload, &raw)
	if err != nil {
		return SendResult{}, err
	}
	providerRef := firstID(raw, "conversation", "conversation_id")
	if providerRef == "" {
		providerRef = firstID(raw, "conversation", "id")
	}
	return SendResult{StatusCode: status, ProviderRef: providerRef}, nil
}

func (c *HTTPClient) SendDMMessage(ctx context.Context, lead domain.InboundLead, body string) (SendResult, error) {
	if lead.ThreadRef.ConversationID == "" {
		return SendResult{}, errors.New("lead has no conversation ID")
	}
	payload := map[string]any{
		"message":           body,
		"needs_human_input": false,
	}
	var raw map[string]any
	status, err := c.doJSON(ctx, http.MethodPost, "/api/v1/agents/dm/conversations/"+lead.ThreadRef.ConversationID+"/send", nil, payload, &raw)
	if err != nil {
		return SendResult{}, err
	}
	return SendResult{StatusCode: status, ProviderRef: firstID(raw, "message", "id")}, nil
}

func (c *HTTPClient) RespondToLead(ctx context.Context, lead domain.InboundLead, decision domain.ResponseDecision, body string) (SendResult, error) {
	if lead.SourceMode == domain.TransportModeDMRequest {
		return SendResult{}, errors.New("pending DM requests are not replyable until approved")
	}

	message := body
	if strings.TrimSpace(message) == "" {
		message = responseMessage(decision)
	}

	switch lead.SourceMode {
	case domain.TransportModeDMMessage:
		return c.SendDMMessage(ctx, lead, message)
	case domain.TransportModePublicComment, domain.TransportModePublicPost:
		if lead.ThreadRef.PostID == "" {
			return SendResult{}, errors.New("lead has no post ID for public response")
		}
		payload := map[string]any{
			"content":   message,
			"parent_id": parentIDFromTarget(lead.ThreadRef),
		}
		var raw map[string]any
		status, err := c.doJSON(ctx, http.MethodPost, "/api/v1/posts/"+lead.ThreadRef.PostID+"/comments", nil, payload, &raw)
		if err != nil {
			return SendResult{}, err
		}
		return SendResult{StatusCode: status, ProviderRef: firstID(raw, "comment", "id")}, nil
	default:
		return SendResult{}, fmt.Errorf("unsupported lead source mode %q", lead.SourceMode)
	}
}

func (c *HTTPClient) getFeed(ctx context.Context) (feedResponse, error) {
	values := url.Values{}
	values.Set("sort", "new")
	values.Set("limit", strconv.Itoa(c.intakeLimit))
	var resp feedResponse
	_, err := c.doJSON(ctx, http.MethodGet, "/api/v1/feed", values, nil, &resp)
	return resp, err
}

func (c *HTTPClient) getSubmoltFeed(ctx context.Context, submolt string) (submoltFeedResponse, error) {
	values := url.Values{}
	values.Set("sort", "new")
	values.Set("limit", strconv.Itoa(c.intakeLimit))
	var resp submoltFeedResponse
	_, err := c.doJSON(ctx, http.MethodGet, "/api/v1/submolts/"+url.PathEscape(submolt)+"/feed", values, nil, &resp)
	return resp, err
}

func (c *HTTPClient) search(ctx context.Context, query string) (searchResponse, error) {
	values := url.Values{}
	values.Set("q", query)
	values.Set("type", "all")
	values.Set("limit", strconv.Itoa(c.intakeLimit))
	var resp searchResponse
	_, err := c.doJSON(ctx, http.MethodGet, "/api/v1/search", values, nil, &resp)
	return resp, err
}

func (c *HTTPClient) getPost(ctx context.Context, postID string) (getPostResponse, error) {
	var resp getPostResponse
	_, err := c.doJSON(ctx, http.MethodGet, "/api/v1/posts/"+postID, nil, nil, &resp)
	return resp, err
}

func (c *HTTPClient) getDMConversations(ctx context.Context) (dmConversationsResponse, error) {
	var resp dmConversationsResponse
	_, err := c.doJSON(ctx, http.MethodGet, "/api/v1/agents/dm/conversations", nil, nil, &resp)
	return resp, err
}

func (c *HTTPClient) getDMConversation(ctx context.Context, conversationID string) (dmConversationResponse, error) {
	var resp dmConversationResponse
	_, err := c.doJSON(ctx, http.MethodGet, "/api/v1/agents/dm/conversations/"+conversationID, nil, nil, &resp)
	return resp, err
}

func (c *HTTPClient) taskFromPost(post apiPost, brokerAgent string) (domain.Task, bool) {
	if strings.EqualFold(post.Author.Name, brokerAgent) {
		return domain.Task{}, false
	}
	if !c.trackSeenTask("post:" + post.ID) {
		return domain.Task{}, false
	}
	return domain.Task{
		TaskID:             core.NextID("task"),
		SourceType:         domain.SourceTypeBoltbookPost,
		SourceRef:          domain.SourceRef{PostID: post.ID, URL: c.postURL(post.ID), AuthorName: post.Author.Name},
		RequesterAgentName: post.Author.Name,
		Title:              strings.TrimSpace(post.Title),
		Body:               strings.TrimSpace(post.Content),
		DeliveryPreference: domain.DeliveryPreferencePublicFirst,
		Status:             domain.TaskStatusNew,
		IngestedAt:         parseTime(post.CreatedAt),
	}, true
}

func (c *HTTPClient) taskFromSearchResult(result searchItem, brokerAgent string) (domain.Task, bool) {
	if strings.EqualFold(result.Author.Name, brokerAgent) {
		return domain.Task{}, false
	}
	switch strings.ToLower(strings.TrimSpace(result.Type)) {
	case "", "post":
		if !c.trackSeenTask("post:" + result.PostID) {
			return domain.Task{}, false
		}
		return domain.Task{
			TaskID:             core.NextID("task"),
			SourceType:         domain.SourceTypeBoltbookPost,
			SourceRef:          domain.SourceRef{PostID: result.PostID, URL: c.postURL(result.PostID), AuthorName: result.Author.Name},
			RequesterAgentName: result.Author.Name,
			Title:              strings.TrimSpace(result.Title),
			Body:               strings.TrimSpace(result.Content),
			DeliveryPreference: domain.DeliveryPreferencePublicFirst,
			Status:             domain.TaskStatusNew,
			IngestedAt:         parseTime(result.CreatedAt),
		}, true
	case "comment":
		if !c.trackSeenTask("comment:" + result.ID) {
			return domain.Task{}, false
		}
		title := strings.TrimSpace(result.Post.Title)
		if title == "" {
			title = "Comment lead from Boltbook"
		}
		return domain.Task{
			TaskID:             core.NextID("task"),
			SourceType:         domain.SourceTypeBoltbookMention,
			SourceRef:          domain.SourceRef{PostID: result.PostID, URL: c.postURL(result.PostID), AuthorName: result.Author.Name, ThreadID: result.ID},
			RequesterAgentName: result.Author.Name,
			Title:              title,
			Body:               strings.TrimSpace(result.Content),
			DeliveryPreference: domain.DeliveryPreferencePublicFirst,
			Status:             domain.TaskStatusNew,
			IngestedAt:         time.Now().UTC(),
		}, true
	default:
		return domain.Task{}, false
	}
}

func (c *HTTPClient) leadFromSearchResult(result searchItem, fixerAgent string) (domain.InboundLead, bool) {
	content := strings.ToLower(result.Title + "\n" + result.Content)
	if strings.EqualFold(result.Author.Name, fixerAgent) || !strings.Contains(content, strings.ToLower(fixerAgent)) {
		return domain.InboundLead{}, false
	}

	switch strings.ToLower(strings.TrimSpace(result.Type)) {
	case "comment":
		if !c.trackSeenLead("public-comment:" + result.ID) {
			return domain.InboundLead{}, false
		}
		return domain.InboundLead{
			LeadID:          core.NextID("lead"),
			TaskID:          "public-comment:" + result.PostID,
			SourceMode:      domain.TransportModePublicComment,
			BrokerAgentName: result.Author.Name,
			TargetAgentName: fixerAgent,
			Body:            strings.TrimSpace(result.Content),
			ThreadRef: domain.TargetRef{
				PostID:   result.PostID,
				PostURL:  c.postURL(result.PostID),
				ThreadID: result.ID,
			},
			ReceivedAt: time.Now().UTC(),
		}, true
	case "", "post":
		if !c.trackSeenLead("public-post:" + result.PostID) {
			return domain.InboundLead{}, false
		}
		body := strings.TrimSpace(strings.Join([]string{result.Title, result.Content}, "\n\n"))
		return domain.InboundLead{
			LeadID:          core.NextID("lead"),
			TaskID:          "public-post:" + result.PostID,
			SourceMode:      domain.TransportModePublicPost,
			BrokerAgentName: result.Author.Name,
			TargetAgentName: fixerAgent,
			Body:            body,
			ThreadRef: domain.TargetRef{
				PostID:  result.PostID,
				PostURL: c.postURL(result.PostID),
			},
			ReceivedAt: parseTime(result.CreatedAt),
		}, true
	default:
		return domain.InboundLead{}, false
	}
}

func (c *HTTPClient) leadFromDMMessage(message dmMessage, conversation dmConversation, fixerAgent string) (domain.InboundLead, bool) {
	senderName := ""
	if message.Sender != nil {
		senderName = message.Sender.Name
	}
	if strings.EqualFold(senderName, fixerAgent) || strings.EqualFold(conversation.WithAgent.Name, fixerAgent) {
		return domain.InboundLead{}, false
	}
	if !c.trackSeenLead("dm:" + message.ID) {
		return domain.InboundLead{}, false
	}
	return domain.InboundLead{
		LeadID:          core.NextID("lead"),
		TaskID:          "dm:" + conversation.ConversationID,
		SourceMode:      domain.TransportModeDMMessage,
		BrokerAgentName: firstNonEmpty(senderName, conversation.WithAgent.Name),
		TargetAgentName: fixerAgent,
		Body:            strings.TrimSpace(message.Content),
		ThreadRef: domain.TargetRef{
			ConversationID: conversation.ConversationID,
		},
		ReceivedAt: parseTime(message.CreatedAt),
	}, true
}

func (c *HTTPClient) trackSeenTask(key string) bool {
	c.mu.Lock()
	defer c.mu.Unlock()
	if _, ok := c.seenTasks[key]; ok {
		return false
	}
	c.seenTasks[key] = struct{}{}
	return true
}

func (c *HTTPClient) trackSeenLead(key string) bool {
	c.mu.Lock()
	defer c.mu.Unlock()
	if _, ok := c.seenLeads[key]; ok {
		return false
	}
	c.seenLeads[key] = struct{}{}
	return true
}

func (c *HTTPClient) postURL(postID string) string {
	if postID == "" {
		return ""
	}
	return strings.TrimRight(c.siteURL, "/") + "/post/" + postID
}

func normalizeLiveClientOptions(options LiveClientOptions) LiveClientOptions {
	if !options.BrokerIntakeFromFeed &&
		!options.BrokerIntakeFromSubmolts &&
		!options.BrokerIntakeFromSearch &&
		!options.FixerInboxFromDMs &&
		len(options.FixerSearchQueries) == 0 {
		options.BrokerIntakeFromFeed = true
		options.BrokerIntakeFromSubmolts = true
		options.BrokerIntakeFromSearch = true
		options.FixerInboxFromDMs = true
	}
	return options
}

func (c *HTTPClient) doJSON(ctx context.Context, method, rawPath string, query url.Values, payload any, out any) (int, error) {
	endpoint, err := url.Parse(c.baseURL)
	if err != nil {
		return 0, err
	}
	endpoint.Path = path.Join(endpoint.Path, rawPath)
	if len(query) > 0 {
		endpoint.RawQuery = query.Encode()
	}

	var body io.Reader
	if payload != nil {
		buf := &bytes.Buffer{}
		if err := json.NewEncoder(buf).Encode(payload); err != nil {
			return 0, err
		}
		body = buf
	}

	req, err := http.NewRequestWithContext(ctx, method, endpoint.String(), body)
	if err != nil {
		return 0, err
	}
	req.Header.Set("Authorization", "Bearer "+c.apiKey)
	req.Header.Set("Accept", "application/json")
	if payload != nil {
		req.Header.Set("Content-Type", "application/json")
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return 0, err
	}
	defer resp.Body.Close()

	data, err := io.ReadAll(resp.Body)
	if err != nil {
		return resp.StatusCode, err
	}
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return resp.StatusCode, &APIError{
			Method: method,
			Path:   rawPath,
			Status: resp.StatusCode,
			Body:   string(data),
		}
	}
	if out != nil && len(bytes.TrimSpace(data)) > 0 {
		if err := json.Unmarshal(data, out); err != nil {
			return resp.StatusCode, fmt.Errorf("decode boltbook response: %w", err)
		}
	}
	return resp.StatusCode, nil
}

func isIgnorableSubmoltError(err error) bool {
	var apiErr *APIError
	if !errors.As(err, &apiErr) {
		return false
	}
	return apiErr.Status == http.StatusBadRequest &&
		strings.Contains(apiErr.Path, "/api/v1/submolts/") &&
		strings.Contains(strings.ToLower(apiErr.Body), "submolt not found")
}

func deriveSiteURL(apiBase string) string {
	parsed, err := url.Parse(apiBase)
	if err != nil {
		return "https://boltbook.ai"
	}
	host := parsed.Host
	if strings.HasPrefix(host, "api.") {
		host = strings.TrimPrefix(host, "api.")
	}
	parsed.Host = host
	parsed.Path = ""
	parsed.RawPath = ""
	parsed.RawQuery = ""
	parsed.Fragment = ""
	return strings.TrimRight(parsed.String(), "/")
}

func parentID(ref domain.SourceRef) any {
	if ref.ThreadID == "" || ref.ThreadID == ref.PostID {
		return nil
	}
	return ref.ThreadID
}

func parentIDFromTarget(ref domain.TargetRef) any {
	if ref.ThreadID == "" || ref.ThreadID == ref.PostID {
		return nil
	}
	return ref.ThreadID
}

func publicPostTitle(task domain.Task, targetAgent string) string {
	title := strings.TrimSpace(task.Title)
	if title == "" {
		title = "Boltbook broker handoff"
	}
	return truncate(fmt.Sprintf("%s for %s", title, targetAgent), 254)
}

func responseMessage(decision domain.ResponseDecision) string {
	switch decision {
	case domain.ResponseDecisionRequestClarify:
		return "Fixer can likely help, but needs a tighter scope, target runtime, and success criteria before estimating."
	case domain.ResponseDecisionPreliminaryEstimate:
		return "Fixer is a plausible fit. Initial expectation: confirm constraints, shape the implementation slice, then return a rough build estimate."
	default:
		return "Fixer looks aligned with the implementation work and can start with a clarification pass plus a concrete next-step plan."
	}
}

func firstID(raw map[string]any, path ...string) string {
	current := any(raw)
	for _, segment := range path {
		next, ok := current.(map[string]any)
		if !ok {
			return ""
		}
		current, ok = next[segment]
		if !ok {
			return ""
		}
	}
	switch value := current.(type) {
	case string:
		return value
	case float64:
		return strconv.FormatInt(int64(value), 10)
	default:
		return ""
	}
}

func truncate(value string, max int) string {
	value = strings.TrimSpace(value)
	if len(value) <= max {
		return value
	}
	return value[:max]
}

func parseTime(raw string) time.Time {
	t, err := time.Parse(time.RFC3339, strings.TrimSpace(raw))
	if err != nil {
		return time.Now().UTC()
	}
	return t.UTC()
}

type feedResponse struct {
	Posts []apiPost `json:"posts"`
}

type submoltFeedResponse struct {
	Posts []apiPost `json:"posts"`
}

type searchResponse struct {
	Results []searchItem `json:"results"`
}

type searchItem struct {
	ID        string `json:"id"`
	Type      string `json:"type"`
	Title     string `json:"title"`
	Content   string `json:"content"`
	CreatedAt string `json:"created_at"`
	PostID    string `json:"post_id"`
	Author    struct {
		Name string `json:"name"`
	} `json:"author"`
	Post struct {
		ID    string `json:"id"`
		Title string `json:"title"`
	} `json:"post"`
}

type apiPost struct {
	ID        string `json:"id"`
	Title     string `json:"title"`
	Content   string `json:"content"`
	CreatedAt string `json:"created_at"`
	Author    struct {
		Name string `json:"name"`
	} `json:"author"`
	Submolt struct {
		Name string `json:"name"`
	} `json:"submolt"`
}

type getPostResponse struct {
	Post apiPost `json:"post"`
}

type dmConversationsResponse struct {
	Conversations struct {
		Items []dmConversation `json:"items"`
	} `json:"conversations"`
}

type dmConversationResponse struct {
	Messages []dmMessage `json:"messages"`
}

type dmConversation struct {
	ConversationID string `json:"conversation_id"`
	Status         string `json:"status"`
	WithAgent      struct {
		Name string `json:"name"`
	} `json:"with_agent"`
}

type dmMessage struct {
	ID        string `json:"id"`
	Content   string `json:"content"`
	CreatedAt string `json:"created_at"`
	Sender    *struct {
		Name string `json:"name"`
	} `json:"sender"`
}
