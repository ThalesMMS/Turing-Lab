import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/batch_execution/batch_execution.dart';
import '../../core/formal_systems/formal_systems.dart';
import '../../core/models/simulation_highlight.dart';
import '../../core/services/canvas_highlight_coordinator.dart';
import '../../core/transducers/transducers.dart';
import '../../features/canvas/graphview/graphview_highlight_channel.dart';
import '../../injection/data_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_structured_messages.dart';
import '../providers/workspace_quick_actions_provider.dart';
import '../widgets/automaton_canvas_tool.dart';
import '../widgets/batch_execution/batch_execution_panel.dart';
import '../widgets/automaton_graphview_canvas.dart';
import '../widgets/automaton_workspace_scaffold.dart';
import '../widgets/canvas_simulation_playback_bar.dart';
import '../widgets/canvas_simulation_step_projection.dart';
import '../widgets/common/workspace_help.dart';
import '../widgets/graphview_canvas_toolbar.dart';
import '../widgets/workspace_dock.dart';
import 'graphview_transducer_canvas_controller.dart';
import 'transducer_editor_state.dart';
import 'transducer_batch_comparison_panel.dart';
import 'transducer_batch_comparison_strings.dart';
import 'transducer_examples_panel.dart';
import 'transducer_machine_panel.dart';
import 'transducer_simulation_panel.dart';
import 'transducer_state_editor.dart';
import 'transducer_transition_editor.dart';
import 'transducer_workspace_definition.dart';

typedef TransducerToolsPanelBuilder<
  TMachine extends DeterministicFiniteStateTransducer
> = Widget Function(BuildContext context, TMachine machine);

class TransducerWorkspace<TMachine extends DeterministicFiniteStateTransducer>
    extends ConsumerStatefulWidget {
  const TransducerWorkspace({
    super.key,
    required this.provider,
    required this.definition,
    required this.helpTopicId,
    this.toolsPanelBuilder,
    this.exampleTextResolver,
  });

  final StateNotifierProvider<
    TransducerEditorNotifier<TMachine>,
    TransducerEditorState<TMachine>
  >
  provider;
  final TransducerWorkspaceDefinition<TMachine> definition;
  final String helpTopicId;
  final TransducerToolsPanelBuilder<TMachine>? toolsPanelBuilder;
  final TransducerExampleTextResolver? exampleTextResolver;

  @override
  ConsumerState<TransducerWorkspace<TMachine>> createState() =>
      _TransducerWorkspaceState<TMachine>();
}

final class _TransducerWorkspaceState<
  TMachine extends DeterministicFiniteStateTransducer
>
    extends ConsumerState<TransducerWorkspace<TMachine>>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final GlobalKey _canvasKey = GlobalKey();
  final AutomatonCanvasToolController _toolController =
      AutomatonCanvasToolController();
  final WorkspaceDockController _dockController = WorkspaceDockController();
  final FocusNode _simulationInputFocus = FocusNode(
    debugLabel: 'Transducer simulation input',
  );
  late final GraphViewTransducerCanvasController<TMachine> _controller;
  late final CanvasHighlightCoordinator _highlightCoordinator;
  late final CanvasHighlightSourceHandle _simulationHighlights;
  late final TabController _toolsTabsController;
  ExampleCatalogCapability<Object>? _examplesCatalog;
  bool? _lastCompactLayout;
  List<TransducerExecutionStep>? _canvasSimulationSteps;
  CanvasHighlightTarget? _canvasSimulationTarget;
  int _canvasSimulationStepIndex = 0;
  Object _canvasSimulationPlaybackKey = Object();
  EdgeInsets _canvasToolbarInsets = EdgeInsets.zero;
  BuildContext? _compactSheetContext;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _toolsTabsController = TabController(length: 2, vsync: this);
    _controller = GraphViewTransducerCanvasController<TMachine>(
      notifier: ref.read(widget.provider.notifier),
      definition: widget.definition,
    );
    final initialDocument = ref.read(widget.provider).document;
    _controller.synchronize(initialDocument);
    _highlightCoordinator = CanvasHighlightCoordinator(
      target: _highlightTarget(initialDocument),
      output: GraphViewSimulationHighlightChannel(_controller),
    );
    _simulationHighlights = _highlightCoordinator.source(
      CanvasHighlightSource.simulation,
    );
    _resolveExamplesCatalog();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _simulationHighlights.dispose();
    _highlightCoordinator.dispose();
    _controller.dispose();
    _toolController.dispose();
    _dockController.dispose();
    _simulationInputFocus.dispose();
    _toolsTabsController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;
    final view = View.of(context);
    final logicalWidth = view.physicalSize.width / view.devicePixelRatio;
    final compact = logicalWidth < AutomatonWorkspaceScaffold.mobileBreakpoint;
    final sheetContext = _compactSheetContext;
    if (compact && _dockController.openPanelId != null) {
      _dockController.closePanel(restoreFocus: false);
    } else if (!compact && sheetContext != null) {
      final route = ModalRoute.of(sheetContext);
      if (route != null) Navigator.of(sheetContext).removeRoute(route);
    }
  }

  /// Resolves the module's example catalog once; the examples tab handles
  /// loading, failure, and empty states itself.
  void _resolveExamplesCatalog() {
    _examplesCatalog = ref
        .read(formalSystemRegistryProvider)
        .moduleFor(widget.definition.systemKey)
        ?.examples;
  }

  bool get _isCompact =>
      MediaQuery.sizeOf(context).width <
      AutomatonWorkspaceScaffold.mobileBreakpoint;

  TransducerSimulationPanel<TMachine> _simulationPanel({
    required TransducerEditorState<TMachine> state,
    ScrollController? scrollController,
    FocusNode? inputFocusNode,
    bool showTitle = true,
  }) => TransducerSimulationPanel<TMachine>(
    state: state,
    notifier: ref.read(widget.provider.notifier),
    controller: _controller,
    highlightChannel: _simulationHighlights,
    definition: widget.definition,
    scrollController: scrollController,
    inputFocusNode: inputFocusNode,
    showTitle: showTitle,
    onViewOnCanvas: supportsCanvasSimulationPlayback(context)
        ? _startCanvasSimulation
        : null,
  );

  void _startCanvasSimulation(List<TransducerExecutionStep> steps) {
    if (steps.isEmpty || !supportsCanvasSimulationPlayback(context)) return;
    final recorded = List<TransducerExecutionStep>.unmodifiable(steps);
    final document = ref.read(widget.provider).document;
    setState(() {
      _canvasSimulationSteps = recorded;
      _canvasSimulationTarget = _highlightTarget(document);
      _canvasSimulationStepIndex = 0;
      _canvasSimulationPlaybackKey = Object();
    });
    _handleCanvasSimulationStep(0);
    final sheetContext = _compactSheetContext;
    if (sheetContext != null && sheetContext.mounted) {
      Navigator.of(sheetContext).maybePop();
    }
  }

  void _handleCanvasSimulationStep(int stepIndex) {
    final steps = _canvasSimulationSteps;
    if (steps == null || stepIndex < 0 || stepIndex >= steps.length) return;
    _canvasSimulationStepIndex = stepIndex;
    ref.read(widget.provider.notifier).setTraceIndex(stepIndex);
    _applyCanvasSimulationHighlight(steps, stepIndex);
  }

  void _applyCanvasSimulationHighlight(
    List<TransducerExecutionStep> steps,
    int index,
  ) {
    final step = steps[index];
    _simulationHighlights.send(
      SimulationHighlight(
        stateIds: {step.targetStateId.value},
        transitionIds: {step.transitionId.value},
      ),
    );
  }

  void _stopCanvasSimulation() {
    if (_canvasSimulationSteps != null && mounted) {
      setState(() {
        _canvasSimulationSteps = null;
        _canvasSimulationTarget = null;
        _canvasSimulationStepIndex = 0;
      });
    }
    _simulationHighlights.clear();
  }

  void _handleCanvasToolbarInsetsChanged(EdgeInsets insets) {
    if (!mounted || _canvasToolbarInsets == insets) return;
    setState(() => _canvasToolbarInsets = insets);
  }

  void _openSimulationSurface() {
    if (!mounted) return;
    if (!_isCompact) {
      _dockController.openPanel(
        AutomatonWorkspaceScaffold.simulationPanelId,
        returnFocusTo: FocusManager.instance.primaryFocus,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _simulationInputFocus.canRequestFocus) {
          _simulationInputFocus.requestFocus();
        }
      });
      return;
    }
    final title = appLocalizationsOf(context).transducerSimulationTitle;
    unawaited(
      _showCompactSheet(
        title: title,
        sheetKey: const Key('transducer-simulation-sheet'),
        builder: (sheetContext, scrollController) => Consumer(
          builder: (context, sheetRef, _) => _simulationPanel(
            state: sheetRef.watch(widget.provider),
            scrollController: scrollController,
            showTitle: false,
          ),
        ),
      ),
    );
  }

  void _openToolsSurface() {
    if (!mounted) return;
    if (!_isCompact) {
      _toolsTabsController.index = 0;
      _dockController.openPanel(AutomatonWorkspaceScaffold.algorithmPanelId);
      return;
    }
    unawaited(
      _showCompactSheet(
        title: appLocalizationsOf(context).algorithmsAndExamples,
        sheetKey: const Key('transducer-tools-sheet'),
        builder: (sheetContext, _) => Consumer(
          builder: (context, sheetRef, _) {
            final editorState = sheetRef.watch(widget.provider);
            final formalSystems = sheetRef.watch(formalSystemRegistryProvider);
            final interoperability = sheetRef.watch(
              documentInteroperabilityRegistryProvider,
            );
            final machine = editorState.document;
            final examples = formalSystems
                .moduleFor(widget.definition.systemKey)
                ?.examples;
            final comparison = TransducerBatchComparisonPanel<TMachine>(
              machine: machine,
              simulatorFor: widget.definition.simulator,
              strings: _batchStrings(appLocalizationsOf(context)),
              selectComparisonMachine: examples == null
                  ? null
                  : () => _selectComparisonMachine(examples),
            );
            final tools =
                widget.toolsPanelBuilder?.call(context, machine) ??
                _TransducerBatchTools(
                  machine: machine,
                  exactComparison: comparison,
                );
            final machinePanel = TransducerMachinePanel<TMachine>(
              machine: machine,
              controller: _controller,
              systemKey: widget.definition.systemKey,
              schema: widget.definition.schema,
              registry: interoperability,
              formalSystems: formalSystems,
              replaceDocument: sheetRef
                  .read(widget.provider.notifier)
                  .replaceDocument,
            );
            final examplesPanel = TransducerExamplesPanel<Object>(
              catalog: _examplesCatalog,
              textResolver: widget.exampleTextResolver,
              payloadFilter: (payload) => payload is TMachine,
              onLoad: (document) {
                if (!mounted || document is! TMachine) return;
                ref.read(widget.provider.notifier).replaceDocument(document);
                Navigator.of(sheetContext).pop();
              },
            );
            return _TransducerCompactTools(
              tools: tools,
              machine: machinePanel,
              examples: examplesPanel,
            );
          },
        ),
      ),
    );
  }

  Future<void> _showCompactSheet({
    required String title,
    required Key sheetKey,
    required Widget Function(BuildContext context, ScrollController controller)
    builder,
  }) {
    final future = showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      requestFocus: true,
      builder: (sheetContext) {
        _compactSheetContext = sheetContext;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) => Semantics(
            namesRoute: true,
            label: title,
            child: Material(
              key: sheetKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          key: const Key('transducer-sheet-close'),
                          tooltip: MaterialLocalizations.of(
                            sheetContext,
                          ).closeButtonTooltip,
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(child: builder(context, scrollController)),
                ],
              ),
            ),
          ),
        );
      },
    );
    future.whenComplete(() {
      if (mounted) _compactSheetContext = null;
    });
    return future;
  }

  void _showMutationError() {
    if (!mounted) return;
    final l10n = appLocalizationsOf(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.transducerInvalidTransition),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<TMachine?> _selectComparisonMachine(
    ExampleCatalogCapability<Object>? catalog,
  ) async {
    if (catalog == null) return null;
    final examples = await catalog.loadExamples();
    if (!mounted) return null;
    return showDialog<TMachine>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(appLocalizationsOf(context).transducerCompareWithExample),
        children: [
          for (final example in examples)
            if (example.payload is TMachine)
              SimpleDialogOption(
                onPressed: () =>
                    Navigator.of(context).pop(example.payload as TMachine),
                child: Text(
                  widget.exampleTextResolver?.call(context, example).name ??
                      (example.nameMessage == null
                          ? example.name
                          : appLocalizationsOf(
                              context,
                            ).resolveStructuredMessage(example.nameMessage!)),
                ),
              ),
        ],
      ),
    );
  }

  AutomatonGraphViewCanvasCustomization _customization(TMachine machine) {
    final isMealy = widget.definition.emissionRule is MealyEmissionRule;
    return AutomatonGraphViewCanvasCustomization(
      supportsAcceptingStates: false,
      nodeSemanticsDetails: (l10n, node) {
        final output = node.secondaryLabel;
        if (output == null) return null;
        return l10n.transducerStateOutputSemantics(
          output == '[]' ? l10n.transducerEmptyOutput : output,
        );
      },
      edgeSemanticsDetails: (l10n, edge) {
        final input = edge.readSymbol ?? edge.symbols.join(' · ');
        final output = edge.transducerOutput;
        if (output == null) return l10n.transducerInputOnlySemantics(input);
        return l10n.transducerTransitionSemantics(
          input,
          output.values.isEmpty
              ? l10n.transducerEmptyOutput
              : output.values.join(' · '),
        );
      },
      stateOptionsHandler: (dialogContext, node, _) async {
        final state = machine.states.firstWhere(
          (candidate) => candidate.id.value == node.id,
        );
        final edit = await showTransducerStateEditor(
          dialogContext,
          node: node,
          emissionRule: widget.definition.emissionRule,
          stateOutput: state is MooreState ? state.output : null,
          onDelete: () => _controller.removeState(node.id),
          outputValidator: (output) {
            final error = _controller.validateStateOutput(node.id, output);
            return error == null
                ? null
                : appLocalizationsOf(
                    dialogContext,
                  ).transducerOutputOutsideAlphabet;
          },
        );
        if (edit == null || !mounted) return;
        try {
          _controller.updateStateDetails(
            id: node.id,
            label: edit.label,
            isInitial: edit.isInitial,
            outputTokens: edit.outputTokens,
          );
        } on ArgumentError {
          _showMutationError();
        }
      },
      transitionConfigBuilder: (_) => AutomatonGraphViewTransitionConfig(
        initialPayloadBuilder: (edge) => AutomatonTransducerTransitionPayload(
          input: edge?.readSymbol ?? '',
          outputTokens: edge?.transducerOutput?.values ?? const [],
        ),
        overlayBuilder: (context, data, overlayController) {
          final payload = data.payload as AutomatonTransducerTransitionPayload;
          return TransducerTransitionEditor(
            initialInput: payload.input,
            initialOutput: payload.outputTokens,
            showOutput: isMealy,
            validator: (input, output) {
              final error = _controller.validateTransitionDraft(
                fromStateId: data.fromStateId,
                toStateId: data.toStateId,
                transitionId: data.transitionId,
                draft: TransducerTransitionDraft(
                  input: input,
                  outputTokens: isMealy ? output : null,
                ),
              );
              return switch (error) {
                TransducerEditError.inputRequired => (
                  inputError: appLocalizationsOf(
                    context,
                  ).transducerInputRequired,
                  outputError: null,
                ),
                TransducerEditError.inputOutsideAlphabet => (
                  inputError: appLocalizationsOf(
                    context,
                  ).transducerInputOutsideAlphabet,
                  outputError: null,
                ),
                TransducerEditError.duplicateInput => (
                  inputError: appLocalizationsOf(
                    context,
                  ).transducerDuplicateInput,
                  outputError: null,
                ),
                TransducerEditError.outputOutsideAlphabet => (
                  inputError: null,
                  outputError: appLocalizationsOf(
                    context,
                  ).transducerOutputOutsideAlphabet,
                ),
                null => (inputError: null, outputError: null),
                _ => (
                  inputError: appLocalizationsOf(
                    context,
                  ).transducerInvalidTransition,
                  outputError: null,
                ),
              };
            },
            onCancel: overlayController.cancel,
            onDelete: data.transitionId == null
                ? null
                : () => overlayController.submit(
                    const AutomatonDeleteTransitionPayload(),
                  ),
            onSubmit: (input, output) => overlayController.submit(
              AutomatonTransducerTransitionPayload(
                input: input,
                outputTokens: output,
              ),
            ),
          );
        },
        persistTransition: (request) {
          if (request.payload is AutomatonDeleteTransitionPayload) {
            final id = request.transitionId;
            if (id != null) _controller.removeTransition(id);
            return;
          }
          final payload =
              request.payload as AutomatonTransducerTransitionPayload;
          try {
            _controller.putTransition(
              fromStateId: request.fromStateId,
              toStateId: request.toStateId,
              transitionId: request.transitionId,
              draft: TransducerTransitionDraft(
                input: payload.input,
                outputTokens: isMealy ? payload.outputTokens : null,
              ),
            );
          } on ArgumentError {
            _showMutationError();
          }
        },
      ),
    );
  }

  Widget _canvas(TMachine machine, {required bool isMobile}) {
    return Stack(
      children: [
        Positioned.fill(
          child: AutomatonGraphViewCanvas(
            automaton: machine,
            canvasKey: _canvasKey,
            controller: _controller,
            toolController: _toolController,
            customization: _customization(machine),
            annotationConfig: AutomatonCanvasAnnotationConfig(
              systemKey: widget.definition.systemKey,
              documentId: machine.id.value,
              documentRevision: '${machine.revision.value}',
            ),
            fragmentImportSystemKey: widget.definition.systemKey,
            fragmentImportDocumentId: machine.id.value,
            fragmentImportDocumentRevision: '${machine.revision.value}',
          ),
        ),
        if (isMobile)
          if (_canvasSimulationSteps case final steps?)
            Positioned(
              left: 16,
              right: 16,
              bottom: _canvasToolbarInsets.bottom + 16,
              child: CanvasSimulationPlaybackBar(
                key: ObjectKey(_canvasSimulationPlaybackKey),
                stepCount: steps.length,
                initialStep: _canvasSimulationStepIndex,
                words: projectTransducerInputSteps(steps),
                onStepChanged: _handleCanvasSimulationStep,
                onClose: _stopCanvasSimulation,
              ),
            ),
        AnimatedBuilder(
          animation: _toolController,
          builder: (context, _) => GraphViewCanvasToolbar(
            controller: _controller,
            placement: isMobile
                ? CanvasToolbarPlacement.bottomCenter
                : CanvasToolbarPlacement.topRight,
            onViewportInsetsChanged: _handleCanvasToolbarInsetsChanged,
            enableToolSelection: true,
            showSelectionTool: true,
            activeTool: _toolController.activeTool,
            onSelectTool: () =>
                _toolController.setActiveTool(AutomatonCanvasTool.selection),
            onAddState: () =>
                _toolController.toggleTool(AutomatonCanvasTool.addState),
            onAddTransition: () =>
                _toolController.toggleTool(AutomatonCanvasTool.transition),
            onClear: _handleClearCanvas,
            onHelp: () => showWorkspaceHelp(
              context: context,
              topicId: widget.helpTopicId,
            ),
          ),
        ),
      ],
    );
  }

  void _handleClearCanvas() {
    _stopCanvasSimulation();
    _controller.clearCanvas();
  }

  @override
  Widget build(BuildContext context) {
    final compactLayout = _isCompact;
    final previousCompactLayout = _lastCompactLayout;
    if (previousCompactLayout != compactLayout) {
      _lastCompactLayout = compactLayout;
      if (previousCompactLayout == true &&
          !compactLayout &&
          _canvasSimulationSteps != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isCompact) {
            _stopCanvasSimulation();
          }
        });
      }
      if (compactLayout && _dockController.openPanelId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _isCompact) {
            _dockController.closePanel(restoreFocus: false);
          }
        });
      }
    }
    final editorState = ref.watch(widget.provider);
    final machine = editorState.document;
    final highlightTarget = _highlightTarget(machine);
    _controller.synchronize(machine);
    _highlightCoordinator.retarget(highlightTarget);
    if (_canvasSimulationSteps != null &&
        _canvasSimulationTarget != highlightTarget) {
      // The trace belongs to another document revision; drop stale playback.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _stopCanvasSimulation();
      });
    }
    final activeTraceIndex = editorState.activeTraceIndex;
    final canvasSteps = _canvasSimulationSteps;
    if (canvasSteps != null &&
        activeTraceIndex != null &&
        activeTraceIndex >= 0 &&
        activeTraceIndex < canvasSteps.length &&
        activeTraceIndex != _canvasSimulationStepIndex) {
      _canvasSimulationStepIndex = activeTraceIndex;
      _canvasSimulationPlaybackKey = Object();
    }
    final notifier = ref.read(widget.provider.notifier);
    final formalSystems = ref.watch(formalSystemRegistryProvider);
    final interoperability = ref.watch(
      documentInteroperabilityRegistryProvider,
    );
    final examples = formalSystems
        .moduleFor(widget.definition.systemKey)
        ?.examples;
    final simulation = _simulationPanel(
      state: editorState,
      inputFocusNode: _simulationInputFocus,
    );
    final legacyTools = TransducerBatchComparisonPanel<TMachine>(
      machine: machine,
      simulatorFor: widget.definition.simulator,
      strings: _batchStrings(appLocalizationsOf(context)),
      selectComparisonMachine: examples == null
          ? null
          : () => _selectComparisonMachine(examples),
    );
    final tools =
        widget.toolsPanelBuilder?.call(context, machine) ??
        _TransducerBatchTools(machine: machine, exactComparison: legacyTools);
    final examplesPanel = TransducerExamplesPanel<Object>(
      catalog: examples,
      textResolver: widget.exampleTextResolver,
      payloadFilter: (payload) => payload is TMachine,
      onLoad: (document) {
        if (document is TMachine) {
          notifier.replaceDocument(document);
          _dockController.closePanel();
        }
      },
    );
    final machinePanel = TransducerMachinePanel<TMachine>(
      machine: machine,
      controller: _controller,
      systemKey: widget.definition.systemKey,
      schema: widget.definition.schema,
      registry: interoperability,
      formalSystems: formalSystems,
      replaceDocument: notifier.replaceDocument,
    );
    publishWorkspaceQuickActionsForKey(
      ref,
      widget.definition.systemKey,
      WorkspaceQuickActions(
        onSimulate: _openSimulationSurface,
        onAlgorithms: _openToolsSurface,
        algorithmsTooltip: appLocalizationsOf(
          context,
        ).workspaceAlgorithmsAndExamplesTooltip,
      ),
    );

    return AutomatonWorkspaceScaffold(
      dockController: _dockController,
      algorithmPanelScrollable: false,
      simulationPanelScrollable: false,
      canvasWithToolbar: ({required isMobile}) =>
          _canvas(machine, isMobile: isMobile),
      algorithmPanel: _WorkspaceToolsTabs(
        controller: _toolsTabsController,
        tools: tools,
        examples: examplesPanel,
      ),
      algorithmTabTitle: appLocalizationsOf(context).algorithmsAndExamples,
      simulationPanel: simulation,
      infoPanel: machinePanel,
    );
  }

  CanvasHighlightTarget _highlightTarget(TMachine machine) =>
      CanvasHighlightTarget(
        kind: AutomatonSurfaceKind.transducer,
        surface: machine,
        documentId: machine.id.value,
        revision: machine.revision.value,
      );
}

final class _TransducerCompactTools extends StatelessWidget {
  const _TransducerCompactTools({
    required this.tools,
    required this.machine,
    required this.examples,
  });

  final Widget tools;
  final Widget machine;
  final Widget examples;

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(
                icon: const Icon(Icons.compare_arrows),
                text: l10n.transducerBatch,
              ),
              Tab(
                icon: const Icon(Icons.tune),
                text: l10n.transducerMachineInfo,
              ),
              Tab(
                icon: const Icon(Icons.school_outlined),
                text: l10n.transducerExamples,
              ),
            ],
          ),
          Expanded(child: TabBarView(children: [tools, machine, examples])),
        ],
      ),
    );
  }
}

TransducerBatchComparisonStrings _batchStrings(AppLocalizations l10n) =>
    TransducerBatchComparisonStrings(
      batchTitle: l10n.transducerBatch,
      batchInputLabel: l10n.transducerBatchInputLabel,
      batchInputHelper: l10n.transducerBatchHint,
      runBatch: l10n.transducerRunBatch,
      batchEmpty: l10n.transducerBatchEmpty,
      batchSuccess: l10n.transducerBatchSuccess,
      batchUndefined: l10n.transducerUndefinedTransition,
      batchInvalidMachine: l10n.transducerInvalidMachine,
      batchInvalidInput: l10n.transducerInvalidInput,
      batchCancelled: l10n.transducerSimulationCancelled,
      batchBounded: l10n.transducerSimulationBounded,
      comparisonTitle: l10n.transducerComparison,
      comparisonModeLabel: l10n.transducerComparisonMode,
      exactMode: l10n.transducerComparisonExact,
      boundedMode: l10n.transducerComparisonBounded,
      boundLabel: l10n.transducerComparisonBound,
      chooseMachine: l10n.transducerCompareWithExample,
      machineSelectionFailed: l10n.transducerExamplesLoadFailed,
      compare: l10n.transducerCompare,
      noComparisonMachine: l10n.transducerNoComparisonMachine,
      exactEquivalent: l10n.transducerExactEquivalent,
      exactDifferent: l10n.transducerExactDifferent,
      boundedDifferent: l10n.transducerBoundedDifferent,
      boundedInconclusive: l10n.transducerBoundedInconclusive,
      comparisonInvalid: l10n.transducerComparisonInvalid,
      inputLabel: l10n.transducerInputTokens,
      outputLabel: l10n.transducerOutput,
      leftOutputLabel: l10n.transducerLeftOutput,
      rightOutputLabel: l10n.transducerRightOutput,
      witnessLabel: l10n.transducerWitness,
      invalidBatchLine: l10n.transducerInvalidBatchLine,
      selectedMachine: l10n.transducerSelectedMachine,
      exploredPairs: l10n.transducerExploredPairs,
    );

final class _WorkspaceToolsTabs extends StatelessWidget {
  const _WorkspaceToolsTabs({
    required this.controller,
    required this.tools,
    required this.examples,
  });

  final TabController controller;
  final Widget tools;
  final Widget examples;

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    return Column(
      children: [
        TabBar(
          controller: controller,
          tabs: [
            Tab(text: l10n.transducerBatch),
            Tab(text: l10n.transducerExamples),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: controller,
            children: [tools, examples],
          ),
        ),
      ],
    );
  }
}

final class _TransducerBatchTools extends StatelessWidget {
  const _TransducerBatchTools({
    required this.machine,
    required this.exactComparison,
  });

  final DeterministicFiniteStateTransducer machine;
  final Widget exactComparison;

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: l10n.transducerBatch),
              Tab(text: l10n.transducerComparison),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(8),
                  child: BatchExecutionPanel(
                    executor: TransducerBatchExecutor(machine),
                    alphabet: machine.inputAlphabet
                        .map((symbol) => symbol.value)
                        .toSet(),
                    title: l10n.transducerBatch,
                    initialStrategyId: 'simulate',
                    initialTokenizationMode:
                        BatchTokenizationMode.explicitTokens,
                  ),
                ),
                exactComparison,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
