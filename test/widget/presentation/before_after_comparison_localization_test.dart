import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/before_after_comparison.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  testWidgets(
    'localizes default comparison labels and semantics in Portuguese',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              height: 500,
              child: BeforeAfterComparison(
                beforeAutomaton: _fsa('before'),
                afterAutomaton: _fsa('after', symbol: 'b'),
                transformationDescription: 'Resultado da conversão',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Antes'), findsOneWidget);
      expect(find.text('Depois'), findsOneWidget);
      expect(find.text('Estados'), findsOneWidget);
      expect(find.text('Transições'), findsOneWidget);
      expect(find.text('Before'), findsNothing);
      expect(find.text('After'), findsNothing);
      expect(find.text('States'), findsNothing);
      expect(find.text('Transitions'), findsNothing);

      final beforeCanvas = tester.getSemantics(
        find.bySemanticsLabel('Antes. 2 estados, 1 transição'),
      );
      expect(beforeCanvas.label, contains('2 estados'));
      expect(beforeCanvas.label, contains('1 transição'));
      final afterCanvas = tester.getSemantics(
        find.bySemanticsLabel('Depois. 2 estados, 1 transição'),
      );
      expect(afterCanvas.label, contains('2 estados'));
      expect(afterCanvas.label, contains('1 transição'));
      semantics.dispose();
    },
  );
}

FSA _fsa(String id, {String symbol = 'a'}) {
  final now = DateTime.utc(2026, 8, 27);
  final q0 = automaton_state.State(
    id: '$id-q0',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );
  final q1 = automaton_state.State(
    id: '$id-q1',
    label: 'q1',
    position: Vector2(100, 0),
    isAccepting: true,
  );
  return FSA(
    id: id,
    name: id,
    states: {q0, q1},
    transitions: {
      FSATransition(
        id: '$id-t0',
        fromState: q0,
        toState: q1,
        inputSymbols: {symbol},
      ),
    },
    alphabet: {symbol},
    initialState: q0,
    acceptingStates: {q1},
    created: now,
    modified: now,
    bounds: const math.Rectangle<double>(0, 0, 400, 300),
  );
}
