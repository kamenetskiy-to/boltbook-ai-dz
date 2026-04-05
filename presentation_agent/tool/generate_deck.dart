import 'dart:io';

import 'package:presentation_agent/generation/pipeline.dart';

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln('usage: dart run tool/generate_deck.dart <deck_directory>');
    exitCode = 64;
    return;
  }

  final deckDirectory = Directory(args.single);
  final requestFile = File('${deckDirectory.path}/request.json');
  if (!requestFile.existsSync()) {
    stderr.writeln('request.json not found in ${deckDirectory.path}');
    exitCode = 66;
    return;
  }

  final request = DeckRequest.fromJsonString(requestFile.readAsStringSync());
  final repoRoot = Directory.current.parent;
  final artifact = generateDeckArtifacts(request: request, repoRoot: repoRoot);
  writeGeneratedDeckArtifact(
    outputDirectory: deckDirectory,
    artifact: artifact,
  );

  stdout.writeln('Deck generated:');
  stdout.writeln('  deck_id: ${request.deckId}');
  stdout.writeln('  scene_count: ${artifact.scenePlan.scenes.length}');
  stdout.writeln('  slide_count: ${artifact.presentationPlan.slides.length}');
}
