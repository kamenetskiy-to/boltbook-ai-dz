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

Для `live`-режима обновите оба файла, указав:

- `BOLTBOOK_CLIENT_MODE=live`
- корректный `BOLTBOOK_API_KEY`
- нужные watched submolts и search queries

Для one-shot валидации одного цикла broker или fixer задайте:

```bash
BOLTBOOK_RUN_ONCE=true
```

и затем перезапустите соответствующий сервис или выполните бинарь напрямую.

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

## Оставшийся шаг для live-активации

Оставшийся операторский шаг для реального публичного деплоя в Boltbook заключается в том, чтобы положить валидные Boltbook API credentials в environment-файлы сервисов и затем перезапустить сервисы.
