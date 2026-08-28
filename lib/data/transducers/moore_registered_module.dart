import '../../core/formal_systems/formal_systems.dart';
import '../../core/transducers/transducers.dart';
import '../codecs/moore_document_codecs.dart';
import '../formal_systems/registered_formal_system_module.dart';
import 'moore_example_catalog.dart';

FormalSystemModule<Object> createMooreRegisteredModule({
  MooreExampleCatalog? examples,
}) =>
    RegisteredFormalSystemModule<MooreMachine>(
      base: TransducerFormalSystemModules.moore,
      codecs: MooreDocumentCodecs.all,
      examples: examples ?? MooreExampleCatalog(),
    );
