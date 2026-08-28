import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/fsa/determinism_badge.dart';
import 'package:turing_lab/presentation/widgets/tm/tape_drawer.dart';

void main() {
  testWidgets('determinism badge exposes localized button semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    for (final scenario in const [
      (
        locale: Locale('en'),
        label: 'DFA, Determinism Analysis',
        hint: 'Show details',
      ),
      (
        locale: Locale('pt'),
        label: 'DFA, Análise de determinismo',
        hint: 'Mostrar detalhes',
      ),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          locale: scenario.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: FsaTypeBadge(
              info: const DeterminismInfo(
                isDeterministic: true,
                hasEpsilonTransitions: false,
              ),
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final data = tester
          .getSemantics(find.byType(FsaTypeBadge))
          .getSemanticsData();
      expect(data.label, scenario.label);
      expect(data.hint, scenario.hint);
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.hasAction(SemanticsAction.tap), isTrue);
    }
    semantics.dispose();
  });

  testWidgets('tape cell clear action uses the active locale', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TMTapePanel(
            tapeState: const TapeState(cells: ['a'], headPosition: 0),
            tapeAlphabet: const {'a'},
            onCellEdit: (_, __) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();

    expect(find.byTooltip('Limpar'), findsOneWidget);
  });
}
