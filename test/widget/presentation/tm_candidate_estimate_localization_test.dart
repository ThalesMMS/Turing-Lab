import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/tm/tm_algorithm_execution_controller.dart';
import 'package:turing_lab/presentation/widgets/tm/tm_algorithm_inputs.dart';
import 'package:turing_lab/presentation/widgets/tm/tm_algorithm_language_controls.dart';
import 'package:turing_lab/presentation/widgets/tm/tm_algorithm_space_controls.dart';

void main() {
  for (final (locale, requested, scheduled) in [
    (const Locale('en'), '2,047', '1,500'),
    (const Locale('pt'), '2.047', '1.500'),
  ]) {
    testWidgets('localizes candidate estimates in $locale', (tester) async {
      final inputs = TMAlgorithmInputs();
      addTearDown(inputs.dispose);
      inputs.languageMaxLength.text = '10';
      inputs.spaceMaxLength.text = '10';
      inputs.languageCandidateCap.text = '1500';
      inputs.spaceCandidateCap.text = '1500';
      final tm = TM
          .empty(id: 'estimate', name: 'Estimate')
          .copyWith(alphabet: {'a', 'b'});
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  TMLanguageExplorerControls(
                    tm: tm,
                    inputs: inputs,
                    state: const TMAlgorithmAnalysisState(),
                    onInputsChanged: () {},
                  ),
                  TMSpaceProfilerControls(
                    tm: tm,
                    inputs: inputs,
                    state: const TMAlgorithmAnalysisState(),
                    onInputsChanged: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final strings = lookupAppLocalizations(locale);
      expect(
        tester
            .widget<Text>(
              find.byKey(const Key('tm-language-candidate-estimate')),
            )
            .data,
        strings.estimatedCandidatesScheduled(requested, scheduled),
      );
      expect(
        tester
            .widget<Text>(find.byKey(const Key('tm-space-candidate-estimate')))
            .data,
        strings.estimatedCandidatesScheduled(requested, requested),
      );
    });
  }
}
