import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/derivation_tree.dart';
import 'package:turing_lab/core/models/derivation_tree_node.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/derivation_tree_view.dart';

// feature-localization-surface: responsive-accessibility
void main() {
  testWidgets('derivation tree container has a localized semantic label', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    const tree = DerivationTree(
      root: DerivationTreeNode(
        symbol: 'S',
        children: [DerivationTreeNode(symbol: 'a', lexeme: 'a')],
      ),
    );

    for (final (locale, expectedLabel) in const [
      (Locale('pt', 'BR'), 'Árvore de derivação'),
      (Locale('en'), 'Derivation Tree'),
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
    }
    expect(find.text('S'), findsOneWidget);
    expect(find.text('a → "a"'), findsOneWidget);
    semantics.dispose();
  });
}
