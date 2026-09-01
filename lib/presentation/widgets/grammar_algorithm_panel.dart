//
//  grammar_algorithm_panel.dart
//  Turing Lab
//
//  Panel that centralizes grammar algorithms, offering buttons for
//  conversions, left-recursion removal, factoring, FIRST and FOLLOW
//  computations, and parse-table construction. The widget wires multiple
//  providers to fire operations, manages loading states, and shows
//  textual results that guide the user's next action.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../empty_string_notation.dart';

import '../../core/algorithms/grammar_analyzer.dart';
import '../../core/algorithms/grammar_cnf_transformer.dart';
import '../../core/algorithms/grammar_gnf_transformer.dart';
import '../../core/algorithms/grammar_to_pda/cfg_to_pda.dart';
import '../../core/formal_systems/formal_systems.dart';
import '../../core/annotations/annotations.dart';
import '../../core/grammar/phrase_structure/phrase_structure.dart';
import '../../core/models/grammar.dart';
import '../../core/models/grammar_diagnostic.dart';
import '../../core/models/fsa.dart';
import '../../core/manual_conversions/fa_grammar_session_factory.dart';
import '../../core/models/asset_example.dart';
import '../../core/models/grammar_diagnostic_severity.dart';
import '../../core/models/grammar_transformation_step.dart';
import '../../core/messages/structured_message.dart';
import '../../core/models/pda.dart';
import '../../core/repositories/examples_repository.dart';
import '../../core/result.dart';
import '../../core/utils/epsilon_utils.dart';
import '../../injection/data_providers.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_structured_messages.dart';
import '../../l10n/app_localizations_workflows.dart';
import 'algorithm_panel_scaffold.dart';
import 'base_simulation_panel.dart';
import 'asset_example_content_button.dart';
import 'common/algorithm_button.dart';
import 'common/algorithm_button_config.dart';
import 'cfg_to_pda_construction_workspace.dart';
import 'manual_conversion_document_preview.dart';
import 'manual_conversion_workspace.dart';
import 'conversion_replacement_dialog.dart';
import 'grammar_transformation_history.dart';
import 'grammar_normalization_teaching_workspace.dart';
import 'variable_dependency_graph_workspace.dart';
import '../unrestricted_grammar/unrestricted_grammar_workspace_strings.dart';
import '../providers/automaton_state_provider.dart';
import '../providers/grammar_provider.dart';
import '../providers/interoperable_document_sidecar_provider.dart';
import '../providers/document_annotations_provider.dart';
import '../providers/home_navigation_provider.dart';
import '../providers/pda_editor_provider.dart';
import 'app_snackbar.dart';
import 'document_interoperability_binding.dart';
import 'file_operations_panel.dart';
import 'fa_grammar_requirement_editor.dart';
import 'interoperability_presentation_labels.dart';
import 'document_annotations.dart';
import '../../core/constants/monospace_typography.dart';

/// Panel for grammar analysis algorithms
class GrammarAlgorithmPanel extends ConsumerStatefulWidget {
  const GrammarAlgorithmPanel({
    super.key,
    this.useExpanded = true,
    this.examplesDataSource,
  });

  final bool useExpanded;
  final ExamplesRepository? examplesDataSource;

  @override
  ConsumerState<GrammarAlgorithmPanel> createState() =>
      _GrammarAlgorithmPanelState();
}

class _GrammarAlgorithmPanelState extends ConsumerState<GrammarAlgorithmPanel> {
  bool _isAnalyzing = false;
  String? _loadingExampleName;
  String? _analysisResult;
  PhraseGrammarClassificationReport? _classificationReport;
  List<GrammarTransformationStep> _transformationSteps = const [];
  List<({StructuredMessage operation, StructuredMessage rationale})>
  _transformationStepMessages = const [];
  late final ExamplesRepository _examplesDataSource;
  late final Future<ListResult<AssetExample<Grammar>>> _grammarExamplesFuture;

  @override
  void initState() {
    super.initState();
    _examplesDataSource =
        widget.examplesDataSource ?? ref.read(examplesRepositoryProvider);
    _grammarExamplesFuture = _examplesDataSource.loadAllTypedCfgExamples();
  }

  @override
  Widget build(BuildContext context) {
    final grammarState = ref.watch(grammarProvider);
    final grammar = ref.read(grammarProvider.notifier).buildGrammar();
    return AlgorithmPanelScaffold(
      title: appLocalizationsOf(context).grammarAnalysisTitle,
      children: [
        _buildAlgorithmButtons(context),
        _buildResultsSection(context),
        DocumentAnnotationsSection(
          systemKey: DefaultFormalSystemIds.grammar,
          documentId: grammarState.documentId,
          documentRevision: '${grammarState.documentGeneration}',
        ),
        const SizedBox(height: 16),
        const Divider(),
        FileOperationsPanel(
          grammar: grammar,
          annotations: annotationsForDocument(
            ref.watch(documentAnnotationsProvider),
            DefaultFormalSystemIds.grammar,
            grammarState.documentId,
          ),
          interoperability: _interoperabilityBinding(grammar, grammarState),
        ),
      ],
    );
  }

  DocumentInteroperabilityBinding _interoperabilityBinding(
    Grammar grammar,
    GrammarState grammarState,
  ) {
    final registry = ref.read(documentInteroperabilityRegistryProvider);
    final descriptor = registry.formalSystems.descriptorFor(
      DefaultFormalSystemIds.grammar,
    )!;
    final sidecar = ref.watch(
      interoperableDocumentSidecarProvider,
    )[DefaultFormalSystemIds.grammar];
    final currentDocument = resolveInteroperableDocument(
      sidecar: sidecar,
      currentDocument: grammar,
      documentIdentity: (
        grammarState.documentId,
        grammarState.documentGeneration,
      ),
      systemKey: DefaultFormalSystemIds.grammar,
      schema: descriptor.schema,
      annotations: annotationsForDocument(
        ref.watch(documentAnnotationsProvider),
        DefaultFormalSystemIds.grammar,
        grammarState.documentId,
      ),
    );
    return DocumentInteroperabilityBinding(
      registry: registry,
      systemKey: DefaultFormalSystemIds.grammar,
      currentDocument: currentDocument,
      captureCheckpoint: () => _GrammarImportCheckpoint(
        editor: ref.read(grammarProvider),
        sidecar: ref.read(
          interoperableDocumentSidecarProvider,
        )[DefaultFormalSystemIds.grammar],
        annotations: ref.read(
          documentAnnotationsProvider,
        )[DefaultFormalSystemIds.grammar],
      ),
      restoreCheckpoint: (checkpoint) {
        final snapshot = checkpoint! as _GrammarImportCheckpoint;
        ref
            .read(grammarProvider.notifier)
            .restoreDocumentCheckpoint(snapshot.editor);
        ref
            .read(interoperableDocumentSidecarProvider.notifier)
            .restore(DefaultFormalSystemIds.grammar, snapshot.sidecar);
        ref
            .read(documentAnnotationsProvider.notifier)
            .restore(DefaultFormalSystemIds.grammar, snapshot.annotations);
      },
      systemLabel: (context, _) =>
          appLocalizationsOf(context).fileSectionGrammar,
      formatLabel: defaultDocumentFormatLabel,
      replace: (document) async {
        final loaded = document.document;
        if (loaded is! Grammar) {
          throw StateError(
            'The grammar workspace received a non-grammar document.',
          );
        }
        ref.read(grammarProvider.notifier).applyGrammar(loaded);
        final loadedState = ref.read(grammarProvider);
        ref
            .read(interoperableDocumentSidecarProvider.notifier)
            .store(
              document,
              documentIdentity: (
                loadedState.documentId,
                loadedState.documentGeneration,
              ),
            );
        ref
            .read(documentAnnotationsProvider.notifier)
            .restore(
              DefaultFormalSystemIds.grammar,
              annotationsFromImportedDocument(
                document,
                documentId: loadedState.documentId,
                documentRevision: '${loadedState.documentGeneration}',
              ),
            );
      },
    );
  }

  Widget _buildAlgorithmButtons(BuildContext context) {
    final grammarState = ref.watch(grammarProvider);
    return Column(
      children: [
        AlgorithmExamplesSection<Grammar>(
          examplesFuture: _grammarExamplesFuture,
          loadingExampleName: _loadingExampleName,
          onExampleSelected: _loadSelectedExample,
          failureMessage: 'Failed to load grammar examples.',
          emptyMessage: 'No grammar examples available.',
          exampleBuilder: (context, example, isLoading, onPressed) =>
              AssetExampleContentButton.maybeBuild(
                context: context,
                example: example,
                isLoading: isLoading,
                onPressed: onPressed,
              ),
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        _buildConversionSection(context, grammarState),
        const SizedBox(height: 24),
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: appLocalizationsOf(context).classifyGrammarTitle,
            description: appLocalizationsOf(context).classifyGrammarDescription,
            icon: Icons.account_tree_outlined,
            isEnabled: !_isAnalyzing,
            isExecuting: false,
            onPressed: _classifyGrammar,
          ),
        ),
        const SizedBox(height: 12),
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: appLocalizationsOf(
              context,
            ).localizeWorkflowText('Variable dependency graph'),
            description: appLocalizationsOf(context).localizeWorkflowText(
              'Explore direct and left-corner dependencies with exact production provenance.',
            ),
            icon: Icons.hub_outlined,
            isEnabled: !_isAnalyzing && grammarState.productions.isNotEmpty,
            onPressed: _openVariableDependencyGraph,
          ),
          key: const ValueKey('open-variable-dependency-graph'),
        ),
        const SizedBox(height: 12),
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: appLocalizationsOf(context).convertToCnfTitle,
            description: appLocalizationsOf(context).convertToCnfDescription,
            icon: Icons.filter_list,
            isEnabled: !_isAnalyzing,
            isExecuting: _isAnalyzing,
            onPressed: _convertToCnf,
          ),
        ),
        const SizedBox(height: 12),
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: appLocalizationsOf(
              context,
            ).localizeWorkflowText('Practice grammar normalization'),
            description: appLocalizationsOf(context).localizeWorkflowText(
              'Propose lambda, unit, useless-production, and CNF steps and check each hypothesis.',
            ),
            icon: Icons.school_outlined,
            isEnabled: !_isAnalyzing && grammarState.productions.isNotEmpty,
            onPressed: _openNormalizationTeaching,
          ),
          key: const ValueKey('open-normalization-teaching'),
        ),
        const SizedBox(height: 12),
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: appLocalizationsOf(context).convertToGnfTitle,
            description: appLocalizationsOf(context).convertToGnfDescription,
            icon: Icons.format_list_numbered,
            isEnabled: !_isAnalyzing,
            isExecuting: _isAnalyzing,
            onPressed: _convertToGnf,
          ),
        ),
        const SizedBox(height: 12),
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: appLocalizationsOf(context).removeLeftRecursionTitle,
            description: appLocalizationsOf(
              context,
            ).removeLeftRecursionDescription,
            icon: Icons.transform,
            isEnabled: !_isAnalyzing,
            isExecuting: _isAnalyzing,
            onPressed: _removeLeftRecursion,
          ),
        ),
        const SizedBox(height: 12),
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: appLocalizationsOf(context).leftFactorTitle,
            description: appLocalizationsOf(context).leftFactorDescription,
            icon: Icons.account_tree,
            isEnabled: !_isAnalyzing,
            isExecuting: _isAnalyzing,
            onPressed: _leftFactor,
          ),
        ),
        const SizedBox(height: 12),
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: appLocalizationsOf(context).findFirstSetsTitle,
            description: appLocalizationsOf(context).findFirstSetsDescription,
            icon: Icons.first_page,
            isEnabled: !_isAnalyzing,
            isExecuting: _isAnalyzing,
            onPressed: _findFirstSets,
          ),
        ),
        const SizedBox(height: 12),
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: appLocalizationsOf(context).findFollowSetsTitle,
            description: appLocalizationsOf(context).findFollowSetsDescription,
            icon: Icons.last_page,
            isEnabled: !_isAnalyzing,
            isExecuting: _isAnalyzing,
            onPressed: _findFollowSets,
          ),
        ),
        const SizedBox(height: 12),
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: appLocalizationsOf(context).buildParseTableTitle,
            description: appLocalizationsOf(context).buildParseTableDescription,
            icon: Icons.table_chart,
            isEnabled: !_isAnalyzing,
            isExecuting: _isAnalyzing,
            onPressed: _buildParseTable,
          ),
        ),
        const SizedBox(height: 12),
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: appLocalizationsOf(context).checkAmbiguityTitle,
            description: appLocalizationsOf(context).checkAmbiguityDescription,
            icon: Icons.rule,
            isEnabled: !_isAnalyzing,
            isExecuting: _isAnalyzing,
            onPressed: _checkAmbiguity,
          ),
        ),
      ],
    );
  }

  Future<void> _openVariableDependencyGraph() async {
    final snapshot = ref.read(grammarProvider.notifier).buildGrammar();
    final revision = LegacyContextFreeGrammarAdapter.sourceRevision(snapshot);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (context, dialogRef, _) {
          dialogRef.watch(grammarProvider);
          final current = dialogRef
              .read(grammarProvider.notifier)
              .buildGrammar();
          final invalidated =
              current.id != snapshot.id ||
              LegacyContextFreeGrammarAdapter.sourceRevision(current) !=
                  revision;
          final workspace = SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: VariableDependencyGraphWorkspace.contextFree(
              grammar: snapshot,
              sourceRevision: revision,
              invalidated: invalidated,
            ),
          );
          if (MediaQuery.sizeOf(context).width < 700) {
            return Dialog.fullscreen(
              child: Scaffold(
                appBar: AppBar(
                  title: Text(
                    appLocalizationsOf(
                      context,
                    ).localizeWorkflowText('Variable dependency graph'),
                  ),
                  leading: IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ),
                body: workspace,
              ),
            );
          }
          return Dialog(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120, maxHeight: 860),
              child: workspace,
            ),
          );
        },
      ),
    );
  }

  Future<void> _openNormalizationTeaching() async {
    final grammar = ref.read(grammarProvider.notifier).buildGrammar();
    final workspace = GrammarNormalizationTeachingWorkspace(
      grammar: grammar,
      store: ref.read(grammarTeachingSessionStoreProvider),
    );
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final content = SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: workspace,
        );
        if (MediaQuery.sizeOf(dialogContext).width < 700) {
          return Dialog.fullscreen(
            child: Scaffold(
              appBar: AppBar(
                title: Text(
                  appLocalizationsOf(
                    dialogContext,
                  ).localizeWorkflowText('Practice grammar normalization'),
                ),
                leading: IconButton(
                  tooltip: MaterialLocalizations.of(
                    dialogContext,
                  ).closeButtonTooltip,
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.close),
                ),
              ),
              body: SafeArea(child: content),
            ),
          );
        }
        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900, maxHeight: 820),
            child: content,
          ),
        );
      },
    );
  }

  Future<void> _openCfgToPdaConstruction(
    CfgToPdaOrientation orientation,
  ) async {
    final snapshot = ref.read(grammarProvider.notifier).buildGrammar();
    final revision = LegacyContextFreeGrammarAdapter.sourceRevision(snapshot);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (context, dialogRef, _) {
          dialogRef.watch(grammarProvider);
          final current = dialogRef
              .read(grammarProvider.notifier)
              .buildGrammar();
          final invalidated =
              current.id != snapshot.id ||
              LegacyContextFreeGrammarAdapter.sourceRevision(current) !=
                  revision;

          Future<void> open(PDA pda) async {
            final shouldReplace = await confirmConversionDestinationReplacement(
              context: dialogContext,
              ref: ref,
              destination: ConversionDestination.pushdownAutomaton,
            );
            if (!shouldReplace || !mounted || !dialogContext.mounted) return;
            final previousPda = ref.read(pdaEditorProvider.notifier).currentPda;
            final previousNavigation = ref.read(homeNavigationProvider);
            ref.read(pdaEditorProvider.notifier).setPda(pda);
            ref.read(homeNavigationProvider.notifier).goToPda();
            Navigator.of(dialogContext).pop();
            showAppSnackBar(
              this.context,
              message: appLocalizationsOf(this.context).localizeWorkflowText(
                'CFG to PDA construction opened in the PDA editor.',
              ),
              tone: AppSnackBarTone.success,
              duration: const Duration(seconds: 6),
              actionLabel: appLocalizationsOf(
                this.context,
              ).localizeWorkflowText('Undo'),
              onAction: () {
                final notifier = ref.read(pdaEditorProvider.notifier);
                if (previousPda == null) {
                  notifier.clear();
                } else {
                  notifier.setPda(previousPda);
                }
                ref
                    .read(homeNavigationProvider.notifier)
                    .setIndex(previousNavigation);
              },
            );
          }

          final workspace = SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: CfgToPdaConstructionWorkspace(
              grammar: snapshot,
              sourceRevision: revision,
              orientation: orientation,
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
                      orientation == CfgToPdaOrientation.ll
                          ? 'CFG to PDA (LL) construction'
                          : 'CFG to PDA (LR) construction',
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

  Future<void> _loadSelectedExample(String exampleName) async {
    setState(() {
      _loadingExampleName = exampleName;
    });

    try {
      final result = await _examplesDataSource.loadTypedCfgExample(exampleName);
      if (!mounted) return;

      if (result.isFailure) {
        _showExampleFeedback(
          'Failed to load example: ${result.error}',
          tone: AppSnackBarTone.error,
        );
        return;
      }

      final grammar = result.data!.payload;
      ref.read(grammarProvider.notifier).applyGrammar(grammar);
      setState(_clearAnalysisResults);
      _showExampleFeedback('Example loaded: ${grammar.name}');
    } catch (error) {
      if (!mounted) return;
      _showExampleFeedback(
        'Failed to load example: $error',
        tone: AppSnackBarTone.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingExampleName = null;
        });
      }
    }
  }

  void _showExampleFeedback(
    String message, {
    AppSnackBarTone tone = AppSnackBarTone.success,
  }) {
    showAppSnackBar(
      context,
      message: appLocalizationsOf(context).localizeWorkflowText(message),
      tone: tone,
    );
  }

  void _clearAnalysisResults() {
    _analysisResult = null;
    _classificationReport = null;
    _transformationSteps = const [];
    _transformationStepMessages = const [];
  }

  Widget _buildConversionSection(
    BuildContext context,
    GrammarState grammarState,
  ) {
    final strings = appLocalizationsOf(context);
    final hasProductions = grammarState.productions.isNotEmpty;
    final isBusy = grammarState.isConverting;
    final isDisabled = isBusy || !hasProductions;
    final activeConversion = grammarState.activeConversion;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          appLocalizationsOf(context).localizeWorkflowText('Conversions'),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: appLocalizationsOf(context).convertRightLinearToFsaTitle,
            description: appLocalizationsOf(
              context,
            ).convertRightLinearToFsaDescription,
            icon: Icons.sync_alt,
            isExecuting:
                isBusy &&
                activeConversion == GrammarConversionKind.grammarToFsa,
            isEnabled: !isDisabled,
            executionStatus: appLocalizationsOf(context).convertingToFsa,
            onPressed: _convertToAutomaton,
          ),
        ),
        const SizedBox(height: 12),
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: appLocalizationsOf(
              context,
            ).localizeWorkflowText('Practice Regular Grammar to FA'),
            description: appLocalizationsOf(context).localizeWorkflowText(
              'Map nonterminals and productions to an automaton with source provenance.',
            ),
            icon: Icons.school_outlined,
            isEnabled: !isBusy && grammarState.type == GrammarType.regular,
            onPressed: _openManualGrammarToFaConstruction,
          ),
        ),
        const SizedBox(height: 12),
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: appLocalizationsOf(context).convertGrammarToPdaGeneralTitle,
            description: appLocalizationsOf(
              context,
            ).convertGrammarToPdaGeneralDescription,
            icon: Icons.auto_fix_high,
            isExecuting:
                isBusy &&
                activeConversion == GrammarConversionKind.grammarToPda,
            isEnabled: !isDisabled,
            executionStatus: appLocalizationsOf(context).convertingToPda,
            onPressed: _convertToPdaGeneral,
          ),
        ),
        const SizedBox(height: 12),
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: appLocalizationsOf(context).convertGrammarToPdaStandardTitle,
            description: appLocalizationsOf(
              context,
            ).convertGrammarToPdaStandardDescription,
            icon: Icons.layers,
            isExecuting:
                isBusy &&
                activeConversion == GrammarConversionKind.grammarToPdaStandard,
            isEnabled: !isDisabled,
            executionStatus: appLocalizationsOf(context).convertingStandard,
            onPressed: _convertToPdaStandard,
          ),
        ),
        const SizedBox(height: 12),
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: appLocalizationsOf(context).convertGrammarToPdaGreibachTitle,
            description: appLocalizationsOf(
              context,
            ).convertGrammarToPdaGreibachDescription,
            icon: Icons.stacked_bar_chart,
            isExecuting:
                isBusy &&
                activeConversion == GrammarConversionKind.grammarToPdaGreibach,
            isEnabled: !isDisabled,
            executionStatus: appLocalizationsOf(context).convertingGreibach,
            onPressed: _convertToPdaGreibach,
          ),
        ),
        const SizedBox(height: 12),
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: appLocalizationsOf(
              context,
            ).localizeWorkflowText('CFG to PDA (LL) construction'),
            description: appLocalizationsOf(context).localizeWorkflowText(
              'Preview a conflict-free top-down LL stack construction with provenance.',
            ),
            icon: Icons.vertical_align_bottom,
            isEnabled: !isDisabled,
            onPressed: () => _openCfgToPdaConstruction(CfgToPdaOrientation.ll),
          ),
          key: const ValueKey('open-cfg-to-pda-ll'),
        ),
        const SizedBox(height: 12),
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: appLocalizationsOf(
              context,
            ).localizeWorkflowText('CFG to PDA (LR) construction'),
            description: appLocalizationsOf(context).localizeWorkflowText(
              'Preview conflict-free bottom-up shifts and reductions with LR item provenance.',
            ),
            icon: Icons.vertical_align_top,
            isEnabled: !isDisabled,
            onPressed: () => _openCfgToPdaConstruction(CfgToPdaOrientation.lr),
          ),
          key: const ValueKey('open-cfg-to-pda-lr'),
        ),
        if (!hasProductions)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              appLocalizationsOf(context).addAtLeastOneProductionRule,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        if (grammarState.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              grammarState.structuredError == null
                  ? strings.localizeWorkflowText(grammarState.error!)
                  : strings.resolveStructuredMessage(
                      grammarState.structuredError!,
                    ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _convertToAutomaton() async {
    final shouldReplace = await confirmConversionDestinationReplacement(
      context: context,
      ref: ref,
      destination: ConversionDestination.automaton,
    );
    if (!mounted || !shouldReplace) return;

    final result = await ref
        .read(grammarProvider.notifier)
        .convertToAutomaton();

    if (!mounted) return;

    if (result.isSuccess) {
      final automaton = result.data!;
      ref.read(automatonStateProvider.notifier).replaceAutomaton(automaton);

      if (!mounted) return;

      ref.read(homeNavigationProvider.notifier).goToFsa();

      showAppSnackBar(
        context,
        message: appLocalizationsOf(context).grammarConvertedToAutomaton,
        tone: AppSnackBarTone.success,
      );
    } else {
      final strings = appLocalizationsOf(context);
      final message = result.structuredError == null
          ? result.error ?? strings.failedToConvertGrammarToAutomaton
          : strings.resolveStructuredMessage(result.structuredError!);
      showAppSnackBar(
        context,
        message: strings.localizeWorkflowText(message),
        tone: AppSnackBarTone.error,
      );
    }
  }

  Future<void> _openManualGrammarToFaConstruction() async {
    final grammarState = ref.read(grammarProvider);
    final source = ref.read(grammarProvider.notifier).buildGrammar();
    final sessionResult = FaGrammarSessionFactory.fromRightLinearGrammar(
      sessionId:
          'manual.grammar-to-fa.${source.id}.${grammarState.documentGeneration}',
      source: source,
      sourceRevision: grammarState.documentGeneration,
    );
    if (!sessionResult.isSuccess || sessionResult.data == null) {
      showAppSnackBar(
        context,
        message: appLocalizationsOf(context).localizeWorkflowText(
          sessionResult.error ?? 'Could not start the construction.',
        ),
        tone: AppSnackBarTone.error,
      );
      return;
    }
    final manualSession = sessionResult.data!;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Consumer(
        builder: (context, dialogRef, _) {
          final liveState = dialogRef.watch(grammarProvider);
          final liveSource = dialogRef
              .read(grammarProvider.notifier)
              .buildGrammar();
          final checkedSession = manualSession.checkSource(
            documentId: liveSource.id,
            revision: liveState.documentGeneration,
          );
          return Dialog.fullscreen(
            child: ManualConversionWorkspace(
              title: appLocalizationsOf(context).localizeWorkflowText(
                'Manual Regular Grammar to FA construction',
              ),
              workspaceKey:
                  'grammar-to-fa.${source.id}.${grammarState.documentGeneration}',
              initialSession: checkedSession,
              currentSourceDocumentId: liveSource.id,
              currentSourceRevision: liveState.documentGeneration,
              sourcePreview: ManualConversionDocumentPreview.grammar(
                liveSource,
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
                final result = FaGrammarSessionFactory.fromRightLinearGrammar(
                  sessionId: invalidated.id,
                  source: liveSource,
                  sourceRevision: liveState.documentGeneration,
                );
                if (!result.isSuccess || result.data == null) {
                  throw StateError(
                    result.error ?? 'Invalid edited regular grammar.',
                  );
                }
                return invalidated.restartFromNewSource(
                  freshSession: result.data!,
                );
              },
              onBranchFromSource: (invalidated, branchId) {
                final result = FaGrammarSessionFactory.fromRightLinearGrammar(
                  sessionId: branchId,
                  source: liveSource,
                  sourceRevision: liveState.documentGeneration,
                );
                if (!result.isSuccess || result.data == null) {
                  throw StateError(
                    result.error ?? 'Invalid edited regular grammar.',
                  );
                }
                return invalidated.branchFromNewSource(
                  branchId: branchId,
                  freshSession: result.data!,
                );
              },
              onClose: () => Navigator.of(dialogContext).pop(),
              onOpenResult: (artifact) async {
                final encodedFsa = artifact['document'];
                if (encodedFsa is! Map || !dialogContext.mounted) return;
                final shouldReplace =
                    await confirmConversionDestinationReplacement(
                      context: dialogContext,
                      ref: ref,
                      destination: ConversionDestination.automaton,
                    );
                if (!shouldReplace || !mounted || !dialogContext.mounted) {
                  return;
                }
                final fsa = FSA.fromJson(Map<String, dynamic>.from(encodedFsa));
                ref.read(automatonStateProvider.notifier).replaceAutomaton(fsa);
                ref.read(homeNavigationProvider.notifier).goToFsa();
                Navigator.of(dialogContext).pop();
                showAppSnackBar(
                  context,
                  message: appLocalizationsOf(context).localizeWorkflowText(
                    'Manual construction opened in the FA editor.',
                  ),
                  tone: AppSnackBarTone.success,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _convertToPdaGeneral() {
    return _handlePdaConversion(
      convert: () => ref.read(grammarProvider.notifier).convertToPda(),
      successMessage: appLocalizationsOf(context).grammarConvertedToPdaGeneral,
    );
  }

  Future<void> _convertToPdaStandard() {
    return _handlePdaConversion(
      convert: () => ref.read(grammarProvider.notifier).convertToPdaStandard(),
      successMessage: appLocalizationsOf(context).grammarConvertedToPdaStandard,
    );
  }

  Future<void> _convertToPdaGreibach() {
    return _handlePdaConversion(
      convert: () => ref.read(grammarProvider.notifier).convertToPdaGreibach(),
      successMessage: appLocalizationsOf(context).grammarConvertedToPdaGreibach,
    );
  }

  Future<void> _handlePdaConversion({
    required Future<Result<PDA>> Function() convert,
    required String successMessage,
  }) async {
    final shouldReplace = await confirmConversionDestinationReplacement(
      context: context,
      ref: ref,
      destination: ConversionDestination.pushdownAutomaton,
    );
    if (!mounted || !shouldReplace) return;

    final result = await convert();

    if (!mounted) return;

    if (result.isSuccess) {
      final pda = result.data!;
      ref.read(pdaEditorProvider.notifier).setPda(pda);
      ref.read(homeNavigationProvider.notifier).goToPda();

      showAppSnackBar(
        context,
        message: successMessage,
        tone: AppSnackBarTone.success,
      );
    } else {
      final strings = appLocalizationsOf(context);
      final message = result.structuredError == null
          ? result.error ?? strings.failedToConvertGrammarToPda
          : strings.resolveStructuredMessage(result.structuredError!);
      showAppSnackBar(
        context,
        message: strings.localizeWorkflowText(message),
        tone: AppSnackBarTone.error,
      );
    }
  }

  Widget _buildResultsSection(BuildContext context) {
    return AlgorithmResultsSection(
      hasResults: _transformationSteps.isNotEmpty || _analysisResult != null,
      emptyBuilder: _buildEmptyResults,
      resultsBuilder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_transformationSteps.isNotEmpty) ...[
            GrammarTransformationHistory(
              steps: _transformationSteps,
              structuredMessages: _transformationStepMessages,
              onApplyGrammar: (grammar) {
                ref.read(grammarProvider.notifier).applyGrammar(grammar);
                showAppSnackBar(
                  context,
                  message: appLocalizationsOf(
                    context,
                  ).localizeWorkflowText('Grammar applied to editor.'),
                  tone: AppSnackBarTone.success,
                );
              },
            ),
            const SizedBox(height: 12),
          ],
          if (_analysisResult == null)
            _buildEmptyResults(context)
          else
            _buildResults(context),
        ],
      ),
    );
  }

  Widget _buildEmptyResults(BuildContext context) {
    return SimulationEmptyResults(
      icon: Icons.analytics_outlined,
      title: appLocalizationsOf(context).noAnalysisResultsYet,
      message: appLocalizationsOf(context).selectAlgorithmToAnalyzeGrammar,
    );
  }

  Widget _buildResults(BuildContext context) {
    return AlgorithmResultsCard(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              EmptyStringNotation.formatMarkers(
                context,
                appLocalizationsOf(
                  context,
                ).localizeWorkflowText(_analysisResult!),
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamilyFallback: kMonospaceFontFamilyFallback,
              ),
            ),
            if (_classificationReport
                case final PhraseGrammarClassificationReport report) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    key: const ValueKey('copy-classification-report'),
                    onPressed: () => _copyClassificationReport(report),
                    icon: const Icon(Icons.copy),
                    label: Text(
                      appLocalizationsOf(context).copyClassificationReport,
                    ),
                  ),
                  if (!report.declaredTypeMatches &&
                      _toLegacyType(report.classification) != null)
                    FilledButton.tonalIcon(
                      key: const ValueKey('update-declared-grammar-type'),
                      onPressed: () => _confirmDeclaredTypeUpdate(report),
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(
                        appLocalizationsOf(context).updateDeclaredGrammarType,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _classifyGrammar() {
    final grammar = ref.read(grammarProvider.notifier).buildGrammar();
    final report = PhraseGrammarClassifier.classifyLegacy(grammar);
    setState(() {
      _classificationReport = report;
      _transformationSteps = const [];
      _transformationStepMessages = const [];
      _analysisResult = _formatClassificationReport(report);
    });
  }

  String _formatClassificationReport(PhraseGrammarClassificationReport report) {
    final strings = appLocalizationsOf(context);
    final workspaceStrings = UnrestrictedGrammarWorkspaceStrings.forLocale(
      Localizations.localeOf(context),
    );
    final normalForms = report.normalForms.isEmpty
        ? workspaceStrings.noNormalForms
        : report.normalForms.map(workspaceStrings.normalForm).join(', ');
    final buffer = StringBuffer()
      ..writeln(strings.classifyGrammarTitle)
      ..writeln()
      ..writeln(
        '${strings.inferredGrammarType}: '
        '${_classificationLabel(report.classification)}',
      )
      ..writeln(
        '${strings.declaredGrammarType}: '
        '${_classificationLabel(report.declaredClassification!)}',
      )
      ..writeln(
        '${workspaceStrings.regularOrientationLabel}: '
        '${workspaceStrings.orientation(report.regularOrientation)}',
      )
      ..writeln('${workspaceStrings.normalFormsLabel}: $normalForms')
      ..writeln()
      ..writeln(strings.grammarStructureNotLanguageClass);
    if (report.diagnostics.isNotEmpty) {
      final diagnosticsHeading = strings.diagnosticsHeading.endsWith(':')
          ? strings.diagnosticsHeading
          : '${strings.diagnosticsHeading}:';
      buffer
        ..writeln()
        ..writeln(diagnosticsHeading);
      for (final diagnostic in report.diagnostics) {
        buffer.writeln('- ${workspaceStrings.diagnostic(diagnostic)}');
      }
    }
    if (report.productionEvidence.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('${workspaceStrings.productionEvidenceLabel}:');
      for (final evidence in report.productionEvidence) {
        final predicates = evidence.violated
            .map(workspaceStrings.predicate)
            .join(', ');
        buffer.writeln(
          '- ${evidence.productionId}: '
          '${evidence.violated.isEmpty ? workspaceStrings.allPredicatesSatisfied : workspaceStrings.violatesPredicates(predicates)}',
        );
      }
    }
    return buffer.toString();
  }

  String _classificationLabel(PhraseGrammarClassification classification) {
    final portuguese = Localizations.localeOf(context).languageCode == 'pt';
    return portuguese
        ? switch (classification) {
            PhraseGrammarClassification.regular => 'regular',
            PhraseGrammarClassification.contextFree => 'livre de contexto',
            PhraseGrammarClassification.contextSensitive =>
              'sensível ao contexto',
            PhraseGrammarClassification.unrestricted => 'irrestrita',
            PhraseGrammarClassification.invalid => 'inválida',
          }
        : switch (classification) {
            PhraseGrammarClassification.regular => 'regular',
            PhraseGrammarClassification.contextFree => 'context-free',
            PhraseGrammarClassification.contextSensitive => 'context-sensitive',
            PhraseGrammarClassification.unrestricted => 'unrestricted',
            PhraseGrammarClassification.invalid => 'invalid',
          };
  }

  Future<void> _copyClassificationReport(
    PhraseGrammarClassificationReport report,
  ) async {
    await Clipboard.setData(
      ClipboardData(text: jsonEncode(report.toStructuredJson())),
    );
    if (!mounted) return;
    showAppSnackBar(
      context,
      message: appLocalizationsOf(context).classificationReportCopied,
      tone: AppSnackBarTone.success,
    );
  }

  Future<void> _confirmDeclaredTypeUpdate(
    PhraseGrammarClassificationReport report,
  ) async {
    final inferredType = _toLegacyType(report.classification);
    if (inferredType == null) return;
    final strings = appLocalizationsOf(context);
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(strings.updateDeclaredGrammarTypeTitle),
            content: Text(
              strings.updateDeclaredGrammarTypeMessage(
                _classificationLabel(report.classification),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(
                  MaterialLocalizations.of(context).cancelButtonLabel,
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(strings.updateDeclaredGrammarType),
              ),
            ],
          ),
        ) ??
        false;
    if (!mounted || !confirmed) return;
    final grammar = ref.read(grammarProvider.notifier).buildGrammar();
    ref
        .read(grammarProvider.notifier)
        .applyGrammar(
          grammar.copyWith(type: inferredType, modified: DateTime.now()),
        );
    _classifyGrammar();
  }

  void _removeLeftRecursion() {
    _performAnalysis<Grammar>(
      'Remove Left Recursion',
      (grammar) async => GrammarAnalyzer.removeLeftRecursion(grammar),
      (original, report) {
        _transformationSteps = report.steps;
        _transformationStepMessages = const [];
        final strings = appLocalizationsOf(context);
        return _formatTransformationResult(
          title: strings.leftRecursionRemovalResultTitle,
          original: original,
          transformed: report.value,
          notes: [
            ...report.structuredNotes.map(strings.resolveStructuredMessage),
            ...report.notes,
          ],
          derivations: report.derivations,
        );
      },
    );
  }

  void _leftFactor() {
    _performAnalysis<Grammar>(
      'Left Factoring',
      (grammar) async => GrammarAnalyzer.leftFactor(grammar),
      (original, report) => _formatTransformationResult(
        title: appLocalizationsOf(context).leftFactoringAnalysisTitle,
        original: original,
        transformed: report.value,
        notes: report.notes,
        derivations: report.derivations,
      ),
    );
  }

  void _findFirstSets() {
    _performAnalysis<Map<String, Set<String>>>(
      'FIRST Sets',
      (grammar) async => GrammarAnalyzer.computeFirstSets(grammar),
      (original, report) => _formatSetResult(
        title: appLocalizationsOf(context).firstSetsAnalysisTitle,
        sets: report.value,
        notes: report.notes,
        derivations: report.derivations,
      ),
    );
  }

  void _findFollowSets() {
    _performAnalysis<Map<String, Set<String>>>(
      'FOLLOW Sets',
      (grammar) async => GrammarAnalyzer.computeFollowSets(grammar),
      (original, report) => _formatSetResult(
        title: appLocalizationsOf(context).followSetsAnalysisTitle,
        sets: report.value,
        notes: report.notes,
        derivations: report.derivations,
      ),
    );
  }

  void _buildParseTable() {
    _performAnalysis<LL1ParseTable>(
      'LL(1) Parse Table',
      (grammar) async => GrammarAnalyzer.buildLL1ParseTable(grammar),
      (original, report) => _formatParseTableResult(report),
    );
  }

  void _checkAmbiguity() {
    _performAnalysis<bool>(
      'Ambiguity Check',
      (grammar) async => GrammarAnalyzer.detectAmbiguity(grammar),
      (original, report) => _formatAmbiguityResult(report),
    );
  }

  void _convertToCnf() {
    _performAnalysis<GrammarCnfTransformationReport>(
      'Convert to CNF',
      (grammar) async {
        final result = GrammarCnfTransformer.toCnf(grammar);
        if (result.isSuccess && result.data != null) {
          final errors = result.data!.diagnostics
              .where((d) => d.severity == GrammarDiagnosticSeverity.error)
              .map(_localizedDiagnosticMessage)
              .toList();
          if (errors.isNotEmpty) {
            return ResultFactory.failure(errors.join('\n'));
          }

          return ResultFactory.success(
            GrammarAnalysisReport<GrammarCnfTransformationReport>(
              value: result.data!,
              notes: [
                appLocalizationsOf(context).cnfConversionNote,
                appLocalizationsOf(context).cnfRulesNote,
              ],
            ),
          );
        }

        return ResultFactory.failure(
          result.error ?? appLocalizationsOf(context).cnfConversionFailed,
        );
      },
      (original, report) {
        setState(() {
          _transformationSteps = report.value.steps;
          _transformationStepMessages = [
            for (final structuredStep in report.value.structuredSteps)
              (
                operation: structuredStep.operationMessage,
                rationale: structuredStep.rationaleMessage,
              ),
          ];
        });

        final diagnosticsText = report.value.diagnostics.isEmpty
            ? ''
            : '\n${appLocalizationsOf(context).diagnosticsHeading}\n${report.value.diagnostics.map((d) => '- [${d.severity.name}] ${_localizedDiagnosticMessage(d)}').join('\n')}';

        return _formatTransformationResult(
          title: appLocalizationsOf(context).cnfConversionTitle,
          original: original,
          transformed: report.value.grammar,
          notes: [
            ...report.notes,
            diagnosticsText,
          ].where((s) => s.trim().isNotEmpty).toList(),
          derivations: report.derivations,
        );
      },
    );
  }

  void _convertToGnf() {
    _performAnalysis<GrammarGnfTransformationReport>(
      'Convert to GNF',
      (grammar) async {
        final report = GrammarGnfTransformer.toGnf(grammar);
        final hasError = report.diagnostics.any(
          (d) => d.severity == GrammarDiagnosticSeverity.error,
        );

        if (hasError) {
          return ResultFactory.failure(
            report.diagnostics
                .where((d) => d.severity == GrammarDiagnosticSeverity.error)
                .map(_localizedDiagnosticMessage)
                .join('\n'),
          );
        }

        return ResultFactory.success(
          GrammarAnalysisReport<GrammarGnfTransformationReport>(
            value: report,
            notes: [
              appLocalizationsOf(context).gnfConversionNote,
              appLocalizationsOf(context).gnfRulesNote,
            ],
          ),
        );
      },
      (original, report) {
        setState(() {
          _transformationSteps = report.value.steps;
          _transformationStepMessages = [
            for (final structuredStep in report.value.structuredSteps)
              (
                operation: structuredStep.operationMessage,
                rationale: structuredStep.rationaleMessage,
              ),
          ];
        });

        final diagnosticsText = report.value.diagnostics.isEmpty
            ? ''
            : '\n${appLocalizationsOf(context).diagnosticsHeading}\n${report.value.diagnostics.map((d) => '- [${d.severity.name}] ${_localizedDiagnosticMessage(d)}').join('\n')}';

        return _formatTransformationResult(
          title: appLocalizationsOf(context).gnfConversionTitle,
          original: original,
          transformed: report.value.grammar,
          notes: [
            ...report.notes,
            diagnosticsText,
          ].where((s) => s.trim().isNotEmpty).toList(),
          derivations: report.derivations,
        );
      },
    );
  }

  Future<void> _performAnalysis<T>(
    String algorithmName,
    Future<Result<GrammarAnalysisReport<T>>> Function(Grammar grammar)
    runAnalysis,
    String Function(Grammar original, GrammarAnalysisReport<T> report)
    formatter,
  ) async {
    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
      _classificationReport = null;
      _transformationSteps = const [];
      _transformationStepMessages = const [];
    });

    final grammar = ref.read(grammarProvider.notifier).buildGrammar();
    final validationErrors = grammar.validate();

    if (validationErrors.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _analysisResult = _formatError(
          appLocalizationsOf(context).cannotRunDueToValidation(algorithmName),
          validationErrors,
        );
      });
      return;
    }

    try {
      final result = await runAnalysis(grammar);
      if (!mounted) {
        return;
      }

      setState(() {
        _isAnalyzing = false;
        if (result.isSuccess) {
          _analysisResult = formatter(grammar, result.data!);
          return;
        }
        final strings = appLocalizationsOf(context);
        final structuredError = result.structuredError;
        _analysisResult = structuredError == null
            ? strings.algorithmFailedError(algorithmName, result.error ?? '')
            : strings.resolveStructuredMessage(structuredError);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isAnalyzing = false;
        _analysisResult = appLocalizationsOf(
          context,
        ).algorithmFailedError(algorithmName, '$error');
      });
    }
  }

  String _formatTransformationResult({
    required String title,
    required Grammar original,
    required Grammar transformed,
    required List<String> notes,
    required List<String> derivations,
  }) {
    final buffer = StringBuffer()
      ..writeln(title)
      ..writeln('')
      ..writeln(appLocalizationsOf(context).originalGrammarLabel)
      ..writeln(_formatGrammar(original))
      ..writeln('')
      ..writeln(appLocalizationsOf(context).transformedGrammarLabel)
      ..writeln(_formatGrammar(transformed));

    _appendSection(buffer, appLocalizationsOf(context).notesSection, notes);
    _appendSection(
      buffer,
      appLocalizationsOf(context).derivationsSection,
      derivations,
    );

    return buffer.toString();
  }

  String _formatSetResult({
    required String title,
    required Map<String, Set<String>> sets,
    required List<String> notes,
    required List<String> derivations,
  }) {
    final entries = sets.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final buffer = StringBuffer()
      ..writeln(title)
      ..writeln('');

    for (final entry in entries) {
      final values = entry.value.toList()..sort(_symbolComparator);
      final label = title.contains('FOLLOW') ? 'FOLLOW' : 'FIRST';
      buffer.writeln('$label(${entry.key}) = {${values.join(', ')}}');
    }

    _appendSection(buffer, appLocalizationsOf(context).notesSection, notes);
    _appendSection(
      buffer,
      appLocalizationsOf(context).derivationsSection,
      derivations,
    );

    return buffer.toString();
  }

  String _formatParseTableResult(GrammarAnalysisReport<LL1ParseTable> report) {
    final table = report.value;
    final terminals = table.terminals.toList()..sort(_symbolComparator);
    final nonTerminals = table.nonTerminals.toList()..sort(_symbolComparator);
    final buffer = StringBuffer()
      ..writeln(appLocalizationsOf(context).ll1ParseTableAnalysis)
      ..writeln('');

    buffer.writeln(['NT', ...terminals].join('\t'));
    for (final nt in nonTerminals) {
      final row = <String>[nt];
      for (final terminal in terminals) {
        final entries = table.table[nt]?[terminal] ?? const <List<String>>[];
        if (entries.isEmpty) {
          row.add('-');
        } else {
          row.add(
            entries
                .map(
                  (symbols) =>
                      symbols.isEmpty ? kEpsilonSymbol : symbols.join(' '),
                )
                .join(' | '),
          );
        }
      }
      buffer.writeln(row.join('\t'));
    }

    _appendSection(
      buffer,
      appLocalizationsOf(context).notesSection,
      report.notes,
    );
    _appendSection(
      buffer,
      appLocalizationsOf(context).conflictsSection,
      report.conflicts,
    );
    _appendSection(
      buffer,
      appLocalizationsOf(context).derivationsSection,
      report.derivations,
    );

    return buffer.toString();
  }

  String _formatAmbiguityResult(GrammarAnalysisReport<bool> report) {
    final strings = appLocalizationsOf(context);
    final status = report.value
        ? strings.ll1NoConflicts
        : strings.notLl1Conflicts;
    final buffer = StringBuffer()
      ..writeln(strings.ll1Classification)
      ..writeln('')
      ..writeln(strings.classificationLabel(status));

    _appendSection(buffer, strings.notesSection, [
      ...report.structuredNotes.map(strings.resolveStructuredMessage),
      ...report.notes.map(strings.localizeWorkflowText),
    ]);
    _appendSection(buffer, strings.conflictsSection, report.conflicts);
    _appendSection(buffer, strings.derivationsSection, report.derivations);

    return buffer.toString();
  }

  String _formatGrammar(Grammar grammar) {
    final productions = grammar.productions.toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    final grouped = <String, List<String>>{};

    for (final production in productions) {
      if (production.leftSide.isEmpty) {
        continue;
      }
      final left = production.leftSide.first;
      final right = production.isLambda || production.rightSide.isEmpty
          ? kEpsilonSymbol
          : production.rightSide.join(' ');
      grouped.putIfAbsent(left, () => <String>[]).add(right);
    }

    final nonTerminals = grouped.keys.toList()..sort(_symbolComparator);
    return nonTerminals
        .map((nt) => '$nt → ${grouped[nt]!.join(' | ')}')
        .join('\n');
  }

  void _appendSection(StringBuffer buffer, String title, List<String> entries) {
    if (entries.isEmpty) {
      return;
    }

    buffer
      ..writeln('')
      ..writeln('$title:');
    for (final entry in entries) {
      buffer.writeln('- $entry');
    }
  }

  String _formatError(String heading, List<String> messages) {
    final buffer = StringBuffer()
      ..writeln(heading)
      ..writeln('');

    for (final message in messages) {
      buffer.writeln('- $message');
    }

    return buffer.toString();
  }

  String _localizedDiagnosticMessage(GrammarDiagnostic diagnostic) {
    final strings = appLocalizationsOf(context);
    final structured = diagnostic.structuredMessage;
    return structured == null
        ? strings.localizeWorkflowText(diagnostic.message)
        : strings.resolveStructuredMessage(structured);
  }

  int _symbolComparator(String a, String b) {
    if (a == b) {
      return 0;
    }
    return a.compareTo(b);
  }
}

final class _GrammarImportCheckpoint {
  const _GrammarImportCheckpoint({
    required this.editor,
    required this.sidecar,
    required this.annotations,
  });

  final GrammarState editor;
  final InteroperableDocumentSidecarEntry? sidecar;
  final DocumentAnnotationCollection? annotations;
}

GrammarType? _toLegacyType(PhraseGrammarClassification classification) =>
    switch (classification) {
      PhraseGrammarClassification.regular => GrammarType.regular,
      PhraseGrammarClassification.contextFree => GrammarType.contextFree,
      PhraseGrammarClassification.contextSensitive =>
        GrammarType.contextSensitive,
      PhraseGrammarClassification.unrestricted => GrammarType.unrestricted,
      PhraseGrammarClassification.invalid => null,
    };
