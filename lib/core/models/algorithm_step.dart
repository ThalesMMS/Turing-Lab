//
//  algorithm_step.dart
//  Turing Lab
//
//  Defines the base model for educational algorithm steps, storing index,
//  title, explanation, and extra properties specific to each conversion type
//  (NFA→DFA, minimization, FA→Regex). Supports serialization, validation,
//  and extension for specialized per-algorithm models.
//
//  Thales Matheus Mendonça Santos - January 2026
//

// Represents a single step in an algorithm execution.
// This is the base model that can be extended by specific algorithm step types.
import 'step_explanation.dart';

class AlgorithmStep {
  /// Unique identifier for this step
  final String id;

  /// Sequential step number (0-indexed)
  final int stepNumber;

  /// Short title describing this step's action
  final String title;

  /// Detailed explanation of what's happening and why.
  ///
  /// Kept for backwards compatibility with existing step-by-step UI.
  final String explanation;

  /// Optional structured explanation (bullets, highlights, suggested fixes).
  final StepExplanation? stepExplanation;

  /// Type of algorithm this step belongs to
  final AlgorithmType type;

  /// When this step was created
  final DateTime timestamp;

  /// Additional properties specific to the algorithm type (unmodifiable)
  final Map<String, dynamic> properties;

  const AlgorithmStep._internal({
    required this.id,
    required this.stepNumber,
    required this.title,
    required this.explanation,
    this.stepExplanation,
    required this.type,
    required this.timestamp,
    required this.properties,
  });

  factory AlgorithmStep({
    required String id,
    required int stepNumber,
    required String title,
    required String explanation,
    StepExplanation? stepExplanation,
    required AlgorithmType type,
    DateTime? timestamp,
    Map<String, dynamic> properties = const {},
  }) {
    return AlgorithmStep._internal(
      id: id,
      stepNumber: stepNumber,
      title: title,
      explanation: explanation,
      stepExplanation: stepExplanation,
      type: type,
      timestamp: timestamp ?? DateTime.now(),
      properties: Map<String, dynamic>.unmodifiable(Map.of(properties)),
    );
  }

  /// Creates a copy of this step with updated properties
  AlgorithmStep copyWith({
    String? id,
    int? stepNumber,
    String? title,
    String? explanation,
    StepExplanation? stepExplanation,
    AlgorithmType? type,
    DateTime? timestamp,
    Map<String, dynamic>? properties,
  }) {
    return AlgorithmStep(
      id: id ?? this.id,
      stepNumber: stepNumber ?? this.stepNumber,
      title: title ?? this.title,
      explanation: explanation ?? this.explanation,
      stepExplanation: stepExplanation ?? this.stepExplanation,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      properties: properties ?? this.properties,
    );
  }

  /// Converts the step to a JSON representation
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stepNumber': stepNumber,
      'title': title,
      'explanation': explanation,
      'stepExplanation': stepExplanation?.toJson(),
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'properties': properties,
    };
  }

  /// Creates a step from a JSON representation
  factory AlgorithmStep.fromJson(Map<String, dynamic> json) {
    final stepExplanationJson = json['stepExplanation'];

    return AlgorithmStep(
      id: json['id'] as String,
      stepNumber: json['stepNumber'] as int,
      title: json['title'] as String,
      explanation: json['explanation'] as String,
      stepExplanation: stepExplanationJson is Map
          ? StepExplanation.fromJson(
              Map<String, dynamic>.from(stepExplanationJson),
            )
          : null,
      type: AlgorithmType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AlgorithmType.nfaToDfa,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      properties: Map<String, dynamic>.from(json['properties'] as Map? ?? {}),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AlgorithmStep &&
        other.id == id &&
        other.stepNumber == stepNumber &&
        other.title == title &&
        other.explanation == explanation &&
        other.type == type &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(id, stepNumber, title, explanation, type, timestamp);
  }

  @override
  String toString() {
    return 'AlgorithmStep(id: $id, stepNumber: $stepNumber, '
        'title: $title, type: ${type.name})';
  }

  /// Validates the step properties
  List<String> validate() {
    final errors = <String>[];

    if (id.isEmpty) {
      errors.add('Step ID cannot be empty');
    }

    if (stepNumber < 0) {
      errors.add('Step number must be non-negative');
    }

    if (title.isEmpty) {
      errors.add('Step title cannot be empty');
    }

    if (explanation.isEmpty) {
      errors.add('Step explanation cannot be empty');
    }

    return errors;
  }

  /// Checks if this step is valid
  bool get isValid => validate().isEmpty;

  /// Gets the step's display number (1-indexed for UI)
  int get displayNumber => stepNumber + 1;
}

/// Types of algorithms that can have step-by-step execution
enum AlgorithmType {
  /// NFA to DFA conversion using subset construction
  nfaToDfa,

  /// DFA minimization using Hopcroft's algorithm
  dfaMinimization,

  /// Finite automaton to regular expression conversion
  faToRegex,

  /// Regular expression to NFA conversion using Thompson's construction
  regexToNfa,

  /// CYK parsing algorithm for context-free grammars
  cykParsing,

  /// Regular expression simplification using algebraic identities
  regexSimplification,

  /// Concatenation of two finite automata through epsilon bridges
  fsaConcatenation,

  /// Kleene star of a finite automaton through Thompson construction
  fsaKleeneStar,

  /// Reversal of a finite-automaton language through reversed transitions
  fsaReversal,
}

/// Extension methods for AlgorithmType
extension AlgorithmTypeExtension on AlgorithmType {
  /// Gets a human-readable name for the algorithm
  String get displayName {
    switch (this) {
      case AlgorithmType.nfaToDfa:
        return 'NFA to DFA Conversion';
      case AlgorithmType.dfaMinimization:
        return 'DFA Minimization';
      case AlgorithmType.faToRegex:
        return 'FA to Regex Conversion';
      case AlgorithmType.regexToNfa:
        return 'Regex to NFA Conversion';
      case AlgorithmType.cykParsing:
        return 'CYK Parsing';
      case AlgorithmType.regexSimplification:
        return 'Regex Simplification';
      case AlgorithmType.fsaConcatenation:
        return 'FSA Concatenation';
      case AlgorithmType.fsaKleeneStar:
        return 'FSA Kleene Star';
      case AlgorithmType.fsaReversal:
        return 'FSA Reversal';
    }
  }

  /// Gets a short description of the algorithm
  String get description {
    switch (this) {
      case AlgorithmType.nfaToDfa:
        return 'Converts a Non-deterministic Finite Automaton to a '
            'Deterministic Finite Automaton using subset construction';
      case AlgorithmType.dfaMinimization:
        return 'Minimizes a DFA by merging equivalent states using '
            'Hopcroft\'s algorithm';
      case AlgorithmType.faToRegex:
        return 'Converts a Finite Automaton to a Regular Expression '
            'using state elimination';
      case AlgorithmType.regexToNfa:
        return 'Converts a Regular Expression to a Non-deterministic '
            'Finite Automaton using Thompson\'s construction';
      case AlgorithmType.cykParsing:
        return 'Parses strings using context-free grammars in Chomsky Normal '
            'Form via the Cocke-Younger-Kasami algorithm';
      case AlgorithmType.regexSimplification:
        return 'Simplifies regular expressions using algebraic identities '
            'and equivalence rules';
      case AlgorithmType.fsaConcatenation:
        return 'Builds an NFA for the concatenation of two finite automata '
            'using epsilon transitions';
      case AlgorithmType.fsaKleeneStar:
        return 'Builds an NFA for zero or more repetitions of a finite '
            'automaton language using Thompson construction';
      case AlgorithmType.fsaReversal:
        return 'Builds an NFA for the reversed language by reversing every '
            'transition and connecting a fresh initial state';
    }
  }
}
