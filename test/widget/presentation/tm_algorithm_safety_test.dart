import 'package:vector_math/vector_math_64.dart' show Vector2;
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:turing_lab/presentation/widgets/tm/tm_algorithm_runner.dart';
import 'package:flutter/material.dart' hide State;
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/tm_acceptance.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/tm/tm_algorithm_execution_controller.dart';
import 'package:turing_lab/presentation/widgets/tm/tm_algorithm_inputs.dart';
import 'package:turing_lab/presentation/widgets/tm/tm_algorithm_language_controls.dart';
import 'package:turing_lab/presentation/widgets/tm/tm_algorithm_space_controls.dart';

void main() {
  test('analyzer callback failure ends the active request', () async {
    final q = State(
      id: 'q',
      label: 'q',
      position: Vector2.zero(),
      isInitial: true,
    );
    final tm = TM
        .empty(id: 'moving', name: 'Moving')
        .copyWith(
          states: {q},
          initialState: q,
          transitions: {
            TMTransition(
              id: 'move',
              fromState: q,
              toState: q,
              label: 'B/B,R',
              readSymbol: 'B',
              writeSymbol: 'B',
              direction: TapeDirection.right,
            ),
          },
        );
    final controller = TMAlgorithmExecutionController(
      initialTm: tm,
      highlights: null,
    );
    final inputs = TMAlgorithmInputs();
    addTearDown(controller.dispose);
    addTearDown(inputs.dispose);
    await TMAlgorithmRunner(execution: controller, inputs: inputs).run(
      TMAnalysisFocus.termination,
      tm,
      missingMachineMessage: 'Missing',
      progressLabel: (_, _) => throw StateError('progress failed'),
    );
    expect(controller.state.isAnalyzing, isFalse);
    expect(controller.state.currentError, 'Simulation failed');
  });

  test('changing acceptance policy invalidates an active analysis', () {
    final tm = TM.empty(id: 'safety', name: 'Safety');
    final controller = TMAlgorithmExecutionController(
      initialTm: tm,
      highlights: null,
    );
    addTearDown(controller.dispose);
    final request = controller.begin(TMAnalysisFocus.termination);
    expect(
      controller.observeMachine(
        tm.copyWith(acceptancePolicy: TMAcceptancePolicy.halting),
      ),
      isTrue,
    );
    expect(controller.isCurrent(request), isFalse);
    expect(controller.state.isAnalyzing, isFalse);
  });

  test('all panel bounds reject values outside the shared limits', () {
    final inputs = TMAlgorithmInputs();
    addTearDown(inputs.dispose);
    for (final value in ['-1', '21', '2147483647']) {
      inputs.languageMaxLength.text = value;
      inputs.spaceMaxLength.text = value;
      inputs.profileMaxLength.text = value;
      expect(inputs.languageLimits, isNull);
      expect(inputs.spaceLimits, isNull);
      expect(inputs.timeBounds, isNull);
    }
    inputs.languageMaxLength.text = ' 2 ';
    inputs.spaceMaxLength.text = ' 2 ';
    inputs.profileMaxLength.text = ' 2 ';
    expect(inputs.languageLimits!.maxInputLength, 2);
    expect(inputs.spaceLimits!.maxInputLength, 2);
    expect(inputs.timeBounds!.maxLength, 2);
    inputs.profileCandidateCap.text = '10001';
    expect(inputs.timeBounds, isNull);
  });

  for (final language in [true, false]) {
    testWidgets(
      'invalid ${language ? 'language' : 'space'} length does not enumerate during build',
      (tester) async {
        final inputs = TMAlgorithmInputs();
        addTearDown(inputs.dispose);
        inputs.languageMaxLength.text = '2147483647';
        inputs.spaceMaxLength.text = '2147483647';
        final tm = TM
            .empty(id: 'safety', name: 'Safety')
            .copyWith(alphabet: {'a', 'b'});
        final controller = TMAlgorithmExecutionController(
          initialTm: tm,
          highlights: null,
        );
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: language
                    ? TMLanguageExplorerControls(
                        tm: tm,
                        inputs: inputs,
                        state: controller.state,
                        onInputsChanged: () {},
                      )
                    : TMSpaceProfilerControls(
                        tm: tm,
                        inputs: inputs,
                        state: controller.state,
                        onInputsChanged: () {},
                      ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
