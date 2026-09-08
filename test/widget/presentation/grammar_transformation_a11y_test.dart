//
//  grammar_transformation_a11y_test.dart
//  Turing Lab
//
//  Semantics-tree and keyboard audit of the grammar transformation history:
//  distinguishable Apply actions, reported expanded state, grouped
//  before/after snapshots, a count-only live region for history changes, and keyboard
//  expansion/activation without focus loss, in English and Portuguese.
//
//  This is widget-level evidence only; it does not replace a VoiceOver or
//  TalkBack journey on hardware.
//

import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/grammar_transformation_step.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/grammar/grammar_transformation_history.dart';

List<GrammarTransformationStep> _steps() {
  final grammar = Grammar.empty(
    id: 'grammar',
    name: 'Grammar',
    type: GrammarType.contextFree,
  );
  return [
    GrammarTransformationStep(
      id: 'remove-lambda',
      operation: 'Remove lambda productions',
      rationale: 'Nullable variables are expanded.',
      before: grammar,
      after: grammar,
    ),
    GrammarTransformationStep(
      id: 'remove-unit',
      operation: 'Remove unit productions',
      rationale: 'Unit chains are inlined.',
      before: grammar,
      after: grammar,
    ),
  ];
}

Future<void> _pump(
  WidgetTester tester, {
  required List<GrammarTransformationStep> steps,
  required ValueChanged<Grammar> onApplyGrammar,
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: GrammarTransformationHistory(
            steps: steps,
            onApplyGrammar: onApplyGrammar,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Iterable<SemanticsNode> _allNodes(WidgetTester tester) {
  final nodes = <SemanticsNode>[];
  void visit(SemanticsNode node) {
    nodes.add(node);
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(tester.getSemantics(find.byType(GrammarTransformationHistory)));
  return nodes;
}

void main() {
  testWidgets('exposes one count-only live region and expanded state', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, steps: _steps(), onApplyGrammar: (_) {});

    // The widget adds exactly one live region (the step count). The other
    // live regions are ExpansionTile's own Collapsed/Expanded announcements.
    final liveRegions = _allNodes(
      tester,
    ).where((node) => node.flagsCollection.isLiveRegion).toList();
    final countRegions = liveRegions
        .where((node) => node.label == '2 transformation steps')
        .toList();
    expect(countRegions, hasLength(1));
    expect(
      liveRegions
          .where((node) => !countRegions.contains(node))
          .every(
            (node) => node.label == 'Collapsed' || node.label == 'Expanded',
          ),
      isTrue,
    );

    SemanticsNode tileOf(String title) => _allNodes(tester).firstWhere(
      (node) =>
          node.flagsCollection.isExpanded != Tristate.none &&
          _subtreeLabel(node).contains(title),
    );
    expect(
      tileOf('Step 1. Remove lambda productions').flagsCollection.isExpanded ==
          Tristate.isTrue,
      isFalse,
    );

    await tester.tap(find.text('Step 1. Remove lambda productions'));
    await tester.pumpAndSettle();
    expect(
      tileOf('Step 1. Remove lambda productions').flagsCollection.isExpanded ==
          Tristate.isTrue,
      isTrue,
    );
    expect(
      tileOf('Step 2. Remove unit productions').flagsCollection.isExpanded ==
          Tristate.isTrue,
      isFalse,
    );

    // Before/after snapshots read as one grouped item each.
    final before = tester.getSemantics(find.text('Before'));
    expect(before.label, startsWith('Before'));
    expect(before.label, contains('(no productions)'));
    final after = tester.getSemantics(find.text('After'));
    expect(after.label, startsWith('After'));
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('Apply buttons carry the step number and operation', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, steps: _steps(), onApplyGrammar: (_) {});
    await tester.tap(find.text('Step 1. Remove lambda productions'));
    await tester.tap(find.text('Step 2. Remove unit productions'));
    await tester.pumpAndSettle();

    final labels = _allNodes(tester)
        .where((node) => node.flagsCollection.isButton)
        .map((node) => node.label)
        .where((label) => label.startsWith('Apply the grammar'))
        .toList();
    expect(labels, [
      'Apply the grammar produced by step 1: Remove lambda productions',
      'Apply the grammar produced by step 2: Remove unit productions',
    ]);
    expect(find.text('Apply'), findsNWidgets(2));
    semantics.dispose();
  });

  testWidgets('keyboard expands a step and applies it without losing focus', (
    tester,
  ) async {
    Grammar? applied;
    await _pump(tester, steps: _steps(), onApplyGrammar: (g) => applied = g);

    // Tab reaches the first step header; Enter expands it.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus, isNotNull);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('apply-grammar-step-remove-lambda')),
      findsOneWidget,
    );

    // Next Tab lands on the Apply button of the expanded step.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final focused = FocusManager.instance.primaryFocus;
    expect(focused, isNotNull);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(applied, isNotNull);
    expect(FocusManager.instance.primaryFocus, same(focused));
    expect(tester.takeException(), isNull);
  });

  testWidgets('localizes the audit strings in Portuguese', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(
      tester,
      steps: _steps(),
      onApplyGrammar: (_) {},
      locale: const Locale('pt', 'BR'),
    );
    expect(
      _allNodes(tester)
          .where((node) => node.flagsCollection.isLiveRegion)
          .map((node) => node.label),
      contains('2 passos de transformação'),
    );

    await tester.tap(find.text('Passo 1. Remove lambda productions'));
    await tester.pumpAndSettle();
    expect(
      _allNodes(tester).map((node) => node.label),
      contains(
        'Aplicar a gramática produzida pelo passo 1: Remove lambda productions',
      ),
    );
    expect(tester.getSemantics(find.text('Antes')).label, startsWith('Antes'));
    semantics.dispose();
  });
}

String _subtreeLabel(SemanticsNode node) {
  final buffer = StringBuffer(node.label);
  node.visitChildren((child) {
    buffer.write(' ${_subtreeLabel(child)}');
    return true;
  });
  return buffer.toString();
}
