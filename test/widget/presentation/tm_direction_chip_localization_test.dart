import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/tm/direction_icon.dart';

void main() {
  for (final scenario in const [
    (
      locale: Locale('en'),
      labels: <String>['Left (L)', 'Right (R)', 'Stay (S)'],
    ),
    (
      locale: Locale('pt', 'BR'),
      labels: <String>['Esquerda (L)', 'Direita (R)', 'Permanecer (S)'],
    ),
  ]) {
    testWidgets('noncompact direction chips expose localized actions in '
        '${scenario.locale.languageCode}', (tester) async {
      final semantics = tester.ensureSemantics();
      var selected = TapeDirection.left;

      await tester.pumpWidget(
        MaterialApp(
          locale: scenario.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => TMDirectionSelector(
                selected: selected,
                onChanged: (value) => setState(() => selected = value),
              ),
            ),
          ),
        ),
      );

      for (var index = 0; index < scenario.labels.length; index++) {
        final label = scenario.labels[index];
        final node = tester.getSemantics(find.bySemanticsLabel(label));
        final data = node.getSemanticsData();
        expect(node.label, label);
        expect(data.hasAction(SemanticsAction.tap), isTrue);
        expect(data.flagsCollection.isButton, isTrue);
        expect(find.byTooltip(label), findsOneWidget);
        expect(
          data.flagsCollection.isSelected,
          index == selected.index ? Tristate.isTrue : Tristate.isFalse,
        );
      }

      await tester.tap(find.bySemanticsLabel(scenario.labels[1]));
      await tester.pump();
      expect(selected, TapeDirection.right);
      expect(
        tester
            .getSemantics(find.bySemanticsLabel(scenario.labels[1]))
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }
}
