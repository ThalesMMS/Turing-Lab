import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/derivation_tree.dart';
import 'package:turing_lab/core/models/derivation_tree_node.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/derivation_tree_view.dart';

// feature-localization-surface: responsive-accessibility
void main() {
  testWidgets('renders a connected hierarchy with localized semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    const tree = DerivationTree(
      root: DerivationTreeNode(
        symbol: 'S',
        children: [
          DerivationTreeNode(
            symbol: 'A',
            children: [DerivationTreeNode(symbol: 'a', lexeme: 'a')],
          ),
          DerivationTreeNode(symbol: 'b', lexeme: 'b'),
        ],
      ),
    );

    for (final (locale, expectedLabel, expectedRoot, expectedLeaf) in const [
      (
        Locale('pt', 'BR'),
        'Árvore de derivação',
        'S, nível 1, 2 filhos',
        'a → "a", folha no nível 3',
      ),
      (
        Locale('en'),
        'Derivation Tree',
        'S, level 1, 2 children',
        'a → "a", leaf at level 3',
      ),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: DerivationTreeView(tree: tree)),
        ),
      );

      final node = tester.getSemantics(find.bySemanticsLabel(expectedLabel));
      expect(node.label, expectedLabel);
      expect(find.bySemanticsLabel(expectedRoot), findsOneWidget);
      expect(find.bySemanticsLabel(expectedLeaf), findsOneWidget);
    }
    expect(find.text('S'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('a → "a"'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('derivation-tree-connections')),
      findsOneWidget,
    );
    expect(find.byType(ExpansionTile), findsNothing);
    expect(find.byType(ListTile), findsNothing);

    final rootRect = tester.getRect(
      find.byKey(const ValueKey('derivation-tree-node-0')),
    );
    final firstChildRect = tester.getRect(
      find.byKey(const ValueKey('derivation-tree-node-1')),
    );
    final secondChildRect = tester.getRect(
      find.byKey(const ValueKey('derivation-tree-node-3')),
    );
    expect(rootRect.bottom, lessThan(firstChildRect.top));
    expect(rootRect.center.dx, greaterThan(firstChildRect.center.dx));
    expect(rootRect.center.dx, lessThan(secondChildRect.center.dx));
    semantics.dispose();
  });

  testWidgets('keeps a wide tree available in a narrow viewport', (
    tester,
  ) async {
    const tree = DerivationTree(
      root: DerivationTreeNode(
        symbol: 'S',
        children: [
          DerivationTreeNode(symbol: 'a'),
          DerivationTreeNode(symbol: 'b'),
          DerivationTreeNode(symbol: 'c'),
          DerivationTreeNode(symbol: 'd'),
          DerivationTreeNode(symbol: 'e'),
          DerivationTreeNode(symbol: 'f'),
          DerivationTreeNode(symbol: 'g'),
          DerivationTreeNode(symbol: 'h'),
          DerivationTreeNode(symbol: 'i'),
          DerivationTreeNode(symbol: 'j'),
          DerivationTreeNode(symbol: 'k'),
          DerivationTreeNode(symbol: 'l'),
        ],
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SizedBox(width: 320, child: DerivationTreeView(tree: tree)),
          ),
        ),
      ),
    );
    await tester.pump();

    final viewport = tester.getRect(
      find.byKey(const ValueKey('derivation-tree-horizontal-scroll')),
    );
    final canvas = tester.getRect(
      find.byKey(const ValueKey('derivation-tree-canvas')),
    );
    final root = tester.getRect(
      find.byKey(const ValueKey('derivation-tree-node-0')),
    );
    expect(canvas.width, greaterThan(viewport.width));
    expect(root.center.dx, closeTo(viewport.center.dx, 0.01));
    expect(
      find.byKey(const ValueKey('derivation-tree-node-12')),
      findsOneWidget,
    );

    await tester.drag(
      find.byKey(const ValueKey('derivation-tree-horizontal-scroll')),
      const Offset(-120, 0),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .getRect(find.byKey(const ValueKey('derivation-tree-node-0')))
          .center
          .dx,
      lessThan(viewport.center.dx),
    );

    final replacementTree = tree.copyWith(
      root: tree.root.copyWith(symbol: 'T'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SizedBox(
              width: 320,
              child: DerivationTreeView(tree: replacementTree),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(
      tester
          .getRect(find.byKey(const ValueKey('derivation-tree-node-0')))
          .center
          .dx,
      closeTo(viewport.center.dx, 0.01),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('lays out a recursive derivation compactly without overlap', (
    tester,
  ) async {
    const tree = DerivationTree(
      root: DerivationTreeNode(
        symbol: 'S',
        children: [
          DerivationTreeNode(
            symbol: 'A',
            children: [
              DerivationTreeNode(symbol: 'a'),
              DerivationTreeNode(symbol: 'b'),
            ],
          ),
          DerivationTreeNode(
            symbol: 'A',
            children: [
              DerivationTreeNode(symbol: 'a'),
              DerivationTreeNode(
                symbol: 'A',
                children: [
                  DerivationTreeNode(symbol: 'a'),
                  DerivationTreeNode(
                    symbol: 'A',
                    children: [
                      DerivationTreeNode(symbol: 'a'),
                      DerivationTreeNode(symbol: 'b'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 390, child: DerivationTreeView(tree: tree)),
        ),
      ),
    );

    final canvas = tester.getSize(
      find.byKey(const ValueKey('derivation-tree-canvas')),
    );
    final nodeRects = [
      for (var index = 0; index < 11; index++)
        tester.getRect(find.byKey(ValueKey('derivation-tree-node-$index'))),
    ];
    for (var first = 0; first < nodeRects.length; first++) {
      for (var second = first + 1; second < nodeRects.length; second++) {
        expect(nodeRects[first].overlaps(nodeRects[second]), isFalse);
      }
    }
    expect(canvas.height, lessThan(400));
    expect(tester.takeException(), isNull);
  });
}
