import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:presentation_agent/app/theme.dart';
import 'package:presentation_agent/models/slide_spec.dart';
import 'package:presentation_agent/widgets/metric_chip.dart';
import 'package:presentation_agent/widgets/slide_frame.dart';

class SolutionDeckSlide extends FlutterDeckSlideWidget {
  SolutionDeckSlide({required this.spec, this.isInitial = false, super.key})
    : super(
        configuration: FlutterDeckSlideConfiguration(
          initial: isInitial,
          route: spec.route,
          title: spec.title,
          speakerNotes: spec.notes,
        ),
      );

  final SlideSpec spec;
  final bool isInitial;

  @override
  Widget build(BuildContext context) {
    return FlutterDeckSlide.blank(
      builder: (context) => SlideFrame(
        spec: spec,
        accentColor: PresentationTheme.seedColor,
        aside: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final metric in spec.metrics)
              MetricChip(label: metric.label, value: metric.value),
          ],
        ),
      ),
    );
  }
}
