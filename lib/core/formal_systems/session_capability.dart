import 'document_schema.dart';
import 'formal_system_ids.dart';

abstract interface class SessionCapability<TDocument extends Object> {
  CapabilityNamespaceId get namespace;

  Map<String, Object?> encodeSession(TDocument document);

  TDocument decodeSession(
    Map<String, Object?> encoded, {
    required DocumentSchemaDescriptor schema,
  });
}
