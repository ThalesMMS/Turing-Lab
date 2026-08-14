//
//  transition_editors_test.dart
//  Turing Lab
//
//  Suite abrangente de testes para editores de transições, validando
//  comportamento de formulários PDA, Turing Machine e editores genéricos de
//  rótulos. Verifica interações com campos de texto, toggles lambda, seletores
//  de direção, atalhos de teclado e callbacks de submissão/cancelamento,
//  garantindo consistência e acessibilidade em todos os cenários de edição.
//
//  Thales Matheus Mendonça Santos - December 2025
//

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/core/models/tm_transition.dart';
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

    testWidgets('submits on enter key in text fields', (tester) async {
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

      await tester.testTextInput.receiveAction(TextInputAction.done);
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
  });

  _registerTransitionLabelEditorFormTests();
}
