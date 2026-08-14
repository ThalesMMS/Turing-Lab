//
//  fsa_page_goldens_test.dart
//  Turing Lab
//
//  Testes golden de regressão visual para componentes da FSA page (toolbar e
//  canvas), capturando snapshots de estados críticos: layouts desktop/mobile,
//  canvas vazio, canvas com autômato, toolbar, badges de determinismo. Garante
//  consistência visual da interface principal entre mudanças e detecta
//  regressões automáticas.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/features/canvas/graphview/graphview_canvas_controller.dart';
import 'package:turing_lab/injection/dependency_injection.dart';
import 'package:turing_lab/presentation/providers/automaton_state_provider.dart';
import 'package:turing_lab/presentation/providers/unified_trace_provider.dart';
import 'package:turing_lab/presentation/widgets/automaton_graphview_canvas.dart';
import 'package:turing_lab/presentation/widgets/automaton_canvas_tool.dart';
import 'package:turing_lab/presentation/widgets/fsa/determinism_badge.dart';
import 'package:turing_lab/presentation/widgets/graphview_canvas_toolbar.dart';

class _TestAutomatonStateNotifier extends AutomatonStateNotifier {
  _TestAutomatonStateNotifier() : super();
}

late SharedPreferences _prefs;

// Widget that composes toolbar + canvas like FSA page does
class _FSAPageTestWidget extends StatefulWidget {
  final FSA? automaton;
  final bool isMobile;

  const _FSAPageTestWidget({this.automaton, this.isMobile = false});

  @override
  State<_FSAPageTestWidget> createState() => _FSAPageTestWidgetState();
}

class _FSAPageTestWidgetState extends State<_FSAPageTestWidget> {
  late final GraphViewCanvasController _canvasController;
  late final AutomatonCanvasToolController _toolController;
  final GlobalKey _canvasKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final provider = _TestAutomatonStateNotifier();
    _canvasController = GraphViewCanvasController(
      automatonStateNotifier: provider,
    );
    if (widget.automaton != null) {
      provider.updateAutomaton(widget.automaton!);
      _canvasController.synchronize(widget.automaton!);
    }
    _toolController = AutomatonCanvasToolController();
  }

  @override
  void dispose() {
    _canvasController.dispose();
    _toolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final combinedListenable = Listenable.merge([
      _toolController,
      _canvasController.graphRevision,
    ]);

    return ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(_prefs)],
      child: Scaffold(
        body: Stack(
          children: [
            // Canvas
            Positioned.fill(
              child: AutomatonGraphViewCanvas(
                automaton: widget.automaton,
                canvasKey: _canvasKey,
                controller: _canvasController,
                toolController: _toolController,
                simulationResult: null,
                showTrace: false,
              ),
            ),
            // Determinism badge
            FSADeterminismOverlay(automaton: widget.automaton),
            // Toolbar
            AnimatedBuilder(
              animation: combinedListenable,
              builder: (context, _) {
                return GraphViewCanvasToolbar(
                  layout: widget.isMobile
                      ? GraphViewCanvasToolbarLayout.mobile
                      : GraphViewCanvasToolbarLayout.desktop,
                  controller: _canvasController,
                  enableToolSelection: true,
                  activeTool: _toolController.activeTool,
                  onAddState: () {
                    _toolController.setActiveTool(AutomatonCanvasTool.addState);
                    _canvasController.addStateAtCenter();
                  },
                  onAddTransition: () {
                    if (_toolController.activeTool !=
                        AutomatonCanvasTool.transition) {
                      _toolController.setActiveTool(
                        AutomatonCanvasTool.transition,
                      );
                    }
                  },
                  onClear: () {},
                  statusMessage:
                      widget.automaton == null ? 'No automaton loaded' : '',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _pumpFSAPageComponents(
  WidgetTester tester, {
  FSA? automaton,
  Size size = const Size(1400, 900),
  bool isMobile = false,
  ThemeMode themeMode = ThemeMode.light,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;

  await tester.pumpWidgetBuilder(
    MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      home: _FSAPageTestWidget(automaton: automaton, isMobile: isMobile),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    _prefs = await initializeSharedPreferences();
  });

  tearDownAll(() async {
    await resetDependencies();
  });

  group('FSA Page Components golden tests', () {
    testGoldens('renders empty canvas with toolbar in desktop layout', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpFSAPageComponents(
        tester,
        size: const Size(1400, 900),
        isMobile: false,
      );

      await screenMatchesGolden(tester, 'fsa_page_empty_desktop');
    });

    testGoldens('renders empty canvas with toolbar in tablet layout', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpFSAPageComponents(
        tester,
        size: const Size(1200, 800),
        isMobile: false,
      );

      await screenMatchesGolden(tester, 'fsa_page_empty_tablet');
    });

    testGoldens('renders empty canvas with toolbar in mobile layout', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpFSAPageComponents(
        tester,
        size: const Size(430, 932),
        isMobile: true,
      );

      await screenMatchesGolden(tester, 'fsa_page_empty_mobile');
    });

    testGoldens(
      'renders canvas with toolbar and simple DFA in desktop layout',
      (tester) async {
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final q0 = automaton_state.State(
          id: 'q0',
          label: 'q0',
          position: Vector2(200, 200),
          isInitial: true,
          isAccepting: false,
        );

        final q1 = automaton_state.State(
          id: 'q1',
          label: 'q1',
          position: Vector2(400, 200),
          isInitial: false,
          isAccepting: true,
        );

        final transition = FSATransition(
          id: 't1',
          fromState: q0,
          toState: q1,
          symbol: 'a',
          label: 'a',
        );

        final automaton = FSA(
          id: 'simple-dfa',
          name: 'Simple DFA',
          states: <automaton_state.State>{q0, q1},
          transitions: <FSATransition>{transition},
          alphabet: const <String>{'a'},
          initialState: q0,
          acceptingStates: <automaton_state.State>{q1},
          created: DateTime.utc(2024, 1, 1),
          modified: DateTime.utc(2024, 1, 1),
          bounds: const math.Rectangle<double>(0, 0, 800, 600),
          zoomLevel: 1,
          panOffset: Vector2.zero(),
        );

        await _pumpFSAPageComponents(
          tester,
          automaton: automaton,
          size: const Size(1400, 900),
          isMobile: false,
        );

        await screenMatchesGolden(tester, 'fsa_page_simple_dfa_desktop');
      },
    );

    testGoldens('renders canvas with toolbar and NFA in desktop layout', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final q0 = automaton_state.State(
        id: 'q0',
        label: 'q0',
        position: Vector2(200, 200),
        isInitial: true,
        isAccepting: false,
      );

      final q1 = automaton_state.State(
        id: 'q1',
        label: 'q1',
        position: Vector2(400, 200),
        isInitial: false,
        isAccepting: true,
      );

      // Two transitions with same symbol - makes it nondeterministic
      final t1 = FSATransition(
        id: 't1',
        fromState: q0,
        toState: q1,
        symbol: 'a',
        label: 'a',
      );

      final t2 = FSATransition(
        id: 't2',
        fromState: q0,
        toState: q0,
        symbol: 'a',
        label: 'a',
      );

      final automaton = FSA(
        id: 'simple-nfa',
        name: 'Simple NFA',
        states: <automaton_state.State>{q0, q1},
        transitions: <FSATransition>{t1, t2},
        alphabet: const <String>{'a'},
        initialState: q0,
        acceptingStates: <automaton_state.State>{q1},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 800, 600),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
      );

      await _pumpFSAPageComponents(
        tester,
        automaton: automaton,
        size: const Size(1400, 900),
        isMobile: false,
      );

      await screenMatchesGolden(tester, 'fsa_page_nfa_desktop');
    });

    testGoldens('renders page with epsilon-NFA in desktop layout', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final q0 = automaton_state.State(
        id: 'q0',
        label: 'q0',
        position: Vector2(200, 200),
        isInitial: true,
        isAccepting: false,
      );

      final q1 = automaton_state.State(
        id: 'q1',
        label: 'q1',
        position: Vector2(400, 200),
        isInitial: false,
        isAccepting: true,
      );

      // Epsilon transition
      final t1 = FSATransition(
        id: 't1',
        fromState: q0,
        toState: q1,
        symbol: '',
        label: 'λ',
      );

      final automaton = FSA(
        id: 'epsilon-nfa',
        name: 'Epsilon-NFA',
        states: <automaton_state.State>{q0, q1},
        transitions: <FSATransition>{t1},
        alphabet: const <String>{'a'},
        initialState: q0,
        acceptingStates: <automaton_state.State>{q1},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 800, 600),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
      );

      await _pumpFSAPageComponents(
        tester,
        automaton: automaton,
        size: const Size(1400, 900),
        isMobile: false,
      );

      await screenMatchesGolden(tester, 'fsa_page_epsilon_nfa_desktop');
    });

    testGoldens(
      'renders opposing vertical transitions with separated labels',
      (tester) async {
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final q0 = automaton_state.State(
          id: 'q0',
          label: 'q0',
          position: Vector2(280, 420),
          isInitial: true,
          isAccepting: false,
        );

        final q1 = automaton_state.State(
          id: 'q1',
          label: 'q1',
          position: Vector2(280, 120),
          isInitial: false,
          isAccepting: true,
        );

        final t1 = FSATransition(
          id: 't1',
          fromState: q0,
          toState: q1,
          symbol: 'a',
          label: 'a',
        );

        final t2 = FSATransition(
          id: 't2',
          fromState: q1,
          toState: q0,
          symbol: 'b',
          label: 'b',
        );

        final automaton = FSA(
          id: 'opposing-vertical',
          name: 'Opposing Vertical',
          states: <automaton_state.State>{q0, q1},
          transitions: <FSATransition>{t1, t2},
          alphabet: const <String>{'a', 'b'},
          initialState: q0,
          acceptingStates: <automaton_state.State>{q1},
          created: DateTime.utc(2024, 1, 1),
          modified: DateTime.utc(2024, 1, 1),
          bounds: const math.Rectangle<double>(0, 0, 800, 600),
          zoomLevel: 1,
          panOffset: Vector2.zero(),
        );

        await _pumpFSAPageComponents(
          tester,
          automaton: automaton,
          size: const Size(1400, 900),
          isMobile: false,
        );

        await screenMatchesGolden(tester, 'fsa_page_opposing_vertical_desktop');
      },
    );

    testGoldens(
      'renders grouped same-direction labels as a stacked card',
      (tester) async {
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final q0 = automaton_state.State(
          id: 'q0',
          label: 'q0',
          position: Vector2(180, 260),
          isInitial: true,
          isAccepting: false,
        );

        final q1 = automaton_state.State(
          id: 'q1',
          label: 'q1',
          position: Vector2(460, 180),
          isInitial: false,
          isAccepting: true,
        );

        final transitions = <FSATransition>{
          FSATransition(
            id: 't1',
            fromState: q0,
            toState: q1,
            symbol: 'a',
            label: 'a',
          ),
          FSATransition(
            id: 't2',
            fromState: q0,
            toState: q1,
            symbol: 'b',
            label: 'b',
          ),
          FSATransition(
            id: 't3',
            fromState: q0,
            toState: q1,
            symbol: 'c',
            label: 'c',
          ),
        };

        final automaton = FSA(
          id: 'grouped-labels',
          name: 'Grouped Labels',
          states: <automaton_state.State>{q0, q1},
          transitions: transitions,
          alphabet: const <String>{'a', 'b', 'c'},
          initialState: q0,
          acceptingStates: <automaton_state.State>{q1},
          created: DateTime.utc(2024, 1, 1),
          modified: DateTime.utc(2024, 1, 1),
          bounds: const math.Rectangle<double>(0, 0, 800, 600),
          zoomLevel: 1,
          panOffset: Vector2.zero(),
        );

        await _pumpFSAPageComponents(
          tester,
          automaton: automaton,
          size: const Size(1400, 900),
          isMobile: false,
        );

        await screenMatchesGolden(tester, 'fsa_page_grouped_labels_desktop');
      },
    );

    testGoldens(
      'renders grouped labels with dark theme surfaces',
      (tester) async {
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final q0 = automaton_state.State(
          id: 'q0',
          label: 'q0',
          position: Vector2(220, 280),
          isInitial: true,
          isAccepting: false,
        );

        final transitions = <FSATransition>{
          FSATransition(
            id: 't1',
            fromState: q0,
            toState: q0,
            symbol: 'a',
            label: 'a',
          ),
          FSATransition(
            id: 't2',
            fromState: q0,
            toState: q0,
            symbol: 'b',
            label: 'b',
          ),
        };

        final automaton = FSA(
          id: 'grouped-dark',
          name: 'Grouped Dark',
          states: <automaton_state.State>{q0},
          transitions: transitions,
          alphabet: const <String>{'a', 'b'},
          initialState: q0,
          acceptingStates: const <automaton_state.State>{},
          created: DateTime.utc(2024, 1, 1),
          modified: DateTime.utc(2024, 1, 1),
          bounds: const math.Rectangle<double>(0, 0, 800, 600),
          zoomLevel: 1,
          panOffset: Vector2.zero(),
        );

        await _pumpFSAPageComponents(
          tester,
          automaton: automaton,
          size: const Size(1400, 900),
          isMobile: false,
          themeMode: ThemeMode.dark,
        );

        await screenMatchesGolden(tester, 'fsa_page_grouped_labels_dark');
      },
    );

    testGoldens('renders page with complex automaton in tablet layout', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final q0 = automaton_state.State(
        id: 'q0',
        label: 'q0',
        position: Vector2(150, 200),
        isInitial: true,
        isAccepting: false,
      );

      final q1 = automaton_state.State(
        id: 'q1',
        label: 'q1',
        position: Vector2(350, 150),
        isInitial: false,
        isAccepting: false,
      );

      final q2 = automaton_state.State(
        id: 'q2',
        label: 'q2',
        position: Vector2(350, 250),
        isInitial: false,
        isAccepting: true,
      );

      final t1 = FSATransition(
        id: 't1',
        fromState: q0,
        toState: q1,
        symbol: 'a',
        label: 'a',
      );

      final t2 = FSATransition(
        id: 't2',
        fromState: q0,
        toState: q2,
        symbol: 'b',
        label: 'b',
      );

      final t3 = FSATransition(
        id: 't3',
        fromState: q1,
        toState: q2,
        symbol: 'b',
        label: 'b',
      );

      final t4 = FSATransition(
        id: 't4',
        fromState: q2,
        toState: q2,
        symbol: 'a',
        label: 'a',
      );

      final automaton = FSA(
        id: 'complex-dfa',
        name: 'Complex DFA',
        states: <automaton_state.State>{q0, q1, q2},
        transitions: <FSATransition>{t1, t2, t3, t4},
        alphabet: const <String>{'a', 'b'},
        initialState: q0,
        acceptingStates: <automaton_state.State>{q2},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 800, 600),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
      );

      await _pumpFSAPageComponents(
        tester,
        automaton: automaton,
        size: const Size(1200, 800),
        isMobile: false,
      );

      await screenMatchesGolden(tester, 'fsa_page_complex_tablet');
    });

    testGoldens('renders page with automaton in mobile layout', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final q0 = automaton_state.State(
        id: 'q0',
        label: 'q0',
        position: Vector2(150, 200),
        isInitial: true,
        isAccepting: false,
      );

      final q1 = automaton_state.State(
        id: 'q1',
        label: 'q1',
        position: Vector2(300, 200),
        isInitial: false,
        isAccepting: true,
      );

      final transition = FSATransition(
        id: 't1',
        fromState: q0,
        toState: q1,
        symbol: 'a',
        label: 'a',
      );

      final automaton = FSA(
        id: 'mobile-dfa',
        name: 'Mobile DFA',
        states: <automaton_state.State>{q0, q1},
        transitions: <FSATransition>{transition},
        alphabet: const <String>{'a'},
        initialState: q0,
        acceptingStates: <automaton_state.State>{q1},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 800, 600),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
      );

      await _pumpFSAPageComponents(
        tester,
        automaton: automaton,
        size: const Size(430, 932),
        isMobile: true,
      );

      await screenMatchesGolden(tester, 'fsa_page_mobile_dfa');
    });
  });
}
