//
//  regex_analysis.dart
//  Turing Lab
//
//  Estruturas imutáveis que armazenam métricas de análise de complexidade
//  para expressões regulares, incluindo star height, nesting depth, contagem
//  de operadores, tamanho do alfabeto e strings de exemplo. Serve como retorno
//  padronizado para o RegexAnalyzer, mantendo todas as métricas calculadas
//  prontas para visualização educacional.
//
//  Thales Matheus Mendonça Santos - January 2026
//

/// Complete analysis result for a regular expression
class RegexAnalysis {
  /// Analysis of complexity metrics
  final RegexComplexityAnalysis complexityAnalysis;

  /// Analysis of structure and alphabet
  final RegexStructureAnalysis structureAnalysis;

  /// Sample strings attached to the analysis.
  ///
  /// `RegexAnalyzer.analyze()` returns this field with an empty sample list and
  /// acceptance metadata only. `RegexAnalyzer.analyzeWithSamples()` returns it
  /// with generated examples.
  final RegexSampleStrings sampleStrings;

  /// Time taken to perform the analysis
  final Duration executionTime;

  const RegexAnalysis({
    required this.complexityAnalysis,
    required this.structureAnalysis,
    required this.sampleStrings,
    required this.executionTime,
  });

  /// Creates an empty analysis with default values
  factory RegexAnalysis.empty() {
    return const RegexAnalysis(
      complexityAnalysis: RegexComplexityAnalysis(
        starHeight: 0,
        nestingDepth: 0,
        complexityScore: 0,
        complexityLevel: ComplexityLevel.simple,
      ),
      structureAnalysis: RegexStructureAnalysis(
        operatorCount: {},
        alphabetSize: 0,
        alphabet: {},
        totalLength: 0,
      ),
      sampleStrings: RegexSampleStrings(
        samples: [],
        shortestString: null,
        acceptsEmptyString: false,
      ),
      executionTime: Duration.zero,
    );
  }

  /// Creates a copy with updated fields
  RegexAnalysis copyWith({
    RegexComplexityAnalysis? complexityAnalysis,
    RegexStructureAnalysis? structureAnalysis,
    RegexSampleStrings? sampleStrings,
    Duration? executionTime,
  }) {
    return RegexAnalysis(
      complexityAnalysis: complexityAnalysis ?? this.complexityAnalysis,
      structureAnalysis: structureAnalysis ?? this.structureAnalysis,
      sampleStrings: sampleStrings ?? this.sampleStrings,
      executionTime: executionTime ?? this.executionTime,
    );
  }

  /// Converts to JSON representation
  Map<String, dynamic> toJson() {
    return {
      'complexityAnalysis': complexityAnalysis.toJson(),
      'structureAnalysis': structureAnalysis.toJson(),
      'sampleStrings': sampleStrings.toJson(),
      'executionTimeMs': executionTime.inMilliseconds,
    };
  }

  /// Creates from JSON representation
  factory RegexAnalysis.fromJson(Map<String, dynamic> json) {
    return RegexAnalysis(
      complexityAnalysis: RegexComplexityAnalysis.fromJson(
        json['complexityAnalysis'] as Map<String, dynamic>,
      ),
      structureAnalysis: RegexStructureAnalysis.fromJson(
        json['structureAnalysis'] as Map<String, dynamic>,
      ),
      sampleStrings: RegexSampleStrings.fromJson(
        json['sampleStrings'] as Map<String, dynamic>,
      ),
      executionTime: Duration(
        milliseconds: json['executionTimeMs'] as int? ?? 0,
      ),
    );
  }

  // Convenience getters for quick access to common metrics

  /// Gets the star height metric
  int get starHeight => complexityAnalysis.starHeight;

  /// Gets the nesting depth metric
  int get nestingDepth => complexityAnalysis.nestingDepth;

  /// Gets the complexity score
  int get complexityScore => complexityAnalysis.complexityScore;

  /// Gets the complexity level
  ComplexityLevel get complexityLevel => complexityAnalysis.complexityLevel;

  /// Gets the operator count map
  Map<String, int> get operatorCount => structureAnalysis.operatorCount;

  /// Gets the alphabet size
  int get alphabetSize => structureAnalysis.alphabetSize;

  /// Gets the list of sample strings
  List<String> get samples => sampleStrings.samples;

  /// Whether the regex accepts the empty string
  bool get acceptsEmptyString => sampleStrings.acceptsEmptyString;

  @override
  String toString() {
    return 'RegexAnalysis('
        'starHeight: $starHeight, '
        'nestingDepth: $nestingDepth, '
        'complexity: ${complexityLevel.name}, '
        'alphabetSize: $alphabetSize, '
        'samples: ${samples.length})';
  }
}

/// Analysis of regex complexity metrics
class RegexComplexityAnalysis {
  /// Maximum nesting of Kleene star operators
  /// For example: a* has height 1, (a*)* has height 2
  final int starHeight;

  /// Maximum depth of parentheses nesting
  /// For example: (a) has depth 1, ((a|b)c) has depth 2
  final int nestingDepth;

  /// Computed complexity score based on all metrics
  /// Higher scores indicate more complex expressions
  final int complexityScore;

  /// Categorical complexity level
  final ComplexityLevel complexityLevel;

  const RegexComplexityAnalysis({
    required this.starHeight,
    required this.nestingDepth,
    required this.complexityScore,
    required this.complexityLevel,
  });

  /// Creates complexity analysis from raw metrics
  factory RegexComplexityAnalysis.fromMetrics({
    required int starHeight,
    required int nestingDepth,
    required int operatorTotal,
    required int length,
  }) {
    // Compute weighted complexity score
    // Star height is heavily weighted as it affects language complexity
    // Nesting depth affects readability
    // Operator count affects expression size
    final score = (starHeight * 3) + (nestingDepth * 2) + (operatorTotal ~/ 2);

    // Determine complexity level based on score and individual metrics
    ComplexityLevel level;
    if (score <= 3 && starHeight <= 1 && nestingDepth <= 2) {
      level = ComplexityLevel.simple;
    } else if (score <= 8 && starHeight <= 2 && nestingDepth <= 4) {
      level = ComplexityLevel.moderate;
    } else {
      level = ComplexityLevel.complex;
    }

    return RegexComplexityAnalysis(
      starHeight: starHeight,
      nestingDepth: nestingDepth,
      complexityScore: score,
      complexityLevel: level,
    );
  }

  /// Converts to JSON representation
  Map<String, dynamic> toJson() {
    return {
      'starHeight': starHeight,
      'nestingDepth': nestingDepth,
      'complexityScore': complexityScore,
      'complexityLevel': complexityLevel.name,
    };
  }

  /// Creates from JSON representation
  factory RegexComplexityAnalysis.fromJson(Map<String, dynamic> json) {
    return RegexComplexityAnalysis(
      starHeight: json['starHeight'] as int? ?? 0,
      nestingDepth: json['nestingDepth'] as int? ?? 0,
      complexityScore: json['complexityScore'] as int? ?? 0,
      complexityLevel: ComplexityLevel.values.firstWhere(
        (e) => e.name == json['complexityLevel'],
        orElse: () => ComplexityLevel.simple,
      ),
    );
  }

  @override
  String toString() {
    return 'RegexComplexityAnalysis('
        'starHeight: $starHeight, '
        'nestingDepth: $nestingDepth, '
        'score: $complexityScore, '
        'level: ${complexityLevel.name})';
  }
}

/// Analysis of regex structure and alphabet
class RegexStructureAnalysis {
  /// Count of each operator type in the regex
  /// Keys: 'union', 'concatenation', 'star', 'plus', 'question'
  final Map<String, int> operatorCount;

  /// Number of distinct symbols in the alphabet
  final int alphabetSize;

  /// The set of distinct symbols used in the regex
  final Set<String> alphabet;

  /// Total length of the regex string
  final int totalLength;

  const RegexStructureAnalysis({
    required this.operatorCount,
    required this.alphabetSize,
    required this.alphabet,
    required this.totalLength,
  });

  /// Gets the total number of operators
  int get totalOperators {
    return operatorCount.values.fold(0, (sum, count) => sum + count);
  }

  /// Gets the count for a specific operator type
  int getOperatorCount(String operatorType) {
    return operatorCount[operatorType] ?? 0;
  }

  /// Gets union operator count
  int get unionCount => getOperatorCount('union');

  /// Gets concatenation operator count
  int get concatenationCount => getOperatorCount('concatenation');

  /// Gets star operator count
  int get starCount => getOperatorCount('star');

  /// Gets plus operator count
  int get plusCount => getOperatorCount('plus');

  /// Gets question/optional operator count
  int get questionCount => getOperatorCount('question');

  /// Converts to JSON representation
  Map<String, dynamic> toJson() {
    return {
      'operatorCount': operatorCount,
      'alphabetSize': alphabetSize,
      'alphabet': alphabet.toList(),
      'totalLength': totalLength,
    };
  }

  /// Creates from JSON representation
  factory RegexStructureAnalysis.fromJson(Map<String, dynamic> json) {
    final alphabetList =
        (json['alphabet'] as List?)?.map((e) => e as String).toSet() ??
            <String>{};
    return RegexStructureAnalysis(
      operatorCount: Map<String, int>.from(
        json['operatorCount'] as Map<String, dynamic>? ?? {},
      ),
      alphabetSize: json['alphabetSize'] as int? ?? 0,
      alphabet: alphabetList,
      totalLength: json['totalLength'] as int? ?? 0,
    );
  }

  @override
  String toString() {
    return 'RegexStructureAnalysis('
        'operators: $totalOperators, '
        'alphabetSize: $alphabetSize, '
        'length: $totalLength)';
  }
}

/// Sample strings generated from a regex
class RegexSampleStrings {
  /// List of sample strings that match the regex
  final List<String> samples;

  /// The shortest string that matches the regex (if any)
  final String? shortestString;

  /// Whether the regex accepts the empty string (epsilon)
  final bool acceptsEmptyString;

  const RegexSampleStrings({
    required this.samples,
    required this.shortestString,
    required this.acceptsEmptyString,
  });

  /// Gets the number of samples generated
  int get count => samples.length;

  /// Whether any samples were generated
  bool get hasSamples => samples.isNotEmpty;

  /// Gets samples up to a maximum count
  List<String> take(int maxCount) {
    return samples.take(maxCount).toList();
  }

  /// Converts to JSON representation
  Map<String, dynamic> toJson() {
    return {
      'samples': samples,
      'shortestString': shortestString,
      'acceptsEmptyString': acceptsEmptyString,
    };
  }

  /// Creates from JSON representation
  factory RegexSampleStrings.fromJson(Map<String, dynamic> json) {
    return RegexSampleStrings(
      samples:
          (json['samples'] as List?)?.map((e) => e as String).toList() ?? [],
      shortestString: json['shortestString'] as String?,
      acceptsEmptyString: json['acceptsEmptyString'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'RegexSampleStrings('
        'count: $count, '
        'shortest: $shortestString, '
        'acceptsEmpty: $acceptsEmptyString)';
  }
}

/// Complexity levels for regular expressions
enum ComplexityLevel {
  /// Simple expressions with low star height and nesting
  /// Typically: literals, simple alternations, single stars
  simple,

  /// Moderate expressions with medium complexity
  /// Typically: nested groups, multiple operators, some nesting
  moderate,

  /// Complex expressions with high star height or deep nesting
  /// Typically: nested stars, deep parentheses, many operators
  complex,
}

/// Extension methods for ComplexityLevel
extension ComplexityLevelExtension on ComplexityLevel {
  /// Gets a human-readable display name
  String get displayName {
    switch (this) {
      case ComplexityLevel.simple:
        return 'Simple';
      case ComplexityLevel.moderate:
        return 'Moderate';
      case ComplexityLevel.complex:
        return 'Complex';
    }
  }

  /// Gets a description of this complexity level
  String get description {
    switch (this) {
      case ComplexityLevel.simple:
        return 'Easy to understand, low computational cost';
      case ComplexityLevel.moderate:
        return 'Moderate complexity, some analysis required';
      case ComplexityLevel.complex:
        return 'High complexity, careful analysis recommended';
    }
  }

  /// Gets a color hint for UI display (as a hex string)
  String get colorHint {
    switch (this) {
      case ComplexityLevel.simple:
        return '#4CAF50'; // Green
      case ComplexityLevel.moderate:
        return '#FF9800'; // Orange
      case ComplexityLevel.complex:
        return '#F44336'; // Red
    }
  }

  /// Gets an icon hint for UI display
  String get iconHint {
    switch (this) {
      case ComplexityLevel.simple:
        return 'check_circle';
      case ComplexityLevel.moderate:
        return 'warning';
      case ComplexityLevel.complex:
        return 'error';
    }
  }
}
