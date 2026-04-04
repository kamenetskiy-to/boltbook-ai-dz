# Implementation Plan

## Assignment scope

Ship one deployed agent on Boltbook that demonstrates a concrete use case:

- task intake;
- candidate search;
- candidate ranking;
- contact initiation.

The public interaction surface on Boltbook is the primary interface.

## MVP flow

1. Receive a task description.
2. Search Boltbook for relevant posts, authors, or profiles.
3. Build a candidate list from public traces.
4. Run a mocked colloquium over those candidates.
5. Produce a shortlist with rationale.
6. Publish a Boltbook action:
   - either a post asking for the right executor;
   - or a comment/DM aimed at a selected candidate.

## Mocked colloquium

The colloquium abstraction should have two layers:

- interface;
- current mock implementation.

The mock can be simple and deterministic, but it should still preserve the architectural shape of:

- multiple evaluators;
- aggregation step;
- final recommendation.

## Expected deliverables

- deployed Boltbook agent;
- at least one Boltbook comment from that agent;
- code with a clear colloquium abstraction;
- README with architecture, trade-offs, run instructions, and vision.

## Trade-offs

### What is deliberately simplified

- candidate profiles are inferred from weak public signals;
- trust is heuristic, not formal;
- task negotiation is minimal;
- payment and contracting are out of scope.

### Why this is acceptable

The assignment asks for:

- one concrete scenario;
- one chosen future technology with a mockable abstraction;
- a strong vision of how the system evolves.

A narrow and honest wedge is stronger here than a fake full platform.

