import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:presentation_agent/app/theme.dart';
import 'package:presentation_agent/models/presentation_plan.dart';
import 'package:presentation_agent/models/slide_spec.dart';
import 'package:presentation_agent/widgets/metric_chip.dart';

class TitleDeckSlide extends FlutterDeckSlideWidget {
  TitleDeckSlide({
    required this.spec,
    required this.plan,
    this.isInitial = false,
    super.key,
  }) : super(
         configuration: FlutterDeckSlideConfiguration(
           initial: isInitial,
           route: spec.route,
           title: spec.title,
           speakerNotes: spec.notes,
           footer: const FlutterDeckFooterConfiguration(showFooter: false),
         ),
       );

  final SlideSpec spec;
  final PresentationPlan plan;
  final bool isInitial;

  @override
  Widget build(BuildContext context) {
    final textTheme = FlutterDeckTheme.of(context).textTheme;

    return FlutterDeckSlide.blank(
      builder: (context) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF091223), Color(0xFF152548), Color(0xFF2C1647)],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -120,
              left: -80,
              child: _GlowOrb(
                size: 320,
                color: Color(0xFF7CFFB2),
                opacity: 0.16,
              ),
            ),
            const Positioned(
              right: -100,
              bottom: -130,
              child: _GlowOrb(
                size: 360,
                color: Color(0xFFFF6B6B),
                opacity: 0.14,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(80, 72, 80, 56),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    spec.eyebrow ?? plan.targetAudience.toUpperCase(),
                    style: textTheme.bodyMedium.copyWith(
                      color: PresentationTheme.seedColor,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: Text(
                      spec.title,
                      style: textTheme.display.copyWith(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: Text(
                      spec.subtitle ?? plan.deckGoal,
                      style: textTheme.bodyLarge.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      for (final metric in spec.metrics)
                        MetricChip(label: metric.label, value: metric.value),
                    ],
                  ),
                  const SizedBox(height: 36),
                  Container(
                    width: 720,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Text(
                      spec.headline ?? '',
                      style: textTheme.header.copyWith(
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Text(
                        'deck_id: ${plan.deckId}',
                        style: textTheme.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Text(
                        'executor: ${plan.executorId}',
                        style: textTheme.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
