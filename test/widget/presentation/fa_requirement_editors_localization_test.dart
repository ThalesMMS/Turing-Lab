import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/manual_conversions/manual_conversion_content.dart';
import 'package:turing_lab/core/manual_conversions/manual_conversion_session.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/fa_grammar_requirement_editor.dart';
import 'package:turing_lab/presentation/widgets/fa_to_regex_requirement_editor.dart';

void main() {
  testWidgets('localizes both editor surfaces and semantics in EN and PT', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pump(
        tester,
        locale: const Locale('en'),
        child: FaGrammarRequirementEditor(
          requirement: _faGrammarRequirement(),
          onSubmit: (_) {},
        ),
      );

      expect(find.bySemanticsLabel('Step input'), findsOneWidget);
      expect(find.text('Nonterminal'), findsOneWidget);
      expect(
        tester
            .getSemantics(find.byKey(const ValueKey('fa-grammar-nonterminal')))
            .label,
        contains('Nonterminal'),
      );
      expect(
        tester
            .getSemantics(find.byKey(const ValueKey('fa-grammar-submit-step')))
            .label,
        contains('Check step'),
      );
      expect(find.text('q0'), findsWidgets);

      await _pump(
        tester,
        locale: const Locale('pt', 'BR'),
        child: FaGrammarRequirementEditor(
          requirement: _faGrammarEpsilonRequirement(),
          onSubmit: (_) {},
        ),
      );

      expect(find.text('Não terminal do lado esquerdo'), findsOneWidget);
      expect(find.text('Lado direito'), findsOneWidget);

      await _pump(
        tester,
        locale: const Locale('pt', 'BR'),
        child: FaGrammarRequirementEditor(
          requirement: _faGrammarRequirement(),
          onSubmit: (_) {},
        ),
      );

      expect(find.bySemanticsLabel('Entrada da etapa'), findsOneWidget);
      expect(find.text('Não terminal'), findsOneWidget);
      expect(
        tester
            .getSemantics(find.byKey(const ValueKey('fa-grammar-nonterminal')))
            .label,
        contains('Não terminal'),
      );
      expect(
        tester
            .getSemantics(find.byKey(const ValueKey('fa-grammar-submit-step')))
            .label,
        contains('Verificar etapa'),
      );
      expect(find.text('q0'), findsWidgets);

      await _pump(
        tester,
        locale: const Locale('en'),
        child: FaToRegexRequirementEditor(
          requirement: _faToRegexRequirement(),
          onSubmit: (_) {},
        ),
      );

      expect(find.bySemanticsLabel('FA to Regex step input'), findsOneWidget);
      expect(
        tester
            .getSemantics(find.byKey(const ValueKey('fa-to-regex-state')))
            .label,
        contains('State to eliminate'),
      );
      expect(
        find.text('Protected start and final states cannot be eliminated.'),
        findsOneWidget,
      );

      await _pump(
        tester,
        locale: const Locale('pt', 'BR'),
        child: FaToRegexRequirementEditor(
          requirement: _faToRegexRequirement(),
          onSubmit: (_) {},
        ),
      );

      expect(
        find.bySemanticsLabel('Entrada da etapa de AF para expressão regular'),
        findsOneWidget,
      );
      expect(
        tester
            .getSemantics(find.byKey(const ValueKey('fa-to-regex-state')))
            .label,
        contains('Estado a eliminar'),
      );
      expect(
        find.text(
          'Os estados inicial e final protegidos não podem ser eliminados.',
        ),
        findsOneWidget,
      );
    } finally {
      semantics.dispose();
    }
  });
}

ManualConversionRequirement _faGrammarRequirement() =>
    ManualConversionRequirement(
      id: 'fa-grammar-map-state-localization',
      contentReference: ManualConversionContent.legacy,
      type: ManualConversionActionType.mapState,
      title: 'Build correspondence',
      instruction: 'Build the expected correspondence.',
      expectedPayload: {'stateId': 'q0', 'nonterminal': 'A0'},
      allowedPayloadKeys: {'stateId', 'nonterminal'},
      provenanceIds: ['q0'],
      hint: 'Read the source entity.',
      revealExplanation: 'The correspondence is canonical.',
      evidence: ManualConversionEvidence(summary: 'Structurally valid.'),
    );

ManualConversionRequirement _faToRegexRequirement() =>
    ManualConversionRequirement(
      id: 'fa-to-regex-select-state-localization',
      contentReference: ManualConversionContent.legacy,
      type: ManualConversionActionType.selectState,
      title: 'Build the next GNFA step',
      instruction: 'Complete this state-elimination step.',
      expectedPayload: {'stateId': 'q1'},
      allowedPayloadKeys: {'stateId'},
      acceptedPayloads: [
        {'stateId': 'q1'},
      ],
      supportingData: {
        'eliminableStateIds': ['q1'],
        'protectedStateIds': ['gnfa:start', 'gnfa:final'],
      },
      hint: 'Inspect the current GNFA.',
      revealExplanation: 'The canonical result is available on reveal.',
      evidence: ManualConversionEvidence(summary: 'Exact GNFA step.'),
    );

ManualConversionRequirement _faGrammarEpsilonRequirement() =>
    ManualConversionRequirement(
      id: 'fa-grammar-mark-epsilon-localization',
      contentReference: ManualConversionContent.legacy,
      type: ManualConversionActionType.markEpsilon,
      title: 'Build correspondence',
      instruction: 'Build the expected correspondence.',
      expectedPayload: const {
        'stateId': 'q0',
        'production': {
          'leftSide': ['A0'],
          'rightSide': <String>[],
          'isEpsilon': true,
        },
      },
      allowedPayloadKeys: const {'stateId', 'production'},
      provenanceIds: const ['q0'],
      hint: 'Read the source entity.',
      revealExplanation: 'The correspondence is canonical.',
      evidence: ManualConversionEvidence(summary: 'Structurally valid.'),
    );

Future<void> _pump(
  WidgetTester tester, {
  required Locale locale,
  required Widget child,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
