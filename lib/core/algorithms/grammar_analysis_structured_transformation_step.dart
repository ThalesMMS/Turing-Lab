import '../messages/structured_message.dart';
import '../models/grammar.dart';
import '../models/grammar_transformation_step.dart';

/// A left-recursion step with locale-neutral operation and rationale payloads.
///
/// The legacy step remains available because existing callers and persisted
/// transformation history still consume its text fields.
final class GrammarAnalysisStructuredTransformationStep {
  const GrammarAnalysisStructuredTransformationStep({
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
