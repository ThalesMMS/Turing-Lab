import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turing_lab/core/manual_conversions/manual_conversion_content.dart';
import 'package:turing_lab/core/manual_conversions/manual_conversion_session.dart';
import 'package:turing_lab/injection/data_providers.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/manual_conversion_workspace.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final scenario in const [
    (
      locale: Locale('en'),
      compare: 'Compare',
      certainty: 'Exact equivalence',
      summary: 'The extracted regex is exactly equivalent to the source FSA.',
      counterexample: 'Counterexample: ab',
      provenance: 'Source provenance: q0',
    ),
    (
      locale: Locale('pt', 'BR'),
      compare: 'Comparar',
      certainty: 'Equivalência exata',
      summary:
          'A expressão regular extraída é exatamente equivalente ao AF de origem.',
      counterexample: 'Contraexemplo: ab',
      provenance: 'Proveniência da origem: q0',
    ),
  ]) {
    testWidgets('localizes manual conversion comparison in '
        '${scenario.locale.languageCode}', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final session = ManualConversionSession.start(
        id: 'manual-comparison-localization',
        direction: ManualConversionDirection.faToRegex,
        source: ManualConversionSource(
          documentId: 'source',
          revision: 1,
          snapshot: {'kind': 'fsa'},
        ),
        requirements: const [],
        canonicalArtifact: const {'regex': 'a'},
        completionEvidence: ManualConversionEvidence(
          summary:
              'The extracted regex is exactly equivalent to the source FSA.',
          certainty: ManualConversionCertainty.exact,
          provenanceIds: ['q0'],
          counterexample: 'ab',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
          child: MaterialApp(
            locale: scenario.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: ManualConversionWorkspace(
                title: 'Manual conversion',
                workspaceKey: 'manual-comparison-localization',
                initialSession: session,
                sourcePreview: const Text('Source'),
                resultPreviewBuilder: (_) => const Text('Result'),
                onOpenResult: (_) {},
                onClose: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, scenario.compare));
      await tester.pumpAndSettle();

      expect(find.textContaining(scenario.certainty), findsOneWidget);
      expect(find.textContaining(scenario.summary), findsOneWidget);
      expect(find.textContaining(scenario.counterexample), findsOneWidget);
      expect(find.textContaining(scenario.provenance), findsOneWidget);
      if (scenario.locale.languageCode == 'pt') {
        expect(find.textContaining('Exact equivalence'), findsNothing);
        expect(
          find.textContaining(
            'The extracted regex is exactly equivalent to the source FSA.',
          ),
          findsNothing,
        );
        expect(find.textContaining('Counterexample: ab'), findsNothing);
        expect(find.textContaining('Source provenance: q0'), findsNothing);
      }
    });
  }

  for (final scenario in const [
    (locale: Locale('en'), message: 'The learner FSA document is malformed.'),
    (
      locale: Locale('pt', 'BR'),
      message: 'O documento de AF do aprendiz está malformado.',
    ),
  ]) {
    testWidgets('localizes manual conversion validation diagnostics in '
        '${scenario.locale.languageCode}', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final session = ManualConversionSession.start(
        id: 'manual-diagnostic-localization',
        direction: ManualConversionDirection.regexToFa,
        source: ManualConversionSource(
          documentId: 'source',
          revision: 1,
          snapshot: {'kind': 'regex'},
        ),
        requirements: [
          ManualConversionRequirement(
            id: 'regex-to-fa.symbol',
            contentReference: ManualConversionContent.legacy,
            type: ManualConversionActionType.createBaseFragment,
            title: 'Build the symbol fragment',
            instruction: 'Build a fragment.',
            expectedPayload: const {
              'fragment': <String, Object?>{'states': []},
            },
            allowedPayloadKeys: const {'fragment'},
            hint: 'Build a fragment.',
            revealExplanation: 'The fragment is available.',
            evidence: ManualConversionEvidence(summary: 'A fragment.'),
          ),
        ],
        canonicalArtifact: const {'fsa': {}},
        completionEvidence: ManualConversionEvidence(summary: 'Complete.'),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
          child: MaterialApp(
            locale: scenario.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: ManualConversionWorkspace(
                title: 'Manual conversion',
                workspaceKey: 'manual-diagnostic-localization',
                initialSession: session,
                sourcePreview: const Text('Source'),
                resultPreviewBuilder: (_) => const Text('Result'),
                onOpenResult: (_) {},
                onClose: () {},
                onApplyPayload: (current, _) => ManualConversionCommandResult(
                  session: current,
                  diagnostics: const [
                    ManualConversionDiagnostic(
                      code: ManualConversionDiagnosticCode.invalidPayload,
                      message: 'The learner FSA document is malformed.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '{}');
      final apply = find.byKey(const ValueKey('manual-conversion-apply'));
      await tester.ensureVisible(apply);
      await tester.tap(apply);
      await tester.pumpAndSettle();

      expect(find.text(scenario.message), findsWidgets);
      if (scenario.locale.languageCode == 'pt') {
        expect(
          find.text('The learner FSA document is malformed.'),
          findsNothing,
        );
      }
    });
  }
}
