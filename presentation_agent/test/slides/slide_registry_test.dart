import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presentation_agent/models/presentation_plan.dart';
import 'package:presentation_agent/models/scene_plan.dart';
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
      "output_language": "en",
      "audience_signals": ["Title"],
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
    const rawScenePlan = '''
    {
      "deck_id": "deck_test",
      "canonical_web_path": "/deck",
      "copy_style": "style",
      "scenes": [
        {
          "slide_id":"title",
          "kind":"title",
          "route":"/title",
          "composition":"hero-orbit",
          "hierarchy":{"primary":"title","secondary":["subtitle"],"supporting":["metrics"]},
          "motion_intent":"orbit-pop",
          "copy_brief":"brief",
          "widget_placements":[{"slot":"hero","widget":"headline","position":"center","emphasis":"primary","max_items":1}],
          "fit_budget":{"max_title_chars":40,"max_headline_chars":120,"max_subtitle_chars":140,"max_key_points":0,"max_metrics":0,"max_nodes":0,"max_workflow_steps":0,"max_evidence_refs":0,"max_body_chars":0,"max_visual_direction_chars":120,"max_units":30}
        },
        {
          "slide_id":"problem",
          "kind":"problem",
          "route":"/problem",
          "composition":"signal-columns",
          "hierarchy":{"primary":"headline","secondary":["key_points"],"supporting":["metrics"]},
          "motion_intent":"card-rise",
          "copy_brief":"brief",
          "widget_placements":[{"slot":"body","widget":"card","position":"left","emphasis":"secondary","max_items":3}],
          "fit_budget":{"max_title_chars":40,"max_headline_chars":120,"max_subtitle_chars":140,"max_key_points":3,"max_metrics":0,"max_nodes":0,"max_workflow_steps":0,"max_evidence_refs":0,"max_body_chars":200,"max_visual_direction_chars":120,"max_units":40}
        },
        {
          "slide_id":"solution",
          "kind":"solution",
          "route":"/solution",
          "composition":"capsule-wall",
          "hierarchy":{"primary":"headline","secondary":["key_points"],"supporting":["metrics"]},
          "motion_intent":"glide-left",
          "copy_brief":"brief",
          "widget_placements":[{"slot":"body","widget":"card","position":"right","emphasis":"secondary","max_items":3}],
          "fit_budget":{"max_title_chars":40,"max_headline_chars":120,"max_subtitle_chars":140,"max_key_points":3,"max_metrics":0,"max_nodes":0,"max_workflow_steps":0,"max_evidence_refs":0,"max_body_chars":200,"max_visual_direction_chars":120,"max_units":40}
        },
        {
          "slide_id":"architecture",
          "kind":"architecture",
          "route":"/architecture",
          "composition":"radar-grid",
          "hierarchy":{"primary":"headline","secondary":["nodes"],"supporting":["evidence_refs"]},
          "motion_intent":"constellation",
          "copy_brief":"brief",
          "widget_placements":[{"slot":"grid","widget":"node","position":"center","emphasis":"secondary","max_items":3}],
          "fit_budget":{"max_title_chars":40,"max_headline_chars":120,"max_subtitle_chars":140,"max_key_points":3,"max_metrics":0,"max_nodes":3,"max_workflow_steps":0,"max_evidence_refs":1,"max_body_chars":220,"max_visual_direction_chars":120,"max_units":50}
        },
        {
          "slide_id":"workflow",
          "kind":"workflow",
          "route":"/workflow",
          "composition":"control-tower",
          "hierarchy":{"primary":"headline","secondary":["workflow_steps"],"supporting":["key_points"]},
          "motion_intent":"trace-scan",
          "copy_brief":"brief",
          "widget_placements":[{"slot":"timeline","widget":"step","position":"right","emphasis":"secondary","max_items":2}],
          "fit_budget":{"max_title_chars":40,"max_headline_chars":120,"max_subtitle_chars":140,"max_key_points":3,"max_metrics":0,"max_nodes":0,"max_workflow_steps":2,"max_evidence_refs":0,"max_body_chars":240,"max_visual_direction_chars":120,"max_units":50}
        },
        {
          "slide_id":"evidence",
          "kind":"evidence",
          "route":"/evidence",
          "composition":"proof-dashboard",
          "hierarchy":{"primary":"headline","secondary":["metrics","key_points"],"supporting":["evidence_refs"]},
          "motion_intent":"dashboard-lift",
          "copy_brief":"brief",
          "widget_placements":[{"slot":"proof","widget":"metric","position":"left","emphasis":"secondary","max_items":2}],
          "fit_budget":{"max_title_chars":40,"max_headline_chars":120,"max_subtitle_chars":140,"max_key_points":2,"max_metrics":2,"max_nodes":0,"max_workflow_steps":0,"max_evidence_refs":1,"max_body_chars":220,"max_visual_direction_chars":120,"max_units":45}
        },
        {
          "slide_id":"cta",
          "kind":"cta",
          "route":"/cta",
          "composition":"decision-poster",
          "hierarchy":{"primary":"headline","secondary":["key_points"],"supporting":["subtitle"]},
          "motion_intent":"poster-rise",
          "copy_brief":"brief",
          "widget_placements":[{"slot":"poster","widget":"card","position":"bottom","emphasis":"secondary","max_items":3}],
          "fit_budget":{"max_title_chars":40,"max_headline_chars":120,"max_subtitle_chars":140,"max_key_points":3,"max_metrics":0,"max_nodes":0,"max_workflow_steps":0,"max_evidence_refs":0,"max_body_chars":200,"max_visual_direction_chars":120,"max_units":40}
        }
      ]
    }
    ''';

    final plan = PresentationPlan.fromAssetJson(rawJson);
    final scenePlan = ScenePlan.fromJsonString(rawScenePlan);
    final registry = SlideRegistry(plan: plan, scenePlan: scenePlan);
    final slides = registry.buildSlides();

    expect(slides, hasLength(7));
    expect(slides, everyElement(isA<Widget>()));
  });
}
