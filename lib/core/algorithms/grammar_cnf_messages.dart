import '../messages/structured_message.dart';
import '../models/grammar.dart';
import '../models/grammar_transformation_step.dart';

part 'grammar_cnf_step_kind.dart';
part 'grammar_cnf_structured_transformation_step.dart';

/// Locale-neutral messages emitted by the CNF transformation pipeline.
///
/// The transformer keeps its existing diagnostic codes and human-readable
/// step fields for compatibility. Presentation code should resolve these
/// payloads at the active locale when it needs user-facing text.
abstract final class GrammarCnfMessages {
  static StructuredMessage grammarNotCfg(String grammarType) => _message(
    'grammar-not-cfg',
    category: StructuredMessageCategory.validation,
    severity: StructuredMessageSeverity.warning,
    arguments: {
      'type': StructuredMessageArgument.outcome(
        grammarType,
        role: 'grammar-type',
      ),
    },
  );

  static StructuredMessage startSymbolRenameFailed() => _message(
    'start-symbol-rename-failed',
    category: StructuredMessageCategory.validation,
    severity: StructuredMessageSeverity.error,
  );

  static StructuredMessage notStrictCnf(String violations) => _message(
    'not-strict-cnf',
    category: StructuredMessageCategory.validation,
    severity: StructuredMessageSeverity.warning,
    arguments: {
      'violations': StructuredMessageArgument.literal(
        violations,
        role: 'grammar-violation-list',
      ),
    },
  );

  static StructuredMessage nullableSubsetLimitExceeded({
    required String productionId,
    required int nullablePositionCount,
    required int subsetCount,
    required int limit,
  }) => _message(
    'nullable-subset-limit-exceeded',
    category: StructuredMessageCategory.validation,
    severity: StructuredMessageSeverity.error,
    arguments: {
      'production': StructuredMessageArgument.identifier(
        productionId,
        role: 'production-id',
      ),
      'nullable-positions': StructuredMessageArgument.count(
        nullablePositionCount,
        role: 'nullable-position-count',
      ),
      'subsets': StructuredMessageArgument.count(
        subsetCount,
        role: 'nullable-subset-count',
      ),
      'limit': StructuredMessageArgument.bound(
        limit,
        role: 'nullable-subset-limit',
      ),
    },
  );

  static StructuredMessage newSymbolLimitReached(int limit) => _message(
    'new-symbol-limit-reached',
    category: StructuredMessageCategory.transformation,
    severity: StructuredMessageSeverity.warning,
    arguments: {
      'limit': StructuredMessageArgument.bound(limit, role: 'new-symbol-limit'),
    },
  );

  static StructuredMessage stepTitle(GrammarCnfStepKind step) =>
      _step(switch (step) {
        GrammarCnfStepKind.startSymbol => 'start-symbol-title',
        GrammarCnfStepKind.epsilon => 'epsilon-title',
        GrammarCnfStepKind.unit => 'unit-title',
        GrammarCnfStepKind.useless => 'useless-title',
        GrammarCnfStepKind.binarize => 'binarize-title',
      });

  static StructuredMessage stepRationale(GrammarCnfStepKind step) =>
      _step(switch (step) {
        GrammarCnfStepKind.startSymbol => 'start-symbol-rationale',
        GrammarCnfStepKind.epsilon => 'epsilon-rationale',
        GrammarCnfStepKind.unit => 'unit-rationale',
        GrammarCnfStepKind.useless => 'useless-rationale',
        GrammarCnfStepKind.binarize => 'binarize-rationale',
      });

  static StructuredMessage _step(String code) => _message(
    code,
    category: StructuredMessageCategory.transformation,
    severity: StructuredMessageSeverity.information,
  );

  static StructuredMessage _message(
    String code, {
    required StructuredMessageCategory category,
    required StructuredMessageSeverity severity,
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => StructuredMessage(
    namespace: 'grammar.cnf',
    code: code,
    category: category,
    severity: severity,
    arguments: arguments,
  );
}
