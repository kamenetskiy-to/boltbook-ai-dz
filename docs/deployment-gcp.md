# Инструкция по деплою в GCP

Теперь в репозитории есть практичный набор артефактов для деплоя первой итерации на небольшой single-VM конфигурации.

## Подтвержденная целевая среда

Проверено 2026-04-04 на конфигурации:

- GCP project: `boltbook-ai-dz-20260404`
- project number: `979246359455`
- billing account: `017975-610EC2-F440F6`
- VM: `boltbook-mvp-vm`
- zone: `europe-west1-b`
- machine type: `e2-micro`
- внешний IP на момент проверки: `34.38.33.15`

## Ожидаемая целевая схема

- по возможности отдельный GCP project;
- одна минимальная Debian VM;
- одна общая SQLite database на VM;
- два долгоживущих `systemd`-сервиса для `broker` и `fixer`;
- отдельный бинарь `demo` для безопасных end-to-end smoke-проверок в fake mode.

## Почему важен бинарь demo

`fake`-режим Boltbook является process-local. Сервисы broker и fixer могут стартовать в fake mode одновременно, но они не разделяют один и тот же in-memory fake transport backend между разными процессами.

Это означает следующее:

- используйте `systemd`-сервисы для проверки долгоживущих процессов и журналов;
- используйте `bin/demo` как безопасный end-to-end proof path в fake mode;
- переводите сервисы в `BOLTBOOK_CLIENT_MODE=live` только после появления реальных Boltbook credentials.

`bin/demo` по умолчанию использует in-memory SQLite database, но при явном `BOLTBOOK_DB_PATH` будет сохранять результирующую trace database, чтобы smoke script мог ее проверить.

## Файлы, добавленные для деплоя

- `deploy/gcp/create_vm.sh`
- `deploy/vm/bootstrap.sh`
- `deploy/vm/install_repo.sh`
- `deploy/vm/smoke_demo.sh`
- `deploy/systemd/boltbook-broker.service`
- `deploy/systemd/boltbook-fixer.service`
- `deploy/env/presentation_generator.env.example`
- `deploy/vm/register_presentation_agent.sh`
- `deploy/env/broker.env.example`
- `deploy/env/fixer.env.example`

## Типовой сценарий

Создать VM:

```bash
PROJECT_ID=boltbook-ai-dz-20260404 \
ZONE=europe-west1-b \
INSTANCE_NAME=boltbook-mvp-vm \
./deploy/gcp/create_vm.sh
```

Скопировать репозиторий на VM:

```bash
gcloud compute scp --recurse . boltbook-mvp-vm:~/boltbook-ai-dz \
  --project boltbook-ai-dz-20260404 \
  --zone europe-west1-b
```

Подготовить окружение и установить приложение:

```bash
gcloud compute ssh boltbook-mvp-vm \
  --project boltbook-ai-dz-20260404 \
  --zone europe-west1-b \
  --command 'cd ~/boltbook-ai-dz && sudo ./deploy/vm/bootstrap.sh && sudo ./deploy/vm/install_repo.sh ~/boltbook-ai-dz'
```

`bootstrap.sh` ставит Go, Node.js/npm и официальный Codex CLI, после чего нормализует путь CLI как `/usr/local/bin/codex`.

Запустить долгоживущие сервисы:

```bash
gcloud compute ssh boltbook-mvp-vm \
  --project boltbook-ai-dz-20260404 \
  --zone europe-west1-b \
  --command 'sudo systemctl restart boltbook-broker boltbook-fixer && sudo systemctl status --no-pager boltbook-broker boltbook-fixer'
```

Запустить безопасный end-to-end smoke path:

```bash
gcloud compute ssh boltbook-mvp-vm \
  --project boltbook-ai-dz-20260404 \
  --zone europe-west1-b \
  --command 'cd /opt/boltbook-ai-dz/current && sudo ./deploy/vm/smoke_demo.sh /opt/boltbook-ai-dz/current'
```

## Рекомендации по environment-файлам

Скрипт установки создает:

- `/etc/boltbook/broker.env`
- `/etc/boltbook/fixer.env`
- `/etc/boltbook/presentation_generator.env`

Для `live`-режима обновите оба файла, указав:

- `BOLTBOOK_BROKER_AGENT_NAME=boltbook_broker`
- `BOLTBOOK_CLIENT_MODE=live`
- корректный `BOLTBOOK_API_KEY`
- нужные watched submolts и search queries

Для presentation executor identity отдельный env-файл заводится через:

```bash
gcloud compute ssh boltbook-mvp-vm \
  --project boltbook-ai-dz-20260404 \
  --zone europe-west1-b \
  --command 'cd /opt/boltbook-ai-dz/current && sudo ./deploy/vm/register_presentation_agent.sh'
```

Скрипт регистрирует `presentation_generator`, сохраняет его `api_key` и, если Boltbook его возвращает, `verification_code` в `/etc/boltbook/presentation_generator.env`, после чего останавливается без запуска live deck request.

Для controlled one-shot A2A validation можно временно сузить intake до одного trace token:

- `BOLTBOOK_BROKER_INTAKE_FROM_FEED=false`
- `BOLTBOOK_BROKER_INTAKE_FROM_SUBMOLTS=false`
- `BOLTBOOK_BROKER_INTAKE_FROM_SEARCH=true`
- `BOLTBOOK_SEARCH_QUERIES=<уникальный trace token>`
- `BOLTBOOK_FIXER_SEARCH_QUERIES=<тот же trace token>`
- `BOLTBOOK_FIXER_INBOX_FROM_DMS=false`

Если хотите включить Codex-backed черновики ответов у `fixer`, дополнительно укажите в `/etc/boltbook/fixer.env`:

- `BOLTBOOK_FIXER_CODEX_ENABLED=true`
- `BOLTBOOK_CODEX_CLI_PATH=/usr/local/bin/codex`
- `BOLTBOOK_CODEX_HOME=/var/lib/boltbook`
- `BOLTBOOK_CODEX_MODEL=gpt-5.3-codex-spark`
- `BOLTBOOK_CODEX_TIMEOUT=45s`

Это включает Codex только для генерации текста ответа на входящий lead у `fixer`. Intake, matching, transport, persistence и остальные циклы остаются детерминированными Go-кодом.

## Установка Codex auth на VM

Скопируйте локальный `~/.codex/auth.json` на VM во временный путь, затем установите его с безопасными правами:

```bash
gcloud compute scp ~/.codex/auth.json boltbook-mvp-vm:~/codex-auth.json \
  --project boltbook-ai-dz-20260404 \
  --zone europe-west1-b

gcloud compute ssh boltbook-mvp-vm \
  --project boltbook-ai-dz-20260404 \
  --zone europe-west1-b \
  --command 'cd /opt/boltbook-ai-dz/current && sudo ./deploy/vm/install_codex_auth.sh /home/hensybex/codex-auth.json'
```

После этого auth будет лежать в `/var/lib/boltbook/.codex/auth.json` с правами `0600` и владельцем `boltbook:boltbook`.

Для smoke-проверки самой Codex интеграции на VM можно выполнить:

```bash
gcloud compute ssh boltbook-mvp-vm \
  --project boltbook-ai-dz-20260404 \
  --zone europe-west1-b \
  --command 'sudo -u boltbook HOME=/var/lib/boltbook /usr/local/bin/codex exec --skip-git-repo-check --sandbox read-only --color never -m gpt-5.3-codex-spark "Reply with exactly: codex-vm-ok"'
```

Для one-shot валидации одного цикла broker или fixer задайте:

```bash
BOLTBOOK_RUN_ONCE=true
```

и затем перезапустите соответствующий сервис или выполните бинарь напрямую.

## Controlled A2A validation через отдельную trace DB

Если нужно доказать broker-to-fixer handoff без запуска широкого polling по production DB, используйте отдельную SQLite trace database и manual-seed task.

Практический шаблон:

1. Оставить `systemd`-сервисы остановленными.
2. Создать отдельный DB-файл, например `/var/lib/boltbook/controlled-a2a.db`.
3. Запустить `bin/broker` один раз с:
   - `BOLTBOOK_DB_PATH=/var/lib/boltbook/controlled-a2a.db`
   - `BOLTBOOK_RUN_ONCE=true`
   - `BOLTBOOK_BROKER_INTAKE_FROM_FEED=false`
   - `BOLTBOOK_BROKER_INTAKE_FROM_SUBMOLTS=false`
   - `BOLTBOOK_BROKER_INTAKE_FROM_SEARCH=false`
4. Вставить ровно одну manual-seed task в `tasks`.
5. Снова запустить `bin/broker` one-shot против той же trace DB.
6. Запустить `bin/fixer` one-shot против той же trace DB с:
   - `BOLTBOOK_FIXER_SEARCH_QUERIES=<уникальный trace token>`
   - `BOLTBOOK_FIXER_INBOX_FROM_DMS=false`
7. Снять evidence из `transport_actions`, `fixer_response_actions`, `run_history` и при необходимости из Boltbook search API.

Критично:

- не используйте production `boltbook.db` для такого сценария, если нужна чистая reviewer-friendly trace;
- не оставляйте `BOLTBOOK_RUN_ONCE=true` в `systemd`-env после завершения проверки;
- после проверки убедитесь, что `boltbook-broker` и `boltbook-fixer` остались в `inactive`, если вы не планируете долгоживущий live polling.

## Как загружать `/etc/boltbook/*.env` в shell

Эти env-файлы написаны под `systemd` `EnvironmentFile=`. Не делайте `source /etc/boltbook/broker.env` или `source /etc/boltbook/fixer.env` в обычном shell: значения вроде `BOLTBOOK_SEARCH_QUERIES=golang broker,mcp sqlite` содержат пробелы и не являются shell-safe assignment syntax.

Для ad-hoc one-shot команд на VM используйте безопасную загрузку построчно:

```bash
while IFS= read -r line; do
  [ -z "$line" ] && continue
  case "$line" in
    \#*) continue ;;
  esac
  export "$line"
done < /etc/boltbook/broker.env
```

Тот же шаблон применяйте для `fixer.env`, после чего переопределяйте только нужные переменные для controlled validation.

## Операторские команды

Статус сервисов:

```bash
sudo systemctl status --no-pager boltbook-broker
sudo systemctl status --no-pager boltbook-fixer
```

Логи:

```bash
sudo journalctl -u boltbook-broker -n 100 --no-pager
sudo journalctl -u boltbook-fixer -n 100 --no-pager
sudo tail -n 100 /var/log/boltbook/demo-smoke.log
```

Проверка SQLite:

```bash
sudo sqlite3 /var/lib/boltbook/boltbook.db '.tables'
sudo sqlite3 /var/lib/boltbook/smoke-demo.db 'select component, status, examined, processed from run_history order by started_at;'
```

## Текущее live-состояние

На 2026-04-04 live-активация уже выполнена:

- Boltbook identities `boltbook_broker` и `fixer` зарегистрированы и активированы;
- VM environment-файлы переведены в `live`-режим;
- реальный authenticated smoke path уже отработан;
- controlled A2A trace подтверждена публичным post `https://boltbook.ai/post/445` и ответом `Fixer` с comment id `1906`.

После проверок оба `systemd`-сервиса намеренно оставлены в состоянии `inactive`, чтобы не продолжать широкий live polling и массовые публичные side effects.

## Что остается оператору

С инженерной точки зрения первая итерация собрана и подтверждена. Следующие шаги уже не про базовую активацию, а про эксплуатационный режим:

- решить, когда снова включать долгоживущие `boltbook-broker` и `boltbook-fixer`;
- сузить intake rules перед повторным включением continuous live polling;
- при необходимости снять еще один публичный trace с более “чистой” reviewer-facing подачей.
