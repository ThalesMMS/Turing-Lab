import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/computation_branch.dart';
import 'package:turing_lab/presentation/widgets/computation_branch_inspector.dart';

void main() {
  testWidgets('narrow layout uses progressive disclosure without overflow',
      (tester) async {
    await _pumpInspector(tester, width: 320);

    expect(
      find.byKey(const ValueKey('computation-branch-inspector-narrow')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('computation-branch-hierarchy-disclosure'),
      ),
      findsOneWidget,
    );
    expect(find.text('Configuration details'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide layout exposes hierarchy and selected detail together',
      (tester) async {
    await _pumpInspector(tester, width: 900);

    expect(
      find.byKey(const ValueKey('computation-branch-inspector-wide')),
      findsOneWidget,
    );
    expect(find.text('q0, input ab'), findsNWidgets(2));
    expect(find.text('Accepted'), findsWidgets);
    expect(find.byIcon(Icons.check_circle_outline), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('node selection has button and selected semantics',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final selected = <ComputationBranchNodeId>[];
    await _pumpInspector(tester, width: 900, selectedNodes: selected);

    final root = find.byKey(
      const ValueKey('computation-branch-node-root'),
    );
    final data = tester.getSemantics(root).getSemanticsData();
    expect(data.flagsCollection.isButton, isTrue);
    expect(data.flagsCollection.isSelected, Tristate.isTrue);
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    expect(data.label, contains('Configuration 1, q0, input ab'));

    await tester.tap(
      find.byKey(const ValueKey('computation-branch-node-accepted')),
    );
    await tester.pump();

    expect(selected, [const ComputationBranchNodeId('accepted')]);
    expect(
      tester
          .getSemantics(
            find.byKey(
              const ValueKey('computation-branch-node-accepted'),
            ),
          )
          .getSemanticsData()
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );
    semantics.dispose();
  });

  testWidgets('native controls support keyboard selection and highlighting',
      (tester) async {
    final selectedBranches = <ComputationBranchId>[];
    final highlighted = <ComputationBranchId>[];
    await _pumpInspector(
      tester,
      width: 900,
      selectedBranches: selectedBranches,
      highlightedBranches: highlighted,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(selectedBranches, [const ComputationBranchId('dead')]);

    final highlight = find.byKey(
      const ValueKey('computation-branch-highlight'),
    );
    await tester.ensureVisible(highlight);
    await tester.tap(highlight);
    await tester.pump();
    expect(highlighted, [const ComputationBranchId('dead')]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('node controls activate with Space and Enter', (tester) async {
    final selected = <ComputationBranchNodeId>[];
    await _pumpInspector(tester, width: 900, selectedNodes: selected);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(selected, [
      const ComputationBranchNodeId('root'),
      const ComputationBranchNodeId('accepted'),
    ]);
  });

  testWidgets(
      'large graphs use an accessible keyboard branch navigator to reach the end',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final selected = <ComputationBranchId>[];
    final graph = _largeGraph(501);
    await _pumpInspector(
      tester,
      width: 900,
      availability: ComputationBranchesAvailable(graph),
      selectedBranches: selected,
    );

    expect(find.byType(DropdownButtonFormField<ComputationBranchId>),
        findsNothing);
    expect(
      find.byKey(const ValueKey('computation-branch-navigator')),
      findsOneWidget,
    );
    expect(find.text('Branch 1 of 501'), findsOneWidget);
    expect(
      tester
          .getSemantics(
            find.byKey(const ValueKey('computation-branch-next')),
          )
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    expect(
      tester
          .getSemantics(
            find.byKey(const ValueKey('computation-branch-next')),
          )
          .label,
      contains('Next branch'),
    );
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const ValueKey('computation-branch-previous')),
          )
          .onPressed,
      isNull,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(selected, [const ComputationBranchId('branch-1')]);

    selected.clear();
    await _pumpInspector(
      tester,
      width: 900,
      availability: ComputationBranchesAvailable(graph),
      initialBranchId: const ComputationBranchId('branch-499'),
      selectedBranches: selected,
    );
    await tester.tap(
      find.byKey(const ValueKey('computation-branch-next')),
    );
    await tester.pump();
    expect(selected, [const ComputationBranchId('branch-500')]);
    expect(find.text('Branch 501 of 501'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const ValueKey('computation-branch-next')),
          )
          .onPressed,
      isNull,
    );
    semantics.dispose();
  });

  testWidgets(
      'long branches page every configuration without inventing terminal outcomes',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final selected = <ComputationBranchNodeId>[];
    await _pumpInspector(
      tester,
      width: 900,
      availability: ComputationBranchesAvailable(_longBranchGraph(1001)),
      selectedNodes: selected,
    );

    expect(find.text('Configurations 1-500 of 1001'), findsOneWidget);
    expect(
      tester
          .getSemantics(
            find.byKey(
              const ValueKey('computation-branch-node-long-node-499'),
            ),
          )
          .label,
      isNot(contains('Accepted')),
    );

    await tester.tap(
      find.byKey(const ValueKey('computation-configurations-next')),
    );
    await tester.pump();
    expect(selected, [const ComputationBranchNodeId('long-node-500')]);
    expect(find.text('Configurations 501-1000 of 1001'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('computation-configurations-next')),
    );
    await tester.pump();
    expect(selected.last, const ComputationBranchNodeId('long-node-1000'));
    expect(find.text('Configurations 1001-1001 of 1001'), findsOneWidget);
    expect(
      tester
          .getSemantics(
            find.byKey(
              const ValueKey('computation-branch-node-long-node-1000'),
            ),
          )
          .label,
      contains('Accepted'),
    );
    semantics.dispose();
  });

  testWidgets('unavailable state presents typed reason with semantics',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpInspector(
      tester,
      width: 320,
      availability: const ComputationBranchesUnavailable(
        ComputationBranchesUnavailableReason.branchesNotRecorded,
      ),
    );

    expect(
      find.text(
        'This simulation records a trace but not every explored branch.',
      ),
      findsOneWidget,
    );
    expect(
      tester.getSemantics(find.byType(Card)).label,
      contains('Branch inspection unavailable'),
    );
    semantics.dispose();
  });

  testWidgets('cycle and stale selection remain finite and selectable',
      (tester) async {
    await _pumpInspector(
      tester,
      width: 900,
      availability: ComputationBranchesAvailable(_cycleGraph()),
      initialBranchId: const ComputationBranchId('missing'),
      initialNodeId: const ComputationBranchNodeId('missing'),
    );

    expect(find.text('Cycle detected'), findsWidgets);
    expect(find.byKey(const ValueKey('computation-branch-node-a')), findsOne);
    expect(find.byKey(const ValueKey('computation-branch-node-b')), findsOne);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpInspector(
  WidgetTester tester, {
  required double width,
  ComputationBranchesAvailability? availability,
  ComputationBranchId? initialBranchId,
  ComputationBranchNodeId? initialNodeId,
  List<ComputationBranchId>? selectedBranches,
  List<ComputationBranchNodeId>? selectedNodes,
  List<ComputationBranchId>? highlightedBranches,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  var branchId = initialBranchId;
  var nodeId = initialNodeId;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setState) => Padding(
              padding: const EdgeInsets.all(8),
              child: SizedBox(
                width: width,
                child: ComputationBranchInspector(
                  availability:
                      availability ?? ComputationBranchesAvailable(_graph()),
                  selectedBranchId: branchId,
                  selectedNodeId: nodeId,
                  onBranchSelected: (id) {
                    selectedBranches?.add(id);
                    setState(() {
                      branchId = id;
                      nodeId = null;
                    });
                  },
                  onNodeSelected: (id) {
                    selectedNodes?.add(id);
                    setState(() => nodeId = id);
                  },
                  onBranchHighlightRequested: (id) {
                    highlightedBranches?.add(id);
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ComputationBranchGraph _graph() {
  return ComputationBranchGraph(
    nodes: [
      ComputationBranchNode(
        id: const ComputationBranchNodeId('root'),
        childIds: const [
          ComputationBranchNodeId('accepted'),
          ComputationBranchNodeId('dead'),
        ],
        configurationSummary: 'q0, input ab',
      ),
      ComputationBranchNode(
        id: const ComputationBranchNodeId('accepted'),
        parentId: const ComputationBranchNodeId('root'),
        configurationSummary: 'q1, input consumed',
        transitionSummary: 'Read ab',
        outcome: ComputationBranchOutcome.accepted,
      ),
      ComputationBranchNode(
        id: const ComputationBranchNodeId('dead'),
        parentId: const ComputationBranchNodeId('root'),
        configurationSummary: 'q2, input b',
        transitionSummary: 'Read a',
        outcome: ComputationBranchOutcome.dead,
      ),
    ],
    branches: [
      ComputationBranch(
        id: const ComputationBranchId('accept'),
        nodeIds: const [
          ComputationBranchNodeId('root'),
          ComputationBranchNodeId('accepted'),
        ],
        outcome: ComputationBranchOutcome.accepted,
      ),
      ComputationBranch(
        id: const ComputationBranchId('dead'),
        nodeIds: const [
          ComputationBranchNodeId('root'),
          ComputationBranchNodeId('dead'),
        ],
        outcome: ComputationBranchOutcome.dead,
      ),
    ],
    rootNodeIds: const [ComputationBranchNodeId('root')],
  );
}

ComputationBranchGraph _cycleGraph() {
  return ComputationBranchGraph(
    nodes: [
      ComputationBranchNode(
        id: const ComputationBranchNodeId('a'),
        parentId: const ComputationBranchNodeId('b'),
        childIds: const [ComputationBranchNodeId('b')],
        configurationSummary: 'A',
      ),
      ComputationBranchNode(
        id: const ComputationBranchNodeId('b'),
        parentId: const ComputationBranchNodeId('a'),
        childIds: const [ComputationBranchNodeId('a')],
        configurationSummary: 'B',
        outcome: ComputationBranchOutcome.cycle,
      ),
    ],
    branches: [
      ComputationBranch(
        id: const ComputationBranchId('cycle'),
        nodeIds: const [
          ComputationBranchNodeId('a'),
          ComputationBranchNodeId('b'),
          ComputationBranchNodeId('a'),
        ],
        outcome: ComputationBranchOutcome.cycle,
      ),
    ],
    rootNodeIds: const [ComputationBranchNodeId('a')],
  );
}

ComputationBranchGraph _largeGraph(int branchCount) {
  const rootId = ComputationBranchNodeId('large-root');
  final leafIds = List<ComputationBranchNodeId>.generate(
    branchCount,
    (index) => ComputationBranchNodeId('large-leaf-$index'),
    growable: false,
  );
  return ComputationBranchGraph(
    nodes: [
      ComputationBranchNode(
        id: rootId,
        childIds: leafIds,
        configurationSummary: 'root',
      ),
      for (var index = 0; index < branchCount; index++)
        ComputationBranchNode(
          id: leafIds[index],
          parentId: rootId,
          configurationSummary: 'leaf $index',
          outcome: ComputationBranchOutcome.dead,
        ),
    ],
    branches: [
      for (var index = 0; index < branchCount; index++)
        ComputationBranch(
          id: ComputationBranchId('branch-$index'),
          nodeIds: [rootId, leafIds[index]],
          outcome: ComputationBranchOutcome.dead,
        ),
    ],
    rootNodeIds: const [rootId],
  );
}

ComputationBranchGraph _longBranchGraph(int configurationCount) {
  final nodeIds = List<ComputationBranchNodeId>.generate(
    configurationCount,
    (index) => ComputationBranchNodeId('long-node-$index'),
    growable: false,
  );
  return ComputationBranchGraph(
    nodes: [
      for (var index = 0; index < configurationCount; index++)
        ComputationBranchNode(
          id: nodeIds[index],
          parentId: index == 0 ? null : nodeIds[index - 1],
          childIds:
              index == configurationCount - 1 ? const [] : [nodeIds[index + 1]],
          configurationSummary: 'configuration $index',
          outcome: index == configurationCount - 1
              ? ComputationBranchOutcome.accepted
              : null,
        ),
    ],
    branches: [
      ComputationBranch(
        id: const ComputationBranchId('long-branch'),
        nodeIds: nodeIds,
        outcome: ComputationBranchOutcome.accepted,
      ),
    ],
    rootNodeIds: [nodeIds.first],
  );
}
