import '../messages/structured_message.dart';

/// Locale-neutral diagnostics emitted while an FSA needs determinization.
abstract final class FsaDeterminizerMessages {
  static StructuredMessage failed(String automaton) => StructuredMessage(
    namespace: 'algorithm.fsa-determinizer',
    code: 'failed',
    category: StructuredMessageCategory.conversion,
    severity: StructuredMessageSeverity.error,
    arguments: {
      'automaton': StructuredMessageArgument.literal(
        automaton,
        role: 'automaton-label',
      ),
    },
  );
}
