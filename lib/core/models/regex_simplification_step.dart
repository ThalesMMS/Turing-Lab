//
//  regex_simplification_step.dart
//  Turing Lab
//
//  Defines the detailed step model for regular-expression simplification
//  using algebraic identities. Captures the applied rule, modified
//  subexpression, simplification result, and complexity metrics (star height,
//  nesting depth) for each algorithm step, enabling educational
//  step-by-step visualization.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'algorithm_step.dart';

/// Represents a single step in regex simplification using algebraic identities
class RegexSimplificationStep {
  /// Base algorithm step information
  final AlgorithmStep baseStep;

  /// Type of operation performed in this step
  final RegexSimplificationStepType stepType;

  /// Original regex expression before this step
  final String? originalRegex;

  /// Simplified regex expression after this step
  final String? simplifiedRegex;

  /// Simplification rule applied in this step
  final SimplificationRule? ruleApplied;

  /// Human-readable description of why the rule applies
  final String? ruleExplanation;

  /// Position in the regex where the rule was applied
  final int? position;

  /// The subexpression that was matched by the rule
  final String? matchedSubexpression;

  /// What the matched subexpression was replaced with
  final String? replacementSubexpression;

  /// Star height metric of the current regex
  final int? starHeight;

  /// Nesting depth metric of the current regex
  final int? nestingDepth;

  /// Size of the alphabet used in the regex
  final int? alphabetSize;

  /// Total number of operators in the regex
  final int? operatorCount;

  /// Sample strings that match the regex
  final List<String>? sampleStrings;

  /// Whether this step reduces complexity
  final bool reducesComplexity;

  /// Number of characters saved by this simplification
  final int? charactersSaved;

  /// Whether this is the final simplified form
  final bool isFinalForm;

  /// Total number of rules applied so far
  final int? totalRulesApplied;

  const RegexSimplificationStep._internal({
    required this.baseStep,
    required this.stepType,
    this.originalRegex,
    this.simplifiedRegex,
    this.ruleApplied,
    this.ruleExplanation,
    this.position,
    this.matchedSubexpression,
    this.replacementSubexpression,
    this.starHeight,
    this.nestingDepth,
    this.alphabetSize,
    this.operatorCount,
    this.sampleStrings,
    required this.reducesComplexity,
    this.charactersSaved,
    required this.isFinalForm,
    this.totalRulesApplied,
  });

  factory RegexSimplificationStep({
    required AlgorithmStep baseStep,
    required RegexSimplificationStepType stepType,
    String? originalRegex,
    String? simplifiedRegex,
    SimplificationRule? ruleApplied,
    String? ruleExplanation,
    int? position,
    String? matchedSubexpression,
    String? replacementSubexpression,
    int? starHeight,
    int? nestingDepth,
    int? alphabetSize,
    int? operatorCount,
    List<String>? sampleStrings,
    bool reducesComplexity = false,
    int? charactersSaved,
    bool isFinalForm = false,
    int? totalRulesApplied,
  }) {
    return RegexSimplificationStep._internal(
      baseStep: baseStep,
      stepType: stepType,
      originalRegex: originalRegex,
      simplifiedRegex: simplifiedRegex,
      ruleApplied: ruleApplied,
      ruleExplanation: ruleExplanation,
      position: position,
      matchedSubexpression: matchedSubexpression,
      replacementSubexpression: replacementSubexpression,
      starHeight: starHeight,
      nestingDepth: nestingDepth,
      alphabetSize: alphabetSize,
      operatorCount: operatorCount,
      sampleStrings:
          sampleStrings != null ? List.unmodifiable(sampleStrings) : null,
      reducesComplexity: reducesComplexity,
      charactersSaved: charactersSaved,
      isFinalForm: isFinalForm,
      totalRulesApplied: totalRulesApplied,
    );
  }

  /// Creates a step for starting the simplification process
  factory RegexSimplificationStep.start({
    required String id,
    required int stepNumber,
    required String regex,
    required int starHeight,
    required int nestingDepth,
    required int operatorCount,
  }) {
    return RegexSimplificationStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Begin regex simplification',
        explanation: 'Starting simplification of regular expression "$regex". '
            'Current complexity metrics: star height = $starHeight, '
            'nesting depth = $nestingDepth, operator count = $operatorCount. '
            'Will apply algebraic identities to find an equivalent simpler form.',
        type: AlgorithmType.regexSimplification,
      ),
      stepType: RegexSimplificationStepType.start,
      originalRegex: regex,
      simplifiedRegex: regex,
      starHeight: starHeight,
      nestingDepth: nestingDepth,
      operatorCount: operatorCount,
    );
  }

  /// Creates a step for analyzing regex complexity
  factory RegexSimplificationStep.analyze({
    required String id,
    required int stepNumber,
    required String regex,
    required int starHeight,
    required int nestingDepth,
    required int alphabetSize,
    required int operatorCount,
  }) {
    return RegexSimplificationStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Analyze regex complexity',
        explanation: 'Analyzing complexity of "$regex". '
            'Star height: $starHeight (maximum nesting of Kleene stars). '
            'Nesting depth: $nestingDepth (maximum depth of parentheses). '
            'Alphabet size: $alphabetSize distinct symbol(s). '
            'Operator count: $operatorCount (union, concatenation, star operators).',
        type: AlgorithmType.regexSimplification,
      ),
      stepType: RegexSimplificationStepType.analyze,
      originalRegex: regex,
      simplifiedRegex: regex,
      starHeight: starHeight,
      nestingDepth: nestingDepth,
      alphabetSize: alphabetSize,
      operatorCount: operatorCount,
    );
  }

  /// Creates a step for applying a simplification rule
  factory RegexSimplificationStep.applyRule({
    required String id,
    required int stepNumber,
    required String originalRegex,
    required String simplifiedRegex,
    required SimplificationRule rule,
    required String matchedSubexpression,
    required String replacementSubexpression,
    int? position,
    required int totalRulesApplied,
  }) {
    final charactersSaved = originalRegex.length - simplifiedRegex.length;
    return RegexSimplificationStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Apply ${rule.displayName}',
        explanation: 'Applying rule: ${rule.displayName}. '
            'Matched subexpression "$matchedSubexpression" at position ${position ?? "N/A"}. '
            'Replacing with "$replacementSubexpression". '
            '${rule.description}. '
            '${charactersSaved > 0 ? "Saved $charactersSaved character(s)." : "Expression length unchanged."}',
        type: AlgorithmType.regexSimplification,
      ),
      stepType: RegexSimplificationStepType.applyRule,
      originalRegex: originalRegex,
      simplifiedRegex: simplifiedRegex,
      ruleApplied: rule,
      ruleExplanation: rule.description,
      position: position,
      matchedSubexpression: matchedSubexpression,
      replacementSubexpression: replacementSubexpression,
      reducesComplexity: charactersSaved > 0,
      charactersSaved: charactersSaved,
      totalRulesApplied: totalRulesApplied,
    );
  }

  /// Creates a step for generating sample strings
  factory RegexSimplificationStep.generateSamples({
    required String id,
    required int stepNumber,
    required String regex,
    required List<String> samples,
  }) {
    final sampleDisplay = samples.isEmpty
        ? 'No strings generated (regex may accept empty language).'
        : 'Generated ${samples.length} sample string(s): ${samples.map((s) => s.isEmpty ? "ε (empty string)" : "\"$s\"").join(", ")}.';
    return RegexSimplificationStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Generate sample strings',
        explanation:
            'Generating strings that match the regex "$regex". $sampleDisplay '
            'These strings demonstrate the language accepted by the expression.',
        type: AlgorithmType.regexSimplification,
      ),
      stepType: RegexSimplificationStepType.generateSamples,
      originalRegex: regex,
      simplifiedRegex: regex,
      sampleStrings: samples,
    );
  }

  /// Creates a step for detecting no further simplification possible
  factory RegexSimplificationStep.noRuleApplicable({
    required String id,
    required int stepNumber,
    required String regex,
    required int totalRulesApplied,
  }) {
    return RegexSimplificationStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: 'No further simplification',
        explanation: 'Checked all simplification rules against "$regex". '
            'No applicable rules found. '
            'The expression is in its simplest form achievable by algebraic identities. '
            'Total rules applied: $totalRulesApplied.',
        type: AlgorithmType.regexSimplification,
      ),
      stepType: RegexSimplificationStepType.noRuleApplicable,
      originalRegex: regex,
      simplifiedRegex: regex,
      totalRulesApplied: totalRulesApplied,
    );
  }

  /// Creates a completion step
  factory RegexSimplificationStep.completion({
    required String id,
    required int stepNumber,
    required String originalRegex,
    required String finalRegex,
    required int totalRulesApplied,
    required int starHeight,
    required int nestingDepth,
    required int operatorCount,
  }) {
    final charactersSaved = originalRegex.length - finalRegex.length;
    final improvement = originalRegex.isNotEmpty
        ? ((charactersSaved / originalRegex.length) * 100).toStringAsFixed(1)
        : '0';
    return RegexSimplificationStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Simplification complete',
        explanation: 'Regex simplification completed. '
            'Original: "$originalRegex" (${originalRegex.length} chars). '
            'Simplified: "$finalRegex" (${finalRegex.length} chars). '
            'Reduction: $improvement%. Rules applied: $totalRulesApplied. '
            'Final metrics: star height = $starHeight, nesting depth = $nestingDepth, operators = $operatorCount.',
        type: AlgorithmType.regexSimplification,
      ),
      stepType: RegexSimplificationStepType.completion,
      originalRegex: originalRegex,
      simplifiedRegex: finalRegex,
      starHeight: starHeight,
      nestingDepth: nestingDepth,
      operatorCount: operatorCount,
      reducesComplexity: charactersSaved > 0,
      charactersSaved: charactersSaved,
      isFinalForm: true,
      totalRulesApplied: totalRulesApplied,
    );
  }

  /// Creates a copy of this step with updated properties
  RegexSimplificationStep copyWith({
    AlgorithmStep? baseStep,
    RegexSimplificationStepType? stepType,
    String? originalRegex,
    String? simplifiedRegex,
    SimplificationRule? ruleApplied,
    String? ruleExplanation,
    int? position,
    String? matchedSubexpression,
    String? replacementSubexpression,
    int? starHeight,
    int? nestingDepth,
    int? alphabetSize,
    int? operatorCount,
    List<String>? sampleStrings,
    bool? reducesComplexity,
    int? charactersSaved,
    bool? isFinalForm,
    int? totalRulesApplied,
  }) {
    return RegexSimplificationStep(
      baseStep: baseStep ?? this.baseStep,
      stepType: stepType ?? this.stepType,
      originalRegex: originalRegex ?? this.originalRegex,
      simplifiedRegex: simplifiedRegex ?? this.simplifiedRegex,
      ruleApplied: ruleApplied ?? this.ruleApplied,
      ruleExplanation: ruleExplanation ?? this.ruleExplanation,
      position: position ?? this.position,
      matchedSubexpression: matchedSubexpression ?? this.matchedSubexpression,
      replacementSubexpression:
          replacementSubexpression ?? this.replacementSubexpression,
      starHeight: starHeight ?? this.starHeight,
      nestingDepth: nestingDepth ?? this.nestingDepth,
      alphabetSize: alphabetSize ?? this.alphabetSize,
      operatorCount: operatorCount ?? this.operatorCount,
      sampleStrings: sampleStrings ?? this.sampleStrings,
      reducesComplexity: reducesComplexity ?? this.reducesComplexity,
      charactersSaved: charactersSaved ?? this.charactersSaved,
      isFinalForm: isFinalForm ?? this.isFinalForm,
      totalRulesApplied: totalRulesApplied ?? this.totalRulesApplied,
    );
  }

  /// Converts the step to a JSON representation
  Map<String, dynamic> toJson() {
    return {
      'baseStep': baseStep.toJson(),
      'stepType': stepType.name,
      'originalRegex': originalRegex,
      'simplifiedRegex': simplifiedRegex,
      'ruleApplied': ruleApplied?.name,
      'ruleExplanation': ruleExplanation,
      'position': position,
      'matchedSubexpression': matchedSubexpression,
      'replacementSubexpression': replacementSubexpression,
      'starHeight': starHeight,
      'nestingDepth': nestingDepth,
      'alphabetSize': alphabetSize,
      'operatorCount': operatorCount,
      'sampleStrings': sampleStrings,
      'reducesComplexity': reducesComplexity,
      'charactersSaved': charactersSaved,
      'isFinalForm': isFinalForm,
      'totalRulesApplied': totalRulesApplied,
    };
  }

  /// Creates a step from a JSON representation
  factory RegexSimplificationStep.fromJson(Map<String, dynamic> json) {
    return RegexSimplificationStep(
      baseStep: AlgorithmStep.fromJson(
        json['baseStep'] as Map<String, dynamic>,
      ),
      stepType: RegexSimplificationStepType.values.firstWhere(
        (e) => e.name == json['stepType'],
        orElse: () => RegexSimplificationStepType.start,
      ),
      originalRegex: json['originalRegex'] as String?,
      simplifiedRegex: json['simplifiedRegex'] as String?,
      ruleApplied: json['ruleApplied'] != null
          ? SimplificationRule.values.firstWhere(
              (e) => e.name == json['ruleApplied'],
              orElse: () => SimplificationRule.emptyUnion,
            )
          : null,
      ruleExplanation: json['ruleExplanation'] as String?,
      position: json['position'] as int?,
      matchedSubexpression: json['matchedSubexpression'] as String?,
      replacementSubexpression: json['replacementSubexpression'] as String?,
      starHeight: json['starHeight'] as int?,
      nestingDepth: json['nestingDepth'] as int?,
      alphabetSize: json['alphabetSize'] as int?,
      operatorCount: json['operatorCount'] as int?,
      sampleStrings:
          (json['sampleStrings'] as List?)?.map((s) => s as String).toList(),
      reducesComplexity: json['reducesComplexity'] as bool? ?? false,
      charactersSaved: json['charactersSaved'] as int?,
      isFinalForm: json['isFinalForm'] as bool? ?? false,
      totalRulesApplied: json['totalRulesApplied'] as int?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RegexSimplificationStep &&
        other.baseStep == baseStep &&
        other.stepType == stepType &&
        other.originalRegex == originalRegex &&
        other.simplifiedRegex == simplifiedRegex &&
        other.ruleApplied == ruleApplied &&
        other.isFinalForm == isFinalForm &&
        other.totalRulesApplied == totalRulesApplied;
  }

  @override
  int get hashCode {
    return Object.hash(
      baseStep,
      stepType,
      originalRegex,
      simplifiedRegex,
      ruleApplied,
      isFinalForm,
      totalRulesApplied,
    );
  }

  @override
  String toString() {
    return 'RegexSimplificationStep(stepNumber: ${baseStep.stepNumber}, '
        'type: ${stepType.name}, title: ${baseStep.title})';
  }

  /// Gets the step number
  int get stepNumber => baseStep.stepNumber;

  /// Gets the step title
  String get title => baseStep.title;

  /// Gets the step explanation
  String get explanation => baseStep.explanation;

  /// Checks if this step applies a simplification rule
  bool get appliesRule => stepType == RegexSimplificationStepType.applyRule;

  /// Checks if this step is an analysis step
  bool get isAnalysis => stepType == RegexSimplificationStepType.analyze;

  /// Checks if this step generates samples
  bool get generatesSamples =>
      stepType == RegexSimplificationStepType.generateSamples;

  /// Gets the complexity score (sum of metrics)
  int? get complexityScore {
    if (starHeight == null || nestingDepth == null || operatorCount == null) {
      return null;
    }
    return starHeight! + nestingDepth! + operatorCount!;
  }

  /// Gets the number of samples generated
  int get sampleCount => sampleStrings?.length ?? 0;

  /// Checks if simplification made progress
  bool get madeProgress => charactersSaved != null && charactersSaved! > 0;

  /// Gets a summary of the rule application
  String get ruleSummary {
    if (ruleApplied == null) return 'No rule applied';
    return '${ruleApplied!.displayName}: "$matchedSubexpression" → "$replacementSubexpression"';
  }
}

/// Types of steps in regex simplification
enum RegexSimplificationStepType {
  /// Starting the simplification algorithm
  start,

  /// Analyzing regex complexity metrics
  analyze,

  /// Applying a simplification rule
  applyRule,

  /// No rule is applicable (simplification complete)
  noRuleApplicable,

  /// Generating sample strings
  generateSamples,

  /// Simplification completion
  completion,
}

/// Extension methods for RegexSimplificationStepType
extension RegexSimplificationStepTypeExtension on RegexSimplificationStepType {
  /// Gets a human-readable name for the step type
  String get displayName {
    switch (this) {
      case RegexSimplificationStepType.start:
        return 'Start';
      case RegexSimplificationStepType.analyze:
        return 'Analyze';
      case RegexSimplificationStepType.applyRule:
        return 'Apply Rule';
      case RegexSimplificationStepType.noRuleApplicable:
        return 'No Rule Applicable';
      case RegexSimplificationStepType.generateSamples:
        return 'Generate Samples';
      case RegexSimplificationStepType.completion:
        return 'Completion';
    }
  }

  /// Gets a short description of what this step type does
  String get description {
    switch (this) {
      case RegexSimplificationStepType.start:
        return 'Initialize the regex simplification process';
      case RegexSimplificationStepType.analyze:
        return 'Analyze complexity metrics of the regex';
      case RegexSimplificationStepType.applyRule:
        return 'Apply an algebraic simplification rule';
      case RegexSimplificationStepType.noRuleApplicable:
        return 'No further simplification rules can be applied';
      case RegexSimplificationStepType.generateSamples:
        return 'Generate sample strings matching the regex';
      case RegexSimplificationStepType.completion:
        return 'Complete the simplification process';
    }
  }
}

/// Simplification rules for regular expressions
enum SimplificationRule {
  /// r|∅ → r (union with empty set)
  emptyUnion,

  /// ∅|r → r (empty set union)
  emptyUnionLeft,

  /// r∅ → ∅ (concatenation with empty set)
  emptySetConcatenation,

  /// ∅r → ∅ (empty set concatenation left)
  emptySetConcatenationLeft,

  /// rε → r (concatenation with empty string)
  emptyStringConcatenation,

  /// εr → r (empty string concatenation left)
  emptyStringConcatenationLeft,

  /// r** → r* (star idempotence)
  starIdempotence,

  /// ∅* → ε (empty set star)
  emptySetStar,

  /// ε* → ε (empty string star)
  emptyStringStar,

  /// r|r → r (union idempotence)
  unionIdempotence,

  /// (r*)* → r* (double star)
  doubleStar,

  /// ε|rr* → r* (plus to star conversion)
  plusToStar,

  /// ε|r*r → r* (plus to star conversion alternative)
  plusToStarAlt,

  /// r+ → rr* (plus expansion)
  plusExpansion,

  /// r? → ε|r (optional expansion)
  optionalExpansion,

  /// (ε|r)* → r* (optional star simplification)
  optionalStarSimplification,

  /// r*r* → r* (star concatenation idempotence)
  starConcatenationIdempotence,

  /// (r|s)* → (r*s*)* (union star distribution) - use with caution
  unionStarDistribution,

  /// Removing unnecessary parentheses
  redundantParentheses,

  // a|b|c → [abc] (character class creation) - conceptual
  characterClassCreation,
}

/// Extension methods for SimplificationRule
extension SimplificationRuleExtension on SimplificationRule {
  /// Gets a human-readable name for the rule
  String get displayName {
    switch (this) {
      case SimplificationRule.emptyUnion:
        return 'Empty Union (r|∅ → r)';
      case SimplificationRule.emptyUnionLeft:
        return 'Empty Union Left (∅|r → r)';
      case SimplificationRule.emptySetConcatenation:
        return 'Empty Set Concatenation (r∅ → ∅)';
      case SimplificationRule.emptySetConcatenationLeft:
        return 'Empty Set Concatenation Left (∅r → ∅)';
      case SimplificationRule.emptyStringConcatenation:
        return 'Empty String Concatenation (rε → r)';
      case SimplificationRule.emptyStringConcatenationLeft:
        return 'Empty String Concatenation Left (εr → r)';
      case SimplificationRule.starIdempotence:
        return 'Star Idempotence (r** → r*)';
      case SimplificationRule.emptySetStar:
        return 'Empty Set Star (∅* → ε)';
      case SimplificationRule.emptyStringStar:
        return 'Empty String Star (ε* → ε)';
      case SimplificationRule.unionIdempotence:
        return 'Union Idempotence (r|r → r)';
      case SimplificationRule.doubleStar:
        return 'Double Star ((r*)* → r*)';
      case SimplificationRule.plusToStar:
        return 'Plus to Star (ε|rr* → r*)';
      case SimplificationRule.plusToStarAlt:
        return 'Plus to Star Alt (ε|r*r → r*)';
      case SimplificationRule.plusExpansion:
        return 'Plus Expansion (r+ → rr*)';
      case SimplificationRule.optionalExpansion:
        return 'Optional Expansion (r? → ε|r)';
      case SimplificationRule.optionalStarSimplification:
        return 'Optional Star ((ε|r)* → r*)';
      case SimplificationRule.starConcatenationIdempotence:
        return 'Star Concat Idempotence (r*r* → r*)';
      case SimplificationRule.unionStarDistribution:
        return 'Union Star Distribution';
      case SimplificationRule.redundantParentheses:
        return 'Remove Redundant Parentheses';
      case SimplificationRule.characterClassCreation:
        return 'Character Class Creation';
    }
  }

  /// Gets a detailed description of the rule
  String get description {
    switch (this) {
      case SimplificationRule.emptyUnion:
        return 'Union with the empty set has no effect; the result is the other operand';
      case SimplificationRule.emptyUnionLeft:
        return 'Empty set on the left of union has no effect';
      case SimplificationRule.emptySetConcatenation:
        return 'Concatenation with the empty set produces the empty set';
      case SimplificationRule.emptySetConcatenationLeft:
        return 'Empty set on the left of concatenation produces empty set';
      case SimplificationRule.emptyStringConcatenation:
        return 'Concatenation with the empty string has no effect';
      case SimplificationRule.emptyStringConcatenationLeft:
        return 'Empty string on the left of concatenation has no effect';
      case SimplificationRule.starIdempotence:
        return 'Applying Kleene star twice is equivalent to applying it once';
      case SimplificationRule.emptySetStar:
        return 'The Kleene star of the empty set is the empty string';
      case SimplificationRule.emptyStringStar:
        return 'The Kleene star of the empty string is the empty string';
      case SimplificationRule.unionIdempotence:
        return 'Union of identical expressions simplifies to one copy';
      case SimplificationRule.doubleStar:
        return 'Star of a starred expression simplifies to single star';
      case SimplificationRule.plusToStar:
        return 'Empty string union with one-or-more equals zero-or-more';
      case SimplificationRule.plusToStarAlt:
        return 'Empty string union with one-or-more (alt) equals zero-or-more';
      case SimplificationRule.plusExpansion:
        return 'Plus operator expands to concatenation with star';
      case SimplificationRule.optionalExpansion:
        return 'Optional operator expands to union with empty string';
      case SimplificationRule.optionalStarSimplification:
        return 'Star of optional expression simplifies to just star';
      case SimplificationRule.starConcatenationIdempotence:
        return 'Concatenation of identical stars simplifies to single star';
      case SimplificationRule.unionStarDistribution:
        return 'Star distributes over union in specific patterns';
      case SimplificationRule.redundantParentheses:
        return 'Parentheses that do not affect precedence can be removed';
      case SimplificationRule.characterClassCreation:
        return 'Multiple single-character alternatives can form a character class';
    }
  }

  /// Gets the formal notation of the rule
  String get formalNotation {
    switch (this) {
      case SimplificationRule.emptyUnion:
        return 'r|∅ → r';
      case SimplificationRule.emptyUnionLeft:
        return '∅|r → r';
      case SimplificationRule.emptySetConcatenation:
        return 'r∅ → ∅';
      case SimplificationRule.emptySetConcatenationLeft:
        return '∅r → ∅';
      case SimplificationRule.emptyStringConcatenation:
        return 'rε → r';
      case SimplificationRule.emptyStringConcatenationLeft:
        return 'εr → r';
      case SimplificationRule.starIdempotence:
        return 'r** → r*';
      case SimplificationRule.emptySetStar:
        return '∅* → ε';
      case SimplificationRule.emptyStringStar:
        return 'ε* → ε';
      case SimplificationRule.unionIdempotence:
        return 'r|r → r';
      case SimplificationRule.doubleStar:
        return '(r*)* → r*';
      case SimplificationRule.plusToStar:
        return 'ε|rr* → r*';
      case SimplificationRule.plusToStarAlt:
        return 'ε|r*r → r*';
      case SimplificationRule.plusExpansion:
        return 'r+ → rr*';
      case SimplificationRule.optionalExpansion:
        return 'r? → ε|r';
      case SimplificationRule.optionalStarSimplification:
        return '(ε|r)* → r*';
      case SimplificationRule.starConcatenationIdempotence:
        return 'r*r* → r*';
      case SimplificationRule.unionStarDistribution:
        return '(r|s)* → (r*s*)*';
      case SimplificationRule.redundantParentheses:
        return '(r) → r';
      case SimplificationRule.characterClassCreation:
        return 'a|b|c → [abc]';
    }
  }
}
