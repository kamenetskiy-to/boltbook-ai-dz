import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presentation_agent/app/theme.dart';
import 'package:presentation_agent/models/presentation_plan.dart';
import 'package:presentation_agent/models/scene_plan.dart';
import 'package:presentation_agent/slides/slide_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'canonical deck renders every slide at 1512x982 without overflow errors',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(1512, 982));

      final plan = PresentationPlan.fromAssetJson(
        await rootBundle.loadString('assets/decks/deck/presentation_plan.json'),
      );
      final scenePlan = ScenePlan.fromJsonString(
        await rootBundle.loadString('assets/decks/deck/scene_plan.json'),
      );
      final registry = SlideRegistry(plan: plan, scenePlan: scenePlan);

      final overflowErrors = <String>[];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        final message = details.exceptionAsString();
        if (message.contains('overflowed by') ||
            message.contains('A RenderFlex overflowed')) {
          overflowErrors.add(message);
        }
        originalOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      for (final slide in plan.slides) {
        overflowErrors.clear();
        await tester.pumpWidget(
          FlutterDeckApp(
            configuration: PresentationTheme.deckConfiguration,
            darkTheme: PresentationTheme.darkTheme,
            lightTheme: PresentationTheme.lightTheme,
            themeMode: ThemeMode.dark,
            slides: [registry.buildSlide(slide)],
          ),
        );
        await tester.pump(const Duration(milliseconds: 1200));
        await tester.pumpAndSettle();

        expect(
          overflowErrors,
          isEmpty,
          reason: 'visual overflow reported on ${slide.route}',
        );
      }
    },
  );
}
