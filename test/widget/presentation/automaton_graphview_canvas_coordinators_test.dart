import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/core/models/automaton.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/simulation_highlight.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/core/models/transition.dart';
import 'package:turing_lab/core/services/highlight_channel.dart';
import 'package:turing_lab/core/services/simulation_highlight_service.dart';
import 'package:turing_lab/features/canvas/graphview/base_graphview_canvas_controller.dart';
import 'package:turing_lab/features/canvas/graphview/graphview_canvas_controller.dart';
import 'package:turing_lab/features/canvas/graphview/graphview_pda_canvas_controller.dart';
import 'package:turing_lab/features/canvas/graphview/graphview_tm_canvas_controller.dart';
import 'package:turing_lab/presentation/providers/automaton_state_provider.dart';
import 'package:turing_lab/presentation/providers/pda_editor_provider.dart';
import 'package:turing_lab/presentation/providers/tm_editor_provider.dart';
import 'package:turing_lab/presentation/widgets/automaton_canvas_tool.dart';
import 'package:turing_lab/presentation/widgets/automaton_graphview/canvas_controller_lifecycle.dart';
import 'package:turing_lab/presentation/widgets/automaton_graphview/canvas_domain_sync_coordinator.dart';
import 'package:turing_lab/presentation/widgets/automaton_graphview/canvas_viewport_adapter.dart';
import 'package:turing_lab/presentation/widgets/automaton_graphview_canvas.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AutomatonGraphViewControllerLifecycle', () {
    test('read-only external controllers never touch providers or ownership',
        () {
      final transformations = <TransformationController>[];
      final controllers = <BaseGraphViewCanvasController<dynamic, dynamic>>[
        GraphViewCanvasController(
          automatonStateNotifier: AutomatonStateNotifier(),
          transformationController: _transformation(transformations),
        ),
        GraphViewPdaCanvasController(
          editorNotifier: PDAEditorNotifier(),
          transformationController: _transformation(transformations),
        ),
        GraphViewTmCanvasController(
          editorNotifier: TMEditorNotifier(),
          transformationController: _transformation(transformations),
        ),
      ];

      for (final controller in controllers) {
        var internalFactoryReads = 0;
        var highlightProviderReads = 0;
        final externalTool = AutomatonCanvasToolController();
        final lifecycle = AutomatonGraphViewControllerLifecycle(
          externalController: controller,
          externalToolController: externalTool,
          createInternalController: () {
            internalFactoryReads++;
            throw StateError('read-only canvas requested an editor provider');
          },
          readHighlightService: () {
            highlightProviderReads++;
            throw StateError('read-only canvas replaced a highlight channel');
          },
          onGraphRevision: () {},
          onHighlight: () {},
          onToolChanged: () {},
        );

        expect(lifecycle.controller, same(controller));
        expect(lifecycle.ownsController, isFalse);
        expect(lifecycle.ownsToolController, isFalse);
        lifecycle.dispose();
        expect(internalFactoryReads, 0);
        expect(highlightProviderReads, 0);
        expect(
          () => externalTool.setActiveTool(AutomatonCanvasTool.transition),
          returnsNormally,
        );
        externalTool.dispose();
      }

      for (var index = 0; index < controllers.length; index++) {
        expect(
          () => transformations[index].value = Matrix4.identity(),
          returnsNormally,
        );
        controllers[index].dispose();
        transformations[index].dispose();
      }
    });

    test('internal resources restore highlight channel and dispose once', () {
      final previousChannel = FunctionHighlightChannel((_) {});
      final highlightService = SimulationHighlightService(
        channel: previousChannel,
      );
      late GraphViewCanvasController internalController;
      var factoryCalls = 0;
      final lifecycle = AutomatonGraphViewControllerLifecycle(
        externalController: null,
        externalToolController: null,
        createInternalController: () {
          factoryCalls++;
          return internalController = GraphViewCanvasController(
            automatonStateNotifier: AutomatonStateNotifier(),
          );
        },
        readHighlightService: () => highlightService,
        onGraphRevision: () {},
        onHighlight: () {},
        onToolChanged: () {},
      );
      final transformation =
          internalController.graphController.transformationController!;

      expect(factoryCalls, 1);
      expect(lifecycle.ownsController, isTrue);
      expect(lifecycle.ownsToolController, isTrue);
      expect(highlightService.channel, isNot(same(previousChannel)));

      lifecycle.dispose();
      lifecycle.dispose();

      expect(highlightService.channel, same(previousChannel));
      expect(
        () => transformation.value = Matrix4.identity()
          ..translateByDouble(1, 0, 0, 1),
        throwsFlutterError,
      );
    });

    test('out-of-order disposal preserves the newest live highlight channel',
        () {
      final previousChannel = FunctionHighlightChannel((_) {});
      final highlightService = SimulationHighlightService(
        channel: previousChannel,
      );
      late GraphViewCanvasController secondController;

      AutomatonGraphViewControllerLifecycle createLifecycle(
        void Function(GraphViewCanvasController controller) capture,
      ) {
        return AutomatonGraphViewControllerLifecycle(
          externalController: null,
          externalToolController: null,
          createInternalController: () {
            final controller = GraphViewCanvasController(
              automatonStateNotifier: AutomatonStateNotifier(),
            );
            capture(controller);
            return controller;
          },
          readHighlightService: () => highlightService,
          onGraphRevision: () {},
          onHighlight: () {},
          onToolChanged: () {},
        );
      }

      final first = createLifecycle((_) {});
      final second = createLifecycle((controller) {
        secondController = controller;
      });
      final secondChannel = highlightService.channel;

      first.dispose();

      expect(highlightService.channel, same(secondChannel));
      highlightService.dispatch(
        SimulationHighlight(stateIds: const {'live'}),
      );
      expect(secondController.highlightNotifier.value.stateIds, {'live'});

      second.dispose();

      expect(highlightService.channel, same(previousChannel));
    });
  });

  group('AutomatonGraphViewDomainSyncCoordinator', () {
    test('coalesces rapid updates and applies only the latest snapshot', () {
      final frames = <FrameCallback>[];
      final synchronized = <Object?>[];
      final coordinator = AutomatonGraphViewDomainSyncCoordinator(
        synchronize: synchronized.add,
        isMounted: () => true,
        schedulePostFrame: frames.add,
      );

      coordinator
        ..schedule('first')
        ..schedule('second')
        ..schedule('latest');

      expect(frames, hasLength(1));
      frames.single(Duration.zero);
      expect(synchronized, ['latest']);
    });

    test('rejects stale callbacks after a controller generation change', () {
      final frames = <FrameCallback>[];
      final oldTarget = <Object?>[];
      final newTarget = <Object?>[];
      final coordinator = AutomatonGraphViewDomainSyncCoordinator(
        synchronize: oldTarget.add,
        isMounted: () => true,
        schedulePostFrame: frames.add,
      );

      coordinator.schedule('stale');
      coordinator.replaceTarget(newTarget.add);
      coordinator.schedule('current');
      expect(frames, hasLength(2));

      frames[0](Duration.zero);
      frames[1](Duration.zero);
      expect(oldTarget, isEmpty);
      expect(newTarget, ['current']);
    });

    test('detects structural updates despite equal automaton identity', () {
      final coordinator = AutomatonGraphViewDomainSyncCoordinator(
        synchronize: (_) {},
        isMounted: () => true,
        schedulePostFrame: (_) {},
      );
      final original = FSA.empty(id: 'same', name: 'Same');
      final state = automaton_state.State(
        id: 'q0',
        label: 'q0',
        position: Vector2(80, 40),
        isInitial: true,
      );
      final updated = original.copyWith(
        states: {state},
        initialState: state,
      );

      expect(original, equals(updated));
      expect(coordinator.contentChanged(original, updated), isTrue);
      expect(coordinator.contentChanged(updated, updated), isFalse);
    });

    test('preserves order in nested PDA push-symbol payloads', () {
      final coordinator = AutomatonGraphViewDomainSyncCoordinator(
        synchronize: (_) {},
        isMounted: () => true,
        schedulePostFrame: (_) {},
      );
      final pushAB = _SerializedAutomaton(const ['A', 'B']);
      final pushBA = _SerializedAutomaton(const ['B', 'A']);

      expect(coordinator.contentChanged(pushAB, pushBA), isTrue);
    });

    test('ignores iteration order for set-backed automaton collections', () {
      final coordinator = AutomatonGraphViewDomainSyncCoordinator(
        synchronize: (_) {},
        isMounted: () => true,
        schedulePostFrame: (_) {},
      );
      final q0 = automaton_state.State(
        id: 'q0',
        label: 'q0',
        position: Vector2(40, 40),
      );
      final q1 = automaton_state.State(
        id: 'q1',
        label: 'q1',
        position: Vector2(160, 40),
      );

      FSA build(Set<automaton_state.State> states, Set<String> alphabet) {
        return FSA(
          id: 'unordered',
          name: 'Unordered',
          states: states,
          transitions: const <Transition>{},
          alphabet: alphabet,
          acceptingStates: states,
          created: DateTime.utc(2024, 1, 1),
          modified: DateTime.utc(2024, 1, 1),
          bounds: const math.Rectangle<double>(0, 0, 400, 300),
        );
      }

      final forward = build({q0, q1}, {'a', 'b'});
      final reverse = build({q1, q0}, {'b', 'a'});

      expect(coordinator.contentChanged(forward, reverse), isFalse);
    });
  });

  testWidgets(
      'mounted canvas swaps external controllers without taking ownership',
      (tester) async {
    final automaton = FSA.empty(id: 'swap', name: 'Swap');
    final firstTransformation = TransformationController();
    final secondTransformation = TransformationController();
    final first = GraphViewCanvasController(
      automatonStateNotifier: AutomatonStateNotifier()
        ..updateAutomaton(automaton),
      transformationController: firstTransformation,
    );
    final second = GraphViewCanvasController(
      automatonStateNotifier: AutomatonStateNotifier()
        ..updateAutomaton(automaton),
      transformationController: secondTransformation,
    );
    final canvasKey = GlobalKey();

    Widget canvas(GraphViewCanvasController controller) => MaterialApp(
          home: Scaffold(
            body: AutomatonGraphViewCanvas(
              automaton: automaton,
              canvasKey: canvasKey,
              controller: controller,
            ),
          ),
        );

    await tester.pumpWidget(canvas(first));
    await tester.pump();
    expect(first.graphController.hasAttachedView, isTrue);

    await tester.pumpWidget(canvas(second));
    await tester.pump();
    expect(first.graphController.hasAttachedView, isFalse);
    expect(second.graphController.hasAttachedView, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(second.graphController.hasAttachedView, isFalse);
    expect(
      () => firstTransformation.value = Matrix4.identity(),
      returnsNormally,
    );
    expect(
      () => secondTransformation.value = Matrix4.identity(),
      returnsNormally,
    );

    first.dispose();
    second.dispose();
    firstTransformation.dispose();
    secondTransformation.dispose();
  });

  test('viewport adapter round-trips caller-owned transforms for FSA/PDA/TM',
      () {
    final transformations = <TransformationController>[];
    final controllers = <BaseGraphViewCanvasController<dynamic, dynamic>>[
      GraphViewCanvasController(
        automatonStateNotifier: AutomatonStateNotifier(),
        transformationController: _transformation(transformations),
      ),
      GraphViewPdaCanvasController(
        editorNotifier: PDAEditorNotifier(),
        transformationController: _transformation(transformations),
      ),
      GraphViewTmCanvasController(
        editorNotifier: TMEditorNotifier(),
        transformationController: _transformation(transformations),
      ),
    ];

    for (var index = 0; index < controllers.length; index++) {
      transformations[index].value = Matrix4.identity()
        ..translateByDouble(32, 24, 0, 1)
        ..scaleByDouble(1.5, 1.5, 1, 1);
      final adapter = AutomatonGraphViewViewportAdapter(
        controller: controllers[index],
      );
      const world = Offset(120, 80);
      final screen = adapter.worldToScreen(world);
      expect(adapter.screenToWorld(screen), offsetMoreOrLessEquals(world));
      controllers[index].dispose();
      transformations[index].dispose();
    }
  });
}

class _SerializedAutomaton extends Automaton {
  _SerializedAutomaton(this.pushSymbols)
      : super(
          id: 'same-pda',
          name: 'Same PDA',
          states: const <automaton_state.State>{},
          transitions: const <Transition>{},
          alphabet: const <String>{},
          acceptingStates: const <automaton_state.State>{},
          type: AutomatonType.pda,
          created: DateTime.utc(2024, 1, 1),
          modified: DateTime.utc(2024, 1, 1),
          bounds: const math.Rectangle<double>(0, 0, 400, 300),
        );

  final List<String> pushSymbols;

  @override
  Automaton copyWith({
    String? id,
    String? name,
    Set<automaton_state.State>? states,
    Set<Transition>? transitions,
    Set<String>? alphabet,
    automaton_state.State? initialState,
    Set<automaton_state.State>? acceptingStates,
    AutomatonType? type,
    DateTime? created,
    DateTime? modified,
    math.Rectangle? bounds,
    double? zoomLevel,
    Vector2? panOffset,
  }) {
    return this;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'PDA',
      'transitions': [
        {
          'id': 't0',
          'pushSymbol': 'same-derived-label',
          'pushSymbols': pushSymbols,
        },
      ],
    };
  }
}

TransformationController _transformation(
  List<TransformationController> transformations,
) {
  final transformation = TransformationController();
  transformations.add(transformation);
  return transformation;
}
