//
//  pda_canvas_graphview_test.dart
//  Turing Lab
//
//  Suite de testes de widget dedicada ao PDACanvasGraphView, certificando que o
//  controlador GraphView de autômatos de pilha sincronize estados, transições e
//  callbacks com o provider durante interações de edição. Os cenários incluem
//  criação incremental de nós, atualização de transições com símbolos de pilha e
//  descarte correto de recursos após cada execução.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:turing_lab/presentation/providers/pda_editor_provider.dart';
import 'package:turing_lab/presentation/widgets/pda_canvas_graphview.dart';
import 'package:turing_lab/features/canvas/graphview/graphview_pda_canvas_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PDACanvasGraphView', () {
    late PDAEditorNotifier notifier;
    late GraphViewPdaCanvasController controller;

    setUp(() {
      notifier = PDAEditorNotifier();
      controller = GraphViewPdaCanvasController(editorNotifier: notifier);
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('renders states and transitions from controller', (
      tester,
    ) async {
      final delivered = <int>[];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [pdaEditorProvider.overrideWith((ref) => notifier)],
          child: MaterialApp(
            home: Scaffold(
              body: PDACanvasGraphView(
                controller: controller,
                onPdaModified: (pda) => delivered.add(pda.states.length),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(delivered, isEmpty);

      controller.addStateAt(const Offset(0, 0));
      await tester.pumpAndSettle();

      expect(find.text('q0'), findsOneWidget);
      expect(delivered, isNotEmpty);

      controller.addStateAt(const Offset(120, 80));
      await tester.pumpAndSettle();

      final states = notifier.state.pda!.states.toList();
      controller.addOrUpdateTransition(
        fromStateId: states.first.id,
        toStateId: states.last.id,
        readSymbol: 'a',
        popSymbol: 'Z',
        pushSymbol: 'AZ',
        isLambdaInput: false,
        isLambdaPop: false,
        isLambdaPush: false,
      );

      await tester.pumpAndSettle();

      // Transition labels are painted via CustomPainter, not rendered as
      // Text widgets. Verify the transition was added to the model instead.
      final transitions = notifier.state.pda!.transitions;
      expect(transitions, hasLength(1));
    });
  });
}
