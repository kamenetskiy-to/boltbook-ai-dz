import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:presentation_agent/app/theme.dart';
import 'package:presentation_agent/models/scene_plan.dart';
import 'package:presentation_agent/models/slide_spec.dart';
import 'package:presentation_agent/widgets/deck_scene.dart';
import 'package:presentation_agent/widgets/evidence_callout.dart';
import 'package:presentation_agent/widgets/metric_chip.dart';

class SolutionDeckSlide extends FlutterDeckSlideWidget {
  SolutionDeckSlide({
    required this.spec,
    required this.scene,
    this.isInitial = false,
    super.key,
  }) : super(
         configuration: FlutterDeckSlideConfiguration(
           initial: isInitial,
           route: spec.route,
           title: spec.title,
           speakerNotes: spec.notes,
         ),
       );

  final SlideSpec spec;
  final SceneSpec scene;
  final bool isInitial;

  @override
  Widget build(BuildContext context) {
    return FlutterDeckSlide.blank(
      builder: (context) => SceneShell(
        scene: scene,
        accentColor: PresentationTheme.seedColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SceneReveal(
              scene: scene,
              child: SceneIntro(
                spec: spec,
                accentColor: PresentationTheme.seedColor,
                compact: true,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: SceneReveal(
                      scene: scene,
                      delay: 0.16,
                      child: Wrap(
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
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 6,
                    child: Column(
                      children: [
                        for (var i = 0; i < spec.keyPoints.length; i++) ...[
                          SceneReveal(
                            scene: scene,
                            delay: 0.18 + (i * 0.08),
                            child: SignalCard(
                              title: 'Опорный тезис',
                              body: spec.keyPoints[i],
                              accentColor: PresentationTheme.seedColor,
                              compact: true,
                            ),
                          ),
                          if (i + 1 < spec.keyPoints.length)
                            const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SceneReveal(
              scene: scene,
              delay: 0.24,
              child: EvidenceCallout(
                title: 'Доказательства',
                refs: spec.evidenceRefs,
                accentColor: PresentationTheme.seedColor,
                compact: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
