import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/grammar/phrase_structure/phrase_structure.dart';
import 'package:turing_lab/presentation/widgets/user_derivation_workspace.dart';

void main() {
  testWidgets('requires an exact allowed occurrence before committing a move', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final grammar = _ambiguousOccurrenceGrammar();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: UserDerivationWorkspace(
              grammar: grammar,
              target: _sequence([_t('a'), _t('a')]),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('manual-production-split')));
    await tester.pump();
    expect(find.text('Choose the exact occurrence'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('manual-occurrence-split-0')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('manual-derivation-preview')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('manual-derivation-commit')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('manual-production-leaf')),
    );
    await tester.tap(find.byKey(const ValueKey('manual-production-leaf')));
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey('manual-occurrence-leaf-1')),
    );
    await tester.tap(find.byKey(const ValueKey('manual-occurrence-leaf-1')));
    await tester.pump();
    expect(
      find.text(
        'That occurrence is not allowed by the selected derivation mode.',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('manual-derivation-preview')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('manual-occurrence-leaf-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('manual-derivation-commit')));
    await tester.pumpAndSettle();
    expect(find.textContaining('a A'), findsWidgets);
    expect(
      find.byKey(const ValueKey('manual-derivation-step-2')),
      findsOneWidget,
    );
  });

  testWidgets('supports undo, redo, bounded hints, and source invalidation', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final grammar = _simpleGrammar();
    UserDerivationDiagnosticCode? invalidation;
    late StateSetter rebuild;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return Scaffold(
              body: SingleChildScrollView(
                child: UserDerivationWorkspace(
                  grammar: grammar,
                  target: _sequence([_t('a')]),
                  invalidationCode: invalidation,
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('manual-production-to-a')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('manual-occurrence-to-a-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('manual-derivation-commit')));
    await tester.pumpAndSettle();
    expect(find.text('Target reached'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('manual-derivation-undo')),
    );
    await tester.tap(find.byKey(const ValueKey('manual-derivation-undo')));
    await tester.pump();
    expect(find.text('Choose the next derivation move.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('manual-derivation-redo')));
    await tester.pump();
    expect(find.text('Target reached'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('manual-derivation-undo')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('manual-derivation-hint')));
    for (var attempt = 0; attempt < 50; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 2)),
      );
      await tester.pump(const Duration(milliseconds: 10));
      if (find
          .byKey(const ValueKey('manual-derivation-hint-result'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }
    expect(
      find.textContaining('Search-derived suggestion: apply to-a'),
      findsOneWidget,
    );

    rebuild(() => invalidation = UserDerivationDiagnosticCode.sourceChanged);
    await tester.pump();
    expect(
      find.text('The grammar or target changed. Start a new session.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const ValueKey('manual-derivation-hint')),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('renders unrestricted multi-symbol replacements without a tree', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final grammar = UnrestrictedGrammar(
      id: 'u',
      name: 'U',
      revision: 1,
      terminals: {_t('a')},
      nonterminals: {_n('S'), _n('A')},
      startSymbol: _n('S'),
      productions: [
        _phrase('seed', [_n('S')], [_n('A'), _t('a')], 0),
        _phrase('pair', [_n('A'), _t('a')], [_t('a')], 1),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: UserDerivationWorkspace(
              grammar: grammar,
              target: _sequence([_t('a')]),
              initialMode: UserDerivationMode.unrestrictedOccurrence,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('manual-production-seed')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('manual-occurrence-seed-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('manual-derivation-commit')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('manual-production-pair')),
    );
    await tester.tap(find.byKey(const ValueKey('manual-production-pair')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('manual-occurrence-pair-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('manual-derivation-commit')));
    await tester.pumpAndSettle();

    expect(find.text('Target reached'), findsOneWidget);
    expect(find.text('Current derivation tree'), findsNothing);
  });

  testWidgets('adapts to phone width and 200 percent text', (tester) async {
    await _useTallSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 800),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              child: UserDerivationWorkspace(
                grammar: _simpleGrammar(),
                target: _sequence([_t('a')]),
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('user-derivation-workspace')),
      findsOneWidget,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('manual-production-to-a')))
          .height,
      greaterThanOrEqualTo(48),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('exposes semantics and copies a versioned structured report', (
    tester,
  ) async {
    await _useTallSurface(tester);
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UserDerivationWorkspace(
            grammar: _simpleGrammar(),
            target: _sequence([_t('a')]),
          ),
        ),
      ),
    );

    final copy = find.byTooltip('Copy structured derivation');
    expect(copy, findsOneWidget);
    expect(tester.getSize(copy).height, greaterThanOrEqualTo(48));
    await tester.tap(copy);
    await tester.pumpAndSettle();

    expect(copied, contains('"id": "${UserDerivationSession.schemaId}"'));
    expect(copied, contains('"version": 1'));
    expect(find.bySemanticsLabel(RegExp('Derive target')), findsWidgets);
  });

  testWidgets('exposes an enforced challenge mode when rules are supplied', (
    tester,
  ) async {
    await _useTallSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UserDerivationWorkspace(
            grammar: _simpleGrammar(),
            target: _sequence([_t('a')]),
            initialMode: UserDerivationMode.challengeEnforced,
            challenge: UserDerivationChallenge(
              id: 'one-step',
              enforcedMode: UserDerivationMode.leftmost,
              maxSteps: 1,
              allowedProductionIds: const {'to-a'},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Challenge rules'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _useTallSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1000, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

ContextFreeGrammar _simpleGrammar() => ContextFreeGrammar(
  id: 'cfg',
  name: 'CFG',
  revision: 1,
  terminals: {_t('a')},
  nonterminals: {_n('S')},
  startSymbol: _n('S'),
  productions: [
    ContextFreeProduction(
      id: 'to-a',
      left: _n('S'),
      right: _sequence([_t('a')]),
      order: 0,
    ),
  ],
);

ContextFreeGrammar _ambiguousOccurrenceGrammar() => ContextFreeGrammar(
  id: 'cfg',
  name: 'CFG',
  revision: 1,
  terminals: {_t('a')},
  nonterminals: {_n('S'), _n('A')},
  startSymbol: _n('S'),
  productions: [
    ContextFreeProduction(
      id: 'split',
      left: _n('S'),
      right: _sequence([_n('A'), _n('A')]),
      order: 0,
    ),
    ContextFreeProduction(
      id: 'leaf',
      left: _n('A'),
      right: _sequence([_t('a')]),
      order: 1,
    ),
  ],
);

PhraseStructureProduction _phrase(
  String id,
  List<PhraseGrammarSymbol> left,
  List<PhraseGrammarSymbol> right,
  int order,
) => PhraseStructureProduction(
  id: id,
  left: _sequence(left),
  right: _sequence(right),
  order: order,
);

GrammarSymbolSequence _sequence(List<PhraseGrammarSymbol> symbols) =>
    GrammarSymbolSequence(symbols);
TerminalGrammarSymbol _t(String value) => TerminalGrammarSymbol(value);
NonterminalGrammarSymbol _n(String value) => NonterminalGrammarSymbol(value);
