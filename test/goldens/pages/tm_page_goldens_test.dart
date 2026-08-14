//
//  tm_page_goldens_test.dart
//  Turing Lab
//
//  Testes golden de regressão visual para componentes da TM page (toolbar e
//  canvas), capturando snapshots de estados críticos: layouts desktop/mobile,
//  canvas vazio, canvas com máquina de Turing, toolbar. Garante
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

import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/features/canvas/graphview/graphview_tm_canvas_controller.dart';
import 'package:turing_lab/injection/dependency_injection.dart';
import 'package:turing_lab/presentation/providers/tm_editor_provider.dart';
import 'package:turing_lab/presentation/providers/unified_trace_provider.dart';
import 'package:turing_lab/presentation/widgets/tm_canvas_graphview.dart';
import 'package:turing_lab/presentation/widgets/automaton_canvas_tool.dart';
import 'package:turing_lab/presentation/widgets/graphview_canvas_toolbar.dart';

late SharedPreferences _prefs;

// Widget that composes toolbar + canvas like TM page does
class _TMPageTestWidget extends StatefulWidget {
  final TM? automaton;
  final bool isMobile;

  const _TMPageTestWidget({this.automaton, this.isMobile = false});

  @override
  State<_TMPageTestWidget> createState() => _TMPageTestWidgetState();
}

class _TMPageTestWidgetState extends State<_TMPageTestWidget> {
  late final GraphViewTmCanvasController _canvasController;
  late final AutomatonCanvasToolController _toolController;
  late final TMEditorNotifier _editorNotifier;

  @override
  void initState() {
    super.initState();
    _editorNotifier = TMEditorNotifier();
    _canvasController = GraphViewTmCanvasController(
      editorNotifier: _editorNotifier,
    );
    if (widget.automaton != null) {
      _editorNotifier.setTm(widget.automaton!);
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
      overrides: [
        sharedPreferencesProvider.overrideWithValue(_prefs),
        tmEditorProvider.overrideWith((ref) => _editorNotifier),
      ],
      child: Scaffold(
        body: Stack(
          children: [
            // Canvas
            Positioned.fill(
              child: TMCanvasGraphView(
                controller: _canvasController,
                toolController: _toolController,
                onTmModified: (_) {},
              ),
            ),
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
                  statusMessage: widget.automaton == null ? 'No TM loaded' : '',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _pumpTMPageComponents(
  WidgetTester tester, {
  TM? automaton,
  Size size = const Size(1400, 900),
  bool isMobile = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;

  await tester.pumpWidgetBuilder(
    MaterialApp(
      home: _TMPageTestWidget(automaton: automaton, isMobile: isMobile),
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

  group('TM Page Components golden tests', () {
    testGoldens('renders empty canvas with toolbar in desktop layout', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpTMPageComponents(
        tester,
        size: const Size(1400, 900),
        isMobile: false,
      );

      await screenMatchesGolden(tester, 'tm_page_empty_desktop');
    });

    testGoldens('renders empty canvas with toolbar in tablet layout', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpTMPageComponents(
        tester,
        size: const Size(1200, 800),
        isMobile: false,
      );

      await screenMatchesGolden(tester, 'tm_page_empty_tablet');
    });

    testGoldens('renders empty canvas with toolbar in mobile layout', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpTMPageComponents(
        tester,
        size: const Size(430, 932),
        isMobile: true,
      );

      await screenMatchesGolden(tester, 'tm_page_empty_mobile');
    });

    testGoldens('renders canvas with toolbar and simple TM in desktop layout', (
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

      final transition = TMTransition.readWrite(
        id: 't1',
        fromState: q0,
        toState: q1,
        symbol: '0',
        direction: TapeDirection.right,
      );

      final automaton = TM(
        id: 'simple-tm',
        name: 'Simple TM',
        states: <automaton_state.State>{q0, q1},
        transitions: <TMTransition>{transition},
        alphabet: const <String>{'0', '1'},
        initialState: q0,
        acceptingStates: <automaton_state.State>{q1},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 800, 600),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
        tapeAlphabet: const <String>{'0', '1', 'B'},
        blankSymbol: 'B',
        tapeCount: 1,
      );

      await _pumpTMPageComponents(
        tester,
        automaton: automaton,
        size: const Size(1400, 900),
        isMobile: false,
      );

      await screenMatchesGolden(tester, 'tm_page_simple_tm_desktop');
    });

    testGoldens(
      'renders canvas with toolbar and copy machine in desktop layout',
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

        final t1 = TMTransition.readWrite(
          id: 't1',
          fromState: q0,
          toState: q0,
          symbol: '0',
          direction: TapeDirection.right,
        );

        final t2 = TMTransition.readWrite(
          id: 't2',
          fromState: q0,
          toState: q0,
          symbol: '1',
          direction: TapeDirection.right,
        );

        final t3 = TMTransition.readWrite(
          id: 't3',
          fromState: q0,
          toState: q1,
          symbol: 'B',
          direction: TapeDirection.stay,
        );

        final automaton = TM(
          id: 'copy-machine',
          name: 'Copy Machine',
          states: <automaton_state.State>{q0, q1},
          transitions: <TMTransition>{t1, t2, t3},
          alphabet: const <String>{'0', '1'},
          initialState: q0,
          acceptingStates: <automaton_state.State>{q1},
          created: DateTime.utc(2024, 1, 1),
          modified: DateTime.utc(2024, 1, 1),
          bounds: const math.Rectangle<double>(0, 0, 800, 600),
          zoomLevel: 1,
          panOffset: Vector2.zero(),
          tapeAlphabet: const <String>{'0', '1', 'B'},
          blankSymbol: 'B',
          tapeCount: 1,
        );

        await _pumpTMPageComponents(
          tester,
          automaton: automaton,
          size: const Size(1400, 900),
          isMobile: false,
        );

        await screenMatchesGolden(tester, 'tm_page_copy_machine_desktop');
      },
    );

    testGoldens(
      'renders page with TM with different directions in desktop layout',
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

        // Transition that moves left
        final t1 = TMTransition.changeSymbol(
          id: 't1',
          fromState: q0,
          toState: q1,
          readSymbol: '0',
          writeSymbol: '1',
          direction: TapeDirection.left,
        );

        final automaton = TM(
          id: 'direction-tm',
          name: 'Direction TM',
          states: <automaton_state.State>{q0, q1},
          transitions: <TMTransition>{t1},
          alphabet: const <String>{'0', '1'},
          initialState: q0,
          acceptingStates: <automaton_state.State>{q1},
          created: DateTime.utc(2024, 1, 1),
          modified: DateTime.utc(2024, 1, 1),
          bounds: const math.Rectangle<double>(0, 0, 800, 600),
          zoomLevel: 1,
          panOffset: Vector2.zero(),
          tapeAlphabet: const <String>{'0', '1', 'B'},
          blankSymbol: 'B',
          tapeCount: 1,
        );

        await _pumpTMPageComponents(
          tester,
          automaton: automaton,
          size: const Size(1400, 900),
          isMobile: false,
        );

        await screenMatchesGolden(tester, 'tm_page_direction_desktop');
      },
    );

    testGoldens('renders page with complex TM in tablet layout', (
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

      final t1 = TMTransition.readWrite(
        id: 't1',
        fromState: q0,
        toState: q1,
        symbol: '0',
        direction: TapeDirection.right,
      );

      final t2 = TMTransition.readWrite(
        id: 't2',
        fromState: q0,
        toState: q2,
        symbol: '1',
        direction: TapeDirection.right,
      );

      final t3 = TMTransition.changeSymbol(
        id: 't3',
        fromState: q1,
        toState: q2,
        readSymbol: '1',
        writeSymbol: '0',
        direction: TapeDirection.left,
      );

      final t4 = TMTransition.readWrite(
        id: 't4',
        fromState: q2,
        toState: q2,
        symbol: 'B',
        direction: TapeDirection.stay,
      );

      final automaton = TM(
        id: 'complex-tm',
        name: 'Complex TM',
        states: <automaton_state.State>{q0, q1, q2},
        transitions: <TMTransition>{t1, t2, t3, t4},
        alphabet: const <String>{'0', '1'},
        initialState: q0,
        acceptingStates: <automaton_state.State>{q2},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 800, 600),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
        tapeAlphabet: const <String>{'0', '1', 'B'},
        blankSymbol: 'B',
        tapeCount: 1,
      );

      await _pumpTMPageComponents(
        tester,
        automaton: automaton,
        size: const Size(1200, 800),
        isMobile: false,
      );

      await screenMatchesGolden(tester, 'tm_page_complex_tablet');
    });

    testGoldens('renders page with TM in mobile layout', (tester) async {
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

      final transition = TMTransition.readWrite(
        id: 't1',
        fromState: q0,
        toState: q1,
        symbol: '0',
        direction: TapeDirection.right,
      );

      final automaton = TM(
        id: 'mobile-tm',
        name: 'Mobile TM',
        states: <automaton_state.State>{q0, q1},
        transitions: <TMTransition>{transition},
        alphabet: const <String>{'0', '1'},
        initialState: q0,
        acceptingStates: <automaton_state.State>{q1},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 800, 600),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
        tapeAlphabet: const <String>{'0', '1', 'B'},
        blankSymbol: 'B',
        tapeCount: 1,
      );

      await _pumpTMPageComponents(
        tester,
        automaton: automaton,
        size: const Size(430, 932),
        isMobile: true,
      );

      await screenMatchesGolden(tester, 'tm_page_mobile_tm');
    });
  });
}
