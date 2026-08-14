import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/pages/regex_page.dart';
import 'package:turing_lab/presentation/providers/regex_editor_provider.dart';

void main() {
  testWidgets('editing the pattern immediately removes old result cards',
      (tester) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(regexEditorProvider.notifier);
    notifier.validateRegex('a*');
    expect(notifier.runSimplificationWithSteps().isSuccess, isTrue);
    expect(notifier.runComplexityAnalysis().isSuccess, isTrue);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RegexPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Re-analyze'), findsOneWidget);
    expect(find.text('Re-simplify'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('regex_input_field')),
      'b',
    );
    await tester.pump();

    expect(find.text('Re-analyze'), findsNothing);
    expect(find.text('Re-simplify'), findsNothing);
    expect(find.text('Analyze Complexity'), findsOneWidget);
    expect(find.text('Simplify with Steps'), findsOneWidget);
  });
}
