import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/tm_reachability_report.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/tm_reachability_result_view.dart';

// feature-localization-contract: advanced-tm-workspaces
// feature-localization-surface: responsive-accessibility
void main() {
  for (final scenario in const [
    (locale: Locale('en'), semanticLabel: 'Input ε • step 2'),
    (locale: Locale('pt', 'BR'), semanticLabel: 'Entrada ε • passo 2'),
  ]) {
    testWidgets('localizes TM reachability witness semantics in '
        '${scenario.locale.languageCode} at narrow high text scale', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(320, 700)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();

      try {
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
                padding: const EdgeInsets.all(16),
                child: TMReachabilityResultView(
                  report: _report(),
                  sourceTm: null,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final visibleSummary = find.text(scenario.semanticLabel);
        expect(visibleSummary, findsOneWidget);
        await tester.ensureVisible(visibleSummary);
        await tester.pumpAndSettle();

        final semanticSummary = find.bySemanticsLabel(scenario.semanticLabel);
        expect(semanticSummary, findsOneWidget);
        expect(
          tester.getSemantics(semanticSummary).label,
          scenario.semanticLabel,
        );
        final witnessTile = find.byKey(const Key('tm-reachability-witness-q0'));
        await tester.ensureVisible(witnessTile);
        await tester.tap(witnessTile);
        await tester.pumpAndSettle();
        if (scenario.locale.languageCode == 'pt') {
          expect(find.bySemanticsLabel('Input ε • step 2'), findsNothing);
          expect(find.text('Escopo de entradas'), findsOneWidget);
          expect(find.text('Exploração semântica'), findsOneWidget);
          expect(find.text('Transições exploradas'), findsOneWidget);
          expect(find.text('Posição do cabeçote'), findsOneWidget);
          expect(find.text('Traço de transições'), findsOneWidget);
          expect(find.text('Input scope'), findsNothing);
          expect(find.text('Transitions explored'), findsNothing);
        }
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }
}

TMReachabilityReport _report() => TMReachabilityReport(
  inputs: const [''],
  status: TMReachabilityStatus.complete,
  message: 'Complete.',
  structurallyReachableStateIds: const {'q0'},
  structurallyUnreachableStateIds: const {},
  witnessesByStateId: {
    'q0': TMReachabilityWitness(
      stateId: 'q0',
      input: '',
      step: 2,
      headPosition: 0,
      readSymbol: 'B',
      incomingTransitionId: 't0',
      stateIds: const ['q0'],
      transitionIds: const ['t0'],
    ),
  },
  configurationsExplored: 2,
  transitionsExplored: 1,
  maxSteps: 10,
  maxConfigurations: 20,
  timeout: const Duration(seconds: 1),
  executionTime: Duration.zero,
);
