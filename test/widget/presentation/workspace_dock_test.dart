import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/presentation/widgets/workspace_dock.dart';

void main() {
  Future<void> pumpDock(
    WidgetTester tester, {
    WorkspaceDockController? controller,
    FocusNode? externalFocusNode,
  }) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              if (controller != null && externalFocusNode != null)
                IconButton(
                  key: const ValueKey('external-panel-trigger'),
                  focusNode: externalFocusNode,
                  tooltip: 'Open details',
                  onPressed: () => controller.togglePanel(
                    'details',
                    returnFocusTo: externalFocusNode,
                  ),
                  icon: const Icon(Icons.open_in_new),
                ),
              Expanded(
                child: WorkspaceDock(
                  controller: controller,
                  content: const Text('workspace content'),
                  panels: const [
                    WorkspaceDockPanel(
                      id: 'details',
                      label: 'Details',
                      icon: Icons.info_outline,
                      child: Text('details panel'),
                    ),
                    WorkspaceDockPanel(
                      id: 'history',
                      label: 'History',
                      icon: Icons.history,
                      child: Text('history panel'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('remains autonomous when no controller is supplied', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpDock(tester);

    expect(find.text('details panel'), findsNothing);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Show Details'))
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );

    await tester.tap(find.byKey(WorkspaceDock.railButtonKey('details')));
    await tester.pump();
    expect(find.text('details panel'), findsOneWidget);

    await tester.tap(find.byKey(WorkspaceDock.railButtonKey('details')));
    await tester.pump();
    expect(find.text('details panel'), findsNothing);
    semantics.dispose();
  });

  testWidgets('external controller synchronizes rail and close button', (
    tester,
  ) async {
    final controller = WorkspaceDockController();
    addTearDown(controller.dispose);
    await pumpDock(tester, controller: controller);

    controller.openPanel('details');
    await tester.pump();

    expect(controller.openPanelId, 'details');
    expect(find.text('details panel'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.descendant(
              of: find.byKey(WorkspaceDock.railButtonKey('details')),
              matching: find.byType(IconButton),
            ),
          )
          .isSelected,
      isTrue,
    );

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();

    expect(controller.openPanelId, isNull);
    expect(find.text('details panel'), findsNothing);
    expect(
      tester
          .widget<IconButton>(
            find.descendant(
              of: find.byKey(WorkspaceDock.railButtonKey('details')),
              matching: find.byType(IconButton),
            ),
          )
          .isSelected,
      isFalse,
    );
  });

  testWidgets('panel scroll override keeps an owned viewport bounded', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WorkspaceDock(
            initialPanelId: 'viewport',
            content: Text('workspace content'),
            panels: [
              WorkspaceDockPanel(
                id: 'viewport',
                label: 'Viewport',
                icon: Icons.view_stream,
                scrollable: false,
                child: CustomScrollView(
                  slivers: [SliverToBoxAdapter(child: Text('owned viewport'))],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    final panel = find.byKey(WorkspaceDock.panelKey('viewport'));
    expect(
      find.descendant(of: panel, matching: find.byType(CustomScrollView)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: panel, matching: find.byType(SingleChildScrollView)),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('closing restores focus to the external panel trigger', (
    tester,
  ) async {
    final controller = WorkspaceDockController();
    final triggerFocusNode = FocusNode(debugLabel: 'External panel trigger');
    addTearDown(controller.dispose);
    addTearDown(triggerFocusNode.dispose);
    await pumpDock(
      tester,
      controller: controller,
      externalFocusNode: triggerFocusNode,
    );

    await tester.tap(find.byKey(const ValueKey('external-panel-trigger')));
    await tester.pump();
    expect(controller.openPanelId, 'details');

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    await tester.pump();

    expect(controller.openPanelId, isNull);
    expect(triggerFocusNode.hasFocus, isTrue);
  });

  testWidgets('panel close restores focus to the rail button that opened it', (
    tester,
  ) async {
    await pumpDock(tester);
    final rail = find.byKey(WorkspaceDock.railButtonKey('details'));

    await tester.tap(rail);
    await tester.pump();
    final railButton = tester.widget<IconButton>(
      find.descendant(of: rail, matching: find.byType(IconButton)),
    );

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    await tester.pump();

    expect(find.text('details panel'), findsNothing);
    expect(railButton.focusNode!.hasFocus, isTrue);
  });

  test('notifies only when the requested panel state changes', () {
    final controller = WorkspaceDockController();
    addTearDown(controller.dispose);
    var notifications = 0;
    controller.addListener(() => notifications++);

    controller.openPanel('details');
    controller.openPanel('details');
    expect(notifications, 1);

    controller.togglePanel('history');
    expect(controller.openPanelId, 'history');
    expect(notifications, 2);

    controller.closePanel(restoreFocus: false);
    controller.closePanel(restoreFocus: false);
    expect(controller.openPanelId, isNull);
    expect(notifications, 3);
  });
}
