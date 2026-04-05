import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presentation_agent/generation/pipeline.dart';
import 'package:presentation_agent/models/presentation_plan.dart';
import 'package:presentation_agent/models/scene_plan.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('scene plan validates the generated canonical deck', () async {
    final request = DeckRequest.fromJsonString(
      await rootBundle.loadString('assets/decks/deck/request.json'),
    );
    final plan = PresentationPlan.fromAssetJson(
      await rootBundle.loadString('assets/decks/deck/presentation_plan.json'),
    );
    final scenePlan = ScenePlan.fromJsonString(
      await rootBundle.loadString('assets/decks/deck/scene_plan.json'),
    );

    final fitReport = validateGeneratedDeck(
      request: request,
      plan: plan,
      scenePlan: scenePlan,
    );

    final repoRoot = Directory.current.parent;
    final generated = generateDeckArtifacts(request: request, repoRoot: repoRoot);

    expect(scenePlan.sceneFor('pipeline').composition, 'editorial-runway');
    expect(scenePlan.sceneFor('release-proof').fitBudget.maxMetrics, 3);
    expect(
      generated.narrativeBrief.proofOrder,
      contains('Затем показать живой A2A-контур и публичный след.'),
    );
    expect(fitReport.hasIssues, isFalse);
  });
}
