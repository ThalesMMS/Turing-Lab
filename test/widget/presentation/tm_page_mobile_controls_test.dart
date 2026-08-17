import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/pages/tm_page.dart';
import 'package:turing_lab/presentation/providers/unified_trace_provider.dart';
import 'package:turing_lab/presentation/widgets/canvas_quick_actions.dart';
import 'package:turing_lab/presentation/widgets/context_aware_help_panel.dart';
import 'package:turing_lab/presentation/widgets/keyboard_shortcuts_dialog.dart';
import 'package:turing_lab/presentation/widgets/mobile_automaton_controls.dart';
import 'package:turing_lab/presentation/widgets/tm_canvas_graphview.dart';
import 'package:turing_lab/presentation/widgets/tm/tape_drawer.dart';

Future<void> _pumpMobileTmPage(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TMPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('empty TM mobile keeps help reachable from both surfaces', (
    tester,
  ) async {
    await _pumpMobileTmPage(tester);

    final trayHelp = find.descendant(
      of: find.byType(MobileAutomatonControls),
      matching: find.byTooltip('Help'),
    );
    final quickHelp = find.descendant(
      of: find.byType(CanvasQuickActions),
      matching: find.byTooltip('Help'),
    );
    expect(trayHelp, findsOneWidget);
    expect(quickHelp, findsOneWidget);

    await tester.tap(trayHelp);
    await tester.pumpAndSettle();

    expect(find.byType(ContextAwareHelpPanel), findsOneWidget);
    await tester.tap(find.widgetWithIcon(TextButton, Icons.keyboard));
    await tester.pumpAndSettle();

    expect(find.byType(ContextAwareHelpPanel), findsNothing);
    expect(find.byType(KeyboardShortcutsDialog), findsOneWidget);
  });

  testWidgets('TMPage mobile exposes and toggles transition mode', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var semanticsDisposed = false;
    addTearDown(() {
      if (!semanticsDisposed) {
        semantics.dispose();
        semanticsDisposed = true;
      }
    });
    await _pumpMobileTmPage(tester);

    final select = find.bySemanticsLabel('Select');
    final addTransition = find.bySemanticsLabel('Add transition');
    final originalCanvas = tester.widget<TMCanvasGraphView>(
      find.byType(TMCanvasGraphView),
    );

    expect(select, findsOneWidget);
    expect(addTransition, findsOneWidget);
    expect(
      tester
          .getSemantics(addTransition)
          .getSemanticsData()
          .flagsCollection
          .isToggled,
      Tristate.isFalse,
    );

    await tester.tap(addTransition);
    await tester.pump();

    expect(
      tester.widget<TMCanvasGraphView>(find.byType(TMCanvasGraphView)),
      same(originalCanvas),
    );

    expect(
      tester
          .getSemantics(addTransition)
          .getSemanticsData()
          .flagsCollection
          .isToggled,
      Tristate.isTrue,
    );

    await tester.tap(addTransition);
    await tester.pump();

    expect(
      tester.getSemantics(select).getSemanticsData().flagsCollection.isToggled,
      Tristate.isTrue,
    );

    semantics.dispose();
    semanticsDisposed = true;
  });

  testWidgets('TMPage mobile selects add-state mode when adding a state', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var semanticsDisposed = false;
    addTearDown(() {
      if (!semanticsDisposed) {
        semantics.dispose();
        semanticsDisposed = true;
      }
    });
    await _pumpMobileTmPage(tester);

    final addState = find.bySemanticsLabel('Add state');
    await tester.tap(addState);
    await tester.pump();

    expect(
      tester
          .getSemantics(addState)
          .getSemanticsData()
          .flagsCollection
          .isToggled,
      Tristate.isTrue,
    );

    semantics.dispose();
    semanticsDisposed = true;
  });

  testWidgets('TMPage mobile Clear resets tape and remains undoable', (
    tester,
  ) async {
    await _pumpMobileTmPage(tester);
    final canvas = tester.widget<TMCanvasGraphView>(
      find.byType(TMCanvasGraphView),
    );
    final controller = canvas.controller!;
    controller.addStateAt(const Offset(120, 120));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Clear canvas'));
    await tester.pumpAndSettle();

    final tapePanel = tester.widget<TMTapePanel>(find.byType(TMTapePanel));
    expect(tapePanel.tapeState.isEmpty, isTrue);
    expect(tapePanel.tapeState.blankSymbol, 'B');
    expect(controller.nodes, isEmpty);
    expect(controller.canUndo, isTrue);
    expect(controller.undo(), isTrue);
    await tester.pumpAndSettle();
    expect(controller.nodes, hasLength(1));
  });
}
