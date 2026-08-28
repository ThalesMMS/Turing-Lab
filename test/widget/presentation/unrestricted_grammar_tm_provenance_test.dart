import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/tm_to_unrestricted_grammar/tm_to_unrestricted_grammar.dart';
import 'package:turing_lab/core/grammar/phrase_structure/phrase_structure.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/pages/unrestricted_grammar_page.dart';
import 'package:turing_lab/presentation/providers/formal_extension_editor_providers.dart';
import 'package:turing_lab/presentation/providers/tm_to_grammar_provider.dart';
import 'package:turing_lab/presentation/providers/workspace_quick_actions_provider.dart';
import 'package:turing_lab/presentation/unrestricted_grammar/unrestricted_grammar_editor_controller.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  testWidgets('destination workspace retains generated production provenance', (
    tester,
  ) async {
    final state = automaton_state.State(
      id: 'q0',
      label: 'q0',
      position: Vector2.zero(),
      isInitial: true,
      isAccepting: true,
    );
    final tm = TM(
      id: 'tm-provenance',
      name: 'Provenance TM',
      states: {state},
      transitions: const {},
      alphabet: const {'a'},
      initialState: state,
      acceptingStates: {state},
      created: DateTime.utc(2026),
      modified: DateTime.utc(2026),
      bounds: const math.Rectangle(0, 0, 800, 600),
      tapeAlphabet: const {'a', 'B'},
    );
    final report = TMToGrammarConverter.build(tm, sourceRevision: 6);
    final controller = UnrestrictedGrammarEditorController(report.grammar!);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          unrestrictedGrammarEditorProvider.overrideWith((ref) => controller),
          tmToGrammarOpenedReportProvider.overrideWith((ref) => report),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: UnrestrictedGrammarPage()),
        ),
      ),
    );
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(UnrestrictedGrammarPage)),
    );
    container
        .read(
          workspaceQuickActionsProvider(
            UnrestrictedGrammarCapabilities.systemKey,
          ),
        )!
        .onEdit!();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('tm-grammar-opened-provenance')),
      findsOneWidget,
    );
    expect(find.text('TM conversion provenance'), findsOneWidget);
    expect(find.textContaining('mapped productions'), findsOneWidget);

    controller.removeProduction(controller.grammar.productions.first.id);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('tm-grammar-opened-provenance')),
      findsNothing,
    );
  });
}
