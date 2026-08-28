//
//  derivation_tree_view.dart
//  Turing Lab
//
//  UI widget for displaying derivation/parse trees.
//
import 'package:flutter/material.dart';

import '../../core/models/derivation_tree.dart';
import '../../core/models/derivation_tree_node.dart';
import '../../core/constants/monospace_typography.dart';
import '../../l10n/app_localizations_resolver.dart';

class DerivationTreeView extends StatelessWidget {
  const DerivationTreeView({
    super.key,
    required this.tree,
    this.initiallyExpanded = true,
  });

  final DerivationTree tree;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: l10n.derivationTree,
      child: _NodeView(node: tree.root, initiallyExpanded: initiallyExpanded),
    );
  }
}

class _NodeView extends StatelessWidget {
  const _NodeView({required this.node, required this.initiallyExpanded});

  final DerivationTreeNode node;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final label =
        node.lexeme == null ? node.symbol : '${node.symbol} → "${node.lexeme}"';

    if (node.children.isEmpty) {
      return Material(
        type: MaterialType.transparency,
        child: ListTile(
          dense: true,
          title: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamilyFallback: kMonospaceFontFamilyFallback,
                ),
          ),
        ),
      );
    }

    return Material(
      type: MaterialType.transparency,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 8),
        childrenPadding: const EdgeInsets.only(left: 16, right: 8, bottom: 8),
        title: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamilyFallback: kMonospaceFontFamilyFallback,
                fontWeight: FontWeight.w600,
              ),
        ),
        children: node.children
            .map((c) => _NodeView(
                  node: c,
                  initiallyExpanded: initiallyExpanded,
                ))
            .toList(growable: false),
      ),
    );
  }
}
