//
//  graphview_label_field_editor_test.dart
//  Turing Lab
//
//  Testes de widget que avaliam o editor inline de rótulos do GraphView,
//  garantindo que submissões por teclado e cancelamentos preservem os valores
//  esperados. As provas verificam interação com mudança de foco, teclas Enter e
//  Escape, além de assegurar que callbacks fornecidos sejam acionados conforme o
//  contrato do componente.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/features/canvas/graphview/graphview_label_field_editor.dart';

void main() {
  testWidgets('GraphViewLabelFieldEditor submits value on Enter', (
    tester,
  ) async {
    String? submitted;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GraphViewLabelFieldEditor(
            initialValue: 'q0',
            onSubmit: (value) => submitted = value,
            onCancel: () {},
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.enterText(find.byType(TextField), 'q1');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(submitted, 'q1');
  });

  testWidgets('GraphViewLabelFieldEditor cancels on Escape', (tester) async {
    var canceled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GraphViewLabelFieldEditor(
            initialValue: 'q0',
            onSubmit: (_) {},
            onCancel: () => canceled = true,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.enterText(find.byType(TextField), 'q2');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(canceled, isTrue);
  });

  testWidgets('GraphViewLabelFieldEditor stays open when focus is lost', (
    tester,
  ) async {
    var canceled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              GraphViewLabelFieldEditor(
                initialValue: 'q0',
                onSubmit: (_) {},
                onCancel: () => canceled = true,
              ),
              const TextField(key: Key('other')),
            ],
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.tap(find.byKey(const Key('other')));
    await tester.pump();

    expect(canceled, isFalse);
    expect(find.byType(GraphViewLabelFieldEditor), findsOneWidget);
  });

  testWidgets('GraphViewLabelFieldEditor triggers delete without canceling', (
    tester,
  ) async {
    var canceled = false;
    var deleted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GraphViewLabelFieldEditor(
            initialValue: 'q0',
            onSubmit: (_) {},
            onCancel: () => canceled = true,
            onDelete: () => deleted = true,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(deleted, isTrue);
    expect(canceled, isFalse);
  });
}
