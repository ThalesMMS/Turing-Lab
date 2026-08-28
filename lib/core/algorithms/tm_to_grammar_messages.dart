import '../messages/structured_message.dart';
import 'tm_to_unrestricted_grammar/tm_to_grammar_models.dart';

/// Locale-neutral messages emitted by the TM-to-unrestricted-grammar
/// conversion.
abstract final class TmToGrammarMessages {
  static StructuredMessage fromDiagnostic({
    required TMToGrammarDiagnosticCode code,
    String? stateId,
    String? symbol,
    String? detailCode,
    int? tapeCount,
    Iterable<String> relatedIds = const [],
    int? maxProductions,
  }) {
    final arguments = <String, StructuredMessageArgument>{};
    switch (code) {
      case TMToGrammarDiagnosticCode.invalidMachine:
        if (detailCode != null) {
          arguments['detail'] = StructuredMessageArgument.literal(
            detailCode,
            role: 'error-detail',
          );
        }
      case TMToGrammarDiagnosticCode.missingInitialState:
      case TMToGrammarDiagnosticCode.noAcceptingState:
        break;
      case TMToGrammarDiagnosticCode.multiTapeUnsupported:
        if (tapeCount != null) {
          arguments['tapes'] = StructuredMessageArgument.count(
            tapeCount,
            role: 'tape-count',
          );
        }
      case TMToGrammarDiagnosticCode.buildingBlocksUnsupported:
        final ids = relatedIds.toList()..sort();
        if (ids.isNotEmpty) {
          arguments['blocks'] = StructuredMessageArgument.literal(
            ids.join(', '),
            role: 'building-block-ids',
          );
        }
      case TMToGrammarDiagnosticCode.blankInInputAlphabet:
        if (symbol != null) {
          arguments['symbol'] = StructuredMessageArgument.symbol(
            symbol,
            role: 'tape-symbol',
          );
        }
      case TMToGrammarDiagnosticCode.inputOutsideTapeAlphabet:
        if (symbol != null) {
          arguments['symbol'] = StructuredMessageArgument.symbol(
            symbol,
            role: 'input-symbol',
          );
        }
      case TMToGrammarDiagnosticCode.constructionLimit:
        if (maxProductions != null) {
          arguments['limit'] = StructuredMessageArgument.bound(
            maxProductions,
            role: 'production-limit',
          );
        } else if (detailCode != null) {
          arguments['detail'] = StructuredMessageArgument.literal(
            detailCode,
            role: 'error-detail',
          );
        }
      case TMToGrammarDiagnosticCode.outputInvalid:
        if (detailCode != null) {
          arguments['detail'] = StructuredMessageArgument.literal(
            detailCode,
            role: 'error-detail',
          );
        }
      case TMToGrammarDiagnosticCode.unreachableState:
        if (stateId != null) {
          arguments['state'] = StructuredMessageArgument.identifier(
            stateId,
            role: 'state-id',
          );
        }
    }
    return StructuredMessage(
      namespace: 'tm.to-unrestricted-grammar',
      code: _code(code),
      category: StructuredMessageCategory.conversion,
      severity:
          code == TMToGrammarDiagnosticCode.noAcceptingState ||
              code == TMToGrammarDiagnosticCode.unreachableState
          ? StructuredMessageSeverity.warning
          : StructuredMessageSeverity.error,
      arguments: arguments,
    );
  }

  static String _code(TMToGrammarDiagnosticCode code) => switch (code) {
    TMToGrammarDiagnosticCode.invalidMachine => 'invalid-machine',
    TMToGrammarDiagnosticCode.missingInitialState => 'missing-initial-state',
    TMToGrammarDiagnosticCode.noAcceptingState => 'no-accepting-state',
    TMToGrammarDiagnosticCode.multiTapeUnsupported => 'multi-tape-unsupported',
    TMToGrammarDiagnosticCode.buildingBlocksUnsupported =>
      'building-blocks-unsupported',
    TMToGrammarDiagnosticCode.blankInInputAlphabet => 'blank-in-input-alphabet',
    TMToGrammarDiagnosticCode.inputOutsideTapeAlphabet =>
      'input-outside-tape-alphabet',
    TMToGrammarDiagnosticCode.constructionLimit => 'construction-limit',
    TMToGrammarDiagnosticCode.outputInvalid => 'output-invalid',
    TMToGrammarDiagnosticCode.unreachableState => 'unreachable-state',
  };
}
