import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:presentation_agent/app/theme.dart';
import 'package:presentation_agent/models/scene_plan.dart';
import 'package:presentation_agent/models/slide_spec.dart';
import 'package:presentation_agent/widgets/deck_scene.dart';

class CtaDeckSlide extends FlutterDeckSlideWidget {
  CtaDeckSlide({
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
        accentColor: PresentationTheme.action,
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SceneReveal(
                  scene: scene,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: SceneIntro(
                      spec: spec,
                      accentColor: PresentationTheme.action,
                      centered: true,
                      compact: true,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SceneReveal(
              scene: scene,
              delay: 0.18,
              child: SizedBox(
                height: 170,
                child: Row(
                  children: [
                    for (var i = 0; i < spec.keyPoints.length; i++) ...[
                      Expanded(
                        child: SignalCard(
                          title: 'Итог',
                          body: spec.keyPoints[i],
                          accentColor: PresentationTheme.action,
                          indexLabel: '0${i + 1}',
                          compact: true,
                        ),
                      ),
                      if (i + 1 < spec.keyPoints.length)
                        const SizedBox(width: 16),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
