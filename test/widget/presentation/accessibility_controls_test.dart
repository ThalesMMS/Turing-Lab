import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/error_banner.dart';
import 'package:turing_lab/presentation/widgets/keyboard_shortcuts_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ErrorBanner', () {
    testWidgets('renders a dismiss action with a 44pt tap target', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorBanner(
              message: 'Something happened',
              severity: ErrorSeverity.warning,
              showRetryButton: false,
              onDismiss: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final dismissButton = find.ancestor(
        of: find.text('Dismiss'),
        matching: find.bySubtype<ButtonStyleButton>(),
      );

      expect(dismissButton, findsOneWidget);
      expect(tester.getSize(dismissButton).height, greaterThanOrEqualTo(44));
    });
  });

  group('KeyboardShortcutsDialog', () {
    testWidgets('closes when Escape is pressed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => KeyboardShortcutsDialog.show(context),
                    child: const Text('Open'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Keyboard Shortcuts'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text('Keyboard Shortcuts'), findsNothing);
    });
  });
}
