import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/pages/settings_page.dart';
import 'package:turing_lab/presentation/widgets/switch_setting_tile.dart';

Future<void> _pumpSwitchSettingTile(
  WidgetTester tester, {
  required double width,
  required double textScale,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 300),
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: SwitchSettingTile(
                title: 'Show Grid',
                subtitle: 'Display grid lines on canvas',
                value: true,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

Future<void> _pumpSettingsPage(
  WidgetTester tester, {
  required double width,
  required double textScale,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 900),
            textScaler: TextScaler.linear(textScale),
          ),
          child: const SettingsPage(),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('SwitchSettingTile', () {
    testWidgets('keeps switch inline at default text scale', (tester) async {
      await _pumpSwitchSettingTile(tester, width: 420, textScale: 1);

      final switchRect = tester.getRect(find.byType(Switch));
      final subtitleRect =
          tester.getRect(find.text('Display grid lines on canvas'));

      expect(tester.takeException(), isNull);
      expect(switchRect.left, greaterThan(subtitleRect.right));
    });

    testWidgets('stacks switch below the copy at larger text scales', (
      tester,
    ) async {
      await _pumpSwitchSettingTile(tester, width: 420, textScale: 1.8);

      final switchRect = tester.getRect(find.byType(Switch));
      final subtitleRect =
          tester.getRect(find.text('Display grid lines on canvas'));

      expect(tester.takeException(), isNull);
      expect(switchRect.top, greaterThan(subtitleRect.bottom));
    });
  });

  group('SettingsPage', () {
    testWidgets(
        'lays out slider controls without overflow at larger text scales', (
      tester,
    ) async {
      await _pumpSettingsPage(tester, width: 360, textScale: 2);
      await tester.ensureVisible(
        find.byKey(const ValueKey('settings_font_size_slider')),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Text size in the interface'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('settings_font_size_slider')),
        findsOneWidget,
      );
      expect(find.text('Save Settings'), findsOneWidget);
    });
  });
}
