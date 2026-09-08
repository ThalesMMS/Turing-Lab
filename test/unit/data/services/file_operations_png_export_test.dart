//
//  file_operations_png_export_test.dart
//  Turing Lab
//
//  Rasterizes a PDA and a Turing machine through the real IO service and
//  checks that a PNG payload is produced with the same off-screen painter
//  the FSA export uses.
//

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/annotations/annotations.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/pda_transition.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:turing_lab/data/services/file_operations_service.dart';
import 'package:vector_math/vector_math_64.dart';

const _pngSignature = [137, 80, 78, 71, 13, 10, 26, 10];

automaton_state.State _state(String id, double x, {bool accepting = false}) {
  return automaton_state.State(
    id: id,
    label: id,
    position: Vector2(x, 200),
    isInitial: x == 100,
    isAccepting: accepting,
  );
}

PDA _pda() {
  final p0 = _state('p0', 100);
  final p1 = _state('p1', 300, accepting: true);
  return PDA(
    id: 'pda',
    name: 'PDA',
    states: {p0, p1},
    transitions: {
      PDATransition(
        id: 't0',
        fromState: p0,
        toState: p1,
        label: 'a,Z->AZ',
        inputSymbol: 'a',
        popSymbol: 'Z',
        pushSymbol: 'AZ',
      ),
      PDATransition(
        id: 't1',
        fromState: p1,
        toState: p1,
        label: 'λ,A->λ',
        inputSymbol: '',
        popSymbol: 'A',
        pushSymbol: '',
      ),
    },
    alphabet: const {'a'},
    initialState: p0,
    acceptingStates: {p1},
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
    bounds: const math.Rectangle<double>(0, 0, 400, 300),
    zoomLevel: 1,
    panOffset: Vector2.zero(),
    stackAlphabet: const {'A', 'Z'},
    initialStackSymbol: 'Z',
  );
}

TM _tm() {
  final t0 = _state('t0', 100);
  final t1 = _state('t1', 300, accepting: true);
  return TM(
    id: 'tm',
    name: 'TM',
    states: {t0, t1},
    transitions: {
      TMTransition(
        id: 't0',
        fromState: t0,
        toState: t1,
        label: '1/0,R',
        readSymbol: '1',
        writeSymbol: '0',
        direction: TapeDirection.right,
      ),
    },
    alphabet: const {'1'},
    initialState: t0,
    acceptingStates: {t1},
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
    bounds: const math.Rectangle<double>(0, 0, 400, 300),
    zoomLevel: 1,
    panOffset: Vector2.zero(),
    tapeAlphabet: const {'1', '0', 'B'},
    blankSymbol: 'B',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final service = FileOperationsService();

  test('FSA PNG preserves every symbol in a transition label', () async {
    final q0 = _state('q0', 100);
    final q1 = _state('q1', 300, accepting: true);
    Future<List<int>> render(Set<String> symbols) async {
      final machine = FSA(
        id: 'fsa',
        name: 'FSA',
        states: {q0, q1},
        transitions: {
          FSATransition(
            id: 'edge',
            fromState: q0,
            toState: q1,
            inputSymbols: symbols,
          ),
        },
        alphabet: const {'a', 'b'},
        initialState: q0,
        acceptingStates: {q1},
        created: DateTime.utc(2026),
        modified: DateTime.utc(2026),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
      );
      final result = await service.exportAutomatonToPngBytes(machine);
      expect(result.isSuccess, isTrue);
      return result.data!;
    }

    expect(await render({'a', 'b'}), isNot(orderedEquals(await render({'a'}))));
    expect(await render({'b', 'a'}), orderedEquals(await render({'a', 'b'})));
  });

  test('PDA states outside the initial viewport remain visible', () async {
    final machine = _pda();
    final offscreen = machine.states
        .map(
          (s) =>
              s.copyWith(position: Vector2(s.position.x + 1000, s.position.y)),
        )
        .toSet();
    final actual = await service.exportPdaToPngBytes(
      machine.copyWith(states: offscreen, transitions: <PDATransition>{}),
    );
    final empty = await service.exportPdaToPngBytes(
      machine.copyWith(
        states: <automaton_state.State>{},
        transitions: <PDATransition>{},
      ),
    );
    expect(actual.isSuccess, isTrue);
    expect(actual.data!, isNot(orderedEquals(empty.data!)));
  });
  test('opposing TM labels retain their direction association', () async {
    final machine = _tm();
    final edge = machine.tmTransitions.single;
    Future<List<int>> render(String a, String b) async =>
        (await service.exportTuringMachineToPngBytes(
          machine.copyWith(
            transitions: {
              edge.copyWith(id: 'a', label: a),
              edge.copyWith(
                id: 'b',
                fromState: edge.toState,
                toState: edge.fromState,
                label: b,
              ),
            },
          ),
        )).data!;
    expect(
      await render('1/0,R', '0/11,L'),
      isNot(orderedEquals(await render('0/11,L', '1/0,R'))),
    );
  });

  for (final target in [
    AnnotationTargetType.canvas,
    AnnotationTargetType.state,
    AnnotationTargetType.transition,
  ]) {
    for (final sign in [-1.0, 1.0]) {
      test(
        'PNG clamps $target annotation geometry at $sign sheet edge',
        () async {
          final machine = _pda();
          Future<Uint8List> render(double extent) async {
            final attached =
                target == AnnotationTargetType.state ||
                target == AnnotationTargetType.transition;
            final note = DocumentAnnotation(
              id: 'bounded-note',
              documentId: machine.id,
              documentRevision: '0',
              text: 'Bounded note',
              x: attached ? 0 : sign * extent,
              y: attached ? 0 : sign * extent,
              width: 4096,
              height: 4096,
              attachment: attached
                  ? AnnotationAttachment(
                      type: target,
                      targetId: target == AnnotationTargetType.state
                          ? 'p0'
                          : 't0',
                      offsetX: sign * extent,
                      offsetY: sign * extent,
                    )
                  : null,
              createdAt: DateTime.utc(2026),
              updatedAt: DateTime.utc(2026),
            );
            final result = await service.exportPdaToPngBytes(
              machine,
              includeAnnotations: true,
              annotations: DocumentAnnotationCollection(
                documentId: machine.id,
                documentRevision: '0',
                annotations: [note],
              ),
            );
            expect(result.isSuccess, isTrue);
            return result.data!;
          }

          expect(await render(1e12), orderedEquals(await render(10000)));
        },
      );
    }
  }

  for (final offset in [Vector2(-1200, -900), Vector2(2400, 1800)]) {
    test(
      'PDA diagram and attached note survive translation by $offset',
      () async {
        final machine = _pda();
        final movedStates = {
          for (final state in machine.states)
            state.id: state.copyWith(position: state.position + offset),
        };
        final moved = machine.copyWith(
          states: movedStates.values.toSet(),
          transitions: {
            for (final edge in machine.pdaTransitions)
              edge.copyWith(
                fromState: movedStates[edge.fromState.id],
                toState: movedStates[edge.toState.id],
              ),
          },
        );
        final annotations = DocumentAnnotationCollection(
          documentId: machine.id,
          documentRevision: '0',
          annotations: [
            DocumentAnnotation(
              id: 'note',
              documentId: machine.id,
              documentRevision: '0',
              text: 'An attached note',
              x: 0,
              y: 0,
              attachment: const AnnotationAttachment(
                type: AnnotationTargetType.state,
                targetId: 'p1',
                offsetY: 120,
              ),
              createdAt: DateTime.utc(2026),
              updatedAt: DateTime.utc(2026),
            ),
          ],
        );
        final original = await service.exportPdaToPngBytes(
          machine,
          includeAnnotations: true,
          annotations: annotations,
        );
        final translated = await service.exportPdaToPngBytes(
          moved,
          includeAnnotations: true,
          annotations: annotations,
        );
        expect(original.isSuccess, isTrue);
        expect(translated.isSuccess, isTrue);
        // Compare pixels: recording translated paths can change subpixel rounding.
        Future<Uint8List> pixels(Uint8List bytes) async {
          final codec = await ui.instantiateImageCodec(bytes);
          final frame = await codec.getNextFrame();
          final data = await frame.image.toByteData();
          frame.image.dispose();
          codec.dispose();
          return data!.buffer.asUint8List();
        }

        final originalPixels = await pixels(original.data!);
        final translatedPixels = await pixels(translated.data!);
        expect(translatedPixels.length, originalPixels.length);
        var delta = 0;
        for (var i = 0; i < originalPixels.length; i++) {
          delta += (originalPixels[i] - translatedPixels[i]).abs();
        }
        expect(delta / originalPixels.length, lessThan(0.01));
      },
    );
  }

  test('opposing PDA labels retain their direction association', () async {
    final machine = _pda();
    final edge = machine.pdaTransitions.firstWhere(
      (e) => e.fromState != e.toState,
    );
    Future<List<int>> render(String a, String b) async =>
        (await service.exportPdaToPngBytes(
          machine.copyWith(
            transitions: {
              edge.copyWith(id: 'a', label: a),
              edge.copyWith(
                id: 'b',
                fromState: edge.toState,
                toState: edge.fromState,
                label: b,
              ),
            },
          ),
        )).data!;
    expect(
      await render('a,Z->AZ', 'bb,A->AAA'),
      isNot(orderedEquals(await render('bb,A->AAA', 'a,Z->AZ'))),
    );
  });

  for (final selfLoop in [false, true]) {
    test(
      'PDA parallel labels occupy separate rows (loop: $selfLoop)',
      () async {
        final machine = _pda();
        final edge = machine.pdaTransitions.firstWhere(
          (edge) => edge.fromState != edge.toState,
        );
        final first = edge.copyWith(
          id: 'first',
          toState: selfLoop ? edge.fromState : edge.toState,
          label: 'a,Z->AZ',
        );
        final second = first.copyWith(id: 'second', label: 'a,A->AA');
        final actual = await service.exportPdaToPngBytes(
          machine.copyWith(transitions: {first, second}),
        );
        final expected = await service.exportPdaToPngBytes(
          machine.copyWith(
            transitions: {first.copyWith(label: 'a,Z->AZ\na,A->AA')},
          ),
        );
        expect(actual.isSuccess, isTrue);
        expect(expected.isSuccess, isTrue);
        expect(actual.data!, orderedEquals(expected.data!));
      },
    );

    test('TM parallel labels occupy separate rows (loop: $selfLoop)', () async {
      final machine = _tm();
      final edge = machine.tmTransitions.single;
      final first = edge.copyWith(
        id: 'first',
        toState: selfLoop ? edge.fromState : edge.toState,
        label: '1/0,R',
      );
      final second = first.copyWith(id: 'second', label: '0/1,R');
      final actual = await service.exportTuringMachineToPngBytes(
        machine.copyWith(transitions: {first, second}),
      );
      final expected = await service.exportTuringMachineToPngBytes(
        machine.copyWith(transitions: {first.copyWith(label: '1/0,R\n0/1,R')}),
      );
      expect(actual.isSuccess, isTrue);
      expect(expected.isSuccess, isTrue);
      expect(actual.data!, orderedEquals(expected.data!));
    });
  }

  test('PDA transition direction survives PNG export', () async {
    final machine = _pda();
    final edge = machine.pdaTransitions.firstWhere(
      (e) => e.fromState != e.toState,
    );
    final forward = await service.exportPdaToPngBytes(
      machine.copyWith(transitions: {edge}),
    );
    final reverse = await service.exportPdaToPngBytes(
      machine.copyWith(
        transitions: {
          edge.copyWith(fromState: edge.toState, toState: edge.fromState),
        },
      ),
    );
    expect(forward.isSuccess, isTrue);
    expect(reverse.isSuccess, isTrue);
    expect(reverse.data!, isNot(orderedEquals(forward.data!)));
  });

  test('TM transition direction survives PNG export', () async {
    final machine = _tm();
    final edge = machine.tmTransitions.single;
    final forward = await service.exportTuringMachineToPngBytes(machine);
    final reverse = await service.exportTuringMachineToPngBytes(
      machine.copyWith(
        transitions: {
          edge.copyWith(fromState: edge.toState, toState: edge.fromState),
        },
      ),
    );
    expect(forward.isSuccess, isTrue);
    expect(reverse.isSuccess, isTrue);
    expect(reverse.data!, isNot(orderedEquals(forward.data!)));
  });

  test('TM self-loop and its label survive PNG export', () async {
    final machine = _tm();
    final state = machine.states.first;
    TM loopMachine(String label) => machine.copyWith(
      transitions: {
        TMTransition(
          id: 'loop',
          fromState: state,
          toState: state,
          label: label,
          readSymbol: '1',
          writeSymbol: '0',
          direction: TapeDirection.right,
        ),
      },
    );
    final empty = (await service.exportTuringMachineToPngBytes(
      machine.copyWith(transitions: <TMTransition>{}),
    )).data!;
    final loop = (await service.exportTuringMachineToPngBytes(
      loopMachine('1/0,R'),
    )).data!;
    final unlabeled = (await service.exportTuringMachineToPngBytes(
      loopMachine(''),
    )).data!;
    expect(loop, isNot(equals(empty)));
    expect(unlabeled, isNot(equals(empty)));
    expect(unlabeled, isNot(equals(loop)));
  });

  test('PDA self-loop and its label survive PNG export', () async {
    final machine = _pda();
    final state = machine.states.first;
    PDA loopMachine(String label) => machine.copyWith(
      transitions: {
        PDATransition(
          id: 'loop',
          fromState: state,
          toState: state,
          label: label,
          inputSymbol: 'a',
          popSymbol: 'Z',
          pushSymbol: 'Z',
        ),
      },
    );
    final empty = (await service.exportPdaToPngBytes(
      machine.copyWith(transitions: <PDATransition>{}),
    )).data!;
    final loop = (await service.exportPdaToPngBytes(
      loopMachine('a,Z/Z'),
    )).data!;
    final unlabeled = (await service.exportPdaToPngBytes(
      loopMachine(''),
    )).data!;
    expect(loop, isNot(equals(empty)));
    expect(unlabeled, isNot(equals(empty)));
    expect(unlabeled, isNot(equals(loop)));
  });

  test('PDA export renders a PNG payload', () async {
    final result = await service.exportPdaToPngBytes(_pda());
    expect(result.isSuccess, isTrue, reason: result.error);
    expect(result.data!.take(8), _pngSignature);
    expect(result.data!.length, greaterThan(1000));
  });

  test('TM export renders a PNG payload', () async {
    final result = await service.exportTuringMachineToPngBytes(
      _tm(),
      emptyStringSymbol: 'λ',
    );
    expect(result.isSuccess, isTrue, reason: result.error);
    expect(result.data!.take(8), _pngSignature);
    expect(result.data!.length, greaterThan(1000));
  });

  test('different machines render different images', () async {
    final pda = (await service.exportPdaToPngBytes(_pda())).data!;
    final tm = (await service.exportTuringMachineToPngBytes(_tm())).data!;
    expect(pda, isNot(equals(tm)));
  });
}
