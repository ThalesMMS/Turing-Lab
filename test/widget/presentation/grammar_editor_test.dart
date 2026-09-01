//
//  grammar_editor_test.dart
//  Turing Lab
//
//  Comprehensive suite covering GrammarEditor, including stub providers and
//  form-driven interaction. The tests validate adding, editing, and removing
//  productions, metadata updates, clear actions, and input-validation
//  responses, keeping the UI in sync with grammar state.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/l10n/app_localizations_en.dart';
import 'package:turing_lab/presentation/empty_string_notation.dart';
import 'package:turing_lab/presentation/providers/grammar_provider.dart';
import 'package:turing_lab/presentation/widgets/grammar_editor.dart';
import 'package:turing_lab/presentation/widgets/grammar_editor_section.dart';

class _RecordingGrammarProvider extends GrammarProvider {
  _RecordingGrammarProvider() : super();

  final List<Map<String, Object?>> addProductionCalls = [];
  final List<Map<String, Object?>> updateProductionCalls = [];
  final List<String> deleteProductionCalls = [];
  int clearProductionsCalls = 0;
  int setProductionsCalls = 0;
  int updateNameCalls = 0;
  int updateStartSymbolCalls = 0;
  String? lastNameValue;
  String? lastStartSymbolValue;

  @override
  ProductionGroupMutationResult addProductionAlternatives({
    required List<String> leftSide,
    required Iterable<ProductionAlternativeDraft> alternatives,
  }) {
    final drafts = alternatives.toList(growable: false);
    for (final draft in drafts) {
      addProductionCalls.add({
        'leftSide': leftSide,
        'rightSide': draft.rightSide,
        'isLambda': draft.isLambda,
      });
    }
    return super.addProductionAlternatives(
      leftSide: leftSide,
      alternatives: drafts,
    );
  }

  @override
  void updateProduction(
    String id, {
    required List<String> leftSide,
    required List<String> rightSide,
    bool isLambda = false,
  }) {
    updateProductionCalls.add({
      'id': id,
      'leftSide': leftSide,
      'rightSide': rightSide,
      'isLambda': isLambda,
    });
    super.updateProduction(
      id,
      leftSide: leftSide,
      rightSide: rightSide,
      isLambda: isLambda,
    );
  }

  @override
  ProductionGroupMutationResult replaceProductionGroup({
    required List<String> originalLeftSide,
    required List<String> leftSide,
    required Iterable<ProductionAlternativeDraft> alternatives,
  }) {
    final drafts = alternatives.toList(growable: false);
    final original = state.productions.firstWhere(
      (production) => production.leftSide.join() == originalLeftSide.join(),
    );
    if (drafts.isNotEmpty) {
      updateProductionCalls.add({
        'id': original.id,
        'leftSide': leftSide,
        'rightSide': drafts.first.rightSide,
        'isLambda': drafts.first.isLambda,
      });
    }
    return super.replaceProductionGroup(
      originalLeftSide: originalLeftSide,
      leftSide: leftSide,
      alternatives: drafts,
    );
  }

  @override
  void deleteProduction(String id) {
    deleteProductionCalls.add(id);
    super.deleteProduction(id);
  }

  @override
  int deleteProductionGroup(List<String> leftSide) {
    deleteProductionCalls.addAll(
      state.productions
          .where((production) => production.leftSide.join() == leftSide.join())
          .map((production) => production.id),
    );
    return super.deleteProductionGroup(leftSide);
  }

  @override
  void clearProductions() {
    clearProductionsCalls++;
    super.clearProductions();
  }

  @override
  void setProductions(List<Production> productions) {
    setProductionsCalls++;
    super.setProductions(productions);
  }

  @override
  void updateName(String value) {
    updateNameCalls++;
    lastNameValue = value;
    super.updateName(value);
  }

  @override
  void updateStartSymbol(String value) {
    updateStartSymbolCalls++;
    lastStartSymbolValue = value;
    super.updateStartSymbol(value);
  }
}

/// Helper to find a [ButtonStyleButton] (including ElevatedButton.icon
/// private subclass) that contains the given [text] label.
Finder _findButtonWithText(String text) {
  return find.ancestor(
    of: find.text(text),
    matching: find.bySubtype<ButtonStyleButton>(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Pump the GrammarEditor inside a large-enough viewport to avoid overflow.
  Future<void> pumpEditor(
    WidgetTester tester,
    _RecordingGrammarProvider provider,
  ) async {
    tester.view.physicalSize = const Size(1366, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [grammarProvider.overrideWith((ref) => provider)],
        child: const MaterialApp(home: Scaffold(body: GrammarEditor())),
      ),
    );

    await tester.pumpAndSettle();
  }

  group('GrammarEditor initialization', () {
    testWidgets('builds successfully with default state', (tester) async {
      final provider = _RecordingGrammarProvider();
      await pumpEditor(tester, provider);

      expect(find.text('Grammar Editor'), findsOneWidget);
      expect(find.text('Grammar Information'), findsOneWidget);
      expect(find.text('Add Production Rule'), findsOneWidget);
      expect(find.text('Production Rules (0)'), findsOneWidget);

      expect(find.text(AppLocalizationsEn().leftSideHelper), findsOneWidget);
      expect(find.text(AppLocalizationsEn().rightSideHelper), findsOneWidget);
    });

    testWidgets('displays empty state when no productions exist', (
      tester,
    ) async {
      final provider = _RecordingGrammarProvider();
      await pumpEditor(tester, provider);

      expect(find.text('No production rules yet'), findsOneWidget);
      expect(find.text('Add your first production rule above'), findsOneWidget);
    });

    testWidgets('initializes text controllers with provider state', (
      tester,
    ) async {
      final provider = _RecordingGrammarProvider();
      await pumpEditor(tester, provider);

      final grammarNameField = find.widgetWithText(TextField, 'My Grammar');
      expect(grammarNameField, findsOneWidget);

      final startSymbolField = find.widgetWithText(TextField, 'S');
      expect(startSymbolField, findsOneWidget);
    });

    testWidgets('formats an initially edited group after dependencies exist', (
      tester,
    ) async {
      final provider = _RecordingGrammarProvider()
        ..addProduction(
          leftSide: const ['S'],
          rightSide: const [],
          isLambda: true,
        );
      final production = provider.state.productions.single;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [grammarProvider.overrideWith((ref) => provider)],
          child: EmptyStringNotation(
            symbol: 'λ',
            child: MaterialApp(
              home: Scaffold(
                body: GrammarEditor(
                  section: GrammarEditorSection.details,
                  productionToEdit: production,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.widgetWithText(TextField, 'λ'), findsOneWidget);
    });
  });

  group('GrammarEditor metadata updates', () {
    testWidgets('uses formal-language keyboard settings for grammar symbols', (
      tester,
    ) async {
      final provider = _RecordingGrammarProvider();
      await pumpEditor(tester, provider);

      final startSymbolField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'S').first,
      );

      expect(startSymbolField.autocorrect, isFalse);
      expect(startSymbolField.enableSuggestions, isFalse);
      expect(startSymbolField.keyboardType, TextInputType.visiblePassword);

      final leftSideField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'e.g., S, A, B').first,
      );
      final rightSideField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'e.g., aA, bB, ε').first,
      );

      expect(leftSideField.autocorrect, isFalse);
      expect(leftSideField.enableSuggestions, isFalse);
      expect(leftSideField.keyboardType, TextInputType.visiblePassword);
      expect(rightSideField.autocorrect, isFalse);
      expect(rightSideField.enableSuggestions, isFalse);
      expect(rightSideField.keyboardType, TextInputType.visiblePassword);
    });

    testWidgets('updates grammar name when text field changes', (tester) async {
      final provider = _RecordingGrammarProvider();
      await pumpEditor(tester, provider);

      final grammarNameField = find
          .widgetWithText(TextField, 'My Grammar')
          .first;
      await tester.enterText(grammarNameField, 'Test Grammar');
      await tester.pump();

      expect(provider.updateNameCalls, equals(1));
      expect(provider.lastNameValue, equals('Test Grammar'));
    });

    testWidgets('updates start symbol when text field changes', (tester) async {
      final provider = _RecordingGrammarProvider();
      await pumpEditor(tester, provider);

      final startSymbolField = find.widgetWithText(TextField, 'S').first;
      await tester.enterText(startSymbolField, 'A');
      await tester.pump();

      expect(provider.updateStartSymbolCalls, equals(1));
      expect(provider.lastStartSymbolValue, equals('A'));
    });
  });

  group('GrammarEditor production management', () {
    testWidgets('helper text is visible by default', (tester) async {
      final provider = _RecordingGrammarProvider();
      await pumpEditor(tester, provider);

      expect(find.text(AppLocalizationsEn().leftSideHelper), findsOneWidget);
      expect(find.text(AppLocalizationsEn().rightSideHelper), findsOneWidget);
    });

    testWidgets(
      'epsilon shortcut inserts canonical symbol into right side field',
      (tester) async {
        final provider = _RecordingGrammarProvider();
        await pumpEditor(tester, provider);

        final rightSideField = find.widgetWithText(
          TextField,
          'e.g., aA, bB, ε',
        );
        await tester.tap(rightSideField);
        await tester.pump();

        expect(find.text('Insert λ'), findsNothing);
        await tester.tap(find.text('Insert ε'));
        await tester.pump();

        final rightSideTextField = tester.widget<TextField>(rightSideField);
        expect(rightSideTextField.controller?.text, equals('ε'));
      },
    );

    testWidgets('can add a production after inserting ε shortcut', (
      tester,
    ) async {
      final provider = _RecordingGrammarProvider();
      await pumpEditor(tester, provider);

      await tester.enterText(
        find.widgetWithText(TextField, 'e.g., S, A, B'),
        'S',
      );
      await tester.tap(find.text('Insert ε'));
      await tester.pump();

      await tester.tap(_findButtonWithText('Add'));
      await tester.pumpAndSettle();

      expect(provider.addProductionCalls, hasLength(1));
      expect(provider.addProductionCalls.single['leftSide'], equals(['S']));
      expect(
        provider.addProductionCalls.single['rightSide'],
        equals(<String>[]),
      );
      expect(provider.addProductionCalls.single['isLambda'], equals(true));

      // Lambda productions are formatted as epsilon in the productions list.
      expect(find.text('S → ε'), findsOneWidget);
    });

    testWidgets('adds a simple production when fields are filled', (
      tester,
    ) async {
      final provider = _RecordingGrammarProvider();
      await pumpEditor(tester, provider);

      final leftSideField = find.widgetWithText(TextField, 'e.g., S, A, B');
      await tester.enterText(leftSideField, 'S');
      await tester.pump();

      final rightSideField = find.widgetWithText(TextField, 'e.g., aA, bB, ε');
      await tester.enterText(rightSideField, 'aA');
      await tester.pump();

      final addButton = _findButtonWithText('Add');
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      expect(provider.addProductionCalls, hasLength(1));
      final call = provider.addProductionCalls.first;
      expect(call['leftSide'], equals(['S']));
      expect(call['rightSide'], equals(['a', 'A']));
      expect(call['isLambda'], equals(false));
    });

    testWidgets('adds a lambda production with epsilon symbol', (tester) async {
      final provider = _RecordingGrammarProvider();
      await pumpEditor(tester, provider);

      final leftSideField = find.widgetWithText(TextField, 'e.g., S, A, B');
      await tester.enterText(leftSideField, 'S');
      await tester.pump();

      final rightSideField = find.widgetWithText(TextField, 'e.g., aA, bB, ε');
      await tester.enterText(rightSideField, 'ε');
      await tester.pump();

      final addButton = _findButtonWithText('Add');
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      expect(provider.addProductionCalls, hasLength(1));
      final call = provider.addProductionCalls.first;
      expect(call['leftSide'], equals(['S']));
      expect(call['rightSide'], equals([]));
      expect(call['isLambda'], equals(true));
    });

    testWidgets('shows specific error for repeated lambda symbols', (
      tester,
    ) async {
      final provider = _RecordingGrammarProvider();
      await pumpEditor(tester, provider);

      await tester.enterText(
        find.widgetWithText(TextField, 'e.g., S, A, B'),
        'S',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'e.g., aA, bB, ε'),
        'λε',
      );
      await tester.pump();

      await tester.tap(_findButtonWithText('Add'));
      await tester.pumpAndSettle();

      expect(provider.addProductionCalls, isEmpty);
      expect(
        find.text('Right side can contain only one ε symbol'),
        findsOneWidget,
      );
      expect(
        find.text('ε must be the only symbol on the right side'),
        findsNothing,
      );
    });

    testWidgets(
      'shows specific error when lambda is mixed with other symbols',
      (tester) async {
        final provider = _RecordingGrammarProvider();
        await pumpEditor(tester, provider);

        await tester.enterText(
          find.widgetWithText(TextField, 'e.g., S, A, B'),
          'S',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'e.g., aA, bB, ε'),
          'λA',
        );
        await tester.pump();

        await tester.tap(_findButtonWithText('Add'));
        await tester.pumpAndSettle();

        expect(provider.addProductionCalls, isEmpty);
        expect(
          find.text('ε must be the only symbol on the right side'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows error when adding production with empty left side (helper text stays visible)',
      (tester) async {
        final provider = _RecordingGrammarProvider();
        await pumpEditor(tester, provider);

        final rightSideField = find.widgetWithText(
          TextField,
          'e.g., aA, bB, ε',
        );
        await tester.enterText(rightSideField, 'aA');
        await tester.pump();

        final addButton = _findButtonWithText('Add');
        await tester.tap(addButton);
        await tester.pumpAndSettle();

        expect(provider.addProductionCalls, hasLength(0));
        expect(
          find.text('Both left side and right side must be specified'),
          findsOneWidget,
        );
        expect(find.text(AppLocalizationsEn().leftSideHelper), findsOneWidget);
        expect(find.text(AppLocalizationsEn().rightSideHelper), findsOneWidget);
      },
    );

    testWidgets('shows error when adding production with empty right side', (
      tester,
    ) async {
      final provider = _RecordingGrammarProvider();
      await pumpEditor(tester, provider);

      final leftSideField = find.widgetWithText(TextField, 'e.g., S, A, B');
      await tester.enterText(leftSideField, 'S');
      await tester.pump();

      final addButton = _findButtonWithText('Add');
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      expect(provider.addProductionCalls, hasLength(0));
      expect(
        find.text('Both left side and right side must be specified'),
        findsOneWidget,
      );
    });

    testWidgets('clears input fields after adding production', (tester) async {
      final provider = _RecordingGrammarProvider();
      await pumpEditor(tester, provider);

      final leftSideField = find.widgetWithText(TextField, 'e.g., S, A, B');
      await tester.enterText(leftSideField, 'S');
      await tester.pump();

      final rightSideField = find.widgetWithText(TextField, 'e.g., aA, bB, ε');
      await tester.enterText(rightSideField, 'aA');
      await tester.pump();

      final addButton = _findButtonWithText('Add');
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      final leftField = tester.widget<TextField>(leftSideField);
      final rightField = tester.widget<TextField>(rightSideField);

      expect(leftField.controller?.text, equals(''));
      expect(rightField.controller?.text, equals(''));
    });
  });

  group('GrammarEditor production list', () {
    testWidgets('adds pipe-separated alternatives as one visual group', (
      tester,
    ) async {
      final provider = _RecordingGrammarProvider();
      await pumpEditor(tester, provider);

      await tester.enterText(
        find.widgetWithText(TextField, 'e.g., S, A, B'),
        'A',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'e.g., aA, bB, ε'),
        'AA | Aa',
      );
      await tester.tap(_findButtonWithText('Add'));
      await tester.pumpAndSettle();

      expect(provider.state.productions, hasLength(2));
      expect(provider.addProductionCalls, hasLength(2));
      expect(find.text('Production Rules (2)'), findsOneWidget);
      expect(find.text('A → AA | Aa'), findsOneWidget);
      expect(find.text('2 alternatives'), findsOneWidget);
      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    });

    testWidgets('later additions merge into the existing visual group', (
      tester,
    ) async {
      final provider = _RecordingGrammarProvider();
      await pumpEditor(tester, provider);

      Future<void> add(String rightSide) async {
        await tester.enterText(
          find.widgetWithText(TextField, 'e.g., S, A, B'),
          'A',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'e.g., aA, bB, ε'),
          rightSide,
        );
        await tester.tap(_findButtonWithText('Add'));
        await tester.pumpAndSettle();
      }

      await add('AA | Aa');
      await add('a | lambda');

      expect(provider.state.productions, hasLength(4));
      expect(find.text('A → AA | Aa | a | ε'), findsOneWidget);
      expect(find.text('4 alternatives'), findsOneWidget);
      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    });

    testWidgets('rejects empty alternatives without partial mutation', (
      tester,
    ) async {
      final provider = _RecordingGrammarProvider();
      await pumpEditor(tester, provider);

      await tester.enterText(
        find.widgetWithText(TextField, 'e.g., S, A, B'),
        'A',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'e.g., aA, bB, ε'),
        'a || b',
      );
      await tester.tap(_findButtonWithText('Add'));
      await tester.pumpAndSettle();

      expect(provider.state.productions, isEmpty);
      expect(provider.addProductionCalls, isEmpty);
      expect(
        find.text('Enter a value between each | separator'),
        findsOneWidget,
      );
    });

    testWidgets('rejects a malformed alternative atomically', (tester) async {
      final provider = _RecordingGrammarProvider();
      await pumpEditor(tester, provider);

      await tester.enterText(
        find.widgetWithText(TextField, 'e.g., S, A, B'),
        'A',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'e.g., aA, bB, ε'),
        'a | aλ',
      );
      await tester.tap(_findButtonWithText('Add'));
      await tester.pumpAndSettle();

      expect(provider.state.productions, isEmpty);
      expect(provider.addProductionCalls, isEmpty);
      expect(
        find.text('ε must be the only symbol on the right side'),
        findsOneWidget,
      );
    });

    testWidgets('accepts an escaped literal pipe terminal', (tester) async {
      final provider = _RecordingGrammarProvider();
      await pumpEditor(tester, provider);

      await tester.enterText(
        find.widgetWithText(TextField, 'e.g., S, A, B'),
        'A',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'e.g., aA, bB, ε'),
        r'\|',
      );
      await tester.tap(_findButtonWithText('Add'));
      await tester.pumpAndSettle();

      expect(provider.state.productions.single.rightSide, ['|']);
      expect(find.text(r'A → \|'), findsOneWidget);
    });

    testWidgets('preserves whitespace-delimited multi-character symbols', (
      tester,
    ) async {
      final provider = _RecordingGrammarProvider();
      await pumpEditor(tester, provider);

      await tester.enterText(
        find.widgetWithText(TextField, 'e.g., S, A, B'),
        'A',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'e.g., aA, bB, ε'),
        'id A | number',
      );
      await tester.tap(_findButtonWithText('Add'));
      await tester.pumpAndSettle();

      expect(
        provider.state.productions.map((production) => production.rightSide),
        [
          ['id', 'A'],
          ['n', 'u', 'm', 'b', 'e', 'r'],
        ],
      );
      expect(find.text('A → id A | number'), findsOneWidget);
    });

    testWidgets('normalizes all supported empty-string input aliases', (
      tester,
    ) async {
      final provider = _RecordingGrammarProvider();
      await pumpEditor(tester, provider);

      await tester.enterText(
        find.widgetWithText(TextField, 'e.g., S, A, B'),
        'A',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'e.g., aA, bB, ε'),
        'lambda | λ | ε',
      );
      await tester.tap(_findButtonWithText('Add'));
      await tester.pumpAndSettle();

      expect(provider.state.productions, hasLength(1));
      expect(provider.state.productions.single.isLambda, isTrue);
      expect(provider.state.productions.single.rightSide, isEmpty);
      expect(find.text('A → ε'), findsOneWidget);
      expect(
        find.text('Added 1; skipped 2 that already existed.'),
        findsOneWidget,
      );
    });

    testWidgets('reports a pasted complete production expression', (
      tester,
    ) async {
      final provider = _RecordingGrammarProvider();
      await pumpEditor(tester, provider);

      await tester.enterText(
        find.widgetWithText(TextField, 'e.g., S, A, B'),
        'A',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'e.g., aA, bB, ε'),
        'A -> a | b',
      );
      await tester.tap(_findButtonWithText('Add'));
      await tester.pumpAndSettle();

      expect(provider.state.productions, isEmpty);
      expect(
        find.text('Enter only right-side alternatives here, without an arrow'),
        findsOneWidget,
      );
    });

    testWidgets('adds only new alternatives and reports duplicates', (
      tester,
    ) async {
      final provider = _RecordingGrammarProvider()
        ..addProduction(leftSide: const ['A'], rightSide: const ['a']);
      await pumpEditor(tester, provider);

      await tester.enterText(
        find.widgetWithText(TextField, 'e.g., S, A, B'),
        'A',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'e.g., aA, bB, ε'),
        'a | b',
      );
      await tester.tap(_findButtonWithText('Add'));
      await tester.pumpAndSettle();

      expect(provider.state.productions, hasLength(2));
      expect(find.text('A → a | b'), findsOneWidget);
      expect(
        find.text('Added 1; skipped 1 that already existed.'),
        findsOneWidget,
      );
    });

    testWidgets('leaves state unchanged when every alternative exists', (
      tester,
    ) async {
      final provider = _RecordingGrammarProvider()
        ..addProduction(leftSide: const ['A'], rightSide: const ['a']);
      await pumpEditor(tester, provider);
      final before = provider.state;

      await tester.enterText(
        find.widgetWithText(TextField, 'e.g., S, A, B'),
        'A',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'e.g., aA, bB, ε'),
        'a',
      );
      await tester.tap(_findButtonWithText('Add'));
      await tester.pumpAndSettle();

      expect(identical(provider.state, before), isTrue);
      expect(find.text('That alternative already exists.'), findsOneWidget);
    });

    testWidgets('groups loaded productions by first left-side appearance', (
      tester,
    ) async {
      final provider = _RecordingGrammarProvider()
        ..addProduction(leftSide: const ['S'], rightSide: const ['a'])
        ..addProduction(leftSide: const ['A'], rightSide: const ['b'])
        ..addProduction(leftSide: const ['S'], rightSide: const ['c']);
      await pumpEditor(tester, provider);

      expect(find.text('S → a | c'), findsOneWidget);
      expect(find.text('A → b'), findsOneWidget);
      expect(find.byType(PopupMenuButton<String>), findsNWidgets(2));
      expect(
        tester.getTopLeft(find.text('S → a | c')).dy,
        lessThan(tester.getTopLeft(find.text('A → b')).dy),
      );
    });

    testWidgets('exposes localized handles, positions, and menu boundaries', (
      tester,
    ) async {
      final provider = _RecordingGrammarProvider()
        ..addProduction(leftSide: const ['S'], rightSide: const ['s'])
        ..addProduction(leftSide: const ['A'], rightSide: const ['a'])
        ..addProduction(leftSide: const ['B'], rightSide: const ['b']);
      await pumpEditor(tester, provider);

      final handle = find.byKey(
        const ValueKey('grammar-production-group-handle-p1'),
      );
      final semantics = tester.getSemantics(handle);
      expect(semantics.label, contains('Reorder productions for S'));
      expect(semantics.value, contains('Position 1 of 3'));
      expect(tester.getSize(handle), const Size(48, 48));

      await tester.tap(find.byTooltip('Production group actions').first);
      await tester.pumpAndSettle();
      final moveUp = tester.widget<PopupMenuItem<String>>(
        find.ancestor(
          of: find.text('Move up'),
          matching: find.byType(PopupMenuItem<String>),
        ),
      );
      final moveDown = tester.widget<PopupMenuItem<String>>(
        find.ancestor(
          of: find.text('Move down'),
          matching: find.byType(PopupMenuItem<String>),
        ),
      );
      expect(moveUp.enabled, isFalse);
      expect(moveDown.enabled, isTrue);
    });

    testWidgets('moves a complete group from the menu and restores focus', (
      tester,
    ) async {
      final provider = _RecordingGrammarProvider()
        ..addProduction(leftSide: const ['S'], rightSide: const ['a'])
        ..addProduction(leftSide: const ['A'], rightSide: const ['b'])
        ..addProduction(leftSide: const ['S'], rightSide: const ['c'])
        ..addProduction(leftSide: const ['B'], rightSide: const ['d']);
      await pumpEditor(tester, provider);

      await tester.tap(find.byTooltip('Production group actions').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Move down'));
      await tester.pumpAndSettle();

      expect(provider.state.productions.map((production) => production.id), [
        'p2',
        'p1',
        'p3',
        'p4',
      ]);
      expect(provider.state.productions.map((production) => production.order), [
        0,
        1,
        2,
        3,
      ]);
      final movedHandle = find.byKey(
        const ValueKey('grammar-production-group-handle-p1'),
      );
      expect(
        tester.getSemantics(movedHandle).value,
        contains('Position 2 of 3'),
      );
      final movedSemantics = tester.getSemantics(movedHandle);
      // Flutter 3.32 compatibility.
      // ignore: deprecated_member_use
      expect(movedSemantics.hasFlag(SemanticsFlag.isFocused), isTrue);
    });

    testWidgets('drags a group only from its explicit handle', (tester) async {
      final provider = _RecordingGrammarProvider()
        ..addProduction(leftSide: const ['S'], rightSide: const ['s'])
        ..addProduction(leftSide: const ['A'], rightSide: const ['a'])
        ..addProduction(leftSide: const ['B'], rightSide: const ['b']);
      await pumpEditor(tester, provider);

      final firstHandle = find.byKey(
        const ValueKey('grammar-production-group-handle-p1'),
      );
      final gesture = await tester.startGesture(tester.getCenter(firstHandle));
      await tester.pump();
      await gesture.moveTo(
        tester.getBottomRight(
              find.byKey(const ValueKey('grammar-production-scroll-view')),
            ) -
            const Offset(24, 24),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(provider.state.productions.map((production) => production.id), [
        'p2',
        'p3',
        'p1',
      ]);
    });

    testWidgets('scrolls from row content without starting a reorder', (
      tester,
    ) async {
      final provider = _RecordingGrammarProvider();
      for (var index = 0; index < 8; index++) {
        provider.addProduction(leftSide: ['N$index'], rightSide: ['t$index']);
      }
      final originalIds = provider.state.productions
          .map((production) => production.id)
          .toList();
      tester.view.physicalSize = const Size(400, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [grammarProvider.overrideWith((ref) => provider)],
          child: const MaterialApp(
            home: Scaffold(
              body: GrammarEditor(section: GrammarEditorSection.productions),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.text('N0 → t0'), const Offset(0, -180));
      await tester.pumpAndSettle();
      final scrollable = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byKey(const ValueKey('grammar-production-scroll-view')),
              matching: find.byType(Scrollable),
            )
            .first,
      );

      expect(scrollable.position.pixels, greaterThan(0));
      expect(
        provider.state.productions.map((production) => production.id),
        originalIds,
      );
    });

    testWidgets('renders empty alternatives with configured notation', (
      tester,
    ) async {
      final provider = _RecordingGrammarProvider()
        ..addProduction(
          leftSide: const ['A'],
          rightSide: const [],
          isLambda: true,
        );
      tester.view.physicalSize = const Size(1366, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [grammarProvider.overrideWith((ref) => provider)],
          child: const EmptyStringNotation(
            symbol: 'λ',
            child: MaterialApp(home: Scaffold(body: GrammarEditor())),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('A → λ'), findsOneWidget);
      expect(find.text('A → ε'), findsNothing);
    });

    testWidgets('displays added productions in the list', (tester) async {
      final provider = _RecordingGrammarProvider();
      await pumpEditor(tester, provider);

      final leftSideField = find.widgetWithText(TextField, 'e.g., S, A, B');
      await tester.enterText(leftSideField, 'S');

      final rightSideField = find.widgetWithText(TextField, 'e.g., aA, bB, ε');
      await tester.enterText(rightSideField, 'aA');

      final addButton = _findButtonWithText('Add');
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      expect(find.text('Production Rules (1)'), findsOneWidget);
      expect(find.text('S → aA'), findsOneWidget);
      expect(find.text('1 alternative'), findsOneWidget);
    });

    testWidgets('displays lambda productions with epsilon symbol', (
      tester,
    ) async {
      final provider = _RecordingGrammarProvider();
      await pumpEditor(tester, provider);

      final leftSideField = find.widgetWithText(TextField, 'e.g., S, A, B');
      await tester.enterText(leftSideField, 'A');

      final rightSideField = find.widgetWithText(TextField, 'e.g., aA, bB, ε');
      await tester.enterText(rightSideField, 'ε');

      final addButton = _findButtonWithText('Add');
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      expect(find.text('A → ε'), findsOneWidget);
    });

    testWidgets('allows selecting a production by tapping', (tester) async {
      final provider = _RecordingGrammarProvider();
      await pumpEditor(tester, provider);

      provider.addProduction(
        leftSide: ['S'],
        rightSide: ['a', 'A'],
        isLambda: false,
      );
      await tester.pumpAndSettle();

      final productionTile = find.ancestor(
        of: find.text('S → aA'),
        matching: find.byType(ListTile),
      );
      await tester.tap(productionTile);
      await tester.pumpAndSettle();

      final listTile = tester.widget<ListTile>(productionTile);
      expect(listTile.selected, equals(true));
    });
  });

  group('GrammarEditor production editing', () {
    testWidgets('edits a complete group and preserves retained IDs', (
      tester,
    ) async {
      final provider = _RecordingGrammarProvider()
        ..addProductionAlternatives(
          leftSide: const ['A'],
          alternatives: const [
            ProductionAlternativeDraft(rightSide: ['a']),
            ProductionAlternativeDraft(rightSide: ['b']),
          ],
        );
      await pumpEditor(tester, provider);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit alternatives'));
      await tester.pumpAndSettle();

      final rightSideField = find.widgetWithText(TextField, 'a | b');
      expect(rightSideField, findsOneWidget);
      await tester.enterText(rightSideField, 'a | c');
      await tester.tap(_findButtonWithText('Update'));
      await tester.pumpAndSettle();

      expect(provider.state.productions.map((production) => production.id), [
        'p1',
        'p3',
      ]);
      expect(find.text('A → a | c'), findsOneWidget);
    });

    testWidgets('enters edit mode when edit menu option is selected', (
      tester,
    ) async {
      final provider = _RecordingGrammarProvider();
      await pumpEditor(tester, provider);

      provider.addProduction(
        leftSide: ['S'],
        rightSide: ['a', 'A'],
        isLambda: false,
      );
      await tester.pumpAndSettle();

      final moreButton = find.byIcon(Icons.more_vert);
      await tester.tap(moreButton);
      await tester.pumpAndSettle();

      final editOption = find.text('Edit alternatives');
      await tester.tap(editOption);
      await tester.pumpAndSettle();

      expect(find.text('Edit alternatives'), findsWidgets);
      expect(_findButtonWithText('Update'), findsOneWidget);
      expect(_findButtonWithText('Cancel'), findsOneWidget);
    });

    testWidgets('populates fields with production data in edit mode', (
      tester,
    ) async {
      final provider = _RecordingGrammarProvider();
      await pumpEditor(tester, provider);

      provider.addProduction(
        leftSide: ['S'],
        rightSide: ['a', 'B'],
        isLambda: false,
      );
      await tester.pumpAndSettle();

      final moreButton = find.byIcon(Icons.more_vert);
      await tester.tap(moreButton);
      await tester.pumpAndSettle();

      final editOption = find.text('Edit alternatives');
      await tester.tap(editOption);
      await tester.pumpAndSettle();

      // In edit mode, the left side field has 'S' as its controller text.
      // The start symbol field also has 'S', so disambiguate by label.
      final leftField = find.ancestor(
        of: find.text('Left Side (Variable)'),
        matching: find.byType(TextField),
      );
      final rightField = find.widgetWithText(TextField, 'aB');

      expect(leftField, findsOneWidget);
      expect(rightField, findsOneWidget);

      // Verify the left side controller text is 'S'.
      final leftTextField = tester.widget<TextField>(leftField);
      expect(leftTextField.controller?.text, equals('S'));
    });

    testWidgets('updates production when Update button is pressed', (
      tester,
    ) async {
      final provider = _RecordingGrammarProvider();
      await pumpEditor(tester, provider);

      provider.addProduction(
        leftSide: ['S'],
        rightSide: ['a', 'A'],
        isLambda: false,
      );
      await tester.pumpAndSettle();

      final moreButton = find.byIcon(Icons.more_vert);
      await tester.tap(moreButton);
      await tester.pumpAndSettle();

      final editOption = find.text('Edit alternatives');
      await tester.tap(editOption);
      await tester.pumpAndSettle();

      final rightSideField = find.widgetWithText(TextField, 'aA');
      await tester.enterText(rightSideField, 'bB');
      await tester.pump();

      final updateButton = _findButtonWithText('Update');
      await tester.tap(updateButton);
      await tester.pumpAndSettle();

      expect(provider.updateProductionCalls, hasLength(1));
      final call = provider.updateProductionCalls.first;
      expect(call['id'], equals('p1'));
      expect(call['rightSide'], equals(['b', 'B']));
    });

    testWidgets('exits edit mode when Cancel button is pressed', (
      tester,
    ) async {
      final provider = _RecordingGrammarProvider();
      await pumpEditor(tester, provider);

      provider.addProduction(
        leftSide: ['S'],
        rightSide: ['a', 'A'],
        isLambda: false,
      );
      await tester.pumpAndSettle();

      final moreButton = find.byIcon(Icons.more_vert);
      await tester.tap(moreButton);
      await tester.pumpAndSettle();

      final editOption = find.text('Edit alternatives');
      await tester.tap(editOption);
      await tester.pumpAndSettle();

      expect(find.text('Edit alternatives'), findsWidgets);

      final cancelButton = _findButtonWithText('Cancel');
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      expect(find.text('Add Production Rule'), findsOneWidget);
      expect(_findButtonWithText('Add'), findsOneWidget);
      expect(provider.updateProductionCalls, hasLength(0));
    });

    testWidgets('clears fields after canceling edit', (tester) async {
      final provider = _RecordingGrammarProvider();
      await pumpEditor(tester, provider);

      provider.addProduction(
        leftSide: ['S'],
        rightSide: ['a', 'A'],
        isLambda: false,
      );
      await tester.pumpAndSettle();

      final moreButton = find.byIcon(Icons.more_vert);
      await tester.tap(moreButton);
      await tester.pumpAndSettle();

      final editOption = find.text('Edit alternatives');
      await tester.tap(editOption);
      await tester.pumpAndSettle();

      final cancelButton = _findButtonWithText('Cancel');
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      final leftSideField = find.widgetWithText(TextField, 'e.g., S, A, B');
      final rightSideField = find.widgetWithText(TextField, 'e.g., aA, bB, ε');

      final leftField = tester.widget<TextField>(leftSideField);
      final rightField = tester.widget<TextField>(rightSideField);

      expect(leftField.controller?.text, equals(''));
      expect(rightField.controller?.text, equals(''));
    });
  });

  group('GrammarEditor production deletion', () {
    testWidgets('confirms and deletes every alternative in a group', (
      tester,
    ) async {
      final provider = _RecordingGrammarProvider()
        ..addProductionAlternatives(
          leftSide: const ['A'],
          alternatives: const [
            ProductionAlternativeDraft(rightSide: ['a']),
            ProductionAlternativeDraft(rightSide: ['b']),
          ],
        );
      await pumpEditor(tester, provider);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete group'));
      await tester.pumpAndSettle();

      expect(find.text('This will delete 2 alternatives.'), findsOneWidget);
      expect(provider.state.productions, hasLength(2));
      await tester.tap(find.widgetWithText(FilledButton, 'Delete group'));
      await tester.pumpAndSettle();

      expect(provider.state.productions, isEmpty);
    });

    testWidgets('deletes production when delete menu option is selected', (
      tester,
    ) async {
      final provider = _RecordingGrammarProvider();
      await pumpEditor(tester, provider);

      provider.addProduction(
        leftSide: ['S'],
        rightSide: ['a', 'A'],
        isLambda: false,
      );
      await tester.pumpAndSettle();

      expect(find.text('Production Rules (1)'), findsOneWidget);

      final moreButton = find.byIcon(Icons.more_vert);
      await tester.tap(moreButton);
      await tester.pumpAndSettle();

      final deleteOption = find.text('Delete group');
      await tester.tap(deleteOption);
      await tester.pumpAndSettle();

      expect(find.text('This will delete 1 alternative.'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete group'));
      await tester.pumpAndSettle();

      expect(provider.deleteProductionCalls, hasLength(1));
      expect(provider.deleteProductionCalls.first, equals('p1'));
      expect(find.text('Production Rules (0)'), findsOneWidget);
    });

    testWidgets('exits edit mode if deleted production was being edited', (
      tester,
    ) async {
      final provider = _RecordingGrammarProvider();
      await pumpEditor(tester, provider);

      provider.addProduction(
        leftSide: ['S'],
        rightSide: ['a', 'A'],
        isLambda: false,
      );
      await tester.pumpAndSettle();

      final moreButton = find.byIcon(Icons.more_vert);
      await tester.tap(moreButton);
      await tester.pumpAndSettle();

      final editOption = find.text('Edit alternatives');
      await tester.tap(editOption);
      await tester.pumpAndSettle();

      expect(find.text('Edit alternatives'), findsWidgets);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      final deleteOption = find.text('Delete group');
      await tester.tap(deleteOption);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Delete group'));
      await tester.pumpAndSettle();

      expect(find.text('Add Production Rule'), findsOneWidget);
      expect(_findButtonWithText('Add'), findsOneWidget);
    });
  });

  group('GrammarEditor clear functionality', () {
    testWidgets('clears all productions when Clear button is pressed', (
      tester,
    ) async {
      final provider = _RecordingGrammarProvider();
      await pumpEditor(tester, provider);

      provider.addProduction(
        leftSide: ['S'],
        rightSide: ['a', 'A'],
        isLambda: false,
      );
      provider.addProduction(
        leftSide: ['A'],
        rightSide: ['b'],
        isLambda: false,
      );
      await tester.pumpAndSettle();

      expect(find.text('Production Rules (2)'), findsOneWidget);

      final clearButton = _findButtonWithText('Clear');
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      // Confirmation dialog.
      await tester.tap(find.widgetWithText(FilledButton, 'Clear'));
      await tester.pumpAndSettle();

      expect(provider.clearProductionsCalls, equals(1));
      expect(find.text('Production Rules (0)'), findsOneWidget);
      expect(find.text('No production rules yet'), findsOneWidget);
      expect(find.text('Clear now'), findsNothing);
      expect(find.widgetWithText(TextButton, 'Undo'), findsOneWidget);
    });

    testWidgets('undo restores productions after clearing', (tester) async {
      final provider = _RecordingGrammarProvider();
      await pumpEditor(tester, provider);

      provider.addProduction(
        leftSide: ['S'],
        rightSide: ['a', 'A'],
        isLambda: false,
      );
      provider.addProduction(
        leftSide: ['A'],
        rightSide: ['b'],
        isLambda: false,
      );
      await tester.pumpAndSettle();

      expect(find.text('Production Rules (2)'), findsOneWidget);

      final clearButton = _findButtonWithText('Clear');
      await tester.tap(clearButton);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Clear'));
      await tester.pumpAndSettle();

      expect(find.text('Production Rules (0)'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Undo'));
      await tester.pumpAndSettle();

      expect(provider.setProductionsCalls, equals(1));
      expect(find.text('Production Rules (2)'), findsOneWidget);
      expect(find.text('S → aA'), findsOneWidget);
      expect(find.text('A → b'), findsOneWidget);
    });

    testWidgets('exits edit mode when Clear button is pressed', (tester) async {
      final provider = _RecordingGrammarProvider();
      await pumpEditor(tester, provider);

      provider.addProduction(
        leftSide: ['S'],
        rightSide: ['a', 'A'],
        isLambda: false,
      );
      await tester.pumpAndSettle();

      final moreButton = find.byIcon(Icons.more_vert);
      await tester.tap(moreButton);
      await tester.pumpAndSettle();

      final editOption = find.text('Edit alternatives');
      await tester.tap(editOption);
      await tester.pumpAndSettle();

      expect(find.text('Edit alternatives'), findsWidgets);

      final clearButton = _findButtonWithText('Clear');
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      // Clear shouldn't happen until the confirmation is accepted.
      expect(find.text('Edit alternatives'), findsWidgets);

      await tester.tap(find.widgetWithText(FilledButton, 'Clear'));
      await tester.pumpAndSettle();

      expect(find.text('Add Production Rule'), findsOneWidget);
    });
  });

  group('GrammarEditor responsive layout', () {
    testWidgets('long grouped rules wrap without ellipsis on narrow screens', (
      tester,
    ) async {
      final provider = _RecordingGrammarProvider()
        ..addProductionAlternatives(
          leftSide: const ['A'],
          alternatives: List.generate(
            8,
            (index) =>
                ProductionAlternativeDraft(rightSide: ['longTerminal$index']),
          ),
        );
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [grammarProvider.overrideWith((ref) => provider)],
          child: const MaterialApp(
            home: Scaffold(
              body: GrammarEditor(section: GrammarEditorSection.productions),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final ruleText = tester.widget<Text>(
        find.textContaining('longTerminal0'),
      );
      expect(ruleText.maxLines, isNull);
      expect(ruleText.overflow, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps reorder controls visible at 320px and 200 percent', (
      tester,
    ) async {
      final provider = _RecordingGrammarProvider()
        ..addProduction(
          leftSide: const ['S'],
          rightSide: const ['longTerminalOne'],
        )
        ..addProduction(
          leftSide: const ['A'],
          rightSide: const ['longTerminalTwo'],
        );
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [grammarProvider.overrideWith((ref) => provider)],
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: const Scaffold(
              body: GrammarEditor(section: GrammarEditorSection.productions),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getSize(
          find.byKey(const ValueKey('grammar-production-group-handle-p1')),
        ),
        const Size(48, 48),
      );
      expect(find.textContaining('longTerminalOne'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('displays compact header on small screens', (tester) async {
      final provider = _RecordingGrammarProvider();

      tester.view.physicalSize = const Size(500, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [grammarProvider.overrideWith((ref) => provider)],
          child: const MaterialApp(home: Scaffold(body: GrammarEditor())),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.text_fields), findsOneWidget);
      expect(find.text('Grammar Editor'), findsOneWidget);
    });

    testWidgets(
      'displays vertical layout for production editor on small screens',
      (tester) async {
        final provider = _RecordingGrammarProvider();

        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [grammarProvider.overrideWith((ref) => provider)],
            child: const MaterialApp(home: Scaffold(body: GrammarEditor())),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
      },
    );

    testWidgets(
      'displays horizontal layout for production editor on large screens',
      (tester) async {
        final provider = _RecordingGrammarProvider();

        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [grammarProvider.overrideWith((ref) => provider)],
            child: const MaterialApp(home: Scaffold(body: GrammarEditor())),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      },
    );
  });
}
