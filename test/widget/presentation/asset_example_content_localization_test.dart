import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/data/data_sources/examples_asset_data_source.dart';
import 'package:turing_lab/data/services/file_operations_service.dart';
import 'package:turing_lab/injection/data_providers.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/content/asset_example_content_copy.dart';
import 'package:turing_lab/presentation/pages/regex_page.dart';
import 'package:turing_lab/presentation/providers/automaton_state_provider.dart';
import 'package:turing_lab/presentation/providers/grammar_provider.dart';
import 'package:turing_lab/presentation/providers/pda_editor_provider.dart';
import 'package:turing_lab/presentation/providers/regex_editor_provider.dart';
import 'package:turing_lab/presentation/providers/tm_editor_provider.dart';
import 'package:turing_lab/presentation/widgets/algorithm_panel.dart';
import 'package:turing_lab/presentation/widgets/asset_example_content_button.dart';
import 'package:turing_lab/presentation/widgets/grammar_algorithm_panel.dart';
import 'package:turing_lab/presentation/widgets/pda_algorithm_panel.dart';
import 'package:turing_lab/presentation/widgets/tm_algorithm_panel.dart';
import 'package:turing_lab/presentation/widgets/workspace_quick_actions_bar.dart';

const _fsaIds = <String>[
  'asset/afd_binary_divisible_by_3',
  'asset/afd_contains_ab',
  'asset/afd_ends_with_a',
  'asset/afd_parity_ab',
  'asset/afn_lambda_a_or_ab',
];

const _regexIds = <String>[
  'asset/regex_a_star',
  'asset/regex_a_then_b',
  'asset/regex_ab_or_ba_pairs',
  'asset/regex_binary_starts_zero',
  'asset/regex_ends_with_ab',
];

const _pdaIds = <String>[
  'asset/apda_anb2n',
  'asset/apda_anbn',
  'asset/apda_balanced_parentheses',
  'asset/apda_mirrored_separator',
  'asset/apda_palindrome',
];

const _grammarIds = <String>[
  'asset/glc_anbn',
  'asset/glc_arithmetic_expressions',
  'asset/glc_balanced_parentheses',
  'asset/glc_even_zeros',
  'asset/glc_palindrome',
];

const _tmIds = <String>[
  'asset/tm_anbn',
  'asset/tm_binary_to_unary',
  'asset/tm_copy_string',
  'asset/tm_increment',
  'asset/tm_multitape_comparison',
  'asset/tm_multitape_copy',
  'asset/tm_multitape_palindrome',
  'asset/tm_multitape_work_tape',
  'asset/tm_palindrome',
];

Future<void> _waitForExampleButtons(
  WidgetTester tester, {
  int expectedCount = 5,
}) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (find.byType(AssetExampleContentButton).evaluate().length ==
        expectedCount) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 25));
  }
  fail('Timed out waiting for $expectedCount localized asset examples.');
}

void _expectLocalizedExamples(
  WidgetTester tester,
  List<String> ids,
  String languageCode,
) {
  for (final id in ids) {
    final copy = AssetExampleContentCopies.resolve(
      id: id,
      languageCode: languageCode,
    );
    expect(find.text(copy.title), findsOneWidget);
    expect(find.textContaining(copy.summary), findsOneWidget);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'FSA chooser localizes five assets at 320px and 200 percent without changing the automaton',
    (tester) async {
      tester.view
        ..physicalSize = const Size(320, 700)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final examples = ExamplesAssetDataSource();
      final expectedExamples = (await examples.loadAllTypedFsaExamples()).data!;
      final notifier = AutomatonStateNotifier();

      Future<void> pump(Locale locale) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [automatonStateProvider.overrideWith((ref) => notifier)],
            child: MaterialApp(
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: Scaffold(
                body: AlgorithmPanel(
                  currentAutomaton: notifier.state.currentAutomaton,
                  showExamples: true,
                  examplesDataSource: examples,
                  fileService: FileOperationsService(),
                ),
              ),
            ),
          ),
        );
        await _waitForExampleButtons(tester);
      }

      await pump(const Locale('en'));
      _expectLocalizedExamples(tester, _fsaIds, 'en');
      expect(find.text('Suggested simulation: 110'), findsOneWidget);
      final en = AssetExampleContentCopies.resolve(
        id: _fsaIds.first,
        languageCode: 'en',
      );
      await tester.scrollUntilVisible(
        find.text(en.title),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      final semantics = tester.getSemantics(
        find.ancestor(
          of: find.text(en.title),
          matching: find.byType(AssetExampleContentButton),
        ),
      );
      expect(semantics.label, contains(en.accessibleDescription));
      expect(semantics.label, contains('Suggested simulation: 110.'));
      await tester.tap(find.text(en.title));
      for (
        var attempt = 0;
        attempt < 100 && notifier.state.currentAutomaton == null;
        attempt++
      ) {
        await tester.pump(const Duration(milliseconds: 25));
      }

      final expected = expectedExamples
          .singleWhere((example) => example.id == _fsaIds.first)
          .payload;
      final loaded = notifier.state.currentAutomaton!;
      expect(loaded.id, expected.id);
      expect(loaded.alphabet, expected.alphabet);
      expect(
        loaded.states.map((state) => state.id).toSet(),
        expected.states.map((state) => state.id).toSet(),
      );
      expect(
        loaded.transitions.map((transition) => transition.id).toSet(),
        expected.transitions.map((transition) => transition.id).toSet(),
      );
      final formalSnapshot = loaded.toJson();

      await pump(const Locale('pt', 'BR'));
      _expectLocalizedExamples(tester, _fsaIds, 'pt-BR');
      expect(find.text('Simulação sugerida: 110'), findsOneWidget);
      expect(find.text(en.title), findsNothing);
      expect(notifier.state.currentAutomaton?.toJson(), formalSnapshot);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Regex algorithms sheet localizes five assets at 320px and 200 percent without changing the document',
    (tester) async {
      tester.view
        ..physicalSize = const Size(320, 700)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final examples = ExamplesAssetDataSource();
      final expectedExamples =
          (await examples.loadAllTypedRegexExamples()).data!;
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          examplesRepositoryProvider.overrideWithValue(examples),
        ],
      );
      addTearDown(container.dispose);

      Future<void> pump(Locale locale) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: Scaffold(
                appBar: AppBar(
                  leading: const WorkspaceQuickActionsBar(
                    workspaceKey: DefaultFormalSystemIds.regex,
                  ),
                  leadingWidth: 144,
                ),
                body: const RegexPage(),
              ),
            ),
          ),
        );
        await tester.pump();
      }

      await pump(const Locale('en'));
      await tester.tap(find.byTooltip('Algorithms & Examples'));
      await tester.pump();
      await _waitForExampleButtons(tester);
      _expectLocalizedExamples(tester, _regexIds, 'en');
      final en = AssetExampleContentCopies.resolve(
        id: _regexIds.first,
        languageCode: 'en',
      );
      await tester.dragFrom(const Offset(160, 650), const Offset(0, -500));
      await tester.pumpAndSettle();
      final semantics = tester.getSemantics(
        find.ancestor(
          of: find.text(en.title),
          matching: find.byType(AssetExampleContentButton),
        ),
      );
      expect(semantics.label, contains(en.accessibleDescription));
      await tester.tap(find.text(en.title));
      await tester.pumpAndSettle();

      final expected = expectedExamples
          .singleWhere((example) => example.id == _regexIds.first)
          .payload;
      final loaded = container.read(regexEditorProvider);
      expect(loaded.documentId, expected.id);
      expect(loaded.documentName, expected.name);
      expect(loaded.currentRegex, expected.expression);
      expect(loaded.alphabet, expected.alphabet);
      final formalSnapshot = (
        loaded.documentId,
        loaded.documentName,
        loaded.currentRegex,
        loaded.alphabet,
      );

      await pump(const Locale('pt', 'BR'));
      await _waitForExampleButtons(tester);
      _expectLocalizedExamples(tester, _regexIds, 'pt-BR');
      expect(find.text(en.title), findsNothing);
      final afterLocaleSwitch = container.read(regexEditorProvider);
      expect((
        afterLocaleSwitch.documentId,
        afterLocaleSwitch.documentName,
        afterLocaleSwitch.currentRegex,
        afterLocaleSwitch.alphabet,
      ), formalSnapshot);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'PDA chooser localizes five assets at 320px and 200 percent without changing the automaton',
    (tester) async {
      tester.view
        ..physicalSize = const Size(320, 700)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final examples = ExamplesAssetDataSource();
      final expectedExamples = (await examples.loadAllTypedPdaExamples()).data!;
      final notifier = PDAEditorNotifier();

      Future<void> pump(Locale locale) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [pdaEditorProvider.overrideWith((ref) => notifier)],
            child: MaterialApp(
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: Scaffold(
                body: PDAAlgorithmPanel(
                  useExpanded: false,
                  examplesDataSource: examples,
                ),
              ),
            ),
          ),
        );
        await _waitForExampleButtons(tester);
      }

      await pump(const Locale('en'));
      _expectLocalizedExamples(tester, _pdaIds, 'en');
      final en = AssetExampleContentCopies.resolve(
        id: _pdaIds.first,
        languageCode: 'en',
      );
      await tester.ensureVisible(find.text(en.title));
      await tester.pumpAndSettle();
      final semantics = tester.getSemantics(
        find.ancestor(
          of: find.text(en.title),
          matching: find.byType(AssetExampleContentButton),
        ),
      );
      expect(semantics.label, contains(en.accessibleDescription));
      await tester.tap(find.text(en.title));
      for (
        var attempt = 0;
        attempt < 100 && notifier.currentPda == null;
        attempt++
      ) {
        await tester.pump(const Duration(milliseconds: 25));
      }

      final expected = expectedExamples
          .singleWhere((example) => example.id == _pdaIds.first)
          .payload;
      final loaded = notifier.currentPda!;
      Map<String, dynamic> formalJson(Map<String, dynamic> source) {
        final json = Map<String, dynamic>.of(source);
        json.remove('created');
        json.remove('modified');
        return json;
      }

      expect(formalJson(loaded.toJson()), formalJson(expected.toJson()));
      final formalSnapshot = loaded.toJson();

      await pump(const Locale('pt', 'BR'));
      _expectLocalizedExamples(tester, _pdaIds, 'pt-BR');
      expect(find.text(en.title), findsNothing);
      expect(notifier.currentPda?.toJson(), formalSnapshot);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Grammar chooser localizes five assets at 320px and 200 percent without changing productions',
    (tester) async {
      tester.view
        ..physicalSize = const Size(320, 700)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final examples = ExamplesAssetDataSource();
      final expectedExamples = (await examples.loadAllTypedCfgExamples()).data!;
      final notifier = GrammarProvider();

      Future<void> pump(Locale locale) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [grammarProvider.overrideWith((ref) => notifier)],
            child: MaterialApp(
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: Scaffold(
                body: GrammarAlgorithmPanel(
                  useExpanded: false,
                  examplesDataSource: examples,
                ),
              ),
            ),
          ),
        );
        await _waitForExampleButtons(tester);
      }

      await pump(const Locale('en'));
      _expectLocalizedExamples(tester, _grammarIds, 'en');
      final en = AssetExampleContentCopies.resolve(
        id: _grammarIds.first,
        languageCode: 'en',
      );
      await tester.ensureVisible(find.text(en.title));
      await tester.pumpAndSettle();
      final semantics = tester.getSemantics(
        find.ancestor(
          of: find.text(en.title),
          matching: find.byType(AssetExampleContentButton),
        ),
      );
      expect(semantics.label, contains(en.accessibleDescription));
      await tester.tap(find.text(en.title));

      final expected = expectedExamples
          .singleWhere((example) => example.id == _grammarIds.first)
          .payload;
      for (
        var attempt = 0;
        attempt < 100 && notifier.state.documentId != expected.id;
        attempt++
      ) {
        await tester.pump(const Duration(milliseconds: 25));
      }
      final loaded = notifier.buildGrammar();
      expect(loaded.id, expected.id);
      expect(loaded.name, expected.name);
      expect(loaded.terminals, expected.terminals);
      expect(loaded.nonterminals, expected.nonterminals);
      expect(loaded.startSymbol, expected.startSymbol);
      expect(loaded.type, expected.type);
      expect(
        {
          for (final production in loaded.productions)
            production.id: production.toJson(),
        },
        {
          for (final production in expected.productions)
            production.id: production.toJson(),
        },
      );
      Map<String, dynamic> formalSnapshot() => {
        'id': notifier.state.documentId,
        'name': notifier.state.name,
        'startSymbol': notifier.state.startSymbol,
        'type': notifier.state.type,
        'productions': {
          for (final production in notifier.state.productions)
            production.id: production.toJson(),
        },
      };
      final snapshotBeforeLocaleSwitch = formalSnapshot();

      await pump(const Locale('pt', 'BR'));
      _expectLocalizedExamples(tester, _grammarIds, 'pt-BR');
      expect(find.text(en.title), findsNothing);
      expect(formalSnapshot(), snapshotBeforeLocaleSwitch);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'TM chooser localizes nine single and multi-tape assets at 320px and 200 percent without changing machines',
    (tester) async {
      tester.view
        ..physicalSize = const Size(320, 700)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final examples = ExamplesAssetDataSource();
      final expectedExamples = (await examples.loadAllTypedTmExamples()).data!;
      final notifier = TMEditorNotifier();

      Future<void> pump(Locale locale) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [tmEditorProvider.overrideWith((ref) => notifier)],
            child: MaterialApp(
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: Scaffold(
                body: TMAlgorithmPanel(
                  useExpanded: false,
                  examplesDataSource: examples,
                ),
              ),
            ),
          ),
        );
        await _waitForExampleButtons(tester, expectedCount: _tmIds.length);
      }

      Map<String, dynamic> formalJson(Map<String, dynamic> source) {
        final json = Map<String, dynamic>.of(source);
        json.remove('created');
        json.remove('modified');
        return json;
      }

      Future<void> selectAndVerify(String id) async {
        final copy = AssetExampleContentCopies.resolve(
          id: id,
          languageCode: 'en',
        );
        final button = find.ancestor(
          of: find.text(copy.title),
          matching: find.byType(AssetExampleContentButton),
        );
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        expect(
          tester.getSemantics(button).label,
          contains(copy.accessibleDescription),
        );
        await tester.tap(button);

        final expected = expectedExamples
            .singleWhere((example) => example.id == id)
            .payload;
        final feedback = 'Example loaded: ${copy.title}';
        for (var attempt = 0; attempt < 100; attempt++) {
          if (notifier.state.tm?.id == expected.id &&
              find.text(feedback).evaluate().isNotEmpty) {
            break;
          }
          await tester.pump(const Duration(milliseconds: 25));
        }
        final loaded = notifier.state.tm!;
        expect(loaded.tapeCount, expected.tapeCount);
        expect(formalJson(loaded.toJson()), formalJson(expected.toJson()));
        expect(find.text(feedback), findsOneWidget);
      }

      await pump(const Locale('en'));
      _expectLocalizedExamples(tester, _tmIds, 'en');
      await selectAndVerify(_tmIds.first);
      expect(notifier.state.tm?.tapeCount, 1);

      const multiTapeId = 'asset/tm_multitape_copy';
      await selectAndVerify(multiTapeId);
      expect(notifier.state.tm?.tapeCount, 2);
      final formalSnapshot = notifier.state.tm!.toJson();

      await pump(const Locale('pt', 'BR'));
      _expectLocalizedExamples(tester, _tmIds, 'pt-BR');
      final en = AssetExampleContentCopies.resolve(
        id: multiTapeId,
        languageCode: 'en',
      );
      final pt = AssetExampleContentCopies.resolve(
        id: multiTapeId,
        languageCode: 'pt-BR',
      );
      expect(find.text(en.title), findsNothing);
      final portugueseButton = find.ancestor(
        of: find.text(pt.title),
        matching: find.byType(AssetExampleContentButton),
      );
      expect(
        tester.getSemantics(portugueseButton).label,
        contains(pt.accessibleDescription),
      );
      expect(notifier.state.tm?.toJson(), formalSnapshot);
      expect(tester.takeException(), isNull);
    },
  );
}
