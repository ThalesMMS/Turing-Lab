import '../../core/formal_systems/formal_systems.dart';
import '../../core/l_systems/l_systems.dart';
import '../codecs/l_system_jflap_codec.dart';
import '../codecs/l_system_json_codec.dart';
import '../formal_systems/registered_formal_system_module.dart';
import 'l_system_examples.dart';

FormalSystemModule<Object> createRegisteredLSystemModule({
  ExampleCatalogCapability<LSystemDocument>? examples =
      const LSystemExampleCatalog(),
}) =>
    RegisteredFormalSystemModule<LSystemDocument>(
      base: LSystemFormalSystemModule(
        codecs: [
          const LSystemJflapCodec(),
          LSystemJsonCodec(),
        ],
        examples: examples,
      ),
    );
