//
//  step_explanation.dart
//  Turing Lab
//
//  Minimal shared explanation/diagnostic schema for simulation and conversion
//  steps.
//
//  This model is intentionally lightweight so it can be attached to existing
//  step entities without deep refactors.
//

/// A human-readable explanation that can be attached to a simulation/configuration
/// step or an algorithm (conversion) step.
class StepExplanation {
  /// Optional short title used as a header in the UI.
  final String? title;

  /// One or more explanation bullets.
  ///
  /// Keep bullets short and user-facing; prefer structure over long prose.
  final List<String> bullets;

  /// Optional categorization for filtering/styling.
  final List<ExplanationCategory> categories;

  /// Optional targets to highlight in the UI (canvas, stack, tape, etc.).
  final List<HighlightTarget> highlights;

  /// Optional actionable hints.
  final List<SuggestedFix> suggestedFixes;

  const StepExplanation({
    this.title,
    this.bullets = const [],
    this.categories = const [],
    this.highlights = const [],
    this.suggestedFixes = const [],
  });

  bool get isEmpty =>
      title == null &&
      bullets.isEmpty &&
      categories.isEmpty &&
      highlights.isEmpty &&
      suggestedFixes.isEmpty;

  Map<String, dynamic> toJson() => {
        'title': title,
        'bullets': bullets,
        'categories': categories.map((c) => c.name).toList(),
        'highlights': highlights.map((h) => h.toJson()).toList(),
        'suggestedFixes': suggestedFixes.map((s) => s.toJson()).toList(),
      };

  factory StepExplanation.fromJson(Map<String, dynamic> json) {
    return StepExplanation(
      title: json['title'] as String?,
      bullets: (json['bullets'] as List? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      categories: (json['categories'] as List? ?? const [])
          .whereType<String>()
          .map(
            (name) => ExplanationCategory.values.firstWhere(
              (c) => c.name == name,
              orElse: () => ExplanationCategory.info,
            ),
          )
          .toList(growable: false),
      highlights: (json['highlights'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => HighlightTarget.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false),
      suggestedFixes: (json['suggestedFixes'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => SuggestedFix.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StepExplanation &&
        other.title == title &&
        _listEquals(other.bullets, bullets) &&
        _listEquals(other.categories, categories) &&
        _listEquals(other.highlights, highlights) &&
        _listEquals(other.suggestedFixes, suggestedFixes);
  }

  @override
  int get hashCode {
    return Object.hash(
      title,
      Object.hashAll(bullets),
      Object.hashAll(categories),
      Object.hashAll(highlights),
      Object.hashAll(suggestedFixes),
    );
  }
}

enum ExplanationCategory {
  info,
  nondeterminism,
  acceptance,
  rejection,
  epsilonMove,
  stackOperation,
  tapeOperation,
  grammarDerivation,
  validation,
  conversion,
}

/// A highlight target for the UI.
///
/// This is intentionally permissive: not all targets will be used by every
/// automaton type.
class HighlightTarget {
  final HighlightTargetType type;

  /// Identifier for the target.
  ///
  /// Examples:
  /// - stateId: "q0"
  /// - transitionId: stable internal edge id (if available)
  final String? id;

  /// Optional additional payload for the target.
  ///
  /// Keep values JSON-serializable.
  final Map<String, dynamic> data;

  const HighlightTarget({required this.type, this.id, this.data = const {}});

  Map<String, dynamic> toJson() => {'type': type.name, 'id': id, 'data': data};

  factory HighlightTarget.fromJson(Map<String, dynamic> json) {
    return HighlightTarget(
      type: HighlightTargetType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => HighlightTargetType.unknown,
      ),
      id: json['id'] as String?,
      data: Map<String, dynamic>.from(json['data'] as Map? ?? const {}),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HighlightTarget &&
        other.type == type &&
        other.id == id &&
        _mapEquals(other.data, data);
  }

  @override
  int get hashCode => Object.hash(type, id, _jsonValueHash(data));
}

enum HighlightTargetType {
  /// Automaton canvas targets
  state,
  transition,

  /// PDA/TM/grammar-specific targets
  stackSpan,
  tapeCell,

  /// Grammar parsing/derivation targets
  productionSpan,

  /// Generic "before/after" span highlight used by grammar and other editors.
  ///
  /// Data payload is intentionally flexible, but should typically include:
  /// - before: String
  /// - after: String
  /// - start: int (inclusive)
  /// - end: int (exclusive)
  sententialFormSpan,

  pdaStack,
  none,
  unknown,
}

/// An actionable hint to fix a problem or understand a step.
class SuggestedFix {
  final String label;
  final String? details;

  /// Optional action identifier for UI wiring (e.g., open settings panel).
  final String? actionId;

  const SuggestedFix({required this.label, this.details, this.actionId});

  Map<String, dynamic> toJson() => {
        'label': label,
        'details': details,
        'actionId': actionId,
      };

  factory SuggestedFix.fromJson(Map<String, dynamic> json) {
    return SuggestedFix(
      label: json['label'] as String,
      details: json['details'] as String?,
      actionId: json['actionId'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SuggestedFix &&
        other.label == label &&
        other.details == details &&
        other.actionId == actionId;
  }

  @override
  int get hashCode => Object.hash(label, details, actionId);
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (!_jsonValueEquals(a[i], b[i])) return false;
  }
  return true;
}

bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key) || !_jsonValueEquals(a[key], b[key])) return false;
  }
  return true;
}

bool _jsonValueEquals(Object? a, Object? b) {
  if (identical(a, b)) return true;
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_jsonValueEquals(a[i], b[i])) return false;
    }
    return true;
  }
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || !_jsonValueEquals(a[key], b[key])) {
        return false;
      }
    }
    return true;
  }
  return a == b;
}

int _jsonValueHash(Object? value) {
  if (value is List) {
    return Object.hashAll(value.map(_jsonValueHash));
  }
  if (value is Map) {
    final keys = value.keys.toList()
      ..sort((a, b) => a.toString().compareTo(b.toString()));
    return Object.hashAll(
      keys.map((key) => Object.hash(key, _jsonValueHash(value[key]))),
    );
  }
  return value.hashCode;
}
