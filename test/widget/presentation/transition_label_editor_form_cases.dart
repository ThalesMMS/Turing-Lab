part of 'transition_editors_test.dart';

void _registerTransitionLabelEditorFormTests() {
  group('TransitionLabelEditorForm', () {
    testWidgets('renders with initial value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransitionLabelEditorForm(
              initialValue: 'a,b',
              onSubmit: (_) {},
              onCancel: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('a,b'), findsOneWidget);
    });

    testWidgets('localizes default labels and semantics in Portuguese', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('pt'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: TransitionLabelEditorForm(
                initialValue: 'a',
                onSubmit: (_) {},
                onCancel: () {},
                onDelete: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Rótulo'), findsOneWidget);
        expect(find.text('Cancelar'), findsOneWidget);
        expect(find.text('Excluir'), findsOneWidget);
        expect(find.text('Salvar'), findsOneWidget);
        expect(
          find.bySemanticsLabel('Editar rótulo da transição'),
          findsOneWidget,
        );
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('disables smart text features for formal labels', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransitionLabelEditorForm(
              initialValue: 'a,b',
              onSubmit: (_) {},
              onCancel: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField));

      expect(field.autocorrect, isFalse);
      expect(field.enableSuggestions, isFalse);
      expect(field.keyboardType, TextInputType.visiblePassword);
    });

    testWidgets('calls onSubmit when save button is pressed', (tester) async {
      String? submittedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransitionLabelEditorForm(
              initialValue: 'a,b',
              onSubmit: (value) {
                submittedValue = value;
              },
              onCancel: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(submittedValue, equals('a,b'));
    });

    testWidgets('calls onCancel when cancel button is pressed', (tester) async {
      var cancelCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransitionLabelEditorForm(
              initialValue: 'a,b',
              onSubmit: (_) {},
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

    testWidgets('submits with updated value after text input', (tester) async {
      String? submittedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransitionLabelEditorForm(
              initialValue: 'a,b',
              onSubmit: (value) {
                submittedValue = value;
              },
              onCancel: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'x,y,z');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(submittedValue, equals('x,y,z'));
    });

    testWidgets('trims whitespace from submitted value', (tester) async {
      String? submittedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransitionLabelEditorForm(
              initialValue: '',
              onSubmit: (value) {
                submittedValue = value;
              },
              onCancel: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '  a,b  ');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(submittedValue, equals('a,b'));
    });

    testWidgets('submits on enter key press', (tester) async {
      String? submittedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransitionLabelEditorForm(
              initialValue: 'a,b',
              onSubmit: (value) {
                submittedValue = value;
              },
              onCancel: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(submittedValue, equals('a,b'));
    });

    testWidgets('cancels on escape key press', (tester) async {
      var cancelCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransitionLabelEditorForm(
              initialValue: 'a,b',
              onSubmit: (_) {},
              onCancel: () {
                cancelCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(cancelCalled, isTrue);
    });

    testWidgets('renders with custom labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransitionLabelEditorForm(
              initialValue: 'test',
              onSubmit: (_) {},
              onCancel: () {},
              fieldLabel: 'Custom Field',
              cancelLabel: 'Dismiss',
              saveLabel: 'Apply',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Custom Field'), findsOneWidget);
      expect(find.text('Dismiss'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);
    });

    testWidgets('renders touch-optimized buttons when enabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransitionLabelEditorForm(
              initialValue: 'test',
              onSubmit: (_) {},
              onCancel: () {},
              touchOptimized: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final outlinedButton = find.byType(OutlinedButton);
      expect(outlinedButton, findsOneWidget);

      final filledButton = find.byType(FilledButton);
      expect(filledButton, findsOneWidget);
      expect(tester.getSize(outlinedButton).height, greaterThanOrEqualTo(44));
      expect(tester.getSize(filledButton).height, greaterThanOrEqualTo(44));
    });

    testWidgets('stacks transition actions in a narrow layout', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 280,
              child: TransitionLabelEditorForm(
                initialValue: 'test',
                onSubmit: (_) {},
                onCancel: () {},
                onDelete: () {},
                touchOptimized: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cancelBounds = tester.getRect(
        find.widgetWithText(OutlinedButton, 'Cancel'),
      );
      final deleteBounds = tester.getRect(
        find.widgetWithText(OutlinedButton, 'Delete'),
      );
      final saveBounds = tester.getRect(
        find.widgetWithText(FilledButton, 'Save'),
      );

      expect(cancelBounds.bottom, lessThan(deleteBounds.top));
      expect(deleteBounds.bottom, lessThan(saveBounds.top));
    });

    testWidgets('keeps accessible actions when touch spacing is disabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransitionLabelEditorForm(
              initialValue: 'test',
              onSubmit: (_) {},
              onCancel: () {},
              touchOptimized: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final outlinedButton = find.byType(OutlinedButton);
      expect(outlinedButton, findsOneWidget);

      final filledButton = find.byType(FilledButton);
      expect(filledButton, findsOneWidget);
      expect(tester.getSize(outlinedButton).height, greaterThanOrEqualTo(44));
      expect(tester.getSize(filledButton).height, greaterThanOrEqualTo(44));
    });

    testWidgets('renders delete action when delete callback is provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransitionLabelEditorForm(
              initialValue: 'test',
              onSubmit: (_) {},
              onCancel: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('calls onDelete when delete button is pressed', (tester) async {
      var deleteCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransitionLabelEditorForm(
              initialValue: 'test',
              onSubmit: (_) {},
              onCancel: () {},
              onDelete: () {
                deleteCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(deleteCalled, isTrue);
    });

    testWidgets('autofocuses text field when enabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransitionLabelEditorForm(
              initialValue: 'test',
              onSubmit: (_) {},
              onCancel: () {},
              autofocus: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.autofocus, isTrue);
    });

    testWidgets('submits on numpad enter key press', (tester) async {
      String? submittedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransitionLabelEditorForm(
              initialValue: 'test',
              onSubmit: (value) {
                submittedValue = value;
              },
              onCancel: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.numpadEnter);
      await tester.pumpAndSettle();

      expect(submittedValue, equals('test'));
    });
  });
}
