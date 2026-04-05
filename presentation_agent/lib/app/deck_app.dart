import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:presentation_agent/app/theme.dart';
import 'package:presentation_agent/models/presentation_plan.dart';
import 'package:presentation_agent/models/scene_plan.dart';
import 'package:presentation_agent/slides/slide_registry.dart';

class PresentationDeckBootstrap extends StatelessWidget {
  const PresentationDeckBootstrap({required this.deckId, super.key});

  final String deckId;

  Future<(PresentationPlan, ScenePlan)> _loadDeck() async {
    final planJson = await rootBundle.loadString(
      'assets/decks/$deckId/presentation_plan.json',
    );
    final sceneJson = await rootBundle.loadString(
      'assets/decks/$deckId/scene_plan.json',
    );
    final plan = PresentationPlan.fromAssetJson(planJson);
    final scenePlan = ScenePlan.fromJsonString(sceneJson);
    scenePlan.runFitChecks(plan);
    return (plan, scenePlan);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(PresentationPlan, ScenePlan)>(
      future: _loadDeck(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              backgroundColor: const Color(0xFF0B1020),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Failed to load deck "$deckId": ${snapshot.error}',
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return MaterialApp(
            home: Scaffold(
              backgroundColor: const Color(0xFF0B1020),
              body: Center(
                child: CircularProgressIndicator(
                  color: PresentationTheme.seedColor,
                ),
              ),
            ),
          );
        }

        final (plan, scenePlan) = snapshot.data!;
        final slideRegistry = SlideRegistry(plan: plan, scenePlan: scenePlan);

        return FlutterDeckApp(
          configuration: PresentationTheme.deckConfiguration,
          darkTheme: PresentationTheme.darkTheme,
          lightTheme: PresentationTheme.lightTheme,
          themeMode: ThemeMode.dark,
          slides: slideRegistry.buildSlides(),
        );
      },
    );
  }
}
