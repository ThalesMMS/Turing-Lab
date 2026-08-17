//
//  graphview_canvas_models_test.dart
//  Turing Lab
//
//  Verifica os modelos de dados utilizados pelo canvas GraphView, confirmando a imutabilidade e a
//  correta propagação de metadados de transições. Exercita métodos utilitários como copyWith para
//  garantir que updates mantenham integridade do grafo.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:turing_lab/features/canvas/graphview/graphview_canvas_models.dart';

void main() {
  group('GraphViewAutomatonMetadata', () {
    test('round-trips TM tape metadata', () {
      const metadata = GraphViewAutomatonMetadata(
        id: 'tm-1',
        name: 'TM',
        alphabet: ['a', 'b'],
        tapeAlphabet: ['a', 'b', 'X', 'B'],
        blankSymbol: 'B',
        tapeCount: 1,
      );

      final restored = GraphViewAutomatonMetadata.fromJson(metadata.toJson());

      expect(restored.alphabet, equals(['a', 'b']));
      expect(restored.tapeAlphabet, equals(['a', 'b', 'X', 'B']));
      expect(restored.blankSymbol, 'B');
      expect(restored.tapeCount, 1);
    });

    test('round-trips PDA stack metadata', () {
      const metadata = GraphViewAutomatonMetadata(
        id: 'pda-1',
        name: 'PDA',
        alphabet: ['a'],
        stackAlphabet: ['Z', 'S_0', 'unused-stack-symbol'],
        initialStackSymbol: 'S_0',
      );

      final restored = GraphViewAutomatonMetadata.fromJson(metadata.toJson());

      expect(
        restored.stackAlphabet,
        ['Z', 'S_0', 'unused-stack-symbol'],
      );
      expect(restored.initialStackSymbol, 'S_0');
    });

    test('copyWith can clear nullable automaton metadata', () {
      const metadata = GraphViewAutomatonMetadata(
        id: 'tm-1',
        name: 'TM',
        alphabet: ['a'],
        blankSymbol: 'B',
        tapeCount: 2,
        initialStackSymbol: 'Z',
      );

      final cleared = metadata.copyWith(
        blankSymbol: null,
        tapeCount: null,
        initialStackSymbol: null,
      );

      expect(cleared.blankSymbol, isNull);
      expect(cleared.tapeCount, isNull);
      expect(cleared.initialStackSymbol, isNull);
    });
  });

  group('GraphViewCanvasEdge', () {
    test('copyWith updates PDA metadata fields', () {
      const baseEdge = GraphViewCanvasEdge(
        id: 'edge-1',
        fromStateId: 'q0',
        toStateId: 'q1',
        symbols: ['a'],
        popSymbol: 'A',
        pushSymbol: 'B',
        isLambdaInput: false,
        isLambdaPop: false,
        isLambdaPush: false,
      );

      final updated = baseEdge.copyWith(
        popSymbol: 'Z',
        pushSymbol: 'Y',
        isLambdaInput: true,
        isLambdaPop: true,
        isLambdaPush: true,
      );

      expect(updated.popSymbol, 'Z');
      expect(updated.pushSymbol, 'Y');
      expect(updated.isLambdaInput, isTrue);
      expect(updated.isLambdaPop, isTrue);
      expect(updated.isLambdaPush, isTrue);
    });

    test('round-trips epsilon edge without phantom empty symbol', () {
      const edge = GraphViewCanvasEdge(
        id: 'epsilon',
        fromStateId: 'q0',
        toStateId: 'q1',
        symbols: <String>[],
        lambdaSymbol: 'ε',
      );

      final restored = GraphViewCanvasEdge.fromJson(edge.toJson());

      expect(restored.symbols, isEmpty);
      expect(restored.lambdaSymbol, 'ε');
    });

    test('round-trips an FSA symbol containing a comma atomically', () {
      const edge = GraphViewCanvasEdge(
        id: 'comma-symbol',
        fromStateId: 'q0',
        toStateId: 'q1',
        symbols: ['a,b', 'c'],
      );

      final json = edge.toJson();
      final restored = GraphViewCanvasEdge.fromJson(json);

      expect(json['symbols'], ['a,b', 'c']);
      expect(restored.symbols, ['a,b', 'c']);
    });

    test('reads legacy comma-joined FSA symbols', () {
      final restored = GraphViewCanvasEdge.fromJson({
        'id': 'legacy',
        'from': 'q0',
        'to': 'q1',
        'symbols': 'a,b',
      });

      expect(restored.symbols, ['a', 'b']);
    });

    test('copyWith can clear every nullable transition field', () {
      const edge = GraphViewCanvasEdge(
        id: 'nullable-fields',
        fromStateId: 'q0',
        toStateId: 'q1',
        symbols: ['a'],
        lambdaSymbol: 'ε',
        controlPointX: 12,
        controlPointY: 24,
        readSymbol: 'a',
        writeSymbol: 'b',
        direction: TapeDirection.left,
        tapeNumber: 2,
        popSymbol: 'Z',
        pushSymbol: 'S_0Z',
        pushSymbols: ['S_0', 'Z'],
        isLambdaInput: false,
        isLambdaPop: false,
        isLambdaPush: false,
      );

      final cleared = edge.copyWith(
        lambdaSymbol: null,
        controlPointX: null,
        controlPointY: null,
        readSymbol: null,
        writeSymbol: null,
        direction: null,
        tapeNumber: null,
        popSymbol: null,
        pushSymbol: null,
        pushSymbols: null,
        isLambdaInput: null,
        isLambdaPop: null,
        isLambdaPush: null,
      );

      expect(cleared.lambdaSymbol, isNull);
      expect(cleared.controlPointX, isNull);
      expect(cleared.controlPointY, isNull);
      expect(cleared.readSymbol, isNull);
      expect(cleared.writeSymbol, isNull);
      expect(cleared.direction, isNull);
      expect(cleared.tapeNumber, isNull);
      expect(cleared.popSymbol, isNull);
      expect(cleared.pushSymbol, isNull);
      expect(cleared.pushSymbols, isNull);
      expect(cleared.isLambdaInput, isNull);
      expect(cleared.isLambdaPop, isNull);
      expect(cleared.isLambdaPush, isNull);
    });
  });
}
