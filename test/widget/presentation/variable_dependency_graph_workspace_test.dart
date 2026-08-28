import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/grammar/phrase_structure/phrase_structure.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/variable_dependency_graph_workspace.dart';
import 'package:turing_lab/presentation/widgets/export/variable_dependency_export_service.dart';

// feature-localization-surface: localized-export-picker-titles
void main() {
  testWidgets('switches modes and synchronizes edge provenance selection', (
    tester,
  ) async {
    await _useSurface(tester);
    await _pumpContextFree(tester);

    expect(find.byKey(const ValueKey('vdg-viewport')), findsOneWidget);
    expect(find.text('S → A (2)'), findsOneWidget);
    await tester.tap(find.text('S → A (2)'));
    await tester.pump();
    expect(find.textContaining('p1:'), findsOneWidget);
    expect(find.textContaining('RHS position 1'), findsNWidgets(2));

    await tester.tap(find.byKey(const ValueKey('vdg-mode')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nullable-aware left corner').last);
    await _waitForAnalysis(tester);
    expect(find.text('S → B (1)'), findsOneWidget);
  });

  testWidgets('supports keyboard navigation, zoom, layout, and semantics', (
    tester,
  ) async {
    await _useSurface(tester);
    await _pumpContextFree(tester);

    final viewport = find.byKey(const ValueKey('vdg-viewport'));
    await tester.tap(viewport);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(find.byKey(const ValueKey('vdg-variable-details')), findsOneWidget);
    expect(find.text('Reachability witness: S → A'), findsOneWidget);
    expect(find.text('Productions: p1, p3'), findsOneWidget);

    final zoom = find.byKey(const ValueKey('vdg-zoom-in'));
    expect(tester.getSize(zoom), const Size(48, 48));
    await tester.tap(zoom);
    await tester.tap(find.byKey(const ValueKey('vdg-fit')));
    await tester.tap(find.byKey(const ValueKey('vdg-layout')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Circular').last);
    await tester.pump();
    expect(tester.takeException(), isNull);

    final semantics = tester.getSemantics(viewport);
    expect(semantics.label, contains('variables'));
    expect(semantics.label, contains('dependency edges'));
  });

  testWidgets('exports labeled SVG and rendered PNG through the save service', (
    tester,
  ) async {
    await _useSurface(tester);
    final service = _RecordingExportService();
    await _pumpContextFree(tester, exportService: service);

    await tester.tap(find.byKey(const ValueKey('vdg-export-svg')));
    await tester.pumpAndSettle();
    expect(service.svg, contains('<svg'));
    expect(service.svg, contains('<desc'));
    expect(service.svg, contains('data-production-ids'));
    expect(service.svgDialogTitle, 'Export SVG');

    await tester.tap(find.byKey(const ValueKey('vdg-export-png')));
    for (var attempt = 0; attempt < 30 && service.png == null; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(service.png, isNotNull);
    expect(service.png, isNotEmpty);
    expect(service.pngDialogTitle, 'Export PNG');
  });

  testWidgets('uses the current locale for semantics and SVG descriptions', (
    tester,
  ) async {
    await _useSurface(tester);
    final service = _RecordingExportService();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: VariableDependencyGraphWorkspace.contextFree(
              grammar: _grammar(),
              sourceRevision: 2,
              exportService: service,
            ),
          ),
        ),
      ),
    );
    await _waitForAnalysis(tester);

    final semantics = tester.getSemantics(
      find.byKey(const ValueKey('vdg-viewport')),
    );
    expect(semantics.label, contains('variáveis'));
    expect(semantics.label, contains('arestas de dependência'));

    await tester.tap(find.byKey(const ValueKey('vdg-export-svg')));
    await tester.pumpAndSettle();
    expect(service.svg, contains('variáveis'));
    expect(service.svg, contains('arestas de dependência'));
    expect(service.svgDialogTitle, 'Exportar SVG');

    await tester.tap(find.byKey(const ValueKey('vdg-export-png')));
    for (var attempt = 0; attempt < 30 && service.png == null; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(service.png, isNotNull);
    expect(service.pngDialogTitle, 'Exportar PNG');
  });

  testWidgets(
    'invalidates stale source revisions instead of recomputing them',
    (tester) async {
      await _useSurface(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VariableDependencyGraphWorkspace.contextFree(
                grammar: _grammar(),
                sourceRevision: 2,
                invalidated: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('vdg-invalidated')), findsOneWidget);
      expect(find.byKey(const ValueKey('vdg-viewport')), findsNothing);
      expect(
        find.textContaining(
          'Reopen the graph to analyze the current revision.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('gates unrestricted graphs and fits phone width at 200 percent', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 1500));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final grammar = UnrestrictedGrammar(
      id: 'u',
      name: 'Unrestricted',
      revision: 1,
      terminals: {const TerminalGrammarSymbol('a')},
      nonterminals: {
        const NonterminalGrammarSymbol('S'),
        const NonterminalGrammarSymbol('A'),
      },
      startSymbol: const NonterminalGrammarSymbol('S'),
      productions: [
        PhraseStructureProduction(
          id: 'pair',
          order: 0,
          left: GrammarSymbolSequence(const [
            NonterminalGrammarSymbol('S'),
            TerminalGrammarSymbol('a'),
          ]),
          right: GrammarSymbolSequence(const [NonterminalGrammarSymbol('A')]),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: VariableDependencyGraphWorkspace.unrestricted(
                grammar: grammar,
                exportService: _RecordingExportService(),
              ),
            ),
          ),
        ),
      ),
    );
    await _waitForAnalysis(tester);

    await tester.tap(find.byKey(const ValueKey('vdg-mode')));
    await tester.pumpAndSettle();
    expect(find.text('Left corner'), findsNothing);
    await tester.tapAt(const Offset(5, 5));
    await tester.pump();
    expect(find.textContaining('Nonproductive:'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpContextFree(
  WidgetTester tester, {
  VariableDependencyExportService? exportService,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: VariableDependencyGraphWorkspace.contextFree(
            grammar: _grammar(),
            sourceRevision: 2,
            exportService: exportService,
          ),
        ),
      ),
    ),
  );
  await _waitForAnalysis(tester);
}

Future<void> _waitForAnalysis(WidgetTester tester) async {
  for (var attempt = 0; attempt < 60; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 3)),
    );
    await tester.pump(const Duration(milliseconds: 10));
    if (find.byKey(const ValueKey('vdg-viewport')).evaluate().isNotEmpty ||
        find.byKey(const ValueKey('vdg-invalidated')).evaluate().isNotEmpty) {
      return;
    }
    final error = find.byKey(const ValueKey('vdg-error'));
    if (error.evaluate().isNotEmpty) {
      final messages = tester
          .widgetList<Text>(
            find.descendant(of: error, matching: find.byType(Text)),
          )
          .map((widget) => widget.data)
          .whereType<String>()
          .join(' ');
      fail(messages);
    }
  }
}

Future<void> _useSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1100, 1800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Grammar _grammar() => Grammar(
  id: 'widget-vdg',
  name: 'Widget VDG',
  terminals: const {'x'},
  nonterminals: const {'S', 'A', 'B'},
  startSymbol: 'S',
  productions: {
    const Production(id: 'p1', leftSide: ['S'], rightSide: ['A']),
    const Production(
      id: 'p2',
      leftSide: ['A'],
      rightSide: [],
      isLambda: true,
      order: 1,
    ),
    const Production(
      id: 'p3',
      leftSide: ['S'],
      rightSide: ['A', 'B'],
      order: 2,
    ),
    const Production(id: 'p4', leftSide: ['B'], rightSide: ['x'], order: 3),
  },
  type: GrammarType.contextFree,
  created: DateTime.utc(2026),
  modified: DateTime.utc(2026),
);

final class _RecordingExportService implements VariableDependencyExportService {
  String? svg;
  Uint8List? png;
  String? svgDialogTitle;
  String? pngDialogTitle;

  @override
  Future<String?> saveSvg({
    required String suggestedName,
    required String svg,
    required String dialogTitle,
  }) async {
    this.svg = svg;
    svgDialogTitle = dialogTitle;
    return '$suggestedName.svg';
  }

  @override
  Future<String?> savePng({
    required String suggestedName,
    required Uint8List bytes,
    required String dialogTitle,
  }) async {
    png = bytes;
    pngDialogTitle = dialogTitle;
    return '$suggestedName.png';
  }
}
