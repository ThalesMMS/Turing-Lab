import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:turing_lab/injection/dependency_injection.dart';
import 'package:turing_lab/presentation/providers/unified_trace_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    await resetDependencies();
  });

  group('Dependency injection initialization', () {
    test('returns startup SharedPreferences for Riverpod override', () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{
        'boot': 'ready',
      });
      final prefs = await SharedPreferences.getInstance();

      final initializedPrefs = await initializeSharedPreferences(
        sharedPreferencesProvider: () async => prefs,
      );
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(initializedPrefs),
        ],
      );
      addTearDown(container.dispose);

      expect(initializedPrefs, same(prefs));
      expect(container.read(sharedPreferencesProvider), same(prefs));
    });

    test('returns platform SharedPreferences without error', () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      final prefs = await initializeSharedPreferences();

      expect(prefs, isA<SharedPreferences>());
    });

    test('reports initialization stages in the expected order', () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      final observedStages = <DependencyInitializationStage>[];

      await initializeSharedPreferences(
        onStage: observedStages.add,
      );

      expect(
        observedStages,
        equals(<DependencyInitializationStage>[
          DependencyInitializationStage.sharedPreferences,
        ]),
      );
    });

    test('falls back to in-memory SharedPreferences when initialization fails',
        () async {
      final originalStore = SharedPreferencesStorePlatform.instance;

      final prefs = await initializeSharedPreferences(
        sharedPreferencesProvider: () async {
          throw Exception('preferences unavailable');
        },
      );

      expect(prefs, isA<SharedPreferences>());

      await resetDependencies();

      expect(
        SharedPreferencesStorePlatform.instance,
        same(originalStore),
      );
    });
  });
}
