import 'dart:io';

import 'package:presentation_agent/models/presentation_plan.dart';

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln(
      'usage: dart run tool/validate_deck.dart <presentation_plan.json>',
    );
    exitCode = 64;
    return;
  }

  final planPath = args.single;
  final rawJson = File(planPath).readAsStringSync();
  final plan = PresentationPlan.fromAssetJson(rawJson);

  stdout.writeln('Deck contract validated:');
  stdout.writeln('  deck_id: ${plan.deckId}');
  stdout.writeln('  target_audience: ${plan.targetAudience}');
  stdout.writeln('  output_language: ${plan.outputLanguage}');
}
