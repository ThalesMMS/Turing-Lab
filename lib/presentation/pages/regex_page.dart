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
import '../../core/constants/help_topic_ids.dart';
import '../../core/models/asset_example.dart';
import '../../core/models/fsa.dart';
import '../../core/models/regex_analysis.dart';
import '../../core/models/regex_preset.dart';
import '../../core/models/regex_simplification_step.dart';
import '../../core/repositories/examples_repository.dart';
import '../../core/result.dart';
import '../../injection/data_providers.dart';
import '../../l10n/app_localizations.dart';
import '../providers/automaton_algorithm_provider.dart';
import '../providers/automaton_state_provider.dart';
import '../providers/home_navigation_provider.dart';
import '../providers/regex_editor_provider.dart';
import '../providers/workspace_quick_actions_provider.dart';
import '../widgets/algorithm_panel_scaffold.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/common/help_navigation.dart';
import '../widgets/error_banner.dart';
import '../widgets/simulation_panel.dart';
import '../widgets/switch_setting_tile.dart';
import '../widgets/tablet_layout_container.dart';

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

  void _showFeedback(String message,
      {AppSnackBarTone tone = AppSnackBarTone.info}) {
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

  void _convertToNFA() {
    final l10n = AppLocalizations.of(context);
    final regexState = ref.read(regexEditorProvider);
    if (!regexState.canRunRegexOperation) {
      _showFeedback(l10n.enterValidRegexFirst, tone: AppSnackBarTone.error);
      return;
    }

    final result = ref.read(regexEditorProvider.notifier).convertToNfa();

    if (result.isFailure || result.data == null) {
      _showFeedback(
        result.error ?? l10n.failedConvertRegexToNfa,
        tone: AppSnackBarTone.error,
      );
      return;
    }

    _pushAutomatonToProvider(result.data!);

    _showFeedback(l10n.convertedRegexToNfa, tone: AppSnackBarTone.success);
  }

  void _convertToDFA() {
    final l10n = AppLocalizations.of(context);
    final regexState = ref.read(regexEditorProvider);
    if (!regexState.canRunRegexOperation) {
      _showFeedback(l10n.enterValidRegexFirst, tone: AppSnackBarTone.error);
      return;
    }

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
    ref.read(automatonStateProvider.notifier).updateAutomaton(automaton);
  }

  void _compareRegexEquivalence() {
    ref.read(regexEditorProvider.notifier).compareRegexEquivalence(
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
                final algorithmState =
                    sheetRef.watch(automatonAlgorithmProvider);
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
      final result =
          await _examplesDataSource.loadTypedRegexExample(exampleName);
      if (!mounted) return;

      if (result.isFailure) {
        _showFeedback(
          'Failed to load example: ${result.error}',
          tone: AppSnackBarTone.error,
        );
        return;
      }

      final preset = result.data!.payload;
      final notifier = ref.read(regexEditorProvider.notifier);
      notifier.setAlphabet(preset.alphabet);
      notifier.validateRegex(preset.expression);
      _showFeedback(
        'Example loaded: ${preset.name}',
        tone: AppSnackBarTone.success,
      );
    } catch (error) {
      if (!mounted) return;
      _showFeedback(
        'Failed to load example: $error',
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

    final result =
        ref.read(regexEditorProvider.notifier).runSimplificationWithSteps();

    if (result.isFailure) {
      _showFeedback(
        result.error ?? l10n.failedSimplifyRegex,
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

    final result =
        ref.read(regexEditorProvider.notifier).runComplexityAnalysis();

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

  @override
  Widget build(BuildContext context) {
    // Watch algorithm provider to get FA→Regex conversion results
    final algorithmState = ref.watch(automatonAlgorithmProvider);

    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 768;
    final isTablet = screenSize.width >= 768 && screenSize.width < 1400;
    publishWorkspaceQuickActions(
      ref,
      WorkspaceTab.regex,
      WorkspaceQuickActions(
        onHelp: _showContextualHelp,
        onAlgorithms: _openAlgorithmSheet,
      ),
    );

    if (isMobile) {
      return _buildMobileLayout();
    } else if (isTablet) {
      return _buildTabletLayout(algorithmState);
    } else {
      return _buildDesktopLayout(algorithmState);
    }
  }
}
