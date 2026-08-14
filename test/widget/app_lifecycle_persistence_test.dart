import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:turing_lab/data/services/active_session_persistence_service.dart';
import 'package:turing_lab/presentation/providers/active_session_provider.dart';
import 'package:turing_lab/presentation/providers/home_navigation_provider.dart';
import 'package:turing_lab/presentation/providers/unified_trace_provider.dart';
import 'package:turing_lab/presentation/widgets/active_session_lifecycle.dart';

void main() {
  testWidgets('paused lifecycle flushes a pending active session',
      (tester) async {
    SharedPreferences.setMockInitialValues(const {});
    final prefs = await SharedPreferences.getInstance();
    final service = _CountingPersistenceService(prefs);
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        activeSessionPersistenceServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: ActiveSessionLifecycle(child: SizedBox.shrink()),
        ),
      ),
    );
    await container.read(activeSessionPersistenceProvider).restoreComplete;
    container
        .read(homeNavigationProvider.notifier)
        .setIndex(HomeNavigationNotifier.regexIndex);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );

    expect(service.saveCount, 1);
    final restored = await ActiveSessionPersistenceService(prefs).loadSession();
    expect(restored?.activeWorkspaceIndex, HomeNavigationNotifier.regexIndex);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _CountingPersistenceService extends ActiveSessionPersistenceService {
  _CountingPersistenceService(super.prefs);

  var saveCount = 0;

  @override
  Future<void> saveSession(ActiveSessionSnapshot session) async {
    saveCount++;
    await super.saveSession(session);
  }
}
