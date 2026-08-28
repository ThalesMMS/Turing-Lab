import '../../core/formal_systems/formal_systems.dart';
import 'workspace_presentation_module.dart';

final class WorkspacePresentationRegistry {
  WorkspacePresentationRegistry(Iterable<WorkspacePresentationModule> modules)
      : modules = List<WorkspacePresentationModule>.unmodifiable(modules) {
    if (this.modules.isEmpty) {
      throw ArgumentError.value(modules, 'modules', 'Must not be empty');
    }

    final keys = <FormalSystemKey>{};
    for (final module in this.modules) {
      if (!keys.add(module.key)) {
        throw ArgumentError.value(
          module.key,
          'modules',
          'Contains a duplicate workspace key',
        );
      }
    }
  }

  final List<WorkspacePresentationModule> modules;

  WorkspacePresentationModule? moduleFor(FormalSystemKey key) {
    final index = indexOfKey(key);
    return index == null ? null : modules[index];
  }

  int? indexOfKey(FormalSystemKey key) {
    final index = modules.indexWhere((module) => module.key == key);
    return index < 0 ? null : index;
  }

  WorkspacePresentationModule moduleAt(int index) =>
      modules[_sanitizeIndex(index)];

  FormalSystemKey keyAt(int index) => moduleAt(index).key;

  int _sanitizeIndex(int index) => index.clamp(0, modules.length - 1);
}
