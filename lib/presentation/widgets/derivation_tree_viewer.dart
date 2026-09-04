//
//  derivation_tree_viewer.dart
//  Turing Lab
//
//  Pan/zoom viewport for derivation trees with a zoom toolbar and an optional
//  full-screen dialog, used by the grammar parser panel.
//
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/models/derivation_tree.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_resolver.dart';
import 'derivation_tree_view.dart';

const _minTreeScale = 0.2;
const _maxTreeScale = 4.0;
const _zoomStep = 1.25;

/// Interactive viewport around a [DerivationTreeView].
///
/// The tree can be dragged to pan and pinched or scroll-wheeled to zoom. The
/// toolbar offers fit-to-screen, zoom in/out and, when [onOpenFullscreen] is
/// supplied, a button that opens the tree in a full-screen dialog.
class DerivationTreeViewer extends StatefulWidget {
  const DerivationTreeViewer({
    super.key,
    required this.tree,
    this.height,
    this.onOpenFullscreen,
  });

  final DerivationTree tree;

  /// Fixed viewport height. When null the viewer expands to fill its parent.
  final double? height;

  final VoidCallback? onOpenFullscreen;

  @override
  State<DerivationTreeViewer> createState() => _DerivationTreeViewerState();
}

class _DerivationTreeViewerState extends State<DerivationTreeViewer> {
  final TransformationController _transformationController =
      TransformationController();
  Size? _fittedViewport;
  bool _fitScheduled = false;

  @override
  void didUpdateWidget(DerivationTreeViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tree != widget.tree) {
      _fittedViewport = null;
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _scheduleFit(Size viewport) {
    if (_fitScheduled || _fittedViewport == viewport) {
      return;
    }
    _fitScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitScheduled = false;
      if (!mounted) return;
      _fit(viewport);
    });
  }

  void _fit(Size viewport) {
    if (viewport.isEmpty) {
      return;
    }
    final content = DerivationTreeView.naturalSize(context, widget.tree);
    if (content.isEmpty) {
      return;
    }
    final scale = math
        .min(viewport.width / content.width, viewport.height / content.height)
        .clamp(_minTreeScale, 1.0)
        .toDouble();
    final dx = (viewport.width - content.width * scale) / 2;
    final dy = math.max(0.0, (viewport.height - content.height * scale) / 2);
    _fittedViewport = viewport;
    _transformationController.value = Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1)
      ..scaleByDouble(scale, scale, scale, 1);
  }

  void _zoomBy(double factor, Size viewport) {
    final current = _transformationController.value.getMaxScaleOnAxis();
    final target = (current * factor).clamp(_minTreeScale, _maxTreeScale);
    if (target == current) {
      return;
    }
    final focal = Offset(viewport.width / 2, viewport.height / 2);
    final ratio = target / current;
    // Zoom about the viewport center: apply the scale in viewport space.
    final zoom = Matrix4.identity()
      ..translateByDouble(focal.dx, focal.dy, 0, 1)
      ..scaleByDouble(ratio, ratio, ratio, 1)
      ..translateByDouble(-focal.dx, -focal.dy, 0, 1);
    _transformationController.value = zoom.multiplied(
      _transformationController.value,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final theme = Theme.of(context);

    Widget viewport = LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 600,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 360,
        );
        _scheduleFit(size);
        return Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                key: const ValueKey('derivation-tree-interactive-viewer'),
                transformationController: _transformationController,
                constrained: false,
                minScale: _minTreeScale,
                maxScale: _maxTreeScale,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                child: DerivationTreeView(
                  tree: widget.tree,
                  fitToContent: true,
                ),
              ),
            ),
            PositionedDirectional(
              top: 4,
              end: 4,
              child: _buildToolbar(context, l10n, size),
            ),
          ],
        );
      },
    );

    viewport = Container(
      key: const ValueKey('derivation-tree-viewport'),
      height: widget.height,
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: viewport,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.height == null) Expanded(child: viewport) else viewport,
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            l10n.derivationTreePanZoomHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(
    BuildContext context,
    AppLocalizations l10n,
    Size viewport,
  ) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(8),
      elevation: 1,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: const ValueKey('derivation-tree-fit'),
            tooltip: l10n.derivationTreeFitToScreen,
            icon: const Icon(Icons.fit_screen),
            onPressed: () => _fit(viewport),
          ),
          IconButton(
            key: const ValueKey('derivation-tree-zoom-in'),
            tooltip: l10n.derivationTreeZoomIn,
            icon: const Icon(Icons.zoom_in),
            onPressed: () => _zoomBy(_zoomStep, viewport),
          ),
          IconButton(
            key: const ValueKey('derivation-tree-zoom-out'),
            tooltip: l10n.derivationTreeZoomOut,
            icon: const Icon(Icons.zoom_out),
            onPressed: () => _zoomBy(1 / _zoomStep, viewport),
          ),
          if (widget.onOpenFullscreen case final onOpenFullscreen?)
            IconButton(
              key: const ValueKey('derivation-tree-fullscreen'),
              tooltip: l10n.derivationTreeFullscreen,
              icon: const Icon(Icons.open_in_full),
              onPressed: onOpenFullscreen,
            ),
        ],
      ),
    );
  }
}

/// Opens [tree] in a full-screen dialog (a large constrained dialog on wide
/// layouts) with pan and zoom controls.
Future<void> showDerivationTreeFullscreen(
  BuildContext context,
  DerivationTree tree,
) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final l10n = appLocalizationsOf(dialogContext);
      final body = Padding(
        padding: const EdgeInsets.all(12),
        child: DerivationTreeViewer(
          key: const ValueKey('derivation-tree-fullscreen-viewer'),
          tree: tree,
        ),
      );
      final appBar = AppBar(
        title: Text(l10n.derivationTree),
        leading: IconButton(
          tooltip: MaterialLocalizations.of(dialogContext).closeButtonTooltip,
          onPressed: () => Navigator.of(dialogContext).pop(),
          icon: const Icon(Icons.close),
        ),
      );
      if (MediaQuery.sizeOf(dialogContext).width < 700) {
        return Dialog.fullscreen(
          child: Scaffold(appBar: appBar, body: body),
        );
      }
      return Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120, maxHeight: 860),
          child: Scaffold(appBar: appBar, body: body),
        ),
      );
    },
  );
}
