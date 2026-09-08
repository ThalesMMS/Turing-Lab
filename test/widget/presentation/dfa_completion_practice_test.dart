//
//  dfa_completion_practice_test.dart
//  Turing Lab
//
//  Covers the guided DFA completion practice inside the FSA algorithm panel:
//  the live missing-pair list, hints as the learner adds the trap state and
//  transitions on the canvas notifier, the complete state, the reveal action,
//  the compact layout and Portuguese copy.
//

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart' as automata;
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/providers/automaton_state_provider.dart';
import 'package:turing_lab/presentation/widgets/algorithm_panel.dart';
import 'package:turing_lab/presentation/widgets/dfa_completion_practice_section.dart';
import 'package:vector_math/vector_math_64.dart';

FSA _partialDfa() {
  final q0 = automata.State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 100),
    isInitial: true,
    isAccepting: false,
  );
  final q1 = automata.State(
    id: 'q1',
    label: 'q1',
    position: Vector2(120, 100),
    isInitial: false,
    isAccepting: true,
  );
  return FSA(
    id: 'dfa',
    name: 'DFA',
    states: {q0, q1},
    transitions: {
      FSATransition.deterministic(
        id: 't0',
        fromState: q0,
        toState: q1,
        symbol: 'a',
      ),
    },
    alphabet: {'a', 'b'},
    initialState: q0,
    acceptingStates: {q1},
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
    bounds: const math.Rectangle(0, 0, 200, 200),
  );
}

Future<AutomatonStateNotifier> _pump(
  WidgetTester tester, {
  FSA? automaton,
  VoidCallback? onCompleteDfa,
  Locale locale = const Locale('en'),
  Size? size,
}) async {
  if (size != null) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }
  final notifier = AutomatonStateNotifier();
  if (automaton != null) notifier.updateAutomaton(automaton);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [automatonStateProvider.overrideWith((ref) => notifier)],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) => AlgorithmPanel(
              currentAutomaton: ref
                  .watch(automatonStateProvider)
                  .currentAutomaton,
              onCompleteDfa: onCompleteDfa,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return notifier;
}

Future<void> _openPractice(WidgetTester tester, String title) async {
  final button = find.text(title);
  await tester.scrollUntilVisible(
    button,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(button);
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('dfa_practice_section')), findsOneWidget);
}

void main() {
  testWidgets('lists missing pairs live and guides until complete', (
    tester,
  ) async {
    final notifier = await _pump(tester, automaton: _partialDfa());
    await _openPractice(tester, 'Practice DFA completion');

    expect(find.textContaining('alphabet {a, b}'), findsOneWidget);
    expect(find.text('3 pairs still have no transition:'), findsOneWidget);
    expect(find.text('• State q0 on symbol b'), findsOneWidget);
    expect(find.text('• State q1 on symbol a'), findsOneWidget);
    expect(find.text('• State q1 on symbol b'), findsOneWidget);
    expect(
      find.textContaining('Create a new non-accepting state'),
      findsOneWidget,
    );

    // The learner creates the trap state on the canvas.
    notifier.addState(id: 'trap', label: 'trap', x: 240, y: 100);
    await tester.pumpAndSettle();
    expect(find.text('5 pairs still have no transition:'), findsOneWidget);
    expect(find.text('Trap candidates: trap'), findsOneWidget);
    expect(
      find.textContaining('Send every missing pair to the trap state trap'),
      findsOneWidget,
    );

    // Route the missing pairs of q0 and q1 to the trap.
    notifier.addOrUpdateTransition(
      id: 't1',
      fromStateId: 'q0',
      toStateId: 'trap',
      label: 'b',
    );
    notifier.addOrUpdateTransition(
      id: 't2',
      fromStateId: 'q1',
      toStateId: 'trap',
      label: 'a',
    );
    notifier.addOrUpdateTransition(
      id: 't3',
      fromStateId: 'q1',
      toStateId: 'trap',
      label: 'b',
    );
    await tester.pumpAndSettle();
    expect(find.text('2 pairs still have no transition:'), findsOneWidget);
    expect(find.text('• State trap on symbol a'), findsOneWidget);
    expect(find.textContaining('Loop the trap state trap'), findsOneWidget);

    notifier.addOrUpdateTransition(
      id: 't4',
      fromStateId: 'trap',
      toStateId: 'trap',
      label: 'a',
    );
    notifier.addOrUpdateTransition(
      id: 't5',
      fromStateId: 'trap',
      toStateId: 'trap',
      label: 'b',
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Complete! Every state has a transition for every symbol.'),
      findsOneWidget,
    );
    expect(find.textContaining('still have no transition'), findsNothing);
    expect(find.text('Hint'), findsNothing);
    final reveal = tester.widget<FilledButton>(
      find.byKey(DfaCompletionPracticeSection.revealKey),
    );
    expect(reveal.onPressed, isNull);
  });

  testWidgets('reveal runs the automatic completion and close hides it', (
    tester,
  ) async {
    var completions = 0;
    await _pump(
      tester,
      automaton: _partialDfa(),
      onCompleteDfa: () => completions++,
    );
    await _openPractice(tester, 'Practice DFA completion');

    await tester.tap(find.byKey(DfaCompletionPracticeSection.revealKey));
    await tester.pumpAndSettle();
    expect(completions, 1);

    await tester.tap(find.byKey(DfaCompletionPracticeSection.closeKey));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('dfa_practice_section')), findsNothing);
  });

  testWidgets('explains the empty and nondeterministic cases', (tester) async {
    final notifier = await _pump(tester);
    await _openPractice(tester, 'Practice DFA completion');
    expect(
      find.text('Load or draw a DFA to practice its completion.'),
      findsOneWidget,
    );

    final dfa = _partialDfa();
    notifier.updateAutomaton(dfa);
    notifier.addOrUpdateTransition(
      id: 'dup',
      fromStateId: 'q0',
      toStateId: 'q0',
      label: 'a',
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Completion applies to DFAs.'), findsOneWidget);
  });

  testWidgets('renders in Portuguese at 320 px without overflow', (
    tester,
  ) async {
    await _pump(
      tester,
      automaton: _partialDfa(),
      locale: const Locale('pt', 'BR'),
      size: const Size(320, 700),
    );
    await _openPractice(tester, 'Praticar completamento de AFD');

    expect(find.text('3 pares ainda não têm transição:'), findsOneWidget);
    expect(find.text('• Estado q0 no símbolo b'), findsOneWidget);
    expect(find.text('Dica'), findsOneWidget);
    expect(find.text('Completar automaticamente'), findsOneWidget);
    expect(find.text('Fechar prática'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
