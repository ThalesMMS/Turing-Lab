part of '../fsa_page.dart';

extension _FSAPageStateBehavior on _FSAPageState {
  void _handleAddStatePressed() {
    // Pure placement toggle: states are added by tapping the canvas while
    // the tool is active, never as a side effect of pressing the button.
    _toolController.toggleTool(AutomatonCanvasTool.addState);
  }

  void _showSnack(String message, {bool isError = false}) {
    showAppSnackBar(
      context,
      message: message,
      tone: isError ? AppSnackBarTone.error : AppSnackBarTone.success,
    );
  }

  String? _localizedSimulationError(SimulationState state) {
    final structured = state.structuredError;
    if (structured != null) {
      return appLocalizationsOf(context).resolveStructuredMessage(structured);
    }
    final error = state.error;
    return error == null
        ? null
        : appLocalizationsOf(context).localizeWorkflowText(error);
  }

  String _localizedAlgorithmError(AlgorithmOperationState state) {
    final error = state.error;
    if (error == null) return '';
    final structured = state.structuredError;
    return structured == null
        ? appLocalizationsOf(context).localizeWorkflowText(error)
        : appLocalizationsOf(context).resolveStructuredMessage(structured);
  }

  FSA? _requireAutomaton({
    bool requireDfa = false,
    bool requireLambda = false,
    String? missingMessage,
    String? invalidMessage,
  }) {
    final l10n = appLocalizationsOf(context);
    final automaton = ref.read(automatonStateProvider).currentAutomaton;
    if (automaton == null) {
      _showSnack(
        missingMessage ?? l10n.loadAutomatonBeforeOperation,
        isError: true,
      );
      return null;
    }

    if (requireDfa &&
        !(automaton.isDeterministic && !automaton.hasEpsilonTransitions)) {
      _showSnack(
        invalidMessage ?? l10n.operationRequiresDeterministicNoEpsilon,
        isError: true,
      );
      return null;
    }

    if (requireLambda && !automaton.hasEpsilonTransitions) {
      _showSnack(
        invalidMessage ?? l10n.automatonHasNoLambdaTransitions,
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
      _showSnack(_localizedAlgorithmError(algorithmState), isError: true);
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
    final l10n = appLocalizationsOf(context);
    await _runCurrentAutomatonOperation(
      operation: (notifier) => notifier.removeLambdaTransitions(),
      successMessage: l10n.lambdaTransitionsRemoved,
      requireLambda: true,
      invalidMessage: l10n.automatonMustContainLambdaToRemove,
    );
  }

  Future<void> _handleComplementDfa() async {
    final l10n = appLocalizationsOf(context);
    await _runCurrentAutomatonOperation(
      operation: (notifier) => notifier.complementDfa(),
      successMessage: l10n.complementComputed,
      requireDfa: true,
      invalidMessage: l10n.complementRequiresDeterministic,
    );
  }

  Future<void> _handlePrefixClosure() async {
    final l10n = appLocalizationsOf(context);
    await _runCurrentAutomatonOperation(
      operation: (notifier) => notifier.prefixClosureDfa(),
      successMessage: l10n.prefixClosureComputed,
      requireDfa: true,
      invalidMessage: l10n.prefixClosureRequiresDeterministic,
    );
  }

  Future<void> _handleSuffixClosure() async {
    final l10n = appLocalizationsOf(context);
    await _runCurrentAutomatonOperation(
      operation: (notifier) => notifier.suffixClosureDfa(),
      successMessage: l10n.suffixClosureComputed,
      requireDfa: true,
      invalidMessage: l10n.suffixClosureRequiresDeterministic,
    );
  }

  Future<void> _handleUnionDfa(FSA other) async {
    final l10n = appLocalizationsOf(context);
    await _runCurrentAutomatonOperation(
      operation: (notifier) => notifier.unionDfa(other),
      successMessage: l10n.unionComputed,
      requireDfa: true,
      invalidMessage: l10n.binaryDfaRequiresDeterministic,
    );
  }

  Future<void> _handleConcatenateFsa(FSA other) async {
    final l10n = appLocalizationsOf(context);
    await _runCurrentAutomatonOperation(
      operation: (notifier) =>
          notifier.concatenateFsa(other, withSteps: _stepByStepMode),
      successMessage: l10n.concatenationComputed,
      invalidMessage: l10n.loadFsaBeforeConcatenation,
    );
  }

  Future<void> _handleKleeneStarFsa() async {
    final l10n = appLocalizationsOf(context);
    await _runCurrentAutomatonOperation(
      operation: (notifier) =>
          notifier.kleeneStarFsa(withSteps: _stepByStepMode),
      successMessage: l10n.kleeneStarComputed,
      invalidMessage: l10n.loadFsaBeforeKleeneStar,
    );
  }

  Future<void> _handleReverseFsa() async {
    final l10n = appLocalizationsOf(context);
    await _runCurrentAutomatonOperation(
      operation: (notifier) => notifier.reverseFsa(withSteps: _stepByStepMode),
      successMessage: l10n.fsaLanguageReversed,
      invalidMessage: l10n.loadFsaBeforeReverse,
    );
  }

  Future<void> _handleIntersectionDfa(FSA other) async {
    final l10n = appLocalizationsOf(context);
    await _runCurrentAutomatonOperation(
      operation: (notifier) => notifier.intersectionDfa(other),
      successMessage: l10n.intersectionComputed,
      requireDfa: true,
      invalidMessage: l10n.binaryDfaRequiresDeterministic,
    );
  }

  Future<void> _handleDifferenceDfa(FSA other) async {
    final l10n = appLocalizationsOf(context);
    await _runCurrentAutomatonOperation(
      operation: (notifier) => notifier.differenceDfa(other),
      successMessage: l10n.differenceComputed,
      requireDfa: true,
      invalidMessage: l10n.binaryDfaRequiresDeterministic,
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
    final isDfa =
        automaton != null &&
        automaton.isDeterministic &&
        !automaton.hasEpsilonTransitions;

    return AlgorithmPanel(
      showExamples: true,
      currentAutomaton: hasAutomaton ? automaton : null,
      onNfaToDfa: hasAutomaton ? _handleNfaToDfa : null,
      onRemoveLambda: hasLambda ? _handleRemoveLambda : null,
      onMinimizeDfa: isDfa ? _handleMinimizeDfa : null,
      onCompleteDfa: isDfa ? () => algorithmNotifier.completeDfa() : null,
      onComplementDfa: isDfa ? _handleComplementDfa : null,
      onUnionDfa: isDfa ? _handleUnionDfa : null,
      onConcatenateFsa: hasAutomaton ? _handleConcatenateFsa : null,
      onKleeneStarFsa: hasAutomaton ? _handleKleeneStarFsa : null,
      onReverseFsa: hasAutomaton ? _handleReverseFsa : null,
      onIntersectionDfa: isDfa ? _handleIntersectionDfa : null,
      onDifferenceDfa: isDfa ? _handleDifferenceDfa : null,
      onPrefixClosure: isDfa ? _handlePrefixClosure : null,
      onSuffixClosure: isDfa ? _handleSuffixClosure : null,
      onFsaToGrammar: hasAutomaton ? _handleFsaToGrammar : null,
      onPracticeFsaToGrammar: hasAutomaton
          ? _openManualFsaToGrammarConstruction
          : null,
      onAutoLayout: hasAutomaton
          ? () => layoutNotifier.applyAutoLayout()
          : null,
      onClear: () => automatonNotifier.clearAutomaton(),
      onRegexToNfa: (regex) => algorithmNotifier.convertRegexToNfa(regex),
      onFaToRegex: hasAutomaton ? _handleFaToRegex : null,
      onPracticeFaToRegex: hasAutomaton
          ? _openManualFaToRegexConstruction
          : null,
      onCompareEquivalence: isDfa ? _handleCompareEquivalence : null,
      equivalenceResult: algorithmState.equivalenceResult,
      equivalenceDetails: algorithmState.equivalenceDetails,
      stepByStepMode: _stepByStepMode,
      onStepByStepModeChanged: _handleStepByStepModeChanged,
    );
  }

  Future<void> _handleFaToRegex() async {
    final shouldReplace = await confirmConversionDestinationReplacement(
      context: context,
      ref: ref,
      destination: ConversionDestination.regex,
    );
    if (!mounted || !shouldReplace) return;

    if (_stepByStepMode) {
      await _handleFaToRegexWithSteps();
    } else {
      final algorithmNotifier = ref.read(automatonAlgorithmProvider.notifier);
      final regex = await algorithmNotifier.convertFaToRegex();
      if (!mounted || regex == null) {
        final algorithmState = ref.read(automatonAlgorithmProvider);
        if (mounted && algorithmState.error != null) {
          _showSnack(_localizedAlgorithmError(algorithmState), isError: true);
        }
        return;
      }

      if (!mounted) return;
      _openRegexWorkspace(regex);
    }
  }

  Future<void> _openManualFaToRegexConstruction() async {
    final state = ref.read(automatonStateProvider);
    final source = state.currentAutomaton;
    if (source == null) return;
    late final ManualConversionSession manualSession;
    try {
      manualSession = ManualConversionFactories.faToRegex(
        source: source,
        sourceRevision: state.documentGeneration,
      );
    } on FaToRegexManualException catch (error) {
      _showSnack(error.message, isError: true);
      return;
    } on StateError catch (error) {
      _showSnack(error.message, isError: true);
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Consumer(
        builder: (context, dialogRef, _) {
          final liveState = dialogRef.watch(automatonStateProvider);
          final liveSource = liveState.currentAutomaton;
          final checkedSession = manualSession.checkSource(
            documentId: liveSource?.id ?? '',
            revision: liveState.documentGeneration,
          );
          return Dialog.fullscreen(
            child: ManualConversionWorkspace(
              title: appLocalizationsOf(
                context,
              ).localizeWorkflowText('Manual FA to Regex construction'),
              workspaceKey:
                  'fa-to-regex.${source.id}.${state.documentGeneration}',
              initialSession: checkedSession,
              currentSourceDocumentId: liveSource?.id ?? '',
              currentSourceRevision: liveState.documentGeneration,
              sourcePreview: ManualConversionDocumentPreview.fsa(
                liveSource ?? source,
              ),
              resultPreviewBuilder: ManualConversionDocumentPreview.artifact,
              onApplyPayload: (session, payload) =>
                  ManualConversionFactories.applyFaToRegexLearnerStep(
                    source: liveSource ?? source,
                    session: session,
                    payload: payload,
                  ),
              requirementEditorBuilder: (context, requirement, onSubmit) =>
                  FaToRegexRequirementEditor(
                    key: ValueKey(requirement.id),
                    requirement: requirement,
                    onSubmit: onSubmit,
                  ),
              onClose: () => Navigator.of(dialogContext).pop(),
              onStepAccepted: (acceptedSession) =>
                  ManualConversionFactories.rebaseFaToRegexSelection(
                    source: liveSource ?? source,
                    sourceRevision: liveState.documentGeneration,
                    acceptedSession: acceptedSession,
                  ),
              onRestartFromSource: (invalidated) {
                if (liveSource == null) {
                  throw StateError('The edited FA is empty.');
                }
                final fresh = ManualConversionFactories.faToRegex(
                  source: liveSource,
                  sourceRevision: liveState.documentGeneration,
                );
                return invalidated.restartFromNewSource(freshSession: fresh);
              },
              onBranchFromSource: (invalidated, branchId) {
                if (liveSource == null) {
                  throw StateError('The edited FA is empty.');
                }
                final fresh = ManualConversionFactories.faToRegex(
                  source: liveSource,
                  sourceRevision: liveState.documentGeneration,
                );
                return invalidated.branchFromNewSource(
                  branchId: branchId,
                  freshSession: fresh,
                );
              },
              onOpenResult: (artifact) async {
                final regex = artifact['regex'];
                if (regex is! String || !dialogContext.mounted) return;
                final shouldReplace =
                    await confirmConversionDestinationReplacement(
                      context: dialogContext,
                      ref: ref,
                      destination: ConversionDestination.regex,
                    );
                if (!shouldReplace || !mounted || !dialogContext.mounted) {
                  return;
                }
                ref.read(regexEditorProvider.notifier).validateRegex(regex);
                ref.read(homeNavigationProvider.notifier).goToRegex();
                Navigator.of(dialogContext).pop();
                _showSnack(
                  appLocalizationsOf(context).localizeWorkflowText(
                    'Manual construction opened in the Regex editor.',
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _openManualFsaToGrammarConstruction() async {
    final state = ref.read(automatonStateProvider);
    final source = state.currentAutomaton;
    if (source == null) return;
    final sessionResult = FaGrammarSessionFactory.fromFa(
      sessionId:
          'manual.fa-to-grammar.${source.id}.${state.documentGeneration}',
      source: source,
      sourceRevision: state.documentGeneration,
    );
    if (!sessionResult.isSuccess || sessionResult.data == null) {
      _showSnack(
        sessionResult.error ?? 'Could not start the construction.',
        isError: true,
      );
      return;
    }
    final manualSession = sessionResult.data!;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Consumer(
        builder: (context, dialogRef, _) {
          final liveState = dialogRef.watch(automatonStateProvider);
          final liveSource = liveState.currentAutomaton;
          final checkedSession = manualSession.checkSource(
            documentId: liveSource?.id ?? '',
            revision: liveState.documentGeneration,
          );
          return Dialog.fullscreen(
            child: ManualConversionWorkspace(
              title: appLocalizationsOf(context).localizeWorkflowText(
                'Manual FA to Regular Grammar construction',
              ),
              workspaceKey:
                  'fa-to-grammar.${source.id}.${state.documentGeneration}',
              initialSession: checkedSession,
              currentSourceDocumentId: liveSource?.id ?? '',
              currentSourceRevision: liveState.documentGeneration,
              sourcePreview: ManualConversionDocumentPreview.fsa(
                liveSource ?? source,
              ),
              resultPreviewBuilder: ManualConversionDocumentPreview.artifact,
              onApplyPayload: (session, payload) =>
                  FaGrammarSessionFactory.applyLearnerAction(
                    session: session,
                    payload: payload,
                  ),
              requirementEditorBuilder: (context, requirement, onSubmit) =>
                  FaGrammarRequirementEditor(
                    key: ValueKey(requirement.id),
                    requirement: requirement,
                    onSubmit: onSubmit,
                  ),
              onRestartFromSource: (invalidated) {
                if (liveSource == null) {
                  throw StateError('The edited FA is empty.');
                }
                final result = FaGrammarSessionFactory.fromFa(
                  sessionId: invalidated.id,
                  source: liveSource,
                  sourceRevision: liveState.documentGeneration,
                );
                if (!result.isSuccess || result.data == null) {
                  throw StateError(result.error ?? 'Invalid edited FA.');
                }
                return invalidated.restartFromNewSource(
                  freshSession: result.data!,
                );
              },
              onBranchFromSource: (invalidated, branchId) {
                if (liveSource == null) {
                  throw StateError('The edited FA is empty.');
                }
                final result = FaGrammarSessionFactory.fromFa(
                  sessionId: branchId,
                  source: liveSource,
                  sourceRevision: liveState.documentGeneration,
                );
                if (!result.isSuccess || result.data == null) {
                  throw StateError(result.error ?? 'Invalid edited FA.');
                }
                return invalidated.branchFromNewSource(
                  branchId: branchId,
                  freshSession: result.data!,
                );
              },
              onClose: () => Navigator.of(dialogContext).pop(),
              onOpenResult: (artifact) async {
                final encodedGrammar = artifact['document'];
                if (encodedGrammar is! Map || !dialogContext.mounted) return;
                final shouldReplace =
                    await confirmConversionDestinationReplacement(
                      context: dialogContext,
                      ref: ref,
                      destination: ConversionDestination.grammar,
                    );
                if (!shouldReplace || !mounted || !dialogContext.mounted) {
                  return;
                }
                final grammar = Grammar.fromJson(
                  Map<String, dynamic>.from(encodedGrammar),
                );
                ref.read(grammarProvider.notifier).applyGrammar(grammar);
                ref.read(homeNavigationProvider.notifier).goToGrammar();
                Navigator.of(dialogContext).pop();
                _showSnack(
                  appLocalizationsOf(context).localizeWorkflowText(
                    'Manual construction opened in the Grammar editor.',
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleFaToRegexWithSteps() async {
    final automaton = _requireAutomaton();
    if (automaton == null) return;

    final algorithmNotifier = ref.read(automatonAlgorithmProvider.notifier);
    final regex = await algorithmNotifier.convertFaToRegexWithSteps();
    if (!mounted || regex == null) {
      final algorithmState = ref.read(automatonAlgorithmProvider);
      if (mounted && algorithmState.error != null) {
        _showSnack(_localizedAlgorithmError(algorithmState), isError: true);
      }
      return;
    }

    if (!mounted) return;
    _openRegexWorkspace(regex);
  }

  void _openRegexWorkspace(String regex) {
    ref.read(regexEditorProvider.notifier).validateRegex(regex);
    ref.read(homeNavigationProvider.notifier).goToRegex();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    _showSnack(appLocalizationsOf(context).convertedToRegexWorkspace);
  }

  Future<void> _handleFsaToGrammar() async {
    final shouldReplace = await confirmConversionDestinationReplacement(
      context: context,
      ref: ref,
      destination: ConversionDestination.grammar,
    );
    if (!mounted || !shouldReplace) return;

    final algorithmNotifier = ref.read(automatonAlgorithmProvider.notifier);
    final grammar = await algorithmNotifier.convertFsaToGrammar();
    if (!mounted || grammar == null) {
      final algorithmState = ref.read(automatonAlgorithmProvider);
      if (mounted && algorithmState.error != null) {
        _showSnack(_localizedAlgorithmError(algorithmState), isError: true);
      }
      return;
    }

    if (!mounted) return;
    ref.read(grammarProvider.notifier).applyGrammar(grammar);
    ref.read(homeNavigationProvider.notifier).goToGrammar();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    _showSnack(appLocalizationsOf(context).convertedToGrammarWorkspace);
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

    String topicId;
    if (automaton == null) {
      topicId = HelpTopicIds.fsaEditorOverview;
    } else if (automaton.hasEpsilonTransitions) {
      topicId = HelpTopicIds.fsaTheoryEpsilon;
    } else if (automaton.isDeterministic) {
      topicId = HelpTopicIds.fsaTheoryDfa;
    } else {
      topicId = HelpTopicIds.fsaTheoryNfa;
    }

    showWorkspaceHelp(context: context, topicId: topicId);
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
        documentActionsController: _documentActions,
        annotationConfig: state.currentAutomaton == null
            ? null
            : AutomatonCanvasAnnotationConfig(
                systemKey: DefaultFormalSystemIds.fsa,
                documentId: state.currentAutomaton!.id,
                documentRevision: '${state.documentGeneration}',
              ),
      );
    }

    final statusMessage = _buildToolbarStatusMessage(state);

    Widget buildCanvasWithToolbar(Widget child) {
      final hasAutomaton =
          state.currentAutomaton != null &&
          state.currentAutomaton!.states.isNotEmpty;
      publishWorkspaceQuickActionsForKey(
        ref,
        DefaultFormalSystemIds.fsa,
        WorkspaceQuickActions(
          onHelp: _showContextualHelp,
          onSimulate: _openSimulationSheet,
          onAlgorithms: _openAlgorithmSheet,
          algorithmsTooltip: appLocalizationsOf(
            context,
          ).workspaceAlgorithmsAndExamplesTooltip,
          simulateEnabled: hasAutomaton,
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
            // Diagnostics bar and DFA/NFA/ε-NFA badge share one top-anchored
            // column, mirroring the PDA/TM top inset without overlapping.
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: SafeArea(
                minimum: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: _buildDiagnosticHighlightBarContent(state)),
                    const SizedBox(height: 8),
                    FSADeterminismOverlay(
                      automaton: state.currentAutomaton,
                      isMobile: isMobile,
                      inline: true,
                    ),
                  ],
                ),
              ),
            ),
            if (_canvasSimulationSteps case final steps?)
              Positioned(
                left: 16,
                right: 16,
                bottom: _canvasToolbarInsets.bottom + 16,
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
                return GraphViewCanvasToolbar(
                  controller: _canvasController,
                  placement: CanvasToolbarPlacement.bottomCenter,
                  onViewportInsetsChanged: _handleCanvasToolbarInsetsChanged,
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
                  onArrangeAutomaton: _documentActions.arrange,
                  onImportAutomaton: _documentActions.importAutomaton,
                  onDocumentNotes: _documentActions.showDocumentNotes,
                  documentActionsEnabled: state.currentAutomaton != null,
                  onHelp: _showContextualHelp,
                  onClear: _clearCanvasAutomaton,
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
          _buildDiagnosticHighlightBar(state),
          // Badge DFA/NFA/ε-NFA (desktop)
          FSADeterminismOverlay(
            automaton: state.currentAutomaton,
            isMobile: isMobile,
            desktopTop: _canvasToolbarInsets.top > 0
                ? _canvasToolbarInsets.top + 8
                : 88,
          ),
          AnimatedBuilder(
            animation: combinedListenable,
            builder: (context, _) {
              return GraphViewCanvasToolbar(
                controller: _canvasController,
                onViewportInsetsChanged: _handleCanvasToolbarInsetsChanged,
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
                onArrangeAutomaton: _documentActions.arrange,
                onImportAutomaton: _documentActions.importAutomaton,
                onDocumentNotes: _documentActions.showDocumentNotes,
                documentActionsEnabled: state.currentAutomaton != null,
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
                      final conversionHistory = sheetRef
                          .watch(conversionHistoryProvider)
                          .history;
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
    _clearDiagnosticHighlight();
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
                      final automaton = sheetRef
                          .watch(automatonStateProvider)
                          .currentAutomaton;
                      return SimulationPanel(
                        onSimulate: (inputString) => sheetRef
                            .read(automatonSimulationProvider.notifier)
                            .simulateAutomaton(inputString),
                        simulationResult: simulationState.simulationResult,
                        errorMessage: _localizedSimulationError(
                          simulationState,
                        ),
                        regexResult: algorithmState.regexResult,
                        highlightService: _highlightService,
                        isDeterministic: automaton?.isDeterministic ?? true,
                        computationStateLabels: {
                          for (final state in automaton?.states ?? const {})
                            state.id: state.label,
                        },
                        onViewOnCanvas: onViewOnCanvas,
                        batchExecutor: automaton == null
                            ? null
                            : FsaBatchExecutor(automaton),
                        batchAlphabet: automaton?.alphabet ?? const {},
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
  }) {
    return Consumer(
      builder: (context, panelRef, _) {
        final algorithmState = panelRef.watch(automatonAlgorithmProvider);
        final stepState = panelRef.watch(algorithmStepProvider);
        final conversionHistory = panelRef
            .watch(conversionHistoryProvider)
            .history;
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
        final automaton = panelRef
            .watch(automatonStateProvider)
            .currentAutomaton;
        return SimulationPanel(
          onSimulate: (inputString) => panelRef
              .read(automatonSimulationProvider.notifier)
              .simulateAutomaton(inputString),
          simulationResult: simulationState.simulationResult,
          errorMessage: _localizedSimulationError(simulationState),
          regexResult: algorithmState.regexResult,
          highlightService: _highlightService,
          isDeterministic: automaton?.isDeterministic ?? true,
          computationStateLabels: {
            for (final state in automaton?.states ?? const {})
              state.id: state.label,
          },
          batchExecutor: automaton == null ? null : FsaBatchExecutor(automaton),
          batchAlphabet: automaton?.alphabet ?? const {},
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
    final cacheKey = automaton == null
        ? null
        : _validationAutomatonKey(automaton);
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
    final stateKeys =
        automaton.states
            .map(
              (state) =>
                  '${state.id}|${state.label}|${state.isInitial}|${state.isAccepting}|${state.type.name}',
            )
            .toList()
          ..sort();
    final transitionKeys =
        automaton.transitions
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
        itemBuilder: (context, index) =>
            ValidationDiagnosticCard(diagnostic: diagnostics[index]),
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
    final target = _highlightCoordinator.target;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _lastValidationHighlightKey != key ||
          _lastValidationHighlight != highlight ||
          target != _highlightCoordinator.target) {
        return;
      }
      if (highlight.isEmpty) {
        _validationHighlights.clearFor(target);
      } else {
        _validationHighlights.sendFor(target, highlight);
      }
    });
  }

  CanvasHighlightTarget _highlightTarget(FSA? automaton) {
    return CanvasHighlightTarget(
      kind: AutomatonSurfaceKind.fsa,
      surface: _canvasController,
      documentId: automaton?.id,
      revision: _highlightRevision,
    );
  }

  void _setDiagnosticHighlight(
    AutomatonDiagnosticHighlightKind kind,
    bool selected,
    AutomatonStateProviderState state,
  ) {
    if (!selected) {
      _clearDiagnosticHighlight();
      return;
    }

    _stopCanvasSimulation();
    final transitionIds = switch (kind) {
      AutomatonDiagnosticHighlightKind.conflicts =>
        _diagnosticHighlightService.conflictingFsaTransitionIds(
          state.currentAutomaton,
        ),
      AutomatonDiagnosticHighlightKind.epsilon =>
        _diagnosticHighlightService.epsilonFsaTransitionIds(
          state.currentAutomaton,
        ),
    };
    _updatePageState(() {
      _activeDiagnosticHighlight = kind;
    });
    _diagnosticHighlights.send(
      _diagnosticHighlightService.transitionHighlight(transitionIds),
    );
  }

  void _clearDiagnosticHighlight() {
    if (_activeDiagnosticHighlight != null && mounted) {
      _updatePageState(() {
        _activeDiagnosticHighlight = null;
      });
    }
    _diagnosticHighlights.clear();
  }

  void _handleSimulationHighlightActivity() {
    _diagnosticHighlights.clear();
    if (_activeDiagnosticHighlight != null && mounted) {
      _updatePageState(() {
        _activeDiagnosticHighlight = null;
      });
    }
  }

  Widget _buildDiagnosticHighlightBarContent(
    AutomatonStateProviderState state,
  ) {
    final conflicts = _diagnosticHighlightService.conflictingFsaTransitionIds(
      state.currentAutomaton,
    );
    final epsilon = _diagnosticHighlightService.epsilonFsaTransitionIds(
      state.currentAutomaton,
    );
    return AutomatonDiagnosticHighlightBar(
      activeKind: _activeDiagnosticHighlight,
      conflictCount: conflicts.length,
      epsilonCount: epsilon.length,
      onConflictSelected: (selected) => _setDiagnosticHighlight(
        AutomatonDiagnosticHighlightKind.conflicts,
        selected,
        state,
      ),
      onEpsilonSelected: (selected) => _setDiagnosticHighlight(
        AutomatonDiagnosticHighlightKind.epsilon,
        selected,
        state,
      ),
    );
  }

  Widget _buildDiagnosticHighlightBar(AutomatonStateProviderState state) {
    return Align(
      alignment: Alignment.topCenter,
      child: SafeArea(
        minimum: EdgeInsets.fromLTRB(
          12,
          _canvasToolbarInsets.top > 0 ? _canvasToolbarInsets.top + 8 : 88,
          12,
          12,
        ),
        child: _buildDiagnosticHighlightBarContent(state),
      ),
    );
  }
}
