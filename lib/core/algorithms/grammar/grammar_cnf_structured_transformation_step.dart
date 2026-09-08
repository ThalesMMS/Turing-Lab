part of 'grammar_cnf_messages.dart';

/// A CNF step with locale-neutral operation and rationale payloads.
///
/// [legacyStep] is retained so callers can continue to use the existing
/// [GrammarTransformationStep] API while presentation code migrates.
final class GrammarCnfStructuredTransformationStep {
  const GrammarCnfStructuredTransformationStep({
    required this.legacyStep,
    required this.operationMessage,
    required this.rationaleMessage,
  });

  final GrammarTransformationStep legacyStep;
  final StructuredMessage operationMessage;
  final StructuredMessage rationaleMessage;

  String get id => legacyStep.id;
  String get operation => legacyStep.operation;
  String get rationale => legacyStep.rationale;
  Grammar get before => legacyStep.before;
  Grammar get after => legacyStep.after;
  Set<String> get changedSymbols => legacyStep.changedSymbols;
  Set<String> get changedProductionIds => legacyStep.changedProductionIds;
}
