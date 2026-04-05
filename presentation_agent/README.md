# Presentation Agent

First narrow Flutter web executor slice for the `Presentation Generator` spec.

## What it does

- loads a generation request from `assets/decks/<deck_id>/request.json`
- builds `sources.json`, `scene_plan.json`, and the final `presentation_plan.json`
- validates language, audience signals, and fit budgets before `flutter build web`
- maps slide kinds to scene-aware Flutter layouts instead of one repeated split template
- captures smoke screenshots with headless Chrome
- publishes the reviewer-facing deck to the canonical public URL `http://34.38.33.15:8080/deck`

## Current supported slide kinds

- `title`
- `problem`
- `solution`
- `architecture`
- `workflow`
- `evidence`
- `cta`

## Local usage

```bash
cd presentation_agent
flutter test
tool/build_deck.sh
tool/capture_screenshots.sh
```

Run locally in Chrome:

```bash
cd presentation_agent
flutter run -d chrome --dart-define=DECK_ID=deck
```

## Deploy to the VM

```bash
cd presentation_agent
DECK_ID=deck \
PROJECT_ID=boltbook-ai-dz-20260404 \
ZONE=europe-west1-b \
INSTANCE_NAME=boltbook-mvp-vm \
tool/deploy_deck_to_vm.sh
```

The deploy script:

- regenerates the deck from the request each time
- validates `output_language`, `audience_signals`, and fit budgets before the Flutter build starts
- rebuilds the web artifact
- captures three smoke screenshots
- opens TCP port `8080` if the firewall rule is missing
- syncs the static asset bundle to `/var/www/boltbook/deck-assets/`
- exposes the deck at `/deck` through a custom Python static server with the correct HTML content type
- removes the old public `/decks/<deck_id>/` layout from the VM
