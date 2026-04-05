import 'dart:math' as math;

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
    final body = scene.composition == 'constellation-ring'
        ? _buildConstellation()
        : _buildDefault();

    return FlutterDeckSlide.blank(
      builder: (context) => SceneShell(
        scene: scene,
        accentColor: PresentationTheme.evidence,
        child: body,
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
    );
  }

  Widget _buildConstellation() {
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
          child: SceneReveal(
            scene: scene,
            delay: 0.16,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final center = Offset(
                  constraints.maxWidth * 0.56,
                  constraints.maxHeight * 0.46,
                );
                final radiusX = constraints.maxWidth * 0.26;
                final radiusY = constraints.maxHeight * 0.28;
                final positions = List.generate(spec.nodes.length, (index) {
                  final angle = (math.pi * 2 * index) / spec.nodes.length;
                  return Offset(
                    center.dx + math.cos(angle) * radiusX,
                    center.dy + math.sin(angle) * radiusY,
                  );
                });

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: center.dx - 150,
                      top: center.dy - 74,
                      child: Container(
                        width: 300,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: PresentationTheme.evidence.withValues(
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
                                fontSize: 22,
                                height: 1.15,
                              ),
                        ),
                      ),
                    ),
                    for (var i = 0; i < spec.nodes.length; i++)
                      Positioned(
                        left: positions[i].dx - 120,
                        top: positions[i].dy - 72,
                        child: SizedBox(
                          width: 240,
                          child: ArchitectureNode(
                            title: spec.nodes[i].title,
                            subtitle: spec.nodes[i].subtitle,
                            detail: spec.nodes[i].detail,
                            compact: true,
                          ),
                        ),
                      ),
                  ],
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
    );
  }
}
