import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/core/constants/help_topic_ids.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/pages/help_page.dart';
import 'package:turing_lab/presentation/widgets/common/help_navigation.dart';
import 'package:turing_lab/presentation/widgets/help_action_button.dart';

Widget _testApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

Finder _helpNode(String topicId) {
  return find.byKey(ValueKey('help-node-$topicId'));
}

class _RecordingNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushes = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushes.add(route);
    super.didPush(route, previousRoute);
  }
}

void main() {
  testWidgets('openHelp reveals and focuses the requested catalog topic', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        Builder(
          builder: (context) {
            return ElevatedButton(
              key: const Key('open-fsa-help'),
              onPressed: () => openHelp(
                context,
                topicId: HelpTopicIds.fsaEditorOverview,
              ),
              child: const Text('Open FSA help'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('open-fsa-help')));
    await tester.pumpAndSettle();

    final page = tester.widget<HelpPage>(find.byType(HelpPage));
    final target = _helpNode(HelpTopicIds.fsaEditorOverview);
    expect(page.initialTopicId, HelpTopicIds.fsaEditorOverview);
    expect(target, findsOneWidget);
    expect(tester.widget<InkWell>(target).focusNode?.hasFocus, isTrue);
    expect(
      find.byKey(
        const ValueKey('help-body-${HelpTopicIds.fsaEditorOverview}'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('openHelp without a topic opens Getting Started', (tester) async {
    await tester.pumpWidget(
      _testApp(
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () => openHelp(context),
              child: const Text('Open general help'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open general help'));
    await tester.pumpAndSettle();

    final page = tester.widget<HelpPage>(find.byType(HelpPage));
    expect(page.initialTopicId, isNull);
    expect(_helpNode('getting-started'), findsOneWidget);
    expect(_helpNode(HelpTopicIds.gettingStartedQuickStart), findsOneWidget);
    expect(find.text('Topic unavailable'), findsNothing);
  });

  testWidgets('openHelp leaves nested navigators and pushes on the root', (
    tester,
  ) async {
    final rootObserver = _RecordingNavigatorObserver();
    final nestedObserver = _RecordingNavigatorObserver();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        navigatorObservers: [rootObserver],
        home: Navigator(
          observers: [nestedObserver],
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (context) => ElevatedButton(
              onPressed: () => openHelp(
                context,
                topicId: HelpTopicIds.fsaEditorOverview,
              ),
              child: const Text('Open from nested route'),
            ),
          ),
        ),
      ),
    );

    expect(rootObserver.pushes, hasLength(1));
    expect(nestedObserver.pushes, hasLength(1));
    await tester.tap(find.text('Open from nested route'));
    await tester.pumpAndSettle();

    expect(rootObserver.pushes, hasLength(2));
    expect(nestedObserver.pushes, hasLength(1));
    expect(find.byType(HelpPage), findsOneWidget);
  });

  testWidgets('HelpActionButton is localized, semantic, and at least 48 square',
      (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var semanticsDisposed = false;
    void disposeSemantics() {
      if (semanticsDisposed) return;
      semantics.dispose();
      semanticsDisposed = true;
    }

    addTearDown(disposeSemantics);
    await tester.pumpWidget(
      _testApp(
        HelpActionButton(
          topicId: HelpTopicIds.shortcutsCanvas,
          tooltip: 'Canvas help',
        ),
      ),
    );

    final button = find.widgetWithIcon(IconButton, Icons.help_outline);
    expect(find.byTooltip('Canvas help'), findsOneWidget);
    expect(find.bySemanticsLabel('Canvas help'), findsOneWidget);
    expect(tester.getSize(button).width, greaterThanOrEqualTo(48));
    expect(tester.getSize(button).height, greaterThanOrEqualTo(48));

    final semanticButton = find.semantics.byPredicate(
      (node) =>
          node.label == 'Canvas help' &&
          node.getSemanticsData().hasAction(SemanticsAction.tap),
      describeMatch: (_) => 'Canvas help with a semantic tap action',
    );
    expect(semanticButton, findsOneWidget);
    tester.semantics.performAction(semanticButton, SemanticsAction.tap);
    await tester.pumpAndSettle();
    expect(find.byType(HelpPage), findsOneWidget);
    expect(_helpNode(HelpTopicIds.shortcutsCanvas), findsOneWidget);
    disposeSemantics();
  });

  test('HelpActionButton rejects a topic outside the catalog', () {
    expect(
      () => HelpActionButton(
        topicId: 'missing.topic',
        tooltip: 'Invalid help',
      ),
      throwsArgumentError,
    );
  });

  testWidgets('openHelp rejects an invalid topic before pushing a route', (
    tester,
  ) async {
    final observer = _RecordingNavigatorObserver();
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [observer],
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => openHelp(context, topicId: 'missing.topic'),
            child: const Text('Open invalid help'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open invalid help'));
    await tester.pump();

    expect(tester.takeException(), isA<ArgumentError>());
    expect(observer.pushes, hasLength(1));
    expect(find.byType(HelpPage), findsNothing);
  });
}
