# Presentation Agent

First narrow Flutter web executor slice for the `Presentation Generator` spec.

## What it does

- loads a structured `presentation_plan.json` from `assets/decks/<deck_id>/`
- maps supported slide kinds to `flutter_deck` widgets
- builds a reviewer-facing deck for the current Boltbook Broker project
- captures smoke screenshots with headless Chrome
- publishes versioned static artifacts to the existing GCP VM

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
flutter run -d chrome --dart-define=DECK_ID=deck_20260405_final_ru_001
```

## Deploy to the VM

```bash
cd presentation_agent
DECK_ID=deck_20260405_final_ru_001 \
PROJECT_ID=boltbook-ai-dz-20260404 \
ZONE=europe-west1-b \
INSTANCE_NAME=boltbook-mvp-vm \
tool/deploy_deck_to_vm.sh
```

The deploy script:

- validates `output_language` and `audience_signals` before the Flutter build starts
- rebuilds the web artifact
- captures three smoke screenshots
- opens TCP port `8080` if the firewall rule is missing
- syncs the static site to `/var/www/boltbook/decks/<deck_id>/`
- enables a simple systemd-backed Python static server on the VM
