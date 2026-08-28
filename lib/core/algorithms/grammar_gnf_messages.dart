import '../messages/structured_message.dart';
import '../models/grammar.dart';
import '../models/grammar_transformation_step.dart';

/// Locale-neutral messages emitted by the GNF transformation pipeline.
///
/// Legacy diagnostic codes and step strings remain available for callers that
/// have not migrated to structured payloads. Presentation code should resolve
/// these messages at the active locale.
abstract final class GrammarGnfMessages {
  static StructuredMessage transformFailed() => _message(
    'transform-failed',
    category: StructuredMessageCategory.transformation,
    severity: StructuredMessageSeverity.error,
  );

  static StructuredMessage notGnf() => _message(
    'not-gnf',
    category: StructuredMessageCategory.validation,
    severity: StructuredMessageSeverity.warning,
  );

  static StructuredMessage convertTitle() => _message(
    'convert-title',
    category: StructuredMessageCategory.transformation,
    severity: StructuredMessageSeverity.information,
  );

  static StructuredMessage convertRationale() => _message(
    'convert-rationale',
    category: StructuredMessageCategory.transformation,
    severity: StructuredMessageSeverity.information,
  );

  static StructuredMessage _message(
    String code, {
    required StructuredMessageCategory category,
    required StructuredMessageSeverity severity,
  }) => StructuredMessage(
    namespace: 'grammar.gnf',
    code: code,
    category: category,
    severity: severity,
  );
}

/// A GNF step with locale-neutral operation and rationale payloads.
///
/// [legacyStep] preserves the existing [GrammarTransformationStep] API while
/// presentation code migrates from embedded English prose.
final class GrammarGnfStructuredTransformationStep {
  const GrammarGnfStructuredTransformationStep({
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
