import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:turing_lab/core/models/simulation_result.dart';
import 'package:turing_lab/core/models/simulation_step.dart';
import 'package:turing_lab/core/models/step_explanation.dart';
import 'package:turing_lab/data/services/trace_persistence_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  SimulationResult traceFixture({
    required String input,
    bool accepted = true,
  }) {
    return accepted
        ? SimulationResult.success(
            inputString: input,
            steps: <SimulationStep>[
              SimulationStep(
                currentState: 'q0',
                activeStateIds: const {
                  'persistent-state-id-1',
                  ' persistent-state-id-2 ',
                },
                remainingInput: input,
                stepNumber: 0,
                explanation: const StepExplanation(
                  highlights: [
                    HighlightTarget(
                      type: HighlightTargetType.transition,
                      id: 'persistent-edge-id',
                    ),
                  ],
                ),
              ),
              const SimulationStep(
                currentState: 'q1',
                remainingInput: '',
                stepNumber: 1,
                isAccepted: true,
              ),
            ],
            executionTime: const Duration(milliseconds: 12),
          )
        : SimulationResult.failure(
            inputString: input,
            steps: <SimulationStep>[
              SimulationStep(
                currentState: 'q0',
                remainingInput: input,
                stepNumber: 0,
              ),
            ],
            errorMessage: 'rejected',
            executionTime: const Duration(milliseconds: 12),
          );
  }

  group('Trace persistence', () {
    late SharedPreferences prefs;
    late TracePersistenceService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues(const {});
      prefs = await SharedPreferences.getInstance();
      service = TracePersistenceService(prefs);
    });

    test('saveTraceToHistory and getTraceHistory round-trip', () async {
      final trace = traceFixture(input: 'abba');

      await service.saveTraceToHistory(
        trace,
        automatonType: 'dfa',
        automatonId: 'automaton-1',
      );

      final history = await service.getTraceHistory();

      expect(history, hasLength(1));
      expect(history.single['automatonType'], equals('dfa'));
      expect(history.single['automatonId'], equals('automaton-1'));
      expect(
        (history.single['trace'] as Map<String, dynamic>)['inputString'],
        equals('abba'),
      );
    });

    test('round-trips active state and transition targets unchanged', () async {
      await service.saveTraceToHistory(
        traceFixture(input: 'abba'),
        automatonType: 'dfa',
      );

      final history = await service.getTraceHistory();
      final restored = SimulationResult.fromJson(
        Map<String, dynamic>.from(history.single['trace'] as Map),
      );

      expect(
        restored.steps.first.explanation!.highlights.single,
        equals(
          const HighlightTarget(
            type: HighlightTargetType.transition,
            id: 'persistent-edge-id',
          ),
        ),
      );
      expect(
        restored.steps.first.activeStateIds,
        {'persistent-state-id-1', ' persistent-state-id-2 '},
      );
    });

    test('concurrent saves preserve all traces with unique ids', () async {
      final inputs = List<String>.generate(12, (index) => 'input-$index');

      await Future.wait(
        inputs.map(
          (input) => service.saveTraceToHistory(
            traceFixture(input: input),
            automatonType: 'dfa',
          ),
        ),
      );

      final history = await service.getTraceHistory();
      final ids = history.map((entry) => entry['id'] as String).toList();
      final savedInputs = history
          .map((entry) =>
              (entry['trace'] as Map<String, dynamic>)['inputString'])
          .toSet();

      expect(history, hasLength(inputs.length));
      expect(ids.toSet(), hasLength(ids.length));
      expect(savedInputs, containsAll(inputs));
    });

    test('concurrent deletes preserve every requested deletion', () async {
      final trace = traceFixture(input: 'existing');
      await prefs.setString(
        'trace_history',
        jsonEncode(<Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'trace-0',
            'timestamp': DateTime(2026, 4, 22).toIso8601String(),
            'automatonType': 'dfa',
            'trace': trace.toJson(),
          },
          <String, dynamic>{
            'id': 'trace-1',
            'timestamp': DateTime(2026, 4, 22).toIso8601String(),
            'automatonType': 'dfa',
            'trace': trace.toJson(),
          },
          <String, dynamic>{
            'id': 'trace-2',
            'timestamp': DateTime(2026, 4, 22).toIso8601String(),
            'automatonType': 'dfa',
            'trace': trace.toJson(),
          },
        ]),
      );

      await Future.wait([
        service.deleteTrace('trace-0'),
        service.deleteTrace('trace-1'),
      ]);

      final history = await service.getTraceHistory();
      final ids = history.map((entry) => entry['id']).toSet();

      expect(ids, equals({'trace-2'}));
    });

    test('evicts the oldest trace when the 51st trace is saved', () async {
      for (var i = 0; i < 51; i++) {
        await service.saveTraceToHistory(
          traceFixture(input: 'input-$i'),
          automatonType: 'dfa',
        );
      }

      final history = await service.getTraceHistory();
      final inputs = history
          .map((entry) =>
              (entry['trace'] as Map<String, dynamic>)['inputString'])
          .toList();

      expect(history, hasLength(50));
      expect(inputs, isNot(contains('input-0')));
      expect(inputs.first, equals('input-50'));
      expect(inputs.last, equals('input-1'));
    });

    test('persists current_trace and step position across a simulated restart',
        () async {
      await service.saveCurrentTrace(traceFixture(input: 'restart'), 1);

      final restartedService = TracePersistenceService(prefs);
      final restored = await restartedService.getCurrentTrace();

      expect(restored, isNotNull);
      expect(restored!['currentStepIndex'], equals(1));
      expect(
        (restored['trace'] as Map<String, dynamic>)['inputString'],
        equals('restart'),
      );
    });

    test('serializes current trace save and clear operations', () async {
      final save = service.saveCurrentTrace(
        traceFixture(input: 'pending-current'),
        1,
      );
      final clear = service.clearCurrentTrace();

      await Future.wait([save, clear]);

      expect(await service.getCurrentTrace(), isNull);
    });

    test('loads legacy core trace history when unified history is absent',
        () async {
      final trace = traceFixture(input: 'legacy');
      await prefs.setString(
        'simulation_trace_history',
        jsonEncode(<Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'legacy-trace',
            'timestamp': DateTime(2026, 4, 22).toIso8601String(),
            'inputString': 'legacy',
            'accepted': true,
            'stepCount': trace.stepCount,
            'trace': trace.toJson(),
          },
        ]),
      );

      final history = await service.getTraceHistory();

      expect(history, hasLength(1));
      expect(history.single['id'], equals('legacy-trace'));
      expect(history.single['automatonType'], equals('unknown'));
      expect(
        (history.single['trace'] as Map<String, dynamic>)['inputString'],
        equals('legacy'),
      );
    });

    test('loads legacy current trace when unified current trace is absent',
        () async {
      await prefs.setString(
        'current_simulation_trace',
        jsonEncode(traceFixture(input: 'legacy-current').toJson()),
      );

      final currentTrace = await service.getCurrentTrace();

      expect(currentTrace, isNotNull);
      expect(currentTrace!['currentStepIndex'], equals(0));
      expect(currentTrace['timestamp'], isA<String>());
      expect(currentTrace.containsKey('id'), isFalse);
      expect(currentTrace.containsKey('automatonType'), isFalse);
      expect(currentTrace.containsKey('automatonId'), isFalse);
      expect(
        (currentTrace['trace'] as Map<String, dynamic>)['inputString'],
        equals('legacy-current'),
      );
    });

    test('stores and retrieves trace metadata', () async {
      await service.saveTraceMetadata(
        traceId: 'trace-1',
        automatonType: 'tm',
        automatonId: 'tm-1',
        inputString: '101',
        accepted: true,
        stepCount: 7,
        executionTime: const Duration(milliseconds: 25),
      );

      final metadata = await service.getTraceMetadata();

      expect(metadata.keys, contains('trace-1'));
      expect(metadata['trace-1']!['automatonType'], equals('tm'));
      expect(metadata['trace-1']!['automatonId'], equals('tm-1'));
      expect(metadata['trace-1']!['stepCount'], equals(7));
      expect(metadata['trace-1']!['executionTime'], equals(25));
    });

    test('concurrent metadata writes preserve every trace entry', () async {
      final traceIds = List<String>.generate(12, (index) => 'trace-$index');

      await Future.wait(
        traceIds.map(
          (traceId) => service.saveTraceMetadata(
            traceId: traceId,
            automatonType: 'dfa',
          ),
        ),
      );

      final metadata = await service.getTraceMetadata();
      expect(metadata.keys, containsAll(traceIds));
      expect(metadata, hasLength(traceIds.length));
    });

    test('clear queued after a save leaves trace history empty', () async {
      final save = service.saveTraceToHistory(
        traceFixture(input: 'pending-save'),
        automatonType: 'dfa',
      );
      final clear = service.clearAllTraces();

      await Future.wait([save, clear]);

      expect(await service.getTraceHistory(), isEmpty);
    });

    test('import queued after a save replaces the saved history', () async {
      final importedTrace = <String, dynamic>{
        'id': 'imported-trace',
        'timestamp': DateTime(2026, 4, 22).toIso8601String(),
        'automatonType': 'pda',
        'trace': traceFixture(input: 'imported').toJson(),
      };
      final importPayload = jsonEncode(<String, dynamic>{
        'traces': [importedTrace],
        'metadata': <String, dynamic>{},
      });

      final save = service.saveTraceToHistory(
        traceFixture(input: 'pending-save'),
        automatonType: 'dfa',
      );
      final import = service.importTraceHistory(importPayload);

      await Future.wait([save, import]);

      final history = await service.getTraceHistory();
      expect(history, hasLength(1));
      expect(history.single['id'], 'imported-trace');
    });

    test('import clamps trace history to the configured maximum', () async {
      final traces = List<Map<String, dynamic>>.generate(
        75,
        (index) => <String, dynamic>{
          'id': 'imported-$index',
          'timestamp': DateTime(2026, 4, 22).toIso8601String(),
          'automatonType': 'dfa',
          'trace': traceFixture(input: 'input-$index').toJson(),
        },
      );

      await service.importTraceHistory(
        jsonEncode(<String, dynamic>{
          'traces': traces,
          'metadata': <String, dynamic>{},
        }),
      );

      final history = await service.getTraceHistory();
      expect(history, hasLength(50));
      expect(history.first['id'], 'imported-0');
      expect(history.last['id'], 'imported-49');
    });

    test('gets a trace by id without a sentinel value', () async {
      await service.saveTraceToHistory(
        traceFixture(input: 'lookup'),
        automatonType: 'tm',
      );
      final history = await service.getTraceHistory();
      final traceId = history.single['id'] as String;

      expect(await service.getTraceById(traceId), history.single);
      expect(await service.getTraceById('missing'), isNull);
    });

    test('invalidates the in-memory history cache on external writes',
        () async {
      await service.saveTraceToHistory(
        traceFixture(input: 'cached'),
        automatonType: 'dfa',
      );
      expect(await service.getTraceHistory(), hasLength(1));

      await prefs.setString(
        'trace_history',
        jsonEncode(<Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'external-trace',
            'timestamp': DateTime(2026, 4, 22).toIso8601String(),
            'automatonType': 'pda',
            'trace': traceFixture(input: 'external').toJson(),
          },
        ]),
      );

      final refreshed = await service.getTraceHistory();
      expect(refreshed.single['id'], 'external-trace');
    });

    test('returns an empty history for malformed trace_history JSON', () async {
      await prefs.setString('trace_history', '{"not":"a-list"}');

      final history = await service.getTraceHistory();

      expect(history, isEmpty);
    });

    test('skips history entries whose nested trace payload is not a map',
        () async {
      await prefs.setString(
        'trace_history',
        jsonEncode(<Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'valid-trace',
            'timestamp': DateTime(2026, 4, 22).toIso8601String(),
            'automatonType': 'dfa',
            'trace': traceFixture(input: 'abba').toJson(),
          },
          <String, dynamic>{
            'id': 'invalid-trace',
            'timestamp': DateTime(2026, 4, 22).toIso8601String(),
            'automatonType': 'dfa',
            'trace': 'not-a-map',
          },
        ]),
      );

      final history = await service.getTraceHistory();
      final statistics = await service.getTraceStatistics();

      expect(history, hasLength(1));
      expect(history.single['id'], equals('valid-trace'));
      expect(statistics['totalTraces'], equals(1));
    });

    test('normalizes malformed automaton types to unknown in statistics',
        () async {
      await prefs.setString(
        'trace_history',
        jsonEncode(<Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'trace-1',
            'timestamp': DateTime(2026, 4, 22).toIso8601String(),
            'automatonType': 42,
            'trace': traceFixture(input: 'abba').toJson(),
          },
        ]),
      );

      final history = await service.getTraceHistory();
      final statistics = await service.getTraceStatistics();

      expect(history.single['automatonType'], equals('unknown'));
      expect(
        statistics['typeCounts'],
        equals(<String, int>{'unknown': 1}),
      );
    });

    test('returns null for corrupted current_trace data', () async {
      await prefs.setString('current_trace', '["broken"]');

      final currentTrace = await service.getCurrentTrace();

      expect(currentTrace, isNull);
    });

    test('returns null for object-shaped current_trace with invalid trace',
        () async {
      await prefs.setString(
        'current_trace',
        '{"trace":"broken","currentStepIndex":0}',
      );

      final currentTrace = await service.getCurrentTrace();

      expect(currentTrace, isNull);
    });

    test('tolerates metadata that references non-existent traces', () async {
      await prefs.setString(
        'trace_metadata',
        jsonEncode(<String, Object>{
          'orphan-trace': <String, Object>{
            'traceId': 'orphan-trace',
            'automatonType': 'pda',
          },
        }),
      );

      final metadata = await service.getTraceMetadata();
      final trace = await service.getTraceById('orphan-trace');

      expect(metadata.keys, contains('orphan-trace'));
      expect(metadata['orphan-trace']!['automatonType'], equals('pda'));
      expect(trace, isNull);
    });

    test('does not throw when malformed persistence payloads are read',
        () async {
      await prefs.setString('trace_history', 'not-json');
      await prefs.setString('current_trace', 'not-json');

      await expectLater(service.getTraceHistory(), completion(isEmpty));
      await expectLater(service.getCurrentTrace(), completion(isNull));
    });
  });
}
