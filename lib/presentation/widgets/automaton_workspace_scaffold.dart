import 'package:flutter/material.dart';

import 'movable_canvas_panel_host.dart';
import 'tablet_layout_container.dart';

typedef AutomatonCanvasBuilder = Widget Function({required bool isMobile});

class AutomatonWorkspaceScaffold extends StatefulWidget {
  const AutomatonWorkspaceScaffold({
    super.key,
    required this.canvasWithToolbar,
    required this.algorithmPanel,
    required this.simulationPanel,
    this.tabletAlgorithmPanel,
    this.infoPanel,
    this.mobileFloatingPanelBuilder,
    this.floatingActionButton,
    this.algorithmTabTitle = 'Algorithms',
    this.simulationTabTitle = 'Simulation',
    this.infoTabTitle = 'Info',
  });

  static const double mobileBreakpoint = 1024;
  static const double tabletBreakpoint = 1400;

  final AutomatonCanvasBuilder canvasWithToolbar;
  final Widget algorithmPanel;
  final Widget? tabletAlgorithmPanel;
  final Widget simulationPanel;
  final Widget? infoPanel;
  final MovableCanvasPanelBuilder? mobileFloatingPanelBuilder;
  final Widget? floatingActionButton;
  final String algorithmTabTitle;
  final String simulationTabTitle;
  final String infoTabTitle;

  @override
  State<AutomatonWorkspaceScaffold> createState() =>
      _AutomatonWorkspaceScaffoldState();
}

class _AutomatonWorkspaceScaffoldState
    extends State<AutomatonWorkspaceScaffold> {
  Offset? _mobileFloatingPanelPosition;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < AutomatonWorkspaceScaffold.mobileBreakpoint;

        return FocusTraversalGroup(
          policy: ReadingOrderTraversalPolicy(),
          child: Scaffold(
            body: isMobile
                ? _buildMobileLayout()
                : width < AutomatonWorkspaceScaffold.tabletBreakpoint
                    ? _buildTabletLayout()
                    : _buildDesktopLayout(),
            floatingActionButton: isMobile ? null : widget.floatingActionButton,
          ),
        );
      },
    );
  }

  Widget _buildMobileLayout() {
    return SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: widget.canvasWithToolbar(isMobile: true),
            ),
          ),
          if (widget.mobileFloatingPanelBuilder != null)
            Positioned.fill(
              child: MovableCanvasPanelHost(
                builder: widget.mobileFloatingPanelBuilder!,
                initialPosition: _mobileFloatingPanelPosition,
                onPositionChanged: (position) {
                  _mobileFloatingPanelPosition = position;
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return TabletLayoutContainer(
      canvas: widget.canvasWithToolbar(isMobile: false),
      algorithmPanel: widget.tabletAlgorithmPanel ?? widget.algorithmPanel,
      simulationPanel: widget.simulationPanel,
      infoPanel: widget.infoPanel,
      algorithmTabTitle: widget.algorithmTabTitle,
      simulationTabTitle: widget.simulationTabTitle,
      infoTabTitle: widget.infoTabTitle,
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildDesktopPanel(
            widget.canvasWithToolbar(isMobile: false),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDesktopPanel(widget.simulationPanel),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDesktopPanel(widget.algorithmPanel),
        ),
        if (widget.infoPanel != null) ...[
          const SizedBox(width: 16),
          Flexible(
            child: _buildDesktopPanel(widget.infoPanel!),
          ),
        ],
      ],
    );
  }

  Widget _buildDesktopPanel(Widget child) {
    return Container(
      margin: const EdgeInsets.all(8),
      child: child,
    );
  }
}
