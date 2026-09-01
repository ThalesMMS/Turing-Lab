import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/manual_conversions/manual_conversion_content.dart';
import 'package:turing_lab/core/manual_conversions/manual_conversion_session.dart';
import 'package:turing_lab/core/utils/epsilon_utils.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/empty_string_notation.dart';
import 'package:turing_lab/presentation/widgets/fa_to_regex_requirement_editor.dart';

// feature-localization-contract: automata-conversions-and-fragments
// feature-localization-surface: localized-editor-fields
// feature-localization-surface: formal-content-preservation
// feature-localization-surface: responsive-accessibility
void main() {
  testWidgets('localizes FA-to-Regex editor controls in Portuguese', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
    });
    try {
      Map<String, Object?>? submitted;
      await _pumpEditor(
        tester,
        locale: const Locale('pt', 'BR'),
        requirement: _requirement(
          type: ManualConversionActionType.complete,
          payload: const {'regex': 'ab'},
        ),
        onSubmit: (payload) => submitted = payload,
        textScaler: const TextScaler.linear(2),
      );

      expect(
        find.bySemanticsLabel('Entrada da etapa de AF para expressão regular'),
        findsOneWidget,
      );
      expect(find.text('Expressão regular final'), findsOneWidget);
      expect(
        find.text('Informe uma expressão equivalente ao autômato de origem.'),
        findsOneWidget,
      );
      expect(find.text('Verificar etapa'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('fa-to-regex-final-expression')),
        '(ab)',
      );
      await tester.tap(find.byKey(const ValueKey('fa-to-regex-submit-step')));
      expect(submitted, {'regex': '(ab)'});
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('selects any eliminable state with a labelled dropdown', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    Map<String, Object?>? submitted;
    await _pumpEditor(
      tester,
      requirement: _requirement(
        type: ManualConversionActionType.selectState,
        payload: const {'stateId': 'q0'},
        acceptedPayloads: const [
          {'stateId': 'q0'},
          {'stateId': 'q1'},
        ],
        supportingData: const {
          'eliminableStateIds': ['q0', 'q1'],
          'protectedStateIds': ['gnfa:start', 'gnfa:final'],
        },
      ),
      onSubmit: (payload) => submitted = payload,
    );

    final dropdown = find.byKey(const ValueKey('fa-to-regex-state'));
    expect(tester.getSemantics(dropdown).label, contains('State to eliminate'));
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('q1').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('fa-to-regex-submit-step')));

    expect(submitted, {'stateId': 'q1'});
    semantics.dispose();
  });

  testWidgets(
    'shows pair terms without revealing the answer and submits text',
    (tester) async {
      Map<String, Object?>? submitted;
      await _pumpEditor(
        tester,
        requirement: _requirement(
          type: ManualConversionActionType.submitPairExpression,
          payload: const {
            'fromStateId': 'q0',
            'toStateId': 'q2',
            'expression': 'a(b)*c',
          },
          supportingData: const {
            'selectedStateId': 'q1',
            'fromStateId': 'q0',
            'toStateId': 'q2',
            'directExpression': '∅',
            'incomingExpression': 'a',
            'loopExpression': 'b',
            'outgoingExpression': 'c',
            'formula': 'R_ij ∪ R_ik(R_kk)*R_kj',
          },
        ),
        onSubmit: (payload) => submitted = payload,
      );

      expect(find.text('R_ij ∪ R_ik(R_kk)*R_kj'), findsOneWidget);
      expect(find.text('R_ik = a'), findsOneWidget);
      expect(find.text('R_kk = b'), findsOneWidget);
      expect(find.text('a(b)*c'), findsNothing);

      final field = find.byKey(const ValueKey('fa-to-regex-pair-expression'));
      await tester.enterText(field, 'a((b)*)c');
      await tester.tap(find.byKey(const ValueKey('fa-to-regex-submit-step')));

      expect(submitted, {
        'fromStateId': 'q0',
        'toStateId': 'q2',
        'expression': 'a((b)*)c',
      });
    },
  );

  testWidgets('formats empty pair operands without changing other terms', (
    tester,
  ) async {
    await _pumpEditor(
      tester,
      emptyStringSymbol: kLambdaSymbol,
      requirement: _requirement(
        type: ManualConversionActionType.submitPairExpression,
        payload: const {
          'fromStateId': 'q0',
          'toStateId': 'q2',
          'expression': 'λ',
        },
        supportingData: const {
          'fromStateId': 'q0',
          'toStateId': 'q2',
          'directExpression': 'ε',
          'incomingExpression': 'a',
          'loopExpression': 'ε',
          'outgoingExpression': 'c',
        },
      ),
      onSubmit: (_) {},
    );

    expect(find.text('R_ij = λ'), findsOneWidget);
    expect(find.text('R_ik = a'), findsOneWidget);
    expect(find.text('R_kk = λ'), findsOneWidget);
    expect(find.text('R_kj = c'), findsOneWidget);
  });

  testWidgets('renders semantic commit and final-expression controls', (
    tester,
  ) async {
    Map<String, Object?>? committed;
    await _pumpEditor(
      tester,
      requirement: _requirement(
        type: ManualConversionActionType.commitElimination,
        payload: const {'stateId': 'q1', 'pairCount': 2},
        supportingData: const {'stateId': 'q1', 'pairCount': 2},
      ),
      onSubmit: (payload) => committed = payload,
    );

    expect(find.text('q1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('fa-to-regex-submit-step')));
    expect(committed, {'stateId': 'q1', 'pairCount': 2});

    Map<String, Object?>? completed;
    await _pumpEditor(
      tester,
      requirement: _requirement(
        type: ManualConversionActionType.complete,
        payload: const {'regex': 'ab'},
      ),
      onSubmit: (payload) => completed = payload,
    );
    await tester.enterText(
      find.byKey(const ValueKey('fa-to-regex-final-expression')),
      '(ab)',
    );
    await tester.tap(find.byKey(const ValueKey('fa-to-regex-submit-step')));
    expect(completed, {'regex': '(ab)'});
  });
}

ManualConversionRequirement _requirement({
  required ManualConversionActionType type,
  required Map<String, Object?> payload,
  List<Map<String, Object?>> acceptedPayloads = const [],
  Map<String, Object?> supportingData = const {},
}) {
  return ManualConversionRequirement(
    id: 'fa-to-regex-${type.name}',
    contentReference: ManualConversionContent.legacy,
    type: type,
    title: 'Build the next GNFA step',
    instruction: 'Complete this state-elimination step.',
    expectedPayload: payload,
    acceptedPayloads: acceptedPayloads,
    allowedPayloadKeys: payload.keys,
    supportingData: supportingData,
    hint: 'Inspect the current GNFA.',
    revealExplanation: 'The canonical result is available on reveal.',
    evidence: ManualConversionEvidence(summary: 'Exact GNFA step.'),
  );
}

Future<void> _pumpEditor(
  WidgetTester tester, {
  required ManualConversionRequirement requirement,
  required ValueChanged<Map<String, Object?>> onSubmit,
  Locale locale = const Locale('en'),
  TextScaler textScaler = TextScaler.noScaling,
  String emptyStringSymbol = kEpsilonSymbol,
}) async {
  await tester.pumpWidget(
    EmptyStringNotation(
      symbol: emptyStringSymbol,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(textScaler: textScaler),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: FaToRegexRequirementEditor(
                key: ValueKey(requirement.id),
                requirement: requirement,
                onSubmit: onSubmit,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
