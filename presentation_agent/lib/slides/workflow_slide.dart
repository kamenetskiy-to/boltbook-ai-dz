import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:presentation_agent/app/theme.dart';
import 'package:presentation_agent/models/slide_spec.dart';
import 'package:presentation_agent/widgets/slide_frame.dart';

class WorkflowDeckSlide extends FlutterDeckSlideWidget {
  WorkflowDeckSlide({required this.spec, this.isInitial = false, super.key})
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
        accentColor: PresentationTheme.evidence,
        body: Column(
          children: [
            for (var index = 0; index < spec.workflowSteps.length; index++) ...[
              _WorkflowStepCard(
                index: index + 1,
                title: spec.workflowSteps[index].title,
                detail: spec.workflowSteps[index].detail,
              ),
              if (index + 1 < spec.workflowSteps.length)
                Padding(
                  padding: const EdgeInsets.only(left: 26),
                  child: Container(
                    width: 2,
                    height: 18,
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
            ],
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
  });

  final int index;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final textTheme = FlutterDeckTheme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
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
        const SizedBox(width: 20),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
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
                  style: textTheme.title.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  detail,
                  style: textTheme.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
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
