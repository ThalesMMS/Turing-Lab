import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turing_lab/core/algorithms/pda_simulator.dart';
import 'package:turing_lab/core/algorithms/tm_simulator.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/simulation_step.dart';
import 'package:turing_lab/core/models/state.dart' as formal;
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/tm_acceptance.dart';
import 'package:turing_lab/core/services/simulation_runner.dart';
import 'package:turing_lab/data/services/active_session_persistence_service.dart';
import 'package:turing_lab/injection/data_providers.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/providers/active_session_provider.dart';
import 'package:turing_lab/presentation/providers/tm_editor_provider.dart';
import 'package:turing_lab/presentation/widgets/tm/tape_drawer.dart';
import 'package:turing_lab/presentation/widgets/tm_simulation_panel.dart';
import 'package:vector_math/vector_math_64.dart';

// feature-localization-contract: tm-acceptance-preference
void main() {
  // feature-localization-surface: localized-preference-control
  // feature-localization-surface: localized-policy-explanations
  // feature-localization-surface: localized-valid-simulation
  // feature-localization-surface: production-session-persistence
  // feature-localization-surface: locale-switch-state-preservation
  // feature-localization-surface: formal-content-preservation
  // feature-localization-surface: semantic-code-preservation
  // feature-localization-surface: tape-and-result-preservation
  // feature-localization-surface: responsive-accessibility
  testWidgets(
    'TM policy, result, tape, and authored document survive EN/PT switching',
    (tester) async {
      final locale = ValueNotifier(const Locale('en'));
      final notifier = TMEditorNotifier()..setTm(_machine());
      final result = TMSimulationResult.success(
        inputString: 'β',
        steps: const [
          SimulationStep(
            currentState: 'UserState_Ω',
            activeStateIds: {'user-state'},
            remainingInput: '',
            tapeContents: 'β',
            headPosition: 0,
            stepNumber: 0,
          ),
          SimulationStep(
            currentState: 'Final_δ',
            activeStateIds: {'final-state'},
            remainingInput: '',
            tapeContents: 'β',
            headPosition: 0,
            stepNumber: 1,
            isAccepted: true,
          ),
        ],
        executionTime: Duration.zero,
        acceptancePolicy: TMAcceptancePolicy.finalStateOrHalting,
        acceptanceReason: TMAcceptanceReason.haltedOutsideFinalState,
      );
      final tapes = <TapeState>[];
      final harness = await _pumpPanel(
        tester,
        locale: locale,
        notifier: notifier,
        result: result,
        onTapeChanged: tapes.add,
      );

      final control = find.byKey(
        const ValueKey('tm-acceptance-policy-control'),
      );
      final semantics = tester.getSemantics(control);
      expect(semantics.label, contains('Turing machine acceptance policy'));
      expect(semantics.value, contains('Final state'));
      expect(tester.getSize(control).height, greaterThanOrEqualTo(48));
      expect(
        find.textContaining('Accept when a final state is entered.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Saved with this TM document'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await _tapVisible(tester, control);
      expect(find.text('Final state'), findsWidgets);
      expect(find.text('Halting'), findsOneWidget);
      expect(find.text('Final state or halting'), findsOneWidget);
      await tester.tap(find.text('Final state or halting').last);
      await tester.pumpAndSettle();
      expect(
        notifier.currentTm?.acceptancePolicy,
        TMAcceptancePolicy.finalStateOrHalting,
      );
      expect(
        notifier.currentTm?.toJson()['acceptancePolicy'],
        'finalStateOrHalting',
      );
      expect(
        find.textContaining(
          'Accept when a final state is entered or execution halts.',
        ),
        findsOneWidget,
      );

      final input = find.widgetWithText(TextField, 'Input String');
      await _scrollUntilVisible(tester, input);
      await tester.enterText(input, 'β');
      await _tapVisible(
        tester,
        find.widgetWithText(ElevatedButton, 'Simulate TM'),
      );

      expect(find.text('Accepted'), findsOneWidget);
      expect(
        find.text(
          'Policy: Final state or halting. '
          'Reason: halted outside a final state.',
        ),
        findsOneWidget,
      );
      expect(find.text('Simulation Steps:'), findsOneWidget);
      expect(find.textContaining('UserState_Ω'), findsOneWidget);
      expect(find.textContaining('β'), findsWidgets);
      expect(tapes, isNotEmpty);

      final documentBefore = notifier.currentTm!.toJson();
      final tapeBefore = tapes.last;
      final inputController = tester.widget<TextField>(input).controller!;
      final policyCodeBefore = result.acceptancePolicy.name;
      final reasonCodeBefore = result.acceptanceReason.name;

      locale.value = const Locale('pt', 'BR');
      await tester.pumpAndSettle();

      final portugueseSemantics = tester.getSemantics(control);
      expect(
        portugueseSemantics.label,
        contains('Política de aceitação da máquina de Turing'),
      );
      expect(portugueseSemantics.value, contains('Estado final ou parada'));
      await _tapVisible(tester, control);
      expect(find.text('Estado final'), findsOneWidget);
      expect(find.text('Parada'), findsOneWidget);
      expect(find.text('Estado final ou parada'), findsWidgets);
      await tester.tap(find.text('Estado final ou parada').last);
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          'Aceite quando um estado final for alcançado ou a execução parar.',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('Salva com este documento de MT'),
        findsOneWidget,
      );
      expect(find.text('Aceita'), findsOneWidget);
      expect(
        find.text(
          'Política: Estado final ou parada. '
          'Motivo: parou fora de um estado final.',
        ),
        findsOneWidget,
      );
      expect(find.text('Passos da simulação:'), findsOneWidget);
      expect(find.textContaining('UserState_Ω'), findsOneWidget);
      expect(inputController.text, 'β');
      expect(notifier.currentTm!.toJson(), documentBefore);
      expect(tapes.last.cells, tapeBefore.cells);
      expect(tapes.last.headPosition, tapeBefore.headPosition);
      expect(tapes.last.blankSymbol, '□');
      expect(result.acceptancePolicy.name, policyCodeBefore);
      expect(result.acceptanceReason.name, reasonCodeBefore);
      expect(find.text('Final state or halting'), findsNothing);

      locale.value = const Locale('pt');
      await tester.pumpAndSettle();
      expect(find.text('Estado final ou parada'), findsOneWidget);
      expect(notifier.currentTm!.toJson(), documentBefore);
      expect(inputController.text, 'β');

      await harness.container
          .read(activeSessionPersistenceProvider.notifier)
          .flush();
      final saved = await ActiveSessionPersistenceService(
        harness.preferences,
      ).loadSession();
      expect(
        saved?.tm?.acceptancePolicy,
        TMAcceptancePolicy.finalStateOrHalting,
      );
      expect(saved?.tm?.name, 'User TM Ω');
      expect(
        saved?.tm?.states.map((state) => state.label),
        containsAll(['UserState_Ω', 'Final_δ']),
      );
      expect(saved?.tm?.tapeAlphabet, containsAll(['β', '□']));
      expect(tester.takeException(), isNull);
    },
  );

  // feature-localization-surface: localized-bounded-outcome
  testWidgets('bounded TM result and policy reason are localized in PT-BR', (
    tester,
  ) async {
    final locale = ValueNotifier(const Locale('pt', 'BR'));
    final notifier = TMEditorNotifier()..setTm(_machine());
    await _pumpPanel(
      tester,
      locale: locale,
      notifier: notifier,
      result: TMSimulationResult.stepLimit(
        inputString: '',
        steps: const [],
        executionTime: Duration.zero,
        acceptancePolicy: TMAcceptancePolicy.finalState,
      ),
    );

    await _tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, 'Simular MT'),
    );

    expect(
      find.text('Limite de passos atingido; o resultado é inconclusivo'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Política: Estado final. Motivo: o limite de passos foi atingido.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Rejected'), findsNothing);
    expect(find.textContaining('Rejeitada'), findsNothing);
    expect(find.textContaining('Step limit'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

final class _Harness {
  const _Harness(this.container, this.preferences);

  final ProviderContainer container;
  final SharedPreferences preferences;
}

Future<_Harness> _pumpPanel(
  WidgetTester tester, {
  required ValueNotifier<Locale> locale,
  required TMEditorNotifier notifier,
  required TMSimulationResult result,
  ValueChanged<TapeState>? onTapeChanged,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(320, 700);
  addTearDown(locale.dispose);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  SharedPreferences.setMockInitialValues(const {});
  final preferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      tmEditorProvider.overrideWith((_) => notifier),
    ],
  );
  addTearDown(container.dispose);
  await container.read(activeSessionPersistenceProvider).restoreComplete;

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: ValueListenableBuilder<Locale>(
        valueListenable: locale,
        builder: (context, value, _) => MaterialApp(
          locale: value,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 700,
              child: TMSimulationPanel(
                simulationRunner: SimulationRunner(
                  backendOverride: _CompletedSimulationBackend(result),
                ),
                onTapeChanged: onTapeChanged,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return _Harness(container, preferences);
}

Future<void> _tapVisible(WidgetTester tester, Finder target) async {
  await _scrollUntilVisible(tester, target);
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target.hitTestable());
  await tester.pumpAndSettle();
}

Future<void> _scrollUntilVisible(WidgetTester tester, Finder target) async {
  if (target.evaluate().isNotEmpty) {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
  }
  for (
    var attempt = 0;
    attempt < 16 && target.hitTestable().evaluate().isEmpty;
    attempt++
  ) {
    final scrollable = find.ancestor(
      of: target,
      matching: find.byType(Scrollable),
    );
    if (scrollable.evaluate().isEmpty) break;
    await tester.drag(scrollable.first, const Offset(0, -180));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

TM _machine() {
  final initial = formal.State(
    id: 'user-state',
    label: 'UserState_Ω',
    position: Vector2.zero(),
    isInitial: true,
  );
  final accepting = formal.State(
    id: 'final-state',
    label: 'Final_δ',
    position: Vector2(120, 0),
    isAccepting: true,
  );
  final now = DateTime.utc(2026, 8, 26);
  return TM(
    id: 'user-tm',
    name: 'User TM Ω',
    states: {initial, accepting},
    transitions: const {},
    alphabet: const {'β'},
    initialState: initial,
    acceptingStates: {accepting},
    created: now,
    modified: now,
    bounds: const math.Rectangle(0, 0, 320, 700),
    tapeAlphabet: const {'β', '□'},
    blankSymbol: '□',
  );
}

final class _CompletedSimulationBackend implements SimulationRunnerBackend {
  const _CompletedSimulationBackend(this.result);

  final TMSimulationResult result;

  @override
  SimulationTask<PDASimulationResult> runPda(
    PDA pda,
    String inputString, {
    required bool stepByStep,
    required Duration timeout,
  }) {
    throw UnimplementedError();
  }

  @override
  SimulationTask<TMSimulationResult> runTm(
    TM tm,
    String inputString, {
    required bool stepByStep,
    required Duration timeout,
  }) => _CompletedTask(classifyTmResult(result));
}

final class _CompletedTask<T> implements SimulationTask<T> {
  const _CompletedTask(this.value);

  final SimulationOutcome<T> value;

  @override
  Future<SimulationOutcome<T>> get outcome async => value;

  @override
  void cancel() {}
}
