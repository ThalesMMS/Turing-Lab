import '../../core/messages/structured_message.dart';

/// Locale-neutral messages emitted by the PDA JSON codec's PDA-specific
/// validation layer.
abstract final class PdaJsonMessages {
  static const namespace = 'codec.pda-json';

  static StructuredMessage unexpectedDocumentType() =>
      _error('unexpected-document-type');

  static StructuredMessage invalidDocument() => _error('invalid-document');

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
