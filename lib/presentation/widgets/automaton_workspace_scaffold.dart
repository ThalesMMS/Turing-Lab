import 'package:flutter/material.dart';

import 'tablet_layout_container.dart';

typedef AutomatonCanvasBuilder = Widget Function({required bool isMobile});

class AutomatonWorkspaceScaffold extends StatelessWidget {
  const AutomatonWorkspaceScaffold({
    super.key,
    required this.canvasWithToolbar,
    required this.algorithmPanel,
    required this.simulationPanel,
    this.tabletAlgorithmPanel,
    this.infoPanel,
    this.mobileFloatingPanel,
    this.floatingActionButton,
  });

  static const double mobileBreakpoint = 1024;
  static const double tabletBreakpoint = 1400;

  final AutomatonCanvasBuilder canvasWithToolbar;
  final Widget algorithmPanel;
  final Widget? tabletAlgorithmPanel;
  final Widget simulationPanel;
  final Widget? infoPanel;
  final Widget? mobileFloatingPanel;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < mobileBreakpoint;

        return FocusTraversalGroup(
          policy: ReadingOrderTraversalPolicy(),
          child: Scaffold(
            body: isMobile
                ? _buildMobileLayout()
                : width < tabletBreakpoint
                    ? _buildTabletLayout()
                    : _buildDesktopLayout(),
            floatingActionButton: isMobile ? null : floatingActionButton,
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
              child: canvasWithToolbar(isMobile: true),
            ),
          ),
          if (mobileFloatingPanel != null)
            Positioned(
              top: 72,
              right: 16,
              child: mobileFloatingPanel!,
            ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return TabletLayoutContainer(
      canvas: canvasWithToolbar(isMobile: false),
      algorithmPanel: tabletAlgorithmPanel ?? algorithmPanel,
      simulationPanel: simulationPanel,
      infoPanel: infoPanel,
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildDesktopPanel(canvasWithToolbar(isMobile: false)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDesktopPanel(simulationPanel),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDesktopPanel(algorithmPanel),
        ),
        if (infoPanel != null) ...[
          const SizedBox(width: 16),
          Flexible(
            child: _buildDesktopPanel(infoPanel!),
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
