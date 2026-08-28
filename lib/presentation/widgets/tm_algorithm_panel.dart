//
//  tm_algorithm_panel.dart
//  Turing Lab
//
//  Thin coordinator for independently testable TM analysis controls, reports,
//  request state, and core analyzers.
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/asset_example.dart';
import '../../core/algorithms/tm_to_unrestricted_grammar/tm_to_unrestricted_grammar.dart';
import '../../core/formal_systems/formal_systems.dart';
import '../../core/annotations/annotations.dart';
import '../../core/grammar/phrase_structure/phrase_structure.dart';
import '../../core/models/tm.dart';
import '../../core/models/tm_language_explorer_models.dart';
import '../../core/repositories/examples_repository.dart';
import '../../core/result.dart';
import '../../core/services/canvas_highlight_coordinator.dart';
import '../../injection/data_providers.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_workflows.dart';
import '../content/asset_example_content_copy.dart';
import '../content/tm_block_example_content_copy.dart';
import '../providers/tm_editor_provider.dart';
import '../providers/formal_extension_editor_providers.dart';
import '../providers/home_navigation_provider.dart';
import '../providers/interoperable_document_sidecar_provider.dart';
import '../providers/document_annotations_provider.dart';
import '../providers/tm_to_grammar_provider.dart';
import '../providers/workspace_registry_provider.dart';
import 'algorithm_panel_scaffold.dart';
import 'app_snackbar.dart';
import 'asset_example_content_button.dart';
import 'common/algorithm_button_config.dart';
import 'file_operations_panel.dart';
import 'document_interoperability_binding.dart';
import 'document_interoperability_preview.dart';
import 'interoperability_presentation_labels.dart';
import 'tm_algorithm_execution_controller.dart';
import 'tm_algorithm_execution_controls.dart';
import 'tm_algorithm_inputs.dart';
import 'tm_algorithm_language_controls.dart';
import 'tm_algorithm_reachability_controls.dart';
import 'tm_algorithm_result_shell.dart';
import 'tm_algorithm_runner.dart';
import 'tm_algorithm_space_controls.dart';
import 'tm_algorithm_state_selector.dart';
import 'tm_algorithm_time_controls.dart';
import 'tm_block_example_button.dart';
import 'tm_to_grammar_construction_workspace.dart';

export 'tm_algorithm_execution_controller.dart';

/// Panel for Turing Machine analysis algorithms.
class TMAlgorithmPanel extends ConsumerStatefulWidget {
  const TMAlgorithmPanel({
    super.key,
    this.useExpanded = true,
    this.examplesDataSource,
  });

  final bool useExpanded;
  final ExamplesRepository? examplesDataSource;

  @override
  ConsumerState<TMAlgorithmPanel> createState() => _TMAlgorithmPanelState();
}

class _TMAlgorithmPanelState extends ConsumerState<TMAlgorithmPanel> {
  final _inputs = TMAlgorithmInputs();
  late final TMAlgorithmExecutionController _execution;
  late final TMAlgorithmRunner _runner;
  late final TMAlgorithmStateSelector<Object> _terminationSelector;
  late final TMAlgorithmStateSelector<Object> _reachabilitySelector;
  late final TMAlgorithmStateSelector<Object> _languageSelector;
  late final TMAlgorithmStateSelector<Object> _spaceSelector;
  late final TMAlgorithmStateSelector<Object> _timeSelector;
  late final TMAlgorithmStateSelector<Object> _cancelSelector;
  late final TMAlgorithmStateSelector<Object> _buttonsSelector;
  late final TMAlgorithmStateSelector<Object> _resultsSelector;
  late final ExamplesRepository _examplesRepository;
  late final Future<ListResult<AssetExample<TM>>> _examplesFuture;
  ProviderSubscription<TMEditorState>? _tmSubscription;
  String? _loadingExampleName;

  @override
  void initState() {
    super.initState();
    _examplesRepository =
        widget.examplesDataSource ?? ref.read(examplesRepositoryProvider);
    _examplesFuture = _examplesRepository.loadAllTypedTmExamples();
    _execution = TMAlgorithmExecutionController(
      initialTm: ref.read(tmEditorProvider).tm,
      highlights: ref
          .read(canvasHighlightCoordinatorProvider)
          ?.source(CanvasHighlightSource.analysis),
    );
    _runner = TMAlgorithmRunner(execution: _execution, inputs: _inputs);
    _terminationSelector = _selector(
      (state) => (
        state.isAnalyzing,
        state.currentFocus,
        state.termination.progress,
        state.tape.progress,
      ),
    );
    _reachabilitySelector = _selector(
      (state) =>
          (state.isAnalyzing, state.currentFocus, state.reachability.progress),
    );
    _languageSelector = _selector(
      (state) =>
          (state.isAnalyzing, state.currentFocus, state.language.progress),
    );
    _spaceSelector = _selector(
      (state) => (state.isAnalyzing, state.currentFocus, state.space.progress),
    );
    _timeSelector = _selector(
      (state) => (state.isAnalyzing, state.currentFocus, state.time.progress),
    );
    _cancelSelector = _selector(
      (state) => (state.isAnalyzing, state.cancelRequested, state.currentFocus),
    );
    _buttonsSelector = _selector(
      (state) => (
        state.isAnalyzing,
        state.currentFocus,
        state.termination.progress,
        state.reachability.progress,
        state.language.progress,
        state.tape.progress,
        state.time.progress,
        state.space.progress,
      ),
    );
    _resultsSelector = _selector(
      (state) => (
        state.currentFocus,
        state.currentError,
        state.currentStructuredError,
        state.termination.report,
        state.reachability.report,
        state.reachability.sourceTm,
        state.language.report,
        state.language.selectedWord,
        state.language.selectedTrace,
        state.language.isLoadingTrace,
        state.tape.report,
        state.tape.sourceTm,
        state.time.report,
        state.space.report,
      ),
    );
    _tmSubscription = ref.listenManual<TMEditorState>(
      tmEditorProvider,
      (_, next) => _execution.observeMachine(next.tm),
    );
  }

  @override
  void dispose() {
    _tmSubscription?.close();
    _terminationSelector.dispose();
    _reachabilitySelector.dispose();
    _languageSelector.dispose();
    _spaceSelector.dispose();
    _timeSelector.dispose();
    _cancelSelector.dispose();
    _buttonsSelector.dispose();
    _resultsSelector.dispose();
    _execution.dispose();
    _inputs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tm = ref.watch(tmEditorProvider).tm;
    return AlgorithmPanelScaffold(
      title: appLocalizationsOf(context).algorithmsAndExamples,
      children: [
        AlgorithmExamplesSection<TM>(
          examplesFuture: _examplesFuture,
          loadingExampleName: _loadingExampleName,
          onExampleSelected: _loadExample,
          failureMessage: 'Failed to load TM examples.',
          emptyMessage: 'No TM examples available.',
          exampleBuilder: _buildExample,
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        _region(
          _terminationSelector,
          (state) => TMTerminationControls(inputs: _inputs, state: state),
        ),
        const SizedBox(height: 12),
        _region(
          _reachabilitySelector,
          (state) => TMReachabilityControls(inputs: _inputs, state: state),
        ),
        const SizedBox(height: 12),
        _region(
          _timeSelector,
          (state) => TMTimeProfilerControls(
            tm: tm,
            inputs: _inputs,
            state: state,
            onInputsChanged: _refreshInputs,
          ),
        ),
        const SizedBox(height: 12),
        _region(
          _languageSelector,
          (state) => TMLanguageExplorerControls(
            tm: tm,
            inputs: _inputs,
            state: state,
            onInputsChanged: _refreshInputs,
          ),
        ),
        const SizedBox(height: 12),
        _region(
          _spaceSelector,
          (state) => TMSpaceProfilerControls(
            tm: tm,
            inputs: _inputs,
            state: state,
            onInputsChanged: _refreshInputs,
          ),
        ),
        const SizedBox(height: 8),
        _region(
          _cancelSelector,
          (state) => TMAnalysisCancelControl(
            state: state,
            onCancel: _execution.requestCancellation,
          ),
        ),
        const SizedBox(height: 12),
        _region(
          _buttonsSelector,
          (state) =>
              AlgorithmButtonList(configs: _buttonConfigs(context, state)),
        ),
        _region(
          _resultsSelector,
          (state) => TMAlgorithmResultsView(
            state: state,
            onLanguageWordSelected: _selectLanguageWord,
          ),
        ),
        const Divider(),
        FileOperationsPanel(
          turingMachine: tm,
          annotations: tm == null
              ? null
              : annotationsForDocument(
                  ref.watch(documentAnnotationsProvider),
                  DefaultFormalSystemIds.tm,
                  tm.id,
                ),
          interoperability: _interoperabilityBinding(tm),
        ),
      ],
    );
  }

  DocumentInteroperabilityBinding _interoperabilityBinding(TM? tm) {
    final registry = ref.read(documentInteroperabilityRegistryProvider);
    final descriptor = registry.formalSystems.descriptorFor(
      DefaultFormalSystemIds.tm,
    )!;
    final editor = ref.watch(tmEditorProvider);
    final sidecar = ref.watch(
      interoperableDocumentSidecarProvider,
    )[DefaultFormalSystemIds.tm];
    final currentDocument = tm == null
        ? null
        : resolveInteroperableDocument(
            sidecar: sidecar,
            currentDocument: tm,
            documentIdentity: (tm.id, editor.documentGeneration),
            systemKey: DefaultFormalSystemIds.tm,
            schema: descriptor.schema,
            annotations: annotationsForDocument(
              ref.watch(documentAnnotationsProvider),
              DefaultFormalSystemIds.tm,
              tm.id,
            ),
          );
    return DocumentInteroperabilityBinding(
      registry: registry,
      systemKey: DefaultFormalSystemIds.tm,
      currentDocument: currentDocument,
      captureCheckpoint: () => _TmImportCheckpoint(
        editor: ref.read(tmEditorProvider),
        sidecar: ref.read(
          interoperableDocumentSidecarProvider,
        )[DefaultFormalSystemIds.tm],
        annotations: ref.read(
          documentAnnotationsProvider,
        )[DefaultFormalSystemIds.tm],
      ),
      restoreCheckpoint: (checkpoint) {
        final snapshot = checkpoint! as _TmImportCheckpoint;
        ref
            .read(tmEditorProvider.notifier)
            .restoreDocumentCheckpoint(snapshot.editor);
        ref
            .read(interoperableDocumentSidecarProvider.notifier)
            .restore(DefaultFormalSystemIds.tm, snapshot.sidecar);
        ref
            .read(documentAnnotationsProvider.notifier)
            .restore(DefaultFormalSystemIds.tm, snapshot.annotations);
      },
      systemLabel: (context, _) => appLocalizationsOf(context).fileSectionTm,
      formatLabel: defaultDocumentFormatLabel,
      previewFacts: (context, document) {
        final machine = document.document as TM;
        final l10n = appLocalizationsOf(context);
        final variant = switch (machine.documentVariant) {
          TMDocumentVariant.singleTape => l10n.tmDocumentVariantSingleTape,
          TMDocumentVariant.multiTape => l10n.tmDocumentVariantMultiTape,
          TMDocumentVariant.buildingBlocks =>
            l10n.tmDocumentVariantBuildingBlocks,
        };
        return [
          DocumentInteroperabilityFact(
            label: l10n.tmDocumentVariant,
            value: variant,
          ),
          DocumentInteroperabilityFact(
            label: l10n.tmTapeCount,
            value: '${machine.tapeCount}',
          ),
        ];
      },
      replace: (document) async {
        final loaded = document.document;
        if (loaded is! TM) {
          throw StateError('The TM workspace received a non-TM document.');
        }
        ref.read(tmEditorProvider.notifier).setTm(loaded);
        final loadedState = ref.read(tmEditorProvider);
        ref
            .read(interoperableDocumentSidecarProvider.notifier)
            .store(
              document,
              documentIdentity: (loaded.id, loadedState.documentGeneration),
            );
        ref
            .read(documentAnnotationsProvider.notifier)
            .restore(
              DefaultFormalSystemIds.tm,
              annotationsFromImportedDocument(
                document,
                documentId: loaded.id,
                documentRevision: '${loadedState.documentGeneration}',
              ),
            );
      },
    );
  }

  TMAlgorithmStateSelector<Object> _selector(
    Object Function(TMAlgorithmAnalysisState state) select,
  ) => TMAlgorithmStateSelector<Object>(controller: _execution, select: select);

  Widget _region(
    Listenable listenable,
    Widget Function(TMAlgorithmAnalysisState state) builder,
  ) => ListenableBuilder(
    listenable: listenable,
    builder: (context, _) => builder(_execution.state),
  );

  void _refreshInputs() {
    if (mounted) setState(() {});
  }

  List<AlgorithmButtonConfig> _buttonConfigs(
    BuildContext context,
    TMAlgorithmAnalysisState state,
  ) {
    final strings = appLocalizationsOf(context);
    return [
      _button(
        strings.terminationAndCyclesTitle,
        strings.terminationAndCyclesDescription,
        Icons.fact_check_outlined,
        TMAnalysisFocus.termination,
        state,
      ),
      _button(
        strings.reachabilityTitle,
        strings.reachabilityDescription,
        Icons.explore,
        TMAnalysisFocus.reachability,
        state,
      ),
      _button(
        strings.languageExplorerTitle,
        strings.languageExplorerDescription,
        Icons.manage_search,
        TMAnalysisFocus.language,
        state,
      ),
      _button(
        strings.tapeTraceTitle,
        strings.tapeTraceDescription,
        Icons.storage,
        TMAnalysisFocus.tape,
        state,
      ),
      _button(
        strings.timeProfileTitle,
        strings.timeProfileDescription,
        Icons.timer,
        TMAnalysisFocus.time,
        state,
      ),
      _button(
        strings.spaceProfileTitle,
        strings.spaceProfileDescription,
        Icons.memory,
        TMAnalysisFocus.space,
        state,
      ),
      AlgorithmButtonConfig(
        title: strings.localizeWorkflowText(
          'TM to unrestricted grammar construction',
        ),
        description: strings.localizeWorkflowText(
          'Preview a token-safe single-tape construction with exact transition provenance.',
        ),
        icon: Icons.account_tree_outlined,
        isEnabled: !state.isAnalyzing && ref.read(tmEditorProvider).tm != null,
        onPressed: _openTmToGrammarConstruction,
      ),
    ];
  }

  Future<void> _openTmToGrammarConstruction() async {
    final editor = ref.read(tmEditorProvider);
    final snapshot = editor.tm;
    if (snapshot == null) return;
    final revision = editor.documentGeneration;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (context, dialogRef, _) {
          final current = dialogRef.watch(tmEditorProvider);
          final invalidated =
              current.tm?.id != snapshot.id ||
              current.documentGeneration != revision;

          Future<void> open(TMToGrammarConstructionReport report) async {
            final grammar = report.grammar!;
            final controller = ref.read(unrestrictedGrammarEditorProvider);
            if (controller.grammar.productions.isNotEmpty) {
              final replace =
                  await showDialog<bool>(
                    context: dialogContext,
                    builder: (confirmationContext) => AlertDialog(
                      title: Text(
                        appLocalizationsOf(
                          confirmationContext,
                        ).localizeWorkflowText('Replace unrestricted grammar?'),
                      ),
                      content: Text(
                        appLocalizationsOf(
                          confirmationContext,
                        ).localizeWorkflowText(
                          'Opening this result replaces the current unrestricted grammar. You can undo it.',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(confirmationContext).pop(false),
                          child: Text(
                            MaterialLocalizations.of(
                              confirmationContext,
                            ).cancelButtonLabel,
                          ),
                        ),
                        FilledButton(
                          onPressed: () =>
                              Navigator.of(confirmationContext).pop(true),
                          child: Text(
                            appLocalizationsOf(
                              confirmationContext,
                            ).localizeWorkflowText('Replace'),
                          ),
                        ),
                      ],
                    ),
                  ) ??
                  false;
              if (!replace) return;
            }
            if (!mounted || !dialogContext.mounted) return;
            final previousNavigation = ref.read(homeNavigationProvider);
            final previousReport = ref.read(tmToGrammarOpenedReportProvider);
            controller.replaceGrammar(grammar);
            ref.read(tmToGrammarOpenedReportProvider.notifier).state = report;
            final workspaceIndex = ref
                .read(workspacePresentationRegistryProvider)
                .indexOfKey(UnrestrictedGrammarCapabilities.systemKey);
            if (workspaceIndex == null) {
              controller.undo();
              ref.read(tmToGrammarOpenedReportProvider.notifier).state =
                  previousReport;
              throw StateError(
                'Unrestricted grammar workspace is unavailable.',
              );
            }
            ref.read(homeNavigationProvider.notifier).setIndex(workspaceIndex);
            Navigator.of(dialogContext).pop();
            showAppSnackBar(
              this.context,
              message: appLocalizationsOf(this.context).localizeWorkflowText(
                'TM construction opened in the unrestricted grammar editor.',
              ),
              tone: AppSnackBarTone.success,
              duration: const Duration(seconds: 6),
              actionLabel: appLocalizationsOf(
                this.context,
              ).localizeWorkflowText('Undo'),
              onAction: () {
                ref.read(unrestrictedGrammarEditorProvider).undo();
                ref.read(tmToGrammarOpenedReportProvider.notifier).state =
                    previousReport;
                ref
                    .read(homeNavigationProvider.notifier)
                    .setIndex(previousNavigation);
              },
            );
          }

          final workspace = SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: TMToGrammarConstructionWorkspace(
              tm: snapshot,
              sourceRevision: revision,
              invalidated: invalidated,
              onOpen: open,
              onCancel: () => Navigator.of(dialogContext).pop(),
            ),
          );
          if (MediaQuery.sizeOf(context).width < 700) {
            return Dialog.fullscreen(
              child: Scaffold(
                appBar: AppBar(
                  title: Text(
                    appLocalizationsOf(context).localizeWorkflowText(
                      'TM to unrestricted grammar construction',
                    ),
                  ),
                  leading: IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ),
                body: workspace,
              ),
            );
          }
          return Dialog(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200, maxHeight: 900),
              child: workspace,
            ),
          );
        },
      ),
    );
  }

  AlgorithmButtonConfig _button(
    String title,
    String description,
    IconData icon,
    TMAnalysisFocus focus,
    TMAlgorithmAnalysisState state,
  ) {
    final isActive = state.isAnalyzing && state.currentFocus == focus;
    final progress = switch (focus) {
      TMAnalysisFocus.language => state.language.progress?.fraction,
      TMAnalysisFocus.space => state.space.progress?.fraction,
      TMAnalysisFocus.time => state.time.progress?.fraction,
      _ => null,
    };
    final status = switch (focus) {
      TMAnalysisFocus.language when state.language.progress != null =>
        appLocalizationsOf(context).evaluatedOf(
          state.language.progress!.evaluatedCandidates,
          state.language.progress!.plannedCandidates,
        ),
      TMAnalysisFocus.space when state.space.progress != null =>
        appLocalizationsOf(context).evaluatedOf(
          state.space.progress!.evaluatedCandidates,
          state.space.progress!.scheduledCandidates,
        ),
      TMAnalysisFocus.time => state.time.progress?.label,
      TMAnalysisFocus.termination => state.termination.progress,
      TMAnalysisFocus.reachability => state.reachability.progress,
      TMAnalysisFocus.tape => state.tape.progress,
      _ => null,
    };
    return AlgorithmButtonConfig(
      title: title,
      description: description,
      icon: icon,
      isEnabled: !state.isAnalyzing,
      isExecuting: isActive,
      isSelected: state.currentFocus == focus,
      executionProgress: isActive ? progress?.clamp(0, 1).toDouble() : null,
      executionStatus: isActive ? status : null,
      onPressed: () => _performAnalysis(focus),
    );
  }

  Future<void> _performAnalysis(TMAnalysisFocus focus) {
    final strings = appLocalizationsOf(context);
    return _runner.run(
      focus,
      ref.read(tmEditorProvider).tm,
      missingMachineMessage: strings.noTmAvailableToAnalyze,
      progressLabel: strings.transitionsConfigurationsProgress,
    );
  }

  Widget? _buildExample(
    BuildContext context,
    AssetExample<TM> example,
    bool isLoading,
    VoidCallback? onPressed,
  ) {
    final assetExample = AssetExampleContentButton.maybeBuild(
      context: context,
      example: example,
      isLoading: isLoading,
      onPressed: onPressed,
    );
    if (assetExample != null) return assetExample;
    if (example.id != TMBlockExampleContentCopies.id) return null;
    return TMBlockExampleButton(
      copy: TMBlockExampleContentCopies.resolve(
        id: example.id,
        languageCode: Localizations.localeOf(context).languageCode,
      ),
      isLoading: isLoading,
      onPressed: onPressed,
    );
  }

  Future<void> _selectLanguageWord(TMLanguageWordResult word) =>
      _runner.selectLanguageWord(word);

  Future<void> _loadExample(String name) async {
    setState(() => _loadingExampleName = name);
    try {
      final result = await _examplesRepository.loadTypedTmExample(name);
      if (!mounted) return;
      if (result.isFailure) {
        showAppSnackBar(
          context,
          message: appLocalizationsOf(
            context,
          ).localizeWorkflowText('Failed to load example: ${result.error}'),
          tone: AppSnackBarTone.error,
        );
        return;
      }
      final loadedExample = result.data!;
      final tm = loadedExample.payload;
      ref.read(tmEditorProvider.notifier).setTm(tm);
      final languageCode = Localizations.localeOf(context).languageCode;
      final localizedTitle = AssetExampleContentCopies.maybeResolve(
        id: loadedExample.id,
        languageCode: languageCode,
      )?.title;
      final exampleName =
          localizedTitle ??
          (loadedExample.id == TMBlockExampleContentCopies.id
              ? TMBlockExampleContentCopies.resolve(
                  id: loadedExample.id,
                  languageCode: languageCode,
                ).title
              : loadedExample.name);
      showAppSnackBar(
        context,
        message: appLocalizationsOf(context).exampleLoaded(exampleName),
        tone: AppSnackBarTone.success,
      );
    } catch (error) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: appLocalizationsOf(
          context,
        ).localizeWorkflowText('Failed to load example: $error'),
        tone: AppSnackBarTone.error,
      );
    } finally {
      if (mounted) setState(() => _loadingExampleName = null);
    }
  }
}

final class _TmImportCheckpoint {
  const _TmImportCheckpoint({
    required this.editor,
    required this.sidecar,
    required this.annotations,
  });

  final TMEditorState editor;
  final InteroperableDocumentSidecarEntry? sidecar;
  final DocumentAnnotationCollection? annotations;
}
