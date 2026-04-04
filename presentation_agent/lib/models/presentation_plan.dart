import 'dart:convert';

import 'package:presentation_agent/models/slide_spec.dart';

class PresentationPlan {
  const PresentationPlan({
    required this.taskId,
    required this.executorId,
    required this.deckId,
    required this.deckTitle,
    required this.deckGoal,
    required this.targetAudience,
    required this.narrativeMode,
    required this.slideCountTarget,
    required this.sourcesUsed,
    required this.slides,
    required this.openRisks,
    required this.assetRequests,
  });

  factory PresentationPlan.fromAssetJson(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'presentation_plan.json must be a JSON object',
      );
    }

    final plan = PresentationPlan(
      taskId: decoded.string('task_id'),
      executorId: decoded.string('executor_id'),
      deckId: decoded.string('deck_id'),
      deckTitle: decoded.string('deck_title'),
      deckGoal: decoded.string('deck_goal'),
      targetAudience: decoded.string('target_audience'),
      narrativeMode: decoded.string('narrative_mode'),
      slideCountTarget: decoded['slide_count_target'] as int,
      sourcesUsed: decoded.stringList('sources_used'),
      slides: decoded.objectList('slides').map(SlideSpec.fromJson).toList(),
      openRisks: decoded.stringList('open_risks'),
      assetRequests: decoded.stringList('asset_requests'),
    );

    plan._validate();
    return plan;
  }

  final String taskId;
  final String executorId;
  final String deckId;
  final String deckTitle;
  final String deckGoal;
  final String targetAudience;
  final String narrativeMode;
  final int slideCountTarget;
  final List<String> sourcesUsed;
  final List<SlideSpec> slides;
  final List<String> openRisks;
  final List<String> assetRequests;

  void _validate() {
    if (slides.isEmpty) {
      throw const FormatException('Deck must contain at least one slide');
    }
    if (slides.length > slideCountTarget) {
      throw FormatException(
        'Deck contains ${slides.length} slides but target is $slideCountTarget',
      );
    }

    final seenRoutes = <String>{};
    for (final slide in slides) {
      if (!seenRoutes.add(slide.route)) {
        throw FormatException('Duplicate slide route: ${slide.route}');
      }
    }
  }
}
