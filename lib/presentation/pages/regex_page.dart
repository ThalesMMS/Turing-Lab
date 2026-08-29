//
//  regex_page.dart
//  Turing Lab
//
//  Centralizes regular-expression tools for validating, simulating, and
//  converting patterns into automata, reusing core algorithms to check
//  equivalence, string acceptance, and to sync results with the active
//  automaton provider.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/batch_execution/batch_execution.dart';
import '../../core/constants/help_topic_ids.dart';
import '../../core/formal_systems/formal_systems.dart';
import '../../core/annotations/annotations.dart';
import '../../core/models/asset_example.dart';
import '../../core/models/fsa.dart';
import '../../core/models/regex_analysis.dart';
import '../../core/models/regex_document.dart';
import '../../core/models/regex_preset.dart';
import '../../core/manual_conversions/regex_to_fa_session_factory.dart';
import '../../core/manual_conversions/manual_conversion_session.dart';
import '../../core/models/regex_simplification_step.dart';
import '../../core/repositories/examples_repository.dart';
import '../../core/result.dart';
import '../../injection/data_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_structured_messages.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_workflows.dart';
import '../localization/locale_value_formatter.dart';
import '../providers/automaton_algorithm_provider.dart';
import '../providers/automaton_state_provider.dart';
import '../providers/home_navigation_provider.dart';
import '../providers/interoperable_document_sidecar_provider.dart';
import '../providers/document_annotations_provider.dart';
import '../providers/regex_editor_provider.dart';
import '../providers/workspace_quick_actions_provider.dart';
import '../widgets/algorithm_panel_scaffold.dart';
import '../widgets/asset_example_content_button.dart';
import '../widgets/batch_execution/batch_execution_panel.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/automaton_workspace_scaffold.dart';
import '../widgets/common/help_navigation.dart';
import '../widgets/conversion_replacement_dialog.dart';
import '../widgets/error_banner.dart';
import '../widgets/document_interoperability_binding.dart';
import '../widgets/document_interoperability_preview.dart';
import '../widgets/file_operations_panel.dart';
import '../widgets/interoperability_presentation_labels.dart';
import '../widgets/document_annotations.dart';
import '../widgets/switch_setting_tile.dart';
import '../widgets/manual_conversion_document_preview.dart';
import '../widgets/manual_conversion_workspace.dart';
import '../widgets/regex_to_fa_fragment_editor.dart';
import '../widgets/workspace_dock.dart';
import '../../core/constants/monospace_typography.dart';

part 'regex_page_layout.dart';
part 'regex_page_simplification.dart';
part 'regex_page_complexity.dart';
part 'regex_page_complexity_colors.dart';
part 'regex_page_samples.dart';

/// Regular Expression page for testing and converting regular expressions
class RegexPage extends ConsumerStatefulWidget {
  const RegexPage({super.key});

  @override
  ConsumerState<RegexPage> createState() => _RegexPageState();
}

class _RegexPageState extends ConsumerState<RegexPage> {
  final TextEditingController _regexController = TextEditingController();
  final TextEditingController _testStringController = TextEditingController();
  final TextEditingController _alphabetController = TextEditingController();
  final TextEditingController _comparisonRegexController =
      TextEditingController();
  ProviderSubscription<RegexEditorState>? _regexEditorSub;
  final ValueNotifier<String?> _loadingExampleName = ValueNotifier(null);
  late final ExamplesRepository _examplesDataSource;
  late final Future<ListResult<AssetExample<RegexPreset>>> _regexExamplesFuture;

  @override
  void initState() {
    super.initState();
    _examplesDataSource = ref.read(examplesRepositoryProvider);
    _regexExamplesFuture = _examplesDataSource.loadAllTypedRegexExamples();
    _syncInputControllers(ref.read(regexEditorProvider));
    _regexEditorSub = ref.listenManual<RegexEditorState>(
      regexEditorProvider,
      (_, next) => _syncInputControllers(next),
    );
  }

  @override
  void dispose() {
    _regexEditorSub?.close();
    _loadingExampleName.dispose();
    _regexController.dispose();
    _testStringController.dispose();
    _alphabetController.dispose();
    _comparisonRegexController.dispose();
    super.dispose();
  }

  void _syncInputControllers(RegexEditorState state) {
    _syncControllerText(_regexController, state.currentRegex);
    _syncControllerText(_testStringController, state.testString);
    _syncControllerText(_alphabetController, state.alphabet);
  }

  void _syncControllerText(TextEditingController controller, String value) {
    if (controller.text == value) {
      return;
    }

    controller.value = controller.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
      composing: TextRange.empty,
    );
  }

  void _showFeedback(
    String message, {
    AppSnackBarTone tone = AppSnackBarTone.info,
  }) {
    showAppSnackBar(context, message: message, tone: tone);
  }

  void _setSimplifyOutput(bool value) {
    ref.read(regexEditorProvider.notifier).setSimplifyOutput(value);
  }

  void _setAlphabet(String value) {
    ref.read(regexEditorProvider.notifier).setAlphabet(value);
  }

  void _validateRegex() {
    ref.read(regexEditorProvider.notifier).validateRegex(_regexController.text);
  }

  Future<void> _testStringMatch() async {
    await ref
        .read(regexEditorProvider.notifier)
        .testStringMatch(_testStringController.text);
  }

  Future<void> _convertToNFA() async {
    final l10n = AppLocalizations.of(context);
    final regexState = ref.read(regexEditorProvider);
    if (!regexState.canRunRegexOperation) {
      _showFeedback(l10n.enterValidRegexFirst, tone: AppSnackBarTone.error);
      return;
    }

    final shouldReplace = await confirmConversionDestinationReplacement(
      context: context,
      ref: ref,
      destination: ConversionDestination.automaton,
    );
    if (!mounted || !shouldReplace) return;

    final result = ref.read(regexEditorProvider.notifier).convertToNfa();

    if (result.isFailure || result.data == null) {
      _showFeedback(
        result.error ?? l10n.failedConvertRegexToNfa,
        tone: AppSnackBarTone.error,
      );
      return;
    }

    _pushAutomatonToProvider(result.data!);

    ref.read(homeNavigationProvider.notifier).goToFsa();

    _showFeedback(l10n.convertedRegexToNfa, tone: AppSnackBarTone.success);
  }

  Future<void> _openManualRegexToFaConstruction() async {
    final regexState = ref.read(regexEditorProvider);
    if (!regexState.canRunRegexOperation) {
      _showFeedback(
        AppLocalizations.of(context).enterValidRegexFirst,
        tone: AppSnackBarTone.error,
      );
      return;
    }
    final source = ref.read(regexEditorProvider.notifier).buildDocument();
    final manualSession = RegexToFaSessionFactory.create(
      source: source,
      sourceRevision: regexState.documentGeneration,
    );

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Consumer(
        builder: (context, dialogRef, _) {
          final liveState = dialogRef.watch(regexEditorProvider);
          final liveSource = dialogRef
              .read(regexEditorProvider.notifier)
              .buildDocument();
          final checkedSession = manualSession.checkSource(
            documentId: liveSource.id,
            revision: liveState.documentGeneration,
          );
          return Dialog.fullscreen(
            child: ManualConversionWorkspace(
              title: appLocalizationsOf(
                context,
              ).localizeWorkflowText('Manual Regex to FA construction'),
              workspaceKey:
                  'regex-to-fa.${source.id}.${regexState.documentGeneration}',
              initialSession: checkedSession,
              currentSourceDocumentId: liveSource.id,
              currentSourceRevision: liveState.documentGeneration,
              sourcePreview: ManualConversionDocumentPreview.regex(
                liveSource.source,
              ),
              resultPreviewBuilder: (artifact) {
                final encodedFsa = artifact['fsa'];
                if (encodedFsa is Map) {
                  return ManualConversionDocumentPreview.fsa(
                    FSA.fromJson(Map<String, dynamic>.from(encodedFsa)),
                  );
                }
                return ManualConversionDocumentPreview.artifact(artifact);
              },
              requirementEditorBuilder: (context, requirement, onSubmit) {
                return RegexToFaFragmentEditor(
                  requirement: requirement,
                  onSubmit: onSubmit,
                );
              },
              onApplyPayload: (session, payload) {
                final encodedFragment = payload['fragment'];
                if (encodedFragment is! Map) {
                  return ManualConversionCommandResult(
                    session: session,
                    diagnostics: const [
                      ManualConversionDiagnostic(
                        code: ManualConversionDiagnosticCode.invalidPayload,
                        message:
                            'Enter the learner fragment as an FSA document.',
                      ),
                    ],
                  );
                }
                try {
                  return RegexToFaSessionFactory.applyLearnerFragment(
                    session: session,
                    fragment: FSA.fromJson(
                      Map<String, dynamic>.from(encodedFragment),
                    ),
                  );
                } on Object {
                  return ManualConversionCommandResult(
                    session: session,
                    diagnostics: const [
                      ManualConversionDiagnostic(
                        code: ManualConversionDiagnosticCode.malformedPayload,
                        message: 'The learner FSA document is malformed.',
                      ),
                    ],
                  );
                }
              },
              onRestartFromSource: (invalidated) {
                final fresh = RegexToFaSessionFactory.create(
                  source: liveSource,
                  sourceRevision: liveState.documentGeneration,
                );
                return invalidated.restartFromNewSource(freshSession: fresh);
              },
              onBranchFromSource: (invalidated, branchId) {
                final fresh = RegexToFaSessionFactory.create(
                  source: liveSource,
                  sourceRevision: liveState.documentGeneration,
                  sessionId: branchId,
                );
                return invalidated.branchFromNewSource(
                  branchId: branchId,
                  freshSession: fresh,
                );
              },
              onClose: () => Navigator.of(dialogContext).pop(),
              onOpenResult: (artifact) async {
                final encodedFsa = artifact['fsa'];
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
                final result = FSA.fromJson(
                  Map<String, dynamic>.from(encodedFsa),
                );
                _pushAutomatonToProvider(result);
                ref.read(homeNavigationProvider.notifier).goToFsa();
                Navigator.of(dialogContext).pop();
                _showFeedback(
                  appLocalizationsOf(context).localizeWorkflowText(
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

  Future<void> _convertToDFA() async {
    final l10n = AppLocalizations.of(context);
    final regexState = ref.read(regexEditorProvider);
    if (!regexState.canRunRegexOperation) {
      _showFeedback(l10n.enterValidRegexFirst, tone: AppSnackBarTone.error);
      return;
    }

    final shouldReplace = await confirmConversionDestinationReplacement(
      context: context,
      ref: ref,
      destination: ConversionDestination.automaton,
    );
    if (!mounted || !shouldReplace) return;

    final result = ref.read(regexEditorProvider.notifier).convertToDfa();

    if (result.isFailure || result.data == null) {
      _showFeedback(
        result.error ?? l10n.failedConvertNfaToDfa,
        tone: AppSnackBarTone.error,
      );
      return;
    }

    _showFeedback(l10n.convertedRegexToDfa, tone: AppSnackBarTone.success);

    _pushAutomatonToProvider(result.data!);

    // Keep navigation consistent with the rest of the app: switch the HomePage
    // workspace instead of pushing a standalone FSAPage route.
    ref.read(homeNavigationProvider.notifier).goToFsa();
  }

  void _pushAutomatonToProvider(FSA automaton) {
    ref.read(automatonStateProvider.notifier).replaceAutomaton(automaton);
  }

  void _compareRegexEquivalence() {
    ref
        .read(regexEditorProvider.notifier)
        .compareRegexEquivalence(
          _regexController.text,
          _comparisonRegexController.text,
        );
  }

  void _showContextualHelp() {
    final regexState = ref.read(regexEditorProvider);

    final topicId = regexState.isValid
        ? HelpTopicIds.regexEditorConversions
        : HelpTopicIds.regexEditorInput;
    openHelp(context, topicId: topicId);
  }

  Future<void> _openSimulationSheet() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Consumer(
              builder: (context, sheetRef, _) {
                sheetRef.watch(regexEditorProvider);
                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [_buildSimulationSection()],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _openAlgorithmSheet() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Consumer(
              builder: (context, sheetRef, _) {
                final algorithmState = sheetRef.watch(
                  automatonAlgorithmProvider,
                );
                sheetRef.watch(regexEditorProvider);
                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [_buildRegexAlgorithmsPanel(algorithmState)],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _loadSelectedRegexExample(String exampleName) async {
    _loadingExampleName.value = exampleName;

    try {
      final result = await _examplesDataSource.loadTypedRegexExample(
        exampleName,
      );
      if (!mounted) return;

      if (result.isFailure) {
        _showFeedback(
          AppLocalizations.of(context).failedToLoadExample('${result.error}'),
          tone: AppSnackBarTone.error,
        );
        return;
      }

      final preset = result.data!.payload;
      final notifier = ref.read(regexEditorProvider.notifier);
      notifier.replaceDocument(
        RegexDocument(
          id: preset.id,
          name: preset.name,
          source: preset.expression,
          alphabet: preset.alphabet.runes.map(String.fromCharCode),
        ),
      );
      _showFeedback(
        AppLocalizations.of(context).exampleLoaded(preset.name),
        tone: AppSnackBarTone.success,
      );
    } catch (error) {
      if (!mounted) return;
      _showFeedback(
        AppLocalizations.of(context).failedToLoadExample('$error'),
        tone: AppSnackBarTone.error,
      );
    } finally {
      if (mounted) {
        _loadingExampleName.value = null;
      }
    }
  }

  void _runSimplificationWithSteps() {
    final l10n = AppLocalizations.of(context);
    if (!ref.read(regexEditorProvider).canRunRegexOperation) {
      _showFeedback(l10n.enterValidRegexFirst, tone: AppSnackBarTone.error);
      return;
    }

    final result = ref
        .read(regexEditorProvider.notifier)
        .runSimplificationWithSteps();

    if (result.isFailure) {
      _showFeedback(
        result.structuredError == null
            ? result.error ?? l10n.failedSimplifyRegex
            : l10n.resolveStructuredMessage(result.structuredError!),
        tone: AppSnackBarTone.error,
      );
    }
  }

  void _runComplexityAnalysis() {
    final l10n = AppLocalizations.of(context);
    if (!ref.read(regexEditorProvider).canRunRegexOperation) {
      _showFeedback(l10n.enterValidRegexFirst, tone: AppSnackBarTone.error);
      return;
    }

    final result = ref
        .read(regexEditorProvider.notifier)
        .runComplexityAnalysis();

    if (result.isFailure) {
      _showFeedback(
        result.error ?? l10n.failedAnalyzeRegex,
        tone: AppSnackBarTone.error,
      );
    }
  }

  void _runSampleGeneration({int maxSamples = 10}) {
    final l10n = AppLocalizations.of(context);
    if (!ref.read(regexEditorProvider).canRunRegexOperation) {
      _showFeedback(l10n.enterValidRegexFirst, tone: AppSnackBarTone.error);
      return;
    }

    final result = ref
        .read(regexEditorProvider.notifier)
        .runSampleGeneration(maxSamples: maxSamples);

    if (result.isFailure) {
      _showFeedback(
        result.error ?? l10n.failedGenerateSampleStrings,
        tone: AppSnackBarTone.error,
      );
    }
  }

  DocumentInteroperabilityBinding _regexInteroperabilityBinding(
    RegexEditorState editor,
  ) {
    final registry = ref.read(documentInteroperabilityRegistryProvider);
    final descriptor = registry.formalSystems.descriptorFor(
      DefaultFormalSystemIds.regex,
    )!;
    final document = ref.read(regexEditorProvider.notifier).buildDocument();
    final identity = (editor.documentId, editor.documentGeneration);
    final sidecar = ref.watch(
      interoperableDocumentSidecarProvider,
    )[DefaultFormalSystemIds.regex];
    final currentDocument = resolveInteroperableDocument(
      sidecar: sidecar,
      currentDocument: document,
      documentIdentity: identity,
      systemKey: DefaultFormalSystemIds.regex,
      schema: descriptor.schema,
      annotations: annotationsForDocument(
        ref.watch(documentAnnotationsProvider),
        DefaultFormalSystemIds.regex,
        editor.documentId,
      ),
    );
    return DocumentInteroperabilityBinding(
      registry: registry,
      systemKey: DefaultFormalSystemIds.regex,
      currentDocument: currentDocument,
      captureCheckpoint: () => _RegexImportCheckpoint(
        editor: ref.read(regexEditorProvider),
        sidecar: ref.read(
          interoperableDocumentSidecarProvider,
        )[DefaultFormalSystemIds.regex],
        annotations: ref.read(
          documentAnnotationsProvider,
        )[DefaultFormalSystemIds.regex],
      ),
      restoreCheckpoint: (checkpoint) {
        final snapshot = checkpoint! as _RegexImportCheckpoint;
        ref
            .read(regexEditorProvider.notifier)
            .restoreDocumentCheckpoint(snapshot.editor);
        ref
            .read(interoperableDocumentSidecarProvider.notifier)
            .restore(DefaultFormalSystemIds.regex, snapshot.sidecar);
        ref
            .read(documentAnnotationsProvider.notifier)
            .restore(DefaultFormalSystemIds.regex, snapshot.annotations);
      },
      systemLabel: (context, _) =>
          AppLocalizations.of(context).fileSectionRegex,
      formatLabel: defaultDocumentFormatLabel,
      previewFacts: (context, interoperable) {
        final value = interoperable.document as RegexDocument;
        final l10n = AppLocalizations.of(context);
        return [
          DocumentInteroperabilityFact(
            label: l10n.regexDocumentDialect,
            value: l10n.regexDocumentDialectTuringLab,
          ),
          DocumentInteroperabilityFact(
            label: l10n.regexDocumentTokenization,
            value: l10n.regexDocumentTokenizationUnicodeScalar,
          ),
          DocumentInteroperabilityFact(
            label: l10n.regexAlphabetLabel,
            value: LocaleValueFormatter.of(
              context,
            ).integer(value.alphabet.length),
          ),
        ];
      },
      replace: (interoperable) async {
        final loaded = interoperable.document;
        if (loaded is! RegexDocument) {
          throw StateError(
            'The Regex workspace received a non-Regex document.',
          );
        }
        ref.read(regexEditorProvider.notifier).replaceDocument(loaded);
        final next = ref.read(regexEditorProvider);
        ref
            .read(interoperableDocumentSidecarProvider.notifier)
            .store(
              interoperable,
              documentIdentity: (next.documentId, next.documentGeneration),
            );
        ref
            .read(documentAnnotationsProvider.notifier)
            .restore(
              DefaultFormalSystemIds.regex,
              annotationsFromImportedDocument(
                interoperable,
                documentId: next.documentId,
                documentRevision: '${next.documentGeneration}',
              ),
            );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch algorithm provider to get FA→Regex conversion results
    final algorithmState = ref.watch(automatonAlgorithmProvider);

    publishWorkspaceQuickActionsForKey(
      ref,
      DefaultFormalSystemIds.regex,
      WorkspaceQuickActions(
        onHelp: _showContextualHelp,
        onSimulate: _openSimulationSheet,
        onAlgorithms: _openAlgorithmSheet,
        algorithmsTooltip: appLocalizationsOf(
          context,
        ).workspaceAlgorithmsAndExamplesTooltip,
      ),
    );

    // Reads the incoming constraints, not the window, so an embedded pane
    // picks the same band a same-sized window would.
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width < AutomatonWorkspaceScaffold.mobileBreakpoint) {
          return _buildMobileLayout();
        }
        return _buildWideLayout(
          algorithmState,
          panelWidth: width < AutomatonWorkspaceScaffold.tabletBreakpoint
              ? AutomatonWorkspaceScaffold.tabletPanelWidth
              : AutomatonWorkspaceScaffold.desktopPanelWidth,
        );
      },
    );
  }
}

final class _RegexImportCheckpoint {
  const _RegexImportCheckpoint({
    required this.editor,
    required this.sidecar,
    required this.annotations,
  });

  final RegexEditorState editor;
  final InteroperableDocumentSidecarEntry? sidecar;
  final DocumentAnnotationCollection? annotations;
}
