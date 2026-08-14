import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/core/result.dart';
import 'package:turing_lab/data/services/file_operations_service.dart';
import 'package:turing_lab/presentation/widgets/utils/platform_file_loader.dart';

void main() {
  group('loadAutomatonFromPlatformFile', () {
    late _RecordingFileOperationsService service;
    late FSA fsa;

    setUp(() {
      final state = automaton_state.State(
        id: 'q0',
        label: 'q0',
        position: Vector2.zero(),
        isInitial: true,
        isAccepting: false,
      );
      fsa = FSA(
        id: 'a1',
        name: 'Automaton',
        states: {state},
        transitions: <FSATransition>{},
        alphabet: <String>{},
        initialState: state,
        acceptingStates: <automaton_state.State>{},
        created: DateTime(2023),
        modified: DateTime(2023),
        bounds: const math.Rectangle(0, 0, 100, 100),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
      );

      service = _RecordingFileOperationsService(automaton: fsa);
    });

    test('prefers bytes when available', () async {
      final file = PlatformFile(
        name: 'automaton.jff',
        size: 4,
        bytes: Uint8List.fromList([1, 2, 3, 4]),
      );

      final result = await loadAutomatonFromPlatformFile(service, file);

      expect(result, isA<Success<FSA>>());
      expect(service.bytesCalls, 1);
      expect(service.pathCalls, 0);
    });

    test('falls back to path when bytes are missing', () async {
      final file = PlatformFile(
        name: 'automaton.jff',
        size: 0,
        path: '/tmp/automaton.jff',
      );

      final result = await loadAutomatonFromPlatformFile(service, file);

      expect(result, isA<Success<FSA>>());
      expect(service.bytesCalls, 0);
      expect(service.pathCalls, 1);
    });

    test('returns failure when neither bytes nor path are provided', () async {
      final file = PlatformFile(name: 'automaton.jff', size: 0);

      final result = await loadAutomatonFromPlatformFile(service, file);

      expect(result, isA<Failure<FSA>>());
      expect(
        result.error,
        contains('could not access the selected file data'),
      );
      expect(service.bytesCalls, 0);
      expect(service.pathCalls, 0);
    });
  });

  group('loadGrammarFromPlatformFile', () {
    late _RecordingFileOperationsService service;
    late Grammar grammar;

    setUp(() {
      grammar = Grammar(
        id: 'g1',
        name: 'Grammar',
        terminals: {'a'},
        nonterminals: {'S'},
        startSymbol: 'S',
        productions: {
          const Production(
            id: 'p0',
            leftSide: ['S'],
            rightSide: ['a'],
            order: 0,
          ),
        },
        type: GrammarType.contextFree,
        created: DateTime(2023),
        modified: DateTime(2023),
      );

      service = _RecordingFileOperationsService(grammar: grammar);
    });

    test('prefers bytes when available', () async {
      final file = PlatformFile(
        name: 'grammar.cfg',
        size: 2,
        bytes: Uint8List.fromList([1, 2]),
      );

      final result = await loadGrammarFromPlatformFile(service, file);

      expect(result, isA<Success<Grammar>>());
      expect(service.grammarBytesCalls, 1);
      expect(service.grammarPathCalls, 0);
    });

    test('falls back to path when bytes are missing', () async {
      final file = PlatformFile(
        name: 'grammar.cfg',
        size: 0,
        path: '/tmp/grammar.cfg',
      );

      final result = await loadGrammarFromPlatformFile(service, file);

      expect(result, isA<Success<Grammar>>());
      expect(service.grammarBytesCalls, 0);
      expect(service.grammarPathCalls, 1);
    });

    test('returns failure when neither bytes nor path are provided', () async {
      final file = PlatformFile(name: 'grammar.cfg', size: 0);

      final result = await loadGrammarFromPlatformFile(service, file);

      expect(result, isA<Failure<Grammar>>());
      expect(
        result.error,
        contains('could not access the selected file data'),
      );
      expect(service.grammarBytesCalls, 0);
      expect(service.grammarPathCalls, 0);
    });
  });
}

class _RecordingFileOperationsService extends FileOperationsService {
  _RecordingFileOperationsService({FSA? automaton, Grammar? grammar})
      : _automaton = automaton,
        _grammar = grammar;

  final FSA? _automaton;
  final Grammar? _grammar;

  int bytesCalls = 0;
  int pathCalls = 0;
  int grammarBytesCalls = 0;
  int grammarPathCalls = 0;

  @override
  Future<Result<FSA>> loadAutomatonFromBytes(Uint8List bytes) async {
    bytesCalls += 1;
    if (_automaton != null) {
      return Success(_automaton);
    }
    return const Failure('No automaton configured');
  }

  @override
  Future<Result<FSA>> loadAutomatonFromJFLAP(String filePath) async {
    pathCalls += 1;
    if (_automaton != null) {
      return Success(_automaton);
    }
    return const Failure('No automaton configured');
  }

  @override
  Future<Result<Grammar>> loadGrammarFromBytes(Uint8List bytes) async {
    grammarBytesCalls += 1;
    if (_grammar != null) {
      return Success(_grammar);
    }
    return const Failure('No grammar configured');
  }

  @override
  Future<Result<Grammar>> loadGrammarFromJFLAP(String filePath) async {
    grammarPathCalls += 1;
    if (_grammar != null) {
      return Success(_grammar);
    }
    return const Failure('No grammar configured');
  }
}
