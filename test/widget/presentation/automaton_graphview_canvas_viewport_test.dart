import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart' show Vector2;

import 'package:turing_lab/core/constants/automaton_canvas_constants.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/features/canvas/graphview/graphview_canvas_controller.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/providers/automaton_state_provider.dart';
import 'package:turing_lab/presentation/widgets/automaton_canvas_tool.dart';
import 'package:turing_lab/presentation/widgets/automaton_graphview_canvas.dart';

class _FitTrackingController extends GraphViewCanvasController {
  _FitTrackingController({required super.automatonStateNotifier});

  int fitCalls = 0;

  @override
  void fitToContent() {
    fitCalls++;
    super.fitToContent();
  }
}

FSA _document(String id, {bool empty = false}) {
  final initial = empty
      ? null
      : automaton_state.State(
          id: 'seed',
          label: 'seed',
          position: Vector2(40, 40),
          isInitial: true,
        );
  return FSA(
    id: id,
    name: 'Viewport regression',
    states: {if (initial != null) initial},
    transitions: const <FSATransition>{},
    alphabet: const {'a'},
    initialState: initial,
    acceptingStates: const <automaton_state.State>{},
    created: DateTime.utc(2026, 1, 1),
    modified: DateTime.utc(2026, 1, 1),
    bounds: const math.Rectangle<double>(0, 0, 800, 600),
  );
}

Future<
  ({
    AutomatonStateNotifier notifier,
    _FitTrackingController controller,
    GlobalKey canvasKey,
  })
>
_mountCanvas(
  WidgetTester tester, {
  required FSA document,
  bool reducedMotion = false,
}) async {
  final container = ProviderContainer();
  final notifier = container.read(automatonStateProvider.notifier);
  notifier.updateAutomaton(document);
  final controller = _FitTrackingController(
    automatonStateNotifier: notifier,
  );
  final toolController = AutomatonCanvasToolController(
    AutomatonCanvasTool.addState,
  );
  final canvasKey = GlobalKey();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    toolController.dispose();
    container.dispose();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                disableAnimations: reducedMotion,
              ),
              child: AutomatonGraphViewCanvas(
                // Watch the real provider so each mutation reaches
                // didUpdateWidget, rather than only refreshing GraphView.
                automaton: ref.watch(automatonStateProvider).currentAutomaton,
                canvasKey: canvasKey,
                controller: controller,
                toolController: toolController,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (
    notifier: notifier,
    controller: controller,
    canvasKey: canvasKey,
  );
}

Matrix4 _editingViewport() => Matrix4.diagonal3Values(1.4, 1.4, 1)
  ..setTranslationRaw(35, -20, 0);

void _expectViewportUnchanged(
  _FitTrackingController controller,
  Matrix4 expected,
  int fitCalls,
) {
  expect(controller.fitCalls, fitCalls);
  expect(
    controller.graphController.transformationController!.value.storage,
    orderedEquals(expected.storage),
  );
}

void main() {
  for (final empty in [true, false]) {
    for (final reducedMotion in [false, true]) {
      testWidgets(
        'state insertion preserves viewport '
        '(empty=$empty, reducedMotion=$reducedMotion)',
        (tester) async {
          final harness = await _mountCanvas(
            tester,
            document: _document('editing', empty: empty),
            reducedMotion: reducedMotion,
          );
          final controller = harness.controller;
          final expected = _editingViewport();
          controller.graphController.transformationController!.value =
              expected.clone();
          await tester.pumpAndSettle();
          final fitCalls = controller.fitCalls;
          final initialCount = controller.nodes.length;
          final canvasOrigin = tester.getTopLeft(find.byKey(harness.canvasKey));
          const positions = [
            Offset(150, 200),
            Offset(350, 300),
            Offset(650, 400),
          ];
          for (var index = 0; index < positions.length; index++) {
            final previousIds = controller.nodes.map((node) => node.id).toSet();
            final worldCenter = controller.toWorldOffset(positions[index]);
            await tester.tapAt(canvasOrigin + positions[index]);
            await tester.pumpAndSettle();

            expect(controller.nodes.length, initialCount + index + 1);
            _expectViewportUnchanged(controller, expected, fitCalls);
            final added = controller.nodes.singleWhere(
              (node) => !previousIds.contains(node.id),
            );
            expect(
              added.x,
              closeTo(worldCenter.dx - kAutomatonStateDiameter / 2, 1e-6),
            );
            expect(
              added.y,
              closeTo(worldCenter.dy - kAutomatonStateDiameter / 2, 1e-6),
            );
          }

          // The keyboard uses addStateAtCenter instead of pointer coordinates.
          await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
          await tester.pumpAndSettle();
          expect(controller.nodes.length, initialCount + positions.length + 1);
          _expectViewportUnchanged(controller, expected, fitCalls);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('structural edits and undo/redo preserve viewport', (tester) async {
    final harness = await _mountCanvas(
      tester,
      document: _document('editing'),
    );
    final controller = harness.controller;
    controller.addStateAt(const Offset(500, 240));
    await tester.pumpAndSettle();
    final addedId = controller.nodes.singleWhere((node) => node.id != 'seed').id;
    final expected = _editingViewport();
    controller.graphController.transformationController!.value = expected.clone();
    await tester.pumpAndSettle();
    final fitCalls = controller.fitCalls;

    Future<void> check(VoidCallback edit, int states, int transitions) async {
      edit();
      await tester.pumpAndSettle();
      expect(controller.nodes.length, states);
      expect(controller.edges.length, transitions);
      _expectViewportUnchanged(controller, expected, fitCalls);
      expect(tester.takeException(), isNull);
    }

    await check(
      () => controller.addOrUpdateTransition(
        fromStateId: 'seed',
        toStateId: addedId,
        label: 'a',
        transitionId: 'edge',
      ),
      2,
      1,
    );
    await check(() => controller.removeTransition('edge'), 2, 0);
    await check(() => expect(controller.undo(), isTrue), 2, 1);
    await check(() => expect(controller.redo(), isTrue), 2, 0);
    await check(() => controller.removeState(addedId), 1, 0);
    await check(() => expect(controller.undo(), isTrue), 2, 0);
    await check(() => expect(controller.redo(), isTrue), 1, 0);
    await check(() => expect(controller.clearCanvas(), isTrue), 0, 0);
    await check(() => expect(controller.undo(), isTrue), 1, 0);
    await check(() => expect(controller.redo(), isTrue), 0, 0);
  });

  testWidgets('initial load, explicit fit and document switching still fit', (
    tester,
  ) async {
    final harness = await _mountCanvas(
      tester,
      document: _document('first'),
    );
    final controller = harness.controller;
    expect(controller.fitCalls, greaterThan(0));
    final transformation = controller.graphController.transformationController!;
    final expected = _editingViewport();
    transformation.value = expected.clone();
    await tester.pumpAndSettle();
    final initialFits = controller.fitCalls;

    controller.fitToContent();
    await tester.pumpAndSettle();
    expect(controller.fitCalls, initialFits + 1);
    expect(transformation.value.storage, isNot(orderedEquals(expected.storage)));

    transformation.value = expected.clone();
    await tester.pumpAndSettle();
    // The new document deliberately has the same state and transition IDs.
    harness.notifier.replaceAutomaton(_document('second'));
    await tester.pumpAndSettle();
    expect(controller.fitCalls, initialFits + 2);
    expect(transformation.value.storage, isNot(orderedEquals(expected.storage)));
    expect(harness.notifier.currentAutomaton!.id, 'second');
    expect(tester.takeException(), isNull);
  });
}
