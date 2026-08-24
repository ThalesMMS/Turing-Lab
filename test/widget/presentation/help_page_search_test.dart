import 'dart:ui' show SemanticsAction, SemanticsFlag;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsNode;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/constants/help_topic_ids.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/pages/help_page.dart';
import 'package:turing_lab/presentation/widgets/help_tree_view.dart';

Future<void> _pumpHelpPage(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_helpApp(locale));
  await tester.pumpAndSettle();
}

Widget _helpApp(Locale locale) {
  return ProviderScope(
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HelpPage(),
    ),
  );
}

Finder _node(String id) => find.byKey(ValueKey('help-node-$id'));
Finder get _searchAction => find.byKey(const ValueKey('help-search-action'));
Finder get _searchField => find.byKey(const ValueKey('help-search-field'));

bool _hasLiveRegionFlag(SemanticsNode node) {
  // Flutter 3.27 exposes semantic flags through hasFlag.
  // ignore: deprecated_member_use
  return node.hasFlag(SemanticsFlag.isLiveRegion);
}

Future<void> _openSearch(WidgetTester tester) async {
  await tester.tap(_searchAction);
  await tester.pump();
}

void main() {
  testWidgets('search action reveals an inline focused field', (tester) async {
    await _pumpHelpPage(tester);

    await _openSearch(tester);

    expect(find.byType(HelpPage), findsOneWidget);
    expect(_searchField, findsOneWidget);
    expect(tester.widget<TextField>(_searchField).focusNode?.hasFocus, isTrue);
    expect(find.byType(HelpTreeView), findsOneWidget);
  });

  testWidgets('shortcut wrapper stays out of keyboard traversal', (
    tester,
  ) async {
    await _pumpHelpPage(tester);

    final shortcutFocus = tester.widget<Focus>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Focus &&
            widget.onKeyEvent != null &&
            widget.child is SafeArea,
      ),
    );

    expect(shortcutFocus.canRequestFocus, isFalse);
  });

  testWidgets('body search filters the same tree and expands every match path',
      (
    tester,
  ) async {
    await _pumpHelpPage(tester);
    await _openSearch(tester);

    await tester.enterText(_searchField, 'five-second limit');
    await tester.pump();

    expect(_node('grammar'), findsOneWidget);
    expect(_node(HelpTopicIds.grammarEditorParserCyk), findsOneWidget);
    expect(_node('fsa'), findsNothing);
    final tree = tester.widget<HelpTreeView>(find.byType(HelpTreeView));
    expect(
      tree.controller.expandedIds,
      containsAll([
        'grammar',
        'grammar.editor',
        'grammar.editor.parser',
        HelpTopicIds.grammarEditorParserCyk,
      ]),
    );
  });

  testWidgets('titles and bodies render literal highlighted spans', (
    tester,
  ) async {
    await _pumpHelpPage(tester);
    await _openSearch(tester);

    await tester.enterText(_searchField, 'CYK parsing');
    await tester.pump();

    final title = tester.widget<Text>(
      find
          .descendant(
            of: _node(HelpTopicIds.grammarEditorParserCyk),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Text &&
                  widget.textSpan?.toPlainText() == 'CYK parsing',
            ),
          )
          .first,
    );
    final titleSpans = (title.textSpan! as TextSpan).children!.cast<TextSpan>();
    final highlightedTitle = titleSpans.singleWhere(
      (span) => span.text == 'CYK parsing',
    );
    final colorScheme = Theme.of(
      tester.element(_node(HelpTopicIds.grammarEditorParserCyk)),
    ).colorScheme;
    expect(
        highlightedTitle.style?.backgroundColor, colorScheme.tertiaryContainer);
    expect(highlightedTitle.style?.color, colorScheme.onTertiaryContainer);

    final body = tester.widget<SelectableText>(
      find
          .descendant(
            of: find.byKey(
              const ValueKey('help-body-grammar.editor.parser.cyk'),
            ),
            matching: find.byType(SelectableText),
          )
          .first,
    );
    expect(
      body.textSpan!.children!.cast<TextSpan>().any(
            (span) =>
                span.text?.toLowerCase() == 'cyk parsing' &&
                span.style?.backgroundColor == colorScheme.tertiaryContainer,
          ),
      isTrue,
    );
  });

  testWidgets('result count is a polite live-region announcement', (
    tester,
  ) async {
    final semanticsHandle = tester.ensureSemantics();
    var semanticsDisposed = false;
    void disposeSemantics() {
      if (semanticsDisposed) return;
      semanticsHandle.dispose();
      semanticsDisposed = true;
    }

    addTearDown(disposeSemantics);
    await _pumpHelpPage(tester);
    await _openSearch(tester);

    await tester.enterText(_searchField, 'five-second limit');
    await tester.pump();

    final status = tester.getSemantics(
      find.byKey(const ValueKey('help-search-status')),
    );
    expect(
      find.semantics.byPredicate(
        (candidate) =>
            candidate.id == status.id && _hasLiveRegionFlag(candidate),
        describeMatch: (_) => 'the live-region search result count',
      ),
      findsOneWidget,
    );
    expect(status.label, '1 result');
    expect(status.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
    disposeSemantics();
  });

  testWidgets('no-match query shows localized empty state', (tester) async {
    await _pumpHelpPage(tester, locale: const Locale('pt'));
    await _openSearch(tester);

    await tester.enterText(_searchField, 'frase definitivamente ausente');
    await tester.pump();

    expect(find.text('Nenhum resultado encontrado'), findsOneWidget);
    expect(
      find.text('Tente outras palavras-chave ou confira a ortografia'),
      findsOneWidget,
    );
    expect(_node('getting-started'), findsNothing);
  });

  testWidgets('clear restores the exact pre-search expansion set', (
    tester,
  ) async {
    await _pumpHelpPage(tester);
    final tree = tester.widget<HelpTreeView>(find.byType(HelpTreeView));
    tree.controller.toggle('getting-started');
    tree.controller.toggle('fsa');
    await tester.pump();
    await _openSearch(tester);

    await tester.enterText(_searchField, 'five-second limit');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('help-search-clear')));
    await tester.pump();

    expect(tree.controller.expandedIds, {'fsa'});
    expect(_searchField, findsOneWidget);
    expect(tester.widget<TextField>(_searchField).controller?.text, isEmpty);
  });

  testWidgets('locale change preserves query and pre-search expansions', (
    tester,
  ) async {
    await _pumpHelpPage(tester);
    final originalController =
        tester.widget<HelpTreeView>(find.byType(HelpTreeView)).controller;
    originalController.toggle('getting-started');
    originalController.toggle('fsa');
    originalController.toggle('pda');
    await tester.pump();
    await _openSearch(tester);
    await tester.enterText(_searchField, 'five-second limit');
    await tester.pump();

    await tester.pumpWidget(_helpApp(const Locale('pt')));
    await tester.pumpAndSettle();

    final localizedController =
        tester.widget<HelpTreeView>(find.byType(HelpTreeView)).controller;
    expect(identical(localizedController, originalController), isTrue);
    expect(localizedController.query, 'five-second limit');
    expect(tester.widget<TextField>(_searchField).controller?.text,
        'five-second limit');
    expect(find.text('Nenhum resultado encontrado'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('help-search-clear')));
    await tester.pump();

    expect(localizedController.expandedIds, {'fsa', 'pda'});
  });

  testWidgets('search-required disclosures stay open when activated', (
    tester,
  ) async {
    await _pumpHelpPage(tester);
    await _openSearch(tester);
    await tester.enterText(_searchField, 'five-second limit');
    await tester.pump();

    await tester.tap(_node('grammar.editor.parser'));
    await tester.pump();

    final body = find.byKey(
      const ValueKey('help-body-grammar.editor.parser.cyk'),
    );
    expect(body, findsOneWidget);
    expect(find.text('1 result'), findsOneWidget);

    await tester.tap(_node(HelpTopicIds.grammarEditorParserCyk));
    await tester.pump();

    expect(body, findsOneWidget);
    final bodyText = tester.widget<SelectableText>(
      find.byKey(
        const ValueKey(
          'help-block-paragraph-grammar.editor.parser.cyk-0',
        ),
      ),
    );
    expect(
      bodyText.textSpan!.children!.cast<TextSpan>().any(
            (span) =>
                span.text == 'five-second limit' &&
                span.style?.backgroundColor != null,
          ),
      isTrue,
    );
    expect(find.text('1 result'), findsOneWidget);
  });

  testWidgets('Escape clears the query before closing the inline field', (
    tester,
  ) async {
    await _pumpHelpPage(tester);
    await _openSearch(tester);
    await tester.enterText(_searchField, 'CYK');
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(_searchField, findsOneWidget);
    expect(tester.widget<TextField>(_searchField).controller?.text, isEmpty);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(_searchField, findsNothing);
    expect(
        tester.widget<IconButton>(_searchAction).focusNode?.hasFocus, isTrue);
  });

  testWidgets('related topic clears a filter that hides its target', (
    tester,
  ) async {
    await _pumpHelpPage(tester);
    await _openSearch(tester);
    await tester.enterText(_searchField, 'shortest path from the Home page');
    await tester.pump();

    await tester.tap(
      find.byKey(
        const ValueKey('help-related-getting-started.choose-workspace'),
      ),
    );
    await tester.pumpAndSettle();

    expect(_searchField, findsOneWidget);
    expect(tester.widget<TextField>(_searchField).controller?.text, isEmpty);
    expect(_node(HelpTopicIds.gettingStartedChooseWorkspace), findsOneWidget);
    expect(
      tester
          .widget<InkWell>(_node(HelpTopicIds.gettingStartedChooseWorkspace))
          .focusNode
          ?.hasFocus,
      isTrue,
    );
  });

  testWidgets('visible related topic preserves query and expansion snapshot', (
    tester,
  ) async {
    await _pumpHelpPage(tester);
    final tree = tester.widget<HelpTreeView>(find.byType(HelpTreeView));
    tree.controller.toggle('fsa');
    await tester.pump();
    await _openSearch(tester);
    await tester.enterText(_searchField, 'Getting started');
    await tester.pump();

    final related = find.descendant(
      of: find.byKey(
        const ValueKey('help-body-getting-started.quick-start'),
      ),
      matching: find.byKey(
        const ValueKey('help-related-getting-started.choose-workspace'),
      ),
    );
    await tester.ensureVisible(related);
    await tester.pumpAndSettle();
    await tester.tap(related);
    await tester.pumpAndSettle();

    expect(tree.controller.query, 'Getting started');
    expect(tester.widget<TextField>(_searchField).controller?.text,
        'Getting started');
    await tester.tap(find.byKey(const ValueKey('help-search-clear')));
    await tester.pump();
    expect(tree.controller.expandedIds, {'getting-started', 'fsa'});
  });

  testWidgets('one query highlights every occurrence across multiple paths', (
    tester,
  ) async {
    await _pumpHelpPage(tester);
    await _openSearch(tester);
    await tester.enterText(_searchField, 'Clear');
    await tester.pump();

    final tree = tester.widget<HelpTreeView>(find.byType(HelpTreeView));
    expect(
      tree.controller.matchingTopicIds,
      containsAll([
        HelpTopicIds.fsaEditorHistoryAndClear,
        HelpTopicIds.pdaEditorHistoryAndClear,
        HelpTopicIds.tmEditorHistoryAndClear,
      ]),
    );

    final tmBody = find.byKey(
      const ValueKey('help-body-tm.editor.history-and-clear'),
    );
    await tester.dragUntilVisible(
      _node(HelpTopicIds.tmEditorHistoryAndClear),
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    final body = tester.widget<SelectableText>(
      find.descendant(of: tmBody, matching: find.byType(SelectableText)).first,
    );
    final colorScheme = Theme.of(tester.element(tmBody)).colorScheme;
    final highlights = body.textSpan!.children!.cast<TextSpan>().where(
          (span) =>
              span.text?.toLowerCase() == 'clear' &&
              span.style?.backgroundColor == colorScheme.tertiaryContainer,
        );
    expect(highlights.length, 3);
  });
}
