import 'dart:math' as math;
import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/simulation_highlight.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/core/services/highlight_channel.dart';
import 'package:turing_lab/core/services/simulation_highlight_service.dart';
import 'package:turing_lab/features/canvas/graphview/graphview_canvas_controller.dart';
import 'package:turing_lab/features/canvas/graphview/graphview_pda_canvas_controller.dart';
import 'package:turing_lab/presentation/providers/automaton_state_provider.dart';
import 'package:turing_lab/presentation/providers/pda_editor_provider.dart';
import 'package:turing_lab/presentation/widgets/automaton_graphview_canvas.dart';
import 'package:turing_lab/presentation/widgets/read_only_fsa_graphview_canvas.dart';

class _SentinelHighlightChannel implements HighlightChannel {
  @override
  void clear() {}

  @override
  void send(SimulationHighlight highlight) {}
}

FSA _buildFsa({required String id, required double stateX}) {
  final state = automaton_state.State(
    id: 'A',
    label: 'A',
    position: Vector2(stateX, 80),
    isInitial: true,
  );
  return FSA(
    id: id,
    name: id,
    states: {state},
    transitions: const <FSATransition>{},
    alphabet: const <String>{'a'},
    initialState: state,
    acceptingStates: <automaton_state.State>{},
    created: DateTime.utc(2024, 1, 1),
    modified: DateTime.utc(2024, 1, 1),
    bounds: const math.Rectangle<double>(0, 0, 400, 300),
    zoomLevel: 1,
    panOffset: Vector2.zero(),
  );
}

Future<void> _doubleTapNode(WidgetTester tester, Finder finder) async {
  final stateCenter = tester.getCenter(finder);
  final firstTap = await tester.startGesture(stateCenter);
  await firstTap.up();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  final secondTap = await tester.startGesture(stateCenter);
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 20)),
  );
  await secondTap.up();
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders a detached preview without ProviderScope',
      (tester) async {
    final preview = _buildFsa(id: 'preview', stateX: 80);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReadOnlyFsaGraphViewCanvas(
            automaton: preview,
            canvasKey: GlobalKey(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('read-only state semantics do not advertise editing', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      final preview = _buildFsa(id: 'read-only-semantics', stateX: 80);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReadOnlyFsaGraphViewCanvas(
              automaton: preview,
              canvasKey: GlobalKey(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final node = tester.getSemantics(
        find.bySemanticsLabel(
          'State A. Initial state. 0 outgoing transitions. '
          '0 incoming transitions.',
        ),
      );
      final data = node.getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      expect(data.hint, 'Read-only state.');
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('ignores double tap state editing in a detached preview', (
    tester,
  ) async {
    final preview = _buildFsa(id: 'preview', stateX: 80);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReadOnlyFsaGraphViewCanvas(
            automaton: preview,
            canvasKey: GlobalKey(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _doubleTapNode(tester, find.text('A'));

    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('tool-selection gate blocks state context editing', (
    tester,
  ) async {
    final preview = _buildFsa(id: 'context-gate', stateX: 80);
    final notifier = AutomatonStateNotifier()..updateAutomaton(preview);
    final controller = GraphViewCanvasController(
      automatonStateNotifier: notifier,
    )..synchronize(preview);
    final fsaCustomization = AutomatonGraphViewCanvasCustomization.fsa();
    final customization = AutomatonGraphViewCanvasCustomization(
      enableStateDrag: true,
      enableToolSelection: false,
      edgeRenderMode: fsaCustomization.edgeRenderMode,
      transitionConfigBuilder: fsaCustomization.transitionConfigBuilder,
    );
    addTearDown(() {
      controller.dispose();
      notifier.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AutomatonGraphViewCanvas(
            automaton: preview,
            canvasKey: GlobalKey(),
            controller: controller,
            customization: customization,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final logs = <String>[];
    final originalDebugPrint = debugPrint;
    try {
      debugPrint = (message, {wrapWidth}) {
        if (message != null) {
          logs.add(message);
        }
      };
      await _doubleTapNode(tester, find.text('A'));
    } finally {
      debugPrint = originalDebugPrint;
    }

    expect(logs, contains(contains('Detected double tap on A')));
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('tool selection remains active when state drag is disabled', (
    tester,
  ) async {
    final preview = _buildFsa(id: 'tool-enabled', stateX: 80);
    final notifier = AutomatonStateNotifier()..updateAutomaton(preview);
    final controller = GraphViewCanvasController(
      automatonStateNotifier: notifier,
    )..synchronize(preview);
    final fsaCustomization = AutomatonGraphViewCanvasCustomization.fsa();
    final customization = AutomatonGraphViewCanvasCustomization(
      enableStateDrag: false,
      enableToolSelection: true,
      edgeRenderMode: fsaCustomization.edgeRenderMode,
      transitionConfigBuilder: fsaCustomization.transitionConfigBuilder,
    );
    addTearDown(() {
      controller.dispose();
      notifier.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AutomatonGraphViewCanvas(
            automaton: preview,
            canvasKey: GlobalKey(),
            controller: controller,
            customization: customization,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final logs = <String>[];
    final originalDebugPrint = debugPrint;
    try {
      debugPrint = (message, {wrapWidth}) {
        if (message != null) {
          logs.add(message);
        }
      };
      await _doubleTapNode(tester, find.text('A'));
    } finally {
      debugPrint = originalDebugPrint;
    }

    expect(logs, contains(contains('Detected double tap on A')));
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets(
    'panning and pinching a detached preview preserve global state and highlight channel',
    (tester) async {
      final sentinel = _SentinelHighlightChannel();
      final highlightService = SimulationHighlightService(channel: sentinel);
      final container = ProviderContainer(
        overrides: [
          canvasHighlightServiceProvider.overrideWithValue(highlightService),
        ],
      );
      addTearDown(container.dispose);
      final globalAutomaton = _buildFsa(id: 'global', stateX: 40);
      final preview = _buildFsa(id: 'preview', stateX: 120);
      container
          .read(automatonStateProvider.notifier)
          .updateAutomaton(globalAutomaton);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: ReadOnlyFsaGraphViewCanvas(
                automaton: preview,
                canvasKey: GlobalKey(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final previewController = tester
          .widget<AutomatonGraphViewCanvas>(
            find.byType(AutomatonGraphViewCanvas),
          )
          .controller as GraphViewCanvasController;
      final transformation =
          previewController.graphController.transformationController!;
      final initialTransformation = List<double>.from(
        transformation.value.storage,
      );
      await tester.drag(find.text('A'), const Offset(60, 0));
      await tester.pumpAndSettle();

      final transformationBeforePinch = List<double>.from(
        transformation.value.storage,
      );
      expect(
        transformationBeforePinch,
        isNot(equals(initialTransformation)),
      );
      final scaleBeforePinch = transformation.value.getMaxScaleOnAxis();
      final nodeCenter = tester.getCenter(find.text('A'));
      final firstPointer = await tester.startGesture(nodeCenter, pointer: 11);
      final secondPointer = await tester.startGesture(
        nodeCenter + const Offset(20, 0),
        pointer: 12,
      );
      await tester.pump();
      await firstPointer.moveTo(nodeCenter - const Offset(40, 0));
      await secondPointer.moveTo(nodeCenter + const Offset(60, 0));
      await tester.pump();
      await firstPointer.up();
      await secondPointer.up();
      await tester.pumpAndSettle();

      final globalState = container
          .read(automatonStateProvider)
          .currentAutomaton!
          .states
          .single;
      expect(globalState.position.x, 40);
      expect(previewController.nodeById('A')!.x, 120);
      expect(
        List<double>.from(transformation.value.storage),
        isNot(equals(initialTransformation)),
      );
      expect(
        transformation.value.getMaxScaleOnAxis(),
        isNot(equals(scaleBeforePinch)),
      );
      expect(
        List<double>.from(transformation.value.storage),
        isNot(equals(transformationBeforePinch)),
      );
      expect(highlightService.channel, same(sentinel));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      expect(highlightService.channel, same(sentinel));
    },
  );

  testWidgets(
    'updates detached notifier and canvas for a new equal-identity FSA',
    (tester) async {
      final canvasKey = GlobalKey();
      final initial = _buildFsa(id: 'same-identity', stateX: 80);
      final updated = _buildFsa(id: 'same-identity', stateX: 220);

      Future<void> pumpPreview(FSA automaton) {
        return tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ReadOnlyFsaGraphViewCanvas(
                key: const ValueKey('preview'),
                automaton: automaton,
                canvasKey: canvasKey,
              ),
            ),
          ),
        );
      }

      await pumpPreview(initial);
      await tester.pumpAndSettle();

      await pumpPreview(updated);
      await tester.pumpAndSettle();

      final controller = tester
          .widget<AutomatonGraphViewCanvas>(
            find.byType(AutomatonGraphViewCanvas),
          )
          .controller as GraphViewCanvasController;
      expect(controller.currentDomainData!.states.single.position.x, 220);
      expect(controller.nodeById('A')!.x, 220);
    },
  );

  test('read-only customization requires an external controller', () {
    final preview = _buildFsa(id: 'preview', stateX: 80);

    expect(
      () => AutomatonGraphViewCanvas(
        automaton: preview,
        canvasKey: GlobalKey(),
        customization: AutomatonGraphViewCanvasCustomization.readOnly(),
      ),
      throwsAssertionError,
    );
  });

  test('non-FSA external controller requires explicit customization', () {
    final notifier = PDAEditorNotifier();
    final controller = GraphViewPdaCanvasController(editorNotifier: notifier);
    addTearDown(() {
      controller.dispose();
      notifier.dispose();
    });

    expect(
      () => AutomatonGraphViewCanvas(
        automaton: null,
        canvasKey: GlobalKey(),
        controller: controller,
      ),
      throwsAssertionError,
    );
  });
}
