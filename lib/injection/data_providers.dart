import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/formal_systems/formal_systems.dart';
import '../core/grammar/teaching/grammar_teaching_session_store.dart';
import '../core/interoperability/interoperability.dart';
import '../core/repositories/examples_repository.dart';
import '../core/repositories/settings_repository.dart';
import '../core/repositories/trace_repository.dart';
import '../core/services/file_operations_gateway.dart';
import '../data/codecs/default_document_interoperability_registry.dart';
import '../data/data_sources/examples_asset_data_source.dart';
import '../data/formal_systems/default_formal_system_registry.dart';
import '../data/repositories/settings_repository_impl.dart';
import '../data/services/active_session_module_registry.dart';
import '../data/services/active_session_persistence_service.dart';
import '../data/services/file_operations_service.dart';
import '../data/services/grammar_teaching_session_store.dart';
import '../data/services/manual_conversion_session_store.dart';
import '../data/services/trace_persistence_service.dart';

final formalSystemRegistryProvider = Provider<FormalSystemRegistry>(
  (ref) => DefaultFormalSystemRegistry.registry,
);

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw StateError(
    'sharedPreferencesProvider must be overridden at app startup.',
  );
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SharedPreferencesSettingsRepository();
});

final traceRepositoryProvider = Provider<TraceRepository>((ref) {
  return TracePersistenceService(ref.watch(sharedPreferencesProvider));
});

final activeSessionRepositoryProvider = Provider<ActiveSessionRepository>((
  ref,
) {
  return ActiveSessionPersistenceService(
    ref.watch(sharedPreferencesProvider),
    registry: ActiveSessionModuleRegistry.withBuiltInSessions(
      ref.watch(formalSystemRegistryProvider),
    ),
  );
});

final manualConversionSessionStoreProvider =
    Provider<ManualConversionSessionStore>((ref) {
  return ManualConversionSessionStore(ref.watch(sharedPreferencesProvider));
});

final grammarTeachingSessionStoreProvider =
    Provider<GrammarTeachingSessionStore>((ref) {
  return SharedPreferencesGrammarTeachingSessionStore(
    ref.watch(sharedPreferencesProvider),
  );
});

final examplesRepositoryProvider = Provider<ExamplesRepository>((ref) {
  return createExamplesRepository(
      registry: ref.watch(formalSystemRegistryProvider));
});

final fileOperationsProvider = Provider<FileOperationsGateway>((ref) {
  return createFileOperationsGateway();
});

final documentInteroperabilityRegistryProvider =
    Provider<DocumentInteroperabilityRegistry>((ref) {
  return createDocumentInteroperabilityRegistry(
    formalSystems: ref.watch(formalSystemRegistryProvider),
  );
});

ExamplesRepository createExamplesRepository({FormalSystemRegistry? registry}) =>
    ExamplesAssetDataSource(
      registry: registry ?? DefaultFormalSystemRegistry.registry,
    );

FileOperationsGateway createFileOperationsGateway() => FileOperationsService();

DocumentInteroperabilityRegistry createDocumentInteroperabilityRegistry({
  FormalSystemRegistry? formalSystems,
}) =>
    DefaultDocumentInteroperabilityRegistry.create(
      formalSystems: formalSystems ?? DefaultFormalSystemRegistry.registry,
    );
