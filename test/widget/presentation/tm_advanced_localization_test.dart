import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/providers/tm_editor_provider.dart';
import 'package:turing_lab/presentation/widgets/tm_simulation_panel.dart';

void main() {
  testWidgets(
    'localizes the TM batch section and keeps its semantic name in PT-BR',
    (tester) async {
      final notifier = TMEditorNotifier()
        ..upsertState(id: 'q0', label: 'q0', x: 0, y: 0, isInitial: true);
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [tmEditorProvider.overrideWith((_) => notifier)],
          child: const MaterialApp(
            locale: Locale('pt', 'BR'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: TMSimulationPanel()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Testes em lote'), findsOneWidget);
      expect(
        tester.getSemantics(find.text('Testes em lote')).label,
        contains('Testes em lote'),
      );

      await tester.ensureVisible(find.text('Testes em lote'));
      await tester.tap(find.text('Testes em lote'));
      await tester.pumpAndSettle();
      expect(find.text('Execução em lote de MT'), findsOneWidget);
      expect(find.text('Run ordered, bounded TM simulations'), findsNothing);
      expect(tester.takeException(), isNull);

      semantics.dispose();
    },
  );
}
