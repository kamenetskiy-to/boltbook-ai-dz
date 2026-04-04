package boltbook

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync"
	"testing"

	"boltbook-ai-dz/internal/domain"
)

func TestHTTPClientPollBrokerIntakeDedupesSources(t *testing.T) {
	t.Parallel()

	var mu sync.Mutex
	var authHeaders []string

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		mu.Lock()
		authHeaders = append(authHeaders, r.Header.Get("Authorization"))
		mu.Unlock()

		w.Header().Set("Content-Type", "application/json")
		switch {
		case r.URL.Path == "/api/v1/feed":
			_ = json.NewEncoder(w).Encode(map[string]any{
				"posts": []map[string]any{
					{
						"id":         "post-1",
						"title":      "Need Go help",
						"content":    "Looking for an executor",
						"created_at": "2026-04-04T10:00:00Z",
						"author":     map[string]any{"name": "requester"},
						"submolt":    map[string]any{"name": "general"},
					},
					{
						"id":         "post-self",
						"title":      "Ignore broker self post",
						"content":    "self",
						"created_at": "2026-04-04T10:01:00Z",
						"author":     map[string]any{"name": "broker"},
						"submolt":    map[string]any{"name": "general"},
					},
				},
			})
		case r.URL.Path == "/api/v1/submolts/engineering/feed":
			_ = json.NewEncoder(w).Encode(map[string]any{
				"posts": []map[string]any{
					{
						"id":         "post-2",
						"title":      "SQLite deployment task",
						"content":    "Need infra support",
						"created_at": "2026-04-04T10:02:00Z",
						"author":     map[string]any{"name": "infra-bot"},
						"submolt":    map[string]any{"name": "engineering"},
					},
				},
			})
		case r.URL.Path == "/api/v1/search":
			_ = json.NewEncoder(w).Encode(map[string]any{
				"results": []map[string]any{
					{
						"id":      "comment-1",
						"type":    "comment",
						"title":   nil,
						"content": "Need fixer for Go MCP work",
						"post_id": "post-3",
						"author":  map[string]any{"name": "searcher"},
						"post":    map[string]any{"id": "post-3", "title": "Can someone help?"},
					},
					{
						"id":         "post-1",
						"type":       "post",
						"title":      "Need Go help",
						"content":    "Looking for an executor",
						"post_id":    "post-1",
						"created_at": "2026-04-04T10:00:00Z",
						"author":     map[string]any{"name": "requester"},
					},
				},
			})
		default:
			t.Fatalf("unexpected path: %s", r.URL.Path)
		}
	}))
	defer server.Close()

	client, err := NewHTTPClient(server.URL, "test-key", "general", []string{"engineering"}, []string{"fixer"}, 20)
	if err != nil {
		t.Fatal(err)
	}

	tasks, err := client.PollBrokerIntake(context.Background(), "broker")
	if err != nil {
		t.Fatal(err)
	}
	if len(tasks) != 3 {
		t.Fatalf("expected 3 tasks, got %+v", tasks)
	}
	if tasks[0].SourceRef.URL == "" || !strings.Contains(tasks[0].SourceRef.URL, "/post/") {
		t.Fatalf("expected post URL in task, got %+v", tasks[0].SourceRef)
	}

	next, err := client.PollBrokerIntake(context.Background(), "broker")
	if err != nil {
		t.Fatal(err)
	}
	if len(next) != 0 {
		t.Fatalf("expected no duplicate tasks on second poll, got %+v", next)
	}

	for _, header := range authHeaders {
		if header != "Bearer test-key" {
			t.Fatalf("expected bearer auth header, got %q", header)
		}
	}
}

func TestHTTPClientTransportAndFixerInbox(t *testing.T) {
	t.Parallel()

	var mu sync.Mutex
	var commentBodies []string
	var postBodies []string
	var dmRequestBodies []string
	var dmSendBodies []string

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		switch {
		case r.URL.Path == "/api/v1/posts/77":
			_ = json.NewEncoder(w).Encode(map[string]any{
				"post": map[string]any{
					"id":         "77",
					"title":      "Source post",
					"content":    "source",
					"created_at": "2026-04-04T10:00:00Z",
					"author":     map[string]any{"name": "requester"},
					"submolt":    map[string]any{"name": "engineering"},
				},
			})
		case strings.HasPrefix(r.URL.Path, "/api/v1/posts/") && strings.HasSuffix(r.URL.Path, "/comments") && r.Method == http.MethodPost:
			var body map[string]any
			if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
				t.Fatal(err)
			}
			mu.Lock()
			commentBodies = append(commentBodies, body["content"].(string))
			mu.Unlock()
			_ = json.NewEncoder(w).Encode(map[string]any{"comment": map[string]any{"id": "comment-200"}})
		case r.URL.Path == "/api/v1/posts" && r.Method == http.MethodPost:
			var body map[string]any
			if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
				t.Fatal(err)
			}
			mu.Lock()
			postBodies = append(postBodies, body["submolt"].(string)+":"+body["title"].(string))
			mu.Unlock()
			_ = json.NewEncoder(w).Encode(map[string]any{"post": map[string]any{"id": "post-900"}})
		case r.URL.Path == "/api/v1/agents/dm/request":
			var body map[string]any
			if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
				t.Fatal(err)
			}
			mu.Lock()
			dmRequestBodies = append(dmRequestBodies, body["to"].(string)+":"+body["message"].(string))
			mu.Unlock()
			_ = json.NewEncoder(w).Encode(map[string]any{"conversation": map[string]any{"conversation_id": "conv-1"}})
		case r.URL.Path == "/api/v1/agents/dm/conversations/conv-1/send":
			var body map[string]any
			if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
				t.Fatal(err)
			}
			mu.Lock()
			dmSendBodies = append(dmSendBodies, body["message"].(string))
			mu.Unlock()
			_ = json.NewEncoder(w).Encode(map[string]any{"message": map[string]any{"id": "dm-1"}})
		case r.URL.Path == "/api/v1/search":
			_ = json.NewEncoder(w).Encode(map[string]any{
				"results": []map[string]any{
					{
						"id":      "mention-1",
						"type":    "comment",
						"title":   nil,
						"content": "Fixer, can you take this Go debugging task?",
						"post_id": "post-555",
						"author":  map[string]any{"name": "broker"},
						"post":    map[string]any{"id": "post-555", "title": "Need help fast"},
					},
				},
			})
		case r.URL.Path == "/api/v1/agents/dm/conversations":
			_ = json.NewEncoder(w).Encode(map[string]any{
				"conversations": map[string]any{
					"items": []map[string]any{
						{
							"conversation_id": "conv-1",
							"status":          "approved",
							"with_agent":      map[string]any{"name": "broker"},
						},
					},
				},
			})
		case r.URL.Path == "/api/v1/agents/dm/conversations/conv-1":
			_ = json.NewEncoder(w).Encode(map[string]any{
				"messages": []map[string]any{
					{
						"id":         "dm-msg-1",
						"content":    "Can you take this lead?",
						"created_at": "2026-04-04T11:00:00Z",
						"sender":     map[string]any{"name": "broker"},
					},
				},
			})
		default:
			t.Fatalf("unexpected request: %s %s", r.Method, r.URL.Path)
		}
	}))
	defer server.Close()

	client, err := NewHTTPClient(server.URL, "live-key", "general", nil, nil, 20)
	if err != nil {
		t.Fatal(err)
	}

	task := domain.Task{
		TaskID:     "task-1",
		Title:      "Need help",
		SourceRef:  domain.SourceRef{PostID: "77", URL: server.URL + "/post/77", ThreadID: "comment-root"},
		SourceType: domain.SourceTypeBoltbookPost,
	}
	reply, err := client.SendPublicReply(context.Background(), task, "fixer", "public response")
	if err != nil {
		t.Fatal(err)
	}
	if reply.ProviderRef != "comment-200" {
		t.Fatalf("unexpected comment provider ref: %+v", reply)
	}

	post, err := client.CreatePublicPost(context.Background(), task, "fixer", "handoff body")
	if err != nil {
		t.Fatal(err)
	}
	if post.ProviderRef != "post-900" {
		t.Fatalf("unexpected post provider ref: %+v", post)
	}

	dmRequest, err := client.OpenDMRequest(context.Background(), task, "fixer", "request body")
	if err != nil {
		t.Fatal(err)
	}
	if dmRequest.ProviderRef != "conv-1" {
		t.Fatalf("unexpected dm request provider ref: %+v", dmRequest)
	}

	dmSend, err := client.SendDMMessage(context.Background(), domain.InboundLead{
		ThreadRef: domain.TargetRef{ConversationID: "conv-1"},
	}, "dm body")
	if err != nil {
		t.Fatal(err)
	}
	if dmSend.ProviderRef != "dm-1" {
		t.Fatalf("unexpected dm send provider ref: %+v", dmSend)
	}

	leads, err := client.PollFixerInbox(context.Background(), "fixer")
	if err != nil {
		t.Fatal(err)
	}
	if len(leads) != 2 {
		t.Fatalf("expected one public lead and one DM lead, got %+v", leads)
	}
	if leads[0].SourceMode != domain.TransportModePublicComment || leads[1].SourceMode != domain.TransportModeDMMessage {
		t.Fatalf("unexpected lead ordering: %+v", leads)
	}

	publicResponse, err := client.RespondToLead(context.Background(), leads[0], domain.ResponseDecisionAcknowledgeFit, "public ack")
	if err != nil {
		t.Fatal(err)
	}
	if publicResponse.ProviderRef != "comment-200" {
		t.Fatalf("unexpected public response ref: %+v", publicResponse)
	}

	dmResponse, err := client.RespondToLead(context.Background(), leads[1], domain.ResponseDecisionAcknowledgeFit, "dm ack")
	if err != nil {
		t.Fatal(err)
	}
	if dmResponse.ProviderRef != "dm-1" {
		t.Fatalf("unexpected dm response ref: %+v", dmResponse)
	}

	if _, err := client.RespondToLead(context.Background(), domain.InboundLead{
		SourceMode: domain.TransportModeDMRequest,
		ThreadRef:  domain.TargetRef{ConversationID: "conv-2"},
	}, domain.ResponseDecisionAcknowledgeFit, "not allowed"); err == nil {
		t.Fatal("expected DM request response to be guarded")
	}

	mu.Lock()
	defer mu.Unlock()
	if len(commentBodies) != 2 {
		t.Fatalf("expected 2 public comment bodies, got %+v", commentBodies)
	}
	if len(postBodies) != 1 || !strings.HasPrefix(postBodies[0], "engineering:") {
		t.Fatalf("expected same-submolt post creation, got %+v", postBodies)
	}
	if len(dmRequestBodies) != 1 || !strings.Contains(dmRequestBodies[0], "fixer:request body") {
		t.Fatalf("unexpected dm request bodies: %+v", dmRequestBodies)
	}
	if len(dmSendBodies) != 2 || dmSendBodies[0] != "dm body" || dmSendBodies[1] != "dm ack" {
		t.Fatalf("unexpected dm send bodies: %+v", dmSendBodies)
	}
}
