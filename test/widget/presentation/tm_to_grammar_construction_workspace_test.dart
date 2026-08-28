import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/tm_to_unrestricted_grammar/tm_to_unrestricted_grammar.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/localization/locale_value_formatter.dart';
import 'package:turing_lab/presentation/widgets/tm_to_grammar_construction_workspace.dart';
import 'package:vector_math/vector_math_64.dart';

// feature-localization-contract: advanced-tm-workspaces
// feature-localization-surface: localized-tm-to-unrestricted-grammar-workspace
void main() {
  testWidgets('shows a token-safe preview and opens its completed report', (
    tester,
  ) async {
    TMToGrammarConstructionReport? opened;
    await _pumpWorkspace(
      tester,
      tm: _immediateAcceptor(),
      onOpen: (report) async => opened = report,
    );
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('tm-grammar-production-list')),
    );

    expect(find.text('Source TM'), findsOneWidget);
    expect(find.text('Result grammar'), findsOneWidget);
    expect(find.text('Production family'), findsOneWidget);
    expect(find.textContaining('Single tape'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final open = find.byKey(const ValueKey('tm-grammar-open'));
    await tester.ensureVisible(open);
    expect(tester.getSize(open).height, greaterThanOrEqualTo(48));
    await tester.tap(open);
    await tester.pump();

    expect(opened, isNotNull);
    expect(opened!.isCompleted, isTrue);
    expect(opened!.sourceRevision, 4);
  });

  testWidgets('blocks an unsupported multi-tape machine with diagnostics', (
    tester,
  ) async {
    await _pumpWorkspace(
      tester,
      tm: _immediateAcceptor().copyWith(tapeCount: 2),
    );
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('tm-grammar-blocked')),
    );

    expect(
      find.text(
        'This TM uses features outside the supported conversion subset.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Multi-tape conversion'), findsOneWidget);
    expect(find.byKey(const ValueKey('tm-grammar-open')), findsNothing);
  });

  testWidgets('invalidates the preview when the source revision changes', (
    tester,
  ) async {
    await _pumpWorkspace(tester, tm: _immediateAcceptor(), invalidated: true);

    expect(
      find.byKey(const ValueKey('tm-grammar-invalidated')),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byKey(const ValueKey('tm-grammar-open')), findsNothing);
  });

  testWidgets('fits 320px at 200 percent text with Portuguese copy', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(320, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpWorkspace(
      tester,
      tm: _immediateAcceptor(),
      locale: const Locale('pt'),
      textScale: 2,
    );
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('tm-grammar-production-list')),
    );

    expect(
      find.text('Prévia da construção de MT para gramática irrestrita'),
      findsOneWidget,
    );
    expect(find.text('MT de origem'), findsOneWidget);
    expect(find.text('Gramática resultante'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final locale in const [Locale('en'), Locale('pt', 'BR')]) {
    testWidgets('groups TM-to-grammar counts for ${locale.languageCode}', (
      tester,
    ) async {
      final tm = _largeCountAcceptor();
      final expected = TMToGrammarConverter.build(tm, sourceRevision: 4);
      expect(expected.isCompleted, isTrue);
      final grammar = expected.grammar!;
      final formatter = LocaleValueFormatter(locale);

      await _pumpWorkspace(tester, tm: tm, locale: locale);
      await _pumpUntilFound(
        tester,
        find.byKey(const ValueKey('tm-grammar-production-list')),
      );

      final productionLabel = locale.languageCode == 'pt'
          ? 'Produções'
          : 'Productions';
      final variableLabel = locale.languageCode == 'pt'
          ? 'Variáveis'
          : 'Variables';
      expect(
        find.text(
          '$productionLabel: ${formatter.integer(grammar.productions.length)}',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          '$variableLabel: ${formatter.integer(grammar.nonterminals.length)}',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final scenario in const [
    (locale: Locale('en'), family: 'Initialization'),
    (locale: Locale('pt', 'BR'), family: 'Inicialização'),
  ]) {
    testWidgets('localizes TM-to-grammar production families in '
        '${scenario.locale.languageCode} at narrow high text scale', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(320, 900)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();

      await _pumpWorkspace(
        tester,
        tm: _immediateAcceptor(),
        locale: scenario.locale,
        textScale: 2,
      );
      await _pumpUntilFound(
        tester,
        find.byKey(const ValueKey('tm-grammar-production-list')),
      );

      expect(find.text(scenario.family), findsWidgets);
      expect(
        tester.getSemantics(find.text(scenario.family).first).label,
        contains(scenario.family),
      );
      expect(find.text('initialization'), findsNothing);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }
}

Future<void> _pumpWorkspace(
  WidgetTester tester, {
  required TM tm,
  bool invalidated = false,
  Locale locale = const Locale('en'),
  double textScale = 1,
  Future<void> Function(TMToGrammarConstructionReport report)? onOpen,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: TMToGrammarConstructionWorkspace(
            tm: tm,
            sourceRevision: 4,
            invalidated: invalidated,
            onOpen: onOpen ?? (_) async {},
            onCancel: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 2)),
    );
    await tester.pump(const Duration(milliseconds: 10));
  }
  fail('Timed out waiting for $finder');
}

TM _immediateAcceptor() {
  final initial = automaton_state.State(
    id: 'q0',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
    isAccepting: true,
  );
  return TM(
    id: 'tm-workspace',
    name: 'Token-safe TM',
    states: {initial},
    transitions: const {},
    alphabet: const {'token', 'Ω'},
    initialState: initial,
    acceptingStates: {initial},
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
    bounds: const math.Rectangle(0, 0, 800, 600),
    tapeAlphabet: const {'token', 'Ω', 'B'},
  );
}

TM _largeCountAcceptor() {
  final initial = automaton_state.State(
    id: 'q0',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );
  final accepting = automaton_state.State(
    id: 'q1',
    label: 'q1',
    position: Vector2(120, 0),
    isAccepting: true,
  );
  final inputAlphabet = {
    for (var index = 0; index < 16; index++)
      't${index.toString().padLeft(2, '0')}',
  };
  final tapeAlphabet = {...inputAlphabet, 'B', 'X', 'Y'};
  final transition = TMTransition(
    id: 'step-right',
    fromState: initial,
    toState: accepting,
    label: 'B/B,R',
    readSymbol: 'B',
    writeSymbol: 'B',
    direction: TapeDirection.right,
  );
  return TM(
    id: 'tm-large-counts',
    name: 'Large-count TM',
    states: {initial, accepting},
    transitions: {transition},
    alphabet: inputAlphabet,
    initialState: initial,
    acceptingStates: {accepting},
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
    bounds: const math.Rectangle(0, 0, 800, 600),
    tapeAlphabet: tapeAlphabet,
  );
}
