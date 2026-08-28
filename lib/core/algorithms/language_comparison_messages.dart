import '../messages/structured_message.dart';

/// Locale-neutral validation diagnostics emitted by language comparison.
///
/// The comparison engine keeps the automaton side as a typed argument so the
/// presentation layer can translate the surrounding explanation without
/// translating the formal side marker (A or B).
abstract final class LanguageComparisonMessages {
  static StructuredMessage emptyStateSet(String automatonSide) => _message(
    'empty-state-set',
    arguments: {
      'automaton': StructuredMessageArgument.identifier(
        automatonSide,
        role: 'automaton-side',
      ),
    },
  );

  static StructuredMessage missingInitialState(String automatonSide) =>
      _message(
        'missing-initial-state',
        arguments: {
          'automaton': StructuredMessageArgument.identifier(
            automatonSide,
            role: 'automaton-side',
          ),
        },
      );

  static StructuredMessage initialStateOutsideSet(String automatonSide) =>
      _message(
        'initial-state-outside-set',
        arguments: {
          'automaton': StructuredMessageArgument.identifier(
            automatonSide,
            role: 'automaton-side',
          ),
        },
      );

  static StructuredMessage internalFailure() => _message(
    'internal-failure',
    category: StructuredMessageCategory.analysis,
  );

  static StructuredMessage _message(
    String code, {
    StructuredMessageCategory category = StructuredMessageCategory.validation,
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => StructuredMessage(
    namespace: 'language.comparison',
    code: code,
    category: category,
    severity: StructuredMessageSeverity.error,
    arguments: arguments,
  );
}
