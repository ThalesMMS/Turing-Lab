//
//  app_store_capture_screens.dart
//  Turing Lab
//
//  Deterministic journey setup for every App Store slot. Each preparation
//  seeds offline fixtures through providers and then waits on observable
//  provider and layout state, never on a fixed delay.
//
//  Thales Matheus Mendonça Santos - August 2026
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/data/data_sources/examples_asset_data_source.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/pages/fsa_page.dart';
import 'package:turing_lab/presentation/pages/grammar_page.dart';
import 'package:turing_lab/presentation/pages/pda_page.dart';
import 'package:turing_lab/presentation/pages/regex_page.dart';
import 'package:turing_lab/presentation/pages/tm_page.dart';
import 'package:turing_lab/presentation/providers/automaton_simulation_provider.dart';
import 'package:turing_lab/presentation/providers/automaton_state_provider.dart';
import 'package:turing_lab/presentation/providers/grammar_provider.dart';
import 'package:turing_lab/presentation/providers/home_navigation_provider.dart';
import 'package:turing_lab/presentation/providers/pda_editor_provider.dart';
import 'package:turing_lab/presentation/providers/regex_editor_provider.dart';
import 'package:turing_lab/presentation/providers/tm_editor_provider.dart';
import 'package:turing_lab/presentation/widgets/workspace_quick_actions_bar.dart';

import '../../tool/app_store/app_store_capture_screen.dart';
import 'app_store_capture_fixtures.dart';
import 'app_store_capture_waits.dart';
import 'app_store_field_entry.dart';

/// Prepares the workspace shown by each captured slot.
class AppStoreCaptureScreens {
  const AppStoreCaptureScreens({
    required this.tester,
    required this.container,
    required this.waits,
    required this.localizations,
  });

  /// Width below which the app renders its mobile workspace layout.
  static const double mobileBreakpoint = 1024;

  final WidgetTester tester;
  final ProviderContainer container;
  final AppStoreCaptureWaits waits;
  final AppLocalizations localizations;

  bool get isMobile => waits.viewport.width < mobileBreakpoint;

  /// Runs the preparation registered for [screen].
  Future<void> prepare(AppStoreCaptureScreen screen) async {
    switch (screen.id) {
      case 'fsa':
        await _prepareFsa();
      case 'grammar':
        await _prepareGrammar();
      case 'pda':
        await _preparePda();
      case 'tm':
        await _prepareTm();
      case 'regex':
        await _prepareRegex();
      default:
        throw StateError('No capture preparation for screen "${screen.id}".');
    }
  }

  Future<void> _prepareFsa() async {
    container
        .read(automatonStateProvider.notifier)
        .updateAutomaton(AppStoreCaptureFixtures.endsWithA());
    await waits.until(
      tester,
      stage: 'fsa-fixture',
      pending: 'automatonStateProvider never exposed the seeded automaton',
      condition: () =>
          container.read(automatonStateProvider).currentAutomaton != null,
    );
    await _showWorkspace(
      HomeNavigationNotifier.fsaIndex,
      find.byType(FSAPage),
      'fsa',
    );

    if (!isMobile) {
      return;
    }

    await _tapSimulateAction();
    await AppStoreFieldEntry.enter(
      tester,
      waits,
      AppStoreFieldEntry.legacyInputLabel,
      'ba',
    );
    await container
        .read(automatonSimulationProvider.notifier)
        .simulateAutomaton('ba');
    await waits.untilVisible(
      tester,
      find.text(localizations.accepted),
      stage: 'fsa-simulation',
      pending: 'the simulation panel never reported '
          '"${localizations.accepted}" for input "ba"',
    );
  }

  Future<void> _prepareGrammar() async {
    final grammar = container.read(grammarProvider.notifier);
    grammar.createNewGrammar(
      name: 'Balanced Grammar',
      startSymbol: 'S',
      type: GrammarType.contextFree,
    );
    grammar.addProduction(
      leftSide: const ['S'],
      rightSide: const ['a', 'S', 'b'],
    );
    grammar.addProduction(
      leftSide: const ['S'],
      rightSide: const ['a', 'b'],
    );
    await waits.until(
      tester,
      stage: 'grammar-fixture',
      pending: 'grammarProvider never exposed the two seeded productions',
      condition: () => container.read(grammarProvider).productions.length == 2,
    );
    await _showWorkspace(
      HomeNavigationNotifier.grammarIndex,
      find.byType(GrammarPage),
      'grammar',
    );
  }

  Future<void> _preparePda() async {
    final pda = await waits.runReal<PDA>(
      tester,
      'pda-fixture',
      () async {
        final result = await ExamplesAssetDataSource()
            .loadTypedPdaExample('APD - a^n b^n');
        final example = result.data;
        if (example == null) {
          throw StateError('Failed to load the PDA example: ${result.error}');
        }
        return example.payload;
      },
    );
    container.read(pdaEditorProvider.notifier).setPda(pda);
    await waits.until(
      tester,
      stage: 'pda-fixture',
      pending: 'pdaEditorProvider never exposed the loaded machine',
      condition: () => container.read(pdaEditorProvider).pda != null,
    );
    await _showWorkspace(
      HomeNavigationNotifier.pdaIndex,
      find.byType(PDAPage),
      'pda',
    );
  }

  Future<void> _prepareTm() async {
    final tm = await waits.runReal<TM>(
      tester,
      'tm-fixture',
      () async {
        final result = await ExamplesAssetDataSource()
            .loadTypedTmExample('MT - Incremento binário');
        final example = result.data;
        if (example == null) {
          throw StateError('Failed to load the TM example: ${result.error}');
        }
        return example.payload;
      },
    );
    container.read(tmEditorProvider.notifier).setTm(tm);
    await waits.until(
      tester,
      stage: 'tm-fixture',
      pending: 'tmEditorProvider never exposed the loaded machine',
      condition: () => container.read(tmEditorProvider).tm != null,
    );
    await _showWorkspace(
      HomeNavigationNotifier.tmIndex,
      find.byType(TMPage),
      'tm',
    );
  }

  Future<void> _prepareRegex() async {
    await _showWorkspace(
      HomeNavigationNotifier.regexIndex,
      find.byType(RegexPage),
      'regex',
    );

    final patternField = find.byKey(const ValueKey('regex_input_field'));
    await waits.untilVisible(
      tester,
      patternField,
      stage: 'regex-pattern-field',
      pending: 'the regex pattern field never became visible',
    );
    await tester.enterText(patternField, '(ab)*a');
    await waits.until(
      tester,
      stage: 'regex-validation',
      pending: 'regexEditorProvider never validated the pattern "(ab)*a"',
      condition: () => container.read(regexEditorProvider).isValid,
    );
    await waits.untilVisible(
      tester,
      find.text(localizations.validRegex),
      stage: 'regex-validation',
      pending: 'the validation banner never showed '
          '"${localizations.validRegex}"',
    );

    final testField = find.byKey(const ValueKey('regex_test_input_field'));
    await waits.untilVisible(
      tester,
      testField,
      stage: 'regex-test-field',
      pending: 'the regex test string field never became visible',
    );
    await tester.enterText(testField, 'aba');
    await waits.until(
      tester,
      stage: 'regex-match',
      pending: 'regexEditorProvider never reported a match for "aba"',
      condition: () {
        final state = container.read(regexEditorProvider);
        return state.hasTested && state.matches;
      },
    );
    await waits.untilVisible(
      tester,
      find.text(localizations.matches),
      stage: 'regex-match',
      pending: 'the match banner never showed "${localizations.matches}"',
    );
  }

  /// Switches to [index] and waits until the matching workspace page is laid
  /// out inside the capture viewport.
  Future<void> _showWorkspace(
    int index,
    Finder pageFinder,
    String stage,
  ) async {
    container.read(homeNavigationProvider.notifier).setIndex(index);
    await waits.until(
      tester,
      stage: '$stage-navigation',
      pending: 'homeNavigationProvider never settled on index $index',
      condition: () => container.read(homeNavigationProvider) == index,
    );
    await waits.untilVisible(
      tester,
      pageFinder,
      stage: '$stage-navigation',
      pending: 'the workspace page never became visible after navigation',
    );
    await waits.untilLoaded(tester, stage: '$stage-navigation');
  }

  /// Taps the simulation shortcut in the workspace app bar.
  Future<void> _tapSimulateAction() async {
    final finder = find.descendant(
      of: find.byType(WorkspaceQuickActionsBar),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is IconButton &&
            widget.icon is Icon &&
            (widget.icon as Icon).icon == Icons.play_arrow &&
            widget.onPressed != null,
      ),
    );
    expect(
      finder,
      findsOneWidget,
      reason: 'Expected one enabled simulation shortcut in the app bar',
    );
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await waits.quiesce(tester);
  }
}
