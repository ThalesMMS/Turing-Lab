import '../messages/structured_message.dart';

export 'grammar_analysis_structured_transformation_step.dart';

/// Locale-neutral diagnostics emitted by grammar analysis algorithms.
///
/// The analysis result carries stable message identities; presentation code
/// resolves their explanatory text for the active locale.
abstract final class GrammarAnalysisMessages {
  static StructuredMessage emptyProductions() => _message(
    'empty-productions',
    category: StructuredMessageCategory.validation,
    severity: StructuredMessageSeverity.error,
  );

  static StructuredMessage noLeftRecursion() => _message(
    'no-left-recursion',
    category: StructuredMessageCategory.analysis,
    severity: StructuredMessageSeverity.information,
  );

  static StructuredMessage firstProductionLhsUndeclared(String left) =>
      _validation(
        'first-production-lhs-undeclared',
        arguments: {
          'non-terminal': StructuredMessageArgument.symbol(
            left,
            role: 'grammar-nonterminal',
          ),
        },
      );

  static StructuredMessage firstEpsilonFromEmptyProduction(String left) =>
      _analysis(
        'first-epsilon-empty-production',
        arguments: {
          'non-terminal': StructuredMessageArgument.symbol(
            left,
            role: 'grammar-nonterminal',
          ),
        },
      );

  static StructuredMessage firstEpsilonFromProduction(
    String left,
    String production,
  ) => _analysis(
    'first-epsilon-production',
    arguments: {
      'non-terminal': StructuredMessageArgument.symbol(
        left,
        role: 'grammar-nonterminal',
      ),
      'production': StructuredMessageArgument.literal(
        production,
        role: 'grammar-production',
      ),
    },
  );

  static StructuredMessage firstTerminalFromProduction({
    required String left,
    required String symbol,
    required String production,
  }) => _analysis(
    'first-terminal-production',
    arguments: {
      'non-terminal': StructuredMessageArgument.symbol(
        left,
        role: 'grammar-nonterminal',
      ),
      'symbol': StructuredMessageArgument.symbol(
        symbol,
        role: 'grammar-symbol',
      ),
      'production': StructuredMessageArgument.literal(
        production,
        role: 'grammar-production',
      ),
    },
  );

  static StructuredMessage firstAbsorbsFirst({
    required String left,
    required String source,
    required String production,
  }) => _analysis(
    'first-absorbs-first',
    arguments: {
      'non-terminal': StructuredMessageArgument.symbol(
        left,
        role: 'grammar-nonterminal',
      ),
      'source': StructuredMessageArgument.symbol(
        source,
        role: 'grammar-nonterminal',
      ),
      'production': StructuredMessageArgument.literal(
        production,
        role: 'grammar-production',
      ),
    },
  );

  static StructuredMessage firstEpsilonFromNullableProduction({
    required String left,
    required String production,
  }) => _analysis(
    'first-epsilon-nullable-production',
    arguments: {
      'non-terminal': StructuredMessageArgument.symbol(
        left,
        role: 'grammar-nonterminal',
      ),
      'production': StructuredMessageArgument.literal(
        production,
        role: 'grammar-production',
      ),
    },
  );

  static StructuredMessage firstSetsComputed(int nonTerminalCount) => _analysis(
    'first-sets-computed',
    arguments: {
      'count': StructuredMessageArgument.count(
        nonTerminalCount,
        role: 'grammar-nonterminal-count',
      ),
    },
  );

  static StructuredMessage followStartSymbolUndeclared(String startSymbol) =>
      _validation(
        'follow-start-symbol-undeclared',
        arguments: {
          'symbol': StructuredMessageArgument.symbol(
            startSymbol,
            role: 'grammar-start-symbol',
          ),
        },
      );

  static StructuredMessage followStartSymbolMissingEntry(String startSymbol) =>
      _analysis(
        'follow-start-symbol-missing-entry',
        severity: StructuredMessageSeverity.error,
        arguments: {
          'symbol': StructuredMessageArgument.symbol(
            startSymbol,
            role: 'grammar-start-symbol',
          ),
        },
      );

  static StructuredMessage followStartIncludesEndMarker(String startSymbol) =>
      _analysis(
        'follow-start-includes-end-marker',
        arguments: {
          'symbol': StructuredMessageArgument.symbol(
            startSymbol,
            role: 'grammar-start-symbol',
          ),
        },
      );

  static StructuredMessage followProductionLhsUndeclared(String left) =>
      _validation(
        'follow-production-lhs-undeclared',
        arguments: {
          'non-terminal': StructuredMessageArgument.symbol(
            left,
            role: 'grammar-nonterminal',
          ),
        },
      );

  static StructuredMessage followGainsFromSuffix({
    required String symbol,
    required String gained,
    required String production,
  }) => _analysis(
    'follow-gains-from-suffix',
    arguments: {
      'non-terminal': StructuredMessageArgument.symbol(
        symbol,
        role: 'grammar-nonterminal',
      ),
      'symbols': StructuredMessageArgument.literal(
        gained,
        role: 'grammar-symbol-list',
      ),
      'production': StructuredMessageArgument.literal(
        production,
        role: 'grammar-production',
      ),
    },
  );

  static StructuredMessage followAbsorbsFollow({
    required String symbol,
    required String source,
    required String production,
  }) => _analysis(
    'follow-absorbs-follow',
    arguments: {
      'non-terminal': StructuredMessageArgument.symbol(
        symbol,
        role: 'grammar-nonterminal',
      ),
      'source': StructuredMessageArgument.symbol(
        source,
        role: 'grammar-nonterminal',
      ),
      'production': StructuredMessageArgument.literal(
        production,
        role: 'grammar-production',
      ),
    },
  );

  static StructuredMessage followSetsComputed(int nonTerminalCount) =>
      _analysis(
        'follow-sets-computed',
        arguments: {
          'count': StructuredMessageArgument.count(
            nonTerminalCount,
            role: 'grammar-nonterminal-count',
          ),
        },
      );

  static StructuredMessage processingOrder(String nonTerminals) => _analysis(
    'processing-order',
    arguments: {
      'non-terminals': StructuredMessageArgument.literal(
        nonTerminals,
        role: 'grammar-nonterminal-list',
      ),
    },
  );

  static StructuredMessage substitutionNote({
    required String production,
    required String via,
  }) => _analysis(
    'substitution-note',
    arguments: {
      'production': StructuredMessageArgument.literal(
        production,
        role: 'grammar-production',
      ),
      'via': StructuredMessageArgument.symbol(via, role: 'grammar-nonterminal'),
    },
  );

  static StructuredMessage substitutionDerivation({
    required String production,
    required String replacements,
  }) => _analysis(
    'substitution-derivation',
    arguments: {
      'production': StructuredMessageArgument.literal(
        production,
        role: 'grammar-production',
      ),
      'replacements': StructuredMessageArgument.literal(
        replacements,
        role: 'grammar-production-list',
      ),
    },
  );

  static StructuredMessage substitutionOperation({
    required String current,
    required String via,
  }) => _transformation(
    'substitution-operation',
    arguments: {
      'non-terminal': StructuredMessageArgument.symbol(
        current,
        role: 'grammar-nonterminal',
      ),
      'via': StructuredMessageArgument.symbol(via, role: 'grammar-nonterminal'),
    },
  );

  static StructuredMessage substitutionRationale({
    required String current,
    required String via,
  }) => _transformation(
    'substitution-rationale',
    arguments: {
      'non-terminal': StructuredMessageArgument.symbol(
        current,
        role: 'grammar-nonterminal',
      ),
      'via': StructuredMessageArgument.symbol(via, role: 'grammar-nonterminal'),
    },
  );

  static StructuredMessage removeVacuousRecursionRationale(
    String nonTerminal,
  ) => _transformation(
    'remove-vacuous-recursion-rationale',
    arguments: {
      'non-terminal': StructuredMessageArgument.symbol(
        nonTerminal,
        role: 'grammar-nonterminal',
      ),
    },
  );

  static StructuredMessage vacuousRecursionDerivation(String productions) =>
      _analysis(
        'vacuous-recursion-derivation',
        arguments: {
          'productions': StructuredMessageArgument.literal(
            productions,
            role: 'grammar-production-list',
          ),
        },
      );

  static StructuredMessage recursiveOnlyRationale(String nonTerminal) =>
      _transformation(
        'recursive-only-rationale',
        arguments: {
          'non-terminal': StructuredMessageArgument.symbol(
            nonTerminal,
            role: 'grammar-nonterminal',
          ),
        },
      );

  static StructuredMessage recursiveOnlyDerivation(String nonTerminal) =>
      _analysis(
        'recursive-only-derivation',
        arguments: {
          'non-terminal': StructuredMessageArgument.symbol(
            nonTerminal,
            role: 'grammar-nonterminal',
          ),
        },
      );

  static StructuredMessage directRecursionIntroduced({
    required String introduced,
    required String nonTerminal,
  }) => _analysis(
    'direct-recursion-introduced',
    arguments: {
      'introduced': StructuredMessageArgument.symbol(
        introduced,
        role: 'grammar-nonterminal',
      ),
      'non-terminal': StructuredMessageArgument.symbol(
        nonTerminal,
        role: 'grammar-nonterminal',
      ),
    },
  );

  static StructuredMessage moveRecursiveSuffixesRationale({
    required String nonTerminal,
    required String introduced,
  }) => _transformation(
    'move-recursive-suffixes-rationale',
    arguments: {
      'non-terminal': StructuredMessageArgument.symbol(
        nonTerminal,
        role: 'grammar-nonterminal',
      ),
      'introduced': StructuredMessageArgument.symbol(
        introduced,
        role: 'grammar-nonterminal',
      ),
    },
  );

  static StructuredMessage directRecursionRewrittenDerivation({
    required String nonTerminal,
    required String introduced,
  }) => _analysis(
    'direct-recursion-rewritten',
    arguments: {
      'non-terminal': StructuredMessageArgument.symbol(
        nonTerminal,
        role: 'grammar-nonterminal',
      ),
      'introduced': StructuredMessageArgument.symbol(
        introduced,
        role: 'grammar-nonterminal',
      ),
    },
  );

  static StructuredMessage directRecursionOperation(String nonTerminal) =>
      _transformation(
        'direct-recursion-operation',
        arguments: {
          'non-terminal': StructuredMessageArgument.symbol(
            nonTerminal,
            role: 'grammar-nonterminal',
          ),
        },
      );

  static StructuredMessage leftCornerCycleRemains() => _analysis(
    'left-corner-cycle-remains',
    severity: StructuredMessageSeverity.error,
  );

  static StructuredMessage leftRecursionRemoved() => _analysis(
    'left-recursion-removed',
    severity: StructuredMessageSeverity.information,
  );

  static StructuredMessage _validation(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(
    code,
    category: StructuredMessageCategory.validation,
    severity: StructuredMessageSeverity.error,
    arguments: arguments,
  );

  static StructuredMessage _analysis(
    String code, {
    StructuredMessageSeverity severity = StructuredMessageSeverity.information,
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(
    code,
    category: StructuredMessageCategory.analysis,
    severity: severity,
    arguments: arguments,
  );

  static StructuredMessage _transformation(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(
    code,
    category: StructuredMessageCategory.transformation,
    severity: StructuredMessageSeverity.information,
    arguments: arguments,
  );

  static StructuredMessage _message(
    String code, {
    required StructuredMessageCategory category,
    required StructuredMessageSeverity severity,
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => StructuredMessage(
    namespace: 'grammar.analysis',
    code: code,
    category: category,
    severity: severity,
    arguments: arguments,
  );
}
