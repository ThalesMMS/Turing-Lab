import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/core/constants/help_topic_ids.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/pages/help_page.dart';
import 'package:turing_lab/presentation/widgets/error_banner.dart';
import 'package:turing_lab/presentation/widgets/help_tree_view.dart';

Finder _helpNode(String id) => find.byKey(ValueKey('help-node-$id'));

Future<void> _pumpHelpPage(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  bool disableAnimations = false,
  Size size = const Size(430, 932),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: disableAnimations),
          child: child!,
        ),
        home: const HelpPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ErrorBanner', () {
    testWidgets('announces newly inserted feedback as a live region', (
      tester,
    ) async {
      final semanticsHandle = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorBanner(
              message: 'Import completed',
              severity: ErrorSeverity.success,
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(ErrorBanner));
      expect(semantics.getSemanticsData().flagsCollection.isLiveRegion, isTrue);
      expect(semantics.label, contains('Import completed'));
      semanticsHandle.dispose();
    });

    testWidgets('renders a dismiss action with a 44pt tap target', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorBanner(
              message: 'Something happened',
              severity: ErrorSeverity.warning,
              showRetryButton: false,
              onDismiss: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final dismissButton = find.ancestor(
        of: find.text('Dismiss'),
        matching: find.bySubtype<ButtonStyleButton>(),
      );

      expect(dismissButton, findsOneWidget);
      expect(tester.getSize(dismissButton).height, greaterThanOrEqualTo(44));
    });
  });

  group('Help tree accessibility', () {
    testWidgets(
      'localizes heading and expanded semantics for category and subsection',
      (tester) async {
        final semanticsHandle = tester.ensureSemantics();
        await _pumpHelpPage(tester, locale: const Locale('pt'));

        final category = tester.getSemantics(_helpNode('getting-started'));
        expect(category.label, 'Recolher Primeiros passos');
        expect(category.flagsCollection.isHeader, isTrue);
        expect(category.flagsCollection.isButton, isTrue);
        expect(category.flagsCollection.isExpanded, Tristate.isTrue);

        await tester.scrollUntilVisible(_helpNode('fsa'), 200);
        await tester.pumpAndSettle();
        await tester.tap(_helpNode('fsa'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(_helpNode('fsa.editor'), 200);
        await tester.pumpAndSettle();

        final subsection = tester.getSemantics(_helpNode('fsa.editor'));
        expect(subsection.label, 'Expandir Editor e canvas');
        expect(subsection.flagsCollection.isHeader, isTrue);
        expect(subsection.flagsCollection.isButton, isTrue);
        expect(subsection.flagsCollection.isExpanded, Tristate.isFalse);
        semanticsHandle.dispose();
      },
    );

    testWidgets('category, subsection, and topic targets are at least 48x48', (
      tester,
    ) async {
      await _pumpHelpPage(tester, size: const Size(430, 1800));

      final tree = tester.widget<HelpTreeView>(find.byType(HelpTreeView));
      tree.controller.revealTopic(HelpTopicIds.fsaEditorOverview);
      await tester.pumpAndSettle();

      for (final id in ['fsa', 'fsa.editor', HelpTopicIds.fsaEditorOverview]) {
        final size = tester.getSize(_helpNode(id));
        expect(size.width, greaterThanOrEqualTo(48), reason: id);
        expect(size.height, greaterThanOrEqualTo(48), reason: id);
      }
    });

    testWidgets('Tab and Shift+Tab follow category subsection topic order', (
      tester,
    ) async {
      await _pumpHelpPage(tester);
      final tree = tester.widget<HelpTreeView>(find.byType(HelpTreeView));
      tree.controller.toggle('getting-started');
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        tester
            .widget<IconButton>(
              find.byKey(const ValueKey('help-search-action')),
            )
            .focusNode
            ?.hasFocus,
        isTrue,
      );

      // The search action is the only stop before the tree, so the next Tab
      // lands on its first category.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'help-node-getting-started',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        tester.widget<InkWell>(_helpNode('fsa')).focusNode?.hasFocus,
        isTrue,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(_helpNode('fsa.editor'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        tester.widget<InkWell>(_helpNode('fsa.editor')).focusNode?.hasFocus,
        isTrue,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(_helpNode(HelpTopicIds.fsaEditorOverview), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        tester
            .widget<InkWell>(_helpNode(HelpTopicIds.fsaEditorOverview))
            .focusNode
            ?.hasFocus,
        isTrue,
      );

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
      expect(
        tester.widget<InkWell>(_helpNode('fsa.editor')).focusNode?.hasFocus,
        isTrue,
      );
    });

    testWidgets('reduced motion removes topic expansion animation', (
      tester,
    ) async {
      await _pumpHelpPage(tester, disableAnimations: true);

      await tester.tap(_helpNode(HelpTopicIds.gettingStartedQuickStart));
      await tester.pump();

      final expansion = tester.widget<AnimatedSwitcher>(
        find.byKey(
          const ValueKey('help-expansion-getting-started.quick-start'),
        ),
      );
      expect(expansion.duration, Duration.zero);
    });
  });
}
