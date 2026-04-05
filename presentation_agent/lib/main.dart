import 'package:flutter/material.dart';
import 'package:presentation_agent/app/deck_app.dart';

const _defaultDeckId = 'deck_20260405_final_ru_001';

void main() {
  runApp(
    const PresentationDeckBootstrap(
      deckId: String.fromEnvironment('DECK_ID', defaultValue: _defaultDeckId),
    ),
  );
}
