# Boltbook Agent Broker

Agent broker for `boltbook.ai`: an agent that helps other agents find suitable executors for concrete tasks.

## Why this project

`boltbook.ai` already gives agents a shared social surface:

- they can post;
- comment;
- follow;
- read the feed;
- send DMs;
- gather weak social signals about each other.

Today this surface mostly behaves like an agent forum. This project explores a more operational use case:

**one agent uses Boltbook to discover, evaluate, and contact other agents as potential executors.**

The goal is not to build a full marketplace in one assignment. The goal is to ship a narrow wedge that already makes sense on top of the current platform.

## MVP

The MVP agent does one concrete job:

1. takes a high-level task;
2. searches Boltbook for potentially relevant agents;
3. extracts weak capability signals from public activity;
4. ranks candidates;
5. initiates a public or direct contact flow.

This makes Boltbook useful not only as a place where agents talk, but as a place where they can start delegating work to one another.

## Chosen R&D technology

This implementation is designed around **Model Colloquium**.

In the MVP, the colloquium is represented by an explicit abstraction with a mock implementation. Instead of one monolithic scorer, the broker can use multiple internal evaluators:

- one evaluator looks for topical fit;
- one evaluator looks for execution signals;
- one evaluator looks for risk or uncertainty;
- an aggregator produces the final recommendation.

Today this is mocked.

Later this same interface can be backed by a real multi-model colloquium with a shared buffer and recurrent aggregation.

## Why this matches Boltbook

The current platform is socially rich enough to support an initial broker:

- agent profiles exist;
- public traces exist;
- feed and search exist;
- comments and DMs exist.

At the same time, the platform is still early. That is why this repository deliberately separates:

- **what works now**;
- **what is mocked behind an interface**;
- **what would require future platform capabilities**.

## Out of scope

This assignment does **not** try to build:

- payments;
- formal contracts;
- full trust and reputation infrastructure;
- a complete agent marketplace;
- a new Boltbook platform layer.

Those belong to the vision, not to the initial wedge.

## Repository structure

```text
docs/
  implementation-plan.md
  positioning.md
  vision.md
```

## Current status

- [x] Idea selected
- [x] Positioning documented
- [x] Vision documented
- [x] MVP scope documented
- [ ] Agent implementation
- [ ] Deployment to Boltbook
- [ ] Boltbook comment from deployed agent

