import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/brute_force_parse_models.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/brute_force_teaching_workspace.dart';

void main() {
  testWidgets('formats brute-force statistics and limits by locale', (
    tester,
  ) async {
    final result = _result();

    await _pump(tester, const Locale('en'), result);
    expect(find.text('12,345'), findsOneWidget);
    expect(find.text('67,890'), findsOneWidget);
    expect(find.text('1,234 / 5,678'), findsOneWidget);
    expect(find.text('1.25 s'), findsOneWidget);
    expect(find.text('explored nodes'), findsOneWidget);
    expect(find.text('terminal count: 4'), findsOneWidget);

    await _pump(tester, const Locale('pt', 'BR'), result);
    expect(find.text('12.345'), findsOneWidget);
    expect(find.text('67.890'), findsOneWidget);
    expect(find.text('1.234 / 5.678'), findsOneWidget);
    expect(find.text('1,25 s'), findsOneWidget);
    expect(find.text('nós explorados'), findsOneWidget);
    expect(find.text('quantidade de terminais: 4'), findsOneWidget);
  });
}

BruteForceParseResult _result() => BruteForceParseResult(
  inputString: 'a',
  mode: BruteForceDerivationMode.leftmost,
  outcome: BruteForceParseOutcome.boundedUnknown,
  statistics: BruteForceSearchStatistics(
    exploredNodes: 12345,
    generatedNodes: 67890,
    frontierSize: 1234,
    frontierPeak: 5678,
    currentDepth: 9,
    retainedStates: 10,
    prunedByReason: const {BruteForcePruneReason.terminalCount: 4},
    executionTime: const Duration(milliseconds: 1250),
  ),
  witnesses: const [],
  witnessCount: 0,
  limit: BruteForceSearchLimit.exploredNodes,
);

Future<void> _pump(
  WidgetTester tester,
  Locale locale,
  BruteForceParseResult result,
) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: BruteForceTeachingWorkspace(result: result),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
