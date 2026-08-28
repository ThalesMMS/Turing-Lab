import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/fsa_concatenation_messages.dart';
import 'package:turing_lab/core/algorithms/fsa_reverser_messages.dart';
import 'package:turing_lab/core/models/algorithm_step.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/algorithm_step_viewer.dart';

void main() {
  testWidgets('renders localized FSA reversal step data', (tester) async {
    final step = AlgorithmStep(
      id: 'reversal-localized-step',
      stepNumber: 0,
      title: 'legacy reversal title',
      explanation: 'legacy reversal explanation',
      type: AlgorithmType.fsaReversal,
      properties: {
        fsaReversalTitleMessageProperty: FsaReversalMessages.stepTitle(
          'reverse',
        ).toJson(),
        fsaReversalExplanationMessageProperty:
            FsaReversalMessages.reverseExplanation().toJson(),
      },
    );

    await tester.pumpWidget(_localizedViewer(step));
    await tester.pumpAndSettle();

    expect(find.text('Inverter cada transição'), findsOneWidget);
    expect(
      find.text(
        'Troque a origem e o destino de cada transição de símbolo e epsilon.',
      ),
      findsOneWidget,
    );
    expect(find.text('legacy reversal title'), findsNothing);
  });

  testWidgets('renders localized FSA concatenation operand step data', (
    tester,
  ) async {
    final step = AlgorithmStep(
      id: 'concatenation-localized-step',
      stepNumber: 0,
      title: 'legacy concatenation title',
      explanation: 'legacy concatenation explanation',
      type: AlgorithmType.fsaConcatenation,
      properties: {
        fsaConcatenationTitleMessageProperty:
            FsaConcatenationMessages.cloneTitle('left').toJson(),
        fsaConcatenationExplanationMessageProperty:
            FsaConcatenationMessages.cloneExplanation('left').toJson(),
      },
    );

    await tester.pumpWidget(_localizedViewer(step));
    await tester.pumpAndSettle();

    expect(find.text('Clonar o operando esquerdo'), findsOneWidget);
    expect(
      find.text(
        'Copie cada estado do operando esquerdo para um namespace de IDs separado.',
      ),
      findsOneWidget,
    );
    expect(find.text('legacy concatenation title'), findsNothing);
  });
}

Widget _localizedViewer(AlgorithmStep step) {
  return MaterialApp(
    locale: const Locale('pt', 'BR'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SingleChildScrollView(child: AlgorithmStepViewer(step: step)),
    ),
  );
}
