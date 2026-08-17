import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/models/algorithm_step.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/pda_transition.dart';
import 'package:turing_lab/core/models/simulation_highlight.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_models;
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:turing_lab/core/models/transition.dart';
import 'package:turing_lab/core/services/canvas_highlight_coordinator.dart';
import 'package:turing_lab/core/services/highlight_channel.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/pages/pda_page.dart';
import 'package:turing_lab/presentation/pages/tm_page.dart';
import 'package:turing_lab/presentation/providers/algorithm_step_provider.dart';
import 'package:turing_lab/presentation/providers/pda_editor_provider.dart';
import 'package:turing_lab/presentation/providers/tm_editor_provider.dart';
import 'package:turing_lab/presentation/providers/unified_trace_provider.dart';
import 'package:turing_lab/presentation/widgets/pda_canvas_graphview.dart';
import 'package:turing_lab/presentation/widgets/pda_simulation_panel.dart';
import 'package:turing_lab/presentation/widgets/tm_canvas_graphview.dart';
import 'package:turing_lab/presentation/widgets/tm_simulation_panel.dart';

class _RecordingHighlightChannel implements HighlightChannel {
  final List<SimulationHighlight?> events = <SimulationHighlight?>[];

  @override
  void clear() => events.add(null);

  @override
  void send(SimulationHighlight highlight) => events.add(highlight);
}

class _KeptAliveHighlightSurface extends ConsumerStatefulWidget {
  const _KeptAliveHighlightSurface({
    required this.label,
    required this.source,
    required this.highlight,
  });

  final String label;
  final CanvasHighlightSource source;
  final SimulationHighlight highlight;

  @override
  ConsumerState<_KeptAliveHighlightSurface> createState() =>
      _KeptAliveHighlightSurfaceState();
}

class _KeptAliveHighlightSurfaceState
    extends ConsumerState<_KeptAliveHighlightSurface>
    with AutomaticKeepAliveClientMixin {
  late final CanvasHighlightSourceHandle _highlights;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _highlights =
        ref.read(canvasHighlightCoordinatorProvider)!.source(widget.source);
  }

  @override
  void dispose() {
    _highlights.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Center(
      child: FilledButton(
        key: ValueKey<String>('publish-${widget.label}'),
        onPressed: () => _highlights.send(widget.highlight),
        child: Text(widget.label),
      ),
    );
  }
}

Future<SharedPreferences> _preferences() async {
  SharedPreferences.setMockInitialValues({});
  return SharedPreferences.getInstance();
}

void _configureDesktopSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1500, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pumpPdaPage(
  WidgetTester tester,
  PDAEditorNotifier notifier,
) async {
  _configureDesktopSurface(tester);
  final preferences = await _preferences();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        pdaEditorProvider.overrideWith((ref) => notifier),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PDAPage(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _pumpTmPage(
  WidgetTester tester,
  TMEditorNotifier notifier,
) async {
  _configureDesktopSurface(tester);
  final preferences = await _preferences();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        tmEditorProvider.overrideWith((ref) => notifier),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TMPage(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _pumpUntilStateHighlights(
  WidgetTester tester,
  ValueNotifier<SimulationHighlight> highlightNotifier,
) async {
  for (var attempt = 0; attempt < 80; attempt++) {
    if (highlightNotifier.value.stateIds.isNotEmpty) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
  fail('Timed out waiting for canvas state highlights.');
}

PDA _pda({required String id, required bool nondeterministic}) {
  final start = automaton_models.State(
    id: 'shared-state-id',
    label: 'PDA start label',
    position: Vector2(80, 80),
    isInitial: true,
  );
  final firstTarget = automaton_models.State(
    id: 'pda-target-a',
    label: 'PDA target A',
    position: Vector2(260, 40),
    isAccepting: true,
  );
  final secondTarget = automaton_models.State(
    id: 'pda-target-b',
    label: 'PDA target B',
    position: Vector2(260, 160),
  );
  final transitions = <Transition>{
    PDATransition(
      id: 'opaque/pda-edge-a',
      fromState: start,
      toState: firstTarget,
      label: 'a, Z/Z',
      inputSymbol: 'a',
      popSymbol: 'Z',
      pushSymbol: 'Z',
    ),
    if (nondeterministic)
      PDATransition(
        id: ' opaque/pda-edge-b ',
        fromState: start,
        toState: secondTarget,
        label: 'a, Z/A',
        inputSymbol: 'a',
        popSymbol: 'Z',
        pushSymbol: 'A',
      ),
  };
  return PDA(
    id: id,
    name: 'Scoped PDA',
    states: {start, firstTarget, secondTarget},
    transitions: transitions,
    alphabet: const {'a'},
    initialState: start,
    acceptingStates: {firstTarget},
    created: DateTime(2026),
    modified: DateTime(2026),
    bounds: const math.Rectangle(0, 0, 400, 300),
    stackAlphabet: const {'Z', 'A'},
    initialStackSymbol: 'Z',
  );
}

TM _tm({required String id, required bool nondeterministic}) {
  final start = automaton_models.State(
    id: 'shared-state-id',
    label: 'TM start label',
    position: Vector2(80, 80),
    isInitial: true,
  );
  final firstTarget = automaton_models.State(
    id: 'tm-target-a',
    label: 'TM target A',
    position: Vector2(260, 40),
    isAccepting: true,
  );
  final secondTarget = automaton_models.State(
    id: 'tm-target-b',
    label: 'TM target B',
    position: Vector2(260, 160),
  );
  final transitions = <Transition>{
    TMTransition(
      id: 'opaque/tm-edge-a',
      fromState: start,
      toState: firstTarget,
      label: 'a/a,R',
      readSymbol: 'a',
      writeSymbol: 'a',
      direction: TapeDirection.right,
    ),
    if (nondeterministic)
      TMTransition(
        id: ' opaque/tm-edge-b ',
        fromState: start,
        toState: secondTarget,
        label: 'a/b,R',
        readSymbol: 'a',
        writeSymbol: 'b',
        direction: TapeDirection.right,
      ),
  };
  return TM(
    id: id,
    name: 'Scoped TM',
    states: {start, firstTarget, secondTarget},
    transitions: transitions,
    alphabet: const {'a'},
    initialState: start,
    acceptingStates: {firstTarget},
    created: DateTime(2026),
    modified: DateTime(2026),
    bounds: const math.Rectangle(0, 0, 400, 300),
    tapeAlphabet: const {'a', 'b', 'B'},
    blankSymbol: 'B',
  );
}

void main() {
  testWidgets(
    'PDA warning, simulation, and analysis stay scoped to the page canvas',
    (tester) async {
      final notifier = PDAEditorNotifier()
        ..setPda(_pda(id: 'pda-document', nondeterministic: true));
      await _pumpPdaPage(tester, notifier);

      final canvas = tester.widget<PDACanvasGraphView>(
        find.byType(PDACanvasGraphView),
      );
      final controller = canvas.controller!;
      const warningIds = {
        'opaque/pda-edge-a',
        ' opaque/pda-edge-b ',
      };
      expect(controller.highlightNotifier.value.transitionIds, warningIds);

      final simulationService = tester
          .widget<PDASimulationPanel>(find.byType(PDASimulationPanel).first)
          .highlightService!;
      final runtime = SimulationHighlight(
        stateIds: const {'shared-state-id'},
      );
      simulationService.dispatch(runtime);
      expect(controller.highlightNotifier.value, runtime);

      simulationService.clear();
      expect(controller.highlightNotifier.value.transitionIds, warningIds);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(PDAPage)),
      );
      container.read(algorithmStepProvider.notifier).initializeSteps([
        AlgorithmStep(
          id: 'unrelated-fsa-step',
          stepNumber: 0,
          title: 'Unrelated FSA step',
          explanation: 'Must not target PDA.',
          type: AlgorithmType.nfaToDfa,
          properties: const {
            'highlightedStateIds': ['shared-state-id'],
            'highlightedTransitionIds': ['opaque/pda-edge-a'],
          },
        ),
      ]);
      await tester.pump();
      expect(controller.highlightNotifier.value.transitionIds, warningIds);

      await tester.ensureVisible(find.text('Find Reachable States'));
      await tester.tap(find.text('Find Reachable States'));
      await _pumpUntilStateHighlights(
        tester,
        controller.highlightNotifier,
      );
      expect(controller.highlightNotifier.value.stateIds, {
        'shared-state-id',
        'pda-target-a',
        'pda-target-b',
      });

      notifier.setPda(
        _pda(id: 'replacement-pda', nondeterministic: false),
      );
      await tester.pump();
      expect(controller.highlightNotifier.value, SimulationHighlight.empty);
    },
  );

  testWidgets(
    'TM warning, simulation, and analysis stay scoped to the page canvas',
    (tester) async {
      final notifier = TMEditorNotifier()
        ..setTm(_tm(id: 'tm-document', nondeterministic: true));
      await _pumpTmPage(tester, notifier);

      final canvas = tester.widget<TMCanvasGraphView>(
        find.byType(TMCanvasGraphView),
      );
      final controller = canvas.controller!;
      const warningIds = {
        'opaque/tm-edge-a',
        ' opaque/tm-edge-b ',
      };
      expect(controller.highlightNotifier.value.transitionIds, warningIds);

      final simulationService = tester
          .widget<TMSimulationPanel>(find.byType(TMSimulationPanel).first)
          .highlightService!;
      final runtime = SimulationHighlight(
        stateIds: const {'shared-state-id'},
      );
      simulationService.dispatch(runtime);
      expect(controller.highlightNotifier.value, runtime);

      simulationService.clear();
      expect(controller.highlightNotifier.value.transitionIds, warningIds);

      await tester.ensureVisible(find.text('Find Reachable States'));
      await tester.tap(find.text('Find Reachable States'));
      await _pumpUntilStateHighlights(
        tester,
        controller.highlightNotifier,
      );
      expect(controller.highlightNotifier.value.stateIds, {
        'shared-state-id',
        'tm-target-a',
        'tm-target-b',
      });

      notifier.setTm(_tm(id: 'replacement-tm', nondeterministic: false));
      await tester.pump();
      expect(controller.highlightNotifier.value, SimulationHighlight.empty);
    },
  );

  testWidgets(
    'kept-alive surfaces with overlapping ids never share highlight output',
    (tester) async {
      final pageController = PageController();
      addTearDown(pageController.dispose);
      final pdaOutput = _RecordingHighlightChannel();
      final tmOutput = _RecordingHighlightChannel();
      final pdaCoordinator = CanvasHighlightCoordinator(
        target: const CanvasHighlightTarget(
          kind: AutomatonSurfaceKind.pda,
          surface: Object(),
          documentId: 'shared-document',
          revision: 0,
        ),
        output: pdaOutput,
      );
      final tmCoordinator = CanvasHighlightCoordinator(
        target: const CanvasHighlightTarget(
          kind: AutomatonSurfaceKind.tm,
          surface: Object(),
          documentId: 'shared-document',
          revision: 0,
        ),
        output: tmOutput,
      );
      addTearDown(pdaCoordinator.dispose);
      addTearDown(tmCoordinator.dispose);
      final pdaHighlight = SimulationHighlight(
        stateIds: const {'overlapping-state'},
        transitionIds: const {'overlapping-edge'},
      );
      final tmHighlight = SimulationHighlight(
        stateIds: const {'overlapping-state', 'tm-only-state'},
        transitionIds: const {'overlapping-edge'},
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: PageView(
              controller: pageController,
              children: [
                ProviderScope(
                  overrides: [
                    canvasHighlightCoordinatorProvider.overrideWithValue(
                      pdaCoordinator,
                    ),
                  ],
                  child: _KeptAliveHighlightSurface(
                    label: 'PDA surface',
                    source: CanvasHighlightSource.analysis,
                    highlight: pdaHighlight,
                  ),
                ),
                ProviderScope(
                  overrides: [
                    canvasHighlightCoordinatorProvider.overrideWithValue(
                      tmCoordinator,
                    ),
                  ],
                  child: _KeptAliveHighlightSurface(
                    label: 'TM surface',
                    source: CanvasHighlightSource.validation,
                    highlight: tmHighlight,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('publish-PDA surface')));
      expect(pdaOutput.events, <SimulationHighlight?>[pdaHighlight]);
      expect(tmOutput.events, isEmpty);

      pageController.jumpToPage(1);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('publish-TM surface')));
      expect(pdaOutput.events, <SimulationHighlight?>[pdaHighlight]);
      expect(tmOutput.events, <SimulationHighlight?>[tmHighlight]);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(PageView)),
      );
      container.read(algorithmStepProvider.notifier).initializeSteps([
        AlgorithmStep(
          id: 'global-fsa-overlap',
          stepNumber: 0,
          title: 'Global FSA overlap',
          explanation: 'Must remain outside both scoped surfaces.',
          type: AlgorithmType.nfaToDfa,
          properties: const {
            'highlightedStateIds': ['overlapping-state'],
            'highlightedTransitionIds': ['overlapping-edge'],
          },
        ),
      ]);
      await tester.pump();

      expect(pdaOutput.events, <SimulationHighlight?>[pdaHighlight]);
      expect(tmOutput.events, <SimulationHighlight?>[tmHighlight]);

      pageController.jumpToPage(0);
      await tester.pumpAndSettle();
      expect(find.text('PDA surface'), findsOneWidget);
      expect(pdaOutput.events.last, pdaHighlight);
    },
  );
}
