# Handoff

Дата: 2026-04-04

## Objective

Собрать и сдать тестовое задание для роли `Agentic Engineer / Evangelist`:

- задеплоить на `boltbook.ai` одного главного агента;
- показать agent-agent interaction как главный интерфейс;
- опереться архитектурно как минимум на одну из их R&D capabilities;
- честно показать работающий `MVP` плюс ясный `vision`.

## Current framing

Главный артефакт проекта:

- `Boltbook Broker` / `registry agent`

Это агент-прослойка для `boltbook.ai`, который:

- принимает высокоуровневую задачу;
- собирает и хранит портфолио агентов-исполнителей;
- извлекает структурированную информацию о специализациях и сигналах качества;
- готовит shortlist кандидатов под будущий `Model Colloquium`;
- инициирует agent-to-agent delegation flow.

### Important constraint

Нельзя расползтись в “строю весь рынок агентов”.

Сдаваемый scope:

- один главный агент;
- один узкий, правдоподобный сценарий;
- одна выбранная технология с mock/placeholder abstraction;
- один живой demo case.

## Chosen technology

Основная опора:

- `Model Colloquium`

Почему:

- лучше всего матчится с broker scenario;
- позволяет честно сделать abstraction уже сейчас;
- легко объясняется как future upgrade:
  - несколько internal evaluators;
  - aggregation;
  - later: real shared-buffer colloquium.

Secondary future-fit:

- `Omnimodal Long-Term Memory`

Но это не основная ось текущего MVP.

## What is already decided

### 1. Main agent

Главный сдаваемый агент:

- не агитатор;
- не весь marketplace;
- не “просто агент, который чатится”;
- а именно broker / registry layer.

### 2. Demo ecosystem

Вокруг главного агента допустим минимальный demo ecosystem:

- `Fixer MCP` как первый зарегистрированный агент-исполнитель.

Это сильный `proof of concept`, потому что превращает идею из абстракции в живую связку:

- broker;
- executor profile;
- portfolio ingest;
- retrieval / shortlist / contact flow.

### 3. Outreach

Outreach к живым агентам на `boltbook.ai` возможен, но не должен быть критическим путем.

Допустимо:

- один introductory post/comment;
- один soft attempt at DM / capability discovery.

Недопустимо ставить на это core success criteria.

## Product truth

`boltbook.ai` сейчас это не полноценный agent marketplace.

Это:

- social API layer;
- minimal agent network;
- posts/comments/DM/follow/submolts;
- early and noisy environment.

Поэтому текущий проект должен показывать:

- `works now` на слабых сигналах;
- `works later` на richer capability primitives.

## Fixer MCP role in this project

`Fixer MCP` не является главным сдаваемым артефактом.

Он является:

- первым агентом-исполнителем;
- демонстрацией того, как настоящий сложный агент может быть опубликован в этой среде;
- proof, что broker работает не только на synthetic profile.

### Honest positioning for Fixer

Позиционировать Fixer честно как:

- orchestration control plane for multi-agent coding work;
- durable state, role boundaries, review flow, launcher semantics;
- suited for engineering / coding / multi-step implementation tasks.

Не обещать:

- “решает вообще любые задачи”;
- полностью autonomous order execution без human-in-the-loop;
- production-grade commercial workflow прямо сейчас.

## Expected MVP behavior

### Broker agent should be able to

1. принять запрос на подбор исполнителя;
2. сохранить/обновить портфолио агента-исполнителя;
3. вытащить structured info из registry;
4. подготовить shortlist / recommendation payload;
5. инициировать контактный шаг в `boltbook`.

### Minimum useful demo

- broker stores Fixer profile;
- broker can retrieve Fixer as relevant executor for an engineering-style task;
- broker can explain why Fixer is a fit;
- broker can produce a public-platform interaction trace.

## Non-goals

Не делать в первой сдаваемой версии:

- полноценную payment system;
- реальный pricing negotiation engine;
- полноценное agent interviewing loop;
- полноценную reputation economy;
- complex marketplace UI;
- три полноценных автономных агента вместо одного сильного ядра.

## Suggested execution order

1. Зафиксировать финальный behavioral spec MVP.
2. Определить data model для executor portfolio.
3. Определить public interaction flow на `boltbook`.
4. Собрать main broker agent.
5. Подготовить Fixer profile as first executor.
6. Прогнать end-to-end demo path.
7. Только после этого докрутить optional outreach to other agents.

## Repo state

Репозиторий:

- `/Users/hensybex/Desktop/projects/boltbook-ai-dz`

Уже есть:

- `README.md`
- `docs/positioning.md`
- `docs/vision.md`
- `docs/implementation-plan.md`

## Immediate next step

Следующим шагом нужно не писать еще одну аналитику, а зафиксировать:

- как именно выглядит `portfolio record`;
- как агент заносит профиль исполнителя в registry;
- как выглядит запрос на подбор исполнителя;
- какой именно output broker отдает в MVP.

После этого можно спокойно переходить к реализации.
