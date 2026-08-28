import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/fsa_kleene_star_messages.dart';
import 'package:turing_lab/core/models/algorithm_step.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/algorithm_step_viewer.dart';

void main() {
  testWidgets('renders a localized Kleene-star construction step', (
    tester,
  ) async {
    final title = FsaKleeneStarMessages.stepTitle('clone');
    final explanation = FsaKleeneStarMessages.cloneExplanation();
    final step = AlgorithmStep(
      id: 'fsa-star-localized-step',
      stepNumber: 0,
      title: title.stableCode,
      explanation: explanation.stableCode,
      type: AlgorithmType.fsaKleeneStar,
      properties: {
        fsaKleeneStarTitleMessageProperty: title.toJson(),
        fsaKleeneStarExplanationMessageProperty: explanation.toJson(),
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(child: AlgorithmStepViewer(step: step)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Clonar o operando'), findsOneWidget);
    expect(
      find.text(
        'Copie cada estado do operando para um namespace de IDs separado e determinístico.',
      ),
      findsOneWidget,
    );
    expect(find.text('automaton.fsa-kleene-star.clone-title'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
