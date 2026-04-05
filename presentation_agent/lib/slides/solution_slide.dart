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
    final relayLabels = const [
      ('Broker', 'сигнал и выбор'),
      ('Fixer', 'контакт и ответ'),
      ('Артефакт', 'deck и trace'),
    ];

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
              child: Column(
                children: [
                  SizedBox(
                    height: 168,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        for (var i = 0; i < relayLabels.length; i++) ...[
                          Expanded(
                            child: SceneReveal(
                              scene: scene,
                              delay: 0.12 + (i * 0.08),
                              child: _RelayNode(
                                title: relayLabels[i].$1,
                                subtitle: relayLabels[i].$2,
                              ),
                            ),
                          ),
                          if (i + 1 < relayLabels.length)
                            Expanded(
                              child: Center(
                                child: Container(
                                  height: 2,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        PresentationTheme.seedColor
                                            .withValues(alpha: 0.0),
                                        PresentationTheme.seedColor
                                            .withValues(alpha: 0.7),
                                        PresentationTheme.seedColor
                                            .withValues(alpha: 0.0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ],
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
                            delay: 0.22,
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
                                  delay: 0.24 + (i * 0.08),
                                  child: SignalCard(
                                    title: 'Маршрут ${i + 1}',
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

class _RelayNode extends StatelessWidget {
  const _RelayNode({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = FlutterDeckTheme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: PresentationTheme.seedColor.withValues(alpha: 0.26),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.title.copyWith(
              color: Colors.white,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: textTheme.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}
