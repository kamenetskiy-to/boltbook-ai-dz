# Аудит возможностей Boltbook API

Дата: 2026-04-04

## Цель

Понять, что именно Boltbook уже предоставляет сегодня для broker-style MVP, и отделить проверенное поведение от предположений.

## Использованные источники

- инспекция публичного сайта `https://boltbook.ai/`
- публичная документация по agent skill на `https://api.boltbook.ai/skill.md`
- публичный heartbeat guide на `https://api.boltbook.ai/heartbeat.md`
- публичная DM policy на `https://api.boltbook.ai/messaging.md`
- публичная API-спецификация на `https://api.boltbook.ai/api/v1/openapi.json`
- live unauthenticated probes против выбранных endpoints от 2026-04-04

## Итоговый вывод

Текущий план MVP в целом валиден, если рассматривать брокера как Boltbook-authenticated agent client, а не как неофициальный web scraper и не как маркетплейс с гарантированной DM-автоматизацией с первого дня.

Ключевые корректировки такие:

- использовать документированный bot API Boltbook как основную integration surface;
- считать, что для всех meaningful feed/search/profile/DM действий нужен agent API key;
- рассматривать direct-message automation как условно доступную возможность после регистрации и подтверждения со стороны получателя, а не как безусловный канал контакта;
- считать discovery новых агентов приближенным и строить его через feed, search, profiles и submolts, а не через отдельный registry endpoint.

## Подтвержденные возможности

### 1. У Boltbook есть реальная публичная bot API surface

Подтверждено через публичный OpenAPI document:

- `GET https://api.boltbook.ai/api/v1/openapi.json` возвращает `200`
- версия OpenAPI: `3.1.0`
- title/version API в спецификации: `Boltbook Bot API` / `0.2.3`

Опубликованные paths включают:

- регистрацию агента и проверку статуса
- доступ к собственному профилю и lookup профилей других агентов
- чтение ленты
- posts CRUD-lite
- чтение и создание комментариев
- поиск
- follow/unfollow
- список/read/subscribe/create для submolt
- DM request, approval, чтение conversation, отправку сообщений в conversation
- upload медиа

### 2. Продукт публично направляет агентов интегрироваться через `api.boltbook.ai`

Подтверждено по главной странице:

- `https://boltbook.ai/` публично предлагает забрать `https://api.boltbook.ai/skill.md`
- там же предлагается использовать `https://api.boltbook.ai/heartbeat.md`
- также указано, что агент должен зарегистрироваться в Boltbook и считается успешно подключенным, когда его статус становится `claimed`

Это важно, потому что bot API здесь не выглядит скрытой целью для reverse engineering. Это штатный путь интеграции.

### 3. На сайте есть публичные community pages, posts, profiles и search UI

Подтверждено прямой инспекцией сайта:

- в публичной навигации доступны communities, создание постов, создание community, search, login и signup
- существуют публичные страницы постов, например `/post/427`
- существуют публичные страницы профилей, например `/u/cyber_nina`
- существуют публичные страницы communities, например `/c/general`

Это подтверждает, что у demo есть правдоподобный публичный social workflow.

### 4. Сайт построен на кастомизированном Lemmy-style instance с отключенной федерацией

Подтверждено через `window.isoData`, встроенный в главную страницу:

- заявленная версия ПО: `0.19.15`
- `federation_enabled: false`
- `registration_mode: "Closed"` для публичного site instance
- страница содержит site metadata, включая количество posts/comments/communities

Следствие:

- Boltbook сейчас скорее выглядит как отдельный instance, а не как открытый федеративный слой discovery.
- Закрытая человеческая регистрация сама по себе не доказывает, что agent registration закрыта, потому что она отдельно вынесена в bot API.

### 5. Для meaningful API usage нужна bearer-token authentication

Подтверждено по OpenAPI spec и live probes:

- схема безопасности это HTTP bearer auth
- `GET https://api.boltbook.ai/api/v1/feed` без токена возвращает `401 Unauthorized`
- `GET https://api.boltbook.ai/api/v1/search?q=test` без токена возвращает `401 Unauthorized`
- `GET https://api.boltbook.ai/api/v1/agents/dm/check` без токена возвращает `401 Unauthorized`

Следствие:

- брокер на VM может опрашивать Boltbook, но только как аутентифицированный Boltbook-агент.
- anonymous scraping не является предполагаемым программным путем.

### 6. Endpoint регистрации агента действительно работает

Подтверждено прямым запросом к endpoint:

- `POST https://api.boltbook.ai/api/v1/agents/register` с `{}` возвращает `422`
- validation error требует поля `name` и `description`

Это подтверждает, что route регистрации поднят и валидирует запросы. В рамках этого аудита live agent account не создавался.

### 7. Feed, posting, comments, profiles, follows и submolt interactions документированы как first-class bot actions

Подтверждено через опубликованные OpenAPI spec и skill docs:

- feed: `GET /api/v1/feed`
- posts: `GET/POST /api/v1/posts`, `GET/DELETE /api/v1/posts/{post_id}`
- comments: `GET/POST /api/v1/posts/{post_id}/comments`
- lookup профиля: `GET /api/v1/agents/profile?name=...`
- собственный профиль: `GET /api/v1/agents/me`
- follow/unfollow: `POST /api/v1/agents/{bot_name}/follow` и `/unfollow`
- submolts: присутствуют endpoints для list/read/create/subscribe
- upload медиа: `POST /api/v1/media/upload`

Для MVP этого документированного surface уже достаточно, чтобы поддержать:

- хранение executor portfolio/profile в самом Boltbook
- task intake через posts/comments и discovery через profiles
- outbound public escalation через comments/posts

### 8. Direct messaging документирован как consent-gated, а не open-send

Подтверждено по `messaging.md`, `heartbeat.md` и OpenAPI spec:

- DM flow начинается с `POST /api/v1/agents/dm/request`
- у получателя есть явное действие approve/reject
- сообщения затем отправляются через conversation endpoints
- heartbeat docs прямо говорят, что новые DM requests требуют human approval перед продолжением чата

Следствие:

- DM automation существует как продуктовая возможность и API surface.
- Но это не fire-and-forget notification channel для произвольных агентов.

## Вероятные, но не подтвержденные предположения

Эти выводы выглядят правдоподобно по документации и спецификации, но не были проверены end-to-end, потому что для этого пришлось бы заводить и эксплуатировать реальную Boltbook agent identity.

### 1. Регистрация, вероятно, сразу возвращает API key

`skill.md` описывает `POST /api/v1/agents/register` как endpoint, который возвращает:

- `api_key`
- `verification_code`

Точное тело runtime response при реальном запросе регистрации в этом аудите не проверялось.

### 2. Статус claimed, вероятно, зависит от отдельного шага claim/approval со стороны человека

На главной странице сказано, что агент считается успешно зарегистрированным, когда его статус становится `claimed`.
Это довольно явно указывает на раздельные стадии registration и claim, но точный UX и тайминг здесь не доказаны.

### 3. Polling с broker VM, вероятно, операционно прост после аутентификации

API это обычный HTTPS плюс bearer auth, а skill docs написаны вокруг периодических heartbeat checks. Это выглядит как прямой сигнал, что cron/polling является поддерживаемым режимом использования.

Поведение rate limit при длительном polling с реальным токеном не проверялось.

### 4. Discovery новых агентов, вероятно, возможен, но только косвенно

В OpenAPI spec нет выделенного публичного path для:

- list all agents
- list newly registered agents
- stream registration events

Тем не менее брокер, скорее всего, сможет находить кандидатов косвенно через:

- чтение ленты
- поиск
- lookup профилей по известному имени
- списки submolt и участие в них
- контекст follows/subscriptions из `agents/me`

Для MVP этого достаточно, но это все же слабее, чем настоящий registry endpoint.

## Неподдерживаемые или заблокированные возможности

### 1. Неаутентифицированные programmatic reads не подходят как стратегия брокера

Ключевые API read-операции без bearer token возвращают `401`. Брокер обязан аутентифицироваться как Boltbook-агент.

### 2. Нет подтвержденного отдельного endpoint для registry/discovery агентов

Спецификация дает lookup профиля по имени, но не предоставляет чистого endpoint вида "list agents" или "newly registered agents".

Это главный разрыв с исходным предположением о "discovery новых регистраций исполнителей".

### 3. DM-эскалация не гарантирована как первый контакт

DM являются consent-gated:

- сначала request
- затем человек на стороне получателя approve/reject
- только после этого продолжается conversation

Поэтому DM нельзя считать гарантированной мгновенной доставкой для broker-to-executor routing.

### 4. Нет подтвержденных гарантий по внешнему SDK/runtime integration

Найдены:

- публичная HTTP API documentation
- `curl`-ориентированные skill-файлы

Не найдены:

- официальный language SDK
- формальная webhook/event-delivery documentation
- docs по интеграции именно с Codex SDK

Это не блокирует MVP, но означает, что интеграцию нужно делать как обычный HTTPS client code.

## Влияние на предложенную архитектуру MVP

## Оставить без изменений

- одного broker-агента
- одного executor-агента (`Fixer`)
- VM-hosted runtime с cron/polling
- локальный broker registry и matching logic вне Boltbook
- future consensus handoff как внутреннюю абстракцию

## Изменить

### 1. Рассматривать Boltbook как social transport layer, а не как source of truth для matching

Использовать Boltbook для:

- agent identity
- публичной активности
- conversation surfaces
- discovery signals

Executor portfolio registry и ranking logic должны оставаться в собственном SQLite-хранилище.

### 2. Сделать public-post/contact workflow основным demo path

Основной надежный demo path должен выглядеть так:

- broker читает контент Boltbook
- broker матчится с локальным registry
- broker пишет публичный post/comment reply или сообщение в submolt
- broker при необходимости открывает DM request
- `Fixer` отвечает публично или через approved DM

Нельзя делать approval DM единственным успешным handoff path в демо.

### 3. Сузить "discovery новых агентов" до приближенного discovery

В формулировке MVP лучше говорить:

- "находит кандидатов-исполнителей по активности и профилям в Boltbook"

И не стоит заявлять:

- "real-time discovery регистраций"
- "полную синхронизацию platform-wide agent registry"

пока у Boltbook не появится отдельный endpoint.

### 4. Считать agent claim/onboarding явной предпосылкой

И брокеру, и `Fixer` нужны:

- успешная регистрация
- сохраненные API keys
- статус `claimed`

до того, как end-to-end demo можно будет считать production-like.

## Рекомендуемые корректировки scope MVP

1. Сохранить `add_portfolio`, `update_portfolio`, `match_agents_top5` и `create_consensus_handoff` внутри собственного broker runtime и database.
2. Переосмыслить `notify_selected_agent_demo` как transport abstraction с таким fallback order:
   - public reply/comment/post
   - DM request
   - approved DM conversation
3. Определить discovery как:
   - polling ленты
   - polling submolt
   - search
   - manual/seeded registration агентов в локальном broker registry
4. Не обещать автоматическое обнаружение каждого нового Boltbook-агента.
5. Не опираться на недокументированные frontend internals. Использовать только опубликованный bot API и публичные site URLs для demo narration.

## Итог

Boltbook уже предоставляет достаточно документированного bot API surface, чтобы поддержать узкий broker MVP.

Что уже твердо работает сегодня:

- аутентифицированное чтение ленты
- posting/commenting
- lookup профилей
- follows/subscriptions
- взаимодействие с submolt
- consent-based DM workflow
- наличие agent registration endpoint

Что пока недостаточно надежно, чтобы ставить на critical path:

- гарантированный DM-based handoff
- полное discovery новых агентов
- любые утверждения, что Boltbook сам по себе уже является полноценным registry исполнителей

Вердикт:

Продолжать с текущей архитектурой, но с двумя конкретными поправками:

- authoritative executor registry брокера должен оставаться локальным для вашей системы;
- demo handoff path должен успешно работать без требования DM approval как единственного маршрута.
