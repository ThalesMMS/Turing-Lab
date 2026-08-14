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

    test('copyWith can clear nullable TM metadata', () {
      const metadata = GraphViewAutomatonMetadata(
        id: 'tm-1',
        name: 'TM',
        alphabet: ['a'],
        blankSymbol: 'B',
        tapeCount: 2,
      );

      final cleared = metadata.copyWith(
        blankSymbol: null,
        tapeCount: null,
      );

      expect(cleared.blankSymbol, isNull);
      expect(cleared.tapeCount, isNull);
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
  });
}
