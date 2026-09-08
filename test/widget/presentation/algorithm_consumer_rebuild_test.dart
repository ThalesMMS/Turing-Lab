//
//  algorithm_consumer_rebuild_test.dart
//  Turing Lab
//
//  Measures how many times consumers that do not depend on an algorithm
//  operation are rebuilt while `automatonAlgorithmProvider` emits during
//  that operation. The counts are recorded in #427; the assertions keep the
//  unrelated consumers at zero rebuilds.
//

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/injection/data_providers.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/pages/fsa_page.dart';
import 'package:turing_lab/presentation/pages/regex_page.dart';
import 'package:turing_lab/presentation/providers/automaton_algorithm_provider.dart';
import 'package:turing_lab/presentation/providers/automaton_state_provider.dart';
import 'package:turing_lab/presentation/providers/regex_editor_provider.dart';
import 'package:turing_lab/presentation/providers/workspace_quick_actions_provider.dart';
import 'package:turing_lab/presentation/widgets/simulation_panel.dart';
import 'package:turing_lab/presentation/widgets/workspace_quick_actions_bar.dart';
import 'package:vector_math/vector_math_64.dart';

import '../../support/workspace_dock_helpers.dart';
import 'examples_test_helpers.dart';

FSA _twoStateDfa() {
  final q0 = automaton_state.State(
    id: 'q0',
    label: 'q0',
    position: Vector2(100, 100),
    isInitial: true,
    isAccepting: false,
  );
  final q1 = automaton_state.State(
    id: 'q1',
    label: 'q1',
    position: Vector2(300, 100),
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
      FSATransition.deterministic(
        id: 't1',
        fromState: q1,
        toState: q1,
        symbol: 'a',
      ),
    },
    alphabet: const {'a'},
    initialState: q0,
    acceptingStates: {q1},
    created: DateTime(2026),
    modified: DateTime(2026),
    bounds: const math.Rectangle(0, 0, 400, 300),
  );
}

Future<ProviderContainer> _pumpPage(
  WidgetTester tester, {
  required Widget page,
  required WorkspaceTab tab,
  required Size size,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      examplesRepositoryProvider.overrideWithValue(TestExamplesRepository()),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: ThemeData(platform: TargetPlatform.macOS),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          appBar: AppBar(
            leading: WorkspaceQuickActionsBar(tab: tab),
            leadingWidth: 144,
          ),
          body: page,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
  return container;
}

/// Counts distinct algorithm-state emissions while [operation] runs.
Future<int> _emissionsDuring(
  ProviderContainer container,
  Future<void> Function() operation,
) async {
  var emissions = 0;
  final subscription = container.listen<AlgorithmOperationState>(
    automatonAlgorithmProvider,
    (_, _) => emissions++,
  );
  await operation();
  subscription.close();
  return emissions;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'FSA simulation panel does not rebuild for equivalence or minimization '
    'step emissions that leave its inputs unchanged',
    (tester) async {
      final container = await _pumpPage(
        tester,
        page: const FSAPage(),
        tab: WorkspaceTab.fsa,
        size: const Size(1440, 900),
      );
      final dfa = _twoStateDfa();
      container.read(automatonStateProvider.notifier).replaceAutomaton(dfa);
      await tester.pump();
      await openWorkspaceSimulationPanel(tester);
      expect(find.byType(SimulationPanel), findsOneWidget);

      SimulationPanel panel() =>
          tester.widget<SimulationPanel>(find.byType(SimulationPanel));
      final before = panel();

      // Scenario 1: language equivalence against an identical machine.
      final equivalenceEmissions = await _emissionsDuring(container, () async {
        await container
            .read(automatonAlgorithmProvider.notifier)
            .compareEquivalence(dfa);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
      });
      expect(equivalenceEmissions, greaterThanOrEqualTo(2));
      expect(
        container.read(automatonAlgorithmProvider).equivalenceResult,
        isTrue,
      );
      expect(
        identical(before, panel()),
        isTrue,
        reason:
            'The simulation panel only depends on regexResult; '
            '$equivalenceEmissions equivalence emissions must not rebuild it.',
      );

      // Scenario 2: clearing results emits a state whose regexResult is
      // unchanged (null), so the panel must stay put.
      final clearBefore = panel();
      final clearEmissions = await _emissionsDuring(container, () async {
        container
            .read(automatonAlgorithmProvider.notifier)
            .clearAlgorithmResults();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
      });
      expect(clearEmissions, 1);
      expect(
        identical(clearBefore, panel()),
        isTrue,
        reason: 'A clear emission must not rebuild the simulation panel.',
      );

      // Minimization with steps replaces the document, which the panel
      // legitimately depends on (determinism, labels, batch executor), so a
      // rebuild here is expected and documents the boundary.
      final minimizeBefore = panel();
      await container
          .read(automatonAlgorithmProvider.notifier)
          .minimizeDfaWithSteps();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(identical(minimizeBefore, panel()), isFalse);

      // Scenario 3: FA to regex sets regexResult, which the panel shows, so
      // exactly this operation is allowed to rebuild it.
      final regexBefore = panel();
      await container
          .read(automatonAlgorithmProvider.notifier)
          .convertFaToRegex();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(identical(regexBefore, panel()), isFalse);
      expect(panel().regexResult, isNotNull);
    },
  );

  testWidgets('Regex page rebuilds only when the FA-to-regex results change', (
    tester,
  ) async {
    final container = await _pumpPage(
      tester,
      page: const RegexPage(),
      tab: WorkspaceTab.regex,
      size: const Size(430, 1200),
    );
    container.read(regexEditorProvider.notifier).validateRegex('a*');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    Widget section() =>
        tester.widget(find.byKey(const ValueKey('regex_input_field')));
    final before = section();

    // Regex to NFA emits loading and step results the page never shows.
    final emissions = await _emissionsDuring(container, () async {
      await container
          .read(automatonAlgorithmProvider.notifier)
          .convertRegexToNfaWithSteps('a*');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
    });
    expect(emissions, greaterThanOrEqualTo(2));
    expect(
      identical(before, section()),
      isTrue,
      reason:
          '$emissions regex-to-NFA emissions must not rebuild the regex '
          'page, which only shows FA-to-regex results.',
    );

    // FA to regex changes rawRegexResult, so the page must rebuild.
    final regexBefore = section();
    await container
        .read(automatonAlgorithmProvider.notifier)
        .convertFaToRegex();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(
      container.read(automatonAlgorithmProvider).rawRegexResult,
      isNotNull,
    );
    expect(identical(regexBefore, section()), isFalse);
  });
}
