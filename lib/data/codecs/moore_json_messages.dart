import '../../core/messages/structured_message.dart';

/// Locale-neutral messages emitted by the Moore Turing Lab JSON codec.
abstract final class MooreJsonMessages {
  static const namespace = 'codec.moore-json';

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
