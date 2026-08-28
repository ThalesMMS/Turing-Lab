//
//  pda_algorithm_panel.dart
//  Turing Lab
//
//  Presents a PDA algorithm hub with conversions, checks, and diagnostics.
//  Coordinates conversion-service calls, shows loading states, and
//  summarizes textual results to guide PDA adjustments.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/algorithms/pda_to_cfg_converter.dart';
import '../../core/algorithms/pda_language_emptiness_analyzer.dart';
import '../../core/algorithms/pda_normalizer.dart';
import '../../core/algorithms/pda_simplifier.dart';
import '../../core/algorithms/pda_simulator.dart';
import '../../core/formal_systems/formal_systems.dart';
import '../../core/annotations/annotations.dart';
import '../../core/models/grammar.dart';
import '../../core/models/pda.dart';
import '../../core/models/pda_simplification.dart';
import '../../core/models/simulation_highlight.dart';
import '../../core/models/asset_example.dart';
import '../../core/repositories/examples_repository.dart';
import '../../core/result.dart';
import '../../core/services/canvas_highlight_coordinator.dart';
import '../../core/utils/epsilon_utils.dart';
import '../../injection/data_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_structured_messages.dart';
import '../../l10n/app_localizations_workflows.dart';
import '../providers/pda_editor_provider.dart';
import '../providers/pda_simulation_provider.dart' show pdaSimulationProvider;
import '../providers/grammar_provider.dart';
import '../providers/home_navigation_provider.dart';
import '../providers/interoperable_document_sidecar_provider.dart';
import '../providers/document_annotations_provider.dart';
import 'algorithm_panel_scaffold.dart';
import 'app_snackbar.dart';
import 'asset_example_content_button.dart';
import 'base_simulation_panel.dart';
import 'common/algorithm_button_config.dart';
import 'conversion_replacement_dialog.dart';
import 'document_interoperability_binding.dart';
import 'file_operations_panel.dart';
import 'interoperability_presentation_labels.dart';
import '../../core/constants/monospace_typography.dart';

/// Panel for PDA analysis algorithms
class PDAAlgorithmPanel extends ConsumerStatefulWidget {
  const PDAAlgorithmPanel({
    super.key,
    this.useExpanded = true,
    this.examplesDataSource,
    this.onApplyPda,
  });

  final bool useExpanded;
  final ExamplesRepository? examplesDataSource;
  final ValueChanged<PDA>? onApplyPda;

  @override
  ConsumerState<PDAAlgorithmPanel> createState() => _PDAAlgorithmPanelState();
}

final class _PdaImportCheckpoint {
  const _PdaImportCheckpoint({
    required this.pda,
    required this.sidecar,
    required this.annotations,
  });

  final PDA? pda;
  final InteroperableDocumentSidecarEntry? sidecar;
  final DocumentAnnotationCollection? annotations;
}

class _PDAAlgorithmPanelState extends ConsumerState<PDAAlgorithmPanel> {
  bool _isAnalyzing = false;
  String? _loadingExampleName;
  String? _analysisResult;
  Grammar? _latestConvertedGrammar;
  PDALanguageEmptinessProof? _latestLanguageProof;
  PDA? _latestLanguageSourcePda;
  CanvasHighlightSourceHandle? _analysisHighlights;
  late final ExamplesRepository _examplesDataSource;
  late final Future<ListResult<AssetExample<PDA>>> _pdaExamplesFuture;

  @override
  void initState() {
    super.initState();
    _examplesDataSource =
        widget.examplesDataSource ?? ref.read(examplesRepositoryProvider);
    _pdaExamplesFuture = _examplesDataSource.loadAllTypedPdaExamples();
    _analysisHighlights = ref
        .read(canvasHighlightCoordinatorProvider)
        ?.source(CanvasHighlightSource.analysis);
  }

  @override
  void dispose() {
    _analysisHighlights?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pda = ref.watch(pdaEditorProvider).pda;

    return AlgorithmPanelScaffold(
      title: appLocalizationsOf(context).pdaAnalysisTitle,
      children: [
        _buildAlgorithmButtons(context),
        _buildResultsSection(context),
        const Divider(),
        FileOperationsPanel(
          pda: pda,
          annotations: pda == null
              ? null
              : annotationsForDocument(
                  ref.watch(documentAnnotationsProvider),
                  DefaultFormalSystemIds.pda,
                  pda.id,
                ),
          interoperability: _interoperabilityBinding(pda),
        ),
      ],
    );
  }

  DocumentInteroperabilityBinding _interoperabilityBinding(PDA? pda) {
    final registry = ref.read(documentInteroperabilityRegistryProvider);
    final descriptor = registry.formalSystems.descriptorFor(
      DefaultFormalSystemIds.pda,
    )!;
    final sidecar = ref.watch(
      interoperableDocumentSidecarProvider,
    )[DefaultFormalSystemIds.pda];
    final currentDocument = pda == null
        ? null
        : resolveInteroperableDocument(
            sidecar: sidecar,
            currentDocument: pda,
            documentIdentity: (pda.id, identityHashCode(pda)),
            systemKey: DefaultFormalSystemIds.pda,
            schema: descriptor.schema,
            annotations: annotationsForDocument(
              ref.watch(documentAnnotationsProvider),
              DefaultFormalSystemIds.pda,
              pda.id,
            ),
          );
    return DocumentInteroperabilityBinding(
      registry: registry,
      systemKey: DefaultFormalSystemIds.pda,
      currentDocument: currentDocument,
      captureCheckpoint: () => _PdaImportCheckpoint(
        pda: ref.read(pdaEditorProvider).pda,
        sidecar: ref.read(
          interoperableDocumentSidecarProvider,
        )[DefaultFormalSystemIds.pda],
        annotations: ref.read(
          documentAnnotationsProvider,
        )[DefaultFormalSystemIds.pda],
      ),
      restoreCheckpoint: (checkpoint) {
        final snapshot = checkpoint! as _PdaImportCheckpoint;
        if (snapshot.pda case final previous?) {
          ref.read(pdaEditorProvider.notifier).setPda(previous);
          ref.read(pdaSimulationProvider.notifier).setPda(previous);
        } else {
          ref.read(pdaEditorProvider.notifier).clear();
          ref.read(pdaSimulationProvider.notifier).clear();
        }
        ref
            .read(interoperableDocumentSidecarProvider.notifier)
            .restore(DefaultFormalSystemIds.pda, snapshot.sidecar);
        ref
            .read(documentAnnotationsProvider.notifier)
            .restore(DefaultFormalSystemIds.pda, snapshot.annotations);
      },
      systemLabel: (context, _) => appLocalizationsOf(context).fileSectionPda,
      formatLabel: defaultDocumentFormatLabel,
      replace: (document) async {
        final loaded = document.document;
        if (loaded is! PDA) {
          throw StateError('The PDA workspace received a non-PDA document.');
        }
        ref.read(pdaEditorProvider.notifier).setPda(loaded);
        ref.read(pdaSimulationProvider.notifier).setPda(loaded);
        ref
            .read(interoperableDocumentSidecarProvider.notifier)
            .store(
              document,
              documentIdentity: (loaded.id, identityHashCode(loaded)),
            );
        ref
            .read(documentAnnotationsProvider.notifier)
            .restore(
              DefaultFormalSystemIds.pda,
              annotationsFromImportedDocument(
                document,
                documentId: loaded.id,
                documentRevision: '${identityHashCode(loaded)}',
              ),
            );
      },
    );
  }

  Widget _buildAlgorithmButtons(BuildContext context) {
    final algorithmConfigs = _algorithmButtonConfigs(context);

    return Column(
      children: [
        _buildExamplesSection(context),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        AlgorithmButtonList(configs: algorithmConfigs),
      ],
    );
  }

  List<AlgorithmButtonConfig> _algorithmButtonConfigs(BuildContext context) {
    final strings = appLocalizationsOf(context);
    return [
      AlgorithmButtonConfig(
        title: strings.convertToCfgTitle,
        description: strings.convertToCfgDescription,
        icon: Icons.transform,
        isEnabled: !_isAnalyzing,
        isExecuting: _isAnalyzing,
        onPressed: _convertToCFG,
      ),
      AlgorithmButtonConfig(
        title: strings.pdaSimplificationButtonTitle,
        description: strings.pdaSimplificationButtonDescription,
        icon: Icons.compress,
        isEnabled: !_isAnalyzing,
        isExecuting: _isAnalyzing,
        onPressed: _simplifyPDA,
      ),
      AlgorithmButtonConfig(
        title: strings.checkDeterminismTitle,
        description: strings.checkDeterminismDescription,
        icon: Icons.fact_check_outlined,
        isEnabled: !_isAnalyzing,
        isExecuting: _isAnalyzing,
        onPressed: _checkDeterminism,
      ),
      AlgorithmButtonConfig(
        title: strings.findReachableStatesTitle,
        description: strings.findReachableStatesDescription,
        icon: Icons.explore,
        isEnabled: !_isAnalyzing,
        isExecuting: _isAnalyzing,
        onPressed: _findReachableStates,
      ),
      AlgorithmButtonConfig(
        title: strings.languageAnalysisTitle,
        description: strings.languageAnalysisDescription,
        icon: Icons.analytics,
        isEnabled: !_isAnalyzing,
        isExecuting: _isAnalyzing,
        onPressed: _analyzeLanguage,
      ),
      AlgorithmButtonConfig(
        title: strings.stackOperationsTitle,
        description: strings.stackOperationsDescription,
        icon: Icons.storage,
        isEnabled: !_isAnalyzing,
        isExecuting: _isAnalyzing,
        onPressed: _analyzeStackOperations,
      ),
    ];
  }

  Widget _buildResultsSection(BuildContext context) {
    final hasResults = _analysisResult != null;
    return AlgorithmResultsSection(
      hasResults: hasResults,
      emptyBuilder: _buildEmptyResults,
      resultsBuilder: _buildResults,
    );
  }

  Widget _buildEmptyResults(BuildContext context) {
    return SimulationEmptyResults(
      icon: Icons.analytics_outlined,
      title: appLocalizationsOf(context).noAnalysisResultsYet,
      message: appLocalizationsOf(context).selectAlgorithmToAnalyzePda,
    );
  }

  Widget _buildResults(BuildContext context) {
    final grammar = _latestConvertedGrammar;
    final theme = Theme.of(context);

    return AlgorithmResultsCard(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              appLocalizationsOf(
                context,
              ).localizeWorkflowText(_analysisResult!),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamilyFallback: kMonospaceFontFamilyFallback,
              ),
            ),
            if (grammar != null) ...[
              const SizedBox(height: 16),
              Divider(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
              const SizedBox(height: 12),
              _buildGrammarSummary(context, grammar),
            ],
            if (_latestLanguageProof case final proof?
                when !proof.isEmpty && proof.witnessTrace != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: _openWitnessTrace,
                icon: const Icon(Icons.play_arrow),
                label: Text(appLocalizationsOf(context).openWitnessInSimulator),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _convertToCFG() async {
    final strings = appLocalizationsOf(context);
    final editorState = ref.read(pdaEditorProvider);
    final pda = editorState.pda;

    if (pda == null) {
      _showSnackbar(
        strings.drawPdaBeforeConvertGrammar,
        tone: AppSnackBarTone.error,
      );
      return;
    }

    final shouldReplace = await confirmConversionDestinationReplacement(
      context: context,
      ref: ref,
      destination: ConversionDestination.grammar,
    );
    if (!mounted || !shouldReplace) return;

    setState(() {
      _latestConvertedGrammar = null;
    });

    _performAnalysis(strings.pdaToCfgConversionTitle, (_) async {
      var conversionPda = pda;
      var conversionResult = PDAtoCFGConverter.convert(conversionPda);
      String? normalizationSummary;

      if (conversionResult.isFailure && _canNormalizeForCfg(pda)) {
        final sourceMode = ref.read(pdaSimulationProvider).mode;
        final normalizationResult = PDANormalizer.normalize(
          pda,
          sourceMode: sourceMode,
          targetForm: PDANormalForm.finalStateAndSinglePop,
        );
        if (normalizationResult.isFailure) {
          final message = strings.pdaConversionFailure(
            normalizationResult.error ?? conversionResult.error ?? '',
          );
          _latestConvertedGrammar = null;
          _showSnackbar(message, tone: AppSnackBarTone.error);
          return message;
        }

        final report = normalizationResult.data!;
        final shouldApply = await _showNormalizationPreview(pda, report);
        if (!shouldApply) {
          return strings.pdaConversionCanceledDocumentUnchanged;
        }
        if (!mounted) {
          return strings.pdaConversionCanceledPanelClosed;
        }
        if (!identical(ref.read(pdaEditorProvider).pda, pda)) {
          return strings.pdaConversionCanceledEditorChanged;
        }

        conversionPda = report.normalizedPda;
        ref.read(pdaEditorProvider.notifier).setPda(conversionPda);
        conversionResult = PDAtoCFGConverter.convert(conversionPda);
        normalizationSummary = strings.pdaNormalizationAppliedSummary(
          pda.states.length,
          conversionPda.states.length,
          pda.pdaTransitions.length,
          conversionPda.pdaTransitions.length,
        );
      }

      if (conversionResult.isSuccess) {
        _latestConvertedGrammar = conversionResult.data!.grammar;
        final grammar = _latestConvertedGrammar!;
        _openGeneratedGrammar(grammar);
        final extraSummary = strings.pdaGeneratedGrammarSummary(
          grammar.productions.length,
          grammar.nonterminals.length,
        );
        return [
          if (normalizationSummary != null) normalizationSummary,
          conversionResult.data!.description,
          extraSummary,
        ].join('\n');
      }

      final message = _localizedPdaToCfgFailure(strings, conversionResult);
      _latestConvertedGrammar = null;
      _showSnackbar(message, tone: AppSnackBarTone.error);
      return message;
    }, resetConvertedGrammar: false);
  }

  void _openGeneratedGrammar(Grammar grammar) {
    ref.read(grammarProvider.notifier).applyGrammar(grammar);
    ref.read(homeNavigationProvider.notifier).goToGrammar();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  bool _canNormalizeForCfg(PDA pda) {
    return pda.acceptingStates.isEmpty ||
        pda.pdaTransitions.any(
          (transition) =>
              transition.isLambdaPop || isEpsilonSymbol(transition.popSymbol),
        );
  }

  Future<bool> _showNormalizationPreview(
    PDA source,
    PDANormalizationReport report,
  ) async {
    if (!mounted) return false;

    final decision = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final strings = appLocalizationsOf(dialogContext);
        String formatAcceptanceMode(PDAAcceptanceMode mode) {
          return switch (mode) {
            PDAAcceptanceMode.finalState => strings.pdaAcceptanceFinalState,
            PDAAcceptanceMode.emptyStack => strings.pdaAcceptanceEmptyStack,
            PDAAcceptanceMode.both => strings.pdaAcceptanceBoth,
          };
        }

        return AlertDialog(
          title: Text(strings.pdaNormalizationReviewTitle),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.pdaNormalizationSourceAcceptance(
                      formatAcceptanceMode(report.sourceMode),
                    ),
                  ),
                  Text(
                    strings.pdaNormalizationTargetAcceptance(
                      formatAcceptanceMode(report.targetMode),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    strings.pdaNormalizationStateCount(
                      source.states.length,
                      report.normalizedPda.states.length,
                    ),
                  ),
                  Text(
                    strings.pdaNormalizationTransitionCount(
                      source.pdaTransitions.length,
                      report.normalizedPda.pdaTransitions.length,
                    ),
                  ),
                  Text(
                    strings.pdaNormalizationNewStackSymbol(
                      report.addedStackSymbols.join(', '),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (report.structuredWarnings.isNotEmpty) ...[
                    ...report.structuredWarnings.map(
                      (warning) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(strings.resolveStructuredMessage(warning)),
                      ),
                    ),
                  ] else
                    Text(strings.pdaNormalizationGrowthWarning),
                  const SizedBox(height: 8),
                  Text(strings.pdaNormalizationCancelHint),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(strings.pdaNormalizationCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(strings.pdaNormalizationApplyAndConvert),
            ),
          ],
        );
      },
    );
    return decision ?? false;
  }

  void _simplifyPDA() {
    final editorState = ref.read(pdaEditorProvider);
    final pda = editorState.pda;
    final strings = appLocalizationsOf(context);

    if (pda == null) {
      _showSnackbar(
        strings.pdaSimplificationMissingPda,
        tone: AppSnackBarTone.error,
      );
      return;
    }

    _performAnalysis(strings.pdaSimplificationAnalysisTitle, (_) async {
      final acceptanceMode = ref.read(pdaSimulationProvider).mode;
      final simplificationResult = PDASimplifier.simplify(
        pda,
        acceptanceMode: acceptanceMode,
      );
      if (!simplificationResult.isSuccess) {
        final detail = simplificationResult.structuredError == null
            ? simplificationResult.error!
            : strings.resolveStructuredMessage(
                simplificationResult.structuredError!,
              );
        final message = strings.pdaSimplificationFailed(detail);
        _showSnackbar(message, tone: AppSnackBarTone.error);
        return message;
      }

      final report = simplificationResult.data!;
      if (!report.changed) return strings.pdaSimplificationNoChange;

      final shouldApply = await _showSimplificationPreview(report);
      if (!shouldApply) return strings.pdaSimplificationCanceled;
      if (!mounted) return strings.pdaSimplificationCanceled;
      if (!identical(ref.read(pdaEditorProvider).pda, pda)) {
        return strings.pdaSimplificationEditorChanged;
      }

      final applyPda = widget.onApplyPda;
      if (applyPda != null) {
        applyPda(report.simplifiedPda);
      } else {
        ref.read(pdaEditorProvider.notifier).setPda(report.simplifiedPda);
      }

      return _formatSimplificationSummary(report, applied: true);
    });
  }

  Future<bool> _showSimplificationPreview(
    PDASimplificationResult report,
  ) async {
    if (!mounted) return false;
    final decision = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final strings = appLocalizationsOf(dialogContext);
        return AlertDialog(
          title: Text(strings.pdaSimplificationReviewTitle),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.pdaSimplificationActiveAcceptance(
                      _formatAcceptanceMode(strings, report.acceptanceMode),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(strings.pdaSimplificationScope),
                  const SizedBox(height: 12),
                  Text(
                    strings.pdaNormalizationStateCount(
                      report.counts.statesBefore,
                      report.counts.statesAfter,
                    ),
                  ),
                  Text(
                    strings.pdaNormalizationTransitionCount(
                      report.counts.transitionsBefore,
                      report.counts.transitionsAfter,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(strings.pdaSimplificationChangesHeading),
                  ..._simplificationChangeLines(strings, report).map(Text.new),
                  const SizedBox(height: 12),
                  ..._simplificationWarningLines(strings, report).map(Text.new),
                  const SizedBox(height: 8),
                  Text(strings.pdaSimplificationCancelHint),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(strings.pdaSimplificationCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(strings.pdaSimplificationApply),
            ),
          ],
        );
      },
    );
    return decision ?? false;
  }

  String _formatSimplificationSummary(
    PDASimplificationResult report, {
    required bool applied,
  }) {
    final strings = appLocalizationsOf(context);
    return [
      if (applied) strings.pdaSimplificationApplied,
      strings.pdaSimplificationActiveAcceptance(
        _formatAcceptanceMode(strings, report.acceptanceMode),
      ),
      strings.pdaNormalizationStateCount(
        report.counts.statesBefore,
        report.counts.statesAfter,
      ),
      strings.pdaNormalizationTransitionCount(
        report.counts.transitionsBefore,
        report.counts.transitionsAfter,
      ),
      ..._simplificationChangeLines(strings, report),
      ..._simplificationWarningLines(strings, report),
    ].join('\n');
  }

  List<String> _simplificationWarningLines(
    AppLocalizations strings,
    PDASimplificationResult report,
  ) {
    if (report.structuredWarnings.isEmpty) {
      return [strings.pdaSimplificationSkippedSemantic];
    }
    return report.structuredWarnings
        .map(strings.resolveStructuredMessage)
        .toList(growable: false);
  }

  List<String> _simplificationChangeLines(
    AppLocalizations strings,
    PDASimplificationResult report,
  ) {
    int count(PDASimplificationChangeReason reason) =>
        report.changes.where((change) => change.reason == reason).length;
    return [
      strings.pdaSimplificationUnreachableChange(
        count(PDASimplificationChangeReason.unreachableControlState),
      ),
      strings.pdaSimplificationMergeChange(
        count(PDASimplificationChangeReason.bisimilarControlStates),
      ),
      strings.pdaSimplificationDuplicateChange(
        count(PDASimplificationChangeReason.duplicateTransition) +
            count(PDASimplificationChangeReason.incidentToUnreachableState),
      ),
    ];
  }

  String _formatAcceptanceMode(
    AppLocalizations strings,
    PDAAcceptanceMode mode,
  ) => switch (mode) {
    PDAAcceptanceMode.finalState => strings.pdaAcceptanceFinalState,
    PDAAcceptanceMode.emptyStack => strings.pdaAcceptanceEmptyStack,
    PDAAcceptanceMode.both => strings.pdaAcceptanceBoth,
  };

  String _localizedPdaToCfgFailure<T>(
    AppLocalizations strings,
    Result<T> result,
  ) {
    final structured = result.structuredError;
    final detail = structured == null
        ? result.error ?? ''
        : strings.resolveStructuredMessage(structured);
    return strings.pdaConversionFailure(detail);
  }

  void _checkDeterminism() {
    final editorState = ref.read(pdaEditorProvider);
    final pda = editorState.pda;

    if (pda == null) {
      _showSnackbar(
        appLocalizationsOf(context).createPdaToAnalyzeDeterminism,
        tone: AppSnackBarTone.error,
      );
      return;
    }

    final strings = appLocalizationsOf(context);
    _performAnalysis(strings.determinismCheckTitle, (setHighlight) async {
      final nondeterministicTransitions =
          editorState.nondeterministicTransitionIds;
      setHighlight(
        SimulationHighlight(transitionIds: nondeterministicTransitions),
      );
      final buffer = StringBuffer();
      buffer.writeln(strings.determinismAnalysis);
      buffer.writeln(strings.totalTransitionsCount(pda.transitions.length));
      buffer.writeln('');

      if (nondeterministicTransitions.isEmpty) {
        buffer.writeln(strings.pdaIsDeterministic);
      } else {
        buffer.writeln(strings.pdaIsNondeterministic);
        buffer.writeln(strings.conflictingTransitions);
        for (final transition in pda.pdaTransitions) {
          if (nondeterministicTransitions.contains(transition.id)) {
            final input =
                transition.isLambdaInput || transition.inputSymbol.isEmpty
                ? kEpsilonSymbol
                : transition.inputSymbol;
            final pop = transition.isLambdaPop || transition.popSymbol.isEmpty
                ? kEpsilonSymbol
                : transition.popSymbol;
            final push =
                transition.isLambdaPush || transition.pushSymbol.isEmpty
                ? kEpsilonSymbol
                : transition.pushSymbol;
            buffer.writeln(
              '  ${transition.fromState.label} -- $input, pop $pop / push $push → ${transition.toState.label}',
            );
          }
        }
      }

      if (editorState.lambdaTransitionIds.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln(
          strings.lambdaTransitionsPresent(
            editorState.lambdaTransitionIds.length,
          ),
        );
      }

      return buffer.toString();
    });
  }

  void _findReachableStates() {
    final editorState = ref.read(pdaEditorProvider);
    final pda = editorState.pda;

    if (pda == null) {
      _showSnackbar(
        appLocalizationsOf(context).createPdaToAnalyzeReachability,
        tone: AppSnackBarTone.error,
      );
      return;
    }

    final strings = appLocalizationsOf(context);
    _performAnalysis(strings.reachableStatesAnalysisTitle, (
      setHighlight,
    ) async {
      final analysisResult = PDASimulator.analyzePDA(pda);
      if (!analysisResult.isSuccess) {
        final message = strings.analysisFailedPrefix(
          analysisResult.error ?? '',
        );
        _showSnackbar(message, tone: AppSnackBarTone.error);
        return message;
      }

      final analysis = analysisResult.data!;
      setHighlight(
        SimulationHighlight(
          stateIds: analysis.reachabilityAnalysis.reachableStates
              .map((state) => state.id)
              .toSet(),
        ),
      );
      final reachable =
          analysis.reachabilityAnalysis.reachableStates
              .map((state) => state.label)
              .toList()
            ..sort();
      final unreachable =
          analysis.reachabilityAnalysis.unreachableStates
              .map((state) => state.label)
              .toList()
            ..sort();

      final buffer = StringBuffer();
      buffer.writeln(
        strings.initialStateWithLabel(pda.initialState?.label ?? '—'),
      );
      buffer.writeln(strings.reachableStatesCount(reachable.length));
      buffer.writeln(reachable.isEmpty ? '  ∅' : '  {${reachable.join(', ')}}');
      buffer.writeln('');
      buffer.writeln(strings.unreachableStatesCount(unreachable.length));
      buffer.writeln(
        unreachable.isEmpty ? '  ∅' : '  {${unreachable.join(', ')}}',
      );

      return buffer.toString();
    });
  }

  void _analyzeLanguage() {
    final editorState = ref.read(pdaEditorProvider);
    final pda = editorState.pda;

    if (pda == null) {
      _showSnackbar(
        appLocalizationsOf(context).createPdaToAnalyzeLanguage,
        tone: AppSnackBarTone.error,
      );
      return;
    }

    final strings = appLocalizationsOf(context);
    _performAnalysis(strings.languageAnalysisTitle, (_) async {
      final acceptanceMode = ref.read(pdaSimulationProvider).mode;
      final analysis = PDALanguageEmptinessAnalyzer.analyze(
        pda,
        acceptanceMode: acceptanceMode,
        isCancelled: () => !mounted,
      );
      if (analysis is PDALanguageEmptinessFailure) {
        final detail = analysis.structuredMessage == null
            ? analysis.message
            : strings.resolveStructuredMessage(analysis.structuredMessage!);
        final message = strings.emptinessProofUnavailable(detail);
        _showSnackbar(message, tone: AppSnackBarTone.error);
        return message;
      }

      final proof = analysis as PDALanguageEmptinessProof;
      if (mounted) {
        setState(() {
          _latestLanguageProof = proof;
          _latestLanguageSourcePda = pda;
        });
      }
      final buffer = StringBuffer();
      buffer.writeln(
        proof.isEmpty
            ? strings.languageIsEmptyProved
            : strings.languageIsNonEmptyProved,
      );
      buffer.writeln(
        strings.acceptanceModeLabel(
          _formatAcceptanceMode(strings, acceptanceMode),
        ),
      );
      buffer.writeln(strings.pdaEmptinessProofLine);
      buffer.writeln(
        strings.productiveNonterminalsCount(
          proof.productiveNonterminals.length,
        ),
      );

      if (!proof.isEmpty) {
        final witness = proof.witnessWord!.isEmpty ? 'ε' : proof.witnessWord!;
        buffer.writeln('');
        buffer.writeln(strings.shortestWitness(witness));
        buffer.writeln(
          strings.terminalSymbolLength(proof.terminalSymbolLength ?? 0),
        );
        buffer.writeln(strings.equalLengthShortlex);
        buffer.writeln('');
        buffer.writeln(strings.leftmostCfgDerivation);
        buffer.writeln('  ${proof.grammar.startSymbol}');
        const displayedStepLimit = 50;
        for (final step in proof.derivation.take(displayedStepLimit)) {
          buffer.writeln('  ⇒ ${_formatSententialForm(step.after)}');
        }
        if (proof.derivation.length > displayedStepLimit) {
          buffer.writeln(
            strings.moreDerivationSteps(
              proof.derivation.length - displayedStepLimit,
            ),
          );
        }
      }

      return buffer.toString();
    });
  }

  void _openWitnessTrace() {
    final proof = _latestLanguageProof;
    final pda = _latestLanguageSourcePda;
    final trace = proof?.witnessTrace;
    final input = proof?.witnessWord;
    if (proof == null || pda == null || trace == null || input == null) return;

    ref
        .read(pdaSimulationProvider.notifier)
        .loadTrace(
          pda: pda,
          input: input,
          mode: proof.acceptanceMode,
          result: trace,
        );
    _showSnackbar(appLocalizationsOf(context).shortestWitnessOpened);
  }

  String _formatSententialForm(List<String> symbols) =>
      symbols.isEmpty ? 'ε' : symbols.join(' ');

  void _analyzeStackOperations() {
    final editorState = ref.read(pdaEditorProvider);
    final pda = editorState.pda;

    if (pda == null) {
      _showSnackbar(
        appLocalizationsOf(context).createPdaToInspectStack,
        tone: AppSnackBarTone.error,
      );
      return;
    }

    final strings = appLocalizationsOf(context);
    _performAnalysis(strings.stackOperationsAnalysisTitle, (_) async {
      final analysisResult = PDASimulator.analyzePDA(pda);
      if (!analysisResult.isSuccess) {
        final message = strings.analysisFailedPrefix(
          analysisResult.error ?? '',
        );
        _showSnackbar(message, tone: AppSnackBarTone.error);
        return message;
      }

      final analysis = analysisResult.data!;
      final pushOps = analysis.stackAnalysis.pushOperations.toList()..sort();
      final popOps = analysis.stackAnalysis.popOperations.toList()..sort();
      final stackSymbols = analysis.stackAnalysis.stackSymbols.toList()..sort();

      final buffer = StringBuffer();
      buffer.writeln(
        strings.initialStackSymbolWithValue(pda.initialStackSymbol),
      );
      buffer.writeln(strings.pushOperationsCount(pushOps.length));
      buffer.writeln(
        pushOps.isEmpty ? strings.noneValue : '  {${pushOps.join(', ')}}',
      );
      buffer.writeln(strings.popOperationsCount(popOps.length));
      buffer.writeln(
        popOps.isEmpty ? strings.noneValue : '  {${popOps.join(', ')}}',
      );
      buffer.writeln(strings.stackSymbolsTouched(stackSymbols.length));
      buffer.writeln(
        stackSymbols.isEmpty
            ? strings.noneValue
            : '  {${stackSymbols.join(', ')}}',
      );
      buffer.writeln('');
      buffer.writeln(
        strings.totalTransitionsCount(
          analysis.transitionAnalysis.totalTransitions,
        ),
      );
      buffer.writeln(
        strings.pdaTransitionsCount(
          analysis.transitionAnalysis.pdaTransitions,
          analysis.transitionAnalysis.fsaTransitions,
        ),
      );

      return buffer.toString();
    });
  }

  void _performAnalysis(
    String algorithmName,
    Future<String> Function(ValueChanged<SimulationHighlight> setHighlight)
    analysisFunction, {
    bool resetConvertedGrammar = true,
  }) {
    final highlights = _analysisHighlights;
    if (highlights != null) {
      highlights.clearFor(highlights.target);
    }
    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
      _latestLanguageProof = null;
      _latestLanguageSourcePda = null;
      if (resetConvertedGrammar) {
        _latestConvertedGrammar = null;
      }
    });

    Future.microtask(() async {
      var nextHighlight = SimulationHighlight.empty;
      try {
        final output = await analysisFunction((highlight) {
          nextHighlight = highlight;
        });
        if (!mounted) {
          return;
        }
        if (highlights != null) {
          highlights.sendFor(highlights.target, nextHighlight);
        }
        setState(() {
          _isAnalyzing = false;
          _analysisResult = '=== $algorithmName ===\n\n$output';
        });
      } catch (error) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isAnalyzing = false;
          _analysisResult =
              '=== $algorithmName ===\n\n${appLocalizationsOf(context).errorRunningAnalysis('$error')}';
        });
      }
    });
  }

  Widget _buildGrammarSummary(BuildContext context, Grammar grammar) {
    final l10n = appLocalizationsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final terminals = grammar.terminals.toList()..sort();
    final nonterminals = grammar.nonterminals.toList()..sort();
    final productions = grammar.productions.toList()
      ..sort((a, b) {
        final orderComparison = a.order.compareTo(b.order);
        if (orderComparison != 0) {
          return orderComparison;
        }
        return a.id.compareTo(b.id);
      });

    String formatSymbols(List<String> symbols) {
      if (symbols.isEmpty) {
        return 'ε';
      }
      return symbols.join(' ');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.generatedGrammar,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.startSymbolValue(grammar.startSymbol),
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            Text(
              l10n.nonterminalsValue('{${nonterminals.join(', ')}}'),
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            Text(
              l10n.terminalsValue('{${terminals.join(', ')}}'),
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          l10n.productionsCountLabel(productions.length),
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...productions.map(
          (production) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '• ${formatSymbols(production.leftSide)} → '
              '${production.isLambda ? 'ε' : formatSymbols(production.rightSide)}',
              style: textTheme.bodyMedium?.copyWith(
                fontFamilyFallback: kMonospaceFontFamilyFallback,
                color: colorScheme.onSurface.withValues(alpha: 0.9),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showSnackbar(
    String message, {
    AppSnackBarTone tone = AppSnackBarTone.success,
  }) {
    showAppSnackBar(
      context,
      message: appLocalizationsOf(context).localizeWorkflowText(message),
      tone: tone,
    );
  }

  Widget _buildExamplesSection(BuildContext context) {
    return AlgorithmExamplesSection<PDA>(
      examplesFuture: _pdaExamplesFuture,
      loadingExampleName: _loadingExampleName,
      onExampleSelected: (name) => _loadSelectedExample(name),
      failureMessage: 'Failed to load PDA examples.',
      emptyMessage: 'No PDA examples available.',
      exampleBuilder: (context, example, isLoading, onPressed) =>
          AssetExampleContentButton.maybeBuild(
            context: context,
            example: example,
            isLoading: isLoading,
            onPressed: onPressed,
          ),
    );
  }

  Future<void> _loadSelectedExample(String exampleName) async {
    setState(() {
      _loadingExampleName = exampleName;
    });

    try {
      final result = await _examplesDataSource.loadTypedPdaExample(exampleName);
      if (!mounted) return;

      if (result.isFailure) {
        _showSnackbar(
          'Failed to load example: ${result.error}',
          tone: AppSnackBarTone.error,
        );
        return;
      }

      final pda = result.data!.payload;
      ref.read(pdaEditorProvider.notifier).setPda(pda);
      _showSnackbar('Example loaded: ${pda.name}');
    } catch (error) {
      if (!mounted) return;
      _showSnackbar(
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
}
