import '../../messages/structured_message.dart';
import 'll1_table_placement.dart';

/// Locale-neutral messages emitted by predictive grammar analyses.
///
/// Predictive reports keep their existing prose for compatibility. These
/// payloads carry the same facts in a form that presentation code can resolve
/// in the active locale.
abstract final class GrammarPredictiveMessages {
  static StructuredMessage factoringIntroduced({
    required String nonTerminal,
    required String introduced,
    required String prefix,
    required int productionCount,
  }) => _transformation(
    'factoring-introduced',
    arguments: {
      'non-terminal': StructuredMessageArgument.symbol(
        nonTerminal,
        role: 'grammar-nonterminal',
      ),
      'introduced': StructuredMessageArgument.symbol(
        introduced,
        role: 'grammar-nonterminal',
      ),
      'prefix': StructuredMessageArgument.literal(
        prefix,
        role: 'grammar-symbol-list',
      ),
      'production-count': StructuredMessageArgument.count(
        productionCount,
        role: 'grammar-production-count',
      ),
    },
  );

  static StructuredMessage factoringDerivation({
    required String nonTerminal,
    required String introduced,
    required String prefix,
    required int productionCount,
  }) => _analysis(
    'factoring-derivation',
    arguments: {
      'non-terminal': StructuredMessageArgument.symbol(
        nonTerminal,
        role: 'grammar-nonterminal',
      ),
      'introduced': StructuredMessageArgument.symbol(
        introduced,
        role: 'grammar-nonterminal',
      ),
      'prefix': StructuredMessageArgument.literal(
        prefix,
        role: 'grammar-symbol-list',
      ),
      'production-count': StructuredMessageArgument.count(
        productionCount,
        role: 'grammar-production-count',
      ),
    },
  );

  static StructuredMessage factoringSuffix({
    required String introduced,
    required String suffix,
  }) => _analysis(
    'factoring-suffix',
    arguments: {
      'introduced': StructuredMessageArgument.symbol(
        introduced,
        role: 'grammar-nonterminal',
      ),
      'suffix': StructuredMessageArgument.literal(
        suffix,
        role: 'grammar-symbol-list',
      ),
    },
  );

  static StructuredMessage noFactoringNeeded() =>
      _analysis('no-factoring-needed');

  static StructuredMessage productionLhsUndeclared(String nonTerminal) =>
      _validation(
        'production-lhs-undeclared',
        arguments: {
          'non-terminal': StructuredMessageArgument.symbol(
            nonTerminal,
            role: 'grammar-nonterminal',
          ),
        },
      );

  static StructuredMessage missingTableRow(String nonTerminal) => _validation(
    'missing-table-row',
    arguments: {
      'non-terminal': StructuredMessageArgument.symbol(
        nonTerminal,
        role: 'grammar-nonterminal',
      ),
    },
  );

  static StructuredMessage missingFollowOrTableEntry(String nonTerminal) =>
      _validation(
        'missing-follow-or-table-entry',
        arguments: {
          'non-terminal': StructuredMessageArgument.symbol(
            nonTerminal,
            role: 'grammar-nonterminal',
          ),
        },
      );

  static StructuredMessage tablePlacement({
    required LL1TablePlacement placement,
    required String nonTerminal,
    required String production,
    required String lookahead,
  }) => _analysis(
    placement == LL1TablePlacement.first
        ? 'table-placement-first'
        : 'table-placement-follow',
    arguments: {
      'non-terminal': StructuredMessageArgument.symbol(
        nonTerminal,
        role: 'grammar-nonterminal',
      ),
      'production': StructuredMessageArgument.literal(
        production,
        role: 'grammar-production',
      ),
      'lookahead': StructuredMessageArgument.symbol(
        lookahead,
        role: 'grammar-lookahead',
      ),
    },
  );

  static StructuredMessage tableConstructed(int nonTerminalCount) => _analysis(
    'table-constructed',
    arguments: {
      'count': StructuredMessageArgument.count(
        nonTerminalCount,
        role: 'grammar-nonterminal-count',
      ),
    },
  );

  static StructuredMessage tableNoConflicts() =>
      _analysis('table-no-conflicts');

  static StructuredMessage tableConflictsDetected(int conflictCount) =>
      _analysis(
        'table-conflicts-detected',
        severity: StructuredMessageSeverity.warning,
        arguments: {
          'count': StructuredMessageArgument.count(
            conflictCount,
            role: 'grammar-conflict-count',
          ),
        },
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
    namespace: 'grammar.predictive',
    code: code,
    category: category,
    severity: severity,
    arguments: arguments,
  );
}
