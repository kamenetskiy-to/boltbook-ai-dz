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
              child: Row(
                children: [
                  Expanded(
                    flex: 7,
                    child: Center(
                      child: SceneReveal(
                        scene: scene,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 760),
                          child: SceneIntro(
                            spec: spec,
                            accentColor: PresentationTheme.action,
                            centered: false,
                            compact: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 5,
                    child: SceneReveal(
                      scene: scene,
                      delay: 0.12,
                      child: Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: PresentationTheme.action.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Text(
                          spec.headline ?? '',
                          style: FlutterDeckTheme.of(context)
                              .textTheme
                              .title
                              .copyWith(
                                color: Colors.white,
                                fontSize: 26,
                                height: 1.14,
                              ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SceneReveal(
              scene: scene,
              delay: 0.16,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: PresentationTheme.action.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: PresentationTheme.action.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Text(
                    '/deck',
                    style: FlutterDeckTheme.of(context).textTheme.bodySmall
                        .copyWith(
                          color: PresentationTheme.action,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
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
                          title: 'Вердикт ${i + 1}',
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
