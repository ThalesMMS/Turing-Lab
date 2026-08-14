//
//  grammar_editor_test.dart
//  Turing Lab
//
//  Suite abrangente que examina o GrammarEditor, garantindo integração com
//  provedores simulados e validações de interação por formulários. Os testes
//  validam adição, edição e remoção de produções, atualização de metadados,
//  ações de limpeza e respostas a validações de entrada, assegurando
//  consistência entre a interface e o estado da gramática.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/presentation/providers/grammar_provider.dart';
import 'package:turing_lab/presentation/widgets/grammar_editor.dart';

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
  void addProduction({
    required List<String> leftSide,
    required List<String> rightSide,
    bool isLambda = false,
  }) {
    addProductionCalls.add({
      'leftSide': leftSide,
      'rightSide': rightSide,
      'isLambda': isLambda,
    });
    super.addProduction(
      leftSide: leftSide,
      rightSide: rightSide,
      isLambda: isLambda,
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
  void deleteProduction(String id) {
    deleteProductionCalls.add(id);
    super.deleteProduction(id);
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

      expect(
        find.text('Enter exactly one non-terminal (e.g., S).'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Use λ/ε for empty string. Right side can be multiple symbols (e.g., aA).',
        ),
        findsOneWidget,
      );
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

      final grammarNameField =
          find.widgetWithText(TextField, 'My Grammar').first;
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

      expect(
        find.text('Enter exactly one non-terminal (e.g., S).'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Use λ/ε for empty string. Right side can be multiple symbols (e.g., aA).',
        ),
        findsOneWidget,
      );
    });

    testWidgets('lambda shortcut inserts symbol into right side field', (
      tester,
    ) async {
      final provider = _RecordingGrammarProvider();
      await pumpEditor(tester, provider);

      final rightSideField = find.widgetWithText(TextField, 'e.g., aA, bB, ε');
      await tester.tap(rightSideField);
      await tester.pump();

      await tester.tap(find.text('Insert λ'));
      await tester.pump();

      final rightSideTextField = tester.widget<TextField>(rightSideField);
      expect(rightSideTextField.controller?.text, equals('λ'));
    });

    testWidgets('can add a production after inserting λ shortcut', (
      tester,
    ) async {
      final provider = _RecordingGrammarProvider();
      await pumpEditor(tester, provider);

      await tester.enterText(
        find.widgetWithText(TextField, 'e.g., S, A, B'),
        'S',
      );
      await tester.tap(find.text('Insert λ'));
      await tester.pump();

      await tester.tap(_findButtonWithText('Add'));
      await tester.pumpAndSettle();

      expect(provider.addProductionCalls, hasLength(1));
      expect(provider.addProductionCalls.single['leftSide'], equals(['S']));
      expect(
          provider.addProductionCalls.single['rightSide'], equals(<String>[]));
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
        find.text('Right side can contain only one λ/ε symbol'),
        findsOneWidget,
      );
      expect(
        find.text('λ/ε must be the only symbol on the right side'),
        findsNothing,
      );
    });

    testWidgets('shows specific error when lambda is mixed with other symbols',
        (
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
        'λA',
      );
      await tester.pump();

      await tester.tap(_findButtonWithText('Add'));
      await tester.pumpAndSettle();

      expect(provider.addProductionCalls, isEmpty);
      expect(
        find.text('λ/ε must be the only symbol on the right side'),
        findsOneWidget,
      );
    });

    testWidgets(
        'shows error when adding production with empty left side (helper text stays visible)',
        (
      tester,
    ) async {
      final provider = _RecordingGrammarProvider();
      await pumpEditor(tester, provider);

      final rightSideField = find.widgetWithText(TextField, 'e.g., aA, bB, ε');
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
      expect(
        find.text('Enter exactly one non-terminal (e.g., S).'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Use λ/ε for empty string. Right side can be multiple symbols (e.g., aA).',
        ),
        findsOneWidget,
      );
    });

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
      expect(find.text('Rule 1'), findsOneWidget);
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

      final editOption = find.text('Edit');
      await tester.tap(editOption);
      await tester.pumpAndSettle();

      expect(find.text('Edit Production Rule'), findsOneWidget);
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

      final editOption = find.text('Edit');
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

      final editOption = find.text('Edit');
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

      final editOption = find.text('Edit');
      await tester.tap(editOption);
      await tester.pumpAndSettle();

      expect(find.text('Edit Production Rule'), findsOneWidget);

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

      final editOption = find.text('Edit');
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

      final deleteOption = find.text('Delete');
      await tester.tap(deleteOption);
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

      final editOption = find.text('Edit');
      await tester.tap(editOption);
      await tester.pumpAndSettle();

      expect(find.text('Edit Production Rule'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      final deleteOption = find.text('Delete');
      await tester.tap(deleteOption);
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

      final editOption = find.text('Edit');
      await tester.tap(editOption);
      await tester.pumpAndSettle();

      expect(find.text('Edit Production Rule'), findsOneWidget);

      final clearButton = _findButtonWithText('Clear');
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      // Clear shouldn't happen until the confirmation is accepted.
      expect(find.text('Edit Production Rule'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Clear'));
      await tester.pumpAndSettle();

      expect(find.text('Add Production Rule'), findsOneWidget);
    });
  });

  group('GrammarEditor responsive layout', () {
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
