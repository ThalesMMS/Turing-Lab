import 'formal_system_ids.dart';

final class DocumentSchemaDescriptor {
  const DocumentSchemaDescriptor({required this.id, required this.version});

  final DocumentSchemaId id;
  final DocumentSchemaVersion version;
}
