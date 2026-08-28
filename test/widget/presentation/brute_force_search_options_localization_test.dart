import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/brute_force_parse_models.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/brute_force_search_options.dart';

void main() {
  testWidgets('formats live brute-force progress by locale', (tester) async {
    final progress = BruteForceSearchProgress(
      statistics: BruteForceSearchStatistics(
        exploredNodes: 12345,
        generatedNodes: 0,
        frontierSize: 6789,
        frontierPeak: 0,
        currentDepth: 0,
        retainedStates: 0,
        prunedByReason: const {},
        executionTime: Duration.zero,
      ),
      witnessCount: 12,
    );
    final fields = List.generate(4, (_) => TextEditingController());

    await _pump(tester, const Locale('en'), progress, fields);
    expect(
      find.text('Searching: 12,345 explored, 6,789 queued, 12 witnesses'),
      findsOneWidget,
    );

    await _pump(tester, const Locale('pt', 'BR'), progress, fields);
    expect(
      find.text('Buscando: 12.345 explorados, 6.789 na fila, 12 testemunhos'),
      findsOneWidget,
    );

    for (final controller in fields) {
      controller.dispose();
    }
  });
}

Future<void> _pump(
  WidgetTester tester,
  Locale locale,
  BruteForceSearchProgress progress,
  List<TextEditingController> fields,
) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BruteForceSearchOptions(
          mode: BruteForceDerivationMode.leftmost,
          onModeChanged: (_) {},
          depthController: fields[0],
          frontierController: fields[1],
          resultCapController: fields[2],
          timeLimitController: fields[3],
          onLimitsChanged: () {},
          progress: progress,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
