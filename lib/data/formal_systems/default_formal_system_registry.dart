import '../../core/formal_systems/formal_systems.dart';
import '../grammar/unrestricted_grammar_module.dart';
import '../l_systems/l_system_module.dart';
import '../transducers/default_transducer_registry.dart';

/// Application registry with every implemented first-class formal system.
abstract final class DefaultFormalSystemRegistry {
  static final registry = extend(DefaultTransducerRegistry.registry);

  static FormalSystemRegistry extend(
    FormalSystemRegistry base, {
    Iterable<FormalSystemModule<Object>> additionalModules = const [],
  }) {
    final existingKeys =
        base.modules.map((module) => module.descriptor.key).toSet();
    final contributions = <FormalSystemModule<Object>>[
      createUnrestrictedGrammarModule(),
      createRegisteredLSystemModule(),
    ];
    return FormalSystemRegistry(
      modules: [
        ...base.modules,
        for (final module in contributions)
          if (existingKeys.add(module.descriptor.key)) module,
        ...additionalModules,
      ],
      formats: base.formats.formats,
    );
  }
}
