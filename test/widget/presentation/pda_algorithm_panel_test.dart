import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/models/pda_acceptance_mode.dart';
import 'package:turing_lab/core/models/pda_transition.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/core/models/simulation_highlight.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/core/models/transition.dart';
import 'package:turing_lab/core/services/canvas_highlight_coordinator.dart';
import 'package:turing_lab/core/services/highlight_channel.dart';
import 'package:turing_lab/core/result.dart';
import 'package:turing_lab/data/data_sources/examples_asset_data_source.dart';
import 'package:turing_lab/presentation/providers/pda_editor_provider.dart';
import 'package:turing_lab/presentation/providers/pda_simulation_provider.dart'
    show PDASimulationNotifier, pdaSimulationProvider;
import 'package:turing_lab/presentation/providers/grammar_provider.dart';
import 'package:turing_lab/presentation/providers/home_navigation_provider.dart';
import 'package:turing_lab/presentation/widgets/common/algorithm_button.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/l10n/app_localizations_en.dart';
import 'package:turing_lab/l10n/app_localizations_pt.dart';
import 'package:turing_lab/l10n/app_localizations_workflows.dart';
import 'package:turing_lab/presentation/widgets/pda_algorithm_panel.dart';
import 'package:turing_lab/presentation/widgets/file_operations_panel.dart';

class _FakePdaExamplesDataSource extends ExamplesAssetDataSource {
  _FakePdaExamplesDataSource() : example = _buildPdaExample();

  final AssetExample<PDA> example;

  @override
  Future<ListResult<AssetExample<PDA>>> loadAllTypedPdaExamples() async {
    return Success([example]);
  }

  @override
  Future<Result<AssetExample<PDA>>> loadTypedPdaExample(String name) async {
    return Success(example);
  }
}

class _RecordingHighlightChannel implements HighlightChannel {
  final List<SimulationHighlight?> events = <SimulationHighlight?>[];

  @override
  void clear() => events.add(null);

  @override
  void send(SimulationHighlight highlight) => events.add(highlight);
}

class _PdaPanelHarness {
  const _PdaPanelHarness({
    required this.notifier,
    required this.simulationNotifier,
    required this.output,
    required this.coordinator,
    required this.appliedPdas,
  });

  final PDAEditorNotifier notifier;
  final PDASimulationNotifier simulationNotifier;
  final _RecordingHighlightChannel output;
  final CanvasHighlightCoordinator coordinator;
  final List<PDA> appliedPdas;
}

Future<_PdaPanelHarness> _pumpPdaAlgorithmPanel(
  WidgetTester tester, {
  PDA? initialPda,
  PDAAcceptanceMode acceptanceMode = PDAAcceptanceMode.finalState,
  Locale locale = const Locale('en'),
}) async {
  final pdaNotifier = PDAEditorNotifier();
  if (initialPda != null) {
    pdaNotifier.setPda(initialPda);
  }
  final examplesDataSource = _FakePdaExamplesDataSource();
  final simulationNotifier = PDASimulationNotifier()
    ..setAcceptanceMode(acceptanceMode);
  final appliedPdas = <PDA>[];
  final output = _RecordingHighlightChannel();
  final coordinator = CanvasHighlightCoordinator(
    target: CanvasHighlightTarget(
      kind: AutomatonSurfaceKind.pda,
      surface: Object(),
      documentId: initialPda?.id,
      revision: 0,
    ),
    output: output,
  );
  addTearDown(coordinator.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pdaEditorProvider.overrideWith((ref) => pdaNotifier),
        pdaSimulationProvider.overrideWith((ref) => simulationNotifier),
        canvasHighlightCoordinatorProvider.overrideWithValue(coordinator),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PDAAlgorithmPanel(
            useExpanded: false,
            examplesDataSource: examplesDataSource,
            onApplyPda: (pda) {
              appliedPdas.add(pda);
              pdaNotifier.setPda(pda);
            },
          ),
        ),
      ),
    ),
  );

  await tester.pump();
  final localizedExampleName = locale.languageCode == 'pt'
      ? AppLocalizationsPt().localizedExampleName('APD - Palíndromo')
      : AppLocalizationsEn().localizedExampleName('APD - Palíndromo');
  await _pumpUntilFound(tester, find.text(localizedExampleName));

  return _PdaPanelHarness(
    notifier: pdaNotifier,
    simulationNotifier: simulationNotifier,
    output: output,
    coordinator: coordinator,
    appliedPdas: appliedPdas,
  );
}

AssetExample<PDA> _buildPdaExample() {
  final start = automaton_state.State(
    id: 'pda/state:start',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );
  final accept = automaton_state.State(
    id: 'pda/state:accept',
    label: 'q1',
    position: Vector2(120, 0),
    isAccepting: true,
  );
  final transition = PDATransition(
    id: 't0',
    fromState: start,
    toState: accept,
    label: 'a,Z/Z',
    type: TransitionType.deterministic,
    inputSymbol: 'a',
    popSymbol: 'Z',
    pushSymbol: 'Z',
  );
  final pda = PDA(
    id: 'pda-palindrome',
    name: 'APD - Palíndromo',
    states: {start, accept},
    transitions: {transition},
    alphabet: const {'a'},
    initialState: start,
    acceptingStates: {accept},
    created: DateTime(2026),
    modified: DateTime(2026),
    bounds: const math.Rectangle(0, 0, 400, 300),
    stackAlphabet: const {'Z'},
    initialStackSymbol: 'Z',
  );

  return AssetExample<PDA>(
    name: pda.name,
    description: 'Fake PDA example for widget tests',
    category: ExampleCategory.pda,
    difficultyLevel: DifficultyLevel.easy,
    complexityLevel: ExampleComplexityLevel.low,
    tags: const ['test'],
    payload: pda,
  );
}

PDA _buildNondeterministicPda() {
  final start = automaton_state.State(
    id: 'pda/state:start',
    label: 'Displayed start',
    position: Vector2.zero(),
    isInitial: true,
  );
  final first = automaton_state.State(
    id: 'pda/state:first',
    label: 'Displayed first',
    position: Vector2(120, 0),
    isAccepting: true,
  );
  final second = automaton_state.State(
    id: 'pda/state:second',
    label: 'Displayed second',
    position: Vector2(120, 120),
  );
  final firstTransition = PDATransition(
    id: 'opaque/pda-edge-a',
    fromState: start,
    toState: first,
    label: 'a, Z/Z',
    inputSymbol: 'a',
    popSymbol: 'Z',
    pushSymbol: 'Z',
  );
  // Whitespace is intentional: transition identifiers must not be trimmed.
  final secondTransition = PDATransition(
    id: ' opaque/pda-edge-b ',
    fromState: start,
    toState: second,
    label: 'a, Z/A',
    inputSymbol: 'a',
    popSymbol: 'Z',
    pushSymbol: 'A',
  );
  return PDA(
    id: 'pda-nondeterministic',
    name: 'Nondeterministic PDA',
    states: {start, first, second},
    transitions: {firstTransition, secondTransition},
    alphabet: const {'a'},
    initialState: start,
    acceptingStates: {first},
    created: DateTime(2026),
    modified: DateTime(2026),
    bounds: const math.Rectangle(0, 0, 400, 300),
    stackAlphabet: const {'Z', 'A'},
    initialStackSymbol: 'Z',
  );
}

PDA _buildLambdaPopPda() {
  final start = automaton_state.State(
    id: 'normalization-start',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );
  final accept = automaton_state.State(
    id: 'normalization-accept',
    label: 'q1',
    position: Vector2(120, 0),
    isAccepting: true,
  );
  final transition = PDATransition(
    id: 'lambda-pop',
    fromState: start,
    toState: accept,
    label: 'a, ε/A',
    inputSymbol: 'a',
    popSymbol: '',
    pushSymbol: 'A',
    pushSymbols: const ['A'],
    isLambdaPop: true,
  );
  return PDA(
    id: 'normalization-pda',
    name: 'Normalization PDA',
    states: {start, accept},
    transitions: {transition},
    alphabet: const {'a'},
    initialState: start,
    acceptingStates: {accept},
    created: DateTime(2026),
    modified: DateTime(2026),
    bounds: const math.Rectangle(0, 0, 400, 300),
    stackAlphabet: const {'Z', 'A'},
    initialStackSymbol: 'Z',
  );
}

PDA _buildReduciblePda() {
  final start = automaton_state.State(
    id: 'simplify-start',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );
  final accept = automaton_state.State(
    id: 'simplify-accept',
    label: 'q1',
    position: Vector2(120, 0),
    isAccepting: true,
  );
  final unreachable = automaton_state.State(
    id: 'simplify-unreachable',
    label: 'unused',
    position: Vector2(240, 0),
  );
  final transition = PDATransition(
    id: 'simplify-transition',
    fromState: start,
    toState: accept,
    label: 'a, Z/Z',
    inputSymbol: 'a',
    popSymbol: 'Z',
    pushSymbol: 'Z',
  );
  return PDA(
    id: 'simplify-pda',
    name: 'Simplify PDA',
    states: {start, accept, unreachable},
    transitions: {transition},
    alphabet: const {'a'},
    initialState: start,
    acceptingStates: {accept},
    created: DateTime(2026),
    modified: DateTime(2026),
    bounds: const math.Rectangle(0, 0, 400, 300),
    stackAlphabet: const {'Z'},
    initialStackSymbol: 'Z',
  );
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 80; attempt++) {
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
  final visibleText = tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => text.data)
      .whereType<String>()
      .join(' | ');
  fail('Timed out waiting for $finder. Visible text: $visibleText');
}

Future<void> _pumpUntilHighlightEvent(
  WidgetTester tester,
  _RecordingHighlightChannel output,
  int previousEventCount,
) async {
  for (var attempt = 0; attempt < 80; attempt++) {
    if (output.events.length > previousEventCount) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
  fail('Timed out waiting for an analysis highlight event.');
}

Future<void> _pumpUntilPdaLoaded(
  WidgetTester tester,
  PDAEditorNotifier pdaNotifier,
) async {
  for (var attempt = 0; attempt < 80; attempt++) {
    if (pdaNotifier.state.pda != null) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
  fail('Timed out waiting for PDA example to load');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('hosts generic PDA interoperability operations', (tester) async {
    final pda = _buildPdaExample().payload;
    await _pumpPdaAlgorithmPanel(tester, initialPda: pda);

    final panel = tester.widget<FileOperationsPanel>(
      find.byType(FileOperationsPanel),
    );
    expect(panel.interoperability?.systemKey, DefaultFormalSystemIds.pda);
    expect(panel.interoperability?.currentDocument?.document, same(pda));
    expect(
      find.byKey(const ValueKey<String>('interoperability_import_document')),
      findsOneWidget,
    );
    expect(find.text('Load JFLAP'), findsNothing);
  });

  testWidgets('offers PDA import before a document exists', (tester) async {
    await _pumpPdaAlgorithmPanel(tester);

    final panel = tester.widget<FileOperationsPanel>(
      find.byType(FileOperationsPanel),
    );
    expect(panel.interoperability?.systemKey, DefaultFormalSystemIds.pda);
    expect(panel.interoperability?.currentDocument, isNull);
    expect(
      find.byKey(const ValueKey<String>('interoperability_import_document')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('interoperability_export_jflap-xml')),
      findsNothing,
    );
  });

  testWidgets('shows empty results before running an analysis', (tester) async {
    await _pumpPdaAlgorithmPanel(tester);

    expect(find.text('No analysis results yet'), findsOneWidget);
    expect(
      find.text('Select an algorithm above to analyze your PDA'),
      findsOneWidget,
    );
  });

  testWidgets('renders PDA actions through AlgorithmButton', (tester) async {
    await _pumpPdaAlgorithmPanel(tester);

    expect(find.byType(AlgorithmButton), findsNWidgets(6));
    expect(find.text('Convert to CFG'), findsOneWidget);
    expect(find.text('Simplify PDA'), findsOneWidget);
    expect(find.text('Check Determinism'), findsOneWidget);
    expect(find.text('Find Reachable States'), findsOneWidget);
    expect(find.text('Language Analysis'), findsOneWidget);
    expect(find.text('Stack Operations'), findsOneWidget);
  });

  testWidgets('proves non-emptiness and opens the shortest witness trace', (
    tester,
  ) async {
    final pda = _buildPdaExample().payload;
    final harness = await _pumpPdaAlgorithmPanel(tester, initialPda: pda);

    await tester.ensureVisible(find.text('Language Analysis'));
    await tester.tap(find.text('Language Analysis'));
    await _pumpUntilFound(
      tester,
      find.textContaining('Language is non-empty (proved).'),
    );

    expect(find.textContaining('Shortest witness: a'), findsOneWidget);
    expect(find.textContaining('Sample accepted strings'), findsNothing);
    await tester.ensureVisible(find.text('Open witness in Simulator'));
    await tester.tap(find.text('Open witness in Simulator'));
    await tester.pump();

    final simulation = harness.simulationNotifier.state;
    expect(simulation.pda, same(pda));
    expect(simulation.lastInput, 'a');
    expect(simulation.stepByStep, isTrue);
    expect(simulation.result?.accepted, isTrue);
    expect(simulation.result?.steps, isNotEmpty);
  });

  testWidgets('PDA action still reports missing editor PDA', (tester) async {
    await _pumpPdaAlgorithmPanel(tester);

    await tester.ensureVisible(find.text('Convert to CFG'));
    await tester.pump();

    await tester.tap(find.text('Convert to CFG'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.text('Draw a PDA before converting to a grammar.'),
      findsOneWidget,
    );
  });

  testWidgets('PDA to CFG opens the generated grammar in its workspace', (
    tester,
  ) async {
    await _pumpPdaAlgorithmPanel(
      tester,
      initialPda: _buildPdaExample().payload,
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(PDAAlgorithmPanel)),
      listen: false,
    );

    await tester.ensureVisible(find.text('Convert to CFG'));
    await tester.tap(find.text('Convert to CFG'));
    await _pumpUntilFound(tester, find.text('Generated Grammar'));

    expect(container.read(grammarProvider).productions, isNotEmpty);
    expect(
      container.read(homeNavigationProvider),
      HomeNavigationNotifier.grammarIndex,
    );
  });

  testWidgets('PDA to CFG conversion summary is localized in Portuguese', (
    tester,
  ) async {
    await _pumpPdaAlgorithmPanel(
      tester,
      initialPda: _buildPdaExample().payload,
      locale: const Locale('pt'),
    );

    await tester.ensureVisible(find.text('Converter para GLC'));
    await tester.tap(find.text('Converter para GLC'));
    await _pumpUntilFound(tester, find.text('Gramática gerada'));

    expect(find.textContaining('A gramática gerada possui'), findsOneWidget);
    expect(find.textContaining('GLC gerada a partir do AP'), findsOneWidget);
    expect(find.textContaining('Start productions:'), findsNothing);
    expect(find.textContaining('Generated grammar has'), findsNothing);
  });

  testWidgets(
    'PDA to CFG conversion stays usable on a narrow Portuguese viewport',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpPdaAlgorithmPanel(
        tester,
        initialPda: _buildPdaExample().payload,
        locale: const Locale('pt'),
      );

      await tester.ensureVisible(find.text('Converter para GLC'));
      await tester.tap(find.text('Converter para GLC'));
      await _pumpUntilFound(tester, find.text('Gramática gerada'));

      expect(find.textContaining('A gramática gerada possui'), findsOneWidget);
      expect(find.textContaining('GLC gerada a partir do AP'), findsOneWidget);
      expect(find.textContaining('[q0, Z, q1]'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('PDA to CFG cancel preserves the loaded grammar', (tester) async {
    await _pumpPdaAlgorithmPanel(
      tester,
      initialPda: _buildPdaExample().payload,
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(PDAAlgorithmPanel)),
      listen: false,
    );
    const loadedProduction = Production(
      id: 'loaded-production',
      leftSide: ['S'],
      rightSide: ['b'],
    );
    final loadedGrammar = Grammar(
      id: 'loaded-grammar',
      name: 'Loaded grammar',
      terminals: const {'b'},
      nonterminals: const {'S'},
      startSymbol: 'S',
      productions: {loadedProduction},
      type: GrammarType.regular,
      created: DateTime(2026),
      modified: DateTime(2026),
    );
    container.read(grammarProvider.notifier).applyGrammar(loadedGrammar);
    await tester.pump();

    await tester.ensureVisible(find.text('Convert to CFG'));
    await tester.tap(find.text('Convert to CFG'));
    await tester.pumpAndSettle();

    expect(
      find.text('A grammar is already loaded. Do you want to replace it?'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(container.read(grammarProvider).productions, [loadedProduction]);
    expect(
      container.read(homeNavigationProvider),
      HomeNavigationNotifier.fsaIndex,
    );
  });

  testWidgets('previews normalization and applies it only after confirmation', (
    tester,
  ) async {
    final source = _buildLambdaPopPda();
    final harness = await _pumpPdaAlgorithmPanel(tester, initialPda: source);

    await tester.ensureVisible(find.text('Convert to CFG'));
    await tester.tap(find.text('Convert to CFG'));
    await _pumpUntilFound(tester, find.text('Review PDA normalization'));

    expect(harness.notifier.currentPda, same(source));
    expect(
      find.textContaining('may increase the state and transition count'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(harness.notifier.currentPda, same(source));

    await tester.ensureVisible(find.text('Convert to CFG'));
    await tester.tap(find.text('Convert to CFG'));
    await _pumpUntilFound(tester, find.text('Review PDA normalization'));
    await tester.tap(find.text('Apply and convert'));
    await _pumpUntilFound(tester, find.text('Generated Grammar'));

    final normalized = harness.notifier.currentPda;
    expect(normalized, isNot(same(source)));
    expect(normalized!.states.length, greaterThan(source.states.length));
    expect(
      normalized.pdaTransitions.any((transition) => transition.isLambdaPop),
      isFalse,
    );
  });

  testWidgets('previews active-mode simplification before cancel or apply', (
    tester,
  ) async {
    final source = _buildReduciblePda();
    final harness = await _pumpPdaAlgorithmPanel(
      tester,
      initialPda: source,
      acceptanceMode: PDAAcceptanceMode.both,
    );

    await tester.ensureVisible(find.text('Simplify PDA'));
    await tester.tap(find.text('Simplify PDA'));
    await _pumpUntilFound(tester, find.text('Review PDA simplification'));

    expect(harness.notifier.currentPda, same(source));
    expect(harness.appliedPdas, isEmpty);
    expect(
      find.text('Active acceptance: final state and empty stack'),
      findsOneWidget,
    );
    expect(find.text('States: 3 → 2'), findsOneWidget);
    expect(
      find.textContaining('uncertain states were retained'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(harness.notifier.currentPda, same(source));
    expect(harness.appliedPdas, isEmpty);

    await tester.ensureVisible(find.text('Simplify PDA'));
    await tester.tap(find.text('Simplify PDA'));
    await _pumpUntilFound(tester, find.text('Review PDA simplification'));
    await tester.tap(find.text('Apply simplification'));
    await tester.pumpAndSettle();

    expect(harness.appliedPdas, hasLength(1));
    expect(harness.notifier.currentPda, same(harness.appliedPdas.single));
    expect(
      harness.notifier.currentPda!.states.map((state) => state.id),
      isNot(contains('simplify-unreachable')),
    );
  });

  testWidgets('reports no supported change without opening a preview', (
    tester,
  ) async {
    final source = _buildPdaExample().payload;
    final harness = await _pumpPdaAlgorithmPanel(tester, initialPda: source);

    await tester.ensureVisible(find.text('Simplify PDA'));
    await tester.tap(find.text('Simplify PDA'));
    await _pumpUntilFound(
      tester,
      find.textContaining('No supported simplification was found'),
    );

    expect(find.text('Review PDA simplification'), findsNothing);
    expect(harness.appliedPdas, isEmpty);
    expect(harness.notifier.currentPda, same(source));
  });

  testWidgets(
    'loads PDA examples from the configured catalog into the editor',
    (tester) async {
      final harness = await _pumpPdaAlgorithmPanel(tester);

      final exampleLabel = AppLocalizationsEn().localizedExampleName(
        'APD - Palíndromo',
      );
      expect(find.text(exampleLabel), findsOneWidget);

      await tester.tap(find.text(exampleLabel));
      await _pumpUntilPdaLoaded(tester, harness.notifier);

      final pda = harness.notifier.state.pda;
      expect(pda, isNotNull);
      expect(pda!.name, equals('APD - Palíndromo'));
      expect(pda.pdaTransitions, isNotEmpty);
      expect(pda.initialStackSymbol, equals('Z'));
    },
  );

  testWidgets('reachable-state analysis emits stable PDA state ids', (
    tester,
  ) async {
    final pda = _buildPdaExample().payload;
    final harness = await _pumpPdaAlgorithmPanel(tester, initialPda: pda);

    final previousEventCount = harness.output.events.length;
    await tester.ensureVisible(find.text('Find Reachable States'));
    await tester.tap(find.text('Find Reachable States'));
    await _pumpUntilHighlightEvent(tester, harness.output, previousEventCount);

    expect(harness.output.events, isNotEmpty);
    expect(harness.output.events.last!.stateIds, {
      'pda/state:start',
      'pda/state:accept',
    });
    expect(harness.output.events.last!.stateIds, isNot(contains('q0')));
  });

  testWidgets('determinism analysis emits exact conflicting PDA edge ids', (
    tester,
  ) async {
    final pda = _buildNondeterministicPda();
    final harness = await _pumpPdaAlgorithmPanel(tester, initialPda: pda);

    final previousEventCount = harness.output.events.length;
    await tester.ensureVisible(find.text('Check Determinism'));
    await tester.tap(find.text('Check Determinism'));
    await _pumpUntilHighlightEvent(tester, harness.output, previousEventCount);

    expect(harness.output.events, isNotEmpty);
    expect(harness.output.events.last!.transitionIds, {
      'opaque/pda-edge-a',
      ' opaque/pda-edge-b ',
    });
  });

  testWidgets('disposing an analysis panel restores validation highlight', (
    tester,
  ) async {
    final pda = _buildPdaExample().payload;
    final harness = await _pumpPdaAlgorithmPanel(tester, initialPda: pda);
    final validation = harness.coordinator.source(
      CanvasHighlightSource.validation,
    );
    addTearDown(validation.dispose);
    final warning = SimulationHighlight(
      transitionIds: const {'persistent-warning'},
    );
    validation.send(warning);

    final previousEventCount = harness.output.events.length;
    await tester.ensureVisible(find.text('Find Reachable States'));
    await tester.tap(find.text('Find Reachable States'));
    await _pumpUntilHighlightEvent(tester, harness.output, previousEventCount);
    expect(harness.output.events.last!.stateIds, isNotEmpty);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(harness.output.events.last, warning);
  });
}
