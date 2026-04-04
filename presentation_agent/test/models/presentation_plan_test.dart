import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presentation_agent/models/presentation_plan.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('presentation plan parses the first deck asset', () async {
    final rawJson = await rootBundle.loadString(
      'assets/decks/deck_20260404_001/presentation_plan.json',
    );

    final plan = PresentationPlan.fromAssetJson(rawJson);

    expect(plan.deckId, 'deck_20260404_001');
    expect(plan.slides, hasLength(7));
    expect(plan.sourcesUsed, contains('README.md'));
    expect(plan.slides.first.route, '/intro');
  });
}
