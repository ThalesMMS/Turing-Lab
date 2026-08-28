import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/regex_to_nfa_converter.dart';
import 'package:turing_lab/core/models/regex_to_nfa_step.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/algorithm_step_viewer.dart';

void main() {
  testWidgets('viewer resolves regex-to-NFA messages after JSON restoration', (
    tester,
  ) async {
    final conversion = RegexToNFAConverter.convertWithSteps('a');
    final typedStep = conversion.data!.steps.firstWhere(
      (step) => step.stepType == RegexToNFAStepType.basicSymbol,
    );
    final step = typedStep.baseStep.copyWith(
      properties: typedStep.toProperties(),
    );

    Future<void> pump(Locale locale) => tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(child: AlgorithmStepViewer(step: step)),
        ),
      ),
    );

    await pump(const Locale('en'));
    expect(find.text('Create an NFA for "a"'), findsOneWidget);
    expect(find.textContaining('Created a fragment'), findsOneWidget);
    expect(find.textContaining('regex.to-nfa.step.'), findsNothing);

    await pump(const Locale('pt'));
    await tester.pumpAndSettle();
    expect(find.text('Criar um AFN para "a"'), findsOneWidget);
    expect(find.textContaining('Foi criado um fragmento'), findsOneWidget);
    expect(find.textContaining('regex.to-nfa.step.'), findsNothing);
  });
}
