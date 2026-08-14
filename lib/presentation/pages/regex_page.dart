//
//  regex_page.dart
//  Turing Lab
//
//  Centraliza as ferramentas de expressões regulares permitindo validar,
//  simular e converter padrões em autômatos, reutilizando algoritmos do núcleo
//  para checar equivalência, aceitação de cadeias e sincronizar resultados com
//  o provedor de autômatos ativo.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/fsa.dart';
import '../../core/models/regex_analysis.dart';
import '../../core/models/regex_simplification_step.dart';
import '../../l10n/app_localizations.dart';
import '../providers/automaton_algorithm_provider.dart';
import '../providers/automaton_state_provider.dart';
import '../providers/help_provider.dart';
import '../providers/home_navigation_provider.dart';
import '../providers/regex_editor_provider.dart';
import '../widgets/algorithm_panel.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/context_aware_help_panel.dart';
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

  @override
  void initState() {
    super.initState();
    _syncInputControllers(ref.read(regexEditorProvider));
    _regexEditorSub = ref.listenManual<RegexEditorState>(
      regexEditorProvider,
      (_, next) => _syncInputControllers(next),
    );
  }

  @override
  void dispose() {
    _regexEditorSub?.close();
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
    final helpNotifier = ref.read(helpProvider.notifier);
    final regexState = ref.read(regexEditorProvider);

    // Determine the most relevant help content based on current regex state
    String helpContextId;
    if (regexState.currentRegex.isNotEmpty && regexState.isValid) {
      // Show conversion help if user has a valid regex
      helpContextId = 'algo_regex_to_nfa';
    } else {
      // Default: show general regex concepts
      helpContextId = 'concept_regex';
    }

    final helpContent = helpNotifier.getHelpByContext(helpContextId);
    if (helpContent != null) {
      ContextAwareHelpPanel.show(context, helpContent: helpContent);
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

    if (isMobile) {
      return _buildMobileLayout(algorithmState);
    } else if (isTablet) {
      return _buildTabletLayout(algorithmState);
    } else {
      return _buildDesktopLayout(algorithmState);
    }
  }
}
