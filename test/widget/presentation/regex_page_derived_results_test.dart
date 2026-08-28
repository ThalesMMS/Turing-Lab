import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/l10n/app_localizations_en.dart';
import 'package:turing_lab/l10n/app_localizations_workflows.dart';
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
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
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
        locale: locale,
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
  testWidgets('Regex simplification formats display metrics for pt-BR', (
    tester,
  ) async {
    final container = await _pumpRegexPage(
      tester,
      size: const Size(430, 1200),
      pattern: '(a|∅)ε',
      locale: const Locale('pt', 'BR'),
    );
    final result = container
        .read(regexEditorProvider.notifier)
        .runSimplificationWithSteps();
    expect(result.isSuccess, isTrue);
    expect(
      container
          .read(regexEditorProvider)
          .simplificationResult!
          .reductionPercentage,
      closeTo(83.333333, 0.000001),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('Algoritmos e Exemplos'));
    await tester.pumpAndSettle();

    expect(find.text('Redução: 83,3%'), findsOneWidget);
    expect(find.text('Redução: 83.3%'), findsNothing);
  });

  for (final scenario in const [
    ('empty mobile', Size(430, 1200), null),
    ('invalid tablet', Size(1000, 1000), '('),
  ]) {
    testWidgets('${scenario.$1} Regex opens input Help without a fixed card', (
      tester,
    ) async {
      await _pumpRegexPage(tester, size: scenario.$2, pattern: scenario.$3);

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
    // The wide layout no longer paints its own help button: the shell's app
    // bar renders the published action instead.
    final actions = container.read(
      workspaceQuickActionsProvider(WorkspaceTab.regex.formalSystemKey),
    );
    expect(actions?.onHelp, isNotNull);
    actions!.onHelp!();
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
    final container = await _pumpRegexPage(tester, size: const Size(430, 1200));

    expect(find.text('Convert to NFA'), findsNothing);
    final algorithms = find.descendant(
      of: find.byType(AppBar),
      matching: find.byTooltip('Algorithms & Examples'),
    );
    expect(algorithms, findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.ancestor(of: algorithms, matching: find.byType(IconButton)),
          )
          .onPressed,
      isNotNull,
    );

    await tester.tap(algorithms);
    await tester.pumpAndSettle();
    final exampleL10n = AppLocalizationsEn();
    await pumpUntilFound(
      tester,
      find.text(exampleL10n.localizedExampleName('Regex - Repetição de A')),
    );
    for (final example in const [
      'Regex - Repetição de A',
      'Regex - Termina com AB',
      'Regex - Binário iniciado por 0',
      'Regex - Pares AB ou BA',
      'Regex - Blocos de A e B',
    ]) {
      expect(
        find.text(exampleL10n.localizedExampleName(example)),
        findsOneWidget,
      );
    }
    expect(find.text('Convert to NFA'), findsOneWidget);
    expect(find.text('Compare Regular Expressions:'), findsOneWidget);

    await tester.tap(
      find.text(exampleL10n.localizedExampleName('Regex - Termina com AB')),
    );
    await pumpUntilFound(tester, find.textContaining('Example loaded:'));
    expect(container.read(regexEditorProvider).currentRegex, '(a|b)*ab');
    expect(container.read(regexEditorProvider).alphabet, 'ab');
  });

  testWidgets('Regex algorithms expose transactional JSON and JFLAP files', (
    tester,
  ) async {
    await _pumpRegexPage(tester, size: const Size(430, 1200));

    await tester.tap(find.byTooltip('Algorithms & Examples'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('interoperability_import_document')),
      400,
      scrollable: find.byType(Scrollable).last,
    );
    expect(
      find.byKey(const ValueKey('interoperability_import_document')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('interoperability_export_jflap-xml')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('interoperability_export_turing-lab-json')),
      findsOneWidget,
    );
  });

  testWidgets('Regex algorithms open the manual FA construction workspace', (
    tester,
  ) async {
    await _pumpRegexPage(tester, size: const Size(430, 1200), pattern: 'a*');

    await tester.tap(find.byTooltip('Algorithms & Examples'));
    await tester.pumpAndSettle();
    final action = find.byKey(const ValueKey('open-manual-regex-to-fa'));
    await tester.scrollUntilVisible(
      action,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(action);
    await tester.pumpAndSettle();

    expect(find.text('Manual Regex to FA construction'), findsOneWidget);
    expect(find.text('Learner construction'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
  });

  testWidgets('editing the pattern immediately removes old result cards', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        examplesRepositoryProvider.overrideWithValue(TestExamplesRepository()),
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

    await tester.tap(find.byTooltip('Algorithms & Examples'));
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

    await tester.tap(find.byTooltip('Algorithms & Examples'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Re-analyze'), findsNothing);
    expect(find.text('Re-simplify'), findsNothing);
    expect(find.text('Analyze Complexity'), findsOneWidget);
    expect(find.text('Simplify with Steps'), findsOneWidget);
  });

  testWidgets('mobile Regex opens simulation behind the Simulate action', (
    tester,
  ) async {
    final container = await _pumpRegexPage(
      tester,
      size: const Size(430, 1200),
      pattern: 'ab',
    );

    // The simulation input is no longer inline in the mobile body.
    expect(find.byKey(const ValueKey('regex_test_input_field')), findsNothing);
    expect(find.byKey(const Key('regex-batch-section')), findsNothing);

    final simulate = find.descendant(
      of: find.byType(AppBar),
      matching: find.byTooltip('Simulate'),
    );
    expect(simulate, findsOneWidget);
    await tester.tap(simulate);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('regex-simulation-section')), findsOneWidget);
    final input = find.byKey(const ValueKey('regex_test_input_field'));
    expect(input, findsOneWidget);
    expect(find.byKey(const Key('regex-batch-section')), findsOneWidget);
    expect(find.text('Batch testing'), findsOneWidget);

    await tester.enterText(input, 'ab');
    await tester.pumpAndSettle();
    final state = container.read(regexEditorProvider);
    expect(state.hasTested, isTrue);
    expect(state.matches, isTrue);
    expect(find.text('Matches!'), findsOneWidget);
  });
}
