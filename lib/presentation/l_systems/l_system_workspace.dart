import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/l_systems/l_systems.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_structured_messages.dart';
import '../../l10n/app_localizations_workflows.dart';
import '../localization/locale_value_formatter.dart';
import 'l_system_editor_controller.dart';
import 'l_system_png_rasterizer.dart';

typedef LSystemSvgExportCallback = void Function(LSystemVectorExport export);
typedef LSystemPngExportCallback = void Function(Uint8List bytes);

final class LSystemWorkspace extends StatefulWidget {
  const LSystemWorkspace({
    super.key,
    required this.controller,
    this.pngRasterizer = const FlutterLSystemPngRasterizer(),
    this.onSvgExport,
    this.onPngExport,
  });

  final LSystemEditorController controller;
  final LSystemPngRasterizer pngRasterizer;
  final LSystemSvgExportCallback? onSvgExport;
  final LSystemPngExportCallback? onPngExport;

  @override
  State<LSystemWorkspace> createState() => _LSystemWorkspaceState();
}

final class _LSystemWorkspaceState extends State<LSystemWorkspace> {
  final _axiomController = TextEditingController();
  final _rulesController = TextEditingController();
  final _iterationsController = TextEditingController();
  final _angleController = TextEditingController();
  final _stepController = TextEditingController();
  final _scaleController = TextEditingController();
  final _headingController = TextEditingController();
  final _originXController = TextEditingController();
  final _originYController = TextEditingController();
  final _lineWidthController = TextEditingController();
  final _lineWidthIncrementController = TextEditingController();
  final _hueIncrementController = TextEditingController();
  final _randomSeedController = TextEditingController();
  final _ignoredContextController = TextEditingController();
  final _mappingController = TextEditingController();
  final _viewportController = TransformationController();
  final _editorFocus = FocusNode();
  final _rulesFocus = FocusNode();
  final _mappingFocus = FocusNode();
  final _iterationsFocus = FocusNode();
  final _angleFocus = FocusNode();
  final _stepFocus = FocusNode();
  final _scaleFocus = FocusNode();
  final _headingFocus = FocusNode();
  final _originXFocus = FocusNode();
  final _originYFocus = FocusNode();
  final _lineWidthFocus = FocusNode();
  final _lineWidthIncrementFocus = FocusNode();
  final _hueIncrementFocus = FocusNode();
  final _randomSeedFocus = FocusNode();
  final _ignoredContextFocus = FocusNode();
  Timer? _playTimer;
  String? _draftError;
  FocusNode? _draftErrorFocus;
  String? _draftLocaleTag;
  Map<TextEditingController, String> _lastFormattedNumericDraft = const {};

  @override
  void initState() {
    super.initState();
    _loadDraft();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.run();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    if (_draftLocaleTag == null) {
      _formatNumericDraft();
    } else if (_draftLocaleTag != localeTag) {
      _reformatNumericDraftPreservingEdits();
    }
    _draftLocaleTag = localeTag;
  }

  @override
  void didUpdateWidget(covariant LSystemWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _stopPlaying();
      _loadDraft();
      _formatNumericDraft();
      _draftLocaleTag = Localizations.localeOf(context).toLanguageTag();
      widget.controller.run();
    }
  }

  @override
  void dispose() {
    _stopPlaying();
    _axiomController.dispose();
    _rulesController.dispose();
    _iterationsController.dispose();
    _angleController.dispose();
    _stepController.dispose();
    _scaleController.dispose();
    _headingController.dispose();
    _originXController.dispose();
    _originYController.dispose();
    _lineWidthController.dispose();
    _lineWidthIncrementController.dispose();
    _hueIncrementController.dispose();
    _randomSeedController.dispose();
    _ignoredContextController.dispose();
    _mappingController.dispose();
    _viewportController.dispose();
    _editorFocus.dispose();
    _rulesFocus.dispose();
    _mappingFocus.dispose();
    _iterationsFocus.dispose();
    _angleFocus.dispose();
    _stepFocus.dispose();
    _scaleFocus.dispose();
    _headingFocus.dispose();
    _originXFocus.dispose();
    _originYFocus.dispose();
    _lineWidthFocus.dispose();
    _lineWidthIncrementFocus.dispose();
    _hueIncrementFocus.dispose();
    _randomSeedFocus.dispose();
    _ignoredContextFocus.dispose();
    super.dispose();
  }

  T _readDraft<T>(FocusNode focusNode, T Function() read) {
    try {
      return read();
    } on Object {
      _draftErrorFocus = focusNode;
      rethrow;
    }
  }

  void _loadDraft() {
    final document = widget.controller.document;
    _axiomController.text = document.axiom.symbols.join(' ');
    _rulesController.text = document.productions
        .map(_formatProduction)
        .join('\n');
    _iterationsController.text = '${document.iterations}';
    _angleController.text = '${document.turtle.angleDegrees}';
    _stepController.text = '${document.turtle.stepLength}';
    _scaleController.text = '${document.turtle.scale}';
    _headingController.text = '${document.turtle.initialHeadingDegrees}';
    _originXController.text = '${document.turtle.initialX}';
    _originYController.text = '${document.turtle.initialY}';
    _lineWidthController.text = '${document.turtle.lineWidth}';
    _lineWidthIncrementController.text =
        '${document.turtle.lineWidthIncrement}';
    _hueIncrementController.text = '${document.turtle.hueIncrementDegrees}';
    _randomSeedController.text = '${document.randomSeed}';
    _ignoredContextController.text = document.ignoredContextSymbols
        .toList()
        .join(' ');
    _mappingController.text =
        (document.commandMapping.commands.entries.toList()
              ..sort((left, right) => left.key.compareTo(right.key)))
            .map((entry) => '${entry.key} = ${entry.value.name}')
            .join('\n');
    _draftError = null;
  }

  void _formatNumericDraft() {
    final formatter = LocaleValueFormatter.of(context);
    final document = widget.controller.document;
    final formatted = _formattedNumericDraft(formatter, document);
    for (final entry in formatted.entries) {
      entry.key.text = entry.value;
    }
    _lastFormattedNumericDraft = Map.unmodifiable(formatted);
  }

  void _reformatNumericDraftPreservingEdits() {
    final formatted = _formattedNumericDraft(
      LocaleValueFormatter.of(context),
      widget.controller.document,
    );
    final nextBaseline = Map<TextEditingController, String>.of(
      _lastFormattedNumericDraft,
    );
    for (final entry in formatted.entries) {
      final controller = entry.key;
      if (_lastFormattedNumericDraft[controller] == controller.text) {
        controller.text = entry.value;
        nextBaseline[controller] = entry.value;
      }
    }
    _lastFormattedNumericDraft = Map.unmodifiable(nextBaseline);
  }

  Map<TextEditingController, String> _formattedNumericDraft(
    LocaleValueFormatter formatter,
    LSystemDocument document,
  ) => {
    _iterationsController: formatter.integer(document.iterations),
    _angleController: _formatDraftDouble(
      formatter,
      document.turtle.angleDegrees,
    ),
    _stepController: _formatDraftDouble(formatter, document.turtle.stepLength),
    _scaleController: _formatDraftDouble(formatter, document.turtle.scale),
    _headingController: _formatDraftDouble(
      formatter,
      document.turtle.initialHeadingDegrees,
    ),
    _originXController: _formatDraftDouble(formatter, document.turtle.initialX),
    _originYController: _formatDraftDouble(formatter, document.turtle.initialY),
    _lineWidthController: _formatDraftDouble(
      formatter,
      document.turtle.lineWidth,
    ),
    _lineWidthIncrementController: _formatDraftDouble(
      formatter,
      document.turtle.lineWidthIncrement,
    ),
    _hueIncrementController: _formatDraftDouble(
      formatter,
      document.turtle.hueIncrementDegrees,
    ),
    _randomSeedController: formatter.integer(document.randomSeed),
  };

  Future<void> _applyDraft() async {
    _draftErrorFocus = null;
    try {
      final current = widget.controller.document;
      final iterations = _readDraft(
        _iterationsFocus,
        () => _parseLocalizedInteger(context, _iterationsController.text),
      );
      final angle = _readDraft(
        _angleFocus,
        () => _parseLocalizedDouble(context, _angleController.text),
      );
      final step = _readDraft(
        _stepFocus,
        () => _parseLocalizedDouble(context, _stepController.text),
      );
      final scale = _readDraft(
        _scaleFocus,
        () => _parseLocalizedDouble(context, _scaleController.text),
      );
      final heading = _readDraft(
        _headingFocus,
        () => _parseLocalizedDouble(context, _headingController.text),
      );
      final originX = _readDraft(
        _originXFocus,
        () => _parseLocalizedDouble(context, _originXController.text),
      );
      final originY = _readDraft(
        _originYFocus,
        () => _parseLocalizedDouble(context, _originYController.text),
      );
      final lineWidth = _readDraft(
        _lineWidthFocus,
        () => _parseLocalizedDouble(context, _lineWidthController.text),
      );
      final lineWidthIncrement = _readDraft(
        _lineWidthIncrementFocus,
        () =>
            _parseLocalizedDouble(context, _lineWidthIncrementController.text),
      );
      final hueIncrement = _readDraft(
        _hueIncrementFocus,
        () => _parseLocalizedDouble(context, _hueIncrementController.text),
      );
      final randomSeed = _readDraft(
        _randomSeedFocus,
        () => _parseLocalizedInteger(context, _randomSeedController.text),
      );
      if (iterations < 0) {
        _draftErrorFocus = _iterationsFocus;
        throw const FormatException('Iterations must be zero or greater.');
      }
      final rules = _readDraft(_rulesFocus, () {
        final rules = <LSystemProduction>[];
        final lines = _rulesController.text.split(RegExp(r'\r?\n'));
        for (var index = 0; index < lines.length; index++) {
          final line = lines[index].trim();
          if (line.isEmpty) continue;
          final separator = line.indexOf('->');
          if (separator < 0) {
            throw FormatException('Rule ${index + 1} must contain ->.');
          }
          final parsed = _parseProductionLeft(
            line.substring(0, separator),
            lineNumber: index + 1,
          );
          final prior = index < current.productions.length
              ? current.productions[index]
              : null;
          rules.add(
            LSystemProduction(
              id: prior?.id ?? 'rule-${current.revision + 1}-$index',
              predecessor: parsed.predecessor,
              successor: LSystemWord(_tokenize(line.substring(separator + 2))),
              leftContext: LSystemWord(parsed.leftContext),
              rightContext: LSystemWord(parsed.rightContext),
              weight: parsed.weight,
            ),
          );
        }
        return rules;
      });
      final next = current.copyWith(
        revision: current.revision + 1,
        axiom: LSystemWord(_tokenize(_axiomController.text)),
        productions: rules,
        iterations: iterations,
        turtle: LSystemTurtleSettings(
          angleDegrees: angle,
          stepLength: step,
          scale: scale,
          initialHeadingDegrees: heading,
          initialX: originX,
          initialY: originY,
          lineWidth: lineWidth,
          lineWidthIncrement: lineWidthIncrement,
          hueIncrementDegrees: hueIncrement,
          initialColorArgb: current.turtle.initialColorArgb,
          initialPolygonColorArgb: current.turtle.initialPolygonColorArgb,
        ),
        commandMapping: _readDraft(
          _mappingFocus,
          () => _parseCommandMapping(_mappingController.text),
        ),
        randomSeed: randomSeed,
        ignoredContextSymbols: _tokenize(_ignoredContextController.text),
      );
      setState(() => _draftError = null);
      widget.controller.replaceDocument(next);
      await widget.controller.run();
      if (mounted) _formatNumericDraft();
    } on Object catch (error) {
      setState(() => _draftError = _friendlyError(context, error));
      (_draftErrorFocus ?? _editorFocus).requestFocus();
    }
  }

  void _undo() {
    widget.controller.undo();
    _loadDraft();
    _formatNumericDraft();
    setState(() {});
    widget.controller.run();
  }

  void _redo() {
    widget.controller.redo();
    _loadDraft();
    _formatNumericDraft();
    setState(() {});
    widget.controller.run();
  }

  void _togglePlaying() {
    if (_playTimer != null) {
      setState(_stopPlaying);
      return;
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _localized(
              context,
              'Animation is disabled by reduced-motion settings.',
            ),
          ),
        ),
      );
      return;
    }
    var generation = widget.controller.generation?.index ?? 0;
    setState(() {
      _playTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
        final maximum = widget.controller.document.iterations;
        if (generation >= maximum) {
          timer.cancel();
          if (mounted) setState(() => _playTimer = null);
          return;
        }
        generation++;
        widget.controller.run(generation: generation);
      });
    });
  }

  void _stopPlaying() {
    _playTimer?.cancel();
    _playTimer = null;
  }

  void _zoom(double factor) {
    _viewportController.value = _viewportController.value.clone()
      ..scaleByDouble(factor, factor, factor, 1);
  }

  Future<void> _exportSvg() async {
    final geometry = widget.controller.geometry;
    final generation = widget.controller.generation;
    if (geometry == null || generation == null) return;
    final export = const LSystemSvgExporter().encode(
      geometry,
      metadata: _metadata(generation.index),
    );
    widget.onSvgExport?.call(export);
    _announceExport('SVG export ready.');
  }

  Future<void> _exportPng() async {
    final geometry = widget.controller.geometry;
    final generation = widget.controller.generation;
    if (geometry == null || generation == null) return;
    final bytes = await widget.pngRasterizer.encode(
      geometry,
      metadata: _metadata(generation.index),
    );
    if (!mounted) return;
    widget.onPngExport?.call(bytes);
    _announceExport('PNG export ready.');
  }

  LSystemRenderMetadata _metadata(int generation) => LSystemRenderMetadata(
    documentId: widget.controller.document.id,
    sourceRevision: widget.controller.document.revision,
    generation: generation,
    settings: widget.controller.document.turtle,
  );

  void _announceExport(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_localized(context, message))));
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final wide = MediaQuery.sizeOf(context).width >= 900;
      final editor = _EditorPanel(
        axiomController: _axiomController,
        rulesController: _rulesController,
        iterationsController: _iterationsController,
        angleController: _angleController,
        stepController: _stepController,
        scaleController: _scaleController,
        headingController: _headingController,
        originXController: _originXController,
        originYController: _originYController,
        lineWidthController: _lineWidthController,
        lineWidthIncrementController: _lineWidthIncrementController,
        hueIncrementController: _hueIncrementController,
        randomSeedController: _randomSeedController,
        ignoredContextController: _ignoredContextController,
        mappingController: _mappingController,
        error: _draftError,
        focusNode: _editorFocus,
        rulesFocus: _rulesFocus,
        mappingFocus: _mappingFocus,
        iterationsFocus: _iterationsFocus,
        angleFocus: _angleFocus,
        stepFocus: _stepFocus,
        scaleFocus: _scaleFocus,
        headingFocus: _headingFocus,
        originXFocus: _originXFocus,
        originYFocus: _originYFocus,
        lineWidthFocus: _lineWidthFocus,
        lineWidthIncrementFocus: _lineWidthIncrementFocus,
        hueIncrementFocus: _hueIncrementFocus,
        randomSeedFocus: _randomSeedFocus,
        ignoredContextFocus: _ignoredContextFocus,
        onApply: _applyDraft,
      );
      final visualization = _VisualizationPanel(
        controller: widget.controller,
        viewportController: _viewportController,
        canUndo: widget.controller.canUndo,
        canRedo: widget.controller.canRedo,
        expanding: widget.controller.isExpanding,
        playing: _playTimer != null,
        onUndo: _undo,
        onRedo: _redo,
        onCancel: widget.controller.cancel,
        onPlay: _togglePlaying,
        onZoomIn: () => _zoom(1.25),
        onZoomOut: () => _zoom(0.8),
        onReset: () => _viewportController.value = Matrix4.identity(),
        onExportSvg: _exportSvg,
        onExportPng: _exportPng,
      );
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 400, child: editor),
                    const SizedBox(width: 12),
                    Expanded(child: visualization),
                  ],
                )
              else ...[
                editor,
                const SizedBox(height: 12),
                visualization,
              ],
            ],
          ),
        ),
      );
    },
  );
}

final class _EditorPanel extends StatelessWidget {
  const _EditorPanel({
    required this.axiomController,
    required this.rulesController,
    required this.iterationsController,
    required this.angleController,
    required this.stepController,
    required this.scaleController,
    required this.headingController,
    required this.originXController,
    required this.originYController,
    required this.lineWidthController,
    required this.lineWidthIncrementController,
    required this.hueIncrementController,
    required this.randomSeedController,
    required this.ignoredContextController,
    required this.mappingController,
    required this.error,
    required this.focusNode,
    required this.rulesFocus,
    required this.mappingFocus,
    required this.iterationsFocus,
    required this.angleFocus,
    required this.stepFocus,
    required this.scaleFocus,
    required this.headingFocus,
    required this.originXFocus,
    required this.originYFocus,
    required this.lineWidthFocus,
    required this.lineWidthIncrementFocus,
    required this.hueIncrementFocus,
    required this.randomSeedFocus,
    required this.ignoredContextFocus,
    required this.onApply,
  });

  final TextEditingController axiomController;
  final TextEditingController rulesController;
  final TextEditingController iterationsController;
  final TextEditingController angleController;
  final TextEditingController stepController;
  final TextEditingController scaleController;
  final TextEditingController headingController;
  final TextEditingController originXController;
  final TextEditingController originYController;
  final TextEditingController lineWidthController;
  final TextEditingController lineWidthIncrementController;
  final TextEditingController hueIncrementController;
  final TextEditingController randomSeedController;
  final TextEditingController ignoredContextController;
  final TextEditingController mappingController;
  final String? error;
  final FocusNode focusNode;
  final FocusNode rulesFocus;
  final FocusNode mappingFocus;
  final FocusNode iterationsFocus;
  final FocusNode angleFocus;
  final FocusNode stepFocus;
  final FocusNode scaleFocus;
  final FocusNode headingFocus;
  final FocusNode originXFocus;
  final FocusNode originYFocus;
  final FocusNode lineWidthFocus;
  final FocusNode lineWidthIncrementFocus;
  final FocusNode hueIncrementFocus;
  final FocusNode randomSeedFocus;
  final FocusNode ignoredContextFocus;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              _localized(context, 'Definition'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: axiomController,
            focusNode: focusNode,
            decoration: InputDecoration(
              labelText: _localized(context, 'Axiom tokens'),
              helperText: _localized(context, 'Separate symbols with spaces.'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: rulesController,
            focusNode: rulesFocus,
            minLines: 4,
            maxLines: 10,
            decoration: InputDecoration(
              labelText: _localized(context, 'Parallel production rules'),
              helperText: _localized(
                context,
                'Use F -> F + F, or L < F > R @2 -> G for contexts and weights.',
              ),
              alignLabelWithHint: true,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: mappingController,
            focusNode: mappingFocus,
            minLines: 3,
            maxLines: 8,
            decoration: InputDecoration(
              labelText: _localized(context, 'Turtle command mapping'),
              helperText: _localized(
                context,
                'One token = command per line, for example F = drawForward.',
              ),
              alignLabelWithHint: true,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 120,
                child: TextField(
                  controller: iterationsController,
                  focusNode: iterationsFocus,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: _localized(context, 'Iterations'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: angleController,
                  focusNode: angleFocus,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: _localized(context, 'Angle °'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: stepController,
                  focusNode: stepFocus,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: _localized(context, 'Step length'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: scaleController,
                  focusNode: scaleFocus,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: _localized(context, 'Scale'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: headingController,
                  focusNode: headingFocus,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: InputDecoration(
                    labelText: _localized(context, 'Heading °'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: originXController,
                  focusNode: originXFocus,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: InputDecoration(
                    labelText: _localized(context, 'Origin X'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: originYController,
                  focusNode: originYFocus,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: InputDecoration(
                    labelText: _localized(context, 'Origin Y'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: lineWidthController,
                  focusNode: lineWidthFocus,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: _localized(context, 'Line width'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: lineWidthIncrementController,
                  focusNode: lineWidthIncrementFocus,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: _localized(context, 'Width change'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: hueIncrementController,
                  focusNode: hueIncrementFocus,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: InputDecoration(
                    labelText: _localized(context, 'Hue change °'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: randomSeedController,
                  focusNode: randomSeedFocus,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                  ),
                  decoration: InputDecoration(
                    labelText: _localized(context, 'Random seed'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(
                width: 252,
                child: TextField(
                  controller: ignoredContextController,
                  focusNode: ignoredContextFocus,
                  decoration: InputDecoration(
                    labelText: _localized(context, 'Context-ignored tokens'),
                    helperText: _localized(
                      context,
                      'Space-separated, for example + - [ ].',
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onApply,
            icon: const Icon(Icons.refresh),
            label: Text(_localized(context, 'Apply and expand')),
          ),
        ],
      ),
    ),
  );
}

final class _VisualizationPanel extends StatelessWidget {
  const _VisualizationPanel({
    required this.controller,
    required this.viewportController,
    required this.canUndo,
    required this.canRedo,
    required this.expanding,
    required this.playing,
    required this.onUndo,
    required this.onRedo,
    required this.onCancel,
    required this.onPlay,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
    required this.onExportSvg,
    required this.onExportPng,
  });

  final LSystemEditorController controller;
  final TransformationController viewportController;
  final bool canUndo;
  final bool canRedo;
  final bool expanding;
  final bool playing;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onCancel;
  final VoidCallback onPlay;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;
  final VoidCallback onExportSvg;
  final VoidCallback onExportPng;

  @override
  Widget build(BuildContext context) {
    final generation = controller.generation;
    final geometry = controller.geometry;
    final valueFormatter = LocaleValueFormatter.of(context);
    final status = _statusText(context, controller);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              key: const Key('l-system-visualization-toolbar'),
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    IconButton(
                      key: const Key('l-system-undo'),
                      tooltip: _localized(context, 'Undo edit'),
                      onPressed: canUndo ? onUndo : null,
                      icon: const Icon(Icons.undo),
                    ),
                    IconButton(
                      key: const Key('l-system-redo'),
                      tooltip: _localized(context, 'Redo edit'),
                      onPressed: canRedo ? onRedo : null,
                      icon: const Icon(Icons.redo),
                    ),
                    if (expanding)
                      FilledButton.tonalIcon(
                        onPressed: onCancel,
                        icon: const Icon(Icons.stop),
                        label: Text(_localized(context, 'Cancel expansion')),
                      ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    IconButton(
                      tooltip: _localized(
                        context,
                        playing
                            ? 'Pause generation playback'
                            : 'Play generations',
                      ),
                      onPressed: onPlay,
                      icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                    ),
                    IconButton(
                      tooltip: _localized(context, 'Zoom in'),
                      onPressed: onZoomIn,
                      icon: const Icon(Icons.zoom_in),
                    ),
                    IconButton(
                      tooltip: _localized(context, 'Zoom out'),
                      onPressed: onZoomOut,
                      icon: const Icon(Icons.zoom_out),
                    ),
                    IconButton(
                      tooltip: _localized(context, 'Reset viewport'),
                      onPressed: onReset,
                      icon: const Icon(Icons.fit_screen),
                    ),
                    IconButton(
                      tooltip: _localized(context, 'Export SVG'),
                      onPressed: geometry == null ? null : onExportSvg,
                      icon: const Icon(Icons.code),
                    ),
                    IconButton(
                      tooltip: _localized(context, 'Export PNG'),
                      onPressed: geometry == null ? null : onExportPng,
                      icon: const Icon(Icons.image_outlined),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (controller.document.iterations > 0)
              MergeSemantics(
                child: Semantics(
                  label: valueFormatter.integersInLocalizedText(
                    _localized(
                      context,
                      'Generation ${generation?.index ?? 0} of ${controller.document.iterations}',
                    ),
                    [generation?.index ?? 0, controller.document.iterations],
                  ),
                  child: Slider(
                    value: math.min(
                      (generation?.index ?? 0).toDouble(),
                      controller.document.iterations.toDouble(),
                    ),
                    min: 0,
                    max: controller.document.iterations.toDouble(),
                    divisions: controller.document.iterations,
                    label: valueFormatter.integer(generation?.index ?? 0),
                    semanticFormatterCallback: (value) =>
                        valueFormatter.integer(value.round()),
                    onChanged: controller.isExpanding
                        ? null
                        : (value) => controller.run(generation: value.round()),
                  ),
                ),
              ),
            Semantics(
              liveRegion: true,
              child: Text(status, key: const Key('l-system-status')),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 420,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: geometry == null
                    ? Center(
                        child: controller.isExpanding
                            ? const CircularProgressIndicator()
                            : Text(
                                _localized(context, 'No geometry to display.'),
                              ),
                      )
                    : Semantics(
                        image: true,
                        label: _geometryDescription(
                          context,
                          geometry,
                          generation,
                        ),
                        child: InteractiveViewer(
                          transformationController: viewportController,
                          minScale: 0.1,
                          maxScale: 20,
                          child: CustomPaint(
                            key: const Key('l-system-canvas'),
                            painter: _LSystemGeometryPainter(
                              geometry,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Semantics(
              header: true,
              child: Text(
                _localized(context, 'Generated tokens'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 4),
            SelectableText(
              _wordPreview(context, generation?.word),
              key: const Key('l-system-generated-word'),
            ),
          ],
        ),
      ),
    );
  }
}

final class _LSystemGeometryPainter extends CustomPainter {
  const _LSystemGeometryPainter(this.geometry, {required this.color});

  final LSystemGeometry geometry;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final transform = LSystemFitTransform.contain(
      geometry.bounds,
      viewportWidth: size.width,
      viewportHeight: size.height,
      padding: 20,
    );
    for (final polygon in geometry.polygons) {
      final path = Path();
      for (var index = 0; index < polygon.coordinates.length; index += 2) {
        final x =
            polygon.coordinates[index] * transform.scale + transform.translateX;
        final y =
            polygon.coordinates[index + 1] * transform.scale +
            transform.translateY;
        if (index == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..color = Color(polygon.colorArgb)
          ..style = PaintingStyle.fill,
      );
    }
    for (var segment = 0; segment < geometry.segmentCount; segment++) {
      final index = segment * 4;
      final segmentColor = geometry.segmentColorsArgb[segment] == 0xff111827
          ? color
          : Color(geometry.segmentColorsArgb[segment]);
      canvas.drawLine(
        Offset(
          geometry.segmentCoordinates[index] * transform.scale +
              transform.translateX,
          geometry.segmentCoordinates[index + 1] * transform.scale +
              transform.translateY,
        ),
        Offset(
          geometry.segmentCoordinates[index + 2] * transform.scale +
              transform.translateX,
          geometry.segmentCoordinates[index + 3] * transform.scale +
              transform.translateY,
        ),
        Paint()
          ..color = segmentColor
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = geometry.segmentWidths[segment],
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LSystemGeometryPainter oldDelegate) =>
      oldDelegate.geometry != geometry || oldDelegate.color != color;
}

LSystemCommandMapping _parseCommandMapping(String source) {
  final commands = <String, LSystemTurtleCommand>{};
  final lines = source.split(RegExp(r'\r?\n'));
  for (var index = 0; index < lines.length; index++) {
    final line = lines[index].trim();
    if (line.isEmpty) continue;
    final separator = line.indexOf('=');
    if (separator < 1) {
      throw FormatException('Command mapping ${index + 1} must contain =.');
    }
    final symbol = line.substring(0, separator).trim();
    final commandName = line.substring(separator + 1).trim();
    if (symbol.isEmpty || symbol.contains(RegExp(r'\s'))) {
      throw FormatException(
        'Command mapping ${index + 1} must start with one token.',
      );
    }
    if (commands.containsKey(symbol)) {
      throw FormatException('Duplicate command mapping for $symbol.');
    }
    try {
      commands[symbol] = LSystemTurtleCommand.values.byName(commandName);
    } on ArgumentError {
      throw FormatException(
        'Command mapping ${index + 1} uses an unknown command.',
      );
    }
  }
  return LSystemCommandMapping(commands);
}

String _formatProduction(LSystemProduction production) {
  final context =
      production.leftContext.isEmpty && production.rightContext.isEmpty
      ? production.predecessor
      : '${production.leftContext.symbols.join(' ')} < '
            '${production.predecessor} > '
            '${production.rightContext.symbols.join(' ')}';
  final weight = production.weight == 1 ? '' : ' @${production.weight}';
  return '${context.trim()}$weight -> ${production.successor.symbols.join(' ')}';
}

({
  List<String> leftContext,
  String predecessor,
  List<String> rightContext,
  double weight,
})
_parseProductionLeft(String source, {required int lineNumber}) {
  var definition = source.trim();
  var weight = 1.0;
  final weightMatch = RegExp(
    r'\s+@([+-]?(?:\d+(?:\.\d*)?|\.\d+))\s*$',
  ).firstMatch(definition);
  if (weightMatch != null) {
    weight = double.parse(weightMatch.group(1)!);
    definition = definition.substring(0, weightMatch.start).trim();
  }
  final opening = definition.indexOf('<');
  final closing = definition.lastIndexOf('>');
  if ((opening < 0) != (closing < 0) || closing < opening) {
    throw FormatException('Rule $lineNumber has an incomplete context marker.');
  }
  if (opening < 0) {
    final tokens = _tokenize(definition);
    if (tokens.length != 1) {
      throw FormatException(
        'Rule $lineNumber must have one predecessor token.',
      );
    }
    return (
      leftContext: const [],
      predecessor: tokens.single,
      rightContext: const [],
      weight: weight,
    );
  }
  final predecessor = _tokenize(definition.substring(opening + 1, closing));
  if (predecessor.length != 1) {
    throw FormatException(
      'Rule $lineNumber must have one token between < and >.',
    );
  }
  return (
    leftContext: _tokenize(definition.substring(0, opening)),
    predecessor: predecessor.single,
    rightContext: _tokenize(definition.substring(closing + 1)),
    weight: weight,
  );
}

List<String> _tokenize(String source) => source
    .trim()
    .split(RegExp(r'\s+'))
    .where((symbol) => symbol.isNotEmpty)
    .toList(growable: false);

String _formatDraftDouble(LocaleValueFormatter formatter, double value) {
  if (!value.isFinite) return value.toString();
  final raw = value.toString();
  final decimalIndex = raw.indexOf('.');
  if (decimalIndex < 0 || raw.contains('e') || raw.contains('E')) {
    return raw;
  }
  return formatter.decimal(value, decimalDigits: raw.length - decimalIndex - 1);
}

int _parseLocalizedInteger(BuildContext context, String source) {
  final format = NumberFormat.decimalPattern(
    Localizations.localeOf(context).toLanguageTag(),
  );
  final trimmed = source.trim();
  final decimalSeparator = format.symbols.DECIMAL_SEP;
  if (trimmed.contains(decimalSeparator) &&
      !_isGroupingForm(trimmed, decimalSeparator)) {
    throw const FormatException('Expected a whole number.');
  }
  var normalized = trimmed.replaceAll(format.symbols.GROUP_SEP, '');
  final alternateGroupSeparator = format.symbols.GROUP_SEP == ',' ? '.' : ',';
  if (_isGroupingForm(normalized, alternateGroupSeparator)) {
    normalized = normalized.replaceAll(alternateGroupSeparator, '');
  }
  return int.parse(normalized);
}

double _parseLocalizedDouble(BuildContext context, String source) {
  final format = NumberFormat.decimalPattern(
    Localizations.localeOf(context).toLanguageTag(),
  );
  final decimalSeparator = format.symbols.DECIMAL_SEP;
  final groupSeparator = format.symbols.GROUP_SEP;
  final trimmed = source.trim();
  final dotIndex = trimmed.lastIndexOf('.');
  final commaIndex = trimmed.lastIndexOf(',');
  var normalized = trimmed;
  if (dotIndex >= 0 && commaIndex >= 0) {
    final decimal = dotIndex > commaIndex ? '.' : ',';
    final grouping = decimal == '.' ? ',' : '.';
    normalized = normalized.replaceAll(grouping, '').replaceAll(decimal, '.');
  } else if (dotIndex >= 0 || commaIndex >= 0) {
    final separator = dotIndex >= 0 ? '.' : ',';
    final occurrences = separator == '.'
        ? '.'.allMatches(trimmed).length
        : ','.allMatches(trimmed).length;
    if (occurrences > 1) {
      if (_isGroupingForm(trimmed, separator)) {
        normalized = normalized.replaceAll(separator, '');
      }
    } else if (separator == decimalSeparator) {
      normalized = normalized.replaceAll(separator, '.');
    } else if (separator == groupSeparator) {
      normalized = _isGroupingForm(trimmed, separator)
          ? normalized.replaceAll(separator, '')
          : normalized.replaceAll(separator, '.');
    } else {
      // Accept a decimal typed with the other locale's separator so an edit
      // survives a locale switch before it is applied.
      normalized = normalized.replaceAll(separator, '.');
    }
  }
  return double.parse(normalized);
}

bool _isGroupingForm(String source, String separator) {
  final parts = source.split(separator);
  if (parts.length < 2 || parts.first.isEmpty) return false;
  final first = parts.first.replaceFirst(RegExp(r'^[+-]'), '');
  return first.isNotEmpty &&
      _allDigits(first) &&
      parts.skip(1).every((part) => part.length == 3 && _allDigits(part));
}

bool _allDigits(String value) =>
    value.isNotEmpty &&
    value.codeUnits.every((unit) => unit >= 48 && unit <= 57);

String _localized(BuildContext context, String source) =>
    appLocalizationsOf(context).localizeWorkflowText(source);

String _friendlyError(BuildContext context, Object error) =>
    _localized(context, switch (error) {
      FormatException() => error.message,
      _ => 'The L-system definition is invalid.',
    });

String _statusText(BuildContext context, LSystemEditorController controller) {
  final generation = controller.generation;
  final geometry = controller.geometry;
  final summary = generation == null
      ? ''
      : ' ${LocaleValueFormatter.of(context).integersInLocalizedText(_localized(context, 'Generation ${generation.index} has ${generation.word.length} tokens'
        '${geometry == null ? '.' : ' and ${geometry.segmentCount} segments.'}'), [generation.index, generation.word.length, if (geometry != null) geometry.segmentCount])}';
  final fallback = switch (controller.status) {
    LSystemEditorStatus.idle => 'Ready.',
    LSystemEditorStatus.expanding => 'Expanding in parallel…',
    LSystemEditorStatus.complete => 'Expansion complete.',
    LSystemEditorStatus.bounded => '',
    LSystemEditorStatus.cancelled => 'Expansion cancelled.',
    LSystemEditorStatus.invalid => 'The L-system is invalid.',
  };
  final messages = controller.messages;
  final resolved = messages.isEmpty
      ? _localized(context, fallback)
      : messages
            .map(appLocalizationsOf(context).resolveStructuredMessage)
            .join(' ');
  return '$resolved$summary';
}

String _geometryDescription(
  BuildContext context,
  LSystemGeometry geometry,
  LSystemGeneration? generation,
) => LocaleValueFormatter.of(context).integersInLocalizedText(
  _localized(
    context,
    'Turtle rendering for generation ${generation?.index ?? 0}, '
    '${geometry.segmentCount} line segments, maximum branch depth '
    '${geometry.maximumBranchDepth}.',
  ),
  [generation?.index ?? 0, geometry.segmentCount, geometry.maximumBranchDepth],
);

String _wordPreview(BuildContext context, LSystemWord? word) {
  if (word == null) return _localized(context, 'No generated word.');
  const maximum = 500;
  final visible = word.symbols.take(maximum).join(' ');
  if (word.length <= maximum) {
    return visible.isEmpty ? _localized(context, 'Empty word.') : visible;
  }
  final overflowCount = word.length - maximum;
  final overflow = LocaleValueFormatter.of(context).integersInLocalizedText(
    _localized(context, '$overflowCount more tokens'),
    [overflowCount],
  );
  return '$visible … ($overflow)';
}
