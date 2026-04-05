import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:presentation_agent/app/theme.dart';
import 'package:presentation_agent/models/scene_plan.dart';
import 'package:presentation_agent/models/slide_spec.dart';
import 'package:presentation_agent/widgets/deck_scene.dart';
import 'package:presentation_agent/widgets/evidence_callout.dart';
import 'package:presentation_agent/widgets/metric_chip.dart';

class ProblemDeckSlide extends FlutterDeckSlideWidget {
  ProblemDeckSlide({
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
        accentColor: PresentationTheme.warning,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SceneReveal(
              scene: scene,
              child: SceneIntro(
                spec: spec,
                accentColor: PresentationTheme.warning,
              ),
            ),
            const SizedBox(height: 28),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 9,
                    child: Wrap(
                      spacing: 18,
                      runSpacing: 18,
                      children: [
                        for (var i = 0; i < spec.keyPoints.length; i++)
                          SizedBox(
                            width: 360,
                            child: SceneReveal(
                              scene: scene,
                              delay: 0.12 + (i * 0.08),
                              child: SignalCard(
                                title: 'Решение ${i + 1}',
                                body: spec.keyPoints[i],
                                indexLabel: '0${i + 1}',
                                accentColor: PresentationTheme.warning,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 4,
                    child: SceneReveal(
                      scene: scene,
                      delay: 0.24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final metric in spec.metrics) ...[
                            MetricChip(
                              label: metric.label,
                              value: metric.value,
                            ),
                            const SizedBox(height: 12),
                          ],
                          const SizedBox(height: 16),
                          EvidenceCallout(
                            title: 'Опора на факты',
                            refs: spec.evidenceRefs,
                            accentColor: PresentationTheme.warning,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
