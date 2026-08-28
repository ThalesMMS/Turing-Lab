//
//  validation_diagnostic.dart
//  Turing Lab
//
//  Structured validation diagnostic model.
//

import '../messages/structured_message.dart';
import 'step_explanation.dart';

/// Structured diagnostic for validation errors (canvas/import/precondition).
///
/// This model is meant to carry enough metadata for rich UI rendering:
/// summary + details, highlight targets and suggested fixes.
class ValidationDiagnostic {
  /// Stable diagnostic code (e.g., FSA_NO_INITIAL).
  final String code;

  /// Short summary suitable for a banner/list row.
  final String summary;

  /// Optional additional details (multi-line allowed).
  final String? details;

  /// Optional location identifier (state id, transition id, production id...).
  final String? location;

  /// UI highlights associated with this diagnostic.
  final List<HighlightTarget> highlights;

  /// Suggested fixes (actionable hints).
  final List<SuggestedFix> suggestedFixes;

  /// Locale-neutral semantic message for presentation resolvers.
  final StructuredMessage? structuredMessage;

  const ValidationDiagnostic({
    required this.code,
    required this.summary,
    this.details,
    this.location,
    this.highlights = const [],
    this.suggestedFixes = const [],
    this.structuredMessage,
  });

  Map<String, dynamic> toJson() => {
    'code': code,
    'summary': summary,
    'details': details,
    'location': location,
    'highlights': highlights.map((h) => h.toJson()).toList(),
    'suggestedFixes': suggestedFixes.map((s) => s.toJson()).toList(),
    if (structuredMessage != null)
      'structuredMessage': structuredMessage!.toJson(),
  };

  ValidationDiagnostic copyWith({
    String? code,
    String? summary,
    String? details,
    String? location,
    List<HighlightTarget>? highlights,
    List<SuggestedFix>? suggestedFixes,
    StructuredMessage? structuredMessage,
  }) => ValidationDiagnostic(
    code: code ?? this.code,
    summary: summary ?? this.summary,
    details: details ?? this.details,
    location: location ?? this.location,
    highlights: highlights ?? this.highlights,
    suggestedFixes: suggestedFixes ?? this.suggestedFixes,
    structuredMessage: structuredMessage ?? this.structuredMessage,
  );

  factory ValidationDiagnostic.fromJson(Map<String, dynamic> json) {
    return ValidationDiagnostic(
      code: json['code'] as String,
      summary: json['summary'] as String,
      details: json['details'] as String?,
      location: json['location'] as String?,
      highlights: (json['highlights'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => HighlightTarget.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false),
      suggestedFixes: (json['suggestedFixes'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => SuggestedFix.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false),
      structuredMessage: json['structuredMessage'] is Map
          ? StructuredMessage.fromJson(
              Map<String, Object?>.from(json['structuredMessage'] as Map),
            )
          : null,
    );
  }
}
