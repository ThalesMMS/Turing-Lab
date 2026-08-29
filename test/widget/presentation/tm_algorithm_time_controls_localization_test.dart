import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/localization/locale_value_formatter.dart';
import 'package:turing_lab/presentation/widgets/tm_algorithm_execution_controller.dart';
import 'package:turing_lab/presentation/widgets/tm_algorithm_inputs.dart';
import 'package:turing_lab/presentation/widgets/tm_algorithm_time_controls.dart';

// feature-localization-contract: grammar-analysis-parsing-and-teaching
// feature-localization-surface: responsive-accessibility
void main() {
  for (final scenario in const [
    (locale: Locale('en'), sampled: 'sampled', exhaustive: 'exhaustive'),
    (locale: Locale('pt', 'BR'), sampled: 'amostrado', exhaustive: 'exaustivo'),
  ]) {
    testWidgets(
      'localizes TM time-profile plan rows in ${scenario.locale.languageCode} '
      'at narrow high text scale',
      (tester) async {
        tester.view
          ..physicalSize = const Size(320, 700)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final inputs = TMAlgorithmInputs()
          ..profileMaxLength.text = '4'
          ..profileCandidateCap.text = '1000';
        addTearDown(inputs.dispose);

        final tm = TM
            .empty(id: 'time-profile-locale', name: 'Locale')
            .copyWith(
              alphabet: {for (var index = 0; index < 10; index++) '$index'},
            );
        await tester.pumpWidget(
          MaterialApp(
            locale: scenario.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                child: TMTimeProfilerControls(
                  tm: tm,
                  inputs: inputs,
                  state: const TMAlgorithmAnalysisState(),
                  onInputsChanged: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final rowsFinder = find.byKey(
          const ValueKey('tm-time-profile-plan-rows'),
        );
        expect(rowsFinder, findsOneWidget);
        final rows = tester.widget<Text>(rowsFinder).data;
        final formatter = LocaleValueFormatter(scenario.locale);
        final plannedCount = tester
            .widget<Text>(
              find.byKey(const ValueKey('tm-time-profile-planned-count')),
            )
            .data;
        expect(plannedCount, contains(formatter.integer(2111)));
        expect(
          rows,
          contains('n=3: ${formatter.integer(1000)} ${scenario.exhaustive}'),
        );
        expect(
          rows,
          contains(
            'n=4: ${formatter.integer(1000)}/'
            '${formatter.integerBigInt(BigInt.from(10000))} '
            '${scenario.sampled}',
          ),
        );
        final oppositeSampled = scenario.sampled == 'sampled'
            ? 'amostrado'
            : 'sampled';
        final oppositeExhaustive = scenario.exhaustive == 'exhaustive'
            ? 'exaustivo'
            : 'exhaustive';
        expect(rows, isNot(contains(oppositeSampled)));
        expect(rows, isNot(contains(oppositeExhaustive)));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
