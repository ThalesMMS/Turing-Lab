//
//  derivation_tree_view.dart
//  Turing Lab
//
//  UI widget for displaying derivation/parse trees.
//
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../core/constants/monospace_typography.dart';
import '../../core/models/derivation_tree.dart';
import '../../core/models/derivation_tree_node.dart';
import '../../l10n/app_localizations_resolver.dart';

const _canvasPadding = 16.0;
const _minimumNodeWidth = 44.0;
const _maximumNodeWidth = 240.0;
const _minimumNodeHeight = 40.0;
const _nodeHorizontalPadding = 12.0;
const _nodeVerticalPadding = 8.0;
const _siblingGap = 16.0;
const _levelGap = 32.0;
const _nodeRadius = 10.0;

class DerivationTreeView extends StatelessWidget {
  const DerivationTreeView({super.key, required this.tree});

  final DerivationTree tree;

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      fontFamilyFallback: kMonospaceFontFamilyFallback,
      fontWeight: FontWeight.w600,
    );
    final layout = _DerivationTreeLayout.build(
      tree.root,
      textStyle: textStyle ?? const TextStyle(),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    );

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: l10n.derivationTree,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewportWidth = constraints.hasBoundedWidth
              ? constraints.maxWidth
              : layout.width;
          final contentWidth = math.max(viewportWidth, layout.width);

          return SizedBox(
            height: layout.height,
            child: _CenteredTreeScrollView(
              tree: tree,
              viewportWidth: viewportWidth,
              contentWidth: contentWidth,
              child: SizedBox(
                width: contentWidth,
                height: layout.height,
                child: Align(
                  alignment: AlignmentDirectional.topCenter,
                  child: SizedBox(
                    key: const ValueKey('derivation-tree-canvas'),
                    width: layout.width,
                    height: layout.height,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: ExcludeSemantics(
                            child: CustomPaint(
                              key: const ValueKey(
                                'derivation-tree-connections',
                              ),
                              painter: _TreeConnectionsPainter(
                                branches: layout.branches,
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ),
                        ),
                        for (final node in layout.nodes)
                          _buildNode(context, node),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNode(BuildContext context, _PositionedTreeNode positioned) {
    final l10n = appLocalizationsOf(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isRoot = positioned.depth == 0;
    final isLeaf = positioned.node.children.isEmpty;
    final backgroundColor = isRoot
        ? colorScheme.primary
        : isLeaf
        ? colorScheme.surfaceContainerHighest
        : colorScheme.primaryContainer;
    final foregroundColor = isRoot
        ? colorScheme.onPrimary
        : isLeaf
        ? colorScheme.onSurface
        : colorScheme.onPrimaryContainer;
    final borderColor = isRoot
        ? colorScheme.primary
        : isLeaf
        ? colorScheme.outlineVariant
        : colorScheme.primary.withValues(alpha: 0.35);
    final semanticsLabel = isLeaf
        ? l10n.derivationTreeLeafSemantics(
            positioned.label,
            positioned.depth + 1,
          )
        : l10n.derivationTreeBranchSemantics(
            positioned.label,
            positioned.depth + 1,
            positioned.node.children.length,
          );

    return Positioned.fromRect(
      rect: positioned.rect,
      child: Semantics(
        container: true,
        sortKey: OrdinalSortKey(positioned.index.toDouble()),
        label: semanticsLabel,
        child: ExcludeSemantics(
          child: DecoratedBox(
            key: ValueKey('derivation-tree-node-${positioned.index}'),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(_nodeRadius),
              border: Border.all(color: borderColor),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _nodeHorizontalPadding,
                vertical: _nodeVerticalPadding,
              ),
              child: Center(
                child: Text(
                  positioned.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: foregroundColor,
                    fontFamilyFallback: kMonospaceFontFamilyFallback,
                    fontWeight: isLeaf ? FontWeight.w500 : FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CenteredTreeScrollView extends StatefulWidget {
  const _CenteredTreeScrollView({
    required this.tree,
    required this.viewportWidth,
    required this.contentWidth,
    required this.child,
  });

  final DerivationTree tree;
  final double viewportWidth;
  final double contentWidth;
  final Widget child;

  @override
  State<_CenteredTreeScrollView> createState() =>
      _CenteredTreeScrollViewState();
}

class _CenteredTreeScrollViewState extends State<_CenteredTreeScrollView> {
  late final ScrollController _controller;
  bool _centeringScheduled = false;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController(
      initialScrollOffset: _targetOffset(widget),
      keepScrollOffset: false,
    );
  }

  @override
  void didUpdateWidget(_CenteredTreeScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tree != widget.tree ||
        oldWidget.viewportWidth != widget.viewportWidth ||
        oldWidget.contentWidth != widget.contentWidth) {
      _scheduleCenter();
    }
  }

  void _scheduleCenter() {
    if (_centeringScheduled) {
      return;
    }
    _centeringScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centeringScheduled = false;
      if (!mounted || !_controller.hasClients) {
        return;
      }
      final target = _targetOffset(
        widget,
      ).clamp(0.0, _controller.position.maxScrollExtent).toDouble();
      _controller.jumpTo(target);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('derivation-tree-horizontal-scroll'),
      controller: _controller,
      scrollDirection: Axis.horizontal,
      child: widget.child,
    );
  }

  static double _targetOffset(_CenteredTreeScrollView widget) =>
      math.max(0, (widget.contentWidth - widget.viewportWidth) / 2);
}

class _DerivationTreeLayout {
  const _DerivationTreeLayout({
    required this.width,
    required this.height,
    required this.nodes,
    required this.branches,
  });

  final double width;
  final double height;
  final List<_PositionedTreeNode> nodes;
  final List<_TreeBranch> branches;

  static _DerivationTreeLayout build(
    DerivationTreeNode root, {
    required TextStyle textStyle,
    required TextDirection textDirection,
    required TextScaler textScaler,
  }) {
    var nextIndex = 0;
    var maximumTextHeight = 0.0;

    _MeasuredTreeNode measure(DerivationTreeNode node, int depth) {
      final label = _labelFor(node);
      final textPainter = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        maxLines: 1,
        textDirection: textDirection,
        textScaler: textScaler,
      )..layout();
      maximumTextHeight = math.max(maximumTextHeight, textPainter.height);
      final nodeWidth = (textPainter.width + 2 * _nodeHorizontalPadding).clamp(
        _minimumNodeWidth,
        _maximumNodeWidth,
      );
      final index = nextIndex++;
      final children = node.children
          .map((child) => measure(child, depth + 1))
          .toList(growable: false);
      final childrenWidth = children.isEmpty
          ? 0.0
          : children.fold<double>(0, (sum, child) => sum + child.subtreeWidth) +
                _siblingGap * (children.length - 1);

      return _MeasuredTreeNode(
        node: node,
        label: label,
        index: index,
        depth: depth,
        width: nodeWidth,
        subtreeWidth: math.max(nodeWidth, childrenWidth),
        childrenWidth: childrenWidth,
        children: children,
      );
    }

    final measuredRoot = measure(root, 0);
    final nodeHeight = math.max(
      _minimumNodeHeight,
      maximumTextHeight + 2 * _nodeVerticalPadding,
    );
    final positionedNodes = <_PositionedTreeNode>[];
    final positionedByIndex = <int, _PositionedTreeNode>{};
    var maximumDepth = 0;

    void position(_MeasuredTreeNode node, double subtreeStart) {
      maximumDepth = math.max(maximumDepth, node.depth);
      final centerX = subtreeStart + node.subtreeWidth / 2;
      final top = _canvasPadding + node.depth * (nodeHeight + _levelGap);
      final positioned = _PositionedTreeNode(
        node: node.node,
        label: node.label,
        index: node.index,
        depth: node.depth,
        rect: Rect.fromLTWH(
          centerX - node.width / 2,
          top,
          node.width,
          nodeHeight,
        ),
      );
      positionedNodes.add(positioned);
      positionedByIndex[node.index] = positioned;

      var childStart =
          subtreeStart + (node.subtreeWidth - node.childrenWidth) / 2;
      for (final child in node.children) {
        position(child, childStart);
        childStart += child.subtreeWidth + _siblingGap;
      }
    }

    position(measuredRoot, _canvasPadding);
    positionedNodes.sort((a, b) => a.index.compareTo(b.index));

    final branches = <_TreeBranch>[];
    void collectBranches(_MeasuredTreeNode node) {
      if (node.children.isNotEmpty) {
        branches.add(
          _TreeBranch(
            parent: positionedByIndex[node.index]!.rect,
            children: node.children
                .map((child) => positionedByIndex[child.index]!.rect)
                .toList(growable: false),
          ),
        );
      }
      for (final child in node.children) {
        collectBranches(child);
      }
    }

    collectBranches(measuredRoot);

    return _DerivationTreeLayout(
      width: measuredRoot.subtreeWidth + 2 * _canvasPadding,
      height:
          2 * _canvasPadding +
          (maximumDepth + 1) * nodeHeight +
          maximumDepth * _levelGap,
      nodes: positionedNodes,
      branches: branches,
    );
  }

  static String _labelFor(DerivationTreeNode node) =>
      node.lexeme == null ? node.symbol : '${node.symbol} → "${node.lexeme}"';
}

class _MeasuredTreeNode {
  const _MeasuredTreeNode({
    required this.node,
    required this.label,
    required this.index,
    required this.depth,
    required this.width,
    required this.subtreeWidth,
    required this.childrenWidth,
    required this.children,
  });

  final DerivationTreeNode node;
  final String label;
  final int index;
  final int depth;
  final double width;
  final double subtreeWidth;
  final double childrenWidth;
  final List<_MeasuredTreeNode> children;
}

class _PositionedTreeNode {
  const _PositionedTreeNode({
    required this.node,
    required this.label,
    required this.index,
    required this.depth,
    required this.rect,
  });

  final DerivationTreeNode node;
  final String label;
  final int index;
  final int depth;
  final Rect rect;
}

class _TreeBranch {
  const _TreeBranch({required this.parent, required this.children});

  final Rect parent;
  final List<Rect> children;
}

class _TreeConnectionsPainter extends CustomPainter {
  const _TreeConnectionsPainter({required this.branches, required this.color});

  final List<_TreeBranch> branches;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final branch in branches) {
      final parentAnchor = branch.parent.bottomCenter;
      final junctionY = parentAnchor.dy + _levelGap / 2;
      final childAnchors = branch.children
          .map((child) => child.topCenter)
          .toList(growable: false);

      canvas.drawLine(parentAnchor, Offset(parentAnchor.dx, junctionY), paint);
      if (childAnchors.length > 1) {
        canvas.drawLine(
          Offset(childAnchors.first.dx, junctionY),
          Offset(childAnchors.last.dx, junctionY),
          paint,
        );
      }
      for (final childAnchor in childAnchors) {
        canvas.drawLine(Offset(childAnchor.dx, junctionY), childAnchor, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TreeConnectionsPainter oldDelegate) =>
      oldDelegate.branches != branches || oldDelegate.color != color;
}
