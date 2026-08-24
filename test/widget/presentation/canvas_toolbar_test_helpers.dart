import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> expandCanvasToolbar(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.open_in_full));
  await tester.pump(const Duration(milliseconds: 250));
}

Future<void> tapSecondaryCanvasAction(
  WidgetTester tester, {
  required String semanticLabel,
  required String menuLabel,
  required bool opensRoute,
}) async {
  final overflow = find.byKey(const ValueKey('canvas-toolbar-overflow'));
  if (overflow.evaluate().isNotEmpty) {
    await tester.tap(overflow);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(
      find
          .ancestor(
            of: find.text(menuLabel),
            matching: find.byWidgetPredicate(
              (widget) => widget is PopupMenuItem,
            ),
          )
          .last,
    );
    if (opensRoute) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump(const Duration(milliseconds: 400));
    }
    return;
  }

  final action = find.descendant(
    of: find.bySemanticsLabel(semanticLabel),
    matching: find.byType(IconButton),
  );
  tester.widget<IconButton>(action).onPressed!();
  if (opensRoute) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 200));
  }
}
