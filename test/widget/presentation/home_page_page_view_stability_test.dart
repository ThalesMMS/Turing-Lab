//
//  home_page_page_view_stability_test.dart
//  Turing Lab
//
//  Garante que o PageView da HomePage mantém o mesmo elemento ao alternar
//  entre módulos com e sem canvas. Recriar a subárvore nessa troca anexava
//  transitoriamente duas ScrollPositions ao mesmo PageController e disparava
//  a assertion "multiple PageViews attached to the same PageController".
//
//  Thales Matheus Mendonça Santos - July 2026
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:turing_lab/injection/data_providers.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/pages/home_page.dart';
import 'package:turing_lab/presentation/providers/home_navigation_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets(
    'keeps the PageView element alive when crossing canvas/non-canvas tabs',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final navigationNotifier = HomeNavigationNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            homeNavigationProvider.overrideWith((ref) => navigationNotifier),
          ],
          child: const MaterialApp(
            home: HomePage(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final pageViewFinder = find.byType(PageView);
      expect(pageViewFinder, findsOneWidget);
      final elementBefore = tester.element(pageViewFinder);
      final controller = tester.widget<PageView>(pageViewFinder).controller!;
      expect(controller.positions, hasLength(1));

      // FSA (canvas, index 0) -> Grammar (non-canvas, index 1).
      navigationNotifier.setIndex(1);
      await tester.pumpAndSettle();

      expect(pageViewFinder, findsOneWidget);
      final elementAfterForward = tester.element(pageViewFinder);
      expect(
        identical(elementBefore, elementAfterForward),
        isTrue,
        reason: 'switching to a non-canvas tab must not recreate the PageView '
            '(a recreated PageView transiently double-attaches the shared '
            'PageController)',
      );
      expect(controller.positions, hasLength(1));

      // And back: Grammar (non-canvas) -> FSA (canvas).
      navigationNotifier.setIndex(0);
      await tester.pumpAndSettle();

      final elementAfterBack = tester.element(pageViewFinder);
      expect(identical(elementBefore, elementAfterBack), isTrue);
      expect(controller.positions, hasLength(1));
    },
  );
}
