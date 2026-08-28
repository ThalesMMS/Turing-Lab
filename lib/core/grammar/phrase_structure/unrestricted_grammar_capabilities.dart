import '../../formal_systems/formal_systems.dart';

abstract final class UnrestrictedGrammarCapabilities {
  static const systemKey = FormalSystemKey(
    type: FormalSystemTypeId('grammar'),
    variant: FormalSystemVariantId('unrestricted'),
  );

  static const schema = DocumentSchemaDescriptor(
    id: DocumentSchemaId('turing-lab.unrestricted-grammar'),
    version: DocumentSchemaVersion(1),
  );
}
