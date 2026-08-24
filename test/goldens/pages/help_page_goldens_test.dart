import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/pages/help_page.dart';
import 'package:turing_lab/presentation/widgets/help_tree_view.dart';

Future<void> _pumpHelpPage(
  WidgetTester tester, {
  required Size size,
  required Locale locale,
  required Brightness brightness,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidgetBuilder(
    ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo,
            brightness: brightness,
          ),
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: const HelpPage(),
      ),
    ),
    surfaceSize: size,
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testGoldens('mobile shows multiple open help branches', (tester) async {
    await _pumpHelpPage(
      tester,
      size: const Size(390, 844),
      locale: const Locale('pt'),
      brightness: Brightness.light,
    );

    final tree = tester.widget<HelpTreeView>(find.byType(HelpTreeView));
    tree.controller.toggle('getting-started');
    tree.controller.toggle('fsa');
    tree.controller.toggle('grammar');
    await tester.pumpAndSettle();

    await screenMatchesGolden(tester, 'help_page_mobile');
  });

  testGoldens('desktop shows search results and highlighted matches', (
    tester,
  ) async {
    await _pumpHelpPage(
      tester,
      size: const Size(1600, 1000),
      locale: const Locale('en'),
      brightness: Brightness.dark,
    );

    await tester.tap(find.byKey(const ValueKey('help-search-action')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('help-search-field')),
      'Clear canvas',
    );
    await tester.pumpAndSettle();

    await screenMatchesGolden(tester, 'help_page_desktop');
  });
}
