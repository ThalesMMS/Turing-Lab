//
//  tm_multi_tape_reduction_messages.dart
//  Turing Lab
//
//  Locale-neutral messages emitted by the multi-tape to single-tape
//  reduction (tm_multi_tape_reducer.dart).
//

import '../../messages/structured_message.dart';
import 'tm_multi_tape_reducer.dart';

abstract final class TmMultiTapeReductionMessages {
  static const namespace = 'tm.multi-tape-reduction';

  static StructuredMessage fromDiagnostic({
    required TMMultiTapeReductionDiagnosticCode code,
    required TMMultiTapeReductionSeverity severity,
    String? detail,
    int? count,
    int? limit,
  }) {
    final arguments = <String, StructuredMessageArgument>{};
    switch (code) {
      case TMMultiTapeReductionDiagnosticCode.alreadySingleTape:
      case TMMultiTapeReductionDiagnosticCode.missingInitialState:
        break;
      case TMMultiTapeReductionDiagnosticCode.invalidMachine:
      case TMMultiTapeReductionDiagnosticCode.buildingBlocksUnsupported:
      case TMMultiTapeReductionDiagnosticCode.acceptancePolicyUnsupported:
      case TMMultiTapeReductionDiagnosticCode.blankInInputAlphabet:
        if (detail != null) {
          arguments['detail'] = StructuredMessageArgument.literal(
            detail,
            role: 'error-detail',
          );
        }
      case TMMultiTapeReductionDiagnosticCode.tapeSymbolBudget:
      case TMMultiTapeReductionDiagnosticCode.stateBudget:
      case TMMultiTapeReductionDiagnosticCode.transitionBudget:
        if (count != null) {
          arguments['count'] = StructuredMessageArgument.count(
            count,
            role: 'expansion-count',
          );
        }
        if (limit != null) {
          arguments['limit'] = StructuredMessageArgument.bound(
            limit,
            role: 'expansion-limit',
          );
        }
    }
    return StructuredMessage(
      namespace: namespace,
      code: codeFor(code),
      category: StructuredMessageCategory.conversion,
      severity: severity == TMMultiTapeReductionSeverity.warning
          ? StructuredMessageSeverity.warning
          : StructuredMessageSeverity.error,
      arguments: arguments,
    );
  }

  static String codeFor(
    TMMultiTapeReductionDiagnosticCode code,
  ) => switch (code) {
    TMMultiTapeReductionDiagnosticCode.alreadySingleTape =>
      'already-single-tape',
    TMMultiTapeReductionDiagnosticCode.invalidMachine => 'invalid-machine',
    TMMultiTapeReductionDiagnosticCode.missingInitialState =>
      'missing-initial-state',
    TMMultiTapeReductionDiagnosticCode.buildingBlocksUnsupported =>
      'building-blocks-unsupported',
    TMMultiTapeReductionDiagnosticCode.acceptancePolicyUnsupported =>
      'acceptance-policy-unsupported',
    TMMultiTapeReductionDiagnosticCode.blankInInputAlphabet =>
      'blank-in-input-alphabet',
    TMMultiTapeReductionDiagnosticCode.tapeSymbolBudget => 'tape-symbol-budget',
    TMMultiTapeReductionDiagnosticCode.stateBudget => 'state-budget',
    TMMultiTapeReductionDiagnosticCode.transitionBudget => 'transition-budget',
  };
}
