# Техническая спецификация первой итерации

Дата: 2026-04-04

## Назначение

Этот документ является каноническим implementation brief для первой поставляемой итерации `Boltbook Broker`.
Он превращает согласованное направление MVP и подтвержденные ограничения Boltbook API в конкретную цель для дальнейшей реализации.

Эта спецификация исходит из того, что:

- `Boltbook Broker` является главным поставляемым артефактом;
- `Fixer` является первым агентом-исполнителем в registry брокера;
- Boltbook используется как аутентифицированный social transport layer, а не как authoritative registry;
- первая итерация по возможности реализуется на Go;
- для MCP server surfaces во внутренних runtime tools следует предпочитать `github.com/modelcontextprotocol/go-sdk`, когда это уместно без лишней сложности.

## Границы продукта

### В scope

- один задеплоенный runtime брокера;
- один задеплоенный runtime исполнителя для `Fixer`;
- один локальный authoritative registry исполнителей;
- один узкий workflow маршрутизации задач;
- один end-to-end demo trace, который проходит без требования DM approval как единственного пути handoff;
- одна future-facing абстракция `Model Colloquium` с mock implementation оценщиков.

### Вне scope

- платежи;
- контракты;
- автоматическое ценообразование;
- широкая экономика репутации;
- полное platform-wide discovery исполнителей;
- гарантированные автономные переговоры через DM;
- general-purpose marketplace UI.

## Подтвержденные ограничения, перенесенные в дизайн

- Boltbook endpoints для feed, search, profile, comments, posts и DM требуют аутентифицированного agent access для meaningful automation.
- Boltbook DM является consent-gated и не может считаться гарантированным каналом первого контакта.
- Boltbook не предоставляет подтвержденного отдельного endpoint вида "list all agents" или "list new agents".
- Брокер должен хранить authoritative registry исполнителей в собственной SQLite database.
- Discovery новых исполнителей носит приближенный характер и должен опираться на polling ленты, search, submolts, lookup профилей и manual seeding.

## Топология первой итерации

### Runtime-компоненты

1. `Boltbook Broker`
   - владеет registry исполнителей;
   - опрашивает Boltbook на предмет intake signals;
   - матчить задачи с исполнителями;
   - создает handoff payloads;
   - выбирает и выполняет transport actions;
   - сохраняет run traces и transport outcomes.

2. `Fixer`
   - является отдельной Boltbook-facing agent identity;
   - получает лиды от брокера через transport surfaces Boltbook;
   - подтверждает fit, запрашивает уточнение или дает rough next step;
   - пишет собственные operational logs.

3. Общая локальная persistence
   - SQLite database на VM;
   - хранит записи исполнителей, task intake records, результаты matching, transport attempts и run history.

4. Внутренний broker tool layer
   - `add_portfolio`
   - `update_portfolio`
   - `match_agents_top5`
   - `create_consensus_handoff`
   - `notify_selected_agent_demo`

### Схема деплоя

- первая итерация запускается на одной GCP VM;
- broker и fixer работают как отдельные процессы с разными Boltbook credentials;
- один общий SQLite-файл допустим для первой итерации;
- один code repository допустим, если разделение рантаймов явно выражено в config и process management.

## Процессная модель

### Рекомендуемая operating model

- `Boltbook Broker` работает как долгоживущий polling service;
- `Fixer` работает как отдельный долгоживущий polling service;
- у каждого сервиса свой poll interval и своя lockfile/process identity;
- для steady-state loop предпочтительны `systemd`-сервисы, а не cron;
- cron допустим только для простых watchdog или recovery-задач.

### Почему `systemd`, а не cron

- проще организовать непрерывный polling без пересечений;
- лучше поведение при рестартах;
- понятнее журналы и проверка service health;
- проще инъекция секретов и environment на VM.

## Транспортная модель Boltbook

### Поддерживаемые intake sources для брокера

- посты в watched submolts;
- прямые упоминания аккаунта брокера;
- replies/comments к постам, опубликованным брокером;
- вручную seeded task records, добавленные оператором.

### Поддерживаемые outbound contact actions

1. публичный reply на существующий пост или комментарий;
2. публичный post от лица брокера с тегом или упоминанием выбранного исполнителя;
3. DM request выбранному исполнителю;
4. follow-up в approved DM conversation после одобрения получателем.

### Транспортная политика

Первая итерация не должна зависеть от DM approval как от единственного успешного пути.

`notify_selected_agent_demo` должен пытаться доставить сообщение в таком порядке:

1. публичный reply/comment, если уже есть видимый task thread;
2. публичный post от брокера, если handoff требует отдельного публичного trace;
3. DM request как путь эскалации;
4. сообщение в DM conversation только после approval.

## Контракты данных

Контракты ниже являются каноническими payload shapes.
Названия полей могут быть реализованы как Go structs, JSON documents или нормализованные таблицы, но семантика должна оставаться неизменной.

### Запись portfolio исполнителя

```json
{
  "executor_id": "fixer",
  "boltbook_agent_name": "fixer",
  "display_name": "Fixer",
  "summary": "Coding orchestration agent for multi-step engineering work.",
  "capability_tags": ["golang", "typescript", "mcp", "debugging", "implementation"],
  "service_modes": ["lead_intake", "clarification", "rough_estimate"],
  "transport_preferences": ["public_comment", "public_post", "dm_request"],
  "availability_state": "active",
  "portfolio_evidence": [
    {
      "kind": "profile",
      "source_url": "https://boltbook.ai/u/fixer",
      "excerpt": "Multi-agent coding orchestration."
    }
  ],
  "trust_signals": {
    "operator_curated": true,
    "last_validated_at": "2026-04-04T00:00:00Z"
  },
  "created_at": "2026-04-04T00:00:00Z",
  "updated_at": "2026-04-04T00:00:00Z"
}
```

Обязательная семантика:

- `executor_id` это локальный authoritative identifier;
- `boltbook_agent_name` это transport identity для lookup и контакта;
- `capability_tags` это локальные входы для matching, а не Boltbook-native taxonomy;
- `availability_state` это локальное состояние брокера и оно может отличаться от фактической reachability в Boltbook;
- `portfolio_evidence` хранит source traces, на которых основана запись.

### Запрос на task intake у брокера

```json
{
  "task_id": "task_20260404_001",
  "source_type": "boltbook_post",
  "source_ref": {
    "post_id": "427",
    "url": "https://boltbook.ai/post/427",
    "author_name": "requesting_agent"
  },
  "requester_agent_name": "requesting_agent",
  "title": "Need help implementing MCP-based broker",
  "body": "Looking for an executor to build a Go service with polling and logs.",
  "task_tags": ["golang", "mcp", "deployment"],
  "delivery_preference": "public_first",
  "status": "new",
  "ingested_at": "2026-04-04T00:00:00Z"
}
```

Обязательная семантика:

- `source_type` различает Boltbook transport и задачи, seeded оператором;
- `source_ref` должен позволять восстановить публичный trace для целей демо;
- `delivery_preference` влияет на выбор transport, но не отменяет правила DM consent;
- `status` должен поддерживать как минимум `new`, `matched`, `contacted`, `awaiting_reply`, `closed` и `deferred`.

### Выход top-5 matching

```json
{
  "task_id": "task_20260404_001",
  "generated_at": "2026-04-04T00:01:00Z",
  "candidates": [
    {
      "rank": 1,
      "executor_id": "fixer",
      "score": 0.91,
      "fit_summary": "Strong fit for implementation-heavy MCP and debugging work.",
      "fit_reasons": [
        "Capability tags overlap with golang, mcp, and implementation.",
        "Operator-curated portfolio reduces discovery uncertainty.",
        "Transport path supports public response without DM approval."
      ],
      "risks": [
        "Estimate quality may depend on clarifying project scope."
      ]
    }
  ],
  "selection_reason": "Fixer is the strongest available executor for the requested engineering task."
}
```

Обязательная семантика:

- формат должен всегда поддерживать до пяти ранжированных кандидатов, даже если в начальном registry пока только один;
- `fit_summary` и `fit_reasons` входят в user-visible contract объяснения;
- `risks` обязателен, чтобы избежать излишне уверенной маршрутизации.

### Payload consensus handoff

```json
{
  "handoff_id": "handoff_20260404_001",
  "task_id": "task_20260404_001",
  "selected_executor_id": "fixer",
  "broker_recommendation": {
    "score": 0.91,
    "fit_summary": "Strong fit for implementation-heavy MCP and debugging work."
  },
  "task_context": {
    "title": "Need help implementing MCP-based broker",
    "body": "Looking for an executor to build a Go service with polling and logs.",
    "task_tags": ["golang", "mcp", "deployment"]
  },
  "transport_plan": {
    "primary_mode": "public_comment",
    "fallback_modes": ["public_post", "dm_request"]
  },
  "colloquium": {
    "mode": "mock",
    "evaluators": ["topic_fit", "execution_fit", "risk_check"],
    "aggregator": "weighted_merge_v1"
  },
  "created_at": "2026-04-04T00:01:30Z"
}
```

Обязательная семантика:

- этот payload является будущей стабильной границей для реального multi-model deliberation;
- брокер может создавать его уже сейчас, даже если colloquium пока только замокан;
- `transport_plan` должен отражать public-first fallback order.

### Запись transport action

```json
{
  "transport_id": "transport_20260404_001",
  "task_id": "task_20260404_001",
  "handoff_id": "handoff_20260404_001",
  "attempted_mode": "public_comment",
  "target_agent_name": "fixer",
  "target_ref": {
    "post_id": "427"
  },
  "request_payload_excerpt": "Fixer looks like the best fit for this implementation-heavy task.",
  "outcome": "sent",
  "provider_status_code": 201,
  "provider_ref": "comment_991",
  "attempted_at": "2026-04-04T00:02:00Z"
}
```

Обязательная семантика:

- каждая outbound attempt должна сохраняться, включая failures;
- `provider_ref` хранит transport artifact, необходимый для traceability в демо;
- `outcome` должен поддерживать как минимум `sent`, `failed`, `deferred`, `awaiting_approval`.

### Запись operational log

```json
{
  "log_id": "log_20260404_001",
  "run_id": "broker_run_20260404T000000Z",
  "component": "broker",
  "level": "info",
  "event": "task_matched",
  "task_id": "task_20260404_001",
  "handoff_id": "handoff_20260404_001",
  "transport_id": "transport_20260404_001",
  "message": "Matched task to fixer and sent public comment.",
  "timestamp": "2026-04-04T00:02:01Z"
}
```

Обязательная семантика:

- логи должны быть structured, а не только free-form;
- каждое значимое изменение состояния должно порождать одну structured record;
- log records должны быть доступны для запроса по `run_id`, `task_id` и `component`.

## Поведение рантайма

### Broker polling loop

Каждый цикл брокера должен выполнять следующие шаги:

1. сгенерировать новый `run_id`;
2. захватить локальный process lock, чтобы не допустить пересечения запусков;
3. получить данные из настроенных Boltbook intake sources;
4. нормализовать найденные элементы в task intake records;
5. выполнить deduplicate по source reference и локальному состоянию задачи;
6. запустить `match_agents_top5` для каждой подходящей задачи;
7. сохранить результаты matching и explanation payloads;
8. создать consensus handoff payload для выбранного исполнителя;
9. выполнить `notify_selected_agent_demo` с transport fallback policy;
10. сохранить результат transport action;
11. выпустить structured logs для каждого перехода состояния;
12. освободить lock и зафиксировать завершение цикла.

### Discovery задач и seeding

Первая итерация поддерживает два класса discovery:

1. аутентифицированный Boltbook discovery
   - watched feed entries;
   - настроенные submolts;
   - явные упоминания брокера;
   - выбранные search queries.

2. operator-assisted seeding
   - ручное добавление профилей исполнителей в локальный registry;
   - ручное добавление task intake records для контролируемых демо.

Это сделано намеренно.
Первая итерация не должна притворяться, что умеет полное автономное platform-wide discovery.

### Выбор transport у брокера

Использовать такое правило принятия решения:

1. если задача пришла из публичного треда и публичный контакт приемлем, отвечать публично;
2. иначе, если для demo trace достаточно публичного поста от брокера, создавать публичный пост;
3. иначе открывать DM request;
4. отправлять сообщение в DM только после явного approval.

### Поведение рантайма `Fixer`

Каждый цикл fixer должен:
- получить новые public mentions и approved DM conversations, относящиеся к агенту `Fixer`;
- дедуплицировать уже обработанные lead records;
- сформировать ограниченный first-response payload;
- выбрать reply path, совместимый с исходным transport context;
- сохранить response action и operational logs;
- не притворяться fully autonomous delivery engine без human review там, где это не подтверждено.

## Внутренние MCP-поверхности

### Broker MCP surface

Первая итерация может публиковать узкий внутренний MCP surface для локальных operator/demo workflows.

Минимально ожидаемые операции:

- `add_portfolio`
- `update_portfolio`
- `match_agents_top5`
- `create_consensus_handoff`
- `notify_selected_agent_demo`

Требования к поведению:

- инструменты должны работать поверх локальной SQLite state;
- side effects должны быть идемпотентными настолько, насколько это разумно для повторяемых demo-запусков;
- transport-инструменты обязаны возвращать достаточно данных для traceability и отладки.

### Fixer MCP surface

Публичная идентичность `Fixer` не должна раскрывать весь `Fixer MCP` как production control plane.

Для первой итерации достаточно узкого Boltbook-facing поведения:

- получить lead;
- подтвердить fit или запросить уточнение;
- дать rough next step или rough estimate;
- при необходимости зафиксировать, что требуется human follow-up.

## Хранение данных и наблюдаемость

### Требования к SQLite

Первая итерация может использовать один общий SQLite-файл, если соблюдены следующие условия:

- broker и fixer явно разделены как отдельные процессы;
- записи run history и transport action сохраняются атомарно;
- база пригодна для операторской инспекции после демо;
- поведение при конкурирующих записях достаточно устойчиво для двух долгоживущих сервисов.

### Минимальная observability

Система должна сохранять достаточно данных, чтобы оператор мог ответить на вопросы:

- когда запускался каждый цикл broker и fixer;
- какие intake items были просмотрены;
- какие задачи были отфильтрованы, сматчены или отложены;
- какой transport mode был выбран;
- какое действие выполнил `Fixer`;
- что завершилось успехом, ошибкой или ожиданием approval.

Это должно быть доступно как минимум через:

- structured logs;
- persisted run history;
- persisted transport action records;
- persisted fixer response records.

## Конфигурация

### Обязательные runtime-параметры

Первая итерация должна поддерживать конфигурацию как минимум для:

- `BOLTBOOK_CLIENT_MODE`
- `BOLTBOOK_API_KEY`
- `BOLTBOOK_API_BASE_URL`
- `BOLTBOOK_DB_PATH`
- `BOLTBOOK_DEFAULT_SUBMOLT`
- `BOLTBOOK_WATCHED_SUBMOLTS`
- `BOLTBOOK_SEARCH_QUERIES`
- `BOLTBOOK_INTAKE_LIMIT`
- poll interval для broker и fixer
- уровня логирования

### Безопасные значения по умолчанию

- `fake` mode должен оставаться безопасным default path для локальной разработки и демо;
- `live` mode должен включаться только через явную конфигурацию;
- one-shot validation через `BOLTBOOK_RUN_ONCE` должна поддерживаться для операторской проверки на VM.

## Тестирование и валидация

### Минимальный автоматизированный test scope

Первая итерация должна иметь автоматизированные тесты как минимум для:

- matching logic;
- transport fallback policy;
- SQLite persistence basics;
- config parsing и безопасных default values;
- локального end-to-end demo path в fake mode;
- live client request/response mapping там, где это возможно через `httptest`.

### Операторская валидация

Помимо automated tests, оператор должен иметь возможность:

- запустить локальный `cmd/demo`;
- запустить broker и fixer как отдельные процессы;
- проверить SQLite state и run history;
- проверить логи `systemd` на VM;
- выполнить безопасный fake-mode smoke path до перехода в live mode.

## Критерии приемки первой итерации

Первая итерация считается принятой, когда доступны и воспроизводимы следующие свойства:

1. на VM запущены два отдельных рантайма: `Boltbook Broker` и `Fixer`;
2. локальный registry содержит как минимум профиль исполнителя `Fixer`;
3. брокер умеет принимать задачу из Boltbook-like intake или operator-seeded record;
4. брокер умеет выдавать ranking в top-5 compatible shape с объяснением fit и рисков;
5. брокер умеет создавать consensus handoff payload;
6. broker-to-fixer handoff проходит по public-first transport policy и не зависит только от DM approval;
7. `Fixer` умеет сформировать узкий first response на полученный lead;
8. system сохраняет достаточный trace для последующего reviewer/operator inspection;
9. локальный fake-mode demo воспроизводим без live Boltbook credentials;
10. путь перехода к live mode задокументирован и не требует изменения архитектуры.

## Направление после MVP

После поставки первой итерации следующими естественными шагами могут быть:

- подключение реального authenticated Boltbook deployment для обоих агентов;
- capture production trace на живой платформе;
- обогащение discovery через реальные public signals и curated portfolio updates;
- замена mock colloquium на более сильный multi-evaluator runtime;
- добавление richer operator views поверх уже сохраненных structured traces.

Эти шаги не являются обязательными для текущей поставки, но текущий design должен оставлять для них чистую эволюционную траекторию.
