import 'dart:ui' show SemanticsAction, SemanticsFlag;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/semantics.dart' show SemanticsNode;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/constants/help_topic_ids.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/pages/help_page.dart';
import 'package:turing_lab/presentation/widgets/help_tree_view.dart';

bool _hasExpandedDisclosureFlags(SemanticsNode node) {
  // Flutter 3.27 exposes semantic flags through hasFlag.
  // ignore: deprecated_member_use
  return node.hasFlag(SemanticsFlag.isHeader) &&
      // ignore: deprecated_member_use
      node.hasFlag(SemanticsFlag.isButton) &&
      // ignore: deprecated_member_use
      node.hasFlag(SemanticsFlag.hasExpandedState) &&
      // ignore: deprecated_member_use
      node.hasFlag(SemanticsFlag.isExpanded);
}

Future<void> _pumpHelpPage(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  Size size = const Size(430, 932),
  String? initialTopicId,
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo,
            brightness: brightness,
          ),
        ),
        home: HelpPage(initialTopicId: initialTopicId),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _node(String id) => find.byKey(ValueKey('help-node-$id'));
Finder _body(String id) => find.byKey(ValueKey('help-body-$id'));

void main() {
  testWidgets(
    'keeps quick start inside the tree instead of a parallel action',
    (tester) async {
      await _pumpHelpPage(tester);

      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byIcon(Icons.rocket_launch),
        ),
        findsNothing,
      );
      expect(find.byIcon(Icons.rocket_launch), findsOneWidget);
      expect(_node(HelpTopicIds.gettingStartedQuickStart), findsOneWidget);
    },
  );

  testWidgets('uses one centered vertical tree at every target width', (
    tester,
  ) async {
    const scenarios = [
      (Size(390, 844), Brightness.light, 358.0),
      (Size(1024, 768), Brightness.dark, 880.0),
      (Size(1600, 1000), Brightness.light, 880.0),
    ];

    for (final (size, brightness, expectedWidth) in scenarios) {
      await _pumpHelpPage(tester, size: size, brightness: brightness);

      expect(find.byType(PageView), findsNothing, reason: '$size');
      expect(find.byType(FilterChip), findsNothing, reason: '$size');
      expect(find.byType(ChoiceChip), findsNothing, reason: '$size');
      expect(find.byType(NavigationRail), findsNothing, reason: '$size');
      expect(find.byType(ListView), findsOneWidget, reason: '$size');
      expect(
        tester.widget<ListView>(find.byType(ListView)).scrollDirection,
        Axis.vertical,
        reason: '$size',
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              (widget.axisDirection == AxisDirection.left ||
                  widget.axisDirection == AxisDirection.right),
        ),
        findsNothing,
        reason: '$size',
      );
      expect(
        tester.getSize(_node('getting-started')).width,
        closeTo(expectedWidth, 0.01),
        reason: '$size',
      );
      expect(
        Theme.of(tester.element(_node('getting-started'))).brightness,
        brightness,
        reason: '$size',
      );
      expect(tester.takeException(), isNull, reason: '$size');
    }
  });

  testWidgets('keeps multiple groups open and expands topic bodies inline', (
    tester,
  ) async {
    await _pumpHelpPage(tester, size: const Size(1200, 1000));

    await tester.tap(_node('fsa'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      _node('grammar'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.tap(_node('grammar'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      _node(HelpTopicIds.gettingStartedQuickStart),
      find.byType(ListView),
      const Offset(0, 300),
    );
    await tester.tap(_node(HelpTopicIds.gettingStartedQuickStart));
    await tester.pumpAndSettle();

    expect(_body(HelpTopicIds.gettingStartedQuickStart), findsOneWidget);
    expect(find.textContaining('shortest path from the Home page'), findsOne);
    await tester.dragUntilVisible(
      _node('grammar.editor'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    expect(_node('grammar.editor'), findsOneWidget);
    await tester.dragUntilVisible(
      _node('fsa.editor'),
      find.byType(ListView),
      const Offset(0, 300),
    );
    expect(_node('fsa.editor'), findsOneWidget);
  });

  testWidgets('keeps a node identity and focus when earlier rows are removed', (
    tester,
  ) async {
    await _pumpHelpPage(tester, size: const Size(1200, 1000));
    final tree = tester.widget<HelpTreeView>(find.byType(HelpTreeView));
    final fsaBefore = tester.element(_node('fsa'));

    tester.widget<InkWell>(_node('fsa')).focusNode!.requestFocus();
    await tester.pump();
    expect(tester.widget<InkWell>(_node('fsa')).focusNode!.hasFocus, isTrue);

    tree.controller.toggle('getting-started');
    await tester.pump();

    expect(tester.element(_node('fsa')), same(fsaBefore));
    expect(tester.widget<InkWell>(_node('fsa')).focusNode!.hasFocus, isTrue);
  });

  testWidgets('sliver entry mapping accounts for feedback offsets', (
    tester,
  ) async {
    await _pumpHelpPage(tester, initialTopicId: 'missing.topic');

    var list = tester.widget<ListView>(find.byType(ListView));
    var delegate = list.childrenDelegate as SliverChildBuilderDelegate;
    expect(
      delegate.findChildIndexCallback?.call(
        const ValueKey('help-entry-unavailable'),
      ),
      0,
    );
    expect(
      delegate.findChildIndexCallback?.call(
        const ValueKey('help-entry-getting-started'),
      ),
      1,
    );
    expect(
      delegate.findChildIndexCallback?.call(const ValueKey('help-entry-fsa')),
      2,
    );

    final tree = tester.widget<HelpTreeView>(find.byType(HelpTreeView));
    tree.controller.setQuery('no catalog result has these words');
    await tester.pump();

    list = tester.widget<ListView>(find.byType(ListView));
    delegate = list.childrenDelegate as SliverChildBuilderDelegate;
    expect(
      delegate.findChildIndexCallback?.call(
        const ValueKey('help-entry-no-results'),
      ),
      0,
    );
    expect(
      delegate.findChildIndexCallback?.call(
        const ValueKey('help-entry-getting-started'),
      ),
      isNull,
    );
  });

  testWidgets('deep Portuguese titles and body wrap without overflow', (
    tester,
  ) async {
    await _pumpHelpPage(
      tester,
      locale: const Locale('pt'),
      size: const Size(390, 844),
      initialTopicId: HelpTopicIds.fsaEditorViewportFitAndReset,
    );

    final title = find.text('Ajustar ao conteúdo e redefinir visualização');
    expect(title, findsOneWidget);
    expect(tester.getSize(title).height, greaterThan(20));
    final body = find.descendant(
      of: _body(HelpTopicIds.fsaEditorViewportFitAndReset),
      matching: find.byType(SelectableText),
    );
    expect(body, findsOneWidget);
    expect(tester.getSize(body).height, greaterThan(100));
    expect(tester.takeException(), isNull);
  });

  testWidgets('each recursive level uses one consistent indentation step', (
    tester,
  ) async {
    await _pumpHelpPage(tester, size: const Size(1600, 1000));
    final tree = tester.widget<HelpTreeView>(find.byType(HelpTreeView));
    tree.controller.toggle('getting-started');
    tree.controller.toggle('fsa');
    tree.controller.toggle('fsa.editor');
    tree.controller.toggle('fsa.editor.viewport');
    await tester.pumpAndSettle();

    final ids = [
      'fsa',
      'fsa.editor',
      'fsa.editor.viewport',
      HelpTopicIds.fsaEditorViewportZoom,
    ];
    final iconOffsets = ids
        .map(
          (id) => tester
              .getTopLeft(
                find
                    .descendant(of: _node(id), matching: find.byType(Icon))
                    .first,
              )
              .dx,
        )
        .toList();

    for (var index = 1; index < iconOffsets.length; index++) {
      expect(iconOffsets[index] - iconOffsets[index - 1], closeTo(20, 0.01));
    }

    final dividerOffsets = ids
        .map((id) => find.byKey(ValueKey('help-divider-$id')))
        .map((divider) {
          expect(divider, findsOneWidget);
          expect(
            tester.widget<Divider>(divider).color,
            Theme.of(tester.element(divider)).colorScheme.outlineVariant,
          );
          return tester.getTopLeft(divider).dx;
        })
        .toList();
    for (var index = 1; index < dividerOffsets.length; index++) {
      expect(
        dividerOffsets[index] - dividerOffsets[index - 1],
        closeTo(20, 0.01),
      );
    }
  });

  testWidgets('disclosures expose heading, button, state, and touch target', (
    tester,
  ) async {
    await _pumpHelpPage(tester);

    final gettingStarted = _node('getting-started');
    final semantics = tester.getSemantics(gettingStarted);
    expect(
      find.semantics.byPredicate(
        (candidate) =>
            candidate.id == semantics.id &&
            _hasExpandedDisclosureFlags(candidate),
        describeMatch: (_) => 'the expanded Getting Started disclosure',
      ),
      findsOneWidget,
    );
    expect(tester.getSize(gettingStarted).height, greaterThanOrEqualTo(48));
  });

  testWidgets('semantic tap toggles a disclosure', (tester) async {
    final semanticsHandle = tester.ensureSemantics();
    await _pumpHelpPage(
      tester,
      initialTopicId: HelpTopicIds.gettingStartedQuickStart,
    );

    final node = tester.semantics.find(
      _node(HelpTopicIds.gettingStartedQuickStart),
    );
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

    final nodeFinder = find.semantics.byPredicate(
      (candidate) => candidate.id == node.id,
      describeMatch: (_) => 'the quick-start disclosure semantics node',
    );
    tester.semantics.performAction(nodeFinder, SemanticsAction.tap);
    await tester.pumpAndSettle();

    expect(_body(HelpTopicIds.gettingStartedQuickStart), findsNothing);
    semanticsHandle.dispose();
  });

  testWidgets('Enter toggles a focused topic disclosure', (tester) async {
    await _pumpHelpPage(
      tester,
      initialTopicId: HelpTopicIds.gettingStartedQuickStart,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(_body(HelpTopicIds.gettingStartedQuickStart), findsNothing);
  });

  testWidgets('Space toggles a focused topic disclosure', (tester) async {
    await _pumpHelpPage(
      tester,
      initialTopicId: HelpTopicIds.gettingStartedQuickStart,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();

    expect(_body(HelpTopicIds.gettingStartedQuickStart), findsNothing);
  });

  testWidgets('related topic reveals its target on the same route', (
    tester,
  ) async {
    await _pumpHelpPage(tester);
    await tester.tap(_node(HelpTopicIds.gettingStartedQuickStart));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        const ValueKey('help-related-getting-started.choose-workspace'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HelpPage), findsOneWidget);
    expect(_body(HelpTopicIds.gettingStartedChooseWorkspace), findsOneWidget);
  });

  testWidgets('contextual topic scrolls into view and receives focus', (
    tester,
  ) async {
    await _pumpHelpPage(
      tester,
      initialTopicId: HelpTopicIds.pdaEditorSimulation,
    );

    final target = _node(HelpTopicIds.pdaEditorSimulation);
    expect(target, findsOneWidget);
    final targetWidget = tester.widget<InkWell>(target);
    final semantics = tester.getSemantics(target);
    expect(targetWidget.focusNode?.hasFocus, isTrue);
    expect(
      find.semantics.byPredicate(
        (candidate) =>
            candidate.id == semantics.id &&
            _hasExpandedDisclosureFlags(candidate),
        describeMatch: (_) => 'the expanded contextual disclosure',
      ),
      findsOneWidget,
    );
    expect(_body(HelpTopicIds.pdaEditorSimulation), findsOneWidget);
  });

  testWidgets('deep contextual topic is revealed beyond the lazy cache', (
    tester,
  ) async {
    await _pumpHelpPage(
      tester,
      size: const Size(320, 320),
      initialTopicId: HelpTopicIds.aboutLicenses,
    );

    final target = _node(HelpTopicIds.aboutLicenses);
    expect(target, findsOneWidget);
    expect(tester.widget<InkWell>(target).focusNode?.hasFocus, isTrue);
  });

  testWidgets(
    'reveal crosses tall open bodies until a distant topic is focused',
    (tester) async {
      await _pumpHelpPage(tester, size: const Size(320, 320));
      final tree = tester.widget<HelpTreeView>(find.byType(HelpTreeView));
      for (final topicId in [
        HelpTopicIds.gettingStartedQuickStart,
        HelpTopicIds.gettingStartedNavigation,
        HelpTopicIds.gettingStartedChooseWorkspace,
        HelpTopicIds.gettingStartedFilesAndExamples,
        HelpTopicIds.gettingStartedFirstInput,
        HelpTopicIds.gettingStartedFindHelp,
      ]) {
        tree.controller.toggle(topicId);
      }
      await tester.pump();
      expect(
        tester.getSize(_body(HelpTopicIds.gettingStartedQuickStart)).height,
        greaterThan(320),
      );

      tree.scrollController.jumpTo(0);
      tree.controller.revealTopic(HelpTopicIds.fsaEditorFilesAndExamples);
      await tester.pumpAndSettle();

      final target = _node(HelpTopicIds.fsaEditorFilesAndExamples);
      expect(target, findsOneWidget);
      expect(tester.widget<InkWell>(target).focusNode?.hasFocus, isTrue);
      expect(_body(HelpTopicIds.gettingStartedQuickStart), findsNothing);
      expect(
        tree.controller.expandedIds,
        contains(HelpTopicIds.gettingStartedQuickStart),
      );
    },
  );

  testWidgets('invalid contextual topic shows localized feedback at the top', (
    tester,
  ) async {
    await _pumpHelpPage(
      tester,
      locale: const Locale('pt'),
      initialTopicId: 'missing.topic',
    );

    expect(
      find.text('Este tópico de ajuda não está disponível.'),
      findsOneWidget,
    );
    expect(_node('getting-started.quick-start'), findsNothing);
    expect(_node('getting-started'), findsOneWidget);
  });
}
