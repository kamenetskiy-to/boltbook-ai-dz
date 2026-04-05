import 'dart:convert';

import 'package:presentation_agent/models/presentation_plan.dart';
import 'package:presentation_agent/models/slide_spec.dart';

class ScenePlan {
  const ScenePlan({
    required this.deckId,
    required this.canonicalWebPath,
    required this.copyStyle,
    required this.scenes,
  });

  factory ScenePlan.fromJsonString(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('scene_plan.json must be a JSON object');
    }

    final plan = ScenePlan(
      deckId: decoded.string('deck_id'),
      canonicalWebPath: decoded.string('canonical_web_path'),
      copyStyle: decoded.string('copy_style'),
      scenes: decoded.objectList('scenes').map(SceneSpec.fromJson).toList(),
    );

    plan._validateStructure();
    return plan;
  }

  final String deckId;
  final String canonicalWebPath;
  final String copyStyle;
  final List<SceneSpec> scenes;

  SceneSpec sceneFor(String slideId) {
    return scenes.firstWhere(
      (scene) => scene.slideId == slideId,
      orElse: () => throw FormatException('Missing scene spec for $slideId'),
    );
  }

  ScenePlanFitReport runFitChecks(PresentationPlan plan) {
    _validateAgainst(plan);

    final results = <SlideFitResult>[];
    final issues = <String>[];

    for (final slide in plan.slides) {
      final scene = sceneFor(slide.slideId);
      final result = scene.fitBudget.estimate(slide);
      results.add(result);
      if (result.issues.isNotEmpty) {
        issues.addAll(result.issues);
      }
    }

    return ScenePlanFitReport(results: results, issues: issues);
  }

  Map<String, dynamic> toJson() {
    return {
      'deck_id': deckId,
      'canonical_web_path': canonicalWebPath,
      'copy_style': copyStyle,
      'scenes': scenes.map((scene) => scene.toJson()).toList(),
    };
  }

  void _validateStructure() {
    if (scenes.isEmpty) {
      throw const FormatException('Scene plan must contain at least one scene');
    }

    final seenSlideIds = <String>{};
    final seenRoutes = <String>{};
    for (final scene in scenes) {
      if (!seenSlideIds.add(scene.slideId)) {
        throw FormatException('Duplicate scene for slide ${scene.slideId}');
      }
      if (!seenRoutes.add(scene.route)) {
        throw FormatException('Duplicate scene route ${scene.route}');
      }
    }
  }

  void _validateAgainst(PresentationPlan plan) {
    if (plan.deckId != deckId) {
      throw FormatException(
        'Scene plan deck_id "$deckId" does not match plan deck_id '
        '"${plan.deckId}"',
      );
    }

    if (plan.slides.length != scenes.length) {
      throw FormatException(
        'Scene plan count ${scenes.length} does not match slide count '
        '${plan.slides.length}',
      );
    }

    for (final slide in plan.slides) {
      final scene = sceneFor(slide.slideId);
      if (scene.kind != slide.kind) {
        throw FormatException(
          'Scene kind ${scene.kind.name} does not match slide kind '
          '${slide.kind.name} for ${slide.slideId}',
        );
      }
      if (scene.route != slide.route) {
        throw FormatException(
          'Scene route ${scene.route} does not match slide route ${slide.route}',
        );
      }
    }
  }
}

class SceneSpec {
  const SceneSpec({
    required this.slideId,
    required this.kind,
    required this.route,
    required this.composition,
    required this.hierarchy,
    required this.motionIntent,
    required this.copyBrief,
    required this.widgetPlacements,
    required this.fitBudget,
  });

  factory SceneSpec.fromJson(Map<String, dynamic> json) {
    return SceneSpec(
      slideId: json.string('slide_id'),
      kind: SlideKind.parse(json.string('kind')),
      route: json.string('route'),
      composition: json.string('composition'),
      hierarchy: SceneHierarchy.fromJson(json.object('hierarchy')),
      motionIntent: json.string('motion_intent'),
      copyBrief: json.string('copy_brief'),
      widgetPlacements: json
          .objectList('widget_placements')
          .map(WidgetPlacementSpec.fromJson)
          .toList(),
      fitBudget: FitBudget.fromJson(json.object('fit_budget')),
    );
  }

  final String slideId;
  final SlideKind kind;
  final String route;
  final String composition;
  final SceneHierarchy hierarchy;
  final String motionIntent;
  final String copyBrief;
  final List<WidgetPlacementSpec> widgetPlacements;
  final FitBudget fitBudget;

  Map<String, dynamic> toJson() {
    return {
      'slide_id': slideId,
      'kind': kind.name,
      'route': route,
      'composition': composition,
      'hierarchy': hierarchy.toJson(),
      'motion_intent': motionIntent,
      'copy_brief': copyBrief,
      'widget_placements': widgetPlacements
          .map((placement) => placement.toJson())
          .toList(),
      'fit_budget': fitBudget.toJson(),
    };
  }
}

class SceneHierarchy {
  const SceneHierarchy({
    required this.primary,
    required this.secondary,
    required this.supporting,
  });

  factory SceneHierarchy.fromJson(Map<String, dynamic> json) {
    return SceneHierarchy(
      primary: json.string('primary'),
      secondary: json.stringList('secondary'),
      supporting: json.stringList('supporting'),
    );
  }

  final String primary;
  final List<String> secondary;
  final List<String> supporting;

  Map<String, dynamic> toJson() {
    return {
      'primary': primary,
      'secondary': secondary,
      'supporting': supporting,
    };
  }
}

class WidgetPlacementSpec {
  const WidgetPlacementSpec({
    required this.slot,
    required this.widget,
    required this.position,
    required this.emphasis,
    required this.maxItems,
  });

  factory WidgetPlacementSpec.fromJson(Map<String, dynamic> json) {
    return WidgetPlacementSpec(
      slot: json.string('slot'),
      widget: json.string('widget'),
      position: json.string('position'),
      emphasis: json.string('emphasis'),
      maxItems: json.intValue('max_items'),
    );
  }

  final String slot;
  final String widget;
  final String position;
  final String emphasis;
  final int maxItems;

  Map<String, dynamic> toJson() {
    return {
      'slot': slot,
      'widget': widget,
      'position': position,
      'emphasis': emphasis,
      'max_items': maxItems,
    };
  }
}

class FitBudget {
  const FitBudget({
    required this.maxTitleChars,
    required this.maxHeadlineChars,
    required this.maxSubtitleChars,
    required this.maxKeyPoints,
    required this.maxMetrics,
    required this.maxNodes,
    required this.maxWorkflowSteps,
    required this.maxEvidenceRefs,
    required this.maxBodyChars,
    required this.maxVisualDirectionChars,
    required this.maxUnits,
  });

  factory FitBudget.fromJson(Map<String, dynamic> json) {
    return FitBudget(
      maxTitleChars: json.intValue('max_title_chars'),
      maxHeadlineChars: json.intValue('max_headline_chars'),
      maxSubtitleChars: json.intValue('max_subtitle_chars'),
      maxKeyPoints: json.intValue('max_key_points'),
      maxMetrics: json.intValue('max_metrics'),
      maxNodes: json.intValue('max_nodes'),
      maxWorkflowSteps: json.intValue('max_workflow_steps'),
      maxEvidenceRefs: json.intValue('max_evidence_refs'),
      maxBodyChars: json.intValue('max_body_chars'),
      maxVisualDirectionChars: json.intValue('max_visual_direction_chars'),
      maxUnits: json.intValue('max_units'),
    );
  }

  final int maxTitleChars;
  final int maxHeadlineChars;
  final int maxSubtitleChars;
  final int maxKeyPoints;
  final int maxMetrics;
  final int maxNodes;
  final int maxWorkflowSteps;
  final int maxEvidenceRefs;
  final int maxBodyChars;
  final int maxVisualDirectionChars;
  final int maxUnits;

  SlideFitResult estimate(SlideSpec slide) {
    final issues = <String>[];
    final bodyChars =
        slide.keyPoints.join().length +
        slide.metrics.fold(
          0,
          (total, metric) => total + metric.label.length + metric.value.length,
        ) +
        slide.nodes.fold(
          0,
          (total, node) =>
              total +
              node.title.length +
              node.subtitle.length +
              node.detail.length,
        ) +
        slide.workflowSteps.fold(
          0,
          (total, step) => total + step.title.length + step.detail.length,
        ) +
        slide.evidenceRefs.join().length;

    void check(bool condition, String issue) {
      if (condition) {
        issues.add(issue);
      }
    }

    check(
      slide.title.length > maxTitleChars,
      '${slide.slideId}: title length ${slide.title.length} > $maxTitleChars',
    );
    check(
      (slide.headline?.length ?? 0) > maxHeadlineChars,
      '${slide.slideId}: headline length ${(slide.headline?.length ?? 0)} '
      '> $maxHeadlineChars',
    );
    check(
      (slide.subtitle?.length ?? 0) > maxSubtitleChars,
      '${slide.slideId}: subtitle length ${(slide.subtitle?.length ?? 0)} '
      '> $maxSubtitleChars',
    );
    check(
      slide.keyPoints.length > maxKeyPoints,
      '${slide.slideId}: key point count ${slide.keyPoints.length} > $maxKeyPoints',
    );
    check(
      slide.metrics.length > maxMetrics,
      '${slide.slideId}: metric count ${slide.metrics.length} > $maxMetrics',
    );
    check(
      slide.nodes.length > maxNodes,
      '${slide.slideId}: node count ${slide.nodes.length} > $maxNodes',
    );
    check(
      slide.workflowSteps.length > maxWorkflowSteps,
      '${slide.slideId}: workflow step count ${slide.workflowSteps.length} '
      '> $maxWorkflowSteps',
    );
    check(
      slide.evidenceRefs.length > maxEvidenceRefs,
      '${slide.slideId}: evidence ref count ${slide.evidenceRefs.length} '
      '> $maxEvidenceRefs',
    );
    check(
      bodyChars > maxBodyChars,
      '${slide.slideId}: body chars $bodyChars > $maxBodyChars',
    );
    check(
      slide.visualDirection.length > maxVisualDirectionChars,
      '${slide.slideId}: visual direction chars '
      '${slide.visualDirection.length} > $maxVisualDirectionChars',
    );

    final units =
        _headlineUnits(slide.title, 20) +
        _headlineUnits(slide.headline ?? '', 34) +
        _headlineUnits(slide.subtitle ?? '', 42) +
        slide.keyPoints.fold<int>(
          0,
          (total, point) => total + _bodyUnits(point, 42) + 3,
        ) +
        slide.metrics.fold<int>(
          0,
          (total, metric) =>
              total +
              _bodyUnits(metric.label, 18) +
              _bodyUnits(metric.value, 16) +
              2,
        ) +
        slide.nodes.fold<int>(
          0,
          (total, node) =>
              total +
              _bodyUnits(node.title, 20) +
              _bodyUnits(node.subtitle, 22) +
              _bodyUnits(node.detail, 42) +
              3,
        ) +
        slide.workflowSteps.fold<int>(
          0,
          (total, step) =>
              total +
              _bodyUnits(step.title, 24) +
              _bodyUnits(step.detail, 38) +
              4,
        ) +
        slide.evidenceRefs.fold<int>(
          0,
          (total, ref) => total + _bodyUnits(ref, 34) + 1,
        );

    check(
      units > maxUnits,
      '${slide.slideId}: estimated layout units $units > $maxUnits',
    );

    return SlideFitResult(
      slideId: slide.slideId,
      estimatedUnits: units,
      budgetUnits: maxUnits,
      issues: issues,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'max_title_chars': maxTitleChars,
      'max_headline_chars': maxHeadlineChars,
      'max_subtitle_chars': maxSubtitleChars,
      'max_key_points': maxKeyPoints,
      'max_metrics': maxMetrics,
      'max_nodes': maxNodes,
      'max_workflow_steps': maxWorkflowSteps,
      'max_evidence_refs': maxEvidenceRefs,
      'max_body_chars': maxBodyChars,
      'max_visual_direction_chars': maxVisualDirectionChars,
      'max_units': maxUnits,
    };
  }

  static int _headlineUnits(String text, int charsPerLine) {
    if (text.isEmpty) {
      return 0;
    }
    return ((text.length / charsPerLine).ceil() * 3) + 2;
  }

  static int _bodyUnits(String text, int charsPerLine) {
    if (text.isEmpty) {
      return 0;
    }
    return (text.length / charsPerLine).ceil();
  }
}

class SlideFitResult {
  const SlideFitResult({
    required this.slideId,
    required this.estimatedUnits,
    required this.budgetUnits,
    required this.issues,
  });

  final String slideId;
  final int estimatedUnits;
  final int budgetUnits;
  final List<String> issues;

  Map<String, dynamic> toJson() {
    return {
      'slide_id': slideId,
      'estimated_units': estimatedUnits,
      'budget_units': budgetUnits,
      'issues': issues,
    };
  }
}

class ScenePlanFitReport {
  const ScenePlanFitReport({required this.results, required this.issues});

  final List<SlideFitResult> results;
  final List<String> issues;

  bool get hasIssues => issues.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'slides': results.map((result) => result.toJson()).toList(),
      'issues': issues,
    };
  }
}

extension _SceneJsonMapX on Map<String, dynamic> {
  Map<String, dynamic> object(String key) {
    final value = this[key];
    if (value is Map<String, dynamic>) {
      return value;
    }
    throw FormatException('Expected object for "$key"');
  }

  int intValue(String key) {
    final value = this[key];
    if (value is int) {
      return value;
    }
    throw FormatException('Expected integer for "$key": ${jsonEncode(value)}');
  }
}
