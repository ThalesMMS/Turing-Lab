import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:turing_lab/core/models/settings_model.dart';
import 'package:turing_lab/core/models/simulation_result.dart';
import 'package:turing_lab/core/models/simulation_step.dart';
import 'package:turing_lab/core/repositories/settings_repository.dart';
import 'package:turing_lab/data/services/trace_persistence_service.dart';
import 'package:turing_lab/injection/dependency_injection.dart';
import 'package:turing_lab/presentation/providers/settings_provider.dart';
import 'package:turing_lab/presentation/providers/unified_trace_provider.dart';

class _DelayedSettingsRepository implements SettingsRepository {
  _DelayedSettingsRepository(this._completer);

  final Completer<SettingsModel> _completer;

  @override
  Future<SettingsModel> loadSettings() => _completer.future;

  @override
  Future<void> saveSettings(SettingsModel settings) async {}
}

SimulationResult _trace(String input) {
  return SimulationResult.success(
    inputString: input,
    steps: <SimulationStep>[
      SimulationStep(currentState: 'q0', remainingInput: input, stepNumber: 0),
      const SimulationStep(
        currentState: 'q1',
        remainingInput: '',
        stepNumber: 1,
        isAccepted: true,
      ),
    ],
    executionTime: const Duration(milliseconds: 10),
  );
}

Future<void> _flushAsyncWork() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    await resetDependencies();
  });

  group('Cold start state', () {
    test(
      'SettingsNotifier exposes defaults before async load completes',
      () async {
        final completer = Completer<SettingsModel>();
        final notifier = SettingsNotifier(
          _DelayedSettingsRepository(completer),
        );
        addTearDown(notifier.dispose);

        expect(notifier.state, equals(const SettingsModel()));
        expect(notifier.state.themeMode, equals('light'));

        completer.complete(
          const SettingsModel(themeMode: 'dark', showGrid: false),
        );
        await _flushAsyncWork();

        expect(notifier.state.themeMode, equals('dark'));
        expect(notifier.state.showGrid, isFalse);
      },
    );

    test('SettingsNotifier can start from preloaded persisted settings', () {
      final completer = Completer<SettingsModel>();
      final notifier = SettingsNotifier(
        _DelayedSettingsRepository(completer),
        initialSettings: const SettingsModel(
          themeMode: 'dark',
          localeCode: 'pt',
        ),
      );
      addTearDown(notifier.dispose);

      expect(notifier.state.themeMode, equals('dark'));
      expect(notifier.state.localeCode, equals('pt'));
      expect(completer.isCompleted, isFalse);
    });

    test(
      'UnifiedTraceNotifier loads persisted trace history on construction',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'trace_history': jsonEncode(<Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'trace-1',
              'timestamp': DateTime(2026, 4, 22).toIso8601String(),
              'automatonType': 'dfa',
              'automatonId': 'dfa-1',
              'trace': _trace('abba').toJson(),
            },
          ]),
        });
        final prefs = await SharedPreferences.getInstance();
        final notifier = UnifiedTraceNotifier(TracePersistenceService(prefs));
        addTearDown(notifier.dispose);

        await _flushAsyncWork();

        expect(notifier.state.traceHistory, hasLength(1));
        expect(notifier.state.traceHistory.single['id'], equals('trace-1'));
      },
    );
  });
}
