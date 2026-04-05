import 'package:flutter/material.dart';
import 'package:presentation_agent/app/deck_app.dart';

const _defaultDeckId = 'deck';

void main() {
  runApp(
    const PresentationDeckBootstrap(
      deckId: String.fromEnvironment('DECK_ID', defaultValue: _defaultDeckId),
    ),
  );
}
