import '../messages/structured_message.dart';

abstract final class PumpingLemmaMessages {
  static StructuredMessage pumpingLengthPositive() =>
      _message('validation.pumping-length-positive');

  static StructuredMessage exponentNonNegative() =>
      _message('validation.exponent-non-negative');

  static StructuredMessage maximumTokensNonNegative() =>
      _message('validation.maximum-tokens-non-negative');

  static StructuredMessage requiredTextNotEmpty(String field) => _message(
    'validation.required-text-not-empty',
    arguments: {
      'field': StructuredMessageArgument.identifier(field, role: 'field-name'),
    },
  );

  static StructuredMessage suggestedWitnessNotEmpty() =>
      _message('validation.suggested-witness-not-empty');

  static StructuredMessage customTitleNotEmpty() =>
      _message('validation.custom-title-not-empty');

  static StructuredMessage witnessRequiresPumpingLength() =>
      _message('validation.witness-requires-pumping-length');

  static StructuredMessage witnessMinimumTokens(int minimumTokens) => _message(
    'validation.witness-minimum-tokens',
    arguments: {
      'minimum': StructuredMessageArgument.integer(
        minimumTokens,
        role: 'minimum-token-count',
      ),
    },
  );

  static StructuredMessage decompositionTheoremMismatch({
    required String actual,
    required String expected,
  }) => _message(
    'validation.decomposition-theorem-mismatch',
    arguments: {
      'actual': StructuredMessageArgument.outcome(
        actual,
        role: 'pumping-theorem',
      ),
      'expected': StructuredMessageArgument.outcome(
        expected,
        role: 'pumping-theorem',
      ),
    },
  );

  static StructuredMessage decompositionWitnessMismatch() =>
      _message('validation.decomposition-witness-mismatch');

  static StructuredMessage decompositionConstraintViolation() =>
      _message('validation.decomposition-constraint-violation');

  static StructuredMessage enterPositivePumpingLength() =>
      _message('input.enter-positive-pumping-length');

  static StructuredMessage enterNonNegativeExponent() =>
      _message('input.enter-non-negative-exponent');

  static StructuredMessage invalidTokenArray() =>
      _message('input.invalid-token-array');

  static StructuredMessage noValidDecomposition() =>
      _message('session.no-valid-decomposition');

  static StructuredMessage decompositionsEnumerated(int count) => _message(
    'session.decompositions-enumerated',
    severity: StructuredMessageSeverity.information,
    arguments: {
      'count': StructuredMessageArgument.count(
        count,
        role: 'decomposition-count',
      ),
    },
  );

  static StructuredMessage pumpedWordBounded({
    required int minimumRequiredTokens,
    required int maximumTokens,
  }) => _message(
    'session.pumped-word-bounded',
    arguments: {
      'minimum': StructuredMessageArgument.integer(
        minimumRequiredTokens,
        role: 'minimum-token-count',
      ),
      'maximum': StructuredMessageArgument.bound(
        maximumTokens,
        role: 'token-limit',
      ),
    },
  );

  static StructuredMessage chooseBoundedExponent() =>
      _message('session.choose-bounded-exponent');

  static StructuredMessage counterexampleEvidence() => _message(
    'outcome.counterexample-evidence',
    severity: StructuredMessageSeverity.information,
  );

  static StructuredMessage finiteCheckInconclusive() => _message(
    'outcome.finite-check-inconclusive',
    severity: StructuredMessageSeverity.information,
  );

  static StructuredMessage sessionImported() => _message(
    'session.imported',
    severity: StructuredMessageSeverity.information,
  );

  static StructuredMessage transitionWrongStage() =>
      _message('transition.wrong-stage');

  static StructuredMessage transitionWrongPlayer() =>
      _message('transition.wrong-player');

  static StructuredMessage transitionInvalidPumpingLength() =>
      _message('transition.invalid-pumping-length');

  static StructuredMessage transitionWitnessTooShort() =>
      _message('transition.witness-too-short');

  static StructuredMessage transitionWitnessOutsideLanguage() =>
      _message('transition.witness-outside-language');

  static StructuredMessage transitionDecompositionMismatch() =>
      _message('transition.decomposition-mismatch');

  static StructuredMessage transitionDecompositionConstraint() =>
      _message('transition.decomposition-constraint');

  static StructuredMessage transitionInvalidExponent() =>
      _message('transition.invalid-exponent');
}

final class PumpingLemmaArgumentError extends ArgumentError {
  PumpingLemmaArgumentError.value(
    Object? invalidValue,
    String name,
    this.structuredMessage,
  ) : super.value(invalidValue, name, structuredMessage.stableCode);

  PumpingLemmaArgumentError.message(this.structuredMessage)
    : super(structuredMessage.stableCode);

  final StructuredMessage structuredMessage;
}

StructuredMessage _message(
  String code, {
  StructuredMessageSeverity severity = StructuredMessageSeverity.error,
  Map<String, StructuredMessageArgument> arguments = const {},
}) => StructuredMessage(
  namespace: 'pumping',
  code: code,
  category: StructuredMessageCategory.validation,
  severity: severity,
  arguments: arguments,
);
