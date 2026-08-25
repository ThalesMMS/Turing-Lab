//
//  automaton_workspace_scaffold.dart
//  Turing Lab
//
//  Shared workspace shell. Compact viewports keep the canvas plus a movable
//  floating panel; wide viewports hand the canvas the whole pane and park
//  every side panel behind the collapsible dock rail.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';

import '../../l10n/app_localizations_resolver.dart';
import 'movable_canvas_panel_host.dart';
import 'workspace_dock.dart';

typedef AutomatonCanvasBuilder = Widget Function({required bool isMobile});

class AutomatonWorkspaceScaffold extends StatefulWidget {
  const AutomatonWorkspaceScaffold({
    super.key,
    required this.canvasWithToolbar,
    required this.algorithmPanel,
    required this.simulationPanel,
    this.infoPanel,
    this.extraPanels = const <WorkspaceDockPanel>[],
    this.mobileFloatingPanelBuilder,
    this.algorithmTabTitle = 'Algorithms',
    this.simulationTabTitle = 'Simulation',
    this.infoTabTitle = 'Info',
  });

  static const double mobileBreakpoint = 1024;
  static const double tabletBreakpoint = 1400;

  /// Panel width the dock opens with on the tablet band.
  static const double tabletPanelWidth = 340;

  /// Panel width the dock opens with from [tabletBreakpoint] upwards.
  static const double desktopPanelWidth = 400;

  /// Dock panel identifiers, exposed so pages and tests can request or assert
  /// a specific panel without repeating string literals.
  static const String algorithmPanelId = 'algorithms';
  static const String simulationPanelId = 'simulation';
  static const String infoPanelId = 'info';

  final AutomatonCanvasBuilder canvasWithToolbar;

  /// Algorithms panel. The dock hosts its panels inside a scroll view, so
  /// this must be a scroll-safe (bounded height) widget.
  final Widget algorithmPanel;
  final Widget simulationPanel;
  final Widget? infoPanel;

  /// Workspace-specific dock panels appended after the shared ones.
  final List<WorkspaceDockPanel> extraPanels;
  final MovableCanvasPanelBuilder? mobileFloatingPanelBuilder;
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

  String _localizedPanelTitle(String title) {
    final l10n = appLocalizationsOf(context);
    return switch (title) {
      'Algorithms' => l10n.algorithms,
      'Simulation' => l10n.simulation,
      'Info' => l10n.info,
      'Parser' => l10n.parser,
      _ => title,
    };
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < AutomatonWorkspaceScaffold.mobileBreakpoint;

        return FocusTraversalGroup(
          policy: ReadingOrderTraversalPolicy(),
          child: Scaffold(
            body: isMobile ? _buildMobileLayout() : _buildWideLayout(width),
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

  Widget _buildWideLayout(double width) {
    final isTablet = width < AutomatonWorkspaceScaffold.tabletBreakpoint;

    return WorkspaceDock(
      content: _buildCanvasSurface(),
      initialPanelWidth: isTablet
          ? AutomatonWorkspaceScaffold.tabletPanelWidth
          : AutomatonWorkspaceScaffold.desktopPanelWidth,
      // Rail order mirrors the old column order: simulation sits closest to
      // the canvas, algorithms next, then the optional info panel.
      panels: [
        WorkspaceDockPanel(
          id: AutomatonWorkspaceScaffold.simulationPanelId,
          label: _localizedPanelTitle(widget.simulationTabTitle),
          icon: Icons.play_arrow,
          child: widget.simulationPanel,
        ),
        WorkspaceDockPanel(
          id: AutomatonWorkspaceScaffold.algorithmPanelId,
          label: _localizedPanelTitle(widget.algorithmTabTitle),
          icon: Icons.auto_awesome,
          child: widget.algorithmPanel,
        ),
        if (widget.infoPanel case final infoPanel?)
          WorkspaceDockPanel(
            id: AutomatonWorkspaceScaffold.infoPanelId,
            label: _localizedPanelTitle(widget.infoTabTitle),
            icon: Icons.info_outline,
            child: infoPanel,
          ),
        ...widget.extraPanels,
      ],
    );
  }

  Widget _buildCanvasSurface() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: widget.canvasWithToolbar(isMobile: false),
    );
  }
}
