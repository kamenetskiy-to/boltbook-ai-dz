import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:presentation_agent/app/theme.dart';
import 'package:presentation_agent/models/scene_plan.dart';
import 'package:presentation_agent/models/slide_spec.dart';
import 'package:presentation_agent/widgets/deck_scene.dart';
import 'package:presentation_agent/widgets/metric_chip.dart';
import 'package:presentation_agent/widgets/evidence_callout.dart';

class EvidenceDeckSlide extends FlutterDeckSlideWidget {
  EvidenceDeckSlide({
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
    final content = switch (scene.composition) {
      'proof-mosaic' => _buildProofMosaic(),
      'audit-wall' => _buildAuditWall(),
      _ => _buildDefault(),
    };

    return FlutterDeckSlide.blank(
      builder: (context) => SceneShell(
        scene: scene,
        accentColor: PresentationTheme.evidence,
        child: content,
      ),
    );
  }

  Widget _buildDefault() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SceneReveal(
          scene: scene,
          child: SceneIntro(
            spec: spec,
            accentColor: PresentationTheme.evidence,
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
                  delay: 0.14,
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
              const SizedBox(width: 18),
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    for (var i = 0; i < spec.keyPoints.length; i++) ...[
                      SceneReveal(
                        scene: scene,
                        delay: 0.16 + (i * 0.08),
                        child: SignalCard(
                          title: 'Подтверждение',
                          body: spec.keyPoints[i],
                          accentColor: PresentationTheme.evidence,
                          compact: true,
                        ),
                      ),
                      if (i + 1 < spec.keyPoints.length)
                        const SizedBox(height: 10),
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
          delay: 0.28,
          child: EvidenceCallout(
            title: 'Ссылки на доказательства',
            refs: spec.evidenceRefs,
            accentColor: PresentationTheme.evidence,
            compact: true,
          ),
        ),
      ],
    );
  }

  Widget _buildProofMosaic() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SceneReveal(
                      scene: scene,
                      child: SceneIntro(
                        spec: spec,
                        accentColor: PresentationTheme.evidence,
                        compact: true,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SceneReveal(
                      scene: scene,
                      delay: 0.12,
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
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 7,
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.45,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (var i = 0; i < spec.keyPoints.length; i++)
                      SceneReveal(
                        scene: scene,
                        delay: 0.16 + (i * 0.08),
                        child: SignalCard(
                          title: 'Доказательство ${i + 1}',
                          body: spec.keyPoints[i],
                          accentColor: PresentationTheme.evidence,
                          compact: true,
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
          delay: 0.28,
          child: EvidenceCallout(
            title: 'Ссылки на доказательства',
            refs: spec.evidenceRefs,
            accentColor: PresentationTheme.evidence,
            compact: true,
          ),
        ),
      ],
    );
  }

  Widget _buildAuditWall() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SceneReveal(
          scene: scene,
          child: SceneIntro(
            spec: spec,
            accentColor: PresentationTheme.evidence,
            compact: true,
          ),
        ),
        const SizedBox(height: 18),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: SceneReveal(
                  scene: scene,
                  delay: 0.12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
              const SizedBox(width: 20),
              Expanded(
                flex: 8,
                child: Column(
                  children: [
                    for (var i = 0; i < spec.keyPoints.length; i++) ...[
                      SceneReveal(
                        scene: scene,
                        delay: 0.18 + (i * 0.08),
                        child: SignalCard(
                          title: 'Проверка ${i + 1}',
                          body: spec.keyPoints[i],
                          accentColor: PresentationTheme.evidence,
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
          delay: 0.28,
          child: EvidenceCallout(
            title: 'Ссылки на доказательства',
            refs: spec.evidenceRefs,
            accentColor: PresentationTheme.evidence,
            compact: true,
          ),
        ),
      ],
    );
  }
}
