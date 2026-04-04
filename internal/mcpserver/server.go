package mcpserver

import (
	"context"

	"github.com/modelcontextprotocol/go-sdk/mcp"

	"boltbook-ai-dz/internal/broker"
	"boltbook-ai-dz/internal/domain"
	"boltbook-ai-dz/internal/fixer"
)

func NewBrokerServer(service *broker.Service) *mcp.Server {
	server := mcp.NewServer(&mcp.Implementation{
		Name:    "boltbook-broker",
		Version: "0.1.0",
	}, nil)

	mcp.AddTool(server, &mcp.Tool{
		Name:        "add_portfolio",
		Description: "Create or replace an executor portfolio in the local broker registry.",
	}, func(ctx context.Context, _ *mcp.CallToolRequest, in domain.ExecutorPortfolio) (*mcp.CallToolResult, domain.ExecutorPortfolio, error) {
		return nil, in, service.AddPortfolio(ctx, in)
	})

	mcp.AddTool(server, &mcp.Tool{
		Name:        "update_portfolio",
		Description: "Update an existing executor portfolio in the local broker registry.",
	}, func(ctx context.Context, _ *mcp.CallToolRequest, in domain.ExecutorPortfolio) (*mcp.CallToolResult, domain.ExecutorPortfolio, error) {
		return nil, in, service.UpdatePortfolio(ctx, in)
	})

	mcp.AddTool(server, &mcp.Tool{
		Name:        "match_agents_top5",
		Description: "Rank up to five executor candidates for a normalized task.",
	}, func(ctx context.Context, _ *mcp.CallToolRequest, in domain.Task) (*mcp.CallToolResult, domain.MatchResult, error) {
		result, err := service.MatchAgentsTop5(ctx, in)
		return nil, result, err
	})

	mcp.AddTool(server, &mcp.Tool{
		Name:        "create_consensus_handoff",
		Description: "Create the broker handoff payload for the highest ranked executor candidate.",
	}, func(ctx context.Context, _ *mcp.CallToolRequest, in domain.Task) (*mcp.CallToolResult, domain.Handoff, error) {
		handoff, err := service.CreateConsensusHandoff(ctx, in)
		return nil, handoff, err
	})

	type notifyInput struct {
		Task    domain.Task    `json:"task"`
		Handoff domain.Handoff `json:"handoff"`
	}
	mcp.AddTool(server, &mcp.Tool{
		Name:        "notify_selected_agent_demo",
		Description: "Execute the public-first transport fallback policy for a broker handoff.",
	}, func(ctx context.Context, _ *mcp.CallToolRequest, in notifyInput) (*mcp.CallToolResult, domain.TransportAction, error) {
		action, err := service.NotifySelectedAgentDemo(ctx, in.Task, in.Handoff)
		return nil, action, err
	})

	return server
}

func NewFixerServer(service *fixer.Service) *mcp.Server {
	server := mcp.NewServer(&mcp.Implementation{
		Name:    "fixer",
		Version: "0.1.0",
	}, nil)

	mcp.AddTool(server, &mcp.Tool{
		Name:        "intake_lead",
		Description: "Persist and return the first-response action for an inbound broker lead.",
	}, func(ctx context.Context, _ *mcp.CallToolRequest, in domain.InboundLead) (*mcp.CallToolResult, domain.FixerResponseAction, error) {
		response, err := service.HandleLead(ctx, in)
		return nil, response, err
	})

	mcp.AddTool(server, &mcp.Tool{
		Name:        "first_response_actions",
		Description: "Generate the narrow first-response action that Fixer would send for a broker lead.",
	}, func(ctx context.Context, _ *mcp.CallToolRequest, in domain.InboundLead) (*mcp.CallToolResult, domain.FixerResponseAction, error) {
		response, err := service.HandleLead(ctx, in)
		return nil, response, err
	})

	return server
}
