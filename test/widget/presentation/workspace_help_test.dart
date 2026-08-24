//
//  workspace_help_test.dart
//  Turing Lab
//
//  Verifies that workspace and contextual indicators share the Help catalog.
//
//  Thales Matheus Mendonça Santos - August 2026
//

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/core/constants/help_topic_ids.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/pages/help_page.dart';
import 'package:turing_lab/presentation/widgets/common/workspace_help.dart';

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
  testWidgets('showWorkspaceHelp opens the requested catalog topic', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () => showWorkspaceHelp(
                context: context,
                topicId: HelpTopicIds.pdaTheoryPda,
              ),
              child: const Text('Open help'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open help'));
    await tester.pumpAndSettle();

    final page = tester.widget<HelpPage>(find.byType(HelpPage));
    expect(page.initialTopicId, HelpTopicIds.pdaTheoryPda);
    expect(
      find.byKey(
        const ValueKey('help-body-${HelpTopicIds.pdaTheoryPda}'),
      ),
      findsOneWidget,
    );
  });
}
