import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turing_lab/app.dart';
import 'package:turing_lab/core/models/settings_model.dart';
import 'package:turing_lab/core/pumping_lemma/pumping_lemma.dart';
import 'package:turing_lab/core/repositories/settings_repository.dart';
import 'package:turing_lab/injection/data_providers.dart';
import 'package:turing_lab/presentation/pages/home_page.dart';
import 'package:turing_lab/presentation/pages/pumping_lemma_chooser_page.dart';
import 'package:turing_lab/presentation/pages/pumping_lemma_page.dart';

class _FakeSettingsRepository implements SettingsRepository {
  @override
  Future<SettingsModel> loadSettings() async => const SettingsModel();

  @override
  Future<void> saveSettings(SettingsModel settings) async {}
}

Future<void> _pumpApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues(const {});
  final preferences = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        settingsRepositoryProvider.overrideWithValue(
          _FakeSettingsRepository(),
        ),
      ],
      child: const TuringLabApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('historical route opens an explicit theorem chooser', (
    tester,
  ) async {
    await _pumpApp(tester);

    Navigator.of(tester.element(find.byType(HomePage))).pushNamed(
      PumpingLemmaChooserPage.route,
    );
    await tester.pumpAndSettle();

    expect(find.byType(PumpingLemmaChooserPage), findsOneWidget);
    expect(find.text('Choose a pumping lemma environment'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('choose-regular-pumping')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('choose-context-free-pumping')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('choose-regular-pumping')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<PumpingLemmaPage>(find.byType(PumpingLemmaPage)).theorem,
      PumpingLemmaTheorem.regular,
    );
  });

  testWidgets('chooser reaches the context-free route', (tester) async {
    await _pumpApp(tester);
    Navigator.of(tester.element(find.byType(HomePage))).pushNamed(
      PumpingLemmaChooserPage.route,
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('choose-context-free-pumping')),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<PumpingLemmaPage>(find.byType(PumpingLemmaPage)).theorem,
      PumpingLemmaTheorem.contextFree,
    );
  });

  testWidgets('chooser has accessible controls at high text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final semantics = tester.ensureSemantics();

    await _pumpApp(tester);
    Navigator.of(tester.element(find.byType(HomePage))).pushNamed(
      PumpingLemmaChooserPage.route,
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Regular pumping'), findsOneWidget);
    expect(find.bySemanticsLabel('Context-free pumping'), findsOneWidget);
    semantics.dispose();
    expect(tester.takeException(), isNull);
  });
}
