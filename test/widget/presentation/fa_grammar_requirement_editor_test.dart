import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/manual_conversions/manual_conversion_content.dart';
import 'package:turing_lab/core/manual_conversions/manual_conversion_session.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/fa_grammar_requirement_editor.dart';

void main() {
  testWidgets('maps a source state with labelled keyboard input', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    Map<String, Object?>? submitted;
    await _pumpEditor(
      tester,
      requirement: _requirement(
        type: ManualConversionActionType.mapState,
        payload: const {'stateId': 'q0', 'nonterminal': 'A0'},
        provenanceIds: const ['q0'],
      ),
      onSubmit: (payload) => submitted = payload,
    );

    expect(find.text('q0'), findsWidgets);
    final field = find.byKey(const ValueKey('fa-grammar-nonterminal'));
    final fieldSemantics = tester.getSemantics(field);
    expect(fieldSemantics.label, contains('Nonterminal'));
    expect(fieldSemantics.flagsCollection.isTextField, isTrue);
    final buttonSemantics = tester.getSemantics(
      find.byKey(const ValueKey('fa-grammar-submit-step')),
    );
    expect(buttonSemantics.flagsCollection.isButton, isTrue);

    await tester.tap(find.byKey(const ValueKey('fa-grammar-submit-step')));
    await tester.pump();
    final editableText = find.descendant(
      of: field,
      matching: find.byType(EditableText),
    );
    expect(
      tester.widget<EditableText>(editableText).focusNode.hasFocus,
      isTrue,
    );
    expect(find.text('Enter a nonterminal.'), findsOneWidget);

    await tester.enterText(field, 'A0');
    await tester.tap(find.byKey(const ValueKey('fa-grammar-submit-step')));

    expect(submitted, {'stateId': 'q0', 'nonterminal': 'A0'});
    semantics.dispose();
  });

  testWidgets('maps a source nonterminal to a state ID', (tester) async {
    Map<String, Object?>? submitted;
    await _pumpEditor(
      tester,
      requirement: _requirement(
        type: ManualConversionActionType.mapNonterminal,
        payload: const {'nonterminal': 'S', 'stateId': 'S'},
        provenanceIds: const ['S'],
      ),
      onSubmit: (payload) => submitted = payload,
    );

    await tester.enterText(
      find.byKey(const ValueKey('fa-grammar-state-id')),
      'S',
    );
    await tester.tap(find.byKey(const ValueKey('fa-grammar-submit-step')));

    expect(submitted, {'nonterminal': 'S', 'stateId': 'S'});
  });

  testWidgets('builds a production from symbol fields instead of JSON', (
    tester,
  ) async {
    Map<String, Object?>? submitted;
    await _pumpEditor(
      tester,
      requirement: _requirement(
        type: ManualConversionActionType.addProduction,
        payload: const {
          'sourceTransitionIds': ['edge-a'],
          'production': {
            'leftSide': ['A0'],
            'rightSide': ['a', 'A1'],
            'isEpsilon': false,
          },
        },
        provenanceIds: const ['edge-a'],
      ),
      onSubmit: (payload) => submitted = payload,
    );

    expect(find.text('edge-a'), findsWidgets);
    await tester.enterText(
      find.byKey(const ValueKey('fa-grammar-production-left')),
      'A0',
    );
    await tester.enterText(
      find.byKey(const ValueKey('fa-grammar-production-right')),
      'a A1',
    );
    await tester.tap(find.byKey(const ValueKey('fa-grammar-submit-step')));

    expect(submitted, {
      'sourceTransitionIds': ['edge-a'],
      'production': {
        'leftSide': ['A0'],
        'rightSide': ['a', 'A1'],
        'isEpsilon': false,
      },
    });
  });

  testWidgets('builds a typed transition and accepting destination', (
    tester,
  ) async {
    Map<String, Object?>? submitted;
    await _pumpEditor(
      tester,
      requirement: _requirement(
        type: ManualConversionActionType.addTransition,
        payload: const {
          'sourceProductionIds': ['p0'],
          'transition': {
            'fromStateId': 'S',
            'toStateId': 'accept',
            'inputSymbol': 'a',
            'isEpsilon': false,
            'toStateIsAccepting': true,
          },
        },
        provenanceIds: const ['p0'],
      ),
      onSubmit: (payload) => submitted = payload,
    );

    await tester.enterText(
      find.byKey(const ValueKey('fa-grammar-transition-from')),
      'S',
    );
    await tester.enterText(
      find.byKey(const ValueKey('fa-grammar-transition-to')),
      'accept',
    );
    await tester.tap(find.byKey(const ValueKey('fa-grammar-transition-kind')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Input symbol').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('fa-grammar-transition-symbol')),
      'a',
    );
    await tester.tap(
      find.byKey(const ValueKey('fa-grammar-transition-accepting')),
    );
    await tester.tap(find.byKey(const ValueKey('fa-grammar-submit-step')));

    expect(submitted, {
      'sourceProductionIds': ['p0'],
      'transition': {
        'fromStateId': 'S',
        'toStateId': 'accept',
        'inputSymbol': 'a',
        'isEpsilon': false,
        'toStateIsAccepting': true,
      },
    });
  });

  testWidgets('builds an epsilon transition without a symbol field', (
    tester,
  ) async {
    Map<String, Object?>? submitted;
    await _pumpEditor(
      tester,
      requirement: _requirement(
        type: ManualConversionActionType.addTransition,
        payload: const {
          'sourceProductionIds': ['unit'],
          'transition': {
            'fromStateId': 'S',
            'toStateId': 'A',
            'inputSymbol': '',
            'isEpsilon': true,
            'toStateIsAccepting': false,
          },
        },
        provenanceIds: const ['unit'],
      ),
      onSubmit: (payload) => submitted = payload,
    );

    await tester.enterText(
      find.byKey(const ValueKey('fa-grammar-transition-from')),
      'S',
    );
    await tester.enterText(
      find.byKey(const ValueKey('fa-grammar-transition-to')),
      'A',
    );
    await tester.tap(find.byKey(const ValueKey('fa-grammar-transition-kind')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Epsilon (ε)').last);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('fa-grammar-transition-symbol')),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('fa-grammar-submit-step')));

    expect(submitted, {
      'sourceProductionIds': ['unit'],
      'transition': {
        'fromStateId': 'S',
        'toStateId': 'A',
        'inputSymbol': '',
        'isEpsilon': true,
        'toStateIsAccepting': false,
      },
    });
  });

  testWidgets('requires explicit acceptance and emits the typed marker', (
    tester,
  ) async {
    Map<String, Object?>? submitted;
    await _pumpEditor(
      tester,
      requirement: _requirement(
        type: ManualConversionActionType.markAccepting,
        payload: const {
          'sourceProductionIds': ['epsilon'],
          'stateId': 'S',
          'isAccepting': true,
        },
        provenanceIds: const ['epsilon'],
      ),
      onSubmit: (payload) => submitted = payload,
    );

    await tester.enterText(
      find.byKey(const ValueKey('fa-grammar-state-id')),
      'S',
    );
    await tester.tap(find.byKey(const ValueKey('fa-grammar-submit-step')));
    await tester.pump();
    expect(submitted, isNull);
    expect(
      find.text('Select accepting before checking this step.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('fa-grammar-mark-accepting')));
    await tester.tap(find.byKey(const ValueKey('fa-grammar-submit-step')));
    expect(submitted, {
      'sourceProductionIds': ['epsilon'],
      'stateId': 'S',
      'isAccepting': true,
    });
  });

  testWidgets('renders epsilon production controls at 200 percent text scale', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpEditor(
      tester,
      textScaler: const TextScaler.linear(2),
      requirement: _requirement(
        type: ManualConversionActionType.markEpsilon,
        payload: const {
          'stateId': 'q0',
          'production': {
            'leftSide': ['A0'],
            'rightSide': <String>[],
            'isEpsilon': true,
          },
        },
        provenanceIds: const ['q0'],
      ),
      onSubmit: (_) {},
    );

    expect(find.text('ε'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

ManualConversionRequirement _requirement({
  required ManualConversionActionType type,
  required Map<String, Object?> payload,
  required List<String> provenanceIds,
}) {
  return ManualConversionRequirement(
    id: 'requirement-${type.name}',
    contentReference: ManualConversionContent.legacy,
    type: type,
    title: 'Build correspondence',
    instruction: 'Build the expected correspondence.',
    expectedPayload: payload,
    allowedPayloadKeys: payload.keys,
    provenanceIds: provenanceIds,
    hint: 'Read the source entity.',
    revealExplanation: 'The correspondence is canonical.',
    evidence: ManualConversionEvidence(summary: 'Structurally valid.'),
  );
}

Future<void> _pumpEditor(
  WidgetTester tester, {
  required ManualConversionRequirement requirement,
  required ValueChanged<Map<String, Object?>> onSubmit,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(textScaler: textScaler),
        child: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: FaGrammarRequirementEditor(
              requirement: requirement,
              onSubmit: onSubmit,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
