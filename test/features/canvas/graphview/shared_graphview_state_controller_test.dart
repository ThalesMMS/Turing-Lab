import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/features/canvas/graphview/base_graphview_canvas_controller.dart';
import 'package:turing_lab/features/canvas/graphview/graphview_canvas_models.dart';
import 'package:turing_lab/features/canvas/graphview/graphview_state_notifier_adapter.dart';

class _StateRecord {
  const _StateRecord({
    required this.id,
    required this.label,
    required this.position,
    this.isInitial = false,
    this.isAccepting = false,
  });

  final String id;
  final String label;
  final Offset position;
  final bool isInitial;
  final bool isAccepting;

  _StateRecord copyWith({
    String? label,
    Offset? position,
    bool? isInitial,
    bool? isAccepting,
  }) {
    return _StateRecord(
      id: id,
      label: label ?? this.label,
      position: position ?? this.position,
      isInitial: isInitial ?? this.isInitial,
      isAccepting: isAccepting ?? this.isAccepting,
    );
  }
}

class _TransitionRecord {
  const _TransitionRecord(this.id);

  final String id;
}

class _DomainRecord {
  const _DomainRecord({
    this.states = const [],
    this.transitions = const [],
  });

  final List<_StateRecord> states;
  final List<_TransitionRecord> transitions;

  _DomainRecord copyWith({
    List<_StateRecord>? states,
    List<_TransitionRecord>? transitions,
  }) {
    return _DomainRecord(
      states: states ?? this.states,
      transitions: transitions ?? this.transitions,
    );
  }
}

class _SharedStateHarnessController
    extends BaseGraphViewCanvasController<Object, _DomainRecord>
    with SharedGraphViewStateController<Object, _DomainRecord> {
  _SharedStateHarnessController() : super(notifier: Object());

  _DomainRecord domain = const _DomainRecord();
  final List<String> logs = [];

  @override
  late final GraphViewStateNotifierAdapter<_DomainRecord> stateNotifierAdapter =
      GraphViewStateNotifierAdapter<_DomainRecord>(
    currentData: () => domain,
    stateIdsOf: (data) => data.states.map((state) => state.id),
    stateLabelsOf: (data) => data.states.map((state) => state.label),
    transitionIdsOf: (data) =>
        data.transitions.map((transition) => transition.id),
    addState: ({required id, required label, required position}) {
      domain = domain.copyWith(
        states: [
          ...domain.states,
          _StateRecord(id: id, label: label, position: position),
        ],
      );
    },
    moveState: ({required id, required position}) {
      domain = domain.copyWith(
        states: [
          for (final state in domain.states)
            state.id == id ? state.copyWith(position: position) : state,
        ],
      );
    },
    updateStateLabel: ({required id, required label}) {
      domain = domain.copyWith(
        states: [
          for (final state in domain.states)
            state.id == id ? state.copyWith(label: label) : state,
        ],
      );
    },
    updateStateFlags: ({required id, isInitial, isAccepting}) {
      domain = domain.copyWith(
        states: [
          for (final state in domain.states)
            state.id == id
                ? state.copyWith(
                    isInitial: isInitial,
                    isAccepting: isAccepting,
                  )
                : state,
        ],
      );
    },
    removeState: (id) {
      domain = domain.copyWith(
        states: [
          for (final state in domain.states)
            if (state.id != id) state,
        ],
      );
    },
    logMutation: logs.add,
  );

  String nextNodeIdForTest() => generateNodeId();
  String nextEdgeIdForTest() => generateEdgeId();
  String nextStateLabelForTest() => nextAvailableStateLabel();
  void synchronizeForTest() => synchronizeGraph(domain);

  @override
  void removeTransition(String id) {
    domain = domain.copyWith(
      transitions: [
        for (final transition in domain.transitions)
          if (transition.id != id) transition,
      ],
    );
  }

  @override
  GraphViewAutomatonSnapshot toSnapshot(_DomainRecord? data) {
    final domain = data ?? const _DomainRecord();
    return GraphViewAutomatonSnapshot(
      nodes: [
        for (final state in domain.states)
          GraphViewCanvasNode(
            id: state.id,
            label: state.label,
            x: state.position.dx,
            y: state.position.dy,
            isInitial: state.isInitial,
            isAccepting: state.isAccepting,
          ),
      ],
      edges: const [],
      metadata: const GraphViewAutomatonMetadata.empty(),
    );
  }

  @override
  void applySnapshotToDomain(GraphViewAutomatonSnapshot snapshot) {
    domain = _DomainRecord(
      states: [
        for (final node in snapshot.nodes)
          _StateRecord(
            id: node.id,
            label: node.label,
            position: Offset(node.x, node.y),
            isInitial: node.isInitial,
            isAccepting: node.isAccepting,
          ),
      ],
    );
    synchronizeGraph(domain);
  }

  @override
  void replaceDomainDocument(_DomainRecord document) {
    domain = document;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedGraphViewStateController', () {
    late _SharedStateHarnessController controller;

    setUp(() {
      controller = _SharedStateHarnessController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('allocates ids and labels from domain state plus canvas cache', () {
      controller.domain = const _DomainRecord(
        states: [
          _StateRecord(
            id: 'state_0',
            label: 'q0',
            position: Offset.zero,
          ),
          _StateRecord(
            id: 'state_2',
            label: 'q2',
            position: Offset(100, 100),
          ),
        ],
        transitions: [
          _TransitionRecord('transition_0'),
          _TransitionRecord('transition_2'),
        ],
      );
      controller.synchronizeForTest();

      expect(controller.nextNodeIdForTest(), equals('state_1'));
      expect(controller.nextEdgeIdForTest(), equals('transition_1'));
      expect(controller.nextStateLabelForTest(), equals('q1'));
    });

    test('centralizes state CRUD mutations and graph synchronization', () {
      controller.addStateAt(const Offset(12, 24));

      var states = controller.domain.states;
      expect(states, hasLength(1));
      expect(states.single.id, equals('state_0'));
      expect(states.single.label, equals('q0'));
      expect(states.single.position, equals(const Offset(-36, -24)));
      expect(controller.nodeById('state_0'), isNotNull);

      controller.moveState('state_0', const Offset(40, 80));
      states = controller.domain.states;
      expect(states.single.position, equals(const Offset(40, 80)));

      controller.updateStateLabel('state_0', '');
      states = controller.domain.states;
      expect(states.single.label, equals('state_0'));

      controller.updateStateFlags(
        'state_0',
        isInitial: true,
        isAccepting: true,
      );
      states = controller.domain.states;
      expect(states.single.isInitial, isTrue);
      expect(states.single.isAccepting, isTrue);

      controller.removeState('state_0');
      expect(controller.domain.states, isEmpty);
      expect(controller.nodeById('state_0'), isNull);
      expect(controller.logs, contains(startsWith('addStateAt ->')));
      expect(controller.logs, contains(startsWith('removeState ->')));
    });
  });
}
