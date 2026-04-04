# Presentation Agent Runbook

Дата: 2026-04-04

## Что появилось в первой реализации

В репозитории добавлен отдельный Flutter subtree `presentation_agent/`, который выполняет первый узкий срез `Presentation Generator`:

- загружает deck из `assets/decks/<deck_id>/presentation_plan.json`;
- мапит structured slide kinds в `flutter_deck`;
- собирает reviewer-facing web deck про текущий Boltbook Broker проект;
- готовит versioned static artifact;
- снимает smoke screenshots через headless Chrome;
- публикует deck на текущую GCP VM как `/var/www/boltbook/decks/<deck_id>/`.

## Поддерживаемые slide kinds

- `title`
- `problem`
- `solution`
- `architecture`
- `workflow`
- `evidence`
- `cta`

## Локальный цикл

```bash
cd presentation_agent
flutter test
tool/build_deck.sh
tool/capture_screenshots.sh
```

Артефакты складываются в:

```text
presentation_agent/build/decks/<deck_id>/site/
```

Там лежат:

- `index.html` и Flutter web bundle;
- `presentation_plan.json`;
- `manifest.json`;
- `sources.json`;
- `run_trace.json`;
- `screenshots/`.

## Деплой на VM

```bash
cd presentation_agent
PROJECT_ID=boltbook-ai-dz-20260404 \
ZONE=europe-west1-b \
INSTANCE_NAME=boltbook-mvp-vm \
tool/deploy_deck_to_vm.sh
```

Скрипт делает следующее:

1. пересобирает web deck;
2. снимает три smoke screenshot;
3. вычисляет текущий внешний IP VM;
4. открывает firewall rule для `tcp:8080`, если ее еще нет;
5. копирует artifact на VM в `/var/www/boltbook/decks/<deck_id>/`;
6. включает `boltbook-decks.service`, который раздает `/var/www/boltbook` как статический каталог.

Ожидаемый URL:

```text
http://<vm-external-ip>:8080/decks/<deck_id>/
```

## Boltbook identity и registry

Для Boltbook-facing identity добавлен reproducible registration path:

```bash
sudo ./deploy/vm/register_presentation_agent.sh
```

Скрипт:

1. проверяет, не настроен ли уже `/etc/boltbook/presentation_generator.env`;
2. если identity еще не существует, регистрирует `presentation_generator` через `POST /api/v1/agents/register`;
3. сохраняет выданный `api_key` и, если Boltbook его возвращает, `verification_code` в `/etc/boltbook/presentation_generator.env`;
4. не запускает реальную deck generation.

Повторный запуск скрипта должен показать текущий статус identity, включая `claimed` и `active`.

Broker-ready request shape для первого реального deck task лежит в:

```text
docs/presentation-agent-request-example.json
```

Этот payload готов для manual seed или для будущего broker-side intake normalization.

## Что пока сознательно не сделано

- нет generic brief intake и outline generation;
- нет persistence слоя `deck_jobs*` в SQLite;
- нет нескольких deck datasets и выбора deck через broker runtime;
- статическая раздача идет через простой Python HTTP server, а не через nginx/Caddy.

Это приемлемо для первой реализации, потому что текущая цель — доказать artifact path: structured deck data -> Flutter web build -> screenshot validation -> versioned VM deployment.

## Точный stopping point перед live platform run

Репозиторий и VM подготовлены до следующего явного шага, который уже будет запускать реальный platform scenario:

1. зарегистрировать и claim-нуть `presentation_generator`;
2. обновить broker repo/VM этим релизом;
3. создать реальный Boltbook task или manual-seed task по форме `docs/presentation-agent-request-example.json`;
4. только после этого запускать generation workflow.

Намеренно не выполняется:

- публикация реального deck request в Boltbook;
- broker-driven live generation;
- автоматический ответ presentation executor в Boltbook.
