//
//  dependency_injection.dart
//  Turing Lab
//
//  Initializes SharedPreferences for Riverpod providers that depend on
//  asynchronous platform state during startup.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

part 'dependency_initialization_typedefs.dart';
part 'dependency_initialization_stage.dart';

SharedPreferencesStorePlatform? _originalSharedPreferencesStorePlatform;
bool _sharedPreferencesFallbackApplied = false;

/// Initializes startup dependencies for the application.
Future<SharedPreferences> initializeSharedPreferences({
  SharedPreferencesProvider? sharedPreferencesProvider,
  DependencyInitializationObserver? onStage,
  DependencyInitializationLogger? logger,
}) async {
  final log = logger ?? debugPrint;

  // Initialize SharedPreferences for trace persistence
  onStage?.call(DependencyInitializationStage.sharedPreferences);
  final prefs = await _initializeSharedPreferences(
    provider: sharedPreferencesProvider,
    logger: log,
  );

  return prefs;
}

/// Resets all dependencies (useful for testing)
Future<void> resetDependencies() async {
  if (_originalSharedPreferencesStorePlatform != null) {
    SharedPreferencesStorePlatform.instance =
        _originalSharedPreferencesStorePlatform!;
  }
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.resetStatic();
  _originalSharedPreferencesStorePlatform = null;
  _sharedPreferencesFallbackApplied = false;
}

Future<SharedPreferences> _initializeSharedPreferences({
  SharedPreferencesProvider? provider,
  required DependencyInitializationLogger logger,
}) async {
  final resolver = provider ?? SharedPreferences.getInstance;

  try {
    final prefs = await resolver();
    return prefs;
  } catch (error, stackTrace) {
    logger(
      '[DI] SharedPreferences initialization failed. Falling back to in-memory preferences. Error: $error',
    );
    debugPrintStack(stackTrace: stackTrace);

    try {
      if (!_sharedPreferencesFallbackApplied) {
        _originalSharedPreferencesStorePlatform =
            SharedPreferencesStorePlatform.instance;
        _sharedPreferencesFallbackApplied = true;
      }
      SharedPreferencesStorePlatform.instance =
          InMemorySharedPreferencesStore.empty();
      final fallbackPrefs = await SharedPreferences.getInstance();
      return fallbackPrefs;
    } catch (fallbackError, fallbackStackTrace) {
      if (_originalSharedPreferencesStorePlatform != null) {
        SharedPreferencesStorePlatform.instance =
            _originalSharedPreferencesStorePlatform!;
      }
      _originalSharedPreferencesStorePlatform = null;
      _sharedPreferencesFallbackApplied = false;
      logger(
        '[DI] SharedPreferences fallback initialization failed: $fallbackError',
      );
      debugPrintStack(stackTrace: fallbackStackTrace);
      rethrow;
    }
  }
}
