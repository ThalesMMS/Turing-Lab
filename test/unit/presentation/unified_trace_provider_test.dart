import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:turing_lab/core/models/simulation_result.dart';
import 'package:turing_lab/core/models/simulation_step.dart';
import 'package:turing_lab/core/repositories/trace_repository.dart';
import 'package:turing_lab/data/services/trace_persistence_service.dart';
import 'package:turing_lab/presentation/providers/unified_trace_provider.dart';

SimulationResult _trace({String input = 'abba'}) {
  return SimulationResult.success(
    inputString: input,
    steps: const <SimulationStep>[
      SimulationStep(currentState: 'q0', remainingInput: 'abba', stepNumber: 0),
      SimulationStep(currentState: 'q1', remainingInput: 'bba', stepNumber: 1),
      SimulationStep(
        currentState: 'q2',
        remainingInput: '',
        stepNumber: 2,
        isAccepted: true,
      ),
    ],
    executionTime: const Duration(milliseconds: 8),
  );
}

Future<void> _flushAsyncWork() async {
  await pumpEventQueue(times: 10);
}

Future<void> _waitUntil(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out waiting for asynchronous notifier work');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

class _DeferredTraceRepository implements TraceRepository {
  final history = Completer<List<Map<String, dynamic>>>();

  @override
  Future<void> clearAllTraces() async {}

  @override
  Future<void> clearCurrentTrace() async {}

  @override
  Future<String> exportTraceHistory() async => '[]';

  @override
  Future<Map<String, dynamic>?> getCurrentTrace() async => null;

  @override
  Future<List<Map<String, dynamic>>> getTraceHistory() => history.future;

  @override
  Future<Map<String, dynamic>?> getTraceById(String traceId) async => null;

  @override
  Future<Map<String, dynamic>> getTraceStatistics() async => const {};

  @override
  Future<void> importTraceHistory(String jsonData) async {}

  @override
  Future<void> saveCurrentTrace(
    SimulationResult trace,
    int currentStepIndex,
  ) async {}

  @override
  Future<void> saveTraceToHistory(
    SimulationResult trace, {
    String? automatonType,
    String? automatonId,
  }) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Trace persistence providers', () {
    test('requires a startup SharedPreferences override', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        () => container.read(sharedPreferencesProvider),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('must be overridden'),
          ),
        ),
      );
    });

    test('build service from Riverpod SharedPreferences override', () async {
      SharedPreferences.setMockInitialValues(const {});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(dataTracePersistenceServiceProvider);
      await service.saveTraceToHistory(_trace(input: 'riverpod'));

      final restartedService = TracePersistenceService(prefs);
      final history = await restartedService.getTraceHistory();
      expect(history, hasLength(1));
      expect(
        (history.single['trace'] as Map<String, dynamic>)['inputString'],
        equals('riverpod'),
      );
    });
  });

  group('UnifiedTraceNotifier restoration', () {
    late SharedPreferences prefs;
    late TracePersistenceService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues(const {});
      prefs = await SharedPreferences.getInstance();
      service = TracePersistenceService(prefs);
    });

    test('ignores constructor loads that finish after disposal', () async {
      final repository = _DeferredTraceRepository();
      final asyncErrors = <Object>[];

      await runZonedGuarded(
        () async {
          final notifier = UnifiedTraceNotifier(repository);
          notifier.dispose();
          repository.history.complete(const []);
          await _flushAsyncWork();
        },
        (error, stackTrace) => asyncErrors.add(error),
      );

      expect(asyncErrors, isEmpty);
    });

    test('restores persisted current trace and step index on startup',
        () async {
      final trace = _trace();
      await service.saveCurrentTrace(trace, 2);

      final notifier = UnifiedTraceNotifier(service);
      addTearDown(notifier.dispose);

      await _waitUntil(
        () =>
            notifier.state.currentTrace != null &&
            notifier.state.traceStatistics.containsKey('totalTraces'),
      );

      expect(notifier.state.currentTrace, isNotNull);
      expect(
          notifier.state.currentTrace!.inputString, equals(trace.inputString));
      expect(notifier.state.currentTrace!.stepCount, equals(trace.stepCount));
      expect(notifier.state.currentStepIndex, equals(2));
      expect(notifier.state.traceStatistics['totalTraces'], equals(0));
    });

    test('setTrace persists current trace immediately for relaunch recovery',
        () async {
      final trace = _trace(input: 'aa');
      final notifier = UnifiedTraceNotifier(service);
      addTearDown(notifier.dispose);

      await notifier.setTrace(trace);
      await _waitUntil(() => notifier.state.traceHistory.length == 1);

      final restored = await service.getCurrentTrace();
      expect(restored, isNotNull);
      expect(restored!['currentStepIndex'], equals(0));
      expect(
        (restored['trace'] as Map<String, dynamic>)['inputString'],
        equals('aa'),
      );
      expect(notifier.state.traceHistory, hasLength(1));
    });

    test('snapshot getters return immutable copies', () async {
      final trace = _trace(input: 'immutability');
      await service.saveTraceToHistory(
        trace,
        automatonType: 'dfa',
        automatonId: 'dfa-1',
      );

      final notifier = UnifiedTraceNotifier(service);
      addTearDown(notifier.dispose);

      notifier.setAutomatonContext(automatonType: 'dfa', automatonId: 'dfa-1');
      await _waitUntil(
        () =>
            notifier.state.tracesForCurrentAutomaton.isNotEmpty &&
            notifier.state.traceStatistics.containsKey('typeCounts'),
      );

      final statistics = notifier.traceStatisticsSnapshot;
      final automatonTraces = notifier.currentAutomatonTracesSnapshot;
      final typeTraces = notifier.currentTypeTracesSnapshot;

      expect(() => statistics['totalTraces'] = 99, throwsUnsupportedError);
      expect(
        () => (statistics['typeCounts'] as Map<String, dynamic>)['dfa'] = 99,
        throwsUnsupportedError,
      );
      expect(
        () => automatonTraces.add(<String, dynamic>{}),
        throwsUnsupportedError,
      );
      expect(
        () => (automatonTraces.single['trace']
            as Map<String, dynamic>)['inputString'] = 'mutated',
        throwsUnsupportedError,
      );
      expect(() => typeTraces.clear(), throwsUnsupportedError);
    });

    test('clears malformed persisted current traces instead of crashing',
        () async {
      await prefs.setString('current_trace', '{"trace":"broken"}');

      final notifier = UnifiedTraceNotifier(service);
      addTearDown(notifier.dispose);

      await _flushAsyncWork();

      expect(notifier.state.currentTrace, isNull);
      expect(await service.getCurrentTrace(), isNull);
    });

    test('restores legacy current trace without metadata fields', () async {
      await prefs.setString(
        'current_simulation_trace',
        jsonEncode(_trace(input: 'legacy-current').toJson()),
      );

      final notifier = UnifiedTraceNotifier(service);
      addTearDown(notifier.dispose);

      await _waitUntil(() => notifier.state.currentTrace != null);

      expect(notifier.state.currentTrace, isNotNull);
      expect(
          notifier.state.currentTrace!.inputString, equals('legacy-current'));
      expect(notifier.state.currentStepIndex, equals(0));

      final migrated = await service.getCurrentTrace();
      expect(migrated, isNotNull);
      expect(migrated!.containsKey('id'), isFalse);
      expect(migrated.containsKey('automatonType'), isFalse);
      expect(migrated.containsKey('automatonId'), isFalse);
    });
  });

  group('UnifiedTraceState copyWith', () {
    test('can clear nullable trace fields', () {
      final state = UnifiedTraceState(
        currentTrace: _trace(input: 'old'),
        currentStepIndex: 2,
        automatonType: 'pda',
        automatonId: 'pda-1',
        errorMessage: 'failed',
      );

      final cleared = state.copyWith(
        currentTrace: null,
        currentStepIndex: 0,
        automatonType: null,
        automatonId: null,
        errorMessage: null,
      );

      expect(cleared.currentTrace, isNull);
      expect(cleared.currentStepIndex, equals(0));
      expect(cleared.automatonType, isNull);
      expect(cleared.automatonId, isNull);
      expect(cleared.errorMessage, isNull);
    });
  });
}
