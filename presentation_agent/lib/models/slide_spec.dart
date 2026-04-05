import 'dart:convert';

enum SlideKind {
  title,
  problem,
  solution,
  architecture,
  workflow,
  evidence,
  cta;

  static SlideKind parse(String rawKind) {
    return SlideKind.values.firstWhere(
      (kind) => kind.name == rawKind,
      orElse: () => throw FormatException('Unsupported slide kind: $rawKind'),
    );
  }
}

class MetricSpec {
  const MetricSpec({required this.label, required this.value});

  factory MetricSpec.fromJson(Map<String, dynamic> json) {
    return MetricSpec(label: json.string('label'), value: json.string('value'));
  }

  final String label;
  final String value;

  Map<String, dynamic> toJson() {
    return {'label': label, 'value': value};
  }
}

class ArchitectureNodeSpec {
  const ArchitectureNodeSpec({
    required this.title,
    required this.subtitle,
    required this.detail,
  });

  factory ArchitectureNodeSpec.fromJson(Map<String, dynamic> json) {
    return ArchitectureNodeSpec(
      title: json.string('title'),
      subtitle: json.string('subtitle'),
      detail: json.string('detail'),
    );
  }

  final String title;
  final String subtitle;
  final String detail;

  Map<String, dynamic> toJson() {
    return {'title': title, 'subtitle': subtitle, 'detail': detail};
  }
}

class WorkflowStepSpec {
  const WorkflowStepSpec({required this.title, required this.detail});

  factory WorkflowStepSpec.fromJson(Map<String, dynamic> json) {
    return WorkflowStepSpec(
      title: json.string('title'),
      detail: json.string('detail'),
    );
  }

  final String title;
  final String detail;

  Map<String, dynamic> toJson() {
    return {'title': title, 'detail': detail};
  }
}

class SlideSpec {
  const SlideSpec({
    required this.slideId,
    required this.kind,
    required this.route,
    required this.title,
    required this.keyPoints,
    required this.evidenceRefs,
    required this.visualDirection,
    required this.notes,
    this.eyebrow,
    this.headline,
    this.subtitle,
    this.metrics = const [],
    this.nodes = const [],
    this.workflowSteps = const [],
  });

  factory SlideSpec.fromJson(Map<String, dynamic> json) {
    return SlideSpec(
      slideId: json.string('slide_id'),
      kind: SlideKind.parse(json.string('kind')),
      route: json.string('route'),
      title: json.string('title'),
      eyebrow: json.optionalString('eyebrow'),
      headline: json.optionalString('headline'),
      subtitle: json.optionalString('subtitle'),
      keyPoints: json.stringList('key_points'),
      evidenceRefs: json.stringList('evidence_refs'),
      visualDirection: json.optionalString('visual_direction') ?? '',
      notes: json.optionalString('notes') ?? '',
      metrics: json.objectList('metrics').map(MetricSpec.fromJson).toList(),
      nodes: json
          .objectList('nodes')
          .map(ArchitectureNodeSpec.fromJson)
          .toList(),
      workflowSteps: json
          .objectList('workflow_steps')
          .map(WorkflowStepSpec.fromJson)
          .toList(),
    );
  }

  final String slideId;
  final SlideKind kind;
  final String route;
  final String title;
  final String? eyebrow;
  final String? headline;
  final String? subtitle;
  final List<String> keyPoints;
  final List<String> evidenceRefs;
  final String visualDirection;
  final String notes;
  final List<MetricSpec> metrics;
  final List<ArchitectureNodeSpec> nodes;
  final List<WorkflowStepSpec> workflowSteps;

  Map<String, dynamic> toJson() {
    return {
      'slide_id': slideId,
      'kind': kind.name,
      'route': route,
      'title': title,
      if (eyebrow != null) 'eyebrow': eyebrow,
      if (headline != null) 'headline': headline,
      if (subtitle != null) 'subtitle': subtitle,
      'key_points': keyPoints,
      'evidence_refs': evidenceRefs,
      'visual_direction': visualDirection,
      'notes': notes,
      if (metrics.isNotEmpty)
        'metrics': metrics.map((metric) => metric.toJson()).toList(),
      if (nodes.isNotEmpty)
        'nodes': nodes.map((node) => node.toJson()).toList(),
      if (workflowSteps.isNotEmpty)
        'workflow_steps': workflowSteps.map((step) => step.toJson()).toList(),
    };
  }
}

extension JsonMapX on Map<String, dynamic> {
  String string(String key) {
    final value = this[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    throw FormatException(
      'Expected non-empty string for "$key": ${jsonEncode(value)}',
    );
  }

  String? optionalString(String key) {
    final value = this[key];
    return value is String && value.isNotEmpty ? value : null;
  }

  List<String> stringList(String key) {
    final value = this[key];
    if (value == null) {
      return const [];
    }
    if (value is List) {
      return value
          .map(
            (item) => item is String
                ? item
                : throw FormatException('Expected string list for "$key"'),
          )
          .toList();
    }
    throw FormatException('Expected list for "$key"');
  }

  List<Map<String, dynamic>> objectList(String key) {
    final value = this[key];
    if (value == null) {
      return const [];
    }
    if (value is List) {
      return value
          .map(
            (item) => item is Map<String, dynamic>
                ? item
                : throw FormatException('Expected object list for "$key"'),
          )
          .toList();
    }
    throw FormatException('Expected object list for "$key"');
  }
}
