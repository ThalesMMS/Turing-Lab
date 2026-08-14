//
//  grammar_transformation_step.dart
//  Turing Lab
//
//  Shared model for recording grammar transformation step history (e.g., CNF/GNF).
//  Each step contains before/after snapshots plus a human-readable rationale and
//  an optional list of symbols/productions touched by the operation.
//
import 'package:freezed_annotation/freezed_annotation.dart';

import 'grammar.dart';

part 'grammar_transformation_step.freezed.dart';
part 'grammar_transformation_step.g.dart';

/// One step in a grammar transformation pipeline.
///
/// This model is UI-friendly (rationale + changed items) and serializable so
/// future export workflows can persist transformation histories.
@freezed
abstract class GrammarTransformationStep with _$GrammarTransformationStep {
  const GrammarTransformationStep._();

  const factory GrammarTransformationStep({
    required String id,
    required String operation,
    required String rationale,
    required Grammar before,
    required Grammar after,
    @Default(<String>{}) Set<String> changedSymbols,
    @Default(<String>{}) Set<String> changedProductionIds,
  }) = _GrammarTransformationStep;

  factory GrammarTransformationStep.fromJson(Map<String, dynamic> json) =>
      _$GrammarTransformationStepFromJson(json);
}
