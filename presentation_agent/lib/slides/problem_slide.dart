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
                compact: true,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: SceneReveal(
                      scene: scene,
                      delay: 0.12,
                      child: Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: PresentationTheme.warning.withValues(
                              alpha: 0.26,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ключевой выбор',
                              style: FlutterDeckTheme.of(context)
                                  .textTheme
                                  .bodySmall
                                  .copyWith(
                                    color: PresentationTheme.warning,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              spec.headline ?? '',
                              style: FlutterDeckTheme.of(context)
                                  .textTheme
                                  .title
                                  .copyWith(
                                    color: Colors.white,
                                    fontSize: 28,
                                    height: 1.12,
                                  ),
                            ),
                            const Spacer(),
                            for (final metric in spec.metrics) ...[
                              MetricChip(
                                label: metric.label,
                                value: metric.value,
                                compact: true,
                              ),
                              const SizedBox(height: 10),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 7,
                    child: Column(
                      children: [
                        for (var i = 0; i < spec.keyPoints.length; i++) ...[
                          SceneReveal(
                            scene: scene,
                            delay: 0.18 + (i * 0.08),
                            child: SignalCard(
                              title: 'Следствие ${i + 1}',
                              body: spec.keyPoints[i],
                              indexLabel: '0${i + 1}',
                              accentColor: PresentationTheme.warning,
                              compact: true,
                            ),
                          ),
                          if (i + 1 < spec.keyPoints.length)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  width: 2,
                                  height: 22,
                                  margin: const EdgeInsets.only(left: 18),
                                  color: PresentationTheme.warning.withValues(
                                    alpha: 0.36,
                                  ),
                                ),
                              ),
                            ),
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
                title: 'Опора на факты',
                refs: spec.evidenceRefs,
                accentColor: PresentationTheme.warning,
                compact: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
