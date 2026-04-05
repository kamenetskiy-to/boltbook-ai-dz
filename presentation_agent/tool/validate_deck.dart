import 'dart:io';

import 'package:presentation_agent/generation/pipeline.dart';
import 'package:presentation_agent/models/presentation_plan.dart';
import 'package:presentation_agent/models/scene_plan.dart';

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln('usage: dart run tool/validate_deck.dart <deck_directory>');
    exitCode = 64;
    return;
  }

  final deckDirectory = Directory(args.single);
  final request = DeckRequest.fromJsonString(
    File('${deckDirectory.path}/request.json').readAsStringSync(),
  );
  final plan = PresentationPlan.fromAssetJson(
    File('${deckDirectory.path}/presentation_plan.json').readAsStringSync(),
  );
  final scenePlan = ScenePlan.fromJsonString(
    File('${deckDirectory.path}/scene_plan.json').readAsStringSync(),
  );
  final fitReport = validateGeneratedDeck(
    request: request,
    plan: plan,
    scenePlan: scenePlan,
  );

  if (fitReport.hasIssues) {
    stderr.writeln('Fit validation failed:');
    for (final issue in fitReport.issues) {
      stderr.writeln('  - $issue');
    }
    exitCode = 65;
    return;
  }

  stdout.writeln('Deck contract validated:');
  stdout.writeln('  deck_id: ${plan.deckId}');
  stdout.writeln('  target_audience: ${plan.targetAudience}');
  stdout.writeln('  output_language: ${plan.outputLanguage}');
  stdout.writeln('  canonical_web_path: ${scenePlan.canonicalWebPath}');
  for (final result in fitReport.results) {
    stdout.writeln(
      '  fit: ${result.slideId} ${result.estimatedUnits}/${result.budgetUnits}',
    );
  }
}
