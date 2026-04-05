import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:presentation_agent/app/theme.dart';
import 'package:presentation_agent/models/scene_plan.dart';
import 'package:presentation_agent/models/slide_spec.dart';
import 'package:presentation_agent/widgets/architecture_node.dart';
import 'package:presentation_agent/widgets/deck_scene.dart';
import 'package:presentation_agent/widgets/evidence_callout.dart';

class ArchitectureDeckSlide extends FlutterDeckSlideWidget {
  ArchitectureDeckSlide({
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
              child: SceneReveal(
                scene: scene,
                delay: 0.16,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = 14.0;
                    final columns = constraints.maxWidth >= 1180 ? 3 : 2;
                    final width =
                        (constraints.maxWidth - (spacing * (columns - 1))) /
                        columns;

                    return Align(
                      alignment: Alignment.topLeft,
                      child: Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          for (final node in spec.nodes)
                            SizedBox(
                              width: width,
                              child: ArchitectureNode(
                                title: node.title,
                                subtitle: node.subtitle,
                                detail: node.detail,
                                compact: true,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),
            SceneReveal(
              scene: scene,
              delay: 0.24,
              child: EvidenceCallout(
                title: 'Откуда взяты факты',
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
