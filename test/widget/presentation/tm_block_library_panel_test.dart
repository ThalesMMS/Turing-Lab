import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/state.dart' as domain;
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/tm_building_blocks.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/providers/tm_block_library_provider.dart';
import 'package:turing_lab/presentation/providers/tm_editor_provider.dart';
import 'package:turing_lab/presentation/widgets/tm/tm_block_library_panel.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  testWidgets(
    'creates, opens, and inserts a typed block on a narrow viewport',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final semantics = tester.ensureSemantics();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final root = _rootMachine();
      container.read(tmEditorProvider.notifier).setTm(root);
      container.read(tmBlockLibraryProvider.notifier).synchronize(root);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: TMBlockLibraryPanel()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Building block library'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Create block'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Create block'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Scan');
      await tester.tap(find.widgetWithText(FilledButton, 'Create block').last);
      await tester.pumpAndSettle();

      final scanTile = find.bySemanticsLabel('Scan');
      expect(scanTile, findsOneWidget);
      await tester.ensureVisible(scanTile);
      await tester.tap(scanTile);
      await tester.pumpAndSettle();
      final insertButton = find.text('Insert on root canvas');
      await tester.scrollUntilVisible(
        insertButton,
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(insertButton);
      await tester.pumpAndSettle();

      final machine = container.read(tmEditorProvider).tm!;
      expect(machine.blockDefinitions.keys, {'scan'});
      expect(machine.blockInvocations, hasLength(1));
      expect(machine.blockInvocations.single.reference.blockId, 'scan');
      expect(
        machine.states.map((state) => state.label),
        contains('Block: Scan'),
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  for (final scenario in const [
    (
      locale: Locale('en'),
      revision: 'Revision 1,234',
      summary: '1,234 states, 0 transitions',
    ),
    (
      locale: Locale('pt', 'BR'),
      revision: 'Revisão 1.234',
      summary: '1.234 estados, 0 transições',
    ),
  ]) {
    testWidgets(
      'groups building-block counts in ${scenario.locale.languageCode}',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final root = _rootMachineWithLargeBlock();
        container.read(tmEditorProvider.notifier).setTm(root);
        container.read(tmBlockLibraryProvider.notifier).synchronize(root);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              locale: scenario.locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(body: TMBlockLibraryPanel()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining(scenario.revision), findsOneWidget);
        expect(find.textContaining(scenario.summary), findsOneWidget);
        expect(find.textContaining('1234'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final scenario in const [
    (
      locale: Locale('en'),
      error: 'Block scan is still referenced. Choose an explicit resolution.',
      undo: 'Undo',
      redo: 'Redo',
    ),
    (
      locale: Locale('pt', 'BR'),
      error:
          'O bloco scan ainda está referenciado. Escolha uma resolução explícita.',
      undo: 'Desfazer',
      redo: 'Refazer',
    ),
  ]) {
    testWidgets(
      'localizes transactional errors in ${scenario.locale.languageCode} '
      'and keeps undo and redo reachable',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final root = _rootMachine();
        container.read(tmEditorProvider.notifier).setTm(root);
        final notifier = container.read(tmBlockLibraryProvider.notifier)
          ..synchronize(root)
          ..createDefinition('Scan')
          ..insertOnRootCanvas('scan');

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              locale: scenario.locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(body: TMBlockLibraryPanel()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        notifier.deleteDefinition('scan', detachInvocations: false);
        await tester.pumpAndSettle();
        final state = container.read(tmBlockLibraryProvider);
        expect(find.text(scenario.error), findsOneWidget);
        expect(find.byTooltip(scenario.undo), findsOneWidget);
        expect(find.byTooltip(scenario.redo), findsOneWidget);
        expect(state.canUndo, isTrue);
        expect(
          state.lastError?.stableCode,
          'service.tm-block-editor.referenced-block',
        );
        expect(state.lastError?.arguments['block']?.value, 'scan');
      },
    );
  }
}

TM _rootMachine() {
  final initial = domain.State(
    id: 'q0',
    label: 'q0',
    position: Vector2(100, 100),
    isInitial: true,
  );
  final now = DateTime.utc(2026);
  return TM(
    id: 'root',
    name: 'Root',
    states: {initial},
    transitions: const {},
    alphabet: {'0', '1'},
    initialState: initial,
    acceptingStates: const {},
    created: now,
    modified: now,
    bounds: const math.Rectangle(0, 0, 800, 600),
    tapeAlphabet: {'0', '1', 'B'},
    blankSymbol: 'B',
  );
}

TM _rootMachineWithLargeBlock() {
  final states = List<domain.State>.generate(
    1234,
    (index) => domain.State(
      id: 'q$index',
      label: 'q$index',
      position: Vector2(index.toDouble(), 0),
      isInitial: index == 0,
      isAccepting: index == 0,
    ),
    growable: false,
  );
  final now = DateTime.utc(2026);
  final blockMachine = TM(
    id: 'large:machine',
    name: 'Large block',
    states: states.toSet(),
    transitions: const {},
    alphabet: const {'0'},
    initialState: states.first,
    acceptingStates: {states.first},
    created: now,
    modified: now,
    bounds: const math.Rectangle(0, 0, 800, 600),
    tapeAlphabet: const {'0', 'B'},
  );
  return _rootMachine().copyWith(
    blockDefinitions: {
      'large': TMBlockDefinition(
        id: 'large',
        name: 'Large block',
        revision: 1234,
        machine: blockMachine,
      ),
    },
  );
}
