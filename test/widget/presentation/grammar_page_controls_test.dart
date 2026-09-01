import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/core/constants/help_topic_ids.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/l10n/app_localizations_en.dart';
import 'package:turing_lab/l10n/app_localizations_workflows.dart';
import 'package:turing_lab/injection/data_providers.dart';
import 'package:turing_lab/presentation/pages/grammar_page.dart';
import 'package:turing_lab/presentation/pages/help_page.dart';
import 'package:turing_lab/presentation/providers/grammar_provider.dart';
import 'package:turing_lab/presentation/providers/workspace_quick_actions_provider.dart';
import 'package:turing_lab/presentation/widgets/common/algorithm_button.dart';
import 'package:turing_lab/presentation/widgets/grammar_algorithm_panel.dart';
import 'package:turing_lab/presentation/widgets/grammar_editor.dart';
import 'package:turing_lab/presentation/widgets/grammar_editor_section.dart';
import 'package:turing_lab/presentation/widgets/grammar_simulation_panel.dart';
import 'package:turing_lab/presentation/widgets/workspace_quick_actions_bar.dart';

import '../../support/workspace_dock_helpers.dart';
import 'examples_test_helpers.dart';

Future<ProviderContainer> _pumpGrammarPage(
  WidgetTester tester, {
  Size size = const Size(430, 932),
  GrammarProvider? grammar,
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      if (grammar != null) grammarProvider.overrideWith((ref) => grammar),
      examplesRepositoryProvider.overrideWithValue(TestExamplesRepository()),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Consumer(
          builder: (context, ref, _) {
            final actions = ref.watch(
              workspaceQuickActionsProvider(
                WorkspaceTab.grammar.formalSystemKey,
              ),
            );
            return Scaffold(
              appBar: AppBar(
                leading: const WorkspaceQuickActionsBar(
                  tab: WorkspaceTab.grammar,
                ),
                leadingWidth: 144,
                actions: [
                  IconButton(
                    tooltip: 'Help',
                    onPressed: actions?.onHelp,
                    icon: const Icon(Icons.help_outline),
                  ),
                ],
              ),
              body: const GrammarPage(),
            );
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void _expectHelpTopic(WidgetTester tester, String topicId) {
  final page = tester.widget<HelpPage>(find.byType(HelpPage));
  expect(page.initialTopicId, topicId);
  expect(find.byKey(ValueKey('help-body-$topicId')), findsOneWidget);
}

Finder _appBarAction(String tooltip) {
  return find.descendant(
    of: find.byType(AppBar),
    matching: find.byTooltip(tooltip),
  );
}

void main() {
  testWidgets('empty mobile Grammar Help opens the editor overview', (
    tester,
  ) async {
    await _pumpGrammarPage(tester, size: const Size(430, 932));

    await tester.tap(_appBarAction('Help'));
    await tester.pumpAndSettle();

    _expectHelpTopic(tester, HelpTopicIds.grammarEditorOverview);
  });

  testWidgets('Grammar algorithm view opens algorithm Help and survives Back', (
    tester,
  ) async {
    final grammar = GrammarProvider()
      ..addProduction(leftSide: const ['S'], rightSide: const ['a']);
    await _pumpGrammarPage(
      tester,
      size: const Size(800, 1100),
      grammar: grammar,
    );

    await tester.tap(_appBarAction('Algorithms & Examples'));
    await tester.pumpAndSettle();
    await pumpUntilFound(
      tester,
      find.text(AppLocalizationsEn().localizedExampleName('GLC - Palíndromo')),
    );
    expect(find.byType(GrammarAlgorithmPanel), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byTooltip('Help'),
      ),
    );
    await tester.pumpAndSettle();
    _expectHelpTopic(tester, HelpTopicIds.grammarEditorAlgorithms);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(GrammarAlgorithmPanel), findsOneWidget);
  });

  testWidgets('populated desktop Grammar Help opens CFG theory', (
    tester,
  ) async {
    final grammar = GrammarProvider()
      ..addProduction(leftSide: const ['S'], rightSide: const ['a']);
    final container = await _pumpGrammarPage(
      tester,
      size: const Size(1500, 1000),
      grammar: grammar,
    );

    await tester.tap(_appBarAction('Help'));
    await tester.pumpAndSettle();
    _expectHelpTopic(tester, HelpTopicIds.grammarTheoryCfg);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(container.read(grammarProvider).productions, hasLength(1));
  });

  testWidgets('Check Ambiguity uses a rule icon and keeps its action', (
    tester,
  ) async {
    final grammar = GrammarProvider()
      ..addProduction(leftSide: const ['S'], rightSide: const ['a']);
    await _pumpGrammarPage(
      tester,
      size: const Size(1500, 1000),
      grammar: grammar,
    );

    await openWorkspaceAlgorithmsPanel(tester);

    final ambiguityButton = find.ancestor(
      of: find.text('Check Ambiguity'),
      matching: find.byType(AlgorithmButton),
    );
    expect(ambiguityButton, findsOneWidget);
    final button = tester.widget<AlgorithmButton>(ambiguityButton);
    expect(button.icon, Icons.rule);
    expect(button.onPressed, isNotNull);

    button.onPressed!.call();
    await tester.pumpAndSettle();
    expect(find.textContaining('LL(1) Classification'), findsOneWidget);
  });

  testWidgets('mobile keeps production rules in the main editor', (
    tester,
  ) async {
    await _pumpGrammarPage(tester);

    expect(find.text('Production Rules (0)'), findsOneWidget);
    expect(
      find.text('Use Edit to add your first production rule'),
      findsOneWidget,
    );
    expect(find.text('Grammar Information'), findsNothing);
    expect(find.text('Add Production Rule'), findsNothing);
  });

  testWidgets('Portuguese localizes grammar edit guidance and Help', (
    tester,
  ) async {
    await _pumpGrammarPage(tester, locale: const Locale('pt'));

    expect(
      find.text('Use Editar para adicionar sua primeira regra de produção'),
      findsOneWidget,
    );
    expect(_appBarAction('Editar'), findsOneWidget);
  });

  testWidgets('Portuguese localizes the desktop editor button', (tester) async {
    await _pumpGrammarPage(
      tester,
      size: const Size(1200, 800),
      locale: const Locale('pt'),
    );

    final productionEditor = find.byWidgetPredicate(
      (widget) =>
          widget is GrammarEditor &&
          widget.section == GrammarEditorSection.productions,
    );

    expect(
      find.descendant(of: productionEditor, matching: find.text('Editar')),
      findsOneWidget,
    );
    expect(find.byTooltip('Mostrar Algoritmos e Exemplos'), findsOneWidget);
  });

  testWidgets('mobile publishes Parser, Algorithms, and Edit in that order', (
    tester,
  ) async {
    await _pumpGrammarPage(tester);

    final parser = _appBarAction('Parser');
    final algorithms = _appBarAction('Algorithms & Examples');
    final edit = _appBarAction('Edit');

    expect(parser, findsOneWidget);
    expect(algorithms, findsOneWidget);
    expect(edit, findsOneWidget);
    expect(
      tester.getCenter(parser).dx,
      lessThan(tester.getCenter(algorithms).dx),
    );
    expect(
      tester.getCenter(algorithms).dx,
      lessThan(tester.getCenter(edit).dx),
    );
  });

  testWidgets('Algorithms opens the grammar algorithm modal', (tester) async {
    final container = await _pumpGrammarPage(tester);

    await tester.tap(_appBarAction('Algorithms & Examples'));
    await tester.pumpAndSettle();
    final exampleL10n = AppLocalizationsEn();
    await pumpUntilFound(
      tester,
      find.text(exampleL10n.localizedExampleName('GLC - Palíndromo')),
    );

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(GrammarAlgorithmPanel), findsOneWidget);
    for (final example in const [
      'GLC - Palíndromo',
      'GLC - Parênteses balanceados',
      'GLC - a^n b^n',
      'GLC - Zeros em quantidade par',
      'GLC - Expressões aritméticas',
    ]) {
      expect(
        find.text(exampleL10n.localizedExampleName(example)),
        findsOneWidget,
      );
    }

    await tester.tap(
      find.text(exampleL10n.localizedExampleName('GLC - a^n b^n')),
    );
    await pumpUntilFound(tester, find.textContaining('Example loaded:'));
    expect(container.read(grammarProvider).name, 'GLC - a^n b^n');
  });

  testWidgets('Parser opens the grammar parser modal', (tester) async {
    final grammar = GrammarProvider()
      ..addProduction(leftSide: const ['S'], rightSide: const ['a']);
    await _pumpGrammarPage(tester, grammar: grammar);

    await tester.tap(_appBarAction('Parser'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(GrammarSimulationPanel), findsOneWidget);
  });

  testWidgets('Edit opens grammar information and production form in a modal', (
    tester,
  ) async {
    await _pumpGrammarPage(tester);

    await tester.tap(_appBarAction('Edit'));
    await tester.pumpAndSettle();

    final sheet = find.byType(BottomSheet);
    expect(sheet, findsOneWidget);
    expect(
      find.descendant(of: sheet, matching: find.text('Grammar Information')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Add Production Rule')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: sheet,
        matching: find.textContaining('Production Rules'),
      ),
      findsNothing,
    );
  });

  testWidgets('editing a group opens the same modal with all alternatives', (
    tester,
  ) async {
    final grammar = GrammarProvider()
      ..addProduction(leftSide: const ['S'], rightSide: const ['a', 'S'])
      ..addProduction(leftSide: const ['S'], rightSide: const ['b']);
    await _pumpGrammarPage(tester, grammar: grammar);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(
      find.ancestor(
        of: find.text('Edit alternatives'),
        matching: find.byWidgetPredicate(
          (widget) => widget is PopupMenuItem<String>,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final sheet = find.byType(BottomSheet);
    expect(sheet, findsOneWidget);
    expect(
      find.descendant(of: sheet, matching: find.text('Edit alternatives')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.widgetWithText(TextField, 'S')),
      findsWidgets,
    );
    expect(
      find.descendant(
        of: sheet,
        matching: find.widgetWithText(TextField, 'aS | b'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Portuguese localizes production group actions', (tester) async {
    final grammar = GrammarProvider()
      ..addProduction(leftSide: const ['S'], rightSide: const ['a'])
      ..addProduction(leftSide: const ['S'], rightSide: const ['b']);
    await _pumpGrammarPage(
      tester,
      grammar: grammar,
      locale: const Locale('pt'),
    );

    expect(find.text('S → a | b'), findsOneWidget);
    expect(find.text('2 alternativas'), findsOneWidget);
    expect(find.byTooltip('Reordenar produções de S'), findsOneWidget);
    expect(
      tester
          .getSemantics(
            find.byKey(const ValueKey('grammar-production-group-handle-p1')),
          )
          .value,
      contains('Posição 1 de 1'),
    );
    await tester.tap(find.byTooltip('Ações do grupo de produções'));
    await tester.pumpAndSettle();

    expect(find.text('Editar alternativas'), findsOneWidget);
    expect(find.text('Excluir grupo'), findsOneWidget);
    expect(find.text('Mover para cima'), findsOneWidget);
    expect(find.text('Mover para baixo'), findsOneWidget);
  });

  testWidgets('tablet names the secondary workspace tab Parser', (
    tester,
  ) async {
    await _pumpGrammarPage(tester, size: const Size(1200, 800));

    expect(find.byTooltip('Show Algorithms & Examples'), findsOneWidget);
    expect(find.byTooltip('Show Parser'), findsOneWidget);
    expect(find.byTooltip('Show Simulation'), findsNothing);
    expect(find.text('Production Rules (0)'), findsOneWidget);
    expect(find.text('Grammar Information'), findsNothing);

    await openWorkspaceSimulationPanel(tester);
    expect(find.byType(GrammarSimulationPanel), findsOneWidget);
    expect(find.byTooltip('Hide Parser'), findsWidgets);
  });

  testWidgets('tablet can open Edit from the production editor header', (
    tester,
  ) async {
    await _pumpGrammarPage(tester, size: const Size(1200, 800));

    final productionEditor = find.byWidgetPredicate(
      (widget) =>
          widget is GrammarEditor &&
          widget.section == GrammarEditorSection.productions,
    );
    final editButton = find.ancestor(
      of: find.descendant(of: productionEditor, matching: find.text('Edit')),
      matching: find.bySubtype<ButtonStyleButton>(),
    );

    expect(editButton, findsOneWidget);
    await tester.tap(editButton);
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('Grammar Information'), findsOneWidget);
    expect(find.text('Add Production Rule'), findsOneWidget);
  });
}
