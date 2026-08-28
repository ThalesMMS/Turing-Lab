//
//  collapsible_canvas_panel_test.dart
//  Turing Lab
//
//  Verifies that a mobile canvas inspector can release its hit-test area
//  without discarding the live state of the wrapped panel: expanded panels
//  show no toggle and collapse when their body is tapped, while interactive
//  children keep winning the gesture arena.
//
//  Thales Matheus Mendonça Santos - August 2026
//

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/presentation/widgets/collapsible_canvas_panel.dart';
import 'package:turing_lab/presentation/widgets/movable_canvas_panel_host.dart';

class _StatefulProbe extends StatefulWidget {
  const _StatefulProbe();

  @override
  State<_StatefulProbe> createState() => _StatefulProbeState();
}

class _StatefulProbeState extends State<_StatefulProbe> {
  var count = 0;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () => setState(() => count++),
      child: Text('Probe $count'),
    );
  }
}

/// Taps a non-interactive corner of the expanded panel body.
Future<void> _tapPanelBody(WidgetTester tester, Finder panel) async {
  await tester.tapAt(tester.getTopLeft(panel) + const Offset(4, 4));
}

void main() {
  testWidgets('external controller opens, closes, and keeps body taps synced', (
    tester,
  ) async {
    final controller = CollapsibleCanvasPanelController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topRight,
            child: CollapsibleCanvasPanel(
              controller: controller,
              label: 'Stack',
              icon: Icons.layers,
              child: const SizedBox(
                width: 180,
                height: 160,
                child: Text('controlled panel'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(controller.expanded, isFalse);
    expect(find.text('controlled panel'), findsNothing);

    controller.open();
    await tester.pump();
    expect(controller.expanded, isTrue);
    expect(find.text('controlled panel'), findsOneWidget);

    await _tapPanelBody(tester, find.byType(CollapsibleCanvasPanel));
    await tester.pump();
    expect(controller.expanded, isFalse);
    expect(find.text('controlled panel'), findsNothing);

    controller.toggle();
    await tester.pump();
    expect(find.text('controlled panel'), findsOneWidget);

    controller.close();
    await tester.pump();
    expect(find.text('controlled panel'), findsNothing);
  });

  testWidgets('collapses on body tap, hides the toggle, and keeps state', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topRight,
            child: CollapsibleCanvasPanel(
              label: 'Stack',
              icon: Icons.layers,
              child: Padding(
                padding: EdgeInsets.all(24),
                child: _StatefulProbe(),
              ),
            ),
          ),
        ),
      ),
    );

    // While expanded, no toggle button is shown and interactive children
    // still receive their taps instead of collapsing the panel.
    expect(find.byType(IconButton), findsNothing);
    await tester.tap(find.text('Probe 0'));
    await tester.pump();
    expect(find.text('Probe 1'), findsOneWidget);
    expect(find.bySemanticsLabel('Collapse Stack panel'), findsOneWidget);

    await _tapPanelBody(tester, find.byType(CollapsibleCanvasPanel));
    await tester.pump();

    expect(find.text('Probe 1'), findsNothing);
    expect(find.text('Probe 1', skipOffstage: false), findsOneWidget);
    expect(find.bySemanticsLabel('Expand Stack panel'), findsOneWidget);
    expect(
      tester.getSize(find.byType(CollapsibleCanvasPanel)),
      const Size.square(48),
    );

    await tester.tap(find.byTooltip('Expand Stack panel'));
    await tester.pump();

    expect(find.text('Probe 1'), findsOneWidget);
    expect(find.byType(IconButton), findsNothing);
    expect(find.bySemanticsLabel('Collapse Stack panel'), findsOneWidget);
  });

  testWidgets('moves the expanded panel by its body and collapsed by icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MovableCanvasPanelHost(
            builder:
                (context, {required onDragDelta, required onPanelSizeChanged}) {
                  return CollapsibleCanvasPanel(
                    key: const ValueKey('movable-panel'),
                    label: 'Stack',
                    icon: Icons.layers,
                    onDragDelta: onDragDelta,
                    onPanelSizeChanged: onPanelSizeChanged,
                    child: const SizedBox(width: 180, height: 160),
                  );
                },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final panel = find.byKey(const ValueKey('movable-panel'));
    final expandedStart = tester.getTopLeft(panel);
    await tester.drag(panel, const Offset(-80, 90));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(panel), isNot(expandedStart));

    await _tapPanelBody(tester, panel);
    await tester.pumpAndSettle();
    expect(tester.getSize(panel), const Size.square(48));

    final collapsedStart = tester.getTopLeft(panel);
    await tester.drag(
      find.byTooltip('Expand Stack panel'),
      const Offset(-40, 50),
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(panel), isNot(collapsedStart));
  });

  testWidgets('keeps the top-right corner anchored across collapse/expand', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MovableCanvasPanelHost(
            builder:
                (context, {required onDragDelta, required onPanelSizeChanged}) {
                  return CollapsibleCanvasPanel(
                    key: const ValueKey('anchored-panel'),
                    label: 'Tape',
                    icon: Icons.horizontal_rule,
                    onDragDelta: onDragDelta,
                    onPanelSizeChanged: onPanelSizeChanged,
                    child: const SizedBox(width: 220, height: 160),
                  );
                },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final panel = find.byKey(const ValueKey('anchored-panel'));
    final expandedTopRight = tester.getTopRight(panel);

    await _tapPanelBody(tester, panel);
    await tester.pumpAndSettle();
    expect(tester.getTopRight(panel), expandedTopRight);

    await tester.tap(find.byTooltip('Expand Tape panel'));
    await tester.pumpAndSettle();
    expect(tester.getTopRight(panel), expandedTopRight);

    await tester.drag(panel, const Offset(-80, 90));
    await tester.pumpAndSettle();
    final movedTopRight = tester.getTopRight(panel);
    expect(movedTopRight, isNot(expandedTopRight));

    await _tapPanelBody(tester, panel);
    await tester.pumpAndSettle();
    expect(tester.getTopRight(panel), movedTopRight);

    await tester.tap(find.byTooltip('Expand Tape panel'));
    await tester.pumpAndSettle();
    expect(tester.getTopRight(panel), movedTopRight);
  });

  testWidgets('clamps a moved panel inside the viewport', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MovableCanvasPanelHost(
            builder:
                (context, {required onDragDelta, required onPanelSizeChanged}) {
                  return CollapsibleCanvasPanel(
                    key: const ValueKey('bounded-panel'),
                    label: 'Tape',
                    icon: Icons.horizontal_rule,
                    onDragDelta: onDragDelta,
                    onPanelSizeChanged: onPanelSizeChanged,
                    child: const SizedBox(width: 220, height: 120),
                  );
                },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final panel = find.byKey(const ValueKey('bounded-panel'));
    final viewport = tester.getRect(find.byType(Scaffold));

    await tester.drag(panel, const Offset(-2000, -2000));
    await tester.pumpAndSettle();
    var rect = tester.getRect(panel);
    expect(rect.left, greaterThanOrEqualTo(viewport.left + 8));
    expect(rect.top, greaterThanOrEqualTo(viewport.top + 8));

    await tester.drag(panel, const Offset(2000, 2000));
    await tester.pumpAndSettle();
    rect = tester.getRect(panel);
    expect(rect.right, lessThanOrEqualTo(viewport.right - 8));
    expect(rect.bottom, lessThanOrEqualTo(viewport.bottom - 8));
  });
}
