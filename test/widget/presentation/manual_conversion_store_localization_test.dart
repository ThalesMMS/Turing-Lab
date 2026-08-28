import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turing_lab/core/manual_conversions/manual_conversion_content.dart';
import 'package:turing_lab/core/manual_conversions/manual_conversion_session.dart';
import 'package:turing_lab/data/services/manual_conversion_session_store.dart';
import 'package:turing_lab/injection/data_providers.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/manual_conversion_workspace.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('locale switch rerenders a persisted restore failure', (
    tester,
  ) async {
    const workspaceKey = 'localized-store-error';
    const storageKey = '${ManualConversionSessionStore.keyPrefix}$workspaceKey';
    SharedPreferences.setMockInitialValues({storageKey: '{invalid json'});
    final preferences = await SharedPreferences.getInstance();
    var locale = const Locale('en');
    late StateSetter rebuildApp;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: StatefulBuilder(
          builder: (context, setState) {
            rebuildApp = setState;
            return MaterialApp(
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: ManualConversionWorkspace(
                  title: 'Manual conversion',
                  workspaceKey: workspaceKey,
                  initialSession: _session(),
                  sourcePreview: const Text('Source'),
                  resultPreviewBuilder: (_) => const Text('Result'),
                  onOpenResult: (_) {},
                  onClose: () {},
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('The saved construction is malformed.'), findsOneWidget);
    await preferences.remove(storageKey);
    rebuildApp(() => locale = const Locale('pt', 'BR'));
    await tester.pumpAndSettle();

    expect(find.text('A construção salva está malformada.'), findsOneWidget);
    expect(find.text('The saved construction is malformed.'), findsNothing);
  });
}

ManualConversionSession _session() => ManualConversionSession.start(
  id: 'localized-store-error-session',
  direction: ManualConversionDirection.faToRegex,
  source: ManualConversionSource(
    documentId: 'fa',
    revision: 1,
    snapshot: const {'edge': 't0'},
  ),
  requirements: [
    ManualConversionRequirement(
      id: 'edge-t0',
      contentReference: ManualConversionContent.legacy,
      type: ManualConversionActionType.addTransition,
      title: 'Map edge',
      instruction: 'Enter the expression.',
      expectedPayload: const {'expression': 'a'},
      allowedPayloadKeys: const {'expression'},
      hint: 'Read the source edge label.',
      revealExplanation: 'The edge maps directly to a.',
      evidence: ManualConversionEvidence(summary: 'Exact mapping.'),
    ),
  ],
  canonicalArtifact: const {'regex': 'a'},
  completionEvidence: ManualConversionEvidence(
    summary: 'The languages are equivalent.',
    certainty: ManualConversionCertainty.exact,
  ),
);
