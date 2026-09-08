import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/presentation/widgets/automaton_diagnostic_highlight_bar.dart';
import 'package:turing_lab/presentation/widgets/collapsible_canvas_panel.dart';

void main() {
  testWidgets(
    'diagnostics start top-left, accept clicks, and move with a mouse',
    (tester) async {
      var conflictSelected = false;
      var canvasTaps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => canvasTaps++,
                  ),
                ),
                AutomatonDiagnosticHighlightBar(
                  floating: true,
                  activeKind: null,
                  conflictCount: 2,
                  epsilonCount: 1,
                  onConflictSelected: (value) => conflictSelected = value,
                  onEpsilonSelected: (_) {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final panel = find.byType(CollapsibleCanvasPanel);
      expect(tester.getTopLeft(panel), const Offset(16, 16));
      await tester.tap(
        find.byKey(const ValueKey('highlight-conflicting-transitions')),
      );
      await tester.pumpAndSettle();
      expect(conflictSelected, isTrue);
      expect(find.byType(FilterChip), findsNWidgets(2));

      Future<void> dragWithMouse() async {
        final start = tester.getTopLeft(panel) + const Offset(8, 8);
        final gesture = await tester.startGesture(
          start,
          kind: PointerDeviceKind.mouse,
        );
        await gesture.moveBy(const Offset(20, 20));
        await gesture.moveBy(const Offset(90, 100));
        await gesture.up();
        await tester.pumpAndSettle();
      }

      final initial = tester.getTopLeft(panel);
      await dragWithMouse();
      expect(tester.getTopLeft(panel).dx, greaterThan(initial.dx));
      expect(tester.getTopLeft(panel).dy, greaterThan(initial.dy));
      await tester.tap(find.byIcon(Icons.expand_less));
      await tester.pumpAndSettle();
      expect(tester.getSize(panel), const Size.square(48));
      expect(find.byType(FilterChip), findsNothing);
      final collapsed = tester.getTopLeft(panel);
      await dragWithMouse();
      expect(tester.getTopLeft(panel).dx, greaterThan(collapsed.dx));
      await tester.tap(find.byIcon(Icons.rule));
      await tester.pumpAndSettle();
      expect(find.byType(FilterChip), findsNWidgets(2));
      await tester.tapAt(const Offset(700, 500));
      expect(canvasTaps, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
