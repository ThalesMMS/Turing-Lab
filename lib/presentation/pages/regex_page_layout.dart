part of 'regex_page.dart';

extension _RegexPageLayoutSections on _RegexPageState {
  Widget _buildMobileLayout() {
    final l10n = AppLocalizations.of(context);
    return FocusTraversalGroup(
      policy: ReadingOrderTraversalPolicy(),
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: _buildInputArea(),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'regex_mobile_context_help_fab',
          onPressed: _showContextualHelp,
          tooltip: l10n.contextAwareHelp,
          child: const Icon(Icons.help_outline),
        ),
      ),
    );
  }

  /// Wide viewports give the editor the whole pane; the algorithms and
  /// simulation panels stay collapsed behind the dock rail until asked for.
  Widget _buildWideLayout(
    AlgorithmOperationState algorithmState, {
    required double panelWidth,
  }) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return FocusTraversalGroup(
      policy: ReadingOrderTraversalPolicy(),
      child: Scaffold(
        body: WorkspaceDock(
          initialPanelWidth: panelWidth,
          content: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            // The editor is a form, not a canvas: cap its measure so the
            // fields stay readable when the pane is very wide.
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: _buildInputArea(),
                ),
              ),
            ),
          ),
          panels: [
            WorkspaceDockPanel(
              id: AutomatonWorkspaceScaffold.simulationPanelId,
              label: l10n.simulation,
              icon: Icons.play_arrow,
              child: SimulationPanel(
                onSimulate: (input) {
                  _testStringController.text = input;
                  return _testStringMatch();
                },
              ),
            ),
            WorkspaceDockPanel(
              id: AutomatonWorkspaceScaffold.algorithmPanelId,
              label: l10n.algorithms,
              icon: Icons.auto_awesome,
              child: _buildRegexAlgorithmsPanel(algorithmState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    final l10n = AppLocalizations.of(context);
    final regexState = ref.watch(regexEditorProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.regularExpressionTitle,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Regex input
        Text(
          l10n.regularExpressionLabel,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextField(
          key: const ValueKey('regex_input_field'),
          controller: _regexController,
          decoration: InputDecoration(
            hintText: l10n.regularExpressionHint,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              onPressed: _validateRegex,
              icon: const Icon(Icons.check),
              tooltip: l10n.validateRegex,
            ),
          ),
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: TextInputType.visiblePassword,
          onChanged: (value) => _validateRegex(),
        ),

        // Validation status
        const SizedBox(height: 8),
        if (regexState.currentRegex.isEmpty)
          ErrorBanner(
            message: l10n.enterRegexToValidate,
            severity: ErrorSeverity.info,
            showRetryButton: false,
            showDismissButton: false,
          )
        else
          ErrorBanner(
            message: regexState.isValid
                ? l10n.validRegex
                : (regexState.errorMessage.isNotEmpty
                    ? regexState.errorMessage
                    : l10n.invalidRegex),
            severity: regexState.isValid
                ? ErrorSeverity.success
                : ErrorSeverity.error,
            showRetryButton: false,
            showDismissButton: false,
          ),

        const SizedBox(height: 16),
        TextField(
          key: const ValueKey('regex_alphabet_field'),
          controller: _alphabetController,
          decoration: InputDecoration(
            labelText: l10n.regexAlphabetLabel,
            helperText: l10n.regexAlphabetHelper,
            errorText: regexState.alphabet.isEmpty
                ? l10n.regexAlphabetEmptyError
                : null,
            border: const OutlineInputBorder(),
          ),
          autocorrect: false,
          enableSuggestions: false,
          onChanged: _setAlphabet,
        ),

        const SizedBox(height: 24),

        // Test string input
        Text(l10n.testStringLabel,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          key: const ValueKey('regex_test_input_field'),
          controller: _testStringController,
          decoration: InputDecoration(
            hintText: l10n.testStringHint,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              onPressed: _testStringMatch,
              icon: const Icon(Icons.play_arrow),
              tooltip: l10n.testStringTooltip,
            ),
          ),
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: TextInputType.visiblePassword,
          onChanged: (value) => _testStringMatch(),
        ),

        // Match result
        const SizedBox(height: 8),
        if (regexState.hasTested)
          ErrorBanner(
            message: regexState.matches ? l10n.matches : l10n.doesNotMatch,
            severity: regexState.matches
                ? ErrorSeverity.success
                : ErrorSeverity.warning,
            showRetryButton: false,
            showDismissButton: false,
          ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildRegexAlgorithmsPanel(AlgorithmOperationState algorithmState) {
    final l10n = AppLocalizations.of(context);
    final regexState = ref.watch(regexEditorProvider);
    final faToRegexWidget = _buildFaToRegexResult(algorithmState);

    return AlgorithmPanelScaffold(
      title: l10n.algorithms,
      children: [
        ValueListenableBuilder<String?>(
          valueListenable: _loadingExampleName,
          builder: (context, loadingExampleName, _) {
            return AlgorithmExamplesSection<RegexPreset>(
              examplesFuture: _regexExamplesFuture,
              loadingExampleName: loadingExampleName,
              onExampleSelected: _loadSelectedRegexExample,
              failureMessage: 'Failed to load Regex examples.',
              emptyMessage: 'No Regex examples available.',
            );
          },
        ),
        const Divider(),
        _buildRegexConversionActions(),
        if (faToRegexWidget != null) faToRegexWidget,
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SwitchSettingTile(
              title: l10n.simplifyOutput,
              subtitle: l10n.simplifyOutputSubtitle,
              value: regexState.simplifyOutput,
              onChanged: _setSimplifyOutput,
              switchKey: const ValueKey('regex_simplify_output_switch'),
            ),
          ),
        ),
        _buildSimplificationStepsSection(),
        _buildComplexityAnalysisSection(),
        _buildSampleStringsSection(),
        _buildRegexEquivalenceSection(),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _clearInputs,
            icon: const Icon(Icons.clear_all),
            label: Text(l10n.clear),
          ),
        ),
      ],
    );
  }

  Widget _buildRegexConversionActions() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.convertToAutomaton,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final buttons = [
              ElevatedButton.icon(
                onPressed: _convertToNFA,
                icon: const Icon(Icons.account_tree),
                label: Text(l10n.convertToNfa),
              ),
              ElevatedButton.icon(
                onPressed: _convertToDFA,
                icon: const Icon(Icons.account_tree_outlined),
                label: Text(l10n.convertToDfa),
              ),
            ];

            if (constraints.maxWidth < 420) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  buttons.first,
                  const SizedBox(height: 12),
                  buttons.last
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: buttons.first),
                const SizedBox(width: 12),
                Expanded(child: buttons.last),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildRegexEquivalenceSection() {
    final l10n = AppLocalizations.of(context);
    final regexState = ref.watch(regexEditorProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.compareRegularExpressions,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _comparisonRegexController,
          decoration: InputDecoration(
            hintText: l10n.comparisonRegexHint,
            border: const OutlineInputBorder(),
          ),
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: TextInputType.visiblePassword,
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _compareRegexEquivalence,
            icon: const Icon(Icons.compare_arrows),
            label: Text(l10n.compareEquivalence),
          ),
        ),
        if (regexState.equivalenceMessage.isNotEmpty) ...[
          const SizedBox(height: 8),
          ErrorBanner(
            message: regexState.equivalenceMessage,
            severity: regexState.equivalenceResult == true
                ? ErrorSeverity.success
                : ErrorSeverity.warning,
            showRetryButton: false,
            showDismissButton: false,
          ),
        ],
      ],
    );
  }

  void _clearInputs() {
    _regexController.clear();
    _testStringController.clear();
    _comparisonRegexController.clear();
    ref.read(automatonAlgorithmProvider.notifier).clearAlgorithmResults();
    ref.read(regexEditorProvider.notifier).clearInputs();
  }

  Widget? _buildFaToRegexResult(
    AlgorithmOperationState algorithmState,
  ) {
    final l10n = AppLocalizations.of(context);
    final regexState = ref.watch(regexEditorProvider);

    // Only show if we have conversion results
    if (algorithmState.rawRegexResult == null &&
        algorithmState.simplifiedRegexResult == null) {
      return null;
    }

    final rawRegex = algorithmState.rawRegexResult;
    final simplifiedRegex = algorithmState.simplifiedRegexResult;
    final displayedFromSimplified =
        (regexState.simplifyOutput && simplifiedRegex != null) ||
            (!regexState.simplifyOutput &&
                rawRegex == null &&
                simplifiedRegex != null);
    final displayedRegex = displayedFromSimplified ? simplifiedRegex : rawRegex;

    if (displayedRegex == null) return null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    displayedFromSimplified
                        ? l10n.convertedRegexSimplified
                        : l10n.convertedRegexRaw,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    try {
                      await Clipboard.setData(
                        ClipboardData(text: displayedRegex),
                      );
                    } catch (error) {
                      debugPrint('Failed to copy regex: $error');
                      return;
                    }
                    if (!mounted) return;
                    _showFeedback(
                      l10n.regexCopiedToClipboard,
                      tone: AppSnackBarTone.success,
                    );
                  },
                  icon: const Icon(Icons.copy, size: 20),
                  tooltip: l10n.copyToClipboard,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: SelectableText(
                displayedRegex,
                style: TextStyle(
                  fontFamilyFallback: kMonospaceFontFamilyFallback,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (algorithmState.rawRegexResult != null &&
                algorithmState.simplifiedRegexResult != null &&
                algorithmState.rawRegexResult !=
                    algorithmState.simplifiedRegexResult)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  regexState.simplifyOutput
                      ? l10n.toggleOffRawOutput
                      : l10n.toggleOnSimplifiedOutput,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
