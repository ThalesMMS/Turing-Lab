import '../../core/messages/structured_message.dart';

/// Locale-neutral messages emitted by the Mealy Turing Lab JSON codec.
abstract final class MealyJsonMessages {
  static const namespace = 'codec.mealy-json';

  static StructuredMessage unexpectedDocumentType() =>
      _error('unexpected-document-type');

  static StructuredMessage invalidDocument(String diagnostic) => _error(
    'invalid-document',
    arguments: {
      'diagnostic': StructuredMessageArgument.outcome(
        diagnostic,
        role: 'validation-code',
      ),
    },
  );

  static StructuredMessage _error(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => StructuredMessage(
    namespace: namespace,
    code: code,
    category: StructuredMessageCategory.interoperability,
    severity: StructuredMessageSeverity.error,
    arguments: arguments,
  );
}
