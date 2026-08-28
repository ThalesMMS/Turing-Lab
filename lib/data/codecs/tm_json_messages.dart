import '../../core/messages/structured_message.dart';

/// Locale-neutral messages emitted by the TM JSON codec's TM-specific
/// validation and migration layer.
abstract final class TmJsonMessages {
  static const namespace = 'codec.tm-json';

  static StructuredMessage unexpectedDocumentType() =>
      _error('unexpected-document-type');

  static StructuredMessage invalidDocument() => _error('invalid-document');

  static StructuredMessage variantMismatch() => _error('variant-mismatch');

  static StructuredMessage variantInferred() =>
      _information('variant-inferred');

  static StructuredMessage operationVectorsMigrated() =>
      _information('operation-vectors-migrated');

  static StructuredMessage endpointsMigratedToIds() =>
      _information('endpoints-migrated-to-ids');

  static StructuredMessage _error(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(
    code,
    severity: StructuredMessageSeverity.error,
    arguments: arguments,
  );

  static StructuredMessage _information(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(
    code,
    severity: StructuredMessageSeverity.information,
    arguments: arguments,
  );

  static StructuredMessage _message(
    String code, {
    required StructuredMessageSeverity severity,
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => StructuredMessage(
    namespace: namespace,
    code: code,
    category: StructuredMessageCategory.interoperability,
    severity: severity,
    arguments: arguments,
  );
}
