import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/pages/about_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpAboutPage(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AboutPage(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the landing overview content', (tester) async {
    await pumpAboutPage(tester);

    expect(find.byKey(const ValueKey('about_page')), findsOneWidget);
    expect(find.byKey(const ValueKey('about_overview_title')), findsOneWidget);
    expect(find.byKey(const ValueKey('about_capabilities')), findsOneWidget);
    expect(find.byKey(const ValueKey('about_formats')), findsOneWidget);
    expect(find.byKey(const ValueKey('about_platforms')), findsOneWidget);
    expect(find.byKey(const ValueKey('about_screenshots')), findsOneWidget);
    expect(find.byKey(const ValueKey('about_open_licenses')), findsOneWidget);
  });
}
