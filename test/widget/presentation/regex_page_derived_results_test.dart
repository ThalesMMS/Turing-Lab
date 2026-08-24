import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/core/constants/help_topic_ids.dart';
import 'package:turing_lab/injection/data_providers.dart';
import 'package:turing_lab/presentation/pages/help_page.dart';
import 'package:turing_lab/presentation/pages/regex_page.dart';
import 'package:turing_lab/presentation/providers/regex_editor_provider.dart';
import 'package:turing_lab/presentation/providers/workspace_quick_actions_provider.dart';
import 'package:turing_lab/presentation/widgets/workspace_quick_actions_bar.dart';

import 'examples_test_helpers.dart';

Future<ProviderContainer> _pumpRegexPage(
  WidgetTester tester, {
  required Size size,
  String? pattern,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer(
    overrides: [
      examplesRepositoryProvider.overrideWithValue(TestExamplesRepository()),
    ],
  );
  addTearDown(container.dispose);
  if (pattern != null) {
    container.read(regexEditorProvider.notifier).validateRegex(pattern);
  }
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          appBar: AppBar(
            leading: const WorkspaceQuickActionsBar(tab: WorkspaceTab.regex),
            leadingWidth: 144,
          ),
          body: const RegexPage(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void _expectRegexHelpTopic(WidgetTester tester, String topicId) {
  expect(
    tester.widget<HelpPage>(find.byType(HelpPage)).initialTopicId,
    topicId,
  );
  expect(find.byKey(ValueKey('help-body-$topicId')), findsOneWidget);
}

void main() {
  for (final scenario in const [
    ('empty mobile', Size(430, 1200), null),
    ('invalid tablet', Size(1000, 1000), '('),
  ]) {
    testWidgets('${scenario.$1} Regex opens input Help without a fixed card', (
      tester,
    ) async {
      await _pumpRegexPage(
        tester,
        size: scenario.$2,
        pattern: scenario.$3,
      );

      expect(find.text('Regular Expression Help'), findsNothing);
      expect(find.textContaining('Common patterns:'), findsNothing);
      await tester.tap(find.byTooltip('Context-Aware Help'));
      await tester.pumpAndSettle();
      _expectRegexHelpTopic(tester, HelpTopicIds.regexEditorInput);
    });
  }

  testWidgets('valid desktop Regex opens conversion Help and survives Back', (
    tester,
  ) async {
    final container = await _pumpRegexPage(
      tester,
      size: const Size(1500, 1000),
      pattern: 'a*',
    );

    expect(find.text('Regular Expression Help'), findsNothing);
    await tester.tap(find.byTooltip('Context-Aware Help'));
    await tester.pumpAndSettle();
    _expectRegexHelpTopic(tester, HelpTopicIds.regexEditorConversions);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(container.read(regexEditorProvider).currentRegex, 'a*');
    expect(find.byKey(const ValueKey('regex_input_field')), findsOneWidget);
  });

  testWidgets('empty mobile Regex exposes five presets through Algorithms', (
    tester,
  ) async {
    final container = await _pumpRegexPage(
      tester,
      size: const Size(430, 1200),
    );

    expect(find.text('Convert to NFA'), findsNothing);
    final algorithms = find.descendant(
      of: find.byType(AppBar),
      matching: find.byTooltip('Algorithms'),
    );
    expect(algorithms, findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.ancestor(
              of: algorithms,
              matching: find.byType(IconButton),
            ),
          )
          .onPressed,
      isNotNull,
    );

    await tester.tap(algorithms);
    await tester.pumpAndSettle();
    await pumpUntilFound(tester, find.text('Regex - Repetição de A'));
    for (final example in const [
      'Regex - Repetição de A',
      'Regex - Termina com AB',
      'Regex - Binário iniciado por 0',
      'Regex - Pares AB ou BA',
      'Regex - Blocos de A e B',
    ]) {
      expect(find.text(example), findsOneWidget);
    }
    expect(find.text('Convert to NFA'), findsOneWidget);
    expect(find.text('Compare Regular Expressions:'), findsOneWidget);

    await tester.tap(find.text('Regex - Termina com AB'));
    await pumpUntilFound(tester, find.textContaining('Example loaded:'));
    expect(container.read(regexEditorProvider).currentRegex, '(a|b)*ab');
    expect(container.read(regexEditorProvider).alphabet, 'ab');
  });

  testWidgets('editing the pattern immediately removes old result cards',
      (tester) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        examplesRepositoryProvider.overrideWithValue(
          TestExamplesRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(regexEditorProvider.notifier);
    notifier.validateRegex('a*');
    expect(notifier.runSimplificationWithSteps().isSuccess, isTrue);
    expect(notifier.runComplexityAnalysis().isSuccess, isTrue);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            appBar: AppBar(
              leading: const WorkspaceQuickActionsBar(tab: WorkspaceTab.regex),
              leadingWidth: 144,
            ),
            body: const RegexPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Algorithms'));
    await tester.pumpAndSettle();
    expect(find.text('Re-analyze'), findsOneWidget);
    expect(find.text('Re-simplify'), findsOneWidget);

    Navigator.of(tester.element(find.byType(BottomSheet))).pop();
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('regex_input_field')),
      'b',
    );
    await tester.pump();

    await tester.tap(find.byTooltip('Algorithms'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Re-analyze'), findsNothing);
    expect(find.text('Re-simplify'), findsNothing);
    expect(find.text('Analyze Complexity'), findsOneWidget);
    expect(find.text('Simplify with Steps'), findsOneWidget);
  });
}
