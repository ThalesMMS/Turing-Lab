//
//  tm_canvas_graphview_test.dart
//  Turing Lab
//
//  Bateria de testes de widget que verifica o TMCanvasGraphView, assegurando
//  que o controlador GraphView de máquinas de Turing sincronize estados e
//  transições com o provider Riverpod durante interações típicas de edição.
//  As verificações incluem criação dinâmica de nós, adição de transições e
//  descarte apropriado do controlador ao término de cada cenário.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:turing_lab/features/canvas/graphview/graphview_tm_canvas_controller.dart';
import 'package:turing_lab/presentation/providers/tm_editor_provider.dart';
import 'package:turing_lab/presentation/widgets/tm_canvas_graphview.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TMCanvasGraphView', () {
    late TMEditorNotifier notifier;
    late GraphViewTmCanvasController controller;

    setUp(() {
      notifier = TMEditorNotifier();
      controller = GraphViewTmCanvasController(editorNotifier: notifier);
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('displays TM states and transitions', (tester) async {
      final delivered = <int>[];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [tmEditorProvider.overrideWith((ref) => notifier)],
          child: MaterialApp(
            home: Scaffold(
              body: TMCanvasGraphView(
                controller: controller,
                onTmModified: (tm) => delivered.add(tm.states.length),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      controller.addStateAt(const Offset(0, 0));
      controller.addStateAt(const Offset(140, 80));
      await tester.pumpAndSettle();

      expect(find.text('q0'), findsOneWidget);
      expect(find.text('q1'), findsOneWidget);

      final states = notifier.state.tm!.states.toList();
      controller.addOrUpdateTransition(
        fromStateId: states.first.id,
        toStateId: states.last.id,
        readSymbol: 'a',
        writeSymbol: 'b',
        direction: TapeDirection.right,
      );

      await tester.pumpAndSettle();

      // Transition labels are painted via CustomPainter, not rendered as
      // Text widgets. Verify the transition was added to the model instead.
      final transitions = notifier.state.tm!.transitions;
      expect(transitions, hasLength(1));
      expect(delivered, isNotEmpty);
    });
  });
}
