import '../formal_systems/formal_system_ids.dart';

abstract interface class DocumentMigrationStep<TPayload extends Object> {
  DocumentSchemaVersion get fromVersion;

  DocumentSchemaVersion get toVersion;

  TPayload migrate(TPayload payload);
}

typedef DocumentMigrationCallback<TPayload extends Object> = TPayload Function(
  TPayload payload,
);

final class CallbackDocumentMigrationStep<TPayload extends Object>
    implements DocumentMigrationStep<TPayload> {
  CallbackDocumentMigrationStep({
    required this.fromVersion,
    required this.toVersion,
    required DocumentMigrationCallback<TPayload> migrate,
  }) : _migrate = migrate {
    if (toVersion.value <= fromVersion.value) {
      throw ArgumentError('A migration must advance the schema version.');
    }
  }

  @override
  final DocumentSchemaVersion fromVersion;

  @override
  final DocumentSchemaVersion toVersion;

  final DocumentMigrationCallback<TPayload> _migrate;

  @override
  TPayload migrate(TPayload payload) => _migrate(payload);
}
