import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:presentation_agent/app/theme.dart';
import 'package:presentation_agent/models/scene_plan.dart';
import 'package:presentation_agent/models/slide_spec.dart';
import 'package:presentation_agent/widgets/deck_scene.dart';
import 'package:presentation_agent/widgets/evidence_callout.dart';

class WorkflowDeckSlide extends FlutterDeckSlideWidget {
  WorkflowDeckSlide({
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
        accentColor: PresentationTheme.evidence,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: SceneReveal(
                      scene: scene,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SceneIntro(
                            spec: spec,
                            accentColor: PresentationTheme.evidence,
                            compact: true,
                          ),
                          const SizedBox(height: 14),
                          for (var i = 0; i < spec.keyPoints.length; i++) ...[
                            SignalCard(
                              title: 'Принцип ${i + 1}',
                              body: spec.keyPoints[i],
                              accentColor: PresentationTheme.evidence,
                              compact: true,
                            ),
                            if (i + 1 < spec.keyPoints.length)
                              const SizedBox(height: 10),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 7,
                    child: Column(
                      children: [
                        for (
                          var index = 0;
                          index < spec.workflowSteps.length;
                          index++
                        ) ...[
                          Expanded(
                            child: SceneReveal(
                              scene: scene,
                              delay: 0.1 + (index * 0.07),
                              child: _WorkflowStepCard(
                                index: index + 1,
                                title: spec.workflowSteps[index].title,
                                detail: spec.workflowSteps[index].detail,
                                compact: true,
                              ),
                            ),
                          ),
                          if (index + 1 < spec.workflowSteps.length)
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 22,
                                top: 6,
                                bottom: 6,
                              ),
                              child: Container(
                                width: 2,
                                height: 10,
                                color: Colors.white.withValues(alpha: 0.16),
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
                title: 'Кодовые опоры',
                refs: spec.evidenceRefs,
                accentColor: PresentationTheme.evidence,
                compact: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkflowStepCard extends StatelessWidget {
  const _WorkflowStepCard({
    required this.index,
    required this.title,
    required this.detail,
    this.compact = false,
  });

  final int index;
  final String title;
  final String detail;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = FlutterDeckTheme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: compact ? 44 : 52,
          height: compact ? 44 : 52,
          decoration: BoxDecoration(
            color: PresentationTheme.evidence.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(color: PresentationTheme.evidence),
          ),
          child: Center(
            child: Text(
              '$index',
              style: textTheme.title.copyWith(color: Colors.white),
            ),
          ),
        ),
        SizedBox(width: compact ? 16 : 20),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(compact ? 16 : 20),
            decoration: BoxDecoration(
              color: PresentationTheme.panelColor.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: PresentationTheme.panelBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.title.copyWith(
                    color: Colors.white,
                    fontSize: compact ? 18 : null,
                    height: compact ? 1.08 : null,
                  ),
                ),
                SizedBox(height: compact ? 6 : 8),
                Text(
                  detail,
                  style: textTheme.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: compact ? 15 : null,
                    height: compact ? 1.2 : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
