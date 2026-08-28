import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/l10n/app_localizations.dart';

import 'package:turing_lab/presentation/widgets/common/algorithm_button.dart';

void main() {
  testWidgets('AlgorithmButton exposes semantic label and hint', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var handleDisposed = false;
    addTearDown(() {
      if (!handleDisposed) {
        handle.dispose();
        handleDisposed = true;
      }
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AlgorithmButton(
            title: 'NFA to DFA',
            description: 'Convert a non-deterministic automaton to DFA form.',
            icon: Icons.transform,
            isSelected: true,
            onPressed: () {},
          ),
        ),
      ),
    );

    final semantics = tester.getSemantics(find.byType(AlgorithmButton));
    final data = semantics.getSemanticsData();

    expect(data.label, 'Algorithm action: NFA to DFA');
    expect(
      data.hint,
      'Double tap to start. Convert a non-deterministic automaton to DFA form.',
    );
    expect(data.value, 'Selected');
    expect(data.flagsCollection.isButton, isTrue);
    expect(data.flagsCollection.isEnabled, Tristate.isTrue);

    handle.dispose();
    handleDisposed = true;
  });

  testWidgets('AlgorithmButton reports disabled semantics when unavailable', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var handleDisposed = false;
    addTearDown(() {
      if (!handleDisposed) {
        handle.dispose();
        handleDisposed = true;
      }
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AlgorithmButton(
            title: 'Minimize DFA',
            description: 'Reduce the deterministic automaton to minimal form.',
            icon: Icons.compress,
            onPressed: null,
          ),
        ),
      ),
    );

    final semantics = tester.getSemantics(find.byType(AlgorithmButton));
    final data = semantics.getSemanticsData();

    expect(data.label, 'Algorithm action: Minimize DFA');
    expect(
      data.hint,
      'Unavailable. Reduce the deterministic automaton to minimal form.',
    );
    expect(data.value, isEmpty);
    expect(data.flagsCollection.isButton, isTrue);
    expect(data.flagsCollection.isEnabled, Tristate.isFalse);

    handle.dispose();
    handleDisposed = true;
  });

  testWidgets('formats execution progress with the active locale', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AlgorithmButton(
            title: 'Analyze',
            description: 'Analyze the automaton.',
            icon: Icons.analytics,
            isExecuting: true,
            executionProgress: 0.125,
          ),
        ),
      ),
    );

    expect(find.text('13%'), findsOneWidget);
    expect(find.text('12%'), findsNothing);
  });
}
