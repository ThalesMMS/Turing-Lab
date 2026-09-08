//
//  transducer_conversion_panel_test.dart
//  Turing Lab
//
//  Covers the Mealy/Moore conversion panel: contract text, exact and
//  convention-difference results, didactic steps, differential evidence,
//  rejection of invalid machines, opening the result in the other workspace
//  with replacement confirmation, and Portuguese copy.
//

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/transducers/transducers.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/providers/home_navigation_provider.dart';
import 'package:turing_lab/presentation/providers/workspace_registry_provider.dart';
import 'package:turing_lab/presentation/transducers/moore_workspace_definition.dart';
import 'package:turing_lab/presentation/transducers/transducer_conversion_panel.dart';

MealyMachine _mealy() => MealyMachine(
  id: const TransducerMachineId('m'),
  name: 'Parity',
  revision: const TransducerRevision(1),
  inputAlphabet: const [TransducerInputSymbol('0'), TransducerInputSymbol('1')],
  outputAlphabet: const [
    TransducerOutputSymbol('e'),
    TransducerOutputSymbol('o'),
  ],
  states: const [
    MealyState(
      id: TransducerStateId('even'),
      label: 'even',
      position: TransducerPoint(0, 0),
      isInitial: true,
    ),
    MealyState(
      id: TransducerStateId('odd'),
      label: 'odd',
      position: TransducerPoint(100, 0),
    ),
  ],
  transitions: [
    MealyTransition(
      id: const TransducerTransitionId('t0'),
      from: const TransducerStateId('even'),
      to: const TransducerStateId('even'),
      input: const TransducerInputSymbol('0'),
      output: TransducerOutputWord.fromValues(const ['e']),
    ),
    MealyTransition(
      id: const TransducerTransitionId('t1'),
      from: const TransducerStateId('even'),
      to: const TransducerStateId('odd'),
      input: const TransducerInputSymbol('1'),
      output: TransducerOutputWord.fromValues(const ['o']),
    ),
    MealyTransition(
      id: const TransducerTransitionId('t2'),
      from: const TransducerStateId('odd'),
      to: const TransducerStateId('odd'),
      input: const TransducerInputSymbol('0'),
      output: TransducerOutputWord.fromValues(const ['o']),
    ),
    MealyTransition(
      id: const TransducerTransitionId('t3'),
      from: const TransducerStateId('odd'),
      to: const TransducerStateId('even'),
      input: const TransducerInputSymbol('1'),
      output: TransducerOutputWord.fromValues(const ['e']),
    ),
  ],
);

MooreMachine _mooreWithInitialOutput() => MooreMachine(
  id: const TransducerMachineId('mo'),
  name: 'Greeter',
  revision: const TransducerRevision(1),
  inputAlphabet: const [TransducerInputSymbol('a')],
  outputAlphabet: const [
    TransducerOutputSymbol('x'),
    TransducerOutputSymbol('y'),
  ],
  states: [
    MooreState(
      id: const TransducerStateId('s0'),
      label: 's0',
      position: const TransducerPoint(0, 0),
      isInitial: true,
      output: TransducerOutputWord.fromValues(const ['x']),
    ),
    MooreState(
      id: const TransducerStateId('s1'),
      label: 's1',
      position: const TransducerPoint(100, 0),
      output: TransducerOutputWord.fromValues(const ['y']),
    ),
  ],
  transitions: const [
    MooreTransition(
      id: TransducerTransitionId('t0'),
      from: TransducerStateId('s0'),
      to: TransducerStateId('s1'),
      input: TransducerInputSymbol('a'),
    ),
    MooreTransition(
      id: TransducerTransitionId('t1'),
      from: TransducerStateId('s1'),
      to: TransducerStateId('s0'),
      input: TransducerInputSymbol('a'),
    ),
  ],
);

Future<ProviderContainer> _pump(
  WidgetTester tester,
  DeterministicFiniteStateTransducer machine, {
  Locale locale = const Locale('en'),
}) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            height: 800,
            child: TransducerConversionPanel(machine: machine),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('large alphabets yield and report partial evidence', (
    tester,
  ) async {
    final alphabet = List.generate(
      64,
      (i) => TransducerInputSymbol('symbol-$i'),
    );
    final machine = MealyMachine(
      id: const TransducerMachineId('wide'),
      name: 'Wide',
      revision: const TransducerRevision(0),
      inputAlphabet: alphabet,
      outputAlphabet: const [],
      states: const [
        MealyState(
          id: TransducerStateId('q'),
          label: 'q',
          position: TransducerPoint(0, 0),
          isInitial: true,
        ),
      ],
      transitions: [
        for (final symbol in alphabet)
          MealyTransition(
            id: TransducerTransitionId(symbol.value),
            from: const TransducerStateId('q'),
            to: const TransducerStateId('q'),
            input: symbol,
            output: TransducerOutputWord.empty,
          ),
      ],
    );
    await _pump(tester, machine);
    await tester.tap(find.byKey(TransducerConversionPanel.convertKey));
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
    expect(
      find.textContaining(
        'Stopped after $kTransducerConversionEvidenceMaxWords input words',
      ),
      findsOneWidget,
    );
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('replacing the document cancels pending evidence', (
    tester,
  ) async {
    await _pump(tester, _mealy());
    await tester.tap(find.byKey(TransducerConversionPanel.convertKey));
    await _pump(tester, _mooreWithInitialOutput());
    expect(
      find.byKey(const ValueKey('transducer_conversion_report')),
      findsNothing,
    );
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(TransducerConversionPanel.convertKey));
    await tester.pumpAndSettle();
    expect(find.textContaining('outputs agree'), findsOneWidget);
  });

  testWidgets('disposing the panel cancels pending evidence', (tester) async {
    await _pump(tester, _mealy());
    await tester.tap(find.byKey(TransducerConversionPanel.convertKey));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('converts a Mealy machine exactly and lists the steps', (
    tester,
  ) async {
    await _pump(tester, _mealy());
    expect(
      find.textContaining('Two transducers are equivalent'),
      findsOneWidget,
    );
    expect(find.text('Convert to Moore'), findsOneWidget);

    await tester.tap(find.byKey(TransducerConversionPanel.convertKey));
    await tester.pumpAndSettle();

    expect(
      find.text('Exact conversion: the same output for every input word.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('2 states and 4 transitions became'),
      findsOneWidget,
    );
    expect(
      find.textContaining('input words up to length 4: outputs agree'),
      findsOneWidget,
    );
    expect(find.text('Construction steps'), findsOneWidget);
    expect(find.textContaining('Create Moore state'), findsWidgets);
    expect(find.text('Open in the Moore workspace'), findsOneWidget);
  });

  testWidgets('reports the dropped Moore initial output as a convention '
      'difference', (tester) async {
    await _pump(tester, _mooreWithInitialOutput());
    expect(find.text('Convert to Mealy'), findsOneWidget);
    await tester.tap(find.byKey(TransducerConversionPanel.convertKey));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Convention difference: the Moore initial output x'),
      findsOneWidget,
    );
    // Once in the hint and once in the drop step.
    expect(
      find.textContaining('cannot be emitted before reading'),
      findsNWidgets(2),
    );
    expect(find.textContaining('outputs agree'), findsOneWidget);
  });

  testWidgets('opens the result in the other workspace and confirms '
      'replacement', (tester) async {
    final container = await _pump(tester, _mealy());
    await tester.tap(find.byKey(TransducerConversionPanel.convertKey));
    await tester.pumpAndSettle();

    // The Moore workspace starts empty: no confirmation needed.
    await tester.tap(find.byKey(TransducerConversionPanel.openKey));
    await tester.pumpAndSettle();
    final moore = container.read(mooreEditorProvider).document;
    expect(moore.states, isNotEmpty);
    expect(moore.states.singleWhere((s) => s.isInitial).output.values, isEmpty);
    expect(
      container.read(homeNavigationProvider),
      container
          .read(workspacePresentationRegistryProvider)
          .indexOfKey(TransducerFormalSystemIds.moore),
    );
    expect(
      find.textContaining('opened in the Moore workspace'),
      findsOneWidget,
    );

    // A second open asks before replacing the loaded Moore machine.
    await tester.tap(find.byKey(TransducerConversionPanel.openKey));
    await tester.pumpAndSettle();
    expect(find.textContaining('already holds a machine'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(container.read(mooreEditorProvider).document, same(moore));
  });

  testWidgets('rejects a nondeterministic machine with diagnostics', (
    tester,
  ) async {
    final base = _mealy();
    final machine = base.copyWith(
      transitions: [
        ...base.transitions,
        MealyTransition(
          id: const TransducerTransitionId('dup'),
          from: const TransducerStateId('even'),
          to: const TransducerStateId('odd'),
          input: const TransducerInputSymbol('0'),
          output: TransducerOutputWord.fromValues(const ['o']),
        ),
      ],
    );
    await _pump(tester, machine);
    await tester.tap(find.byKey(TransducerConversionPanel.convertKey));
    await tester.pumpAndSettle();
    expect(find.textContaining('cannot be converted until'), findsOneWidget);
    expect(find.byKey(TransducerConversionPanel.openKey), findsNothing);
  });

  testWidgets('localizes the panel in Portuguese', (tester) async {
    await _pump(tester, _mealy(), locale: const Locale('pt', 'BR'));
    expect(find.text('Converter para Moore'), findsOneWidget);
    await tester.tap(find.byKey(TransducerConversionPanel.convertKey));
    await tester.pumpAndSettle();
    expect(
      find.text('Conversão exata: a mesma saída para toda palavra de entrada.'),
      findsOneWidget,
    );
    expect(find.text('Passos da construção'), findsOneWidget);
    expect(find.text('Abrir no espaço de trabalho de Moore'), findsOneWidget);
  });
}
