import 'package:freezed_annotation/freezed_annotation.dart';

import '../messages/structured_message.dart';
import 'grammar.dart';
import 'grammar_transformation_step.dart';

part 'grammar_gnf_structured_transformation_step.freezed.dart';

/// A GNF step with locale-neutral operation and rationale payloads.
///
/// [legacyStep] preserves the existing [GrammarTransformationStep] API while
/// presentation code migrates from embedded English prose.
@freezed
abstract class GrammarGnfStructuredTransformationStep
    with _$GrammarGnfStructuredTransformationStep {
  const GrammarGnfStructuredTransformationStep._();

  const factory GrammarGnfStructuredTransformationStep({
    required GrammarTransformationStep legacyStep,
    required StructuredMessage operationMessage,
    required StructuredMessage rationaleMessage,
  }) = _GrammarGnfStructuredTransformationStep;

  String get id => legacyStep.id;
  String get operation => legacyStep.operation;
  String get rationale => legacyStep.rationale;
  Grammar get before => legacyStep.before;
  Grammar get after => legacyStep.after;
  Set<String> get changedSymbols => legacyStep.changedSymbols;
  Set<String> get changedProductionIds => legacyStep.changedProductionIds;
}
