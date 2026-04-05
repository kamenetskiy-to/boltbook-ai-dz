# Presentation Generation Research for Flutter Deck Redesign

Date: 2026-04-05

Primary research tool: Tavily MCP

## Why this report exists

The current Flutter presentation flow already has one strong structural idea: it separates source gathering, scene planning, copy generation, validation, Flutter rendering, and screenshot capture. The problem is not that the pipeline lacks stages. The problem is that the stages are still too shallow in narrative planning, density control, visual variety, and post-render critique.

This report focuses on concrete presentation-generation patterns from recent papers and production systems that are worth adapting to the Boltbook `presentation_agent` flow. The target is not generic AI slide generation. The target is a better reviewer-facing Russian Flutter web deck for Boltbook/Fixer.

## Current repo position

From the repo docs and runbook, the current presentation flow is effectively:

`request -> sources -> scene_plan -> presentation_plan -> fit validation -> Flutter web build -> screenshots -> deploy`

That is already better than prompt-only slide generators. The next jump should come from:

- stronger narrative planning before copy;
- stronger grounding of each slide to evidence;
- explicit audience-aware copy and narration design;
- more structured layout and density control;
- visual review after rendering, not only before rendering.

## Best external findings

### 1. Multi-stage decomposition beats direct long-context slide generation

DocPres shows that breaking the task into smaller stages with shorter, purpose-built contexts performs better than asking one model to turn a long document directly into slides. Its core flow is:

- build a hierarchical bird's-eye summary of the document;
- generate the outline from that summary;
- map each planned slide to source sections;
- generate slide text with previous slides as flow context;
- choose images using grounded similarity to the contributing sections.

Why it matters here:

- this validates the repo's current stage-based direction;
- it also suggests the missing piece: the scene plan should be more than titles and slide kinds, and should explicitly map each slide to source facts and source slices.

Source:

- DocPres, Adobe Research: https://arxiv.org/html/2406.06556v1

### 2. Edit-based generation with reference slide families is stronger than generating layout from scratch every time

PPTAgent reframes presentation creation as analysis of reference presentations plus iterative editing of reference slides. It first extracts slide functional types and schemas, then plans the outline, picks references, and produces editing actions. It also uses execution feedback for self-correction.

Why it matters here:

- the important reusable idea is not "use PowerPoint APIs";
- the reusable idea is "do not ask the model to invent structure from nothing on every slide";
- instead, maintain a small catalog of Boltbook-specific scene families and per-family content schemas, then fill and refine them.

For Flutter this means:

- keep `slide_kind -> widget builder`;
- add `slide_kind -> variant family -> capacity rules -> expected evidence pattern`;
- let the planner choose a scene variant, not just a slide kind.

Source:

- PPTAgent / PPTEVAL: https://aclanthology.org/2025.emnlp-main.728.pdf

### 3. Audience/style preference distillation and narration-aware planning improve coherence

SlideTailor adds two especially useful ideas:

- separate content preference from aesthetic preference;
- generate slide-wise outlines together with anticipated speech via a chain-of-speech mechanism.

The key result is that narration-aware planning improved content quality, and preference distillation improved flow and alignment.

Why it matters here:

- the current pipeline has `target_audience`, `output_language`, and `audience_signals`, but not a real audience model;
- reviewer-facing Russian decks need explicit control over: what the reviewer must believe, what evidence reduces doubt, how much detail to show, and what should stay in speaker notes rather than on the slide.

For Flutter this means:

- enrich `scene_plan.json` with `slide_thesis`, `audience_intent`, `proof_goal`, `speaker_note_intent`, and `detail_budget`;
- generate speaker notes early, alongside slide content, not after.

Source:

- SlideTailor: https://arxiv.org/html/2512.20292v1

### 4. Visual self-verification after layout generation is a real step-change, not polish

The textual-to-visual self-verification paper is directly relevant. It decomposes content generation and layout generation, then turns the structured layout into a visualized slide, and runs a Reviewer + Refiner loop on the visual output. The review targets overlap, overflow, misalignment, spacing, formatting consistency, and overall balance.

Why it matters here:

- this is the clearest external confirmation that screenshot-based review should be a first-class stage;
- deterministic pre-build validators catch language and obvious budget issues, but they do not reliably catch visual imbalance;
- the repo already captures screenshots. The missing step is to critique and repair from those screenshots before final artifact publication.

For Flutter this means:

- render candidate slides;
- inspect screenshots with a multimodal critic;
- return concrete fixes such as "reduce bullet count", "switch scene variant", "shrink evidence callout", "move metric block below architecture strip";
- rebuild and re-check.

Source:

- Textual-to-Visual Iterative Self-Verification for Slide Generation: https://arxiv.org/abs/2502.15412

### 5. Programmatic / API-level generation works better than end-to-end image generation for structured slides

AutoPresent shows that program generation beats end-to-end image generation for slide creation, and that iterative refinement improves quality further. It also shows that helper libraries and templates materially improve outputs.

Why it matters here:

- this supports the Flutter-native direction;
- editable, structured, component-level generation is the right path;
- "generate a pretty bitmap of a slide" is the wrong architecture for a reusable deck pipeline.

For Flutter this means:

- keep generation in structured JSON plus widget configuration;
- add higher-level scene helpers so the planner operates on semantic building blocks instead of raw layout freedom.

Source:

- AutoPresent: https://openaccess.thecvf.com/content/CVPR2025/papers/Ge_AutoPresent_Designing_Structured_Visuals_from_Scratch_CVPR_2025_paper.pdf

### 6. Presentation evaluation must separate content, design, and coherence

PPTAgent's PPTEVAL and PASS's coherence/relevance/redundancy scoring both point in the same direction: one scalar "deck quality" score is not enough. Different failure modes need different judges.

Why it matters here:

- a reviewer-facing Boltbook deck can be factually correct but still weak because the narrative is abrupt or the design is monotonous;
- it can also look good while repeating the same point across multiple slides;
- these should be scored separately.

For Flutter this means:

- add per-deck scores for `content_grounding`, `narrative_coherence`, `redundancy`, `visual_clarity`, and `reviewer_fit`;
- store them in `run_trace.json`.

Sources:

- PPTAgent / PPTEVAL: https://aclanthology.org/2025.emnlp-main.728.pdf
- PASS: https://arxiv.org/html/2501.06497v1

### 7. Current models are still weak at pure slide critique, so visual evaluation should be constrained and taxonomy-driven

SlideAudit found that AI models still struggle to identify slide design flaws reliably, though taxonomy-informed prompting improves performance. This matters because it argues against a vague "is this slide good?" critic prompt.

Why it matters here:

- the visual critic should review against an explicit checklist;
- otherwise the model will miss subtle flaws or give generic advice.

For Flutter this means:

- define a slide-audit checklist for the current deck system:
- overflow;
- overlap;
- weak hierarchy;
- low contrast;
- overcrowding;
- dead space;
- repeated layout pattern;
- image irrelevance;
- proof mismatch;
- CTA weakness.

Source:

- SlideAudit: https://arxiv.org/pdf/2508.03630

## Strong reusable patterns to adopt

### A. Strengthen the planning artifact, not just the generator

The repo already uses `scene_plan.json` and `presentation_plan.json`. The next version should add stricter semantics:

- `slide_thesis`: one sentence for what the slide must prove;
- `audience_intent`: what the reviewer should understand or believe after this slide;
- `evidence_refs[]`: exact sources backing the slide;
- `evidence_type`: local doc, external research, metric, screenshot, architecture fact;
- `detail_budget`: max bullets, max words, max dense components;
- `speaker_note_intent`: what is said but not shown;
- `visual_role`: proof, compare, sequence, system map, risk, CTA;
- `variant_candidates[]`: scene variants allowed for this slide.

This is the most important immediate upgrade.

### B. Add a narrative brief between request normalization and scene planning

Before scene planning, derive a compact narrative artifact:

- deck goal;
- target audience;
- skepticism profile;
- desired final belief;
- proof order;
- non-negotiable claims;
- prohibited claims;
- tone;
- language.

This makes scene planning materially better, especially for Russian reviewer decks where trust and proof sequence matter more than marketing flourish.

### C. Treat layout capacity as a hard constraint

Most weak AI decks fail because the system writes too much and tries to solve it with smaller fonts or denser blocks. The pipeline should carry explicit capacity budgets per scene variant:

- max bullets;
- max characters per bullet;
- max metrics;
- max proof callouts;
- max simultaneous visual regions.

If the content does not fit:

- split the slide;
- switch scene variant;
- move detail to notes;
- compress copy.

### D. Add a render-review-repair loop

The current screenshot stage should stop being terminal evidence only. It should become a repair loop:

1. build candidate deck;
2. capture canonical screenshots;
3. run deterministic checks plus multimodal critique;
4. emit repair actions;
5. rebuild;
6. keep the best-scoring candidate or stop after a small retry budget.

### E. Use scene families with explicit visual variety rules

A common failure in generated decks is monotonous layout repetition. Maintain a small family of scene variants for each slide kind, then enforce variety across adjacent slides.

Example:

- `problem`: dense evidence variant, contrast variant, single-claim variant;
- `solution`: system overview variant, before/after variant;
- `workflow`: linear steps, swimlane, broker/executor exchange;
- `evidence`: metric-first, screenshot-first, quote-first.

The planner should avoid repeating the same variant class too often in sequence.

## Medium-confidence ideas worth testing

### 1. Learn preferences from previous good decks

SlideTailor's preference distillation is strong in principle. In this repo, the practical adaptation is:

- mine prior accepted Boltbook reviewer decks;
- extract recurring flow, detail level, and preferred scene patterns;
- use that as a prior for future plans.

This is promising, but only if the corpus of "good prior decks" is genuinely good.

### 2. Add presenter-note generation as a first-class output

This is likely useful for future narrated demos and recordings. PASS and SlideTailor both support the idea. It is probably worth adding now because it naturally improves slide brevity.

### 3. Add template-guided scene APIs for planner outputs

AutoPresent and PPTBench both suggest that structured templates or API-level priors help generation. In Flutter terms, that means semantic scene APIs rather than loose widget placement freedom.

## What not to copy from mainstream slide-generation systems

- Do not copy the "prompt -> generic outline -> generic deck" path used by many SaaS tools. It optimizes speed, not trust.
- Do not copy PPTX- or HTML-editing specifics from PPTAgent directly. The important idea is edit-based generation, not the file format.
- Do not copy end-to-end image generation for final slide output. It destroys editability and weakens validation.
- Do not copy generic template churn. For Boltbook, the deck should feel purpose-built for technical reviewer proof, not like a shuffled startup template pack.
- Do not make design novelty the primary goal. For this project, clarity, proof ordering, and reviewer trust beat decorative cleverness.

## What we should change next in our pipeline

### 1. Introduce `narrative_brief.json`

Add a deterministic artifact between `request.json` and `scene_plan.json` with:

- target audience;
- skepticism profile;
- desired takeaways;
- claim order;
- evidence priorities;
- output language;
- tone.

### 2. Upgrade `scene_plan.json` into a true proof plan

Each slide should include:

- thesis;
- proof goal;
- evidence refs;
- audience intent;
- visual role;
- detail budget;
- variant candidates.

### 3. Split copy generation into on-slide copy and spoken copy

Generate:

- concise on-slide copy for visual scanning;
- separate speaker notes / narration intent for delivery and future voiceover.

### 4. Add variant-aware scene selection

Keep current slide kinds, but add 2-4 scene variants per kind with explicit capacity rules and variety constraints.

### 5. Add screenshot-based critique before final publish

The runbook already captures screenshots. Extend the pipeline so screenshots trigger:

- deterministic overflow and density checks;
- taxonomy-based multimodal visual critique;
- a bounded repair loop.

### 6. Score the deck on multiple axes in `run_trace.json`

At minimum:

- `content_grounding_score`
- `coherence_score`
- `redundancy_score`
- `visual_clarity_score`
- `audience_fit_score`

### 7. Keep the pipeline Flutter-native

Do not pivot toward raw HTML slides or image-only generation. The strongest external evidence still supports structured, editable, programmatic generation for slides.

## Recommended next target architecture

The nearest practical redesign for this repo is:

`request.json`
-> `source_bundle.json`
-> optional `research_bundle.json`
-> `narrative_brief.json`
-> `scene_plan.json`
-> `slide_content.json`
-> `layout_plan.json`
-> Flutter render
-> screenshots
-> critique + repair
-> `presentation_plan.json`
-> final build/deploy

Notes:

- `presentation_plan.json` should stop being the first fully meaningful plan artifact;
- `scene_plan.json` and `slide_content.json` should carry more of the intelligence;
- `layout_plan.json` should make visual and density decisions explicit before widget rendering.

## Bottom line

The repo is already pointed in the right direction because it is staged, structured, and Flutter-native. The next upgrade is not "use a better model". The next upgrade is to make the planning artifacts richer, the visual constraints harder, and the screenshot stage corrective rather than merely documentary.

That combination is the clearest path to decks that are:

- more coherent;
- less repetitive;
- more reviewer-trustworthy;
- more visually varied without losing discipline.
