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
    required this.outputLanguage,
    required this.audienceSignals,
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
      outputLanguage: decoded.string('output_language'),
      audienceSignals: decoded.stringList('audience_signals'),
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
  final String outputLanguage;
  final List<String> audienceSignals;
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
    if (audienceSignals.isEmpty) {
      throw const FormatException(
        'Deck must declare at least one audience signal for validation',
      );
    }
    if (outputLanguage != 'ru' && outputLanguage != 'en') {
      throw FormatException(
        'Unsupported output_language "$outputLanguage"; expected "ru" or "en"',
      );
    }

    final seenRoutes = <String>{};
    for (final slide in slides) {
      if (!seenRoutes.add(slide.route)) {
        throw FormatException('Duplicate slide route: ${slide.route}');
      }
    }

    final textCorpus = _allTextFragments().join(' ').toLowerCase();
    final cyrillicCount = RegExp(r'[а-яё]').allMatches(textCorpus).length;
    final latinCount = RegExp(r'[a-z]').allMatches(textCorpus).length;

    switch (outputLanguage) {
      case 'ru':
        if (cyrillicCount == 0 || cyrillicCount <= latinCount) {
          throw const FormatException(
            'Deck copy does not match output_language="ru"',
          );
        }
        break;
      case 'en':
        if (latinCount == 0 || latinCount < cyrillicCount) {
          throw const FormatException(
            'Deck copy does not match output_language="en"',
          );
        }
        break;
    }

    final visibleTextCorpus = _visibleTextFragments().join(' ').toLowerCase();
    final missingAudienceSignals = audienceSignals.where(
      (signal) => !visibleTextCorpus.contains(signal.toLowerCase()),
    );
    if (missingAudienceSignals.isNotEmpty) {
      throw FormatException(
        'Deck copy is missing audience signals: '
        '${missingAudienceSignals.join(', ')}',
      );
    }
  }

  Iterable<String> _allTextFragments() sync* {
    yield deckTitle;
    yield deckGoal;
    yield targetAudience;
    yield* _visibleTextFragments();
  }

  Iterable<String> _visibleTextFragments() sync* {
    yield deckTitle;
    for (final slide in slides) {
      yield slide.title;
      if (slide.eyebrow != null) {
        yield slide.eyebrow!;
      }
      if (slide.headline != null) {
        yield slide.headline!;
      }
      if (slide.subtitle != null) {
        yield slide.subtitle!;
      }
      yield slide.visualDirection;
      yield slide.notes;
      for (final point in slide.keyPoints) {
        yield point;
      }
      for (final metric in slide.metrics) {
        yield metric.label;
        yield metric.value;
      }
      for (final node in slide.nodes) {
        yield node.title;
        yield node.subtitle;
        yield node.detail;
      }
      for (final step in slide.workflowSteps) {
        yield step.title;
        yield step.detail;
      }
    }
  }
}
