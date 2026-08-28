import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/l_systems/l_systems.dart';
import 'package:turing_lab/data/l_systems/l_system_examples.dart';
import 'package:turing_lab/presentation/l_systems/l_system_editor_controller.dart';
import 'package:turing_lab/presentation/l_systems/l_system_png_rasterizer.dart';
import 'package:turing_lab/presentation/l_systems/l_system_workspace.dart';

void main() {
  testWidgets('integrates history and visualization actions in one toolbar', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var semanticsDisposed = false;
    addTearDown(() {
      if (!semanticsDisposed) semantics.dispose();
    });
    final controller = LSystemEditorController(
      document: LSystemExamples.values.first.document,
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: LSystemWorkspace(controller: controller)),
      ),
    );
    await tester.pumpAndSettle();

    const toolbarKey = Key('l-system-visualization-toolbar');
    const undoKey = Key('l-system-undo');
    const redoKey = Key('l-system-redo');
    final toolbar = find.byKey(toolbarKey);
    final undo = find.byKey(undoKey);
    final redo = find.byKey(redoKey);
    expect(toolbar, findsOneWidget);
    expect(find.ancestor(of: toolbar, matching: find.byType(Card)), findsOne);
    expect(
      find.descendant(of: toolbar, matching: find.byType(IconButton)),
      findsNWidgets(8),
    );
    expect(
      tester
          .widgetList<IconButton>(
            find.descendant(of: toolbar, matching: find.byType(IconButton)),
          )
          .every((button) => button.style == null),
      isTrue,
    );
    expect(
      tester.getSemantics(undo).getSemanticsData().flagsCollection.isEnabled,
      ui.Tristate.isFalse,
    );
    expect(
      tester.getSemantics(redo).getSemanticsData().flagsCollection.isEnabled,
      ui.Tristate.isFalse,
    );

    controller.replaceDocument(
      controller.document.copyWith(revision: controller.document.revision + 1),
    );
    await tester.pump();
    expect(
      tester.getSemantics(undo).getSemanticsData().flagsCollection.isEnabled,
      ui.Tristate.isTrue,
    );
    await tester.ensureVisible(undo);
    await tester.tap(undo);
    await tester.pumpAndSettle();
    expect(controller.canRedo, isTrue);
    await tester.tap(redo);
    await tester.pumpAndSettle();
    expect(controller.document.revision, 1);

    semantics.dispose();
    semanticsDisposed = true;
  });

  testWidgets('cancel expansion remains in the visualization toolbar', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    final original = LSystemExamples.values.first.document;
    final controller = LSystemEditorController(
      document: original.copyWith(
        axiom: LSystemWord(List.filled(1024, 'F')),
        iterations: 4,
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(body: LSystemWorkspace(controller: controller)),
      ),
    );

    final toolbar = find.byKey(const Key('l-system-visualization-toolbar'));
    final cancel = find.widgetWithText(FilledButton, 'Cancel expansion');
    expect(controller.isExpanding, isTrue);
    await tester.pump();
    expect(find.descendant(of: toolbar, matching: cancel), findsOneWidget);
    await tester.ensureVisible(cancel);
    await tester.tap(cancel);
    await tester.pumpAndSettle();

    expect(controller.status, LSystemEditorStatus.cancelled);
    expect(find.textContaining('Expansion cancelled.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reflows at 320 px, 200 percent text, and exposes geometry', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var semanticsDisposed = false;
    addTearDown(() {
      if (!semanticsDisposed) semantics.dispose();
    });
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    final controller = LSystemEditorController(
      document: LSystemExamples.values.first.document,
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(body: LSystemWorkspace(controller: controller)),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('l-system-canvas')), findsOneWidget);
    expect(find.text('Turtle command mapping'), findsOneWidget);
    final canvasSemantics = tester.getSemantics(
      find.byKey(const Key('l-system-canvas')),
    );
    expect(canvasSemantics.getSemanticsData().flagsCollection.isImage, isTrue);
    semantics.dispose();
    semanticsDisposed = true;
  });

  testWidgets('honors reduced motion for generation playback', (tester) async {
    final controller = LSystemEditorController(
      document: LSystemExamples.values.first.document,
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(body: LSystemWorkspace(controller: controller)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final play = find.byTooltip('Play generations');
    await tester.ensureVisible(play);
    await tester.tap(play);
    await tester.pump();
    expect(
      find.text('Animation is disabled by reduced-motion settings.'),
      findsOneWidget,
    );
  });

  testWidgets('edits command mapping and complete turtle settings', (
    tester,
  ) async {
    final controller = LSystemEditorController(
      document: LSystemExamples.values.first.document,
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: LSystemWorkspace(controller: controller)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Turtle command mapping'),
      'F = moveForward\n+ = turnRight',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Scale'), '2');
    await tester.enterText(find.widgetWithText(TextField, 'Heading °'), '-90');
    await tester.enterText(find.widgetWithText(TextField, 'Origin X'), '-4');
    await tester.enterText(find.widgetWithText(TextField, 'Origin Y'), '8');
    await tester.enterText(find.widgetWithText(TextField, 'Line width'), '3');
    await tester.enterText(
      find.widgetWithText(TextField, 'Width change'),
      '1.5',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Hue change °'),
      '30',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Random seed'), '-9');
    await tester.enterText(
      find.widgetWithText(TextField, 'Context-ignored tokens'),
      '+ -',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Parallel production rules'),
      'L < F > R @2 -> F\nL < F > R -> G',
    );
    final apply = find.text('Apply and expand');
    await tester.ensureVisible(apply);
    await tester.tap(apply);
    await tester.pumpAndSettle();

    expect(controller.document.turtle.scale, 2);
    expect(controller.document.turtle.initialHeadingDegrees, -90);
    expect(controller.document.turtle.initialX, -4);
    expect(controller.document.turtle.initialY, 8);
    expect(controller.document.turtle.lineWidth, 3);
    expect(controller.document.turtle.lineWidthIncrement, 1.5);
    expect(controller.document.turtle.hueIncrementDegrees, 30);
    expect(controller.document.randomSeed, -9);
    expect(controller.document.ignoredContextSymbols, {'+', '-'});
    expect(controller.document.productions, hasLength(2));
    expect(controller.document.productions.first.leftContext.symbols, ['L']);
    expect(controller.document.productions.first.rightContext.symbols, ['R']);
    expect(controller.document.productions.first.weight, 2);
    expect(
      controller.document.commandMapping.commands['F']?.name,
      'moveForward',
    );
    expect(controller.document.commandMapping.commands['+']?.name, 'turnRight');
  });

  testWidgets('PNG rasterizer returns requested dimensions', (tester) async {
    final controller = LSystemEditorController(
      document: LSystemExamples.values.first.document,
    );
    addTearDown(controller.dispose);
    await controller.run(generation: 1);
    await tester.runAsync(() async {
      final bytes = await const FlutterLSystemPngRasterizer().encode(
        controller.geometry!,
        metadata: LSystemRenderMetadata(
          documentId: controller.document.id,
          sourceRevision: controller.document.revision,
          generation: controller.generation!.index,
          settings: controller.document.turtle,
        ),
        width: 96,
        height: 64,
      );

      expect(bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      try {
        expect(frame.image.width, 96);
        expect(frame.image.height, 64);
      } finally {
        frame.image.dispose();
        codec.dispose();
      }
    });
  });
}
