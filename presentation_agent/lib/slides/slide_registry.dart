import 'package:flutter/widgets.dart';
import 'package:presentation_agent/models/presentation_plan.dart';
import 'package:presentation_agent/models/slide_spec.dart';
import 'package:presentation_agent/slides/architecture_slide.dart';
import 'package:presentation_agent/slides/cta_slide.dart';
import 'package:presentation_agent/slides/evidence_slide.dart';
import 'package:presentation_agent/slides/problem_slide.dart';
import 'package:presentation_agent/slides/solution_slide.dart';
import 'package:presentation_agent/slides/title_slide.dart';
import 'package:presentation_agent/slides/workflow_slide.dart';

class SlideRegistry {
  SlideRegistry({required this.plan})
    : initialRoute = Uri.base.queryParameters['slide'];

  final PresentationPlan plan;
  final String? initialRoute;

  List<Widget> buildSlides() {
    return plan.slides.map(buildSlide).toList(growable: false);
  }

  Widget buildSlide(SlideSpec slide) {
    final isInitial = slide.route == initialRoute;
    switch (slide.kind) {
      case SlideKind.title:
        return TitleDeckSlide(spec: slide, plan: plan, isInitial: isInitial);
      case SlideKind.problem:
        return ProblemDeckSlide(spec: slide, isInitial: isInitial);
      case SlideKind.solution:
        return SolutionDeckSlide(spec: slide, isInitial: isInitial);
      case SlideKind.architecture:
        return ArchitectureDeckSlide(spec: slide, isInitial: isInitial);
      case SlideKind.workflow:
        return WorkflowDeckSlide(spec: slide, isInitial: isInitial);
      case SlideKind.evidence:
        return EvidenceDeckSlide(spec: slide, isInitial: isInitial);
      case SlideKind.cta:
        return CtaDeckSlide(spec: slide, isInitial: isInitial);
    }
  }
}
