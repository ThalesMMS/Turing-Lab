import '../../core/formal_systems/formal_systems.dart';
import '../../core/transducers/transducers.dart';
import '../codecs/mealy_jflap_codec.dart';
import '../codecs/mealy_json_document_codec.dart';
import '../formal_systems/registered_formal_system_module.dart';
import 'mealy_example_catalog.dart';
import 'moore_registered_module.dart';

/// Adds operational transducer modules without changing the core registry.
abstract final class DefaultTransducerRegistry {
  static final registry = withBuiltInTransducers(
    FormalSystemRegistry.defaultRegistry,
  );

  static FormalSystemRegistry withBuiltInTransducers(
    FormalSystemRegistry base, {
    Iterable<FormalSystemModule<Object>> additionalModules = const [],
  }) {
    final contributions = <FormalSystemModule<Object>>[
      mealyModule,
      createMooreRegisteredModule(),
    ];
    final existingKeys =
        base.modules.map((module) => module.descriptor.key).toSet();
    return FormalSystemRegistry(
      modules: [
        ...base.modules,
        for (final module in contributions)
          if (existingKeys.add(module.descriptor.key)) module,
        // Caller contributions remain visible to release-mode validation.
        ...additionalModules,
      ],
      formats: base.formats.formats,
    );
  }

  static final FormalSystemModule<Object> mealyModule =
      RegisteredFormalSystemModule<MealyMachine>(
    base: TransducerFormalSystemModules.mealy,
    codecs: [
      const MealyJflapDocumentCodec(),
      MealyJsonDocumentCodec(),
    ],
    examples: MealyExampleCatalog(),
  );
}
