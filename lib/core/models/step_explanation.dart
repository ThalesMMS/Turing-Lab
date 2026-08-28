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

import '../messages/structured_message.dart';

/// An explanation attached to a simulation or conversion step.
class StepExplanation {
  static const schemaVersion = 2;

  final String? _legacyTitle;

  /// Temporary compatibility view for renderers that still expect prose.
  String? get title => _legacyTitle ?? titleMessage?.stableCode;

  final List<String> _legacyBullets;

  /// Temporary compatibility view for renderers that still expect prose.
  List<String> get bullets => _legacyBullets.isNotEmpty
      ? _legacyBullets
      : bulletMessages
            .map((message) => message.stableCode)
            .toList(growable: false);

  /// Locale-neutral title resolved by presentation code.
  final StructuredMessage? titleMessage;

  /// Locale-neutral explanation bullets resolved by presentation code.
  final List<StructuredMessage> bulletMessages;

  /// Optional categorization for filtering/styling.
  final List<ExplanationCategory> categories;

  /// Optional targets to highlight in the UI (canvas, stack, tape, etc.).
  final List<HighlightTarget> highlights;

  /// Optional actionable hints.
  final List<SuggestedFix> suggestedFixes;

  final List<String>? _decodedCategoryWireCodes;

  const StepExplanation({
    String? title,
    List<String> bullets = const [],
    this.titleMessage,
    this.bulletMessages = const [],
    this.categories = const [],
    this.highlights = const [],
    this.suggestedFixes = const [],
  }) : _legacyTitle = title,
       _legacyBullets = bullets,
       _decodedCategoryWireCodes = null,
       assert(
         title == null || titleMessage == null,
         'An explanation cannot contain both legacy and structured titles.',
       );

  const StepExplanation._decoded({
    String? title,
    List<String> bullets = const [],
    this.titleMessage,
    this.bulletMessages = const [],
    this.categories = const [],
    this.highlights = const [],
    this.suggestedFixes = const [],
    required List<String> categoryWireCodes,
  }) : _legacyTitle = title,
       _legacyBullets = bullets,
       _decodedCategoryWireCodes = categoryWireCodes;

  bool get isEmpty =>
      _legacyTitle == null &&
      _legacyBullets.isEmpty &&
      titleMessage == null &&
      bulletMessages.isEmpty &&
      categories.isEmpty &&
      highlights.isEmpty &&
      suggestedFixes.isEmpty;

  bool get usesLegacyText =>
      _legacyTitle != null ||
      _legacyBullets.isNotEmpty ||
      suggestedFixes.any((fix) => fix.usesLegacyText);

  Map<String, dynamic> toJson() {
    if (_legacyTitle != null && titleMessage != null) {
      throw StateError(
        'An explanation cannot contain both legacy and structured titles.',
      );
    }
    if (_legacyBullets.isNotEmpty && bulletMessages.isNotEmpty) {
      throw StateError(
        'An explanation cannot contain both legacy and structured bullets.',
      );
    }
    final hasLegacyExplanationText =
        _legacyTitle != null || _legacyBullets.isNotEmpty;
    final hasStructuredExplanationText =
        titleMessage != null || bulletMessages.isNotEmpty;
    if (hasLegacyExplanationText && !hasStructuredExplanationText) {
      return {
        'title': _legacyTitle,
        'bullets': _legacyBullets,
        'categories': _categoryWireCodes(legacyWire: true),
        'highlights': highlights
            .map((highlight) => highlight.toJson(legacyWire: true))
            .toList(),
        'suggestedFixes': suggestedFixes.map((s) => s.toJson()).toList(),
      };
    }
    return {
      'schemaVersion': schemaVersion,
      if (_legacyTitle != null) 'title': _legacyTitle,
      if (_legacyBullets.isNotEmpty) 'bullets': _legacyBullets,
      'titleMessage': titleMessage?.toJson(),
      'bulletMessages': bulletMessages
          .map((message) => message.toJson())
          .toList(growable: false),
      'categories': _categoryWireCodes(),
      'highlights': highlights.map((h) => h.toJson()).toList(),
      'suggestedFixes': suggestedFixes.map((s) => s.toJson()).toList(),
    };
  }

  factory StepExplanation.fromJson(Map<String, dynamic> json) {
    final version = json['schemaVersion'];
    if (version != null && version != schemaVersion) {
      throw FormatException('Unsupported step-explanation version: $version.');
    }
    final isLegacy = version == null;
    final title = json['title'] as String?;
    final bullets = (json['bullets'] as List? ?? const [])
        .whereType<String>()
        .toList(growable: false);
    final titleMessage = json['titleMessage'] is Map
        ? StructuredMessage.fromJson(
            Map<String, Object?>.from(json['titleMessage'] as Map),
          )
        : null;
    final bulletMessages = (json['bulletMessages'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (value) =>
              StructuredMessage.fromJson(Map<String, Object?>.from(value)),
        )
        .toList(growable: false);
    if (title != null && titleMessage != null) {
      throw const FormatException(
        'Step explanation contains both legacy and structured titles.',
      );
    }
    if (bullets.isNotEmpty && bulletMessages.isNotEmpty) {
      throw const FormatException(
        'Step explanation contains both legacy and structured bullets.',
      );
    }
    final categoryWireCodes = (json['categories'] as List? ?? const [])
        .whereType<String>()
        .toList(growable: false);
    return StepExplanation._decoded(
      title: isLegacy || title != null ? title : null,
      bullets: isLegacy || bullets.isNotEmpty ? bullets : const [],
      titleMessage: titleMessage,
      bulletMessages: bulletMessages,
      categories: categoryWireCodes
          .map(_categoryFromWireCode)
          .toList(growable: false),
      highlights: (json['highlights'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => HighlightTarget.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false),
      suggestedFixes: (json['suggestedFixes'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => SuggestedFix.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false),
      categoryWireCodes: categoryWireCodes,
    );
  }

  List<String> _categoryWireCodes({bool legacyWire = false}) {
    final decoded = _decodedCategoryWireCodes;
    if (decoded != null) return List<String>.of(decoded, growable: false);
    return categories
        .map(legacyWire ? _legacyCategoryWireCode : _categoryWireCode)
        .toList(growable: false);
  }

  List<String> _categoryComparisonCodes() {
    final decoded = _decodedCategoryWireCodes;
    if (decoded == null) {
      return categories.map(_categoryWireCode).toList(growable: false);
    }
    return decoded
        .map((wireCode) {
          final category = _categoryFromWireCode(wireCode);
          return category == ExplanationCategory.unknown &&
                  wireCode != 'unknown'
              ? wireCode
              : _categoryWireCode(category);
        })
        .toList(growable: false);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StepExplanation &&
        other._legacyTitle == _legacyTitle &&
        _listEquals(other._legacyBullets, _legacyBullets) &&
        other.titleMessage == titleMessage &&
        _listEquals(other.bulletMessages, bulletMessages) &&
        _listEquals(
          other._categoryComparisonCodes(),
          _categoryComparisonCodes(),
        ) &&
        _listEquals(other.highlights, highlights) &&
        _listEquals(other.suggestedFixes, suggestedFixes);
  }

  @override
  int get hashCode {
    return Object.hash(
      _legacyTitle,
      Object.hashAll(_legacyBullets),
      titleMessage,
      Object.hashAll(bulletMessages),
      Object.hashAll(_categoryComparisonCodes()),
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
  unknown,
}

String _categoryWireCode(ExplanationCategory category) => switch (category) {
  ExplanationCategory.info => 'info',
  ExplanationCategory.nondeterminism => 'nondeterminism',
  ExplanationCategory.acceptance => 'acceptance',
  ExplanationCategory.rejection => 'rejection',
  ExplanationCategory.epsilonMove => 'epsilon-move',
  ExplanationCategory.stackOperation => 'stack-operation',
  ExplanationCategory.tapeOperation => 'tape-operation',
  ExplanationCategory.grammarDerivation => 'grammar-derivation',
  ExplanationCategory.validation => 'validation',
  ExplanationCategory.conversion => 'conversion',
  ExplanationCategory.unknown => 'unknown',
};

String _legacyCategoryWireCode(ExplanationCategory category) =>
    switch (category) {
      ExplanationCategory.info => 'info',
      ExplanationCategory.nondeterminism => 'nondeterminism',
      ExplanationCategory.acceptance => 'acceptance',
      ExplanationCategory.rejection => 'rejection',
      ExplanationCategory.epsilonMove => 'epsilonMove',
      ExplanationCategory.stackOperation => 'stackOperation',
      ExplanationCategory.tapeOperation => 'tapeOperation',
      ExplanationCategory.grammarDerivation => 'grammarDerivation',
      ExplanationCategory.validation => 'validation',
      ExplanationCategory.conversion => 'conversion',
      ExplanationCategory.unknown => 'unknown',
    };

ExplanationCategory _categoryFromWireCode(String wireCode) =>
    switch (wireCode) {
      'nondeterminism' => ExplanationCategory.nondeterminism,
      'acceptance' => ExplanationCategory.acceptance,
      'rejection' => ExplanationCategory.rejection,
      'epsilon-move' || 'epsilonMove' => ExplanationCategory.epsilonMove,
      'stack-operation' ||
      'stackOperation' => ExplanationCategory.stackOperation,
      'tape-operation' || 'tapeOperation' => ExplanationCategory.tapeOperation,
      'grammar-derivation' ||
      'grammarDerivation' => ExplanationCategory.grammarDerivation,
      'validation' => ExplanationCategory.validation,
      'conversion' => ExplanationCategory.conversion,
      'info' => ExplanationCategory.info,
      _ => ExplanationCategory.unknown,
    };

/// A highlight target for the UI.
///
/// This is intentionally permissive: not all targets will be used by every
/// automaton type.
class HighlightTarget {
  final HighlightTargetType type;
  final String? _decodedTypeWireCode;

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

  const HighlightTarget({required this.type, this.id, this.data = const {}})
    : _decodedTypeWireCode = null;

  const HighlightTarget._decoded({
    required this.type,
    required String? typeWireCode,
    this.id,
    this.data = const {},
  }) : _decodedTypeWireCode = typeWireCode;

  Map<String, dynamic> toJson({bool legacyWire = false}) => {
    'type': _typeWireCode(legacyWire: legacyWire),
    'id': id,
    'data': data,
  };

  factory HighlightTarget.fromJson(Map<String, dynamic> json) {
    final typeWireCode = json['type'];
    return HighlightTarget._decoded(
      type: _highlightTargetFromWireCode(typeWireCode),
      typeWireCode: typeWireCode is String ? typeWireCode : null,
      id: json['id'] as String?,
      data: Map<String, dynamic>.from(json['data'] as Map? ?? const {}),
    );
  }

  String _typeWireCode({required bool legacyWire}) =>
      _decodedTypeWireCode ??
      (legacyWire
          ? _legacyHighlightTargetWireCode(type)
          : _highlightTargetWireCode(type));

  String get _typeComparisonWireCode {
    final decoded = _decodedTypeWireCode;
    if (decoded == null) return _highlightTargetWireCode(type);
    return type == HighlightTargetType.unknown && decoded != 'unknown'
        ? decoded
        : _highlightTargetWireCode(type);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HighlightTarget &&
        other._typeComparisonWireCode == _typeComparisonWireCode &&
        other.id == id &&
        _mapEquals(other.data, data);
  }

  @override
  int get hashCode =>
      Object.hash(_typeComparisonWireCode, id, _jsonValueHash(data));
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

String _highlightTargetWireCode(HighlightTargetType type) => switch (type) {
  HighlightTargetType.state => 'state',
  HighlightTargetType.transition => 'transition',
  HighlightTargetType.stackSpan => 'stack-span',
  HighlightTargetType.tapeCell => 'tape-cell',
  HighlightTargetType.productionSpan => 'production-span',
  HighlightTargetType.sententialFormSpan => 'sentential-form-span',
  HighlightTargetType.pdaStack => 'pda-stack',
  HighlightTargetType.none => 'none',
  HighlightTargetType.unknown => 'unknown',
};

String _legacyHighlightTargetWireCode(HighlightTargetType type) =>
    switch (type) {
      HighlightTargetType.state => 'state',
      HighlightTargetType.transition => 'transition',
      HighlightTargetType.stackSpan => 'stackSpan',
      HighlightTargetType.tapeCell => 'tapeCell',
      HighlightTargetType.productionSpan => 'productionSpan',
      HighlightTargetType.sententialFormSpan => 'sententialFormSpan',
      HighlightTargetType.pdaStack => 'pdaStack',
      HighlightTargetType.none => 'none',
      HighlightTargetType.unknown => 'unknown',
    };

HighlightTargetType _highlightTargetFromWireCode(Object? wireCode) =>
    switch (wireCode) {
      'state' => HighlightTargetType.state,
      'transition' => HighlightTargetType.transition,
      'stack-span' || 'stackSpan' => HighlightTargetType.stackSpan,
      'tape-cell' || 'tapeCell' => HighlightTargetType.tapeCell,
      'production-span' ||
      'productionSpan' => HighlightTargetType.productionSpan,
      'sentential-form-span' ||
      'sententialFormSpan' => HighlightTargetType.sententialFormSpan,
      'pda-stack' || 'pdaStack' => HighlightTargetType.pdaStack,
      'none' => HighlightTargetType.none,
      _ => HighlightTargetType.unknown,
    };

/// An actionable hint to fix a problem or understand a step.
class SuggestedFix {
  final String? _legacyLabel;
  final String? _legacyDetails;

  String get label => _legacyLabel ?? labelMessage?.stableCode ?? '';
  String? get details => _legacyDetails ?? detailsMessage?.stableCode;

  final StructuredMessage? labelMessage;
  final StructuredMessage? detailsMessage;

  /// Optional action identifier for UI wiring (e.g., open settings panel).
  final String? actionId;

  const SuggestedFix({
    required String label,
    String? details,
    this.labelMessage,
    this.detailsMessage,
    this.actionId,
  }) : _legacyLabel = label,
       _legacyDetails = details,
       assert(
         labelMessage == null,
         'A suggested fix cannot contain both legacy and structured labels.',
       ),
       assert(
         detailsMessage == null,
         'Use SuggestedFix.structured for structured suggested-fix fields.',
       );

  factory SuggestedFix.structured({
    required StructuredMessage labelMessage,
    StructuredMessage? detailsMessage,
    String? actionId,
  }) => SuggestedFix._structured(
    labelMessage: labelMessage,
    detailsMessage: detailsMessage,
    actionId: actionId,
  );

  const SuggestedFix._structured({
    required this.labelMessage,
    this.detailsMessage,
    this.actionId,
  }) : _legacyLabel = null,
       _legacyDetails = null;

  bool get usesLegacyText => _legacyLabel != null || _legacyDetails != null;

  Map<String, dynamic> toJson() {
    final hasLegacy = _legacyLabel != null || _legacyDetails != null;
    final hasStructured = labelMessage != null || detailsMessage != null;
    if (hasLegacy && hasStructured) {
      throw StateError('Suggested fix mixes legacy and structured fields.');
    }
    return hasLegacy
        ? {
            'label': _legacyLabel,
            'details': _legacyDetails,
            'actionId': actionId,
          }
        : {
            'labelMessage': labelMessage!.toJson(),
            'detailsMessage': detailsMessage?.toJson(),
            'actionId': actionId,
          };
  }

  factory SuggestedFix.fromJson(Map<String, dynamic> json) {
    if (json['labelMessage'] is Map) {
      if (json['label'] != null || json['details'] != null) {
        throw const FormatException(
          'Suggested fix mixes legacy and structured fields.',
        );
      }
      return SuggestedFix.structured(
        labelMessage: StructuredMessage.fromJson(
          Map<String, Object?>.from(json['labelMessage'] as Map),
        ),
        detailsMessage: json['detailsMessage'] is Map
            ? StructuredMessage.fromJson(
                Map<String, Object?>.from(json['detailsMessage'] as Map),
              )
            : null,
        actionId: json['actionId'] as String?,
      );
    }
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
        other._legacyLabel == _legacyLabel &&
        other._legacyDetails == _legacyDetails &&
        other.labelMessage == labelMessage &&
        other.detailsMessage == detailsMessage &&
        other.actionId == actionId;
  }

  @override
  int get hashCode => Object.hash(
    _legacyLabel,
    _legacyDetails,
    labelMessage,
    detailsMessage,
    actionId,
  );
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
