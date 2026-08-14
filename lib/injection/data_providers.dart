import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/repositories/examples_repository.dart';
import '../core/repositories/settings_repository.dart';
import '../core/repositories/trace_repository.dart';
import '../core/services/file_operations_gateway.dart';
import '../data/data_sources/examples_asset_data_source.dart';
import '../data/repositories/settings_repository_impl.dart';
import '../data/services/active_session_persistence_service.dart';
import '../data/services/file_operations_service.dart';
import '../data/services/trace_persistence_service.dart';

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
  );
});

final examplesRepositoryProvider = Provider<ExamplesRepository>((ref) {
  return createExamplesRepository();
});

final fileOperationsProvider = Provider<FileOperationsGateway>((ref) {
  return createFileOperationsGateway();
});

ExamplesRepository createExamplesRepository() => ExamplesAssetDataSource();

FileOperationsGateway createFileOperationsGateway() => FileOperationsService();
