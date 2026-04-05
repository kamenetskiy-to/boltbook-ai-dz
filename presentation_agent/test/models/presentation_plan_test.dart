import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presentation_agent/generation/pipeline.dart';
import 'package:presentation_agent/models/presentation_plan.dart';
import 'package:presentation_agent/models/scene_plan.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('presentation plan parses the first deck asset', () async {
    final rawJson = await rootBundle.loadString(
      'assets/decks/deck/presentation_plan.json',
    );

    final plan = PresentationPlan.fromAssetJson(rawJson);

    expect(plan.deckId, 'deck');
    expect(plan.outputLanguage, 'ru');
    expect(plan.audienceSignals, contains('проверяющ'));
    expect(plan.slides, hasLength(8));
    expect(plan.sourcesUsed, contains('README.md'));
    expect(plan.slides.first.route, '/intro');
  });

  test(
    'scene plan matches the canonical deck and stays within fit budgets',
    () async {
      final request = DeckRequest.fromJsonString(
        await rootBundle.loadString('assets/decks/deck/request.json'),
      );
      final rawPlan = await rootBundle.loadString(
        'assets/decks/deck/presentation_plan.json',
      );
      final rawScene = await rootBundle.loadString(
        'assets/decks/deck/scene_plan.json',
      );

      final plan = PresentationPlan.fromAssetJson(rawPlan);
      final scenePlan = ScenePlan.fromJsonString(rawScene);
      final fitReport = validateGeneratedDeck(
        request: request,
        plan: plan,
        scenePlan: scenePlan,
      );

      expect(scenePlan.scenes, hasLength(plan.slides.length));
      expect(scenePlan.canonicalWebPath, '/deck');
      expect(fitReport.hasIssues, isFalse);
    },
  );

  test('presentation plan rejects copy that does not match Russian output', () {
    const rawJson = '''
    {
      "task_id": "task",
      "executor_id": "presentation_generator",
      "deck_id": "deck_invalid",
      "deck_title": "English deck",
      "deck_goal": "This copy should fail.",
      "target_audience": "reviewer",
      "output_language": "ru",
      "audience_signals": ["reviewer"],
      "narrative_mode": "technical_product",
      "slide_count_target": 1,
      "sources_used": [],
      "open_risks": [],
      "asset_requests": [],
      "slides": [
        {
          "slide_id":"title",
          "kind":"title",
          "route":"/intro",
          "title":"English only",
          "headline":"Still English",
          "subtitle":"No Russian copy here",
          "key_points":[],
          "evidence_refs":[],
          "visual_direction":"plain",
          "notes":"- note"
        }
      ]
    }
    ''';

    expect(
      () => PresentationPlan.fromAssetJson(rawJson),
      throwsA(isA<FormatException>()),
    );
  });
}
