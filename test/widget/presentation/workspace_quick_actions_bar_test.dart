import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/l_systems/l_systems.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/providers/workspace_quick_actions_provider.dart';
import 'package:turing_lab/presentation/providers/workspace_registry_provider.dart';
import 'package:turing_lab/presentation/widgets/workspace_quick_actions_bar.dart';
import 'package:turing_lab/presentation/workspaces/workspace_quick_action.dart';

Future<ProviderContainer> _pumpProgressAction(
  WidgetTester tester, {
  required WorkspaceQuickActions actions,
  Locale locale = const Locale('en'),
}) async {
  final container = ProviderContainer(
    overrides: [
      formalSystemRegistryProvider.overrideWithValue(
        FormalSystemRegistry.defaultRegistry,
      ),
    ],
  );
  addTearDown(container.dispose);
  container
          .read(
            workspaceQuickActionsProvider(
              DefaultFormalSystemIds.regularPumping,
            ).notifier,
          )
          .state =
      actions;

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          appBar: AppBar(
            leading: const WorkspaceQuickActionsBar(
              workspaceKey: DefaultFormalSystemIds.regularPumping,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<ProviderContainer> _pumpExamplesAction(
  WidgetTester tester, {
  required WorkspaceQuickActions actions,
  Locale locale = const Locale('en'),
}) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  container
          .read(
            workspaceQuickActionsProvider(LSystemFormalSystemIds.key).notifier,
          )
          .state =
      actions;

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          appBar: AppBar(
            leading: const WorkspaceQuickActionsBar(
              workspaceKey: LSystemFormalSystemIds.key,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('Progress exposes a static label, metrics icon, and callback', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var taps = 0;

    await _pumpProgressAction(
      tester,
      actions: WorkspaceQuickActions(onProgress: () => taps++),
    );

    final action = find.byKey(
      const ValueKey('workspace-quick-action-progress'),
    );
    expect(action, findsOneWidget);
    expect(find.byTooltip('Progress'), findsOneWidget);
    expect(
      find.descendant(of: action, matching: find.byIcon(Icons.bar_chart)),
      findsOneWidget,
    );
    final data = tester.getSemantics(action).getSemanticsData();
    expect(data.hasAction(SemanticsAction.tap), isTrue);

    await tester.tap(action);
    await tester.pump();
    expect(taps, 1);
    semantics.dispose();
  });

  testWidgets('Progress supports Portuguese and a disabled state', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await _pumpProgressAction(
      tester,
      locale: const Locale('pt'),
      actions: WorkspaceQuickActions(onProgress: () {}, progressEnabled: false),
    );

    final action = find.byKey(
      const ValueKey('workspace-quick-action-progress'),
    );
    expect(find.byTooltip('Progresso'), findsOneWidget);
    final data = tester.getSemantics(action).getSemanticsData();
    expect(data.flagsCollection.isEnabled, Tristate.isFalse);
    expect(data.hasAction(SemanticsAction.tap), isFalse);
    semantics.dispose();
  });

  testWidgets('Examples exposes localized enabled and unavailable semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var taps = 0;
    await _pumpExamplesAction(
      tester,
      locale: const Locale('pt'),
      actions: WorkspaceQuickActions(onExamples: () => taps++),
    );

    final action = find.byKey(
      const ValueKey('workspace-quick-action-examples'),
    );
    expect(find.bySemanticsLabel('Exemplos'), findsOneWidget);
    expect(
      tester
          .getSemantics(action)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    await tester.tap(action);
    await tester.pump();
    expect(taps, 1);

    await _pumpExamplesAction(
      tester,
      actions: WorkspaceQuickActions(
        onExamples: () {},
        examplesEnabled: false,
        examplesTooltip: 'Examples unavailable',
      ),
    );
    expect(find.bySemanticsLabel('Examples unavailable'), findsOneWidget);
    final disabledData = tester.getSemantics(action).getSemanticsData();
    expect(disabledData.flagsCollection.isEnabled, Tristate.isFalse);
    expect(disabledData.hasAction(SemanticsAction.tap), isFalse);
    semantics.dispose();
  });

  test('Progress participates in capability filtering and value equality', () {
    void onProgress() {}

    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    final left = WorkspaceQuickActions(
      onProgress: onProgress,
      progressFocusNode: focusNode,
    );
    final right = WorkspaceQuickActions(
      onProgress: onProgress,
      progressFocusNode: focusNode,
    );

    expect(left, right);
    expect(left.hashCode, right.hashCode);
    final descriptor = FormalSystemRegistry.defaultRegistry.descriptorFor(
      DefaultFormalSystemIds.regularPumping,
    )!;
    final constrained = left.constrainedTo(
      capabilities: descriptor.capabilities,
      supportedActions: const {WorkspaceQuickAction.progress},
    );
    expect(constrained.onProgress, same(onProgress));
    expect(constrained.progressFocusNode, same(focusNode));
  });

  test('Examples participates in capability filtering and value equality', () {
    void onExamples() {}

    final left = WorkspaceQuickActions(
      onExamples: onExamples,
      examplesEnabled: false,
      examplesTooltip: 'Loading examples',
    );
    final right = WorkspaceQuickActions(
      onExamples: onExamples,
      examplesEnabled: false,
      examplesTooltip: 'Loading examples',
    );
    expect(left, right);
    expect(left.hashCode, right.hashCode);

    final constrained = left.constrainedTo(
      capabilities: const FormalSystemCapabilities(
        examples: SupportedCapability(),
      ),
      supportedActions: const {WorkspaceQuickAction.examples},
    );
    expect(constrained.onExamples, same(onExamples));
    expect(constrained.examplesEnabled, isFalse);
    expect(constrained.examplesTooltip, 'Loading examples');

    final unavailable = left.constrainedTo(
      capabilities: const FormalSystemCapabilities(),
      supportedActions: const {WorkspaceQuickAction.examples},
    );
    expect(unavailable.onExamples, isNull);
  });
}
