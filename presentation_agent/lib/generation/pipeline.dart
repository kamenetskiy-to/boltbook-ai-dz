import 'dart:convert';
import 'dart:io';

import 'package:presentation_agent/models/presentation_plan.dart';
import 'package:presentation_agent/models/scene_plan.dart';
import 'package:presentation_agent/models/slide_spec.dart';

const reviewerCopyStyle =
    'Ты - креативный ИИ-медиажурналист. Ты пишешь аккуратно, лаконично, '
    'современным, живым языком. Ты не используешь англицизмы, твоя аудитория '
    'полностью русскоязычная. Ты используешь Великий и Могучий, чтобы даже '
    'скептик почувствовал ясность, напряжение и доверие к фактам.';

class DeckRequest {
  const DeckRequest({
    required this.taskId,
    required this.requesterAgentName,
    required this.executorId,
    required this.deckId,
    required this.deckTitle,
    required this.title,
    required this.body,
    required this.taskTags,
    required this.deliveryPreference,
    required this.deckGoal,
    required this.targetAudience,
    required this.outputLanguage,
    required this.audienceSignals,
    required this.narrativeMode,
    required this.slideCountTarget,
    required this.sourceBundle,
    required this.expectedArtifacts,
    required this.canonicalWebPath,
    required this.canonicalPublicUrl,
  });

  factory DeckRequest.fromJsonString(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('request.json must be a JSON object');
    }

    return DeckRequest(
      taskId: decoded.string('task_id'),
      requesterAgentName: decoded.string('requester_agent_name'),
      executorId: decoded.string('executor_id'),
      deckId: decoded.string('deck_id'),
      deckTitle: decoded.string('deck_title'),
      title: decoded.string('title'),
      body: decoded.string('body'),
      taskTags: decoded.stringList('task_tags'),
      deliveryPreference: decoded.string('delivery_preference'),
      deckGoal: decoded.string('deck_goal'),
      targetAudience: decoded.string('target_audience'),
      outputLanguage: decoded.string('output_language'),
      audienceSignals: decoded.stringList('audience_signals'),
      narrativeMode: decoded.string('narrative_mode'),
      slideCountTarget: decoded.intValue('slide_count_target'),
      sourceBundle: decoded.stringList('source_bundle'),
      expectedArtifacts: decoded.stringList('expected_artifacts'),
      canonicalWebPath: decoded.string('canonical_web_path'),
      canonicalPublicUrl: decoded.string('canonical_public_url'),
    );
  }

  final String taskId;
  final String requesterAgentName;
  final String executorId;
  final String deckId;
  final String deckTitle;
  final String title;
  final String body;
  final List<String> taskTags;
  final String deliveryPreference;
  final String deckGoal;
  final String targetAudience;
  final String outputLanguage;
  final List<String> audienceSignals;
  final String narrativeMode;
  final int slideCountTarget;
  final List<String> sourceBundle;
  final List<String> expectedArtifacts;
  final String canonicalWebPath;
  final String canonicalPublicUrl;
}

class SourceEntry {
  const SourceEntry({
    required this.type,
    required this.path,
    required this.confidence,
    required this.facts,
  });

  final String type;
  final String path;
  final String confidence;
  final List<String> facts;

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'path': path,
      'confidence': confidence,
      'facts': facts,
    };
  }
}

class SourceBundleArtifact {
  const SourceBundleArtifact({
    required this.deckId,
    required this.sourceBundle,
    required this.unresolvedQuestions,
  });

  final String deckId;
  final List<SourceEntry> sourceBundle;
  final List<String> unresolvedQuestions;

  Map<String, dynamic> toJson() {
    return {
      'deck_id': deckId,
      'source_bundle': sourceBundle.map((entry) => entry.toJson()).toList(),
      'unresolved_questions': unresolvedQuestions,
    };
  }
}

class NarrativeBriefArtifact {
  const NarrativeBriefArtifact({
    required this.deckId,
    required this.audience,
    required this.skepticismProfile,
    required this.proofGoal,
    required this.proofOrder,
    required this.nonNegotiableClaims,
    required this.prohibitedClaims,
    required this.tone,
  });

  final String deckId;
  final String audience;
  final List<String> skepticismProfile;
  final String proofGoal;
  final List<String> proofOrder;
  final List<String> nonNegotiableClaims;
  final List<String> prohibitedClaims;
  final String tone;

  Map<String, dynamic> toJson() {
    return {
      'deck_id': deckId,
      'audience': audience,
      'skepticism_profile': skepticismProfile,
      'proof_goal': proofGoal,
      'proof_order': proofOrder,
      'non_negotiable_claims': nonNegotiableClaims,
      'prohibited_claims': prohibitedClaims,
      'tone': tone,
    };
  }
}

class GeneratedDeckArtifact {
  const GeneratedDeckArtifact({
    required this.request,
    required this.sources,
    required this.narrativeBrief,
    required this.scenePlan,
    required this.presentationPlan,
    required this.fitReport,
    required this.manifest,
    required this.runTrace,
  });

  final DeckRequest request;
  final SourceBundleArtifact sources;
  final NarrativeBriefArtifact narrativeBrief;
  final ScenePlan scenePlan;
  final PresentationPlan presentationPlan;
  final ScenePlanFitReport fitReport;
  final Map<String, dynamic> manifest;
  final Map<String, dynamic> runTrace;
}

GeneratedDeckArtifact generateDeckArtifacts({
  required DeckRequest request,
  required Directory repoRoot,
}) {
  final sources = _buildSourceBundle(request: request, repoRoot: repoRoot);
  final narrativeBrief = _buildNarrativeBrief(request);
  final scenePlan = _buildScenePlan(request);
  final presentationPlan = _buildPresentationPlan(request);
  final fitReport = scenePlan.runFitChecks(presentationPlan);
  if (fitReport.hasIssues) {
    throw FormatException(
      'Generated deck exceeded fit budgets:\n${fitReport.issues.join('\n')}',
    );
  }

  final manifest = {
    'task_id': request.taskId,
    'executor_id': request.executorId,
    'status': 'prepared',
    'deck_id': request.deckId,
    'deck_title': request.deckTitle,
    'canonical_web_url': request.canonicalPublicUrl,
    'artifact_urls': <String, dynamic>{},
    'screenshots': <String>[],
    'sources_used': request.sourceBundle,
    'summary':
        'Подготовлен новый reviewer-facing выпуск: сначала опорные источники, '
        'затем narrative brief, отдельный сцен-план, редактура, проверка '
        'кадра и выпуск только через /deck.',
    'risks': [
      'Долгоживущий опрос платформы по-прежнему выключен; презентация честно '
          'опирается на воспроизводимый след, а не на непрерывный фоновый шум.',
    ],
  };

  final runTrace = {
    'deck_id': request.deckId,
    'status': 'prepared',
    'source_count': sources.sourceBundle.length,
    'research_used': false,
    'slide_count': presentationPlan.slides.length,
    'build_commit_or_version': 'local-worktree',
    'stages': [
      {
        'name': 'source_bundle',
        'status': 'completed',
        'summary':
            'Локальный контекст собран из README, redesign brief и '
            'профильных документов.',
      },
      {
        'name': 'narrative_brief',
        'status': 'completed',
        'summary':
            'Зафиксированы скепсис проверяющего, порядок доказательства и '
            'запрещенные обещания.',
      },
      {
        'name': 'scene_plan',
        'status': 'completed',
        'summary':
            'Для каждого слайда зафиксированы композиция, иерархия, движение '
            'и размещение виджетов.',
      },
      {
        'name': 'copywriting',
        'status': 'completed',
        'summary':
            'Редактура выполнена по встроенному русскоязычному стилю без '
            'маркетинговой пустоты и англоязычного шума.',
      },
      {
        'name': 'fit_validation',
        'status': 'completed',
        'summary': 'Прогон по бюджетам компоновки завершен без переполнения.',
      },
      {
        'name': 'render_and_capture',
        'status': 'pending',
        'summary':
            'После Flutter build будут сняты кадры по всем маршрутам deck.',
      },
      {
        'name': 'screenshot_critique',
        'status': 'pending',
        'summary':
            'Кадры еще не проверены по контрасту, заполненности и различимости.',
      },
    ],
    'copy_style': reviewerCopyStyle,
    'narrative_brief': narrativeBrief.toJson(),
    'fit_validation': fitReport.toJson(),
    'operator_notes': [
      'Narrative brief стал обязательной стадией перед сцен-планом.',
      'Сценарный план стал обязательной промежуточной стадией перед текстом.',
      'Проверка компоновки останавливает сборку до Flutter build, если текст '
          'разваливает кадр.',
      'Скриншоты теперь не только собираются, но и проходят формализованную '
          'послесборочную критику.',
      'Публичный путь публикации теперь каноничен: только /deck.',
    ],
  };

  return GeneratedDeckArtifact(
    request: request,
    sources: sources,
    narrativeBrief: narrativeBrief,
    scenePlan: scenePlan,
    presentationPlan: presentationPlan,
    fitReport: fitReport,
    manifest: manifest,
    runTrace: runTrace,
  );
}

void writeGeneratedDeckArtifact({
  required Directory outputDirectory,
  required GeneratedDeckArtifact artifact,
}) {
  outputDirectory.createSync(recursive: true);
  _writeJson(
    File('${outputDirectory.path}/sources.json'),
    artifact.sources.toJson(),
  );
  _writeJson(
    File('${outputDirectory.path}/scene_plan.json'),
    artifact.scenePlan.toJson(),
  );
  _writeJson(
    File('${outputDirectory.path}/narrative_brief.json'),
    artifact.narrativeBrief.toJson(),
  );
  _writeJson(
    File('${outputDirectory.path}/presentation_plan.json'),
    artifact.presentationPlan.toJson(),
  );
  _writeJson(File('${outputDirectory.path}/manifest.json'), artifact.manifest);
  _writeJson(File('${outputDirectory.path}/run_trace.json'), artifact.runTrace);
}

ScenePlanFitReport validateGeneratedDeck({
  required DeckRequest request,
  required PresentationPlan plan,
  required ScenePlan scenePlan,
}) {
  if (plan.deckId != request.deckId) {
    throw FormatException(
      'Plan deck id "${plan.deckId}" does not match request deck id '
      '"${request.deckId}"',
    );
  }

  if (scenePlan.canonicalWebPath != request.canonicalWebPath) {
    throw FormatException(
      'Scene plan canonical path "${scenePlan.canonicalWebPath}" does not '
      'match request canonical path "${request.canonicalWebPath}"',
    );
  }

  return scenePlan.runFitChecks(plan);
}

SourceBundleArtifact _buildSourceBundle({
  required DeckRequest request,
  required Directory repoRoot,
}) {
  final sources = <SourceEntry>[];
  for (final relativePath in request.sourceBundle) {
    final sourceFile = File('${repoRoot.path}/$relativePath');
    if (!sourceFile.existsSync()) {
      throw FormatException('Missing source file: $relativePath');
    }

    final facts = _factsForSource(relativePath);
    sources.add(
      SourceEntry(
        type: 'local_doc',
        path: relativePath,
        confidence: 'high',
        facts: facts,
      ),
    );
  }

  return SourceBundleArtifact(
    deckId: request.deckId,
    sourceBundle: sources,
    unresolvedQuestions: [
      'Если позже понадобится внешний показ без порта 8080, поверх /deck '
          'можно поставить обратный прокси; для текущего показа это не '
          'остановка.',
    ],
  );
}

NarrativeBriefArtifact _buildNarrativeBrief(DeckRequest request) {
  return NarrativeBriefArtifact(
    deckId: request.deckId,
    audience: request.targetAudience,
    skepticismProfile: const [
      'Проверяющий не обязан верить в большой готовый рынок.',
      'Ему нужен живой след, а не только локальный запуск.',
      'Однообразный инженерный нарратив убивает убедительность даже при хорошей архитектуре.',
    ],
    proofGoal:
        'Показать Boltbook Broker как работающий слой координации между '
        'агентами, где Fixer и presentation_generator выступают реальными '
        'исполнителями, а /deck служит финальным reviewer-facing артефактом.',
    proofOrder: const [
      'Сначала объяснить, почему брокер — это слой координации, а не витрина.',
      'Затем показать живой A2A-контур и публичный след.',
      'После этого закрепить архитектурную ось Model Colloquium.',
      'В конце доказать, что новая презентационная цепочка сама стала зрелым артефактом релиза.',
    ],
    nonNegotiableClaims: const [
      'Главный артефакт подачи — Boltbook Broker.',
      'Презентация обязана быть полностью русскоязычной и reviewer-facing.',
      'Публикация допускается только по каноническому пути /deck.',
    ],
    prohibitedClaims: const [
      'Нельзя выдавать проект за готовый маркетплейс.',
      'Нельзя использовать старый deck как содержательный референс.',
      'Нельзя заменять живой русский текст англоязычным техно-жаргоном.',
    ],
    tone:
        'Плотный, редакторский, живой и доказательный. Без канцелярита, без '
        'маркетинговой ваты, без лишнего пафоса.',
  );
}

ScenePlan _buildScenePlan(DeckRequest request) {
  return ScenePlan(
    deckId: request.deckId,
    canonicalWebPath: request.canonicalWebPath,
    copyStyle: reviewerCopyStyle,
    scenes: const [
      SceneSpec(
        slideId: 'title',
        kind: SlideKind.title,
        route: '/intro',
        composition: 'signal-stage',
        hierarchy: SceneHierarchy(
          primary: 'title',
          secondary: ['subtitle', 'headline'],
          supporting: ['metrics', 'deck_id'],
        ),
        motionIntent: 'orbit-pop',
        copyBrief:
            'Открыть презентацию как финальный показ для проверяющего: без '
            'шума, с ясным обещанием и с прямой связью между продуктом и '
            'доказательством.',
        widgetPlacements: [
          WidgetPlacementSpec(
            slot: 'badge',
            widget: 'eyebrow',
            position: 'top-left',
            emphasis: 'primary',
            maxItems: 1,
          ),
          WidgetPlacementSpec(
            slot: 'hero',
            widget: 'headline_block',
            position: 'center-left',
            emphasis: 'primary',
            maxItems: 1,
          ),
          WidgetPlacementSpec(
            slot: 'proof_strip',
            widget: 'metric_chip',
            position: 'bottom-left',
            emphasis: 'supporting',
            maxItems: 3,
          ),
        ],
        fitBudget: FitBudget(
          maxTitleChars: 32,
          maxHeadlineChars: 180,
          maxSubtitleChars: 220,
          maxKeyPoints: 0,
          maxMetrics: 3,
          maxNodes: 0,
          maxWorkflowSteps: 0,
          maxEvidenceRefs: 3,
          maxBodyChars: 280,
          maxVisualDirectionChars: 180,
          maxUnits: 58,
        ),
      ),
      SceneSpec(
        slideId: 'platform-reality',
        kind: SlideKind.problem,
        route: '/platform-reality',
        composition: 'tension-bridge',
        hierarchy: SceneHierarchy(
          primary: 'headline',
          secondary: ['key_points'],
          supporting: ['metrics', 'evidence_refs'],
        ),
        motionIntent: 'card-rise',
        copyBrief:
            'Честно показать ограничения платформы и сразу превратить каждое '
            'ограничение в инженерное решение.',
        widgetPlacements: [
          WidgetPlacementSpec(
            slot: 'lead',
            widget: 'intro',
            position: 'top-left',
            emphasis: 'primary',
            maxItems: 1,
          ),
          WidgetPlacementSpec(
            slot: 'column_a',
            widget: 'key_point_card',
            position: 'lower-left',
            emphasis: 'secondary',
            maxItems: 2,
          ),
          WidgetPlacementSpec(
            slot: 'column_b',
            widget: 'key_point_card',
            position: 'lower-right',
            emphasis: 'secondary',
            maxItems: 2,
          ),
          WidgetPlacementSpec(
            slot: 'rail',
            widget: 'metric_chip',
            position: 'right-rail',
            emphasis: 'supporting',
            maxItems: 3,
          ),
        ],
        fitBudget: FitBudget(
          maxTitleChars: 56,
          maxHeadlineChars: 170,
          maxSubtitleChars: 200,
          maxKeyPoints: 3,
          maxMetrics: 2,
          maxNodes: 0,
          maxWorkflowSteps: 0,
          maxEvidenceRefs: 3,
          maxBodyChars: 520,
          maxVisualDirectionChars: 180,
          maxUnits: 76,
        ),
      ),
      SceneSpec(
        slideId: 'artifact',
        kind: SlideKind.solution,
        route: '/artifact',
        composition: 'relay-diagram',
        hierarchy: SceneHierarchy(
          primary: 'headline',
          secondary: ['subtitle', 'metrics'],
          supporting: ['key_points', 'evidence_refs'],
        ),
        motionIntent: 'glide-left',
        copyBrief:
            'Показать продукт как уже собранный рабочий контур, а не как '
            'обещание будущего маркетплейса.',
        widgetPlacements: [
          WidgetPlacementSpec(
            slot: 'intro',
            widget: 'intro',
            position: 'left-stage',
            emphasis: 'primary',
            maxItems: 1,
          ),
          WidgetPlacementSpec(
            slot: 'proof_wall',
            widget: 'metric_chip',
            position: 'bottom-left',
            emphasis: 'secondary',
            maxItems: 3,
          ),
          WidgetPlacementSpec(
            slot: 'narrative_stack',
            widget: 'key_point_card',
            position: 'right-stage',
            emphasis: 'supporting',
            maxItems: 3,
          ),
        ],
        fitBudget: FitBudget(
          maxTitleChars: 60,
          maxHeadlineChars: 170,
          maxSubtitleChars: 200,
          maxKeyPoints: 3,
          maxMetrics: 3,
          maxNodes: 0,
          maxWorkflowSteps: 0,
          maxEvidenceRefs: 3,
          maxBodyChars: 520,
          maxVisualDirectionChars: 180,
          maxUnits: 80,
        ),
      ),
      SceneSpec(
        slideId: 'pipeline',
        kind: SlideKind.workflow,
        route: '/scene-pipeline',
        composition: 'editorial-runway',
        hierarchy: SceneHierarchy(
          primary: 'headline',
          secondary: ['workflow_steps'],
          supporting: ['key_points', 'evidence_refs'],
        ),
        motionIntent: 'trace-scan',
        copyBrief:
            'Сделать новую цепочку генерации главным героем: источники, '
            'сценарный план, редактура, проверка кадра, сборка и публикация.',
        widgetPlacements: [
          WidgetPlacementSpec(
            slot: 'rail',
            widget: 'intro',
            position: 'left-rail',
            emphasis: 'primary',
            maxItems: 1,
          ),
          WidgetPlacementSpec(
            slot: 'timeline',
            widget: 'workflow_step',
            position: 'right-stage',
            emphasis: 'secondary',
            maxItems: 6,
          ),
          WidgetPlacementSpec(
            slot: 'proof_footer',
            widget: 'evidence_callout',
            position: 'bottom',
            emphasis: 'supporting',
            maxItems: 1,
          ),
        ],
        fitBudget: FitBudget(
          maxTitleChars: 52,
          maxHeadlineChars: 170,
          maxSubtitleChars: 180,
          maxKeyPoints: 3,
          maxMetrics: 0,
          maxNodes: 0,
          maxWorkflowSteps: 6,
          maxEvidenceRefs: 3,
          maxBodyChars: 900,
          maxVisualDirectionChars: 180,
          maxUnits: 104,
        ),
      ),
      SceneSpec(
        slideId: 'fit-guardrails',
        kind: SlideKind.evidence,
        route: '/fit-guardrails',
        composition: 'audit-wall',
        hierarchy: SceneHierarchy(
          primary: 'headline',
          secondary: ['metrics', 'key_points'],
          supporting: ['evidence_refs'],
        ),
        motionIntent: 'dashboard-lift',
        copyBrief:
            'Показать, как новая система не дает тексту тихо вывалиться за '
            'границы кадра.',
        widgetPlacements: [
          WidgetPlacementSpec(
            slot: 'intro',
            widget: 'intro',
            position: 'top-left',
            emphasis: 'primary',
            maxItems: 1,
          ),
          WidgetPlacementSpec(
            slot: 'metrics_board',
            widget: 'metric_chip',
            position: 'left-board',
            emphasis: 'secondary',
            maxItems: 3,
          ),
          WidgetPlacementSpec(
            slot: 'proof_stack',
            widget: 'key_point_card',
            position: 'right-board',
            emphasis: 'secondary',
            maxItems: 3,
          ),
        ],
        fitBudget: FitBudget(
          maxTitleChars: 44,
          maxHeadlineChars: 176,
          maxSubtitleChars: 180,
          maxKeyPoints: 3,
          maxMetrics: 3,
          maxNodes: 0,
          maxWorkflowSteps: 0,
          maxEvidenceRefs: 3,
          maxBodyChars: 560,
          maxVisualDirectionChars: 180,
          maxUnits: 80,
        ),
      ),
      SceneSpec(
        slideId: 'runtime',
        kind: SlideKind.architecture,
        route: '/runtime',
        composition: 'constellation-ring',
        hierarchy: SceneHierarchy(
          primary: 'headline',
          secondary: ['nodes'],
          supporting: ['key_points', 'evidence_refs'],
        ),
        motionIntent: 'constellation',
        copyBrief:
            'Связать брокер, исполнителя, редактор презентации и публикацию '
            'на одной схеме без перегрузки.',
        widgetPlacements: [
          WidgetPlacementSpec(
            slot: 'intro',
            widget: 'intro',
            position: 'top-left',
            emphasis: 'primary',
            maxItems: 1,
          ),
          WidgetPlacementSpec(
            slot: 'node_grid',
            widget: 'architecture_node',
            position: 'center',
            emphasis: 'secondary',
            maxItems: 5,
          ),
          WidgetPlacementSpec(
            slot: 'evidence',
            widget: 'evidence_callout',
            position: 'bottom-right',
            emphasis: 'supporting',
            maxItems: 1,
          ),
        ],
        fitBudget: FitBudget(
          maxTitleChars: 48,
          maxHeadlineChars: 176,
          maxSubtitleChars: 180,
          maxKeyPoints: 3,
          maxMetrics: 0,
          maxNodes: 5,
          maxWorkflowSteps: 0,
          maxEvidenceRefs: 3,
          maxBodyChars: 940,
          maxVisualDirectionChars: 180,
          maxUnits: 98,
        ),
      ),
      SceneSpec(
        slideId: 'release-proof',
        kind: SlideKind.evidence,
        route: '/release-proof',
        composition: 'proof-mosaic',
        hierarchy: SceneHierarchy(
          primary: 'headline',
          secondary: ['metrics', 'key_points'],
          supporting: ['evidence_refs'],
        ),
        motionIntent: 'scanline',
        copyBrief:
            'Показать итоговую публикацию как выпускной щит: канонический '
            'адрес, снимки, след выполнения и зачистка старых путей.',
        widgetPlacements: [
          WidgetPlacementSpec(
            slot: 'url_panel',
            widget: 'metric_chip',
            position: 'left-board',
            emphasis: 'primary',
            maxItems: 3,
          ),
          WidgetPlacementSpec(
            slot: 'release_notes',
            widget: 'key_point_card',
            position: 'right-board',
            emphasis: 'secondary',
            maxItems: 3,
          ),
          WidgetPlacementSpec(
            slot: 'evidence',
            widget: 'evidence_callout',
            position: 'bottom',
            emphasis: 'supporting',
            maxItems: 1,
          ),
        ],
        fitBudget: FitBudget(
          maxTitleChars: 52,
          maxHeadlineChars: 176,
          maxSubtitleChars: 190,
          maxKeyPoints: 3,
          maxMetrics: 3,
          maxNodes: 0,
          maxWorkflowSteps: 0,
          maxEvidenceRefs: 3,
          maxBodyChars: 560,
          maxVisualDirectionChars: 180,
          maxUnits: 82,
        ),
      ),
      SceneSpec(
        slideId: 'decision',
        kind: SlideKind.cta,
        route: '/decision',
        composition: 'closing-manifesto',
        hierarchy: SceneHierarchy(
          primary: 'headline',
          secondary: ['key_points'],
          supporting: ['subtitle', 'evidence_refs'],
        ),
        motionIntent: 'poster-rise',
        copyBrief:
            'Закрыть показ как инженерный вердикт: работающий итог вместо '
            'чернового наброска.',
        widgetPlacements: [
          WidgetPlacementSpec(
            slot: 'hero',
            widget: 'intro',
            position: 'center',
            emphasis: 'primary',
            maxItems: 1,
          ),
          WidgetPlacementSpec(
            slot: 'claim_row',
            widget: 'key_point_card',
            position: 'bottom',
            emphasis: 'secondary',
            maxItems: 3,
          ),
        ],
        fitBudget: FitBudget(
          maxTitleChars: 48,
          maxHeadlineChars: 188,
          maxSubtitleChars: 190,
          maxKeyPoints: 3,
          maxMetrics: 0,
          maxNodes: 0,
          maxWorkflowSteps: 0,
          maxEvidenceRefs: 3,
          maxBodyChars: 440,
          maxVisualDirectionChars: 180,
          maxUnits: 68,
        ),
      ),
    ],
  );
}

PresentationPlan _buildPresentationPlan(DeckRequest request) {
  return PresentationPlan(
    taskId: request.taskId,
    executorId: request.executorId,
    deckId: request.deckId,
    deckTitle: request.deckTitle,
    deckGoal:
        'Финальная русскоязычная презентация для проверяющего: показать '
        'честный MVP Boltbook Broker, новую цепочку подготовки слайдов и '
        'каноническую публикацию по адресу /deck.',
    targetAudience: request.targetAudience,
    outputLanguage: request.outputLanguage,
    audienceSignals: request.audienceSignals,
    narrativeMode: request.narrativeMode,
    slideCountTarget: request.slideCountTarget,
    sourcesUsed: request.sourceBundle,
    openRisks: const [
      'Непрерывный живой опрос платформы по-прежнему выключен; это сознательный '
          'выбор ради чистого и проверяемого показа.',
    ],
    assetRequests: const [],
    slides: const [
      SlideSpec(
        slideId: 'title',
        kind: SlideKind.title,
        route: '/intro',
        title: 'Boltbook Broker',
        eyebrow: 'ФИНАЛЬНАЯ РУССКОЯЗЫЧНАЯ ВЕРСИЯ',
        headline:
            'Перед проверяющим не черновик и не технический каркас, а '
            'собранная презентация: честный продуктовый рассказ, строгая '
            'сборка и один канонический путь публикации.',
        subtitle:
            'Один брокер, один первый исполнитель, одна воспроизводимая '
            'цепочка от задачи до публичного следа.',
        keyPoints: [],
        evidenceRefs: [
          'README.md',
          'docs/presentation-agent-spec.md',
          'https://boltbook.ai/post/445',
        ],
        metrics: [
          MetricSpec(label: 'Язык показа', value: 'Русский'),
          MetricSpec(label: 'Канонический адрес', value: '/deck'),
          MetricSpec(label: 'Публичный след', value: 'post 445'),
        ],
        visualDirection:
            'Крупный заголовок, спокойное напряжение, световые орбиты вокруг '
            'главного тезиса и короткая полоса доказательств внизу.',
        notes:
            '- Открыть показ как финальную русскоязычную версию.\n'
            '- Сразу снять сомнение: это не временная заготовка.',
      ),
      SlideSpec(
        slideId: 'platform-reality',
        kind: SlideKind.problem,
        route: '/platform-reality',
        title: 'Платформа живая, но честность важнее красивой легенды',
        eyebrow: 'ИСПРАВНАЯ ОТПРАВНАЯ ТОЧКА',
        headline:
            'Проверяющему не нужна сказка про готовый рынок. Ему нужен ясный '
            'ответ: какие ограничения уже подтверждены и как они превращены в '
            'работающие решения.',
        subtitle:
            'Именно поэтому первый выпуск не маскирует пробелы платформы, а '
            'укладывает их в строгую инженерную рамку.',
        keyPoints: [
          'Полного списка исполнителей через готовый внешний каталог нет, '
              'поэтому реестр и подбор остаются у брокера.',
          'Личные сообщения требуют согласия, значит публичные отклики и '
              'посты остаются основным транспортом передачи.',
          'Социальные сигналы уже полезны, но источник истины для отбора пока '
              'должен жить в локальной базе и журнале действий.',
        ],
        evidenceRefs: [
          'docs/boltbook-api-capabilities-audit.md',
          'docs/first-iteration-technical-spec.md',
          'README.md',
        ],
        metrics: [
          MetricSpec(label: 'Поиск', value: 'лента и ручной посев'),
          MetricSpec(label: 'Связь', value: 'публично прежде всего'),
        ],
        visualDirection:
            'Сигнальные карточки в две колонны, справа сжатая рейка с '
            'ограничениями и спокойным оранжевым акцентом.',
        notes:
            '- Не нагнетать драму; это слайд про зрелость, а не про оправдания.\n'
            '- Каждое ограничение сразу связывать с решением.',
      ),
      SlideSpec(
        slideId: 'artifact',
        kind: SlideKind.solution,
        route: '/artifact',
        title: 'Брокер уже превращает сигнал в исполнимую передачу задачи',
        eyebrow: 'ТО, ЧТО УЖЕ СОБРАНО',
        headline:
            'Главный артефакт теперь продает не будущее обещание, а рабочий '
            'контур: брокер собирает портфели, объясняет выбор и передает '
            'задачу первому исполнителю.',
        subtitle:
            'Fixer остается первым живым исполнителем, а генератор презентации '
            'доказывает, что поверх этой основы можно выпускать убедительные '
            'артефакты для проверки.',
        keyPoints: [
          'Локальная база делает подбор объяснимым: у каждого решения есть '
              'след, причина и понятный источник фактов.',
          'Fixer показан как отдельная публичная личность, а не как декорация '
              'для снимка экрана.',
          'Будущая коллегия моделей уже выделена как шов развития, но не '
              'мешает нынешнему узкому и честному выпуску.',
        ],
        evidenceRefs: [
          'README.md',
          'docs/handoff.md',
          'docs/first-iteration-technical-spec.md',
        ],
        metrics: [
          MetricSpec(label: 'Первый исполнитель', value: 'Fixer'),
          MetricSpec(label: 'Источник истины', value: 'SQLite'),
          MetricSpec(label: 'Запас роста', value: 'коллегия моделей'),
        ],
        visualDirection:
            'Слева плотный вступительный блок, справа вертикальная стена '
            'аргументов, внизу полоса доказательств.',
        notes:
            '- Удерживать речь в логике продукта, а не в логике мечты.\n'
            '- Подчеркнуть различие между публичной ролью и внутренним MCP.',
      ),
      SlideSpec(
        slideId: 'pipeline',
        kind: SlideKind.workflow,
        route: '/scene-pipeline',
        title: 'Новая цепочка собирает показ в пять шагов',
        eyebrow: 'СЦЕНАРНЫЙ ПЛАН ПЕРЕД ТЕКСТОМ',
        headline:
            'Сначала источники, потом сценарный план, затем редактура, '
            'проверка кадра, сборка и публикация. Случайный текст больше не '
            'может проскочить сразу к выпуску.',
        subtitle:
            'Именно промежуточный сценарный план делает композицию, ритм и '
            'движение предсказуемыми еще до написания окончательной копии.',
        keyPoints: [
          'Сценарный план заранее фиксирует композицию кадра, иерархию смысла, '
              'движение и места для виджетов.',
          'Редактура работает по готовому замыслу, поэтому текст больше не '
              'дерется с макетом.',
          'Сборка стартует только после проверки языка, аудитории и '
              'вместимости кадра.',
        ],
        evidenceRefs: [
          'presentation_agent/tool/generate_deck.dart',
          'presentation_agent/tool/validate_deck.dart',
          'docs/presentation-agent-runbook.md',
        ],
        workflowSteps: [
          WorkflowStepSpec(
            title: 'Собрать исходный свод',
            detail:
                'README и профильные документы дают факты без вольного домысливания.',
          ),
          WorkflowStepSpec(
            title: 'Сделать сценарный план',
            detail:
                'Для каждого кадра заранее определяются композиция, главный тезис и размещение элементов.',
          ),
          WorkflowStepSpec(
            title: 'Написать окончательный текст',
            detail:
                'Редактура следует встроенному русскоязычному стилю и пишет для проверяющего.',
          ),
          WorkflowStepSpec(
            title: 'Проверить вместимость кадра',
            detail:
                'Бюджеты текста и блоков останавливают сборку, если кадр норовит выйти за пределы видимой области.',
          ),
          WorkflowStepSpec(
            title: 'Собрать и опубликовать',
            detail:
                'После снимков и проверки адреса публикация уходит только по пути /deck.',
          ),
        ],
        visualDirection:
            'Слева поясняющий рейл, справа вертикальная башня шагов с '
            'светлой линией прохождения.',
        notes:
            '- Это главный инженерный слайд всей работы.\n'
            '- Нужно прямо произнести, что раньше такого промежуточного шага не было.',
      ),
      SlideSpec(
        slideId: 'fit-guardrails',
        kind: SlideKind.evidence,
        route: '/fit-guardrails',
        title: 'Текст больше не вываливается из кадра',
        eyebrow: 'ПРОВЕРКА КОМПОНОВКИ',
        headline:
            'Вертикальное переполнение теперь считается ошибкой подготовки: '
            'на каждый кадр есть бюджет длины, числа блоков и примерной '
            'высоты содержимого.',
        subtitle:
            'Если текст расползается, сборка падает еще до выпуска и не '
            'подменяет аккуратный кадр прокруткой.',
        keyPoints: [
          'Сценарный план задает пределы для заголовка, подзаголовка, '
              'карточек, узлов, шагов и ссылок на доказательства.',
          'Проверка оценивает примерную высоту содержимого и бьет тревогу, '
              'если макет уже не укладывается в кадр.',
          'Та же проверка защищает русский язык и сигналы аудитории, так что '
              'ошибка с англоязычной выдачей не повторится.',
        ],
        evidenceRefs: [
          'presentation_agent/lib/models/scene_plan.dart',
          'presentation_agent/tool/validate_deck.dart',
          'presentation_agent/test/models/scene_plan_test.dart',
        ],
        metrics: [
          MetricSpec(label: 'Падение сборки', value: 'до Flutter build'),
          MetricSpec(label: 'Прокрутка', value: 'только крайний случай'),
          MetricSpec(label: 'Сигналы аудитории', value: 'обязательны'),
        ],
        visualDirection:
            'Щит доказательств: слева три крупные метрики, справа стек '
            'аргументов, внизу спокойная плашка со ссылками на код.',
        notes:
            '- Подчеркнуть, что проверка не декоративная, а блокирующая.\n'
            '- Важно явно связать вместимость кадра и язык выдачи.',
      ),
      SlideSpec(
        slideId: 'runtime',
        kind: SlideKind.architecture,
        route: '/runtime',
        title: 'Система небольшая, но уже убедительная',
        eyebrow: 'ОБЩАЯ СХЕМА',
        headline:
            'Два прикладных процесса, локальный журнал, отдельный генератор '
            'презентации и публикация на одной машине дают проверяющему '
            'достаточно фактов без архитектурной пены.',
        subtitle:
            'Новая презентационная цепочка встроена рядом с брокером и '
            'исполнителем, а не существует как второй, оторванный продукт.',
        keyPoints: [
          'Брокер и Fixer остаются отдельными публичными ролями даже на одной машине.',
          'След выполнения хранит, что было просмотрено, как принято решение '
              'и какой публичный шаг действительно случился.',
          'Генератор презентации проходит полный путь: источники, сценарий, '
              'текст, проверка, снимки и публикация.',
        ],
        evidenceRefs: [
          'docs/deployment-gcp.md',
          'docs/presentation-agent-runbook.md',
          'deploy/systemd/boltbook-decks.service',
        ],
        nodes: [
          ArchitectureNodeSpec(
            title: 'Boltbook Broker',
            subtitle: 'Главный артефакт',
            detail:
                'Принимает задачу, хранит портфели, подбирает исполнителя и объясняет выбор.',
          ),
          ArchitectureNodeSpec(
            title: 'Fixer',
            subtitle: 'Первый исполнитель',
            detail:
                'Отвечает на входящую передачу и показывает, что реестр живет не только на бумаге.',
          ),
          ArchitectureNodeSpec(
            title: 'Журнал и база',
            subtitle: 'Локальный след',
            detail:
                'Сохраняют портфели, задачи, действия транспорта и историю выполнения.',
          ),
          ArchitectureNodeSpec(
            title: 'Генератор презентации',
            subtitle: 'Артефакт для проверки',
            detail:
                'Собирает исходный свод, сценарный план, окончательный текст, проверку вместимости и публикацию.',
          ),
          ArchitectureNodeSpec(
            title: 'Публикация /deck',
            subtitle: 'Канонический показ',
            detail:
                'Один открытый адрес, снимки экрана и файлы следа без вороха версий.',
          ),
        ],
        visualDirection:
            'Созвездие из пяти узлов без излишней диаграммной мишуры, с '
            'чистой сеткой и холодным светом.',
        notes:
            '- Схема должна подтверждать устойчивость, а не впечатлять сложностью.\n'
            '- Обязательно показать, что /deck встроен в ту же систему.',
      ),
      SlideSpec(
        slideId: 'release-proof',
        kind: SlideKind.evidence,
        route: '/release-proof',
        title: 'Публикация ведет только в одно место',
        eyebrow: 'ВЫПУСК И ПРОВЕРКА',
        headline:
            'Итоговая презентация публикуется только по адресу '
            'http://34.38.33.15:8080/deck. Старые наружные пути удаляются или '
            'утрачивают значение для проверки.',
        subtitle:
            'После выпуска рядом лежат снимки экрана, описание артефакта и '
            'след выполнения, чтобы проверяющий видел не только страницу, но '
            'и подтверждение пути.',
        keyPoints: [
          'Развертывание кладет готовый выпуск в каталог /deck и вычищает '
              'старые публичные каталоги прежних выпусков.',
          'Служебный корень больше не показывает ворох версий: он ведет к '
              'одному каноническому показу.',
          'После копирования адрес проверяется по сети, а файлы описания '
              'получают окончательные ссылки и снимки.',
        ],
        evidenceRefs: [
          'presentation_agent/tool/deploy_deck_to_vm.sh',
          'presentation_agent/tool/capture_screenshots.sh',
          'docs/presentation-agent-runbook.md',
        ],
        metrics: [
          MetricSpec(label: 'Публичный адрес', value: '34.38.33.15:8080/deck'),
          MetricSpec(label: 'След выпуска', value: 'описание + журнал'),
          MetricSpec(label: 'Снимки', value: '3 кадра'),
        ],
        visualDirection:
            'Выпускной щит с крупным адресом, синими метками и спокойной '
            'полосой доказательств внизу.',
        notes:
            '- Здесь должен прозвучать прямой ответ на требование про /deck.\n'
            '- Отдельно назвать зачистку старых путей.',
      ),
      SlideSpec(
        slideId: 'decision',
        kind: SlideKind.cta,
        route: '/decision',
        title: 'Это уже итоговая подача, а не пробный прогон',
        eyebrow: 'ИНЖЕНЕРНЫЙ ВЕРДИКТ',
        headline:
            'Проверяющий получает собранный итог: русскоязычную презентацию, '
            'живой продуктовый рассказ, проверку вместимости и один ясный '
            'публичный адрес.',
        subtitle:
            'Следующий шаг теперь не в том, чтобы переделывать показ, а в том, '
            'чтобы расширять сам путь исполнения, не теряя этой дисциплины.',
        keyPoints: [
          'Презентация строится по сценарию, а не по случайному набору блоков.',
          'Текст пишет для проверяющего и держит русский язык без постороннего шума.',
          'Публикация больше не расползается по версиям: у показа один канон.',
        ],
        evidenceRefs: [
          'presentation_agent/tool/generate_deck.dart',
          'presentation_agent/tool/deploy_deck_to_vm.sh',
          'https://boltbook.ai/post/445',
        ],
        visualDirection:
            'Плакатный финал: крупный вердикт по центру и три коротких '
            'утверждения как подпорки под итог.',
        notes:
            '- Закрывать как уверенное инженерное решение.\n'
            '- Не уходить в дорожную карту и будущие обещания.',
      ),
    ],
  );
}

List<String> _factsForSource(String path) {
  switch (path) {
    case 'README.md':
      return const [
        'Boltbook Broker остается главным артефактом подачи.',
        'Fixer выступает первым публичным исполнителем в реестре.',
        'Публичная проверка уже опирается на след в post 445.',
      ];
    case 'docs/presentation-redesign-brief.md':
      return const [
        'Старый deck запрещено использовать как содержательный референс.',
        'Новый pipeline обязан включать narrative brief, scene plan, copywriting, fit validation и screenshot critique.',
        'Публичный reviewer-facing адрес должен оставаться только один: /deck.',
      ];
    case 'docs/presentation-generation-research-20260405.md':
      return const [
        'Сильные presentation pipelines сначала строят narrative planning, а потом пишут copy.',
        'Пострендерная visual critique должна быть блокирующей стадией, а не приложением к релизу.',
        'Различимые scene families лучше прямой генерации однотипных раскладок.',
      ];
    case 'docs/first-iteration-technical-spec.md':
      return const [
        'Источник истины для подбора остается в локальной SQLite-базе.',
        'Порядок передачи задачи остается публичным прежде всего, с явными запасными ходами.',
        'Проверяемый итог требует воспроизводимого следа и ясной операционной картины.',
      ];
    case 'docs/deployment-gcp.md':
      return const [
        'Целевая машина уже подтверждена: boltbook-mvp-vm в зоне europe-west1-b.',
        'После прошлой проверки службы сознательно оставлены в покое, чтобы не шуметь живым опросом.',
        'Внешний адрес 34.38.33.15 уже использовался для проверки артефактов.',
      ];
    case 'docs/presentation-agent-spec.md':
      return const [
        'Генератор презентации обязан строить веб-показ на Flutter и публиковать его на существующей машине.',
        'Сценарный план и проверяемый договор презентации должны быть детерминированны.',
        'Локальные документы имеют приоритет перед внешним поиском.',
      ];
    case 'docs/presentation-agent-runbook.md':
      return const [
        'Сборка, снимки экрана и публикация уже оформлены как воспроизводимые скрипты.',
        'Артефакт обязан содержать описание, след выполнения и снимки ключевых кадров.',
        'Новый выпуск должен публиковаться канонически через /deck.',
      ];
    default:
      throw FormatException('No source-fact mapping for $path');
  }
}

void _writeJson(File file, Map<String, dynamic> payload) {
  file.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(payload)}\n',
  );
}

extension _GenerationJsonMapX on Map<String, dynamic> {
  int intValue(String key) {
    final value = this[key];
    if (value is int) {
      return value;
    }
    throw FormatException('Expected integer for "$key": ${jsonEncode(value)}');
  }
}
