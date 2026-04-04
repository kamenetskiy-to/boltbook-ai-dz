import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:presentation_agent/app/theme.dart';
import 'package:presentation_agent/models/slide_spec.dart';
import 'package:presentation_agent/widgets/slide_frame.dart';

class CtaDeckSlide extends FlutterDeckSlideWidget {
  CtaDeckSlide({required this.spec, this.isInitial = false, super.key})
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
      builder: (context) =>
          SlideFrame(spec: spec, accentColor: PresentationTheme.action),
    );
  }
}
