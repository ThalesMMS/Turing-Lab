import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/derivation_tree.dart';
import 'package:turing_lab/core/models/derivation_tree_node.dart';
import 'package:turing_lab/presentation/widgets/derivation_tree_view.dart';
import 'package:turing_lab/presentation/widgets/derivation_tree_viewer.dart';

// feature-localization-surface: responsive-accessibility
const _tree = DerivationTree(
  root: DerivationTreeNode(
    symbol: 'Expr',
    children: [
      DerivationTreeNode(
        symbol: 'Fator',
        children: [DerivationTreeNode(symbol: 'id', lexeme: 'id')],
      ),
      DerivationTreeNode(symbol: '+', lexeme: '+'),
      DerivationTreeNode(
        symbol: 'Fator',
        children: [DerivationTreeNode(symbol: 'num', lexeme: 'num')],
      ),
    ],
  ),
);

InteractiveViewer _viewer(WidgetTester tester) =>
    tester.widget<InteractiveViewer>(
      find.byKey(const ValueKey('derivation-tree-interactive-viewer')),
    );

void main() {
  testWidgets('renders the tree inside a pan/zoom viewport with a toolbar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DerivationTreeViewer(
            tree: _tree,
            height: 300,
            onOpenFullscreen: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(InteractiveViewer), findsOneWidget);
    final treeView = tester.widget<DerivationTreeView>(
      find.byType(DerivationTreeView),
    );
    expect(treeView.fitToContent, isTrue);
    expect(find.text('id → "id"'), findsOneWidget);
    expect(find.byKey(const ValueKey('derivation-tree-fit')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('derivation-tree-zoom-in')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('derivation-tree-zoom-out')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('derivation-tree-fullscreen')),
      findsOneWidget,
    );
    expect(find.text('Drag to pan; pinch or scroll to zoom.'), findsOneWidget);
  });

  testWidgets('zoom buttons change the scale and fit restores it', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DerivationTreeViewer(tree: _tree, height: 300)),
      ),
    );
    await tester.pumpAndSettle();

    final controller = _viewer(tester).transformationController!;
    final fitted = controller.value.getMaxScaleOnAxis();

    await tester.tap(find.byKey(const ValueKey('derivation-tree-zoom-in')));
    await tester.pumpAndSettle();
    expect(controller.value.getMaxScaleOnAxis(), greaterThan(fitted));

    await tester.tap(find.byKey(const ValueKey('derivation-tree-zoom-out')));
    await tester.tap(find.byKey(const ValueKey('derivation-tree-zoom-out')));
    await tester.pumpAndSettle();
    expect(controller.value.getMaxScaleOnAxis(), lessThan(fitted));

    await tester.tap(find.byKey(const ValueKey('derivation-tree-fit')));
    await tester.pumpAndSettle();
    expect(controller.value.getMaxScaleOnAxis(), closeTo(fitted, 0.0001));
  });

  testWidgets('hides the fullscreen button without a callback', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DerivationTreeViewer(tree: _tree, height: 300)),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('derivation-tree-fullscreen')),
      findsNothing,
    );
  });

  testWidgets('showDerivationTreeFullscreen opens a dialog with the tree', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: DerivationTreeViewer(
                tree: _tree,
                height: 200,
                onOpenFullscreen: () =>
                    showDerivationTreeFullscreen(context, _tree),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('derivation-tree-fullscreen')));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(
      find.byKey(const ValueKey('derivation-tree-fullscreen-viewer')),
      findsOneWidget,
    );
    expect(find.byType(InteractiveViewer), findsNWidgets(2));
    expect(find.text('Derivation Tree'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
  });
}
