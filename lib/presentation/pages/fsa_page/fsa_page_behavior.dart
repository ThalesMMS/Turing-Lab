part of '../fsa_page.dart';

extension _FSAPageStateBehavior on _FSAPageState {
  void _handleAddStatePressed() {
    if (_toolController.activeTool != AutomatonCanvasTool.addState) {
      _toolController.setActiveTool(AutomatonCanvasTool.addState);
    }
    _canvasController.addStateAtCenter();
  }

  void _showSnack(String message, {bool isError = false}) {
    showAppSnackBar(
      context,
      message: message,
      tone: isError ? AppSnackBarTone.error : AppSnackBarTone.success,
    );
  }

  FSA? _requireAutomaton({
    bool requireDfa = false,
    bool requireLambda = false,
    String? missingMessage,
    String? invalidMessage,
  }) {
    final automaton = ref.read(automatonStateProvider).currentAutomaton;
    if (automaton == null) {
      _showSnack(
        missingMessage ?? 'Load an automaton before running this operation.',
        isError: true,
      );
      return null;
    }

    if (requireDfa &&
        !(automaton.isDeterministic && !automaton.hasEpsilonTransitions)) {
      _showSnack(
        invalidMessage ??
            'This operation requires a deterministic automaton without ε-transitions.',
        isError: true,
      );
      return null;
    }

    if (requireLambda && !automaton.hasEpsilonTransitions) {
      _showSnack(
        invalidMessage ??
            'The current automaton does not contain λ-transitions.',
        isError: true,
      );
      return null;
    }

    return automaton;
  }

  Future<void> _runCurrentAutomatonOperation({
    required Future<void> Function(AutomatonAlgorithmNotifier notifier)
        operation,
    required String successMessage,
    bool requireDfa = false,
    bool requireLambda = false,
    String? invalidMessage,
  }) async {
    final automaton = _requireAutomaton(
      requireDfa: requireDfa,
      requireLambda: requireLambda,
      invalidMessage: invalidMessage,
    );
    if (automaton == null) return;

    final notifier = ref.read(automatonAlgorithmProvider.notifier);
    await operation(notifier);
    if (!mounted) return;

    final algorithmState = ref.read(automatonAlgorithmProvider);
    if (algorithmState.error != null) {
      _showSnack(algorithmState.error!, isError: true);
      notifier.clearError();
      return;
    }

    _showSnack(successMessage);
  }

  void _handleStepByStepModeChanged(bool enabled) {
    _updatePageState(() {
      _stepByStepMode = enabled;
    });
    if (!enabled) {
      ref.read(algorithmStepProvider.notifier).clearSteps();
    }
  }

  Future<void> _handleNfaToDfa() async {
    if (_stepByStepMode) {
      final automaton = _requireAutomaton();
      if (automaton == null) return;
      await ref
          .read(automatonAlgorithmProvider.notifier)
          .convertNfaToDfaWithSteps();
    } else {
      await ref.read(automatonAlgorithmProvider.notifier).convertNfaToDfa();
    }
  }

  Future<void> _handleMinimizeDfa() async {
    if (_stepByStepMode) {
      final automaton = _requireAutomaton(requireDfa: true);
      if (automaton == null) return;
      await ref
          .read(automatonAlgorithmProvider.notifier)
          .minimizeDfaWithSteps();
    } else {
      await ref.read(automatonAlgorithmProvider.notifier).minimizeDfa();
    }
  }

  Future<void> _handleRemoveLambda() async {
    await _runCurrentAutomatonOperation(
      operation: (notifier) => notifier.removeLambdaTransitions(),
      successMessage: 'λ-transitions removed successfully.',
      requireLambda: true,
      invalidMessage:
          'The current automaton must contain λ-transitions to remove them.',
    );
  }

  Future<void> _handleComplementDfa() async {
    await _runCurrentAutomatonOperation(
      operation: (notifier) => notifier.complementDfa(),
      successMessage: 'Complement computed successfully.',
      requireDfa: true,
      invalidMessage:
          'Complement is only available for deterministic automata without ε-transitions.',
    );
  }

  Future<void> _handlePrefixClosure() async {
    await _runCurrentAutomatonOperation(
      operation: (notifier) => notifier.prefixClosureDfa(),
      successMessage: 'Prefix closure computed successfully.',
      requireDfa: true,
      invalidMessage:
          'Prefix closure is only available for deterministic automata without ε-transitions.',
    );
  }

  Future<void> _handleSuffixClosure() async {
    await _runCurrentAutomatonOperation(
      operation: (notifier) => notifier.suffixClosureDfa(),
      successMessage: 'Suffix closure computed successfully.',
      requireDfa: true,
      invalidMessage:
          'Suffix closure is only available for deterministic automata without ε-transitions.',
    );
  }

  Future<void> _handleUnionDfa(FSA other) async {
    await _runCurrentAutomatonOperation(
      operation: (notifier) => notifier.unionDfa(other),
      successMessage: 'Union computed successfully.',
      requireDfa: true,
      invalidMessage:
          'Binary DFA operations require a deterministic automaton without ε-transitions.',
    );
  }

  Future<void> _handleIntersectionDfa(FSA other) async {
    await _runCurrentAutomatonOperation(
      operation: (notifier) => notifier.intersectionDfa(other),
      successMessage: 'Intersection computed successfully.',
      requireDfa: true,
      invalidMessage:
          'Binary DFA operations require a deterministic automaton without ε-transitions.',
    );
  }

  Future<void> _handleDifferenceDfa(FSA other) async {
    await _runCurrentAutomatonOperation(
      operation: (notifier) => notifier.differenceDfa(other),
      successMessage: 'Difference computed successfully.',
      requireDfa: true,
      invalidMessage:
          'Binary DFA operations require a deterministic automaton without ε-transitions.',
    );
  }

  Widget _buildStepViewerPanel() {
    final stepState = ref.watch(algorithmStepProvider);

    if (!stepState.hasSteps) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewerMaxHeight = constraints.maxHeight.isFinite
              ? (constraints.maxHeight - _kStepViewerNavigationControlsHeight)
                  .clamp(_kStepViewerMinHeight, _kStepViewerMaxHeight)
              : _kStepViewerDefaultHeight;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (stepState.currentStep != null)
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: viewerMaxHeight),
                  child: SingleChildScrollView(
                    child: AlgorithmStepViewer(step: stepState.currentStep!),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: StepNavigationControls(
                  currentStepIndex: stepState.currentStepIndex,
                  totalSteps: stepState.totalSteps,
                  isPlaying: stepState.isPlaying,
                  onPrevious: stepState.hasPreviousStep
                      ? () => ref
                          .read(algorithmStepProvider.notifier)
                          .previousStep()
                      : null,
                  onPlayPause: () => ref
                      .read(algorithmStepProvider.notifier)
                      .togglePlayPause(),
                  onNext: stepState.hasNextStep
                      ? () =>
                          ref.read(algorithmStepProvider.notifier).nextStep()
                      : null,
                  onReset: () => ref
                      .read(algorithmStepProvider.notifier)
                      .jumpToFirstStep(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  AlgorithmPanel _buildAlgorithmPanelForState(
    AutomatonStateProviderState state,
    AlgorithmOperationState algorithmState,
  ) {
    final automatonNotifier = ref.read(automatonStateProvider.notifier);
    final algorithmNotifier = ref.read(automatonAlgorithmProvider.notifier);
    final layoutNotifier = ref.read(automatonLayoutProvider.notifier);
    final automaton = state.currentAutomaton;
    final hasAutomaton = automaton != null;
    final hasLambda = automaton?.hasEpsilonTransitions ?? false;
    final isDfa = automaton != null &&
        automaton.isDeterministic &&
        !automaton.hasEpsilonTransitions;

    return AlgorithmPanel(
      currentAutomaton: hasAutomaton ? automaton : null,
      onNfaToDfa: hasAutomaton ? _handleNfaToDfa : null,
      onRemoveLambda: hasLambda ? _handleRemoveLambda : null,
      onMinimizeDfa: isDfa ? _handleMinimizeDfa : null,
      onCompleteDfa: isDfa ? () => algorithmNotifier.completeDfa() : null,
      onComplementDfa: isDfa ? _handleComplementDfa : null,
      onUnionDfa: isDfa ? _handleUnionDfa : null,
      onIntersectionDfa: isDfa ? _handleIntersectionDfa : null,
      onDifferenceDfa: isDfa ? _handleDifferenceDfa : null,
      onPrefixClosure: isDfa ? _handlePrefixClosure : null,
      onSuffixClosure: isDfa ? _handleSuffixClosure : null,
      onFsaToGrammar: hasAutomaton ? _handleFsaToGrammar : null,
      onAutoLayout:
          hasAutomaton ? () => layoutNotifier.applyAutoLayout() : null,
      onClear: () => automatonNotifier.clearAutomaton(),
      onRegexToNfa: (regex) => algorithmNotifier.convertRegexToNfa(regex),
      onFaToRegex: hasAutomaton ? _handleFaToRegex : null,
      onCompareEquivalence: isDfa ? _handleCompareEquivalence : null,
      equivalenceResult: algorithmState.equivalenceResult,
      equivalenceDetails: algorithmState.equivalenceDetails,
      onStepByStepModeChanged: _handleStepByStepModeChanged,
    );
  }

  Future<void> _handleFaToRegex() async {
    if (_stepByStepMode) {
      await _handleFaToRegexWithSteps();
    } else {
      final algorithmNotifier = ref.read(automatonAlgorithmProvider.notifier);
      final regex = await algorithmNotifier.convertFaToRegex();
      if (!mounted || regex == null) {
        final algorithmState = ref.read(automatonAlgorithmProvider);
        if (mounted && algorithmState.error != null) {
          _showSnack(algorithmState.error!, isError: true);
        }
        return;
      }

      if (!mounted) return;
      _showRegexResultDialog(regex, isStepByStep: false);
    }
  }

  Future<void> _handleFaToRegexWithSteps() async {
    final automaton = _requireAutomaton();
    if (automaton == null) return;

    final algorithmNotifier = ref.read(automatonAlgorithmProvider.notifier);
    final regex = await algorithmNotifier.convertFaToRegexWithSteps();
    if (!mounted || regex == null) {
      final algorithmState = ref.read(automatonAlgorithmProvider);
      if (mounted && algorithmState.error != null) {
        _showSnack(algorithmState.error!, isError: true);
      }
      return;
    }

    if (!mounted) return;
    _showRegexResultDialog(regex, isStepByStep: true);
  }

  void _showRegexResultDialog(String regex, {required bool isStepByStep}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isStepByStep
              ? 'FA to Regex Result (Step-by-Step)'
              : 'FA to Regex Result',
        ),
        content: SelectableText(regex),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleFsaToGrammar() async {
    final algorithmNotifier = ref.read(automatonAlgorithmProvider.notifier);
    final grammar = await algorithmNotifier.convertFsaToGrammar();
    if (!mounted || grammar == null) {
      final algorithmState = ref.read(automatonAlgorithmProvider);
      if (mounted && algorithmState.error != null) {
        _showSnack(algorithmState.error!, isError: true);
      }
      return;
    }

    if (!mounted) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const GrammarPage()));
  }

  Future<void> _handleCompareEquivalence(FSA other) async {
    await ref
        .read(automatonAlgorithmProvider.notifier)
        .compareEquivalence(other);
    if (!mounted) return;
    final message = ref.read(automatonAlgorithmProvider).equivalenceDetails;
    if (message != null) {
      _showSnack(message);
    }
  }

  void _showContextualHelp() {
    final automaton = ref.read(automatonStateProvider).currentAutomaton;

    // Determine the most relevant help content based on current automaton state
    String helpContextId;
    if (automaton == null) {
      helpContextId = 'usage_getting_started';
    } else if (automaton.hasEpsilonTransitions) {
      helpContextId = 'concept_nfa';
    } else if (automaton.isDeterministic) {
      helpContextId = 'concept_dfa';
    } else {
      helpContextId = 'concept_nfa';
    }

    showWorkspaceHelp(
      context: context,
      ref: ref,
      contextId: helpContextId,
    );
  }

  Widget _buildCanvasArea({
    required AutomatonStateProviderState state,
    required bool isMobile,
  }) {
    Widget buildGraphViewCanvas() {
      return AutomatonGraphViewCanvas(
        automaton: state.currentAutomaton,
        canvasKey: _canvasKey,
        controller: _canvasController,
        toolController: _toolController,
      );
    }

    final statusMessage = _buildToolbarStatusMessage(state);

    Widget buildCanvasWithToolbar(Widget child) {
      final hasAutomaton = state.currentAutomaton != null &&
          state.currentAutomaton!.states.isNotEmpty;
      publishWorkspaceQuickActions(
        ref,
        WorkspaceTab.fsa,
        WorkspaceQuickActions(
          onHelp: _showContextualHelp,
          onSimulate: _openSimulationSheet,
          onAlgorithms: _openAlgorithmSheet,
          simulateEnabled: hasAutomaton,
          algorithmsEnabled: hasAutomaton,
        ),
      );

      final combinedListenable = Listenable.merge([
        _toolController,
        _canvasController.graphRevision,
      ]);

      if (isMobile) {
        return Stack(
          children: [
            Positioned.fill(child: child),
            // Badge DFA/NFA/ε-NFA
            FSADeterminismOverlay(automaton: state.currentAutomaton),
            if (_canvasSimulationSteps case final steps?)
              Positioned(
                left: 16,
                right: 16,
                bottom: 144,
                child: CanvasSimulationPlaybackBar(
                  key: ValueKey(steps),
                  stepCount: steps.length,
                  words: projectInputWordSteps(steps),
                  onStepChanged: _handleCanvasSimulationStep,
                  onClose: _stopCanvasSimulation,
                ),
              ),
            AnimatedBuilder(
              animation: combinedListenable,
              builder: (context, _) {
                return MobileAutomatonControls(
                  onHelp: _showContextualHelp,
                  enableToolSelection: true,
                  showSelectionTool: true,
                  activeTool: _toolController.activeTool,
                  onSelectTool: () => _toolController.setActiveTool(
                    AutomatonCanvasTool.selection,
                  ),
                  onAddState: _handleAddStatePressed,
                  onAddTransition: () => _toolController.toggleTool(
                    AutomatonCanvasTool.transition,
                  ),
                  onZoomIn: _canvasController.zoomIn,
                  onZoomOut: _canvasController.zoomOut,
                  onFitToContent: _canvasController.fitToContent,
                  onResetView: _canvasController.resetView,
                  onClear: _clearCanvasAutomaton,
                  onUndo: _canvasController.undo,
                  onRedo: _canvasController.redo,
                  canUndo: _canvasController.canUndo,
                  canRedo: _canvasController.canRedo,
                  statusMessage: statusMessage,
                );
              },
            ),
          ],
        );
      }

      return Stack(
        children: [
          Positioned.fill(child: child),
          // Badge DFA/NFA/ε-NFA (desktop)
          FSADeterminismOverlay(automaton: state.currentAutomaton),
          AnimatedBuilder(
            animation: combinedListenable,
            builder: (context, _) {
              return GraphViewCanvasToolbar(
                controller: _canvasController,
                enableToolSelection: true,
                showSelectionTool: true,
                activeTool: _toolController.activeTool,
                onSelectTool: () => _toolController.setActiveTool(
                  AutomatonCanvasTool.selection,
                ),
                onAddState: _handleAddStatePressed,
                onHelp: _showContextualHelp,
                onAddTransition: () =>
                    _toolController.toggleTool(AutomatonCanvasTool.transition),
                onClear: _clearCanvasAutomaton,
                statusMessage: statusMessage,
              );
            },
          ),
        ],
      );
    }

    // Wrap canvas with step navigator at the bottom
    return Column(
      children: [
        Expanded(child: buildCanvasWithToolbar(buildGraphViewCanvas())),
        const AlgorithmStepNavigator(),
      ],
    );
  }

  String _buildToolbarStatusMessage(AutomatonStateProviderState state) {
    final automaton = state.currentAutomaton;
    return buildAutomatonWorkspaceStatus(
      l10n: appLocalizationsOf(context),
      stateCount: automaton?.states.length ?? 0,
      transitionCount: automaton?.transitions.length ?? 0,
      hasInitialState: automaton?.initialState != null,
      hasAcceptingState: automaton?.acceptingStates.isNotEmpty ?? false,
      hasNondeterministicTransitions:
          automaton != null && !automaton.isDeterministic,
      hasLambdaTransitions: automaton?.hasEpsilonTransitions ?? false,
    );
  }

  Future<void> _openAlgorithmSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Consumer(
                    builder: (context, sheetRef, _) {
                      final sheetState = sheetRef.watch(automatonStateProvider);
                      final algorithmState = sheetRef.watch(
                        automatonAlgorithmProvider,
                      );
                      final stepState = sheetRef.watch(algorithmStepProvider);
                      final conversionHistory =
                          sheetRef.watch(conversionHistoryProvider).history;
                      final validationDiagnostics = _validationDiagnosticsFor(
                        sheetState.currentAutomaton,
                      );
                      return Column(
                        children: [
                          _buildAlgorithmPanelForState(
                            sheetState,
                            algorithmState,
                          ),
                          _buildValidationDiagnosticsPanel(
                            validationDiagnostics,
                          ),
                          _buildConversionComparisonPanel(
                            conversionHistory,
                            sheetState.currentAutomaton,
                          ),
                          if (stepState.hasSteps) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              height: _kMobileStepViewerHeight,
                              child: _buildStepViewerPanel(),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _openSimulationSheet() async {
    _stopCanvasSimulation();
    final onViewOnCanvas = supportsCanvasSimulationPlayback(context)
        ? _startCanvasSimulation
        : null;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Consumer(
                    builder: (context, sheetRef, _) {
                      final simulationState = sheetRef.watch(
                        automatonSimulationProvider,
                      );
                      final algorithmState = sheetRef.watch(
                        automatonAlgorithmProvider,
                      );
                      return SimulationPanel(
                        onSimulate: (inputString) => sheetRef
                            .read(automatonSimulationProvider.notifier)
                            .simulateAutomaton(inputString),
                        simulationResult: simulationState.simulationResult,
                        regexResult: algorithmState.regexResult,
                        highlightService: _highlightService,
                        onViewOnCanvas: onViewOnCanvas,
                      );
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAlgorithmWorkspacePanel({
    required AutomatonStateProviderState state,
    required bool useExpanded,
  }) {
    return Consumer(
      builder: (context, panelRef, _) {
        final algorithmState = panelRef.watch(automatonAlgorithmProvider);
        final stepState = panelRef.watch(algorithmStepProvider);
        final conversionHistory =
            panelRef.watch(conversionHistoryProvider).history;
        final validationDiagnostics = _validationDiagnosticsFor(
          state.currentAutomaton,
        );
        final algorithmPanel = _buildAlgorithmPanelForState(
          state,
          algorithmState,
        );
        final validationPanel = _buildValidationDiagnosticsPanel(
          validationDiagnostics,
        );
        final comparisonPanel = _buildConversionComparisonPanel(
          conversionHistory,
          state.currentAutomaton,
        );

        if (useExpanded) {
          return Column(
            children: [
              Expanded(child: algorithmPanel),
              validationPanel,
              comparisonPanel,
              if (stepState.hasSteps) ...[
                const SizedBox(height: 8),
                Expanded(child: _buildStepViewerPanel()),
              ],
            ],
          );
        }

        final stepViewerMaxHeight = (MediaQuery.sizeOf(context).height * 0.45)
            .clamp(_kTabletStepViewerMinHeight, _kTabletStepViewerMaxHeight);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            algorithmPanel,
            validationPanel,
            comparisonPanel,
            if (stepState.hasSteps) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: _kTabletStepViewerMinHeight,
                  maxHeight: stepViewerMaxHeight,
                ),
                child: _buildStepViewerPanel(),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSimulationWorkspacePanel() {
    return Consumer(
      builder: (context, panelRef, _) {
        final simulationState = panelRef.watch(automatonSimulationProvider);
        final algorithmState = panelRef.watch(automatonAlgorithmProvider);
        return SimulationPanel(
          onSimulate: (inputString) => panelRef
              .read(automatonSimulationProvider.notifier)
              .simulateAutomaton(inputString),
          simulationResult: simulationState.simulationResult,
          regexResult: algorithmState.regexResult,
          highlightService: _highlightService,
        );
      },
    );
  }

  void _startCanvasSimulation(List<SimulationStep> steps) {
    if (steps.isEmpty || !supportsCanvasSimulationPlayback(context)) return;
    final recordedSteps = List<SimulationStep>.unmodifiable(steps);
    _updatePageState(() {
      _canvasSimulationSteps = recordedSteps;
    });
    _highlightService.emitFromSteps(recordedSteps, 0);
    Navigator.of(context).pop();
  }

  void _handleCanvasSimulationStep(int stepIndex) {
    final steps = _canvasSimulationSteps;
    if (steps == null || stepIndex < 0 || stepIndex >= steps.length) return;
    _highlightService.emitFromSteps(steps, stepIndex);
  }

  void _stopCanvasSimulation() {
    if (_canvasSimulationSteps != null && mounted) {
      _updatePageState(() {
        _canvasSimulationSteps = null;
      });
    }
    _highlightService.clear();
  }

  void _clearCanvasAutomaton() {
    _stopCanvasSimulation();
    _canvasController.clearCanvas();
  }

  List<ValidationDiagnostic> _validationDiagnosticsFor(FSA? automaton) {
    final cacheKey =
        automaton == null ? null : _validationAutomatonKey(automaton);
    if (cacheKey == _cachedValidationAutomatonKey) {
      return _cachedValidationDiagnostics;
    }

    _cachedValidationAutomatonKey = cacheKey;
    if (automaton == null) {
      _cachedValidationDiagnostics = const [];
      return _cachedValidationDiagnostics;
    }

    _cachedValidationDiagnostics = [
      for (final issue in InputValidators.validateFSA(automaton))
        ValidationIssueToDiagnostic.fromIssue(issue),
    ];
    return _cachedValidationDiagnostics;
  }

  String _validationAutomatonKey(FSA automaton) {
    final stateKeys = automaton.states
        .map(
          (state) =>
              '${state.id}|${state.label}|${state.isInitial}|${state.isAccepting}|${state.type.name}',
        )
        .toList()
      ..sort();
    final transitionKeys = automaton.transitions
        .map((transition) => transition.toJson().toString())
        .toList()
      ..sort();
    final alphabet = automaton.alphabet.toList()..sort();
    final accepting = automaton.acceptingStates.map((s) => s.id).toList()
      ..sort();

    return [
      automaton.id,
      automaton.name,
      automaton.initialState?.id ?? '',
      alphabet.join(','),
      accepting.join(','),
      stateKeys.join(';'),
      transitionKeys.join(';'),
    ].join('|');
  }

  Widget _buildValidationDiagnosticsPanel(
    List<ValidationDiagnostic> diagnostics,
  ) {
    if (diagnostics.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 220,
      child: ListView.builder(
        itemCount: diagnostics.length,
        itemBuilder: (context, index) => ValidationDiagnosticCard(
          diagnostic: diagnostics[index],
        ),
      ),
    );
  }

  Widget _buildConversionComparisonPanel(
    ConversionHistory? history,
    FSA? currentAutomaton,
  ) {
    return FSAConversionComparisonPanel(
      history: history,
      currentAutomaton: currentAutomaton,
    );
  }

  void _syncValidationHighlight(List<ValidationDiagnostic> diagnostics) {
    final validationDiagnostic = diagnostics.isEmpty ? null : diagnostics.first;
    final validationHighlight = validationDiagnostic == null
        ? SimulationHighlight.empty
        : _simulationHighlightForDiagnostic(validationDiagnostic);
    _scheduleValidationHighlight(
      validationDiagnostic == null
          ? 'none'
          : _validationHighlightKey(validationDiagnostic, validationHighlight),
      validationHighlight,
    );
  }

  SimulationHighlight _simulationHighlightForDiagnostic(
    ValidationDiagnostic diagnostic,
  ) {
    final stateIds = <String>{};
    final transitionIds = <String>{};
    for (final target in diagnostic.highlights) {
      final id = target.id?.trim();
      if (id == null || id.isEmpty) continue;
      if (target.type == HighlightTargetType.state) {
        stateIds.add(id);
      } else if (target.type == HighlightTargetType.transition) {
        transitionIds.add(id);
      }
    }

    return SimulationHighlight(
      stateIds: Set.unmodifiable(stateIds),
      transitionIds: Set.unmodifiable(transitionIds),
    );
  }

  String _validationHighlightKey(
    ValidationDiagnostic diagnostic,
    SimulationHighlight highlight,
  ) {
    final stateIds = highlight.stateIds.toList()..sort();
    final transitionIds = highlight.transitionIds.toList()..sort();
    return [
      diagnostic.code,
      diagnostic.location ?? '',
      stateIds.join(','),
      transitionIds.join(','),
    ].join('|');
  }

  void _scheduleValidationHighlight(String key, SimulationHighlight highlight) {
    if (_lastValidationHighlightKey == key &&
        _lastValidationHighlight == highlight) {
      return;
    }
    _lastValidationHighlightKey = key;
    _lastValidationHighlight = highlight;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _lastValidationHighlightKey != key ||
          _lastValidationHighlight != highlight) {
        return;
      }
      if (highlight.isEmpty) {
        _highlightService.clear();
      } else {
        _highlightService.dispatch(highlight);
      }
    });
  }
}
