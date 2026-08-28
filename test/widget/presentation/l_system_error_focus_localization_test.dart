import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/data/l_systems/l_system_examples.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/l_systems/l_system_editor_controller.dart';
import 'package:turing_lab/presentation/l_systems/l_system_workspace.dart';

void main() {
  testWidgets('focuses invalid L-system fields in EN and PT', (tester) async {
    final locale = ValueNotifier(const Locale('en'));
    final controller = LSystemEditorController(
      document: LSystemExamples.values.first.document,
    );
    addTearDown(locale.dispose);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      ValueListenableBuilder<Locale>(
        valueListenable: locale,
        builder: (context, value, _) => MaterialApp(
          locale: value,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: LSystemWorkspace(controller: controller)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final iterations = find.widgetWithText(TextField, 'Iterations');
    await tester.enterText(iterations, '-1');
    await _tapApply(tester, 'Apply and expand');
    expect(find.text('Iterations must be zero or greater.'), findsOneWidget);
    expect(tester.widget<TextField>(iterations).focusNode?.hasFocus, isTrue);

    await tester.enterText(iterations, '0');
    locale.value = const Locale('pt', 'BR');
    await tester.pumpAndSettle();

    final rules = find.widgetWithText(TextField, 'Regras de produção paralela');
    await tester.enterText(rules, 'F');
    await _tapApply(tester, 'Aplicar e expandir');
    expect(find.text('A regra 1 deve conter ->.'), findsOneWidget);
    expect(tester.widget<TextField>(rules).focusNode?.hasFocus, isTrue);

    await tester.enterText(rules, 'F -> F');
    final mapping = find.widgetWithText(
      TextField,
      'Mapeamento de comandos da tartaruga',
    );
    await tester.enterText(mapping, 'F drawForward');
    await _tapApply(tester, 'Aplicar e expandir');
    expect(
      find.text('O mapeamento de comandos 1 deve conter =.'),
      findsOneWidget,
    );
    expect(tester.widget<TextField>(mapping).focusNode?.hasFocus, isTrue);
  });
}

Future<void> _tapApply(WidgetTester tester, String label) async {
  final apply = find.widgetWithText(FilledButton, label);
  await tester.ensureVisible(apply);
  await tester.tap(apply);
  await tester.pumpAndSettle();
}
