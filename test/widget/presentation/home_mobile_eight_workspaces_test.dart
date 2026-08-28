import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/services/simulation_highlight_service.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/pages/home_page.dart';
import 'package:turing_lab/presentation/providers/workspace_registry_provider.dart';
import 'package:turing_lab/presentation/widgets/navigation_item.dart';
import 'package:turing_lab/presentation/widgets/workspace_selector.dart';
import 'package:turing_lab/presentation/workspaces/workspace_presentation_module.dart';
import 'package:turing_lab/presentation/workspaces/workspace_presentation_registry.dart';

void main() {
  testWidgets(
    'Home reflows eight mobile workspaces at 320 px and 200 percent text',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var semanticsDisposed = false;
      addTearDown(() {
        if (!semanticsDisposed) semantics.dispose();
      });
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.physicalSize = const Size(960, 2100);
      tester.view.devicePixelRatio = 3;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workspacePresentationRegistryProvider.overrideWithValue(
              _eightWorkspaceRegistry(),
            ),
            canvasHighlightServiceProvider.overrideWithValue(
              SimulationHighlightService(),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: const HomePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(WorkspaceSelector), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(
        tester
            .widget<Scaffold>(find.byType(Scaffold).first)
            .bottomNavigationBar,
        isNull,
      );
      expect(find.text('Workspace 1'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_drop_down));
      await tester.pumpAndSettle();
      for (var index = 1; index <= 8; index++) {
        final item = find.bySemanticsLabel('Navigate to Workspace $index');
        expect(item, findsOneWidget);
        final data = tester.getSemantics(item).getSemanticsData();
        expect(data.flagsCollection.isButton, isTrue);
        expect(data.hint, 'Description $index');
        expect(
          data.flagsCollection.isSelected,
          index == 1 ? Tristate.isTrue : Tristate.isFalse,
        );
      }

      await tester.tap(find.bySemanticsLabel('Navigate to Workspace 8'));
      await tester.pumpAndSettle();
      expect(find.text('Page 8'), findsOneWidget);
      expect(find.text('Workspace 8'), findsOneWidget);
      expect(find.bySemanticsLabel('Navigate to Workspace 8'), findsNothing);
      semantics.dispose();
      semanticsDisposed = true;
    },
  );

  testWidgets('keyboard opens and dismisses the compact workspace selector', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final selected = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          appBar: AppBar(
            title: WorkspaceSelector(
              currentIndex: 0,
              onSelected: selected.add,
              items: _eightNavigationItems,
              compact: true,
            ),
          ),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Navigate to Workspace 8'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Workspace: Workspace 1'))
          .getSemanticsData()
          .flagsCollection
          .isExpanded,
      Tristate.isTrue,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Navigate to Workspace 8'), findsNothing);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Workspace: Workspace 1'))
          .getSemanticsData()
          .flagsCollection
          .isExpanded,
      Tristate.isFalse,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(selected, [1]);
    semantics.dispose();
  });

  testWidgets('a short viewport scrolls to every workspace destination', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(320, 240);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          appBar: AppBar(
            title: WorkspaceSelector(
              currentIndex: 0,
              onSelected: (_) {},
              items: _eightNavigationItems,
              compact: true,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.arrow_drop_down));
    await tester.pumpAndSettle();
    final last = find.bySemanticsLabel('Navigate to Workspace 8');
    expect(last, findsOneWidget);
    await tester.ensureVisible(last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.getBottomRight(last).dy, lessThanOrEqualTo(240));
  });
}

const _eightNavigationItems = <NavigationItem>[
  NavigationItem(
    label: 'Workspace 1',
    icon: Icons.looks_one,
    description: 'Description 1',
  ),
  NavigationItem(
    label: 'Workspace 2',
    icon: Icons.looks_two,
    description: 'Description 2',
  ),
  NavigationItem(
    label: 'Workspace 3',
    icon: Icons.looks_3,
    description: 'Description 3',
  ),
  NavigationItem(
    label: 'Workspace 4',
    icon: Icons.looks_4,
    description: 'Description 4',
  ),
  NavigationItem(
    label: 'Workspace 5',
    icon: Icons.looks_5,
    description: 'Description 5',
  ),
  NavigationItem(
    label: 'Workspace 6',
    icon: Icons.looks_6,
    description: 'Description 6',
  ),
  NavigationItem(
    label: 'Workspace 7',
    icon: Icons.filter_7,
    description: 'Description 7',
  ),
  NavigationItem(
    label: 'Workspace 8',
    icon: Icons.filter_8,
    description: 'Description 8',
  ),
];

WorkspacePresentationRegistry _eightWorkspaceRegistry() =>
    WorkspacePresentationRegistry([
      for (var index = 0; index < _eightNavigationItems.length; index++)
        WorkspacePresentationModule(
          descriptor: FormalSystemDescriptor(
            key: FormalSystemKey(
              type: FormalSystemTypeId('test-${index + 1}'),
              variant: const FormalSystemVariantId('default'),
            ),
            schema: DocumentSchemaDescriptor(
              id: DocumentSchemaId('test.workspace.${index + 1}'),
              version: const DocumentSchemaVersion(1),
            ),
            route: WorkspaceRouteId('/test-${index + 1}'),
            category: FormalSystemCategory.learning,
            localizationNamespace: CapabilityNamespaceId(
              'formal.test.${index + 1}',
            ),
            semanticsNamespace: CapabilityNamespaceId(
              'semantics.test.${index + 1}',
            ),
            capabilities: const FormalSystemCapabilities(),
          ),
          icon: _eightNavigationItems[index].icon,
          pageBuilder: (_) => Center(child: Text('Page ${index + 1}')),
          helpTopicId: 'test-${index + 1}',
          navigationLabel: (_) => _eightNavigationItems[index].label,
          navigationDescription: (_) =>
              _eightNavigationItems[index].description,
          quickActions: const {},
        ),
    ]);
