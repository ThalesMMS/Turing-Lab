import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/core/models/simulation_result.dart';
import 'package:turing_lab/core/models/simulation_step.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/common/algorithm_button.dart';
import 'package:turing_lab/presentation/widgets/grammar_simulation_panel.dart';
import 'package:turing_lab/presentation/widgets/algorithm_panel.dart';
import 'package:turing_lab/presentation/widgets/pda_simulation_panel.dart';
import 'package:turing_lab/presentation/widgets/simulation_panel.dart';
import 'package:turing_lab/presentation/widgets/tm_simulation_panel.dart';
import 'package:turing_lab/presentation/widgets/trace_viewers/base_trace_viewer.dart';

void main() {
  testWidgets('localizes the FSA simulation surface in Portuguese', (
    tester,
  ) async {
    await _pumpPortuguese(tester, SimulationPanel(onSimulate: (_) {}));

    expect(find.text('Simulação'), findsOneWidget);
    expect(find.text('Cadeia de entrada'), findsOneWidget);
    expect(find.text('Simular'), findsOneWidget);
  });

  testWidgets('localizes the PDA simulation surface in Portuguese', (
    tester,
  ) async {
    await _pumpPortuguese(tester, const PDASimulationPanel());

    expect(find.text('Simulação de AP'), findsOneWidget);
    expect(find.text('Entrada da simulação'), findsOneWidget);
    expect(find.text('Simular AP'), findsOneWidget);
  });

  testWidgets('localizes the TM simulation surface in Portuguese', (
    tester,
  ) async {
    await _pumpPortuguese(tester, const TMSimulationPanel());

    expect(find.text('Simulação de MT'), findsOneWidget);
    expect(find.text('Entrada da simulação'), findsOneWidget);
    expect(find.text('Simular MT'), findsOneWidget);
  });

  testWidgets('localizes the Grammar parser surface in Portuguese', (
    tester,
  ) async {
    await _pumpPortuguese(tester, const GrammarSimulationPanel());

    expect(find.text('Analisador de gramática'), findsOneWidget);
    expect(find.text('Algoritmo de análise'), findsOneWidget);
    expect(find.text('Analisar cadeia'), findsOneWidget);
  });

  testWidgets('localizes a Regex algorithm action in Portuguese', (
    tester,
  ) async {
    await _pumpPortuguese(
      tester,
      const AlgorithmButton(
        title: 'Regex to NFA',
        description: 'Convert a regular expression to an automaton',
        icon: Icons.transform,
      ),
    );

    expect(find.text('Expressão regular para AFN'), findsOneWidget);
  });

  testWidgets('localizes the FSA algorithm controls in Portuguese', (
    tester,
  ) async {
    await _pumpPortuguese(tester, const AlgorithmPanel());

    expect(find.text('Modo passo a passo'), findsOneWidget);
    expect(
      find.text(
        'Mostrar etapas detalhadas da execução do algoritmo com explicações',
      ),
      findsOneWidget,
    );
    expect(find.text('Praticar AF para expressão regular'), findsOneWidget);
    expect(find.text('Praticar AF para gramática regular'), findsOneWidget);
  });

  testWidgets('localizes indirect left-recursion removal in Portuguese', (
    tester,
  ) async {
    await _pumpPortuguese(
      tester,
      const AlgorithmButton(
        title: 'Remove Left Recursion',
        description: 'Eliminate direct and indirect left recursion',
        icon: Icons.transform,
      ),
    );

    expect(find.text('Remover recursão à esquerda'), findsOneWidget);
    expect(
      find.text('Eliminar recursão direta e indireta à esquerda'),
      findsOneWidget,
    );
  });

  testWidgets('localizes the bounded TM time-profile action in Portuguese', (
    tester,
  ) async {
    await _pumpPortuguese(
      tester,
      const AlgorithmButton(
        title: 'Time Profile',
        description: 'Measure transition steps by input length within bounds',
        icon: Icons.timer,
      ),
    );

    expect(find.text('Perfil de tempo'), findsOneWidget);
    expect(
      find.text(
        'Meça passos de transição por comprimento de entrada dentro dos limites',
      ),
      findsOneWidget,
    );
  });

  testWidgets('localizes trace navigation and semantics in Portuguese', (
    tester,
  ) async {
    final result = SimulationResult.success(
      inputString: 'a',
      steps: const [
        SimulationStep(currentState: 'q0', remainingInput: 'a', stepNumber: 0),
        SimulationStep(currentState: 'q1', remainingInput: '', stepNumber: 1),
      ],
      executionTime: Duration.zero,
    );
    await _pumpPortuguese(
      tester,
      BaseTraceViewer(
        result: result,
        title: 'Trace',
        detailsBuilder: (_, __, ___) => null,
        buildStepLine: (step, index) => Text(step.currentState),
      ),
    );

    expect(find.text('Linha do tempo'), findsOneWidget);
    expect(find.text('Passo 1 de 2'), findsOneWidget);
    expect(find.byTooltip('Próximo passo'), findsOneWidget);
  });

  testWidgets('formats trace counters in Portuguese', (tester) async {
    final result = SimulationResult.success(
      inputString: '',
      steps: List<SimulationStep>.generate(
        1234,
        (index) => SimulationStep(
          currentState: 'q$index',
          remainingInput: '',
          stepNumber: index,
        ),
      ),
      executionTime: Duration.zero,
    );
    await _pumpPortuguese(
      tester,
      BaseTraceViewer(
        result: result,
        title: 'Trace',
        detailsBuilder: (_, __, ___) => null,
        buildStepLine: (step, index) => Text(step.currentState),
      ),
    );

    expect(find.text('1 / 1.234'), findsOneWidget);
    expect(find.text('1 / 1234'), findsNothing);
  });
}

Future<void> _pumpPortuguese(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
