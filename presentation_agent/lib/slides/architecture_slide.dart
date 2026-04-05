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
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SceneReveal(
                scene: scene,
                delay: 0.16,
                child: Wrap(
                  spacing: 18,
                  runSpacing: 18,
                  children: [
                    for (final node in spec.nodes)
                      ArchitectureNode(
                        title: node.title,
                        subtitle: node.subtitle,
                        detail: node.detail,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            SceneReveal(
              scene: scene,
              delay: 0.24,
              child: EvidenceCallout(
                title: 'Откуда взяты факты',
                refs: spec.evidenceRefs,
                accentColor: PresentationTheme.evidence,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
