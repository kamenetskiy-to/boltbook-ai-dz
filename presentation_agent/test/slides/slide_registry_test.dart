import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presentation_agent/models/presentation_plan.dart';
import 'package:presentation_agent/slides/slide_registry.dart';

void main() {
  test('slide registry builds one widget per slide kind in the deck', () {
    const rawJson = '''
    {
      "task_id": "task",
      "executor_id": "presentation_generator",
      "deck_id": "deck_test",
      "deck_title": "Deck",
      "deck_goal": "Goal",
      "target_audience": "reviewer",
      "narrative_mode": "technical_product",
      "slide_count_target": 7,
      "sources_used": [],
      "open_risks": [],
      "asset_requests": [],
      "slides": [
        {"slide_id":"title","kind":"title","route":"/title","title":"Title","key_points":[],"evidence_refs":[],"visual_direction":"hero","notes":"- note"},
        {"slide_id":"problem","kind":"problem","route":"/problem","title":"Problem","key_points":["one"],"evidence_refs":[],"visual_direction":"cards","notes":"- note"},
        {"slide_id":"solution","kind":"solution","route":"/solution","title":"Solution","key_points":["one"],"evidence_refs":[],"visual_direction":"cards","notes":"- note"},
        {"slide_id":"architecture","kind":"architecture","route":"/architecture","title":"Architecture","key_points":["one"],"evidence_refs":[],"visual_direction":"graph","notes":"- note","nodes":[{"title":"Broker","subtitle":"Node","detail":"Detail"}]},
        {"slide_id":"workflow","kind":"workflow","route":"/workflow","title":"Workflow","key_points":["one"],"evidence_refs":[],"visual_direction":"timeline","notes":"- note","workflow_steps":[{"title":"Step","detail":"Detail"}]},
        {"slide_id":"evidence","kind":"evidence","route":"/evidence","title":"Evidence","key_points":["one"],"evidence_refs":["README.md"],"visual_direction":"proof","notes":"- note"},
        {"slide_id":"cta","kind":"cta","route":"/cta","title":"CTA","key_points":["one"],"evidence_refs":[],"visual_direction":"action","notes":"- note"}
      ]
    }
    ''';

    final plan = PresentationPlan.fromAssetJson(rawJson);
    final registry = SlideRegistry(plan: plan);
    final slides = registry.buildSlides();

    expect(slides, hasLength(7));
    expect(slides, everyElement(isA<Widget>()));
  });
}
