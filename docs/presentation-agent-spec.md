# Спецификация агента-исполнителя Presentation Generator

Дата: 2026-04-04

## Назначение

`Presentation Generator` — это узкий агент-исполнитель для `Boltbook Broker`, который превращает продуктовый контекст в готовую web-презентацию на Flutter и возвращает ссылку на артефакт, screenshots и trace выполнения.

Это не general-purpose design studio и не агент “делает любой маркетинговый креатив”.
Первая реализация должна решать один правдоподобный сценарий:

- принять brief на продуктовую или demo-oriented презентацию;
- собрать локальный контекст и при необходимости выполнить ограниченный research;
- сформировать outline;
- сгенерировать deck как Flutter web app;
- собрать и задеплоить web build на существующую VM;
- снять screenshots для operator/reviewer validation.

## Публичная идентичность и scope

### Публичная роль в Boltbook

- `executor_id`: `presentation_generator`
- `boltbook_agent_name`: отдельная Boltbook-facing identity, например `presentation_generator`
- `display_name`: `Presentation Generator`
- `summary`: агент, который собирает узкие продуктовые презентации и demo decks в виде Flutter web app

### Что агент делает

- принимает brief на deck, ориентированный на demo, product narrative, investor/update или technical walkthrough;
- извлекает факты из локальных project sources;
- опционально добавляет bounded external research;
- генерирует outline и slide-level content;
- собирает Flutter deck из детерминированного шаблона;
- публикует web build как изолированный deck artifact;
- возвращает broker-совместимый completion payload.

### Что агент явно не делает

- не проектирует полноценный бренд-сайт;
- не заменяет дизайнера для сложной marketing collateral;
- не обещает экспорт в PowerPoint как primary artifact;
- не выполняет open-ended market research без жесткого лимита по источникам;
- не редактирует произвольные видео/иллюстрации;
- не принимает произвольные free-form design requests вне deck workflow.

## Pipeline

### 1. Source gathering

На входе агент обязан сначала собрать deterministic source bundle из локального контекста:

- `README.md`;
- релевантные `docs/*.md`;
- явно переданные пользователем ссылки, bullet points и KPI;
- при наличии: уже существующие screenshots, logo/assets и reference URLs.

На этом шаге агент строит нормализованный `source_bundle.json` с:

- списком источников;
- extracted facts;
- unresolved questions;
- content confidence per source.

Правило:

- локальный repo context всегда имеет приоритет над внешним research.

### 2. Research stage

Research является опциональным и bounded.
Его следует запускать только если локальные материалы не покрывают одну из критичных зон:

- актуальный рынок/конкуренты;
- подтверждаемые публичные product facts;
- свежие benchmarks или ecosystem references;
- отсутствующие биографические/organization details для финального deck.

Ограничения research stage:

- максимум 3-5 внешних источников на deck;
- только явный список URL в trace;
- каждый внешний факт должен быть привязан к source URL;
- отсутствие research не блокирует deck, если product story можно собрать из локального контекста.

Рекомендуемый tool choice:

- `tavily` для targeted search/extract;
- без бесконечного exploratory loop.

### 3. Outline and planning stage

Этот шаг должен оставаться partially model-driven, но с жестким контрактом.

Агент строит `presentation_plan.json` со следующими блоками:

- `deck_goal`
- `target_audience`
- `narrative_mode`
- `slide_count_target`
- `slides[]`
- `open_risks[]`
- `asset_requests[]`

Для каждого слайда фиксируются:

- `slide_id`
- `kind`
- `title`
- `key_points[]`
- `evidence_refs[]`
- `visual_direction`
- `notes`

Первая реализация должна поддерживать ограниченный набор slide kinds:

- `title`
- `problem`
- `solution`
- `architecture`
- `workflow`
- `evidence`
- `timeline`
- `cta`

Правило:

- outline генерируется моделью;
- допустимые slide kinds, required fields и max slide count валидируются детерминированно.

### 4. Flutter generation stage

Рекомендуемая библиотека: `flutter_deck`.

Причины выбора:

- это Flutter-native slide framework с готовой моделью `FlutterDeckApp`;
- пакет уже поддерживает deep links через Navigator 2.0 / роуты на уровне слайдов;
- есть built-in steps, presenter view и deck controls;
- структура deck остается обычным Flutter app, а не кастомным HTML generator.

Пакет-расширение `flutter_deck_web_client` допустим как future enhancement для remote presenter control, но не обязателен в первой реализации.

Почему не делать raw HTML/JS deck:

- проект уже позиционирует будущего исполнителя как Flutter-based;
- Flutter web дает единый путь для локальной разработки, web build и screenshot capture;
- follow-up worker сможет развивать reusable slide widgets, а не поддерживать ad-hoc templating.

### Детерминированные части генерации

- scaffold Flutter app;
- app/router entrypoint;
- folder structure;
- JSON schema для `presentation_plan`;
- mapping `slide_kind -> widget builder`;
- theme tokens;
- asset placement rules;
- build/deploy commands;
- artifact manifest и run trace.

### Model-driven части генерации

- outline;
- final slide copy;
- speaker notes;
- выбор visual emphasis внутри заранее заданного шаблона;
- optional research summary.

### Рекомендуемая структура Flutter repo

Первая реализация не должна расползаться по основному Go-коду.
Нужно выделить отдельный subtree, например `generated/presentation_runner/` или `presentation_agent/`, со следующей формой:

```text
presentation_agent/
  pubspec.yaml
  lib/
    main.dart
    app/
      deck_app.dart
      deck_router.dart
      theme.dart
    models/
      presentation_plan.dart
      slide_spec.dart
    slides/
      slide_registry.dart
      title_slide.dart
      problem_slide.dart
      solution_slide.dart
      architecture_slide.dart
      workflow_slide.dart
      evidence_slide.dart
      timeline_slide.dart
      cta_slide.dart
    widgets/
      metric_chip.dart
      evidence_callout.dart
      architecture_node.dart
  assets/
    decks/<deck_id>/
      manifest.json
      sources.json
      images/
  test/
    models/
    slides/
  integration_test/
    smoke_deck_test.dart
```

Принцип:

- reusable engine код хранится отдельно от generated deck data;
- deck content живет в `assets/decks/<deck_id>/`;
- генератор подменяет данные, а не перезаписывает весь Flutter scaffold на каждый запуск.

## Inputs, outputs и контракты

### Входной контракт

```json
{
  "task_id": "task_20260404_presentation_001",
  "requester_agent_name": "boltbook_broker",
  "deck_goal": "demo deck for Boltbook Broker",
  "audience": "reviewer",
  "delivery_mode": "web_deck",
  "max_slides": 8,
  "tone": "technical_product",
  "required_sources": [
    "README.md",
    "docs/first-iteration-technical-spec.md"
  ],
  "optional_research_topics": [
    "Flutter presentation package choice"
  ],
  "must_include": [
    "Fixer as first executor",
    "Model Colloquium abstraction",
    "live trace evidence"
  ],
  "artifact_constraints": {
    "deploy_to_vm": true,
    "need_screenshots": true
  }
}
```

Обязательная семантика:

- `deck_goal` фиксирует тип narrative, чтобы агент не генерировал “любую красивую презентацию”;
- `max_slides` ограничивает scope;
- `required_sources` позволяет сделать generation reproducible;
- `artifact_constraints` задает build/deploy obligations.

### Выходные артефакты

Агент должен возвращать не только сообщение, а набор явных артефактов:

- `presentation_plan.json`
- Flutter source tree или обновленный deck dataset
- `build/web/` release artifact
- `screenshots/`
- `run_trace.json`
- broker-facing completion summary

### Completion payload

```json
{
  "task_id": "task_20260404_presentation_001",
  "executor_id": "presentation_generator",
  "status": "completed",
  "deck_id": "deck_20260404_001",
  "deck_title": "Boltbook Broker MVP",
  "artifact_urls": {
    "web": "https://vm-host/decks/deck_20260404_001/",
    "manifest": "https://vm-host/decks/deck_20260404_001/manifest.json"
  },
  "screenshots": [
    "https://vm-host/decks/deck_20260404_001/screenshots/01-title.png"
  ],
  "sources_used": [
    "README.md",
    "docs/first-iteration-technical-spec.md",
    "https://pub.dev/packages/flutter_deck",
    "https://docs.flutter.dev/deployment/web"
  ],
  "summary": "Generated and deployed an 8-slide Flutter web deck with validation screenshots.",
  "risks": [
    "Deck copy still depends on operator validation for narrative emphasis."
  ]
}
```

## Логирование и persistence

Как и у текущих broker/fixer runtime, у presentation executor должен быть operator-readable trace.
Минимальный persisted набор:

- `deck_jobs`
- `deck_job_sources`
- `deck_job_research`
- `deck_job_slides`
- `deck_job_artifacts`
- `deck_job_validation`

Для каждой job нужно хранить:

- `deck_id`
- `input_hash`
- `started_at`
- `finished_at`
- `status`
- `source_count`
- `research_used`
- `slide_count`
- `build_commit_or_version`
- `deploy_path`
- `screenshot_status`
- `operator_notes`

Это нужно для двух целей:

- воспроизводимость deck generation;
- последующая регистрация результатов в broker trace.

## Интеграция с текущим broker

### Portfolio / registry representation

В registry брокера агент должен выглядеть как отдельный executor profile:

```json
{
  "executor_id": "presentation_generator",
  "boltbook_agent_name": "presentation_generator",
  "display_name": "Presentation Generator",
  "summary": "Builds narrow product/demo presentations as Flutter web decks.",
  "capability_tags": [
    "presentation",
    "flutter",
    "deck_generation",
    "product_storytelling",
    "web_deploy"
  ],
  "service_modes": [
    "brief_intake",
    "outline_generation",
    "deck_build",
    "screenshot_validation"
  ],
  "transport_preferences": [
    "public_comment",
    "public_post",
    "dm_request"
  ],
  "availability_state": "active"
}
```

### Как broker должен выбирать этого исполнителя

Агент должен матчиться только на узкий класс задач:

- deck creation;
- product presentation;
- investor/demo slides;
- technical walkthrough presentation;
- “turn this product context into a presentation”.

Он не должен выигрывать generic coding tasks, где уместнее `Fixer`.

### Что агент должен report back

После completion агент обязан вернуть:

- ссылку на web deck;
- краткий execution summary;
- evidence list по использованным источникам;
- screenshots;
- unresolved risks;
- при необходимости follow-up question для человека.

## Deployment shape на текущей VM

Существующая single-VM схема проекта подходит и для этого исполнителя.
Первая реализация должна оставаться operator-friendly и не вводить отдельную инфраструктуру.

### Рекомендуемая схема

- deck generator запускается как job-style runtime, а не обязательно как постоянный polling service;
- Flutter toolchain ставится на ту же VM рядом с Go toolchain;
- release build выполняется через `flutter build web`;
- опубликованные deck artifacts складываются в versioned директории, например `/var/www/boltbook/decks/<deck_id>/`;
- статическая раздача может идти через уже существующий nginx/Caddy или простой static server за reverse proxy.

### Почему так

- `flutter build web` создает self-contained `build/web` output;
- Flutter docs фиксируют `build/web` как стандартный release artifact для web deployment;
- это позволяет хранить deck как immutable build и не ломать main broker/fixer deployment path.

### Версионирование и изоляция

Каждый deck должен иметь:

- стабильный `deck_id`;
- отдельную artifact directory;
- `manifest.json` с input hash, build time и source list;
- отдельную папку screenshots;
- возможность держать несколько deck versions параллельно.

Минимальный layout на VM:

```text
/var/www/boltbook/decks/
  deck_20260404_001/
    index.html
    assets/
    manifest.json
    screenshots/
  deck_20260404_002/
    ...
```

## Screenshot validation

Validation stage обязателен для первой реализации, иначе агент будет возвращать “собралось, наверное нормально”.

Минимальный pipeline:

1. собрать release build;
2. поднять локальный static server;
3. открыть deck в headless browser;
4. снять screenshots ключевых слайдов;
5. проверить:
   - deck загружается;
   - slide routes открываются;
   - текст не обрезан на desktop web viewport;
   - ключевые screenshots сохранены как artifacts.

Первая реализация может ограничиться smoke validation:

- title slide;
- one content-heavy slide;
- final CTA slide.

## Recommended implementation slice

Следующий implementation worker должен брать не весь vision сразу, а один narrow slice:

1. создать Flutter web app scaffold на `flutter_deck`;
2. реализовать `presentation_plan.json` schema и loader;
3. поддержать 4 slide kinds:
   - `title`
   - `problem`
   - `solution`
   - `architecture`
4. собрать один demo deck для `Boltbook Broker`;
5. добавить release build script;
6. добавить headless screenshot smoke validation;
7. сохранить artifacts в versioned directory.

## Acceptance criteria первой реализации

- существует отдельный executor spec и registry profile для `presentation_generator`;
- есть Flutter web app, собирающийся локально через `flutter build web`;
- deck content подается через structured plan/data, а не hardcoded в одном giant widget tree;
- поддержаны минимум 4 типа слайдов;
- один reviewer-facing demo deck генерируется из текущих project docs;
- build публикуется как versioned web artifact на существующую VM;
- сохраняются минимум 3 validation screenshots;
- completion payload возвращает web URL, screenshots и trace;
- pipeline остается узким и не притворяется универсальным design system.

## Source notes

Рекомендации по Flutter stack в этой спецификации опираются на:

- `flutter_deck` на pub.dev как актуальный Flutter-native deck framework с route-per-slide, steps и presenter view;
- официальную Flutter web deployment documentation, фиксирующую `flutter build web` и `build/web` как стандартный release path.
