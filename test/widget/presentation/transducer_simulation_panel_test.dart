import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/transducers/transducers.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/l10n/app_localizations_resolver.dart';
import 'package:turing_lab/l10n/app_localizations_structured_messages.dart';
import 'package:turing_lab/presentation/transducers/graphview_transducer_canvas_controller.dart';
import 'package:turing_lab/presentation/transducers/mealy_workspace_definition.dart';
import 'package:turing_lab/presentation/transducers/transducer_editor_state.dart';
import 'package:turing_lab/presentation/transducers/transducer_simulation_panel.dart';

void main() {
  testWidgets('invalid step limit stays visible and receives focus', (
    tester,
  ) async {
    await tester.pumpWidget(const _App(child: _SimulationHarness()));

    await tester.enterText(
      find.byKey(const Key('transducer-simulation-max-steps')),
      '-1',
    );
    await tester.tap(find.byKey(const Key('transducer-run')));
    await tester.pump();

    expect(find.text('Enter zero or a positive whole number.'), findsOneWidget);
    final field = tester.widget<TextField>(
      find.byKey(const Key('transducer-simulation-max-steps')),
    );
    expect(field.focusNode!.hasFocus, isTrue);
  });

  testWidgets('configured bound produces a typed bounded outcome', (
    tester,
  ) async {
    await tester.pumpWidget(const _App(child: _SimulationHarness()));
    await tester.enterText(
      find.byKey(const Key('transducer-simulation-input')),
      'a\na',
    );
    await tester.enterText(
      find.byKey(const Key('transducer-simulation-max-steps')),
      '1',
    );

    await tester.tap(find.byKey(const Key('transducer-run')));
    await tester.pumpAndSettle();

    final state = tester.state<_SimulationHarnessState>(
      find.byType(_SimulationHarness),
    );
    expect(state.notifier.state.lastExecution, isA<TransducerBounded>());
    expect(
      find.text(
        'The simulation stopped at the one-step limit after processing one input token.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('transducer-simulation-output')), findsOne);
  });

  testWidgets('same structured outcome rerenders in the active locale', (
    tester,
  ) async {
    final outcome = TransducerBounded(
      input: TransducerInputWord.fromValues(const ['a', 'a']),
      output: TransducerOutputWord.fromValues(const ['x']),
      trace: const [],
      processedInputCount: 1,
      maxSteps: 1,
    );
    final summary = _OutcomeSummary(outcome);

    await tester.pumpWidget(_App(locale: const Locale('en'), child: summary));
    expect(
      find.text(
        'The simulation stopped at the one-step limit after processing one input token.',
      ),
      findsOneWidget,
    );

    await tester.pumpWidget(_App(locale: const Locale('pt'), child: summary));
    expect(
      find.text(
        'A simulação parou no limite de um passo após processar um token de entrada.',
      ),
      findsOneWidget,
    );
    expect(identical(summary.outcome, outcome), isTrue);
  });

  testWidgets('long cooperative run can be cancelled from the panel', (
    tester,
  ) async {
    await tester.pumpWidget(const _App(child: _SimulationHarness()));
    await tester.enterText(
      find.byKey(const Key('transducer-simulation-input')),
      List.filled(4000, 'a').join('\n'),
    );

    await tester.tap(find.byKey(const Key('transducer-run')));
    await tester.pump();
    expect(find.byKey(const Key('transducer-cancel-run')), findsOneWidget);
    await tester.tap(find.byKey(const Key('transducer-cancel-run')));
    await tester.pumpAndSettle();

    final state = tester.state<_SimulationHarnessState>(
      find.byType(_SimulationHarness),
    );
    expect(state.notifier.state.lastExecution, isA<TransducerCancelled>());
  });
}

final class _SimulationHarness extends StatefulWidget {
  const _SimulationHarness();

  @override
  State<_SimulationHarness> createState() => _SimulationHarnessState();
}

final class _SimulationHarnessState extends State<_SimulationHarness> {
  late final TransducerEditorNotifier<MealyMachine> notifier;
  late final GraphViewTransducerCanvasController<MealyMachine> controller;
  late final VoidCallback removeListener;

  @override
  void initState() {
    super.initState();
    notifier = TransducerEditorNotifier(_machine());
    controller = GraphViewTransducerCanvasController(
      notifier: notifier,
      definition: mealyWorkspaceDefinition,
    );
    controller.synchronize(notifier.state.document);
    removeListener = notifier.addListener((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    removeListener();
    controller.dispose();
    notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 360,
    height: 640,
    child: TransducerSimulationPanel(
      state: notifier.state,
      notifier: notifier,
      controller: controller,
      definition: mealyWorkspaceDefinition,
    ),
  );
}

MealyMachine _machine() => MealyMachine(
  id: const TransducerMachineId('simulation-test'),
  name: 'Simulation test',
  revision: const TransducerRevision(0),
  inputAlphabet: {const TransducerInputSymbol('a')},
  outputAlphabet: {const TransducerOutputSymbol('x')},
  states: const [
    MealyState(
      id: TransducerStateId('q0'),
      label: 'q0',
      position: TransducerPoint(0, 0),
      isInitial: true,
    ),
  ],
  transitions: [
    MealyTransition(
      id: const TransducerTransitionId('loop'),
      from: const TransducerStateId('q0'),
      to: const TransducerStateId('q0'),
      input: const TransducerInputSymbol('a'),
      output: TransducerOutputWord.fromValues(const ['x']),
    ),
  ],
);

final class _App extends StatelessWidget {
  const _App({required this.child, this.locale});

  final Widget child;
  final Locale? locale;

  @override
  Widget build(BuildContext context) => MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

final class _OutcomeSummary extends StatelessWidget {
  const _OutcomeSummary(this.outcome);

  final TransducerExecutionOutcome outcome;

  @override
  Widget build(BuildContext context) => Text(
    appLocalizationsOf(
      context,
    ).resolveStructuredMessage(outcome.structuredMessage),
  );
}
