//
//  pda_page_goldens_test.dart
//  Turing Lab
//
//  Visual regression golden tests for PDA page components (toolbar and
//  canvas), capturing snapshots of critical states: desktop/mobile layouts,
//  empty canvas, canvas with a pushdown automaton, toolbar, and stack panels.
//  Guards visual consistency of the main UI across changes and catches
//  automatic regressions.
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

import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/pda_transition.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/features/canvas/graphview/graphview_pda_canvas_controller.dart';
import 'package:turing_lab/injection/dependency_injection.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/pages/pda_page.dart';
import 'package:turing_lab/presentation/providers/pda_editor_provider.dart';
import 'package:turing_lab/presentation/providers/unified_trace_provider.dart';
import 'package:turing_lab/presentation/widgets/automaton_canvas_tool.dart';
import 'package:turing_lab/presentation/widgets/graphview_canvas_toolbar.dart';
import 'package:turing_lab/presentation/widgets/pda/stack_drawer.dart';
import 'package:turing_lab/presentation/widgets/pda_canvas_graphview.dart';

class _TestPdaEditorNotifier extends PDAEditorNotifier {
  _TestPdaEditorNotifier() : super();
}

late SharedPreferences _prefs;

// Widget that composes toolbar + canvas like PDA page does
class _PDAPageTestWidget extends ConsumerStatefulWidget {
  final PDA? automaton;

  const _PDAPageTestWidget({this.automaton});

  @override
  ConsumerState<_PDAPageTestWidget> createState() => _PDAPageTestWidgetState();
}

class _PDAPageTestWidgetState extends ConsumerState<_PDAPageTestWidget> {
  late final GraphViewPdaCanvasController _canvasController;
  late final AutomatonCanvasToolController _toolController;

  @override
  void initState() {
    super.initState();
    _canvasController = GraphViewPdaCanvasController(
      editorNotifier: ref.read(pdaEditorProvider.notifier),
    );
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

    return Scaffold(
      body: Stack(
        children: [
          // Canvas
          Positioned.fill(
            child: PDACanvasGraphView(
              controller: _canvasController,
              toolController: _toolController,
              onPdaModified: (_) {},
            ),
          ),
          // Stack panel
          if (widget.automaton != null)
            Positioned(
              bottom: 16,
              right: 16,
              child: PDAStackPanel(
                stackState: const StackState.empty(),
                initialStackSymbol: widget.automaton!.initialStackSymbol,
                stackAlphabet: widget.automaton!.stackAlphabet,
                isSimulating: false,
                onClear: () {},
              ),
            ),
          // Toolbar
          AnimatedBuilder(
            animation: combinedListenable,
            builder: (context, _) {
              return GraphViewCanvasToolbar(
                controller: _canvasController,
                enableToolSelection: true,
                showSelectionTool: true,
                activeTool: _toolController.activeTool,
                onSelectTool: () => _toolController.setActiveTool(
                  AutomatonCanvasTool.selection,
                ),
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
    );
  }
}

Future<void> _pumpPDAPageComponents(
  WidgetTester tester, {
  PDA? automaton,
  Size size = const Size(1400, 900),
  bool isMobile = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;

  final notifier = _TestPdaEditorNotifier();
  if (automaton != null) {
    notifier.setPda(automaton);
  }

  if (isMobile) {
    await tester.pumpWidgetBuilder(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(_prefs),
          pdaEditorProvider.overrideWith((ref) => notifier),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PDAPage(),
        ),
      ),
      surfaceSize: size,
    );
    expect(tester.view.physicalSize, size);
    await tester.pumpAndSettle();
    if (automaton != null) {
      final canvas = tester.widget<PDACanvasGraphView>(
        find.byType(PDACanvasGraphView),
      );
      final canvasController = canvas.controller!;
      expect(
        canvasController.nodes.map((node) => node.id),
        unorderedEquals(automaton.states.map((state) => state.id)),
      );
      expect(
        canvasController.edges.map((edge) => edge.id),
        unorderedEquals(
          automaton.transitions.map((transition) => transition.id),
        ),
      );
    }
    return;
  }

  await tester.pumpWidgetBuilder(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(_prefs),
        pdaEditorProvider.overrideWith((ref) => notifier),
      ],
      child: MaterialApp(
        home: _PDAPageTestWidget(automaton: automaton),
      ),
    ),
    surfaceSize: size,
  );

  expect(tester.view.physicalSize, size);
  await tester.pumpAndSettle();

  if (automaton != null) {
    final pageState = tester.state<_PDAPageTestWidgetState>(
      find.byType(_PDAPageTestWidget),
    );
    expect(
      pageState._canvasController.nodes.map((node) => node.id),
      unorderedEquals(automaton.states.map((state) => state.id)),
    );
    expect(
      pageState._canvasController.edges.map((edge) => edge.id),
      unorderedEquals(
        automaton.pdaTransitions.map((transition) => transition.id),
      ),
    );
  }
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

  group('PDA Page Components golden tests', () {
    testGoldens('renders empty canvas with toolbar in desktop layout', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpPDAPageComponents(
        tester,
        size: const Size(1400, 900),
        isMobile: false,
      );

      await screenMatchesGolden(tester, 'pda_page_empty_desktop');
    });

    testGoldens('renders empty canvas with toolbar in tablet layout', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpPDAPageComponents(
        tester,
        size: const Size(1200, 800),
        isMobile: false,
      );

      await screenMatchesGolden(tester, 'pda_page_empty_tablet');
    });

    testGoldens('renders empty canvas with real controls in mobile layout', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpPDAPageComponents(
        tester,
        size: const Size(430, 932),
        isMobile: true,
      );

      expect(find.byType(PDAPage), findsOneWidget);
      expect(find.byType(GraphViewCanvasToolbar), findsOneWidget);
      await screenMatchesGolden(tester, 'pda_page_empty_mobile');
    });

    testGoldens(
      'renders canvas with toolbar and simple PDA in desktop layout',
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

        final transition = PDATransition.readAndStack(
          id: 't1',
          fromState: q0,
          toState: q1,
          inputSymbol: 'a',
          popSymbol: 'Z',
          pushSymbol: 'Z',
        );

        final automaton = PDA(
          id: 'simple-pda',
          name: 'Simple PDA',
          states: <automaton_state.State>{q0, q1},
          transitions: <PDATransition>{transition},
          alphabet: const <String>{'a'},
          initialState: q0,
          acceptingStates: <automaton_state.State>{q1},
          created: DateTime.utc(2024, 1, 1),
          modified: DateTime.utc(2024, 1, 1),
          bounds: const math.Rectangle<double>(0, 0, 800, 600),
          zoomLevel: 1,
          panOffset: Vector2.zero(),
          stackAlphabet: const <String>{'Z'},
          initialStackSymbol: 'Z',
        );

        await _pumpPDAPageComponents(
          tester,
          automaton: automaton,
          size: const Size(1400, 900),
          isMobile: false,
        );

        await screenMatchesGolden(tester, 'pda_page_simple_pda_desktop');
      },
    );

    testGoldens(
      'renders canvas with toolbar and balanced parentheses PDA in desktop layout',
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

        // Push opening parenthesis
        final t1 = PDATransition.readAndStack(
          id: 't1',
          fromState: q0,
          toState: q0,
          inputSymbol: '(',
          popSymbol: 'Z',
          pushSymbol: 'Z(',
        );

        // Pop closing parenthesis
        final t2 = PDATransition.readAndStack(
          id: 't2',
          fromState: q0,
          toState: q0,
          inputSymbol: ')',
          popSymbol: '(',
          pushSymbol: '',
        );

        // Accept on empty stack
        final t3 = PDATransition.stackOnly(
          id: 't3',
          fromState: q0,
          toState: q1,
          popSymbol: 'Z',
          pushSymbol: '',
        );

        final automaton = PDA(
          id: 'balanced-parens-pda',
          name: 'Balanced Parentheses PDA',
          states: <automaton_state.State>{q0, q1},
          transitions: <PDATransition>{t1, t2, t3},
          alphabet: const <String>{'(', ')'},
          initialState: q0,
          acceptingStates: <automaton_state.State>{q1},
          created: DateTime.utc(2024, 1, 1),
          modified: DateTime.utc(2024, 1, 1),
          bounds: const math.Rectangle<double>(0, 0, 800, 600),
          zoomLevel: 1,
          panOffset: Vector2.zero(),
          stackAlphabet: const <String>{'Z', '('},
          initialStackSymbol: 'Z',
        );

        await _pumpPDAPageComponents(
          tester,
          automaton: automaton,
          size: const Size(1400, 900),
          isMobile: false,
        );

        await screenMatchesGolden(tester, 'pda_page_balanced_parens_desktop');
      },
    );

    testGoldens('renders page with epsilon-PDA in desktop layout', (
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
      final t1 = PDATransition.epsilon(id: 't1', fromState: q0, toState: q1);

      final automaton = PDA(
        id: 'epsilon-pda',
        name: 'Epsilon-PDA',
        states: <automaton_state.State>{q0, q1},
        transitions: <PDATransition>{t1},
        alphabet: const <String>{'a'},
        initialState: q0,
        acceptingStates: <automaton_state.State>{q1},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 800, 600),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
        stackAlphabet: const <String>{'Z'},
        initialStackSymbol: 'Z',
      );

      await _pumpPDAPageComponents(
        tester,
        automaton: automaton,
        size: const Size(1400, 900),
        isMobile: false,
      );

      await screenMatchesGolden(tester, 'pda_page_epsilon_pda_desktop');
    });

    testGoldens('renders page with complex PDA in tablet layout', (
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

      final t1 = PDATransition.readAndStack(
        id: 't1',
        fromState: q0,
        toState: q1,
        inputSymbol: 'a',
        popSymbol: 'Z',
        pushSymbol: 'AZ',
      );

      final t2 = PDATransition.readAndStack(
        id: 't2',
        fromState: q1,
        toState: q1,
        inputSymbol: 'a',
        popSymbol: 'A',
        pushSymbol: 'AA',
      );

      final t3 = PDATransition.readAndStack(
        id: 't3',
        fromState: q1,
        toState: q2,
        inputSymbol: 'b',
        popSymbol: 'A',
        pushSymbol: '',
      );

      final t4 = PDATransition.readAndStack(
        id: 't4',
        fromState: q2,
        toState: q2,
        inputSymbol: 'b',
        popSymbol: 'A',
        pushSymbol: '',
      );

      final automaton = PDA(
        id: 'complex-pda',
        name: 'Complex PDA',
        states: <automaton_state.State>{q0, q1, q2},
        transitions: <PDATransition>{t1, t2, t3, t4},
        alphabet: const <String>{'a', 'b'},
        initialState: q0,
        acceptingStates: <automaton_state.State>{q2},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 800, 600),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
        stackAlphabet: const <String>{'Z', 'A'},
        initialStackSymbol: 'Z',
      );

      await _pumpPDAPageComponents(
        tester,
        automaton: automaton,
        size: const Size(1200, 800),
        isMobile: false,
      );

      await screenMatchesGolden(tester, 'pda_page_complex_tablet');
    });

    testGoldens('renders page with PDA in mobile layout', (tester) async {
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

      final transition = PDATransition.readAndStack(
        id: 't1',
        fromState: q0,
        toState: q1,
        inputSymbol: 'a',
        popSymbol: 'Z',
        pushSymbol: 'Z',
      );

      final automaton = PDA(
        id: 'mobile-pda',
        name: 'Mobile PDA',
        states: <automaton_state.State>{q0, q1},
        transitions: <PDATransition>{transition},
        alphabet: const <String>{'a'},
        initialState: q0,
        acceptingStates: <automaton_state.State>{q1},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 800, 600),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
        stackAlphabet: const <String>{'Z'},
        initialStackSymbol: 'Z',
      );

      await _pumpPDAPageComponents(
        tester,
        automaton: automaton,
        size: const Size(430, 932),
        isMobile: true,
      );

      expect(find.byType(PDAPage), findsOneWidget);
      expect(find.byType(GraphViewCanvasToolbar), findsOneWidget);
      await screenMatchesGolden(tester, 'pda_page_mobile_pda');
    });
  });
}
