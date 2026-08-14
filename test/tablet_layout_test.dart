import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turing_lab/presentation/pages/fsa_page.dart';
import 'package:turing_lab/presentation/pages/regex_page.dart';
import 'package:turing_lab/presentation/pages/grammar_page.dart';
import 'package:turing_lab/presentation/pages/tm_page.dart';
import 'package:turing_lab/presentation/pages/pda_page.dart';
import 'package:turing_lab/presentation/widgets/tablet_layout_container.dart';
import 'package:turing_lab/presentation/providers/grammar_provider.dart';
import 'package:turing_lab/presentation/providers/unified_trace_provider.dart';
import 'package:turing_lab/presentation/pages/pumping_lemma_page.dart';
import 'package:turing_lab/l10n/app_localizations.dart';

Future<Override> _sharedPreferencesOverride() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return sharedPreferencesProvider.overrideWithValue(prefs);
}

void main() {
  group('Tablet Layout Tests', () {
    testWidgets('FSAPage uses TabletLayoutContainer on tablet width', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1366, 1024);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [await _sharedPreferencesOverride()],
          child: const MaterialApp(home: FSAPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TabletLayoutContainer), findsOneWidget);
    });

    testWidgets('RegexPage uses TabletLayoutContainer on tablet width', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1366, 1024);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [await _sharedPreferencesOverride()],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: RegexPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TabletLayoutContainer), findsOneWidget);
    });

    testWidgets('GrammarPage uses TabletLayoutContainer on tablet width', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1366, 1024);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            await _sharedPreferencesOverride(),
            grammarProvider.overrideWith((ref) => GrammarProvider()),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: GrammarPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TabletLayoutContainer), findsOneWidget);
    });

    testWidgets('TMPage uses TabletLayoutContainer on tablet width', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1366, 1024);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [await _sharedPreferencesOverride()],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: TMPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TabletLayoutContainer), findsOneWidget);
    });

    testWidgets('PDAPage uses TabletLayoutContainer on tablet width', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1366, 1024);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [await _sharedPreferencesOverride()],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: PDAPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TabletLayoutContainer), findsOneWidget);
    });

    testWidgets('PumpingLemmaPage uses TabletLayoutContainer on tablet width', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1366, 1024);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [await _sharedPreferencesOverride()],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: PumpingLemmaPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TabletLayoutContainer), findsOneWidget);
      expect(find.text('Help'), findsOneWidget);
      expect(find.text('Progress'), findsOneWidget);
    });

    testWidgets('TabletLayoutContainer sidebar can be collapsed and expanded', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1366, 1024);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TabletLayoutContainer(
              canvas: Text('Canvas Content'),
              algorithmPanel: Text('Algorithm Panel Content'),
              simulationPanel: Text('Simulation Panel Content'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially expanded
      expect(find.text('Algorithm Panel Content'), findsOneWidget);
      expect(find.byIcon(Icons.close_fullscreen), findsOneWidget);

      // Collapse
      await tester.tap(find.byIcon(Icons.close_fullscreen));
      await tester.pumpAndSettle();

      // Sidebar content should be gone
      expect(find.text('Algorithm Panel Content'), findsNothing);
      expect(find.byIcon(Icons.menu_open), findsOneWidget);

      // Expand
      await tester.tap(find.byIcon(Icons.menu_open));
      await tester.pumpAndSettle();

      expect(find.text('Algorithm Panel Content'), findsOneWidget);
      expect(find.byIcon(Icons.close_fullscreen), findsOneWidget);
    });
  });
}
