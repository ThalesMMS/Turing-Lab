//
//  transition_editor_goldens_test.dart
//  Turing Lab
//
//  Testes golden de regressão visual para editores de transições (PDA, TM, e
//  genérico), capturando snapshots de estados críticos: valores iniciais,
//  toggles lambda ativados/desativados, diferentes direções de fita, modos
//  touch-optimized. Garante consistência visual dos formulários de edição entre
//  mudanças e detecta regressões automáticas.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:turing_lab/presentation/widgets/transition_editors/pda_transition_editor.dart';
import 'package:turing_lab/presentation/widgets/transition_editors/tm_transition_operations_editor.dart';
import 'package:turing_lab/presentation/widgets/transition_editors/transition_label_editor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PdaTransitionEditor golden tests', () {
    testGoldens('renders with initial values', (tester) async {
      await tester.pumpWidgetBuilder(
        PdaTransitionEditor(
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
        surfaceSize: const Size(400, 600),
      );

      await screenMatchesGolden(tester, 'pda_editor_initial_values');
    });

    testGoldens('renders with empty values', (tester) async {
      await tester.pumpWidgetBuilder(
        PdaTransitionEditor(
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
        ),
        surfaceSize: const Size(400, 600),
      );

      await screenMatchesGolden(tester, 'pda_editor_empty_values');
    });

    testGoldens('renders with lambda input enabled', (tester) async {
      await tester.pumpWidgetBuilder(
        PdaTransitionEditor(
          initialRead: '',
          initialPop: 'Z',
          initialPush: 'AZ',
          isLambdaInput: true,
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
        surfaceSize: const Size(400, 600),
      );

      await screenMatchesGolden(tester, 'pda_editor_lambda_input');
    });

    testGoldens('renders with lambda pop enabled', (tester) async {
      await tester.pumpWidgetBuilder(
        PdaTransitionEditor(
          initialRead: 'a',
          initialPop: '',
          initialPush: 'AZ',
          isLambdaInput: false,
          isLambdaPop: true,
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
        surfaceSize: const Size(400, 600),
      );

      await screenMatchesGolden(tester, 'pda_editor_lambda_pop');
    });

    testGoldens('renders with lambda push enabled', (tester) async {
      await tester.pumpWidgetBuilder(
        PdaTransitionEditor(
          initialRead: 'a',
          initialPop: 'Z',
          initialPush: '',
          isLambdaInput: false,
          isLambdaPop: false,
          isLambdaPush: true,
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
        surfaceSize: const Size(400, 600),
      );

      await screenMatchesGolden(tester, 'pda_editor_lambda_push');
    });

    testGoldens('renders with all lambdas enabled', (tester) async {
      await tester.pumpWidgetBuilder(
        PdaTransitionEditor(
          initialRead: '',
          initialPop: '',
          initialPush: '',
          isLambdaInput: true,
          isLambdaPop: true,
          isLambdaPush: true,
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
        surfaceSize: const Size(400, 600),
      );

      await screenMatchesGolden(tester, 'pda_editor_all_lambda');
    });

    testGoldens('renders with complex push sequence', (tester) async {
      await tester.pumpWidgetBuilder(
        PdaTransitionEditor(
          initialRead: 'a',
          initialPop: 'Z',
          initialPush: 'XYZ',
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
        surfaceSize: const Size(400, 600),
      );

      await screenMatchesGolden(tester, 'pda_editor_complex_push');
    });
  });

  group('TmTransitionOperationsEditor golden tests', () {
    testGoldens('renders with initial values and right direction', (
      tester,
    ) async {
      await tester.pumpWidgetBuilder(
        TmTransitionOperationsEditor(
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
        surfaceSize: const Size(400, 600),
      );

      await screenMatchesGolden(tester, 'tm_editor_right_direction');
    });

    testGoldens('renders with left direction', (tester) async {
      await tester.pumpWidgetBuilder(
        TmTransitionOperationsEditor(
          initialRead: 'x',
          initialWrite: 'y',
          initialDirection: TapeDirection.left,
          onSubmit: ({
            required readSymbol,
            required writeSymbol,
            required direction,
          }) {},
          onCancel: () {},
        ),
        surfaceSize: const Size(400, 600),
      );

      await screenMatchesGolden(tester, 'tm_editor_left_direction');
    });

    testGoldens('renders with stay direction', (tester) async {
      await tester.pumpWidgetBuilder(
        TmTransitionOperationsEditor(
          initialRead: '0',
          initialWrite: '1',
          initialDirection: TapeDirection.stay,
          onSubmit: ({
            required readSymbol,
            required writeSymbol,
            required direction,
          }) {},
          onCancel: () {},
        ),
        surfaceSize: const Size(400, 600),
      );

      await screenMatchesGolden(tester, 'tm_editor_stay_direction');
    });

    testGoldens('renders with empty values', (tester) async {
      await tester.pumpWidgetBuilder(
        TmTransitionOperationsEditor(
          initialRead: '',
          initialWrite: '',
          initialDirection: TapeDirection.right,
          onSubmit: ({
            required readSymbol,
            required writeSymbol,
            required direction,
          }) {},
          onCancel: () {},
        ),
        surfaceSize: const Size(400, 600),
      );

      await screenMatchesGolden(tester, 'tm_editor_empty_values');
    });

    testGoldens('renders with blank symbol', (tester) async {
      await tester.pumpWidgetBuilder(
        TmTransitionOperationsEditor(
          initialRead: '_',
          initialWrite: '_',
          initialDirection: TapeDirection.right,
          onSubmit: ({
            required readSymbol,
            required writeSymbol,
            required direction,
          }) {},
          onCancel: () {},
        ),
        surfaceSize: const Size(400, 600),
      );

      await screenMatchesGolden(tester, 'tm_editor_blank_symbol');
    });

    testGoldens('renders with multi-character symbols', (tester) async {
      await tester.pumpWidgetBuilder(
        TmTransitionOperationsEditor(
          initialRead: 'abc',
          initialWrite: 'xyz',
          initialDirection: TapeDirection.left,
          onSubmit: ({
            required readSymbol,
            required writeSymbol,
            required direction,
          }) {},
          onCancel: () {},
        ),
        surfaceSize: const Size(400, 600),
      );

      await screenMatchesGolden(tester, 'tm_editor_multi_char');
    });
  });

  group('TransitionLabelEditorForm golden tests', () {
    testGoldens('renders with initial value', (tester) async {
      await tester.pumpWidgetBuilder(
        TransitionLabelEditorForm(
          initialValue: 'a,b',
          onSubmit: (_) {},
          onCancel: () {},
        ),
        surfaceSize: const Size(400, 300),
      );

      await screenMatchesGolden(tester, 'label_editor_initial_value');
    });

    testGoldens('renders with empty value', (tester) async {
      await tester.pumpWidgetBuilder(
        TransitionLabelEditorForm(
          initialValue: '',
          onSubmit: (_) {},
          onCancel: () {},
        ),
        surfaceSize: const Size(400, 300),
      );

      await screenMatchesGolden(tester, 'label_editor_empty_value');
    });

    testGoldens('renders with multiple symbols', (tester) async {
      await tester.pumpWidgetBuilder(
        TransitionLabelEditorForm(
          initialValue: 'a,b,c,d',
          onSubmit: (_) {},
          onCancel: () {},
        ),
        surfaceSize: const Size(400, 300),
      );

      await screenMatchesGolden(tester, 'label_editor_multiple_symbols');
    });

    testGoldens('renders with custom labels', (tester) async {
      await tester.pumpWidgetBuilder(
        TransitionLabelEditorForm(
          initialValue: 'test',
          onSubmit: (_) {},
          onCancel: () {},
          fieldLabel: 'Custom Field',
          cancelLabel: 'Dismiss',
          saveLabel: 'Apply',
        ),
        surfaceSize: const Size(400, 300),
      );

      await screenMatchesGolden(tester, 'label_editor_custom_labels');
    });

    testGoldens('renders in touch-optimized mode', (tester) async {
      await tester.pumpWidgetBuilder(
        TransitionLabelEditorForm(
          initialValue: 'a,b',
          onSubmit: (_) {},
          onCancel: () {},
          touchOptimized: true,
        ),
        surfaceSize: const Size(400, 300),
      );

      await screenMatchesGolden(tester, 'label_editor_touch_optimized');
    });

    testGoldens('renders standard mode', (tester) async {
      await tester.pumpWidgetBuilder(
        TransitionLabelEditorForm(
          initialValue: 'x,y,z',
          onSubmit: (_) {},
          onCancel: () {},
          touchOptimized: false,
        ),
        surfaceSize: const Size(400, 300),
      );

      await screenMatchesGolden(tester, 'label_editor_standard_mode');
    });

    testGoldens('renders with lambda symbol', (tester) async {
      await tester.pumpWidgetBuilder(
        TransitionLabelEditorForm(
          initialValue: 'λ',
          onSubmit: (_) {},
          onCancel: () {},
        ),
        surfaceSize: const Size(400, 300),
      );

      await screenMatchesGolden(tester, 'label_editor_lambda_symbol');
    });

    testGoldens('renders with long input', (tester) async {
      await tester.pumpWidgetBuilder(
        TransitionLabelEditorForm(
          initialValue: 'a,b,c,d,e,f,g,h,i,j,k,l',
          onSubmit: (_) {},
          onCancel: () {},
        ),
        surfaceSize: const Size(400, 300),
      );

      await screenMatchesGolden(tester, 'label_editor_long_input');
    });
  });
}
