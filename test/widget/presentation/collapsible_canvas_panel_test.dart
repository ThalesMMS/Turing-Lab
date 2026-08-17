//
//  collapsible_canvas_panel_test.dart
//  Turing Lab
//
//  Verifies that a mobile canvas inspector can release its hit-test area
//  without discarding the live state of the wrapped panel.
//
//  Thales Matheus Mendonça Santos - August 2026
//

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/presentation/widgets/collapsible_canvas_panel.dart';

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

void main() {
  testWidgets('collapses to 48pt and preserves the live child state', (
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
              child: _StatefulProbe(),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Probe 0'));
    await tester.pump();
    expect(find.text('Probe 1'), findsOneWidget);
    expect(find.bySemanticsLabel('Collapse Stack panel'), findsOneWidget);

    await tester.tap(find.byTooltip('Collapse Stack panel'));
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
    expect(find.bySemanticsLabel('Collapse Stack panel'), findsOneWidget);
  });
}
