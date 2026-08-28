import 'dart:ui' show CheckedState;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/pda_acceptance_mode.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/pda_acceptance_mode_control.dart';

void main() {
  testWidgets('narrow control reflows without overflow and explains selection',
      (tester) async {
    await _pumpControl(tester, width: 320);

    expect(
      find.byKey(const ValueKey('pda-acceptance-layout-narrow')),
      findsOneWidget,
    );
    expect(
      find.textContaining('stack ignored'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow control localizes its label and explanation',
      (tester) async {
    await _pumpControl(tester, width: 308, locale: const Locale('pt'));

    expect(find.text('Modo de aceitação: estado final'), findsOneWidget);
    expect(find.text('Entrada consumida; pilha ignorada.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('radio semantics and arrow keys expose all acceptance rules',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final selected = <PDAAcceptanceMode>[];
    await _pumpControl(tester, width: 720, selected: selected);

    final finalState = find.byKey(
      const ValueKey('pda-acceptance-mode-finalState'),
    );
    expect(
      tester
          .getSemantics(finalState)
          .getSemanticsData()
          .flagsCollection
          .isChecked,
      CheckedState.isTrue,
    );
    expect(
      tester
          .getSemantics(
            find.byKey(const ValueKey('pda-acceptance-mode-semantics')),
          )
          .label,
      contains('Acceptance mode: final state'),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(selected, [PDAAcceptanceMode.emptyStack]);
    expect(
      tester
          .getSemantics(
            find.byKey(const ValueKey('pda-acceptance-mode-emptyStack')),
          )
          .getSemanticsData()
          .flagsCollection
          .isChecked,
      CheckedState.isTrue,
    );
    expect(
      find.textContaining('current state does not need to be accepting'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('308px dropdown opens and changes mode from the keyboard',
      (tester) async {
    final selected = <PDAAcceptanceMode>[];
    await _pumpControl(tester, width: 308, selected: selected);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('empty stack'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(selected, [PDAAcceptanceMode.emptyStack]);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpControl(
  WidgetTester tester, {
  required double width,
  List<PDAAcceptanceMode>? selected,
  Locale? locale,
}) async {
  tester.view.physicalSize = Size(width, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  var value = PDAAcceptanceMode.finalState;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => Center(
            child: SizedBox(
              width: width,
              child: PdaAcceptanceModeControl(
                value: value,
                onChanged: (next) {
                  selected?.add(next);
                  setState(() => value = next);
                },
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
