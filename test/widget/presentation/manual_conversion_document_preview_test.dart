import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/manual_conversion_document_preview.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  testWidgets('renders a nested learner FSA as a semantic preview', (
    tester,
  ) async {
    final fsa = FSA.twoState(
      id: 'learner-fsa',
      name: 'Learner automaton',
      fromStateId: 'q0',
      toStateId: 'q1',
      symbol: 'a',
      fromPosition: Vector2.zero(),
      toPosition: Vector2(120, 0),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ManualConversionDocumentPreview.artifact({
            'kind': 'fsa',
            'document': fsa.toJson(),
          }),
        ),
      ),
    );

    expect(find.text('Learner automaton'), findsOneWidget);
    expect(find.textContaining('q0 [q0; initial]'), findsOneWidget);
    expect(find.textContaining('q1 [q1; accepting]'), findsOneWidget);
    expect(find.textContaining('q0 → q1: a [t1]'), findsOneWidget);
    expect(find.textContaining('"document"'), findsNothing);
  });

  testWidgets('renders an intermediate GNFA without exposing JSON', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ManualConversionDocumentPreview.artifact(const {
            'schema': 'turing-lab.fa-to-regex-learner',
            'gnfa': {
              'revision': 3,
              'startStateId': 'start',
              'finalStateId': 'final',
              'states': [
                {'id': 'start', 'label': 'Start', 'isProtected': true},
                {'id': 'q0', 'label': 'q0', 'isProtected': false},
                {'id': 'final', 'label': 'Final', 'isProtected': true},
              ],
              'labels': [
                {'fromStateId': 'start', 'toStateId': 'q0', 'expression': 'ε'},
              ],
            },
            'selectedStateId': 'q0',
          }),
        ),
      ),
    );

    expect(find.text('GNFA revision 3'), findsOneWidget);
    expect(
      find.textContaining('Start [start; protected start]'),
      findsOneWidget,
    );
    expect(find.textContaining('start → q0: ε'), findsOneWidget);
    expect(find.textContaining('Selected state: q0'), findsOneWidget);
    expect(find.textContaining('"gnfa"'), findsNothing);
  });

  testWidgets('renders a partial grammar learner artifact without JSON', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ManualConversionDocumentPreview.artifact(const {
            'kind': 'grammar',
            'orientation': 'rightLinear',
            'stateToNonterminal': {'q0': 'S'},
            'productions': [
              {
                'leftSide': ['S'],
                'rightSide': ['a', 'A'],
                'isEpsilon': false,
              },
            ],
            'document': null,
          }),
        ),
      ),
    );

    expect(find.text('Learner grammar'), findsOneWidget);
    expect(find.text('State mappings: q0 → S'), findsOneWidget);
    expect(find.text('S → a A'), findsOneWidget);
    expect(find.textContaining('"productions"'), findsNothing);
  });

  testWidgets('localizes conversion labels while preserving FSA data', (
    tester,
  ) async {
    final fsa = FSA.twoState(
      id: 'learner-fsa-pt',
      name: 'Learner automaton',
      fromStateId: 'q0',
      toStateId: 'q1',
      symbol: 'a',
      fromPosition: Vector2.zero(),
      toPosition: Vector2(120, 0),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: ManualConversionDocumentPreview.fsa(fsa)),
      ),
    );

    expect(find.textContaining('Estados: q0 [q0; inicial]'), findsOneWidget);
    expect(find.textContaining('q1 [q1; de aceitação]'), findsOneWidget);
    expect(find.textContaining('Alfabeto: a'), findsOneWidget);
    expect(find.textContaining('States:'), findsNothing);
    expect(find.textContaining('Alphabet:'), findsNothing);
    expect(find.textContaining('q0 → q1: a [t1]'), findsOneWidget);
  });

  testWidgets('localizes learner grammar and empty GNFA messages', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ManualConversionDocumentPreview.grammar(
            Grammar(
              id: 'grammar-pt',
              name: 'Learner grammar',
              terminals: {'a'},
              nonterminals: {'S', 'A'},
              startSymbol: 'S',
              productions: {
                const Production(
                  id: 'p1',
                  leftSide: ['S'],
                  rightSide: ['a', 'A'],
                ),
              },
              type: GrammarType.contextFree,
              created: DateTime.utc(2025),
              modified: DateTime.utc(2025),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Learner grammar'), findsOneWidget);
    expect(find.text('Início: S'), findsOneWidget);
    expect(find.text('Não terminais: A, S'), findsOneWidget);
    expect(find.text('Terminais: a'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ManualConversionDocumentPreview.artifact(const {
            'kind': 'grammar',
            'stateToNonterminal': {'q0': 'S'},
            'productions': [
              {
                'leftSide': ['S'],
                'rightSide': ['a'],
                'isEpsilon': false,
              },
            ],
          }),
        ),
      ),
    );
    expect(find.text('Gramática do aprendiz'), findsOneWidget);
    expect(find.text('Mapeamentos de estados: q0 → S'), findsOneWidget);
    expect(find.text('State mappings: q0 → S'), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ManualConversionDocumentPreview.artifact(const {
            'schema': 'turing-lab.fa-to-regex-learner',
            'gnfa': {
              'revision': 2,
              'startStateId': 'start',
              'finalStateId': 'final',
              'states': [],
              'labels': [],
            },
          }),
        ),
      ),
    );
    expect(find.text('Revisão do GNFA 2'), findsOneWidget);
    expect(find.text('O GNFA salvo não possui estados.'), findsOneWidget);
    expect(find.text('The saved GNFA has no states.'), findsNothing);
  });
}
