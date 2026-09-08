import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/grammar_diagnostic.dart';
import 'package:turing_lab/core/models/grammar_gnf_structured_transformation_step.dart';
import 'package:turing_lab/core/models/grammar_transformation_step.dart';

part 'grammar_gnf_transformation_report.freezed.dart';

@freezed
abstract class GrammarGnfTransformationReport
    with _$GrammarGnfTransformationReport {
  const factory GrammarGnfTransformationReport({
    required Grammar grammar,
    required List<GrammarTransformationStep> steps,
    @Default(<GrammarGnfStructuredTransformationStep>[])
    List<GrammarGnfStructuredTransformationStep> structuredSteps,
    required List<GrammarDiagnostic> diagnostics,
  }) = _GrammarGnfTransformationReport;
}
