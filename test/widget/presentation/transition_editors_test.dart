//
//  transition_editors_test.dart
//  Turing Lab
//
//  Comprehensive tests for transition editors, covering PDA and Turing
//  machine forms plus generic label editors. Cases include text fields,
//  lambda toggles, direction selectors, keyboard shortcuts, and
//  submit/cancel callbacks for consistent, accessible editing.
//
//  Thales Matheus Mendonça Santos - December 2025
//

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/pda/stack_drawer.dart';
import 'package:turing_lab/presentation/widgets/pda/stack_operation_preview.dart';
import 'package:turing_lab/presentation/widgets/transition_editors/pda_transition_editor.dart';
import 'package:turing_lab/presentation/widgets/transition_editors/tm_transition_operations_editor.dart';
import 'package:turing_lab/presentation/widgets/transition_editors/transition_label_editor.dart';

part 'transition_label_editor_form_cases.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PdaTransitionEditor', () {
    testWidgets('renders with initial values', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdaTransitionEditor(
              initialRead: 'a',
              initialPop: 'Z',
              initialPush: 'AZ',
              isLambdaInput: false,
              isLambdaPop: false,
              isLambdaPush: false,
              onSubmit: ({
                required readSymbol,
                required popSymbol,
                required pushSymbol,
                required lambdaInput,
                required lambdaPop,
                required lambdaPush,
              }) {},
              onCancel: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('a'), findsOneWidget);
      expect(find.text('Z'), findsOneWidget);
      expect(find.text('AZ'), findsOneWidget);
    });

    testWidgets('localizes PDA fields, validation, and actions in Portuguese', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('pt'),
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: PdaTransitionEditor(
              initialRead: '',
              initialPop: '',
              initialPush: '',
              isLambdaInput: false,
              isLambdaPop: false,
              isLambdaPush: false,
              onSubmit: ({
                required readSymbol,
                required popSymbol,
                required pushSymbol,
                required lambdaInput,
                required lambdaPop,
                required lambdaPush,
              }) {},
              onCancel: () {},
              onDelete: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final label in <String>[
        'Símbolo de entrada',
        'λ-entrada',
        'Símbolo para desempilhar',
        'λ-desempilhar',
        'Símbolo para empilhar',
        'λ-empilhar',
        'Cancelar',
        'Excluir',
        'Salvar',
      ]) {
        expect(find.text(label), findsOneWidget);
      }

      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(
        find.text('Insira um símbolo ou ative λ-entrada'),
        findsOneWidget,
      );
      expect(
        find.text('Insira um símbolo ou ative λ-desempilhar'),
        findsOneWidget,
      );
      expect(
        find.text('Insira um símbolo ou ative λ-empilhar'),
        findsOneWidget,
      );
    });

    testWidgets('disables smart text features for PDA symbols', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdaTransitionEditor(
              initialRead: 'a',
              initialPop: 'Z',
              initialPush: 'AZ',
              isLambdaInput: false,
              isLambdaPop: false,
              isLambdaPush: false,
              onSubmit: ({
                required readSymbol,
                required popSymbol,
                required pushSymbol,
                required lambdaInput,
                required lambdaPop,
                required lambdaPush,
              }) {},
              onCancel: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      for (final field
          in tester.widgetList<TextField>(find.byType(TextField))) {
        expect(field.autocorrect, isFalse);
        expect(field.enableSuggestions, isFalse);
        expect(field.keyboardType, TextInputType.visiblePassword);
      }
    });

    testWidgets('calls onSubmit when save button is pressed', (tester) async {
      Map<String, dynamic>? submittedData;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdaTransitionEditor(
              initialRead: 'a',
              initialPop: 'Z',
              initialPush: 'AZ',
              isLambdaInput: false,
              isLambdaPop: false,
              isLambdaPush: false,
              onSubmit: ({
                required readSymbol,
                required popSymbol,
                required pushSymbol,
                required lambdaInput,
                required lambdaPop,
                required lambdaPush,
              }) {
                submittedData = {
                  'readSymbol': readSymbol,
                  'popSymbol': popSymbol,
                  'pushSymbol': pushSymbol,
                  'lambdaInput': lambdaInput,
                  'lambdaPop': lambdaPop,
                  'lambdaPush': lambdaPush,
                };
              },
              onCancel: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(submittedData, isNotNull);
      expect(submittedData!['readSymbol'], equals('a'));
      expect(submittedData!['popSymbol'], equals('Z'));
      expect(submittedData!['pushSymbol'], equals('AZ'));
      expect(submittedData!['lambdaInput'], isFalse);
      expect(submittedData!['lambdaPop'], isFalse);
      expect(submittedData!['lambdaPush'], isFalse);
    });

    testWidgets('rejects empty non-lambda symbols on save', (tester) async {
      var submitted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdaTransitionEditor(
              initialRead: '',
              initialPop: '',
              initialPush: '',
              isLambdaInput: false,
              isLambdaPop: false,
              isLambdaPush: false,
              onSubmit: ({
                required readSymbol,
                required popSymbol,
                required pushSymbol,
                required lambdaInput,
                required lambdaPop,
                required lambdaPush,
              }) {
                submitted = true;
              },
              onCancel: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(submitted, isFalse);
      expect(find.text('Enter a symbol or enable λ-input'), findsOneWidget);
      expect(find.text('Enter a symbol or enable λ-pop'), findsOneWidget);
      expect(find.text('Enter a symbol or enable λ-push'), findsOneWidget);
    });

    testWidgets('renders the supplied stack in the operation preview', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdaTransitionEditor(
              initialRead: 'a',
              initialPop: 'Z',
              initialPush: 'AZ',
              isLambdaInput: false,
              isLambdaPop: false,
              isLambdaPush: false,
              currentStack: const StackState(symbols: ['Z']),
              onSubmit: ({
                required readSymbol,
                required popSymbol,
                required pushSymbol,
                required lambdaInput,
                required lambdaPop,
                required lambdaPush,
              }) {},
              onCancel: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(StackOperationPreview), findsOneWidget);
      expect(find.text('Operation Preview'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('calls onCancel when cancel button is pressed', (tester) async {
      var cancelCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdaTransitionEditor(
              initialRead: 'a',
              initialPop: 'Z',
              initialPush: 'AZ',
              isLambdaInput: false,
              isLambdaPop: false,
              isLambdaPush: false,
              onSubmit: ({
                required readSymbol,
                required popSymbol,
                required pushSymbol,
                required lambdaInput,
                required lambdaPop,
                required lambdaPush,
              }) {},
              onCancel: () {
                cancelCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(cancelCalled, isTrue);
    });

    testWidgets('lambda input toggle clears read field and disables it', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdaTransitionEditor(
              initialRead: 'a',
              initialPop: 'Z',
              initialPush: 'AZ',
              isLambdaInput: false,
              isLambdaPop: false,
              isLambdaPush: false,
              onSubmit: ({
                required readSymbol,
                required popSymbol,
                required pushSymbol,
                required lambdaInput,
                required lambdaPop,
                required lambdaPush,
              }) {},
              onCancel: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final inputFieldFinder = find.widgetWithText(TextField, 'a');
      expect(inputFieldFinder, findsOneWidget);
      final inputField = tester.widget<TextField>(inputFieldFinder);
      expect(inputField.enabled, isTrue);

      await tester.tap(find.text('λ-input'));
      await tester.pumpAndSettle();

      final disabledInputFieldFinder = find.ancestor(
        of: find.text('Input symbol'),
        matching: find.byType(TextField),
      );
      expect(disabledInputFieldFinder, findsOneWidget);
      final disabledInputField = tester.widget<TextField>(
        disabledInputFieldFinder,
      );
      expect(disabledInputField.enabled, isFalse);
      expect(disabledInputField.controller?.text, isEmpty);
    });

    testWidgets('lambda pop toggle clears pop field and disables it', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdaTransitionEditor(
              initialRead: 'a',
              initialPop: 'Z',
              initialPush: 'AZ',
              isLambdaInput: false,
              isLambdaPop: false,
              isLambdaPush: false,
              onSubmit: ({
                required readSymbol,
                required popSymbol,
                required pushSymbol,
                required lambdaInput,
                required lambdaPop,
                required lambdaPush,
              }) {},
              onCancel: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('λ-pop'));
      await tester.pumpAndSettle();

      final disabledPopFieldFinder = find.ancestor(
        of: find.text('Pop symbol'),
        matching: find.byType(TextField),
      );
      expect(disabledPopFieldFinder, findsOneWidget);
      final disabledPopField = tester.widget<TextField>(disabledPopFieldFinder);
      expect(disabledPopField.enabled, isFalse);
      expect(disabledPopField.controller?.text, isEmpty);
    });

    testWidgets('lambda push toggle clears push field and disables it', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdaTransitionEditor(
              initialRead: 'a',
              initialPop: 'Z',
              initialPush: 'AZ',
              isLambdaInput: false,
              isLambdaPop: false,
              isLambdaPush: false,
              onSubmit: ({
                required readSymbol,
                required popSymbol,
                required pushSymbol,
                required lambdaInput,
                required lambdaPop,
                required lambdaPush,
              }) {},
              onCancel: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('λ-push'));
      await tester.pumpAndSettle();

      final disabledPushFieldFinder = find.ancestor(
        of: find.text('Push symbol'),
        matching: find.byType(TextField),
      );
      expect(disabledPushFieldFinder, findsOneWidget);
      final disabledPushField = tester.widget<TextField>(
        disabledPushFieldFinder,
      );
      expect(disabledPushField.enabled, isFalse);
      expect(disabledPushField.controller?.text, isEmpty);
    });

    testWidgets('submits with updated values after text input', (tester) async {
      Map<String, dynamic>? submittedData;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdaTransitionEditor(
              initialRead: 'a',
              initialPop: 'Z',
              initialPush: 'AZ',
              isLambdaInput: false,
              isLambdaPop: false,
              isLambdaPush: false,
              onSubmit: ({
                required readSymbol,
                required popSymbol,
                required pushSymbol,
                required lambdaInput,
                required lambdaPop,
                required lambdaPush,
              }) {
                submittedData = {
                  'readSymbol': readSymbol,
                  'popSymbol': popSymbol,
                  'pushSymbol': pushSymbol,
                  'lambdaInput': lambdaInput,
                  'lambdaPop': lambdaPop,
                  'lambdaPush': lambdaPush,
                };
              },
              onCancel: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final readFieldFinder = find.ancestor(
        of: find.text('Input symbol'),
        matching: find.byType(TextField),
      );
      await tester.enterText(readFieldFinder, 'b');
      await tester.pumpAndSettle();

      final popFieldFinder = find.ancestor(
        of: find.text('Pop symbol'),
        matching: find.byType(TextField),
      );
      await tester.enterText(popFieldFinder, 'X');
      await tester.pumpAndSettle();

      final pushFieldFinder = find.ancestor(
        of: find.text('Push symbol'),
        matching: find.byType(TextField),
      );
      await tester.enterText(pushFieldFinder, 'BX');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(submittedData, isNotNull);
      expect(submittedData!['readSymbol'], equals('b'));
      expect(submittedData!['popSymbol'], equals('X'));
      expect(submittedData!['pushSymbol'], equals('BX'));
    });

    testWidgets('submits on enter key in any field', (tester) async {
      Map<String, dynamic>? submittedData;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdaTransitionEditor(
              initialRead: 'a',
              initialPop: 'Z',
              initialPush: 'AZ',
              isLambdaInput: false,
              isLambdaPop: false,
              isLambdaPush: false,
              onSubmit: ({
                required readSymbol,
                required popSymbol,
                required pushSymbol,
                required lambdaInput,
                required lambdaPop,
                required lambdaPush,
              }) {
                submittedData = {
                  'readSymbol': readSymbol,
                  'popSymbol': popSymbol,
                  'pushSymbol': pushSymbol,
                };
              },
              onCancel: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(submittedData, isNotNull);
    });

    testWidgets('trims whitespace from input values', (tester) async {
      Map<String, dynamic>? submittedData;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdaTransitionEditor(
              initialRead: '',
              initialPop: '',
              initialPush: '',
              isLambdaInput: false,
              isLambdaPop: false,
              isLambdaPush: false,
              onSubmit: ({
                required readSymbol,
                required popSymbol,
                required pushSymbol,
                required lambdaInput,
                required lambdaPop,
                required lambdaPush,
              }) {
                submittedData = {
                  'readSymbol': readSymbol,
                  'popSymbol': popSymbol,
                  'pushSymbol': pushSymbol,
                };
              },
              onCancel: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final readFieldFinder = find.ancestor(
        of: find.text('Input symbol'),
        matching: find.byType(TextField),
      );
      await tester.enterText(readFieldFinder, '  a  ');
      await tester.pumpAndSettle();

      final popFieldFinder = find.ancestor(
        of: find.text('Pop symbol'),
        matching: find.byType(TextField),
      );
      await tester.enterText(popFieldFinder, '  Z  ');
      await tester.pumpAndSettle();

      final pushFieldFinder = find.ancestor(
        of: find.text('Push symbol'),
        matching: find.byType(TextField),
      );
      await tester.enterText(pushFieldFinder, '  AZ  ');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(submittedData!['readSymbol'], equals('a'));
      expect(submittedData!['popSymbol'], equals('Z'));
      expect(submittedData!['pushSymbol'], equals('AZ'));
    });

    testWidgets('cancels on escape key press', (tester) async {
      var cancelCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdaTransitionEditor(
              initialRead: 'a',
              initialPop: 'Z',
              initialPush: 'AZ',
              isLambdaInput: false,
              isLambdaPop: false,
              isLambdaPush: false,
              onSubmit: ({
                required readSymbol,
                required popSymbol,
                required pushSymbol,
                required lambdaInput,
                required lambdaPop,
                required lambdaPush,
              }) {},
              onCancel: () {
                cancelCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextField).first);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(cancelCalled, isTrue);
    });
  });

  group('TmTransitionOperationsEditor', () {
    testWidgets('renders with initial values', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TmTransitionOperationsEditor(
              initialRead: 'a',
              initialWrite: 'b',
              initialDirection: TapeDirection.right,
              onSubmit: ({
                required readSymbol,
                required writeSymbol,
                required direction,
              }) {},
              onCancel: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('a'), findsOneWidget);
      expect(find.text('b'), findsOneWidget);
    });

    testWidgets('localizes TM fields, validation, and actions in Portuguese', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TmTransitionOperationsEditor(
              initialRead: '',
              initialWrite: '',
              initialDirection: TapeDirection.right,
              onSubmit: ({
                required readSymbol,
                required writeSymbol,
                required direction,
              }) {},
              onCancel: () {},
              onDelete: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final label in <String>[
        'Símbolo lido',
        'Símbolo escrito',
        'Direção',
        'Cancelar',
        'Excluir',
        'Salvar',
      ]) {
        expect(find.text(label), findsOneWidget);
      }

      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(find.text('Insira um símbolo de leitura'), findsOneWidget);
      expect(find.text('Insira um símbolo de escrita'), findsOneWidget);
    });

    testWidgets('disables smart text features for TM symbols', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TmTransitionOperationsEditor(
              initialRead: 'a',
              initialWrite: 'b',
              initialDirection: TapeDirection.right,
              onSubmit: ({
                required readSymbol,
                required writeSymbol,
                required direction,
              }) {},
              onCancel: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      for (final field
          in tester.widgetList<TextField>(find.byType(TextField))) {
        expect(field.autocorrect, isFalse);
        expect(field.enableSuggestions, isFalse);
        expect(field.keyboardType, TextInputType.visiblePassword);
      }
    });

    testWidgets('calls onSubmit when save button is pressed', (tester) async {
      Map<String, dynamic>? submittedData;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TmTransitionOperationsEditor(
              initialRead: 'a',
              initialWrite: 'b',
              initialDirection: TapeDirection.right,
              onSubmit: ({
                required readSymbol,
                required writeSymbol,
                required direction,
              }) {
                submittedData = {
                  'readSymbol': readSymbol,
                  'writeSymbol': writeSymbol,
                  'direction': direction,
                };
              },
              onCancel: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(submittedData, isNotNull);
      expect(submittedData!['readSymbol'], equals('a'));
      expect(submittedData!['writeSymbol'], equals('b'));
      expect(submittedData!['direction'], equals(TapeDirection.right));
    });

    testWidgets('rejects empty read and write symbols on save', (tester) async {
      var submitted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TmTransitionOperationsEditor(
              initialRead: '',
              initialWrite: '',
              initialDirection: TapeDirection.right,
              onSubmit: ({
                required readSymbol,
                required writeSymbol,
                required direction,
              }) {
                submitted = true;
              },
              onCancel: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(submitted, isFalse);
      expect(find.text('Enter a read symbol'), findsOneWidget);
      expect(find.text('Enter a write symbol'), findsOneWidget);
    });

    testWidgets('calls onCancel when cancel button is pressed', (tester) async {
      var cancelCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TmTransitionOperationsEditor(
              initialRead: 'a',
              initialWrite: 'b',
              initialDirection: TapeDirection.right,
              onSubmit: ({
                required readSymbol,
                required writeSymbol,
                required direction,
              }) {},
              onCancel: () {
                cancelCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(cancelCalled, isTrue);
    });

    testWidgets('updates direction via dropdown', (tester) async {
      Map<String, dynamic>? submittedData;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TmTransitionOperationsEditor(
              initialRead: 'a',
              initialWrite: 'b',
              initialDirection: TapeDirection.right,
              onSubmit: ({
                required readSymbol,
                required writeSymbol,
                required direction,
              }) {
                submittedData = {'direction': direction};
              },
              onCancel: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButton<TapeDirection>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Left (L)').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(submittedData, isNotNull);
      expect(submittedData!['direction'], equals(TapeDirection.left));
    });

    testWidgets('submits with updated text values', (tester) async {
      Map<String, dynamic>? submittedData;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TmTransitionOperationsEditor(
              initialRead: 'a',
              initialWrite: 'b',
              initialDirection: TapeDirection.right,
              onSubmit: ({
                required readSymbol,
                required writeSymbol,
                required direction,
              }) {
                submittedData = {
                  'readSymbol': readSymbol,
                  'writeSymbol': writeSymbol,
                };
              },
              onCancel: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final readFieldFinder = find.ancestor(
        of: find.text('Read symbol'),
        matching: find.byType(TextField),
      );
      await tester.enterText(readFieldFinder, 'x');
      await tester.pumpAndSettle();

      final writeFieldFinder = find.ancestor(
        of: find.text('Write symbol'),
        matching: find.byType(TextField),
      );
      await tester.enterText(writeFieldFinder, 'y');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(submittedData!['readSymbol'], equals('x'));
      expect(submittedData!['writeSymbol'], equals('y'));
    });

    testWidgets('trims whitespace from input values', (tester) async {
      Map<String, dynamic>? submittedData;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TmTransitionOperationsEditor(
              initialRead: '',
              initialWrite: '',
              initialDirection: TapeDirection.right,
              onSubmit: ({
                required readSymbol,
                required writeSymbol,
                required direction,
              }) {
                submittedData = {
                  'readSymbol': readSymbol,
                  'writeSymbol': writeSymbol,
                };
              },
              onCancel: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final readFieldFinder = find.ancestor(
        of: find.text('Read symbol'),
        matching: find.byType(TextField),
      );
      await tester.enterText(readFieldFinder, '  x  ');
      await tester.pumpAndSettle();

      final writeFieldFinder = find.ancestor(
        of: find.text('Write symbol'),
        matching: find.byType(TextField),
      );
      await tester.enterText(writeFieldFinder, '  y  ');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(submittedData!['readSymbol'], equals('x'));
      expect(submittedData!['writeSymbol'], equals('y'));
    });

    testWidgets('next advances focus and hardware enter submits',
        (tester) async {
      var submitCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TmTransitionOperationsEditor(
              initialRead: 'a',
              initialWrite: 'b',
              initialDirection: TapeDirection.right,
              onSubmit: ({
                required readSymbol,
                required writeSymbol,
                required direction,
              }) {
                submitCalled = true;
              },
              onCancel: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextField, 'Read symbol'));
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();

      expect(submitCalled, isFalse);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(submitCalled, isTrue);
    });

    testWidgets('cancels on escape key press', (tester) async {
      var cancelCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TmTransitionOperationsEditor(
              initialRead: 'a',
              initialWrite: 'b',
              initialDirection: TapeDirection.right,
              onSubmit: ({
                required readSymbol,
                required writeSymbol,
                required direction,
              }) {},
              onCancel: () {
                cancelCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextField).first);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(cancelCalled, isTrue);
    });

    testWidgets('reacts to a narrow viewport while already open', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 700);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TmTransitionOperationsEditor(
                initialRead: 'a',
                initialWrite: 'b',
                initialDirection: TapeDirection.right,
                onSubmit: ({
                  required readSymbol,
                  required writeSymbol,
                  required direction,
                }) {},
                onCancel: () {},
                onDelete: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final editor = find.byType(TmTransitionOperationsEditor);
      expect(tester.getSize(editor).width, 360);

      tester.view.physicalSize = const Size(320, 700);
      await tester.pumpAndSettle();

      final editorBounds = tester.getRect(editor);
      expect(editorBounds.width, 296);
      expect(editorBounds.left, greaterThanOrEqualTo(12));
      expect(editorBounds.right, lessThanOrEqualTo(308));

      final actionButtons = [
        find.widgetWithText(OutlinedButton, 'Cancel'),
        find.widgetWithText(OutlinedButton, 'Delete'),
        find.widgetWithText(FilledButton, 'Save'),
      ];
      for (final button in actionButtons) {
        expect(button, findsOneWidget);
        final bounds = tester.getRect(button);
        expect(bounds.left, greaterThanOrEqualTo(12));
        expect(bounds.right, lessThanOrEqualTo(308));
        expect(bounds.height, greaterThanOrEqualTo(48));
      }
    });
  });

  _registerTransitionLabelEditorFormTests();
}
