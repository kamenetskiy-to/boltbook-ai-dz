import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:presentation_agent/app/theme.dart';
import 'package:presentation_agent/models/presentation_plan.dart';
import 'package:presentation_agent/models/scene_plan.dart';
import 'package:presentation_agent/models/slide_spec.dart';
import 'package:presentation_agent/widgets/deck_scene.dart';
import 'package:presentation_agent/widgets/metric_chip.dart';

class TitleDeckSlide extends FlutterDeckSlideWidget {
  TitleDeckSlide({
    required this.spec,
    required this.plan,
    required this.scene,
    this.isInitial = false,
    super.key,
  }) : super(
         configuration: FlutterDeckSlideConfiguration(
           initial: isInitial,
           route: spec.route,
           title: spec.title,
           speakerNotes: spec.notes,
           footer: const FlutterDeckFooterConfiguration(showFooter: false),
         ),
       );

  final SlideSpec spec;
  final PresentationPlan plan;
  final SceneSpec scene;
  final bool isInitial;

  @override
  Widget build(BuildContext context) {
    final textTheme = FlutterDeckTheme.of(context).textTheme;

    return FlutterDeckSlide.blank(
      builder: (context) => SceneShell(
        scene: scene,
        accentColor: PresentationTheme.seedColor,
        child: SceneReveal(
          scene: scene,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                spec.eyebrow ?? plan.targetAudience.toUpperCase(),
                style: textTheme.bodyMedium.copyWith(
                  color: PresentationTheme.seedColor,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                plan.targetAudience,
                style: textTheme.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.54),
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 7,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 760),
                            child: Text(
                              spec.title,
                              style: textTheme.display.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 760),
                            child: Text(
                              spec.subtitle ?? plan.deckGoal,
                              style: textTheme.bodyLarge.copyWith(
                                color: Colors.white.withValues(alpha: 0.82),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              for (final metric in spec.metrics)
                                MetricChip(
                                  label: metric.label,
                                  value: metric.value,
                                  compact: true,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 28),
                    Expanded(
                      flex: 5,
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 560),
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Text(
                            spec.headline ?? '',
                            style: textTheme.title.copyWith(
                              color: Colors.white,
                              fontSize: 24,
                              height: 1.18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 18,
                runSpacing: 8,
                children: [
                  Text(
                    'deck_id: ${plan.deckId}',
                    style: textTheme.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'language: ${plan.outputLanguage.toUpperCase()}',
                    style: textTheme.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'executor: ${plan.executorId}',
                    style: textTheme.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
