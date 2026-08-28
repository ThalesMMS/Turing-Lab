import 'dart:isolate';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../core/grammar/dependency_graph/dependency_graph.dart';
import '../../core/grammar/phrase_structure/phrase_structure.dart';
import '../../core/models/grammar.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_structured_messages.dart';
import '../../l10n/app_localizations_workflows.dart';
import 'app_snackbar.dart';
import 'export/variable_dependency_graph_exporter.dart';
import 'export/variable_dependency_export_service.dart';
import '../localization/locale_value_formatter.dart';

final class VariableDependencyGraphWorkspace extends StatefulWidget {
  const VariableDependencyGraphWorkspace.contextFree({
    super.key,
    required Grammar grammar,
    required this.sourceRevision,
    this.invalidated = false,
    this.exportService,
  }) : contextFreeGrammar = grammar,
       unrestrictedGrammar = null;

  VariableDependencyGraphWorkspace.unrestricted({
    super.key,
    required UnrestrictedGrammar grammar,
    this.invalidated = false,
    this.exportService,
  }) : contextFreeGrammar = null,
       unrestrictedGrammar = grammar,
       sourceRevision = grammar.revision;

  final Grammar? contextFreeGrammar;
  final UnrestrictedGrammar? unrestrictedGrammar;
  final int sourceRevision;
  final bool invalidated;
  final VariableDependencyExportService? exportService;

  bool get isUnrestricted => unrestrictedGrammar != null;
  String get grammarName =>
      contextFreeGrammar?.name ?? unrestrictedGrammar!.name;

  @override
  State<VariableDependencyGraphWorkspace> createState() =>
      _VariableDependencyGraphWorkspaceState();
}

final class _VariableDependencyGraphWorkspaceState
    extends State<VariableDependencyGraphWorkspace> {
  final _transformationController = TransformationController();
  final _repaintKey = GlobalKey();
  late final VariableDependencyExportService _exportService;
  VariableDependencyMode _mode = VariableDependencyMode.directOccurrence;
  VariableDependencyLayout _layout = VariableDependencyLayout.layered;
  VariableDependencyGraphReport? _report;
  String? _selectedEdgeId;
  String? _selectedVariable;
  Object? _error;
  int _requestSerial = 0;
  bool _analyzing = false;

  @override
  void initState() {
    super.initState();
    _exportService =
        widget.exportService ?? createVariableDependencyExportService();
    if (!widget.invalidated) _analyze();
  }

  @override
  void didUpdateWidget(VariableDependencyGraphWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sourceChanged =
        oldWidget.contextFreeGrammar?.id != widget.contextFreeGrammar?.id ||
        oldWidget.unrestrictedGrammar?.id != widget.unrestrictedGrammar?.id ||
        oldWidget.sourceRevision != widget.sourceRevision;
    if (widget.invalidated) {
      _requestSerial++;
    } else if (sourceChanged || oldWidget.invalidated) {
      _analyze();
    }
  }

  @override
  void dispose() {
    _requestSerial++;
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final report = _report;
    return Card.outlined(
      key: const ValueKey('variable-dependency-workspace'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.localizeWorkflowText('Variable dependency graph'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Text(widget.grammarName),
            const SizedBox(height: 12),
            if (widget.invalidated)
              _StatusMessage(
                key: const ValueKey('vdg-invalidated'),
                icon: Icons.warning_amber,
                text: l10n.localizeWorkflowText(
                  'The source grammar changed. Reopen the graph to analyze the current revision.',
                ),
                color: Theme.of(context).colorScheme.error,
              )
            else if (_error != null)
              _StatusMessage(
                key: const ValueKey('vdg-error'),
                icon: Icons.error_outline,
                text:
                    '${l10n.localizeWorkflowText('The dependency graph could not be built.')} $_error',
                color: Theme.of(context).colorScheme.error,
              )
            else if (_analyzing || report == null)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              _buildControls(context, report),
              const SizedBox(height: 12),
              _buildLegend(context),
              const SizedBox(height: 8),
              _GraphViewport(
                report: report,
                layout: _layout,
                selectedEdgeId: _selectedEdgeId,
                selectedVariable: _selectedVariable,
                transformationController: _transformationController,
                repaintKey: _repaintKey,
                onEdgeSelected: (id) => setState(() {
                  _selectedEdgeId = id;
                  _selectedVariable = null;
                }),
                onVariableSelected: (variable) => setState(() {
                  _selectedVariable = variable;
                  _selectedEdgeId = null;
                }),
              ),
              const SizedBox(height: 12),
              _buildAnalysisSummary(context, report),
              const SizedBox(height: 12),
              _buildSelectionDetails(context, report),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildControls(
    BuildContext context,
    VariableDependencyGraphReport report,
  ) {
    final l10n = appLocalizationsOf(context);
    final modes = widget.isUnrestricted
        ? const [VariableDependencyMode.directOccurrence]
        : VariableDependencyMode.values;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 260,
          child: DropdownButtonFormField<VariableDependencyMode>(
            key: const ValueKey('vdg-mode'),
            initialValue: _mode,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.localizeWorkflowText('Dependency mode'),
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final mode in modes)
                DropdownMenuItem(
                  value: mode,
                  child: Text(_modeLabel(context, mode)),
                ),
            ],
            onChanged: (mode) {
              if (mode == null || mode == _mode) return;
              setState(() => _mode = mode);
              _analyze();
            },
          ),
        ),
        SizedBox(
          width: 190,
          child: DropdownButtonFormField<VariableDependencyLayout>(
            key: const ValueKey('vdg-layout'),
            initialValue: _layout,
            decoration: InputDecoration(
              labelText: l10n.localizeWorkflowText('Graph layout'),
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final layout in VariableDependencyLayout.values)
                DropdownMenuItem(
                  value: layout,
                  child: Text(_layoutLabel(context, layout)),
                ),
            ],
            onChanged: (layout) {
              if (layout == null) return;
              setState(() => _layout = layout);
              _fitGraph();
            },
          ),
        ),
        IconButton.outlined(
          key: const ValueKey('vdg-fit'),
          tooltip: l10n.localizeWorkflowText('Fit graph'),
          constraints: const BoxConstraints.tightFor(width: 48, height: 48),
          onPressed: _fitGraph,
          icon: const Icon(Icons.fit_screen),
        ),
        IconButton.outlined(
          key: const ValueKey('vdg-zoom-in'),
          tooltip: l10n.localizeWorkflowText('Zoom in'),
          constraints: const BoxConstraints.tightFor(width: 48, height: 48),
          onPressed: () => _setZoom(1.25),
          icon: const Icon(Icons.zoom_in),
        ),
        IconButton.outlined(
          key: const ValueKey('vdg-zoom-out'),
          tooltip: l10n.localizeWorkflowText('Zoom out'),
          constraints: const BoxConstraints.tightFor(width: 48, height: 48),
          onPressed: () => _setZoom(0.8),
          icon: const Icon(Icons.zoom_out),
        ),
        OutlinedButton.icon(
          key: const ValueKey('vdg-export-svg'),
          onPressed: () => _exportSvg(report),
          icon: const Icon(Icons.code),
          label: Text(l10n.localizeWorkflowText('Export SVG')),
        ),
        OutlinedButton.icon(
          key: const ValueKey('vdg-export-png'),
          onPressed: () => _exportPng(report),
          icon: const Icon(Icons.image_outlined),
          label: Text(l10n.localizeWorkflowText('Export PNG')),
        ),
      ],
    );
  }

  Widget _buildLegend(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.hasBoundedWidth
            ? math.min(320.0, constraints.maxWidth)
            : 320.0;
        return Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            _LegendItem(
              width: itemWidth,
              color: const Color(0xffe3f2fd),
              label: l10n.localizeWorkflowText('Reachable and productive'),
            ),
            _LegendItem(
              width: itemWidth,
              color: const Color(0xffffecb3),
              label: l10n.localizeWorkflowText('Unreachable'),
            ),
            if (!widget.isUnrestricted)
              _LegendItem(
                width: itemWidth,
                color: const Color(0xffffcdd2),
                label: l10n.localizeWorkflowText('Nonproductive'),
              ),
            _LegendItem(
              width: itemWidth,
              color: const Color(0xffe1bee7),
              label: l10n.localizeWorkflowText('Recursive component'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnalysisSummary(
    BuildContext context,
    VariableDependencyGraphReport report,
  ) {
    final l10n = appLocalizationsOf(context);
    final formatter = LocaleValueFormatter.of(context);
    String values(Iterable<String> source) =>
        source.isEmpty ? '—' : (source.toList()..sort()).join(', ');
    return Semantics(
      liveRegion: true,
      label: _accessibleSummary(l10n, report),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          Chip(
            label: Text(
              '${l10n.localizeWorkflowText('Reachable')}: '
              '${values(report.reachableVariables)}',
            ),
          ),
          Chip(
            label: Text(
              '${l10n.localizeWorkflowText('Unreachable')}: '
              '${values(report.unreachableVariables)}',
            ),
          ),
          if (report.productivityAvailable)
            Chip(
              label: Text(
                '${l10n.localizeWorkflowText('Nonproductive')}: '
                '${values(report.nonproductiveVariables)}',
              ),
            ),
          Chip(
            label: Text(
              '${l10n.localizeWorkflowText('Sources')}: '
              '${values(report.sourceVariables)}',
            ),
          ),
          Chip(
            label: Text(
              '${l10n.localizeWorkflowText('Sinks')}: '
              '${values(report.sinkVariables)}',
            ),
          ),
          Chip(
            label: Text(
              '${l10n.localizeWorkflowText('Recursive components')}: '
              '${formatter.integer(report.cycleWitnesses.length)}',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionDetails(
    BuildContext context,
    VariableDependencyGraphReport report,
  ) {
    final l10n = appLocalizationsOf(context);
    final formatter = LocaleValueFormatter.of(context);
    final selectedEdge = _selectedEdgeId == null
        ? null
        : report.edgeById(_selectedEdgeId!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.localizeWorkflowText('Dependencies and provenance'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final edge in report.edges)
              ChoiceChip(
                key: ValueKey('vdg-edge-${edge.id}'),
                selected: edge.id == _selectedEdgeId,
                label: Text(
                  '${edge.from} → ${edge.to} '
                  '(${formatter.integer(edge.contributions.length)})',
                ),
                onSelected: (_) => setState(() {
                  _selectedEdgeId = edge.id;
                  _selectedVariable = null;
                }),
              ),
          ],
        ),
        if (selectedEdge != null) ...[
          const SizedBox(height: 8),
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${selectedEdge.from} → ${selectedEdge.to}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  for (final contribution in selectedEdge.contributions)
                    Text(
                      '${contribution.productionId}: '
                      '${l10n.localizeWorkflowText('LHS position')} '
                      '${formatter.integer(contribution.leftPosition + 1)}, '
                      '${l10n.localizeWorkflowText('RHS position')} '
                      '${formatter.integer(contribution.rightPosition + 1)}',
                    ),
                ],
              ),
            ),
          ),
        ],
        if (_selectedVariable != null) ...[
          const SizedBox(height: 8),
          Card(
            key: const ValueKey('vdg-variable-details'),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.localizeWorkflowText('Selected variable')}: '
                    '$_selectedVariable · '
                    '${l10n.localizeWorkflowText('Dependencies')}: '
                    '${formatter.integer(report.edges.where((edge) => edge.from == _selectedVariable || edge.to == _selectedVariable).length)}',
                  ),
                  if (report.reachabilityWitnesses[_selectedVariable]
                      case final VariableDependencyPathWitness witness) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.localizeWorkflowText('Reachability witness')}: '
                      '${witness.variables.join(' → ')}',
                    ),
                    if (witness.productionIds.isNotEmpty)
                      Text(
                        '${l10n.localizeWorkflowText('Productions')}: '
                        '${witness.productionIds.join(', ')}',
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
        if (report.cycleWitnesses.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            l10n.localizeWorkflowText('Recursion witnesses'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          for (var index = 0; index < report.cycleWitnesses.length; index++)
            ListTile(
              key: ValueKey('vdg-cycle-${index + 1}'),
              minTileHeight: 48,
              leading: const Icon(Icons.loop),
              title: Text(report.cycleWitnesses[index].variables.join(' → ')),
              subtitle: Text(
                '${l10n.localizeWorkflowText('Productions')}: '
                '${report.cycleWitnesses[index].productionIds.join(', ')} · '
                '${l10n.localizeWorkflowText('Edges')}: '
                '${report.cycleWitnesses[index].edgeIds.join(', ')}',
              ),
              onTap: () => setState(() {
                _selectedEdgeId = report.cycleWitnesses[index].edgeIds.first;
                _selectedVariable = null;
              }),
            ),
        ],
      ],
    );
  }

  Future<void> _analyze() async {
    final serial = ++_requestSerial;
    final request = widget.unrestrictedGrammar == null
        ? _VariableDependencyAnalysisRequest.contextFree(
            widget.contextFreeGrammar!,
            widget.sourceRevision,
            _mode,
          )
        : _VariableDependencyAnalysisRequest.unrestricted(
            widget.unrestrictedGrammar!,
            _mode,
          );
    setState(() {
      _analyzing = true;
      _error = null;
      _selectedEdgeId = null;
      _selectedVariable = null;
    });
    try {
      final report = await Isolate.run(request.run);
      if (!mounted || serial != _requestSerial) return;
      setState(() {
        _report = report;
        _analyzing = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitGraph());
    } on Object catch (error) {
      if (!mounted || serial != _requestSerial) return;
      setState(() {
        _error = error;
        _analyzing = false;
      });
    }
  }

  void _fitGraph() {
    if (!mounted) return;
    _transformationController.value = Matrix4.identity();
  }

  void _setZoom(double factor) {
    final current = _transformationController.value.getMaxScaleOnAxis();
    final target = (current * factor).clamp(0.25, 4.0);
    _transformationController.value = Matrix4.diagonal3Values(
      target,
      target,
      1,
    );
  }

  Future<void> _exportSvg(VariableDependencyGraphReport report) async {
    final l10n = appLocalizationsOf(context);
    final path = await _exportService.saveSvg(
      suggestedName: _safeName(widget.grammarName),
      dialogTitle: l10n.localizeWorkflowText('Export SVG'),
      svg: VariableDependencyGraphExporter.toSvg(
        report,
        title: l10n.localizeWorkflowText('Variable dependency graph'),
        description: _accessibleSummary(l10n, report),
        layoutMode: _layout,
      ),
    );
    if (!mounted || path == null) return;
    showAppSnackBar(
      context,
      message: appLocalizationsOf(
        context,
      ).localizeWorkflowText('Variable dependency graph exported.'),
    );
  }

  Future<void> _exportPng(VariableDependencyGraphReport report) async {
    final dialogTitle = appLocalizationsOf(
      context,
    ).localizeWorkflowText('Export PNG');
    final boundary = _repaintKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) return;
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (data == null) return;
    final path = await _exportService.savePng(
      suggestedName: _safeName(widget.grammarName),
      dialogTitle: dialogTitle,
      bytes: data.buffer.asUint8List(),
    );
    if (!mounted || path == null) return;
    showAppSnackBar(
      context,
      message: appLocalizationsOf(
        context,
      ).localizeWorkflowText('Variable dependency graph exported.'),
    );
  }
}

final class _VariableDependencyAnalysisRequest {
  const _VariableDependencyAnalysisRequest.contextFree(
    this.contextFreeGrammar,
    this.sourceRevision,
    this.mode,
  ) : unrestrictedGrammar = null;

  const _VariableDependencyAnalysisRequest.unrestricted(
    this.unrestrictedGrammar,
    this.mode,
  ) : contextFreeGrammar = null,
      sourceRevision = 0;

  final Grammar? contextFreeGrammar;
  final UnrestrictedGrammar? unrestrictedGrammar;
  final int sourceRevision;
  final VariableDependencyMode mode;

  VariableDependencyGraphReport run() => unrestrictedGrammar == null
      ? VariableDependencyGraphAnalyzer.analyzeContextFree(
          contextFreeGrammar!,
          sourceRevision: sourceRevision,
          mode: mode,
        )
      : VariableDependencyGraphAnalyzer.analyzeUnrestricted(
          unrestrictedGrammar!,
          mode: mode,
        );
}

final class _GraphViewport extends StatelessWidget {
  const _GraphViewport({
    required this.report,
    required this.layout,
    required this.selectedEdgeId,
    required this.selectedVariable,
    required this.transformationController,
    required this.repaintKey,
    required this.onEdgeSelected,
    required this.onVariableSelected,
  });

  final VariableDependencyGraphReport report;
  final VariableDependencyLayout layout;
  final String? selectedEdgeId;
  final String? selectedVariable;
  final TransformationController transformationController;
  final GlobalKey repaintKey;
  final ValueChanged<String> onEdgeSelected;
  final ValueChanged<String> onVariableSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final positions = VariableDependencyGraphExporter.layout(report, layout);
    return Container(
      key: const ValueKey('vdg-viewport'),
      height: 430,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        image: true,
        label: _accessibleSummary(l10n, report),
        child: Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is! KeyDownEvent || report.variables.isEmpty) {
              return KeyEventResult.ignored;
            }
            if (event.logicalKey != LogicalKeyboardKey.arrowRight &&
                event.logicalKey != LogicalKeyboardKey.arrowDown &&
                event.logicalKey != LogicalKeyboardKey.arrowLeft &&
                event.logicalKey != LogicalKeyboardKey.arrowUp) {
              return KeyEventResult.ignored;
            }
            final current = selectedVariable == null
                ? -1
                : report.variables.indexOf(selectedVariable!);
            final forward =
                event.logicalKey == LogicalKeyboardKey.arrowRight ||
                event.logicalKey == LogicalKeyboardKey.arrowDown;
            final next = forward
                ? (current + 1) % report.variables.length
                : (current <= 0 ? report.variables.length : current) - 1;
            onVariableSelected(report.variables[next]);
            return KeyEventResult.handled;
          },
          child: InteractiveViewer(
            transformationController: transformationController,
            minScale: 0.25,
            maxScale: 4,
            constrained: false,
            boundaryMargin: const EdgeInsets.all(160),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) => _selectAt(details.localPosition, positions),
              child: RepaintBoundary(
                key: repaintKey,
                child: CustomPaint(
                  size: const Size(
                    VariableDependencyGraphExporter.canvasWidth,
                    VariableDependencyGraphExporter.canvasHeight,
                  ),
                  painter: _VariableDependencyPainter(
                    report: report,
                    positions: positions,
                    selectedEdgeId: selectedEdgeId,
                    selectedVariable: selectedVariable,
                    colorScheme: Theme.of(context).colorScheme,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _selectAt(Offset point, Map<String, VariableDependencyPoint> positions) {
    for (final variable in report.variables) {
      final position = positions[variable]!;
      if ((point - Offset(position.x, position.y)).distance <=
          VariableDependencyGraphExporter.nodeRadius + 8) {
        onVariableSelected(variable);
        return;
      }
    }
    VariableDependencyEdge? closest;
    var distance = 18.0;
    for (final edge in report.edges) {
      final from = positions[edge.from]!;
      final to = positions[edge.to]!;
      final candidate = edge.from == edge.to
          ? (point - Offset(from.x, from.y - 58)).distance
          : _distanceToSegment(
              point,
              Offset(from.x, from.y),
              Offset(to.x, to.y),
            );
      if (candidate < distance) {
        distance = candidate;
        closest = edge;
      }
    }
    if (closest != null) onEdgeSelected(closest.id);
  }
}

final class _VariableDependencyPainter extends CustomPainter {
  const _VariableDependencyPainter({
    required this.report,
    required this.positions,
    required this.selectedEdgeId,
    required this.selectedVariable,
    required this.colorScheme,
  });

  final VariableDependencyGraphReport report;
  final Map<String, VariableDependencyPoint> positions;
  final String? selectedEdgeId;
  final String? selectedVariable;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = colorScheme.surface);
    for (final edge in report.edges) {
      final from = positions[edge.from]!;
      final to = positions[edge.to]!;
      final selected = edge.id == selectedEdgeId;
      final paint = Paint()
        ..color = selected ? colorScheme.tertiary : colorScheme.outline
        ..strokeWidth = selected ? 4 : 2
        ..style = PaintingStyle.stroke;
      if (edge.from == edge.to) {
        final rect = Rect.fromCircle(
          center: Offset(from.x, from.y - 42),
          radius: 28,
        );
        canvas.drawArc(rect, math.pi * 0.15, math.pi * 1.7, false, paint);
        _arrow(canvas, Offset(from.x + 26, from.y - 32), 1.2, paint.color);
      } else {
        final angle = math.atan2(to.y - from.y, to.x - from.x);
        final start = Offset(
          from.x + math.cos(angle) * 28,
          from.y + math.sin(angle) * 28,
        );
        final end = Offset(
          to.x - math.cos(angle) * 28,
          to.y - math.sin(angle) * 28,
        );
        canvas.drawLine(start, end, paint);
        _arrow(canvas, end, angle, paint.color);
      }
    }
    final recursive = <String>{
      for (final witness in report.cycleWitnesses) ...witness.variables,
    };
    for (final variable in report.variables) {
      final position = positions[variable]!;
      final selected = variable == selectedVariable;
      final fill = report.unreachableVariables.contains(variable)
          ? const Color(0xffffecb3)
          : report.nonproductiveVariables.contains(variable)
          ? const Color(0xffffcdd2)
          : recursive.contains(variable)
          ? const Color(0xffe1bee7)
          : const Color(0xffe3f2fd);
      canvas.drawCircle(
        Offset(position.x, position.y),
        28,
        Paint()..color = fill,
      );
      canvas.drawCircle(
        Offset(position.x, position.y),
        28,
        Paint()
          ..color = selected ? colorScheme.primary : colorScheme.onSurface
          ..strokeWidth = selected ? 4 : 2
          ..style = PaintingStyle.stroke,
      );
      final text = TextPainter(
        text: TextSpan(
          text: variable,
          style: TextStyle(
            color: const Color(0xff102027),
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: 48);
      text.paint(
        canvas,
        Offset(position.x - text.width / 2, position.y - text.height / 2),
      );
    }
  }

  void _arrow(Canvas canvas, Offset tip, double angle, Color color) {
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        tip.dx - 12 * math.cos(angle - 0.45),
        tip.dy - 12 * math.sin(angle - 0.45),
      )
      ..lineTo(
        tip.dx - 12 * math.cos(angle + 0.45),
        tip.dy - 12 * math.sin(angle + 0.45),
      )
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_VariableDependencyPainter oldDelegate) =>
      oldDelegate.report != report ||
      oldDelegate.positions != positions ||
      oldDelegate.selectedEdgeId != selectedEdgeId ||
      oldDelegate.selectedVariable != selectedVariable ||
      oldDelegate.colorScheme != colorScheme;
}

final class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.width,
    required this.color,
    required this.label,
  });

  final double width;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(child: Text(label)),
      ],
    ),
  );
}

final class _StatusMessage extends StatelessWidget {
  const _StatusMessage({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    ),
  );
}

double _distanceToSegment(Offset point, Offset start, Offset end) {
  final dx = end.dx - start.dx;
  final dy = end.dy - start.dy;
  if (dx == 0 && dy == 0) return (point - start).distance;
  final t =
      (((point.dx - start.dx) * dx + (point.dy - start.dy) * dy) /
              (dx * dx + dy * dy))
          .clamp(0.0, 1.0);
  return (point - Offset(start.dx + t * dx, start.dy + t * dy)).distance;
}

String _modeLabel(BuildContext context, VariableDependencyMode mode) {
  final l10n = appLocalizationsOf(context);
  return l10n.localizeWorkflowText(switch (mode) {
    VariableDependencyMode.directOccurrence => 'Direct occurrence',
    VariableDependencyMode.leftCorner => 'Left corner',
    VariableDependencyMode.nullableAwareLeftCorner =>
      'Nullable-aware left corner',
  });
}

String _layoutLabel(BuildContext context, VariableDependencyLayout layout) {
  final l10n = appLocalizationsOf(context);
  return l10n.localizeWorkflowText(switch (layout) {
    VariableDependencyLayout.layered => 'Layered',
    VariableDependencyLayout.circular => 'Circular',
    VariableDependencyLayout.grid => 'Grid',
  });
}

String _accessibleSummary(
  AppLocalizations localizations,
  VariableDependencyGraphReport report,
) => report
    .accessibleSummaryMessages()
    .map(localizations.resolveStructuredMessage)
    .join(' ');

String _safeName(String value) {
  final sanitized = value.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '-');
  return sanitized.isEmpty ? 'variable-dependency-graph' : '$sanitized-vdg';
}
