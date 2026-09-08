part of 'regex_simplifier.dart';

/// Internal helper class for step application results
class _StepApplicationResult {
  final String newRegex;
  final RegexSimplificationStep step;

  const _StepApplicationResult({required this.newRegex, required this.step});
}

/// Result of regex simplification with step-by-step information
class RegexSimplificationResult {
  /// Original regular expression before simplification
  final String originalRegex;

  /// Simplified regular expression after all transformations
  final String simplifiedRegex;

  /// Detailed simplification steps
  final List<RegexSimplificationStep> steps;

  /// Total execution time
  final Duration executionTime;

  /// Total number of rules applied during simplification
  final int totalRulesApplied;

  const RegexSimplificationResult({
    required this.originalRegex,
    required this.simplifiedRegex,
    required this.steps,
    required this.executionTime,
    required this.totalRulesApplied,
  });

  /// Gets the number of steps
  int get stepCount => steps.length;

  /// Gets the first step
  RegexSimplificationStep? get firstStep =>
      steps.isNotEmpty ? steps.first : null;

  /// Gets the last step
  RegexSimplificationStep? get lastStep => steps.isNotEmpty ? steps.last : null;

  /// Gets the execution time in milliseconds
  int get executionTimeMs => executionTime.inMilliseconds;

  /// Gets the execution time in seconds
  double get executionTimeSeconds => executionTime.inMicroseconds / 1000000.0;

  /// Gets the number of characters saved by simplification
  int get charactersSaved => originalRegex.length - simplifiedRegex.length;

  /// Gets the percentage reduction in length
  double get reductionPercentage {
    if (originalRegex.isEmpty) return 0.0;
    return (charactersSaved / originalRegex.length) * 100;
  }

  /// Checks if simplification made any changes
  bool get madeProgress => originalRegex != simplifiedRegex;

  /// Gets only the rule application steps (excludes start/completion)
  List<RegexSimplificationStep> get ruleApplicationSteps {
    return steps
        .where((s) => s.stepType == RegexSimplificationStepType.applyRule)
        .toList();
  }

  /// Gets a summary of all rules applied
  List<SimplificationRule> get rulesApplied {
    return ruleApplicationSteps
        .where((s) => s.ruleApplied != null)
        .map((s) => s.ruleApplied!)
        .toList();
  }

  /// Converts the result to a JSON representation
  Map<String, dynamic> toJson() {
    return {
      'originalRegex': originalRegex,
      'simplifiedRegex': simplifiedRegex,
      'steps': steps.map((s) => s.toJson()).toList(),
      'executionTimeMs': executionTimeMs,
      'totalRulesApplied': totalRulesApplied,
      'charactersSaved': charactersSaved,
      'reductionPercentage': reductionPercentage,
    };
  }

  /// Creates a result from a JSON representation
  factory RegexSimplificationResult.fromJson(Map<String, dynamic> json) {
    return RegexSimplificationResult(
      originalRegex: json['originalRegex'] as String,
      simplifiedRegex: json['simplifiedRegex'] as String,
      steps: (json['steps'] as List)
          .map(
            (s) => RegexSimplificationStep.fromJson(s as Map<String, dynamic>),
          )
          .toList(),
      executionTime: Duration(milliseconds: json['executionTimeMs'] as int),
      totalRulesApplied: json['totalRulesApplied'] as int,
    );
  }

  @override
  String toString() {
    return 'RegexSimplificationResult('
        'original: "$originalRegex", '
        'simplified: "$simplifiedRegex", '
        'steps: $stepCount, '
        'rules: $totalRulesApplied, '
        'saved: $charactersSaved chars)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RegexSimplificationResult &&
        other.originalRegex == originalRegex &&
        other.simplifiedRegex == simplifiedRegex &&
        const ListEquality<RegexSimplificationStep>().equals(
          other.steps,
          steps,
        ) &&
        other.executionTime == executionTime &&
        other.totalRulesApplied == totalRulesApplied;
  }

  @override
  int get hashCode {
    return Object.hash(
      originalRegex,
      simplifiedRegex,
      const ListEquality<RegexSimplificationStep>().hash(steps),
      executionTime,
      totalRulesApplied,
    );
  }
}
