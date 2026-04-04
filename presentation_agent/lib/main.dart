import 'package:flutter/material.dart';
import 'package:presentation_agent/app/deck_app.dart';

const _defaultDeckId = 'deck_20260404_001';

void main() {
  runApp(
    const PresentationDeckBootstrap(
      deckId: String.fromEnvironment('DECK_ID', defaultValue: _defaultDeckId),
    ),
  );
}
