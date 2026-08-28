import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formal_systems/formal_systems.dart';
import '../../injection/data_providers.dart';
import '../workspaces/default_workspace_presentation_modules.dart';
import '../workspaces/workspace_presentation_registry.dart';
import 'home_navigation_provider.dart';

export '../../injection/data_providers.dart' show formalSystemRegistryProvider;

final workspacePresentationRegistryProvider =
    Provider<WorkspacePresentationRegistry>((ref) {
  final coreRegistry = ref.watch(formalSystemRegistryProvider);
  return WorkspacePresentationRegistry(
    buildDefaultWorkspacePresentationModules(coreRegistry),
  );
});

final activeWorkspaceKeyProvider = Provider<FormalSystemKey>((ref) {
  final registry = ref.watch(workspacePresentationRegistryProvider);
  final index = ref.watch(homeNavigationProvider);
  return registry.keyAt(index);
});
