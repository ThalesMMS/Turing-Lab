//
//  workspace_help_test.dart
//  Turing Lab
//
//  Verifies the shared workspace help flow, including unavailable content and
//  the path from contextual guidance to the keyboard shortcuts dialog.
//
//  Thales Matheus Mendonça Santos - August 2026
//

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/core/constants/help_content.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/common/workspace_help.dart';
import 'package:turing_lab/presentation/widgets/context_aware_help_panel.dart';
import 'package:turing_lab/presentation/widgets/keyboard_shortcuts_dialog.dart';

Widget _testApp(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('reports unavailable workspace help content', (tester) async {
    await tester.pumpWidget(
      _testApp(
        Consumer(
          builder: (context, ref, _) {
            return ElevatedButton(
              onPressed: () => showWorkspaceHelp(
                context: context,
                ref: ref,
                contextId: 'missing_workspace_help',
              ),
              child: const Text('Open help'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open help'));
    await tester.pump();

    expect(
      find.text('Help content is not available right now.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('contextual help opens keyboard shortcuts', (tester) async {
    await tester.pumpWidget(
      _testApp(
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () => ContextAwareHelpPanel.show(
                context,
                helpContent: kHelpContent['usage_getting_started']!,
                showKeyboardShortcutsAction: true,
              ),
              child: const Text('Open contextual help'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open contextual help'));
    await tester.pumpAndSettle();

    expect(find.byType(ContextAwareHelpPanel), findsOneWidget);
    await tester.tap(find.widgetWithIcon(TextButton, Icons.keyboard));
    await tester.pumpAndSettle();

    expect(find.byType(ContextAwareHelpPanel), findsNothing);
    expect(find.byType(KeyboardShortcutsDialog), findsOneWidget);
  });
}
