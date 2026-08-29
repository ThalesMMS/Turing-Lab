// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get selectTransition => 'Select transition';

  @override
  String get createNewTransition => 'Create new transition';

  @override
  String canvasViewportStateCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count states',
      one: '1 state',
      zero: '0 states',
    );
    return '$_temp0';
  }

  @override
  String canvasViewportTransitionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transitions',
      one: '1 transition',
      zero: '0 transitions',
    );
    return '$_temp0';
  }

  @override
  String get workspaceStatusNoAutomaton => 'No automaton defined';

  @override
  String get workspaceStatusMissingInitialState => 'Missing start state';

  @override
  String get workspaceStatusNoAcceptingStates => 'No accepting states';

  @override
  String get workspaceStatusNondeterministic => 'Nondeterministic transitions';

  @override
  String get workspaceStatusLambdaTransitions => 'ε-transitions present';

  @override
  String workspaceStatusCounts(String states, String transitions) {
    return '$states · $transitions';
  }

  @override
  String workspaceStatusWithWarnings(String warnings, String counts) {
    return '⚠ $warnings · $counts';
  }

  @override
  String get workspaceHelpUnavailable =>
      'Help content is not available right now.';

  @override
  String collapseCanvasPanel(String label) {
    return 'Collapse $label panel';
  }

  @override
  String expandCanvasPanel(String label) {
    return 'Expand $label panel';
  }

  @override
  String canvasViewportSemantics(String states, String transitions) {
    return 'Automaton canvas viewport. $states, $transitions.';
  }

  @override
  String canvasStateSemantics(String name) {
    return 'State $name.';
  }

  @override
  String get canvasInitialStateSemantics => 'Initial state.';

  @override
  String get canvasAcceptingStateSemantics => 'Accepting state.';

  @override
  String canvasOutgoingTransitionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count outgoing transitions.',
      one: '1 outgoing transition.',
      zero: '0 outgoing transitions.',
    );
    return '$_temp0';
  }

  @override
  String canvasIncomingTransitionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count incoming transitions.',
      one: '1 incoming transition.',
      zero: '0 incoming transitions.',
    );
    return '$_temp0';
  }

  @override
  String get canvasUnlabeledTransition => 'unlabeled';

  @override
  String get canvasSelectedTransitionSemantics => 'Selected transition.';

  @override
  String canvasTransitionSemantics(
    String id,
    String from,
    String to,
    String label,
  ) {
    return 'Transition $id from $from to $to labeled $label.';
  }

  @override
  String get canvasViewportEditHint =>
      'Use keyboard shortcuts or toolbar controls to edit the canvas.';

  @override
  String get canvasViewportReadOnlyHint =>
      'This canvas is read-only. Pan or zoom to inspect the automaton.';

  @override
  String get canvasStateEditHint =>
      'Activate to edit state details. Drag to move in selection mode.';

  @override
  String get canvasStateReadOnlyHint => 'Read-only state.';

  @override
  String get canvasAddTransitionPrompt => 'Add transition...';

  @override
  String get canvasChooseTargetState => 'Choose target state';

  @override
  String get dismissTransitionEditor => 'Dismiss transition editor';

  @override
  String get stateLabel => 'State label';

  @override
  String get initialState => 'Initial state';

  @override
  String get acceptingState => 'Accepting state';

  @override
  String get deleteState => 'Delete state';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get close => 'Close';

  @override
  String get conversionReplaceTitle => 'Replace loaded result?';

  @override
  String get conversionReplaceCancel => 'Cancel';

  @override
  String get conversionReplaceConfirm => 'Replace';

  @override
  String get conversionReplaceAutomatonMessage =>
      'An automaton is already loaded. Do you want to replace it?';

  @override
  String get conversionReplaceGrammarMessage =>
      'A grammar is already loaded. Do you want to replace it?';

  @override
  String get conversionReplacePushdownAutomatonMessage =>
      'A pushdown automaton is already loaded. Do you want to replace it?';

  @override
  String get conversionReplaceTuringMachineMessage =>
      'A Turing machine is already loaded. Do you want to replace it?';

  @override
  String get conversionReplaceRegexMessage =>
      'A regex is already loaded. Do you want to replace it?';

  @override
  String canvasActionSemantics(String action) {
    return 'Canvas action: $action';
  }

  @override
  String canvasDestructiveActionSemantics(String action) {
    return 'Canvas action: $action. Destructive action.';
  }

  @override
  String get canvasSelectAction => 'Select';

  @override
  String get canvasAddStateAction => 'Add state';

  @override
  String get canvasAddTransitionAction => 'Add transition';

  @override
  String get canvasUndoAction => 'Undo';

  @override
  String get canvasRedoAction => 'Redo';

  @override
  String get canvasZoomOutAction => 'Zoom out';

  @override
  String get canvasZoomInAction => 'Zoom in';

  @override
  String get canvasFitToContentAction => 'Fit to content';

  @override
  String get canvasResetViewAction => 'Reset view';

  @override
  String get canvasArrangeAutomatonAction => 'Arrange automaton states';

  @override
  String get canvasImportAutomatonAction => 'Import automaton';

  @override
  String get canvasDocumentNotesAction => 'Document notes';

  @override
  String get canvasClearAction => 'Clear canvas';

  @override
  String get canvasHelpAction => 'Help';

  @override
  String get canvasHelpShortcutsAction => 'Help & Shortcuts';

  @override
  String get canvasExpandToolbarAction => 'Expand toolbar';

  @override
  String get canvasCollapseToolbarAction => 'Collapse toolbar';

  @override
  String get canvasMoreActions => 'More canvas actions';

  @override
  String canvasZoomLevel(int percent) {
    return 'Zoom $percent%';
  }

  @override
  String get canvasSelectHint =>
      'Activates selection mode for moving and editing states.';

  @override
  String get canvasAddStateHint =>
      'Toggles Add State mode; tap the canvas to place a state.';

  @override
  String get canvasAddTransitionHint =>
      'Activates transition mode to connect two states.';

  @override
  String get canvasUndoHint => 'Reverts the most recent canvas change.';

  @override
  String get canvasRedoHint =>
      'Restores the most recently undone canvas change.';

  @override
  String get canvasZoomOutHint => 'Decreases the canvas zoom level.';

  @override
  String get canvasZoomInHint => 'Increases the canvas zoom level.';

  @override
  String get canvasFitToContentHint =>
      'Zooms and pans to show the full automaton.';

  @override
  String get canvasResetViewHint => 'Resets the canvas zoom and pan position.';

  @override
  String get canvasArrangeAutomatonHint =>
      'Previews a layout before applying it to this automaton.';

  @override
  String get canvasImportAutomatonHint =>
      'Previews and combines a compatible automaton with this document.';

  @override
  String get canvasDocumentNotesHint => 'Opens the notes for this document.';

  @override
  String get canvasClearHint =>
      'Removes all states and transitions from the canvas.';

  @override
  String get canvasHelpShortcutsHint =>
      'Opens canvas help and keyboard shortcut information.';

  @override
  String get canvasExpandToolbarHint =>
      'Shows history, viewport, clear, and help actions.';

  @override
  String get canvasCollapseToolbarHint => 'Hides secondary canvas actions.';

  @override
  String get canvasMoreActionsHint => 'Opens the secondary canvas action menu.';

  @override
  String get pdaInputSymbol => 'Input symbol';

  @override
  String get pdaLambdaInput => 'ε-input';

  @override
  String get pdaInputSymbolRequired => 'Enter a symbol or enable ε-input';

  @override
  String get pdaPopSymbol => 'Pop symbol';

  @override
  String get pdaLambdaPop => 'ε-pop';

  @override
  String get pdaPopSymbolRequired => 'Enter a symbol or enable ε-pop';

  @override
  String get pdaPushSymbol => 'Push symbol';

  @override
  String get pdaLambdaPush => 'ε-push';

  @override
  String get pdaPushSymbolRequired => 'Enter a symbol or enable ε-push';

  @override
  String get tmReadSymbol => 'Read symbol';

  @override
  String get tmReadSymbolRequired => 'Enter a read symbol';

  @override
  String get tmWriteSymbol => 'Write symbol';

  @override
  String get tmWriteSymbolRequired => 'Enter a write symbol';

  @override
  String get tmDirection => 'Direction';

  @override
  String get transitionEditorCancel => 'Cancel';

  @override
  String get transitionEditorDelete => 'Delete';

  @override
  String get transitionEditorSave => 'Save';

  @override
  String get transitionLabel => 'Label';

  @override
  String get transitionEditLabelSemantics => 'Edit transition label';

  @override
  String get contextAwareHelp => 'Context-Aware Help';

  @override
  String get algorithms => 'Algorithms';

  @override
  String get algorithmsAndExamples => 'Algorithms & Examples';

  @override
  String get settingsPageTitle => 'Settings';

  @override
  String get settingsSaveTooltip => 'Save Settings';

  @override
  String get settingsResetTooltip => 'Reset to Defaults';

  @override
  String get settingsLoadError => 'Failed to load settings. Please try again.';

  @override
  String get settingsSaveSuccess => 'Settings saved.';

  @override
  String get settingsSaveError => 'Failed to save settings. Please try again.';

  @override
  String get settingsApplyError =>
      'Settings were saved, but could not be applied. Restart Turing Lab to refresh them.';

  @override
  String get settingsResetSuccess => 'Settings reset to defaults.';

  @override
  String get settingsSectionTheme => 'Theme';

  @override
  String get settingsSectionLanguage => 'Language';

  @override
  String get settingsSectionCanvas => 'Canvas';

  @override
  String get settingsSectionGeneral => 'General';

  @override
  String get settingsSectionActions => 'Actions';

  @override
  String get settingsThemeModeTitle => 'Theme Mode';

  @override
  String get settingsThemeModeDescription => 'Choose your preferred theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsLanguageTitle => 'App Language';

  @override
  String get settingsLanguageDescription =>
      'Choose the language used by Turing Lab';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguagePortuguese => 'Português';

  @override
  String get settingsShowGridTitle => 'Show Grid';

  @override
  String get settingsShowGridDescription => 'Display grid lines on canvas';

  @override
  String get settingsShowCoordinatesTitle => 'Show Coordinates';

  @override
  String get settingsShowCoordinatesDescription =>
      'Display coordinate information';

  @override
  String get settingsGridSizeTitle => 'Grid Size';

  @override
  String get settingsGridSizeDescription => 'Size of grid cells';

  @override
  String get settingsNodeSizeTitle => 'Node Size';

  @override
  String get settingsNodeSizeDescription => 'Size of automaton nodes';

  @override
  String get settingsFontSizeTitle => 'Font Size';

  @override
  String get settingsFontSizeDescription => 'Text size in the interface';

  @override
  String get settingsAutoSaveTitle => 'Auto Save';

  @override
  String get settingsAutoSaveDescription => 'Automatically save changes';

  @override
  String get settingsShowTooltipsTitle => 'Show Tooltips';

  @override
  String get settingsShowTooltipsDescription => 'Display helpful tooltips';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsAboutTileTitle => 'About Turing Lab';

  @override
  String get settingsAboutTileSubtitle =>
      'Product overview, platforms, and credits';

  @override
  String get aboutPageTitle => 'About Turing Lab';

  @override
  String get aboutEyebrow => 'Formal languages and automata';

  @override
  String get aboutLead =>
      'A Flutter-based toolkit for constructing, transforming, and simulating formal language models.';

  @override
  String get aboutDetail =>
      'It provides dedicated workspaces for finite-state automata, context-free grammars, pushdown automata, Turing machines, regular expressions, and pumping lemma exercises.';

  @override
  String get aboutDevelopmentStatus =>
      'Development status: Apple and Android builds are currently under testing.';

  @override
  String get aboutViewSource => 'View source';

  @override
  String get aboutReadDocumentation => 'Read documentation';

  @override
  String get aboutReportIssue => 'Report an issue';

  @override
  String get aboutCapabilitiesTitle => 'Supported models and workflows';

  @override
  String get aboutCapabilitiesIntro =>
      'The current scope is organized around six independent workspaces. File support and transformations vary by model.';

  @override
  String get aboutCapabilityEditing => 'Editing';

  @override
  String get aboutCapabilitySimulation => 'Simulation';

  @override
  String get aboutCapabilityTransformations => 'Transformations';

  @override
  String get aboutCapabilityImportExport => 'Import/export';

  @override
  String get aboutWorkspaceFsa => 'Finite-state automata';

  @override
  String get aboutWorkspaceFsaEditing => 'State and transition canvas';

  @override
  String get aboutWorkspaceFsaSimulation => 'Step-by-step acceptance traces';

  @override
  String get aboutWorkspaceFsaTransformations =>
      'NFA/DFA/regex conversion and DFA minimisation';

  @override
  String get aboutWorkspaceFsaFiles => 'JFLAP XML, JSON, SVG, and native PNG';

  @override
  String get aboutWorkspaceGrammar => 'Context-free grammars';

  @override
  String get aboutWorkspaceGrammarEditing => 'Grammar and production editor';

  @override
  String get aboutWorkspaceGrammarSimulation => 'Parsing and validation';

  @override
  String get aboutWorkspaceGrammarTransformations =>
      'FIRST/FOLLOW analysis, LL(1) diagnostics, and CNF conversion';

  @override
  String get aboutWorkspaceGrammarFiles => 'JFLAP grammar and SVG';

  @override
  String get aboutWorkspacePda => 'Pushdown automata';

  @override
  String get aboutWorkspacePdaEditing => 'State and transition canvas';

  @override
  String get aboutWorkspacePdaSimulation => 'Input and stack traces';

  @override
  String get aboutWorkspacePdaTransformations => 'Not applicable';

  @override
  String get aboutWorkspacePdaFiles => 'SVG export';

  @override
  String get aboutWorkspaceTm => 'Turing machines';

  @override
  String get aboutWorkspaceTmEditing => 'State and transition canvas';

  @override
  String get aboutWorkspaceTmSimulation => 'Tape and transition traces';

  @override
  String get aboutWorkspaceTmTransformations => 'Not applicable';

  @override
  String get aboutWorkspaceTmFiles => 'SVG export';

  @override
  String get aboutWorkspaceRegex => 'Regular expressions';

  @override
  String get aboutWorkspaceRegexEditing => 'Expression editor';

  @override
  String get aboutWorkspaceRegexSimulation => 'Match testing and comparison';

  @override
  String get aboutWorkspaceRegexTransformations =>
      'Simplification and automaton conversion';

  @override
  String get aboutWorkspaceRegexFiles => 'Not applicable';

  @override
  String get aboutWorkspacePumping => 'Pumping lemma';

  @override
  String get aboutWorkspacePumpingEditing => 'Guided case workflow';

  @override
  String get aboutWorkspacePumpingSimulation => 'Decomposition validation';

  @override
  String get aboutWorkspacePumpingTransformations => 'Not applicable';

  @override
  String get aboutWorkspacePumpingFiles => 'Not applicable';

  @override
  String get aboutFiniteAutomataTitle => 'Finite automata';

  @override
  String get aboutFiniteAutomataBody =>
      'Finite-state workflows include conversion between nondeterministic and deterministic automata, regular-expression conversion, DFA minimisation, and acceptance traces.';

  @override
  String get aboutGrammarAnalysisTitle => 'Grammar analysis';

  @override
  String get aboutGrammarAnalysisBody =>
      'Grammar tooling provides parsing diagnostics, FIRST and FOLLOW sets, LL(1) conflict reporting, and a best-effort Chomsky normal form pipeline.';

  @override
  String get aboutExecutionTracesTitle => 'Execution traces';

  @override
  String get aboutExecutionTracesBody =>
      'FSA, PDA, and TM simulations expose intermediate configurations through state, transition, stack, or tape traces appropriate to each model.';

  @override
  String get aboutFormatsTitle =>
      'Local execution and bounded file compatibility';

  @override
  String get aboutFormatsIntro =>
      'Turing Lab does not require an account or a developer-operated backend. Editing, simulation, diagnostics, and bundled examples run locally.';

  @override
  String get aboutFormatFsa =>
      'FSA: JFLAP XML and JSON import/export, SVG export, and PNG export on native platforms.';

  @override
  String get aboutFormatGrammar =>
      'Grammar: JFLAP grammar import/export and SVG export.';

  @override
  String get aboutFormatPdaTm =>
      'PDA: SVG export. TM: JFLAP XML and JSON import/export plus SVG export.';

  @override
  String get aboutFormatWebLimitation =>
      'Web limitation: PNG export is unavailable in web builds.';

  @override
  String get aboutPlatformsTitle => 'Current validation status';

  @override
  String get aboutPlatformsIntro =>
      'Testing builds are undergoing platform validation and release preparation. Experimental targets may have incomplete platform integration and are not part of the current release scope.';

  @override
  String get aboutStatusTesting => 'Testing';

  @override
  String get aboutStatusExperimental => 'Experimental';

  @override
  String get aboutPlatformIos => 'iOS and iPadOS';

  @override
  String get aboutPlatformMacos => 'macOS';

  @override
  String get aboutPlatformAndroid => 'Android';

  @override
  String get aboutPlatformWeb => 'Web';

  @override
  String get aboutPlatformWindows => 'Windows';

  @override
  String get aboutPlatformLinux => 'Linux';

  @override
  String get aboutScreenshotsTitle => 'Application workspaces';

  @override
  String get aboutScreenshotsIntro =>
      'Captured from controlled mobile and tablet testing configurations.';

  @override
  String get aboutScreenshotFsa =>
      'Finite-state automata. Automaton canvas, simulation result, and step-by-step trace.';

  @override
  String get aboutScreenshotGrammar =>
      'Context-free grammars. Production editing and grammar transformations.';

  @override
  String get aboutScreenshotTm =>
      'Turing machines. Tape simulation, transition editing, and machine-specific analysis.';

  @override
  String get aboutAttribution =>
      'Turing Lab is inspired by the original JFLAP project. Turing Lab is not affiliated with, endorsed by, or an official release of JFLAP, Duke University, or Susan H. Rodger.';

  @override
  String get aboutOpenLicenses => 'Open-source licenses';

  @override
  String get aboutOpenPrivacy => 'Privacy policy';

  @override
  String get aboutOpenSupport => 'Support';

  @override
  String get homeHelpTooltip => 'Help';

  @override
  String get homeSettingsTooltip => 'Settings';

  @override
  String get homeNavigationFsaLabel => 'FSA';

  @override
  String get homeNavigationFsaDescription => 'Finite State Automata';

  @override
  String get homeNavigationGrammarLabel => 'Grammar';

  @override
  String get homeNavigationGrammarDescription => 'Context-Free Grammars';

  @override
  String get homeNavigationPdaLabel => 'PDA';

  @override
  String get homeNavigationPdaDescription => 'Pushdown Automata';

  @override
  String get homeNavigationTmLabel => 'TM';

  @override
  String get homeNavigationTmDescription => 'Turing Machines';

  @override
  String get homeNavigationRegexLabel => 'Regex';

  @override
  String get homeNavigationRegexDescription => 'Regular Expressions';

  @override
  String get homeNavigationPumpingLabel => 'Pumping';

  @override
  String get homeNavigationPumpingDescription => 'Pumping Lemma';

  @override
  String get homeNavigationRegularPumpingLabel => 'Regular pumping';

  @override
  String get homeNavigationRegularPumpingDescription => 'Regular pumping lemma';

  @override
  String get homeNavigationContextFreePumpingLabel => 'Context-free pumping';

  @override
  String get homeNavigationContextFreePumpingDescription =>
      'Context-free pumping lemma';

  @override
  String get choosePumpingLemmaEnvironment =>
      'Choose a pumping lemma environment';

  @override
  String get choosePumpingLemmaEnvironmentDescription =>
      'Regular and context-free pumping lemmas have different decompositions and proof obligations.';

  @override
  String get helpPageTitle => 'Help & Documentation';

  @override
  String get helpSearchTooltip => 'Search Help';

  @override
  String get helpQuickStartTitle => 'Quick Start Guide';

  @override
  String get helpQuickStartBody =>
      'Welcome to Turing Lab. Here is a quick way to get started:\n\n1. Choose a workspace such as FSA, Grammar, PDA, TM, or Regex.\n2. Start with a blank workspace or open a supported example or file.\n3. Use the editor to build your machine or grammar. Double-tap a state for quick actions.\n4. Run simulations to test your work.\n5. Use algorithms to transform structures.\n\nTips:\n• Use navigation tabs or section chips to switch workspaces quickly.\n• Double-tap a state to open its quick action menu.\n• Pinch to zoom on the canvas.\n• Tap the Quick Start icon whenever you need a refresher.';

  @override
  String get helpGotIt => 'Got it!';

  @override
  String get helpSearchFieldLabel => 'Search help...';

  @override
  String get helpSearchClear => 'Clear search';

  @override
  String get helpSearchClose => 'Close search';

  @override
  String get helpSearchTitle => 'Search Help';

  @override
  String get helpSearchSubtitle =>
      'Find tutorials, shortcuts, and theory explanations';

  @override
  String get helpSearchNoResults => 'No results found';

  @override
  String get helpSearchNoResultsDescription =>
      'Try different keywords or check your spelling';

  @override
  String get helpSectionGettingStarted => 'Getting Started';

  @override
  String get helpSectionFsa => 'FSA';

  @override
  String get helpSectionGrammar => 'Grammar';

  @override
  String get helpSectionPda => 'PDA';

  @override
  String get helpSectionTm => 'Turing Machine';

  @override
  String get helpSectionRegex => 'Regular Expression';

  @override
  String get helpSectionPumping => 'Pumping Lemma';

  @override
  String get helpSectionFileOperations => 'File Operations';

  @override
  String get helpSectionTroubleshooting => 'Troubleshooting';

  @override
  String get helpSectionAbout => 'About';

  @override
  String get regularExpressionTitle => 'Regular Expression';

  @override
  String get regularExpressionLabel => 'Regular Expression:';

  @override
  String get regularExpressionHint => 'Enter regular expression (e.g., a*b+)';

  @override
  String get validateRegex => 'Validate Regex';

  @override
  String get enterRegexToValidate => 'Enter a regular expression to validate.';

  @override
  String get validRegex => 'Valid regex';

  @override
  String get invalidRegex => 'Invalid regex';

  @override
  String get testStringLabel => 'Test String:';

  @override
  String get testStringHint => 'Enter string to test';

  @override
  String get testStringTooltip => 'Test String';

  @override
  String get regexBatchTestingTitle => 'Batch testing';

  @override
  String get regexBatchTestingSubtitle => 'Match ordered, bounded input cases';

  @override
  String get regexBatchExecutionTitle => 'Regex batch execution';

  @override
  String get matches => 'Matches!';

  @override
  String get doesNotMatch => 'Does not match';

  @override
  String get convertToAutomaton => 'Convert to Automaton:';

  @override
  String get convertToNfa => 'Convert to NFA';

  @override
  String get convertToDfa => 'Convert to DFA';

  @override
  String get simplifyOutput => 'Simplify Output';

  @override
  String get simplifyOutputSubtitle =>
      'Apply algebraic simplifications to converted automata';

  @override
  String get compareRegularExpressions => 'Compare Regular Expressions:';

  @override
  String get comparisonRegexHint => 'Enter second regular expression';

  @override
  String get compareEquivalence => 'Compare Equivalence';

  @override
  String get regexHelp => 'Regex Help';

  @override
  String get regexHelpPatterns =>
      'Common patterns:\n• a* - zero or more a\'s\n• a+ - one or more a\'s\n• a? - zero or one a\n• a|b - a or b\n• (ab)* - zero or more ab\'s\n• [abc] - any of a, b, or c';

  @override
  String get convertedRegexSimplified => 'Converted Regex (Simplified)';

  @override
  String get convertedRegexRaw => 'Converted Regex (Raw)';

  @override
  String get regexCopiedToClipboard => 'Regex copied to clipboard';

  @override
  String get copyToClipboard => 'Copy to clipboard';

  @override
  String get toggleOffRawOutput => 'Toggle off to see raw output';

  @override
  String get toggleOnSimplifiedOutput => 'Toggle on to see simplified output';

  @override
  String get enterValidRegexFirst =>
      'Please enter a valid regular expression first';

  @override
  String get failedConvertRegexToNfa => 'Failed to convert regex to NFA';

  @override
  String get convertedRegexToNfa =>
      'Converted regex to NFA. View it in the FSA workspace.';

  @override
  String get failedConvertNfaToDfa => 'Failed to convert NFA to DFA';

  @override
  String get convertedRegexToDfa =>
      'Converted regex to DFA. Opening the DFA in the FSA workspace.';

  @override
  String get failedSimplifyRegex => 'Failed to simplify regex';

  @override
  String get failedAnalyzeRegex => 'Failed to analyze regex';

  @override
  String get failedGenerateSampleStrings => 'Failed to generate sample strings';

  @override
  String get simplificationSteps => 'Simplification Steps';

  @override
  String get hideSteps => 'Hide steps';

  @override
  String get showSteps => 'Show steps';

  @override
  String get simplifyWithSteps => 'Simplify with Steps';

  @override
  String get clear => 'Clear';

  @override
  String get resimplify => 'Re-simplify';

  @override
  String get originalLabel => 'Original:';

  @override
  String get rulesAppliedLabel => 'rule(s) applied';

  @override
  String get simplifiedLabel => 'Simplified:';

  @override
  String get simplifiedRegexCopiedToClipboard =>
      'Simplified regex copied to clipboard';

  @override
  String get copySimplifiedRegex => 'Copy simplified regex';

  @override
  String get saved => 'Saved';

  @override
  String get charactersAbbreviation => 'chars';

  @override
  String get reduction => 'Reduction';

  @override
  String get time => 'Time';

  @override
  String get stepLabel => 'Step';

  @override
  String get ofLabel => 'of';

  @override
  String get previousStep => 'Previous Step';

  @override
  String get nextStep => 'Next Step';

  @override
  String get allSteps => 'All Steps:';

  @override
  String get transformation => 'Transformation';

  @override
  String get before => 'Before';

  @override
  String get after => 'After';

  @override
  String get rule => 'Rule';

  @override
  String get starHeight => 'Star Height';

  @override
  String get nestingDepth => 'Nesting Depth';

  @override
  String get operators => 'Operators';

  @override
  String get conversionComparisonUnavailable =>
      'Conversion comparison unavailable. Saved snapshots could not be read.';

  @override
  String get conversionComparisonResult => 'Conversion result';

  @override
  String get simulation => 'Simulation';

  @override
  String get viewOnCanvas => 'View on Canvas';

  @override
  String get inputString => 'Input String';

  @override
  String get simulationInputHint =>
      'Leave blank for ε; whitespace is preserved';

  @override
  String get simulationInputString => 'Simulation input string';

  @override
  String get simulate => 'Simulate';

  @override
  String get simulating => 'Simulating...';

  @override
  String get cancelSimulation => 'Cancel simulation';

  @override
  String get runSimulation => 'Run simulation';

  @override
  String get runSimulationHint =>
      'Runs the machine using the currently entered input string.';

  @override
  String simulationInputSemantics(String label) {
    return 'Simulation input: $label';
  }

  @override
  String simulationEditHint(String hint) {
    return '$hint. Double tap to edit.';
  }

  @override
  String get simulationResult => 'Simulation Result';

  @override
  String get regexResult => 'Regex Result';

  @override
  String get regularExpression => 'Regular Expression';

  @override
  String get stepByStepMode => 'Step-by-Step Mode';

  @override
  String get stepByStepModeSemantics => 'Step-by-step mode';

  @override
  String get stepByStepExecution => 'Step-by-Step Execution';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get reset => 'Reset';

  @override
  String get expand => 'Expand';

  @override
  String get collapse => 'Collapse';

  @override
  String get noStepsRecorded => 'No steps recorded';

  @override
  String get noStepsAvailable => 'No steps available';

  @override
  String get noSteps => 'No steps';

  @override
  String get timeline => 'Timeline';

  @override
  String get timelineScrubber => 'Timeline scrubber';

  @override
  String get timelineNavigationHint =>
      'Drag to navigate through simulation steps';

  @override
  String stepOf(int current, int total) {
    final intl.NumberFormat currentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String currentString = currentNumberFormat.format(current);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Step $currentString of $totalString';
  }

  @override
  String stepNumber(int step) {
    final intl.NumberFormat stepNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String stepString = stepNumberFormat.format(step);

    return 'Step $stepString';
  }

  @override
  String activeStepOf(int current, int total) {
    return 'Active step $current of $total';
  }

  @override
  String pdaTrace(int count) {
    return 'PDA Trace ($count steps)';
  }

  @override
  String tmTrace(int count) {
    return 'TM Trace ($count steps)';
  }

  @override
  String get traceRemaining => 'rem';

  @override
  String get traceStack => 'stack';

  @override
  String get traceTape => 'tape';

  @override
  String get pdaStackPanelLabel => 'Stack';

  @override
  String get timeout => 'Timeout';

  @override
  String get infiniteLoop => 'Infinite Loop';

  @override
  String get steps => 'Steps';

  @override
  String get states => 'States';

  @override
  String get executionPath => 'Execution Path';

  @override
  String get transitions => 'Transitions';

  @override
  String get animationSpeed => 'Animation speed';

  @override
  String get selectPlaybackSpeed => 'Select playback speed';

  @override
  String get speed => 'Speed:';

  @override
  String slowSpeed(String speed) {
    return 'Slow $speed';
  }

  @override
  String get normalSpeed => 'Normal speed';

  @override
  String fastSpeed(String speed) {
    return 'Fast $speed';
  }

  @override
  String playbackSpeedMultiplier(String speed) {
    return '${speed}x';
  }

  @override
  String get on => 'On';

  @override
  String get off => 'Off';

  @override
  String get stepByStepToggleHint =>
      'Turns manual simulation review on or off for the current result.';

  @override
  String simulationStartDescription(String state, String input) {
    return 'Start at $state with input $input.';
  }

  @override
  String simulationFinalDescription(String state, String verdict) {
    return 'Final configuration $state – input $verdict.';
  }

  @override
  String simulationReadDescription(
    String consumed,
    String state,
    String nextState,
    String remaining,
  ) {
    return 'Read \"$consumed\" from $state → $nextState with $remaining.';
  }

  @override
  String get noInputRemaining => 'no input remaining';

  @override
  String remainingQuoted(String input) {
    return 'remaining \"$input\"';
  }

  @override
  String consumedValue(String value) {
    return 'Consumed: \"$value\"';
  }

  @override
  String nextStateValue(String state) {
    return 'Next state: $state';
  }

  @override
  String remainingInputValue(String input) {
    return 'Remaining input: $input';
  }

  @override
  String get previousSimulationStep => 'Previous simulation step';

  @override
  String get previousSimulationStepHint =>
      'Moves to the prior recorded simulation step.';

  @override
  String get nextSimulationStep => 'Next simulation step';

  @override
  String get nextSimulationStepHint =>
      'Advances to the next recorded simulation step.';

  @override
  String get playSimulationSteps => 'Play simulation steps';

  @override
  String get pauseSimulationPlayback => 'Pause simulation playback';

  @override
  String get playSimulationHint =>
      'Automatically advances through the recorded simulation steps.';

  @override
  String get pauseSimulationHint =>
      'Pauses automatic playback of simulation steps.';

  @override
  String get resetSimulationSteps => 'Reset simulation steps';

  @override
  String get resetSimulationStepsHint =>
      'Returns the step-by-step view to the first recorded step.';

  @override
  String get resetToFirst => 'Reset to First';

  @override
  String get jumpToLast => 'Jump to Last';

  @override
  String get previousStepLower => 'Previous step';

  @override
  String get nextStepLower => 'Next step';

  @override
  String hiddenStepsSummary(int before, int after) {
    return '$before before, $after after hidden';
  }

  @override
  String get noSimulationResults => 'No simulation results yet';

  @override
  String get simulationEmptyHint =>
      'Enter an input string and activate Simulate to see results';

  @override
  String get accepted => 'Accepted';

  @override
  String get rejected => 'Rejected';

  @override
  String get acceptedLower => 'accepted';

  @override
  String get rejectedLower => 'rejected';

  @override
  String get regexAlphabetLabel => 'Alphabet / universe';

  @override
  String get regexAlphabetHelper =>
      'Characters used by ., \\D, \\W, and \\S (spaces count).';

  @override
  String get regexAlphabetEmptyError => 'Alphabet cannot be empty.';

  @override
  String get suggestedFixes => 'Suggested fixes';

  @override
  String algorithmAction(String title) {
    return 'Algorithm action: $title';
  }

  @override
  String algorithmUnavailableHint(String description) {
    return 'Unavailable. $description';
  }

  @override
  String algorithmStartHint(String description) {
    return 'Double tap to start. $description';
  }

  @override
  String get pdaNormalizationReviewTitle => 'Review PDA normalization';

  @override
  String pdaNormalizationSourceAcceptance(String mode) {
    return 'Source acceptance: $mode';
  }

  @override
  String pdaNormalizationTargetAcceptance(String mode) {
    return 'Target acceptance: $mode';
  }

  @override
  String pdaNormalizationStateCount(int before, int after) {
    return 'States: $before → $after';
  }

  @override
  String pdaNormalizationTransitionCount(int before, int after) {
    return 'Transitions: $before → $after';
  }

  @override
  String pdaNormalizationNewStackSymbol(String symbol) {
    return 'New stack symbol: $symbol';
  }

  @override
  String get pdaNormalizationGrowthWarning =>
      'Normalization may increase the state and transition count. Acceptance conversion may also introduce non-determinism.';

  @override
  String get pdaNormalizationCancelHint =>
      'Review the counts before applying. Cancel leaves the editor unchanged.';

  @override
  String get pdaNormalizationCancel => 'Cancel';

  @override
  String get pdaNormalizationApplyAndConvert => 'Apply and convert';

  @override
  String get pdaSimplificationButtonTitle => 'Simplify PDA';

  @override
  String get pdaSimplificationButtonDescription =>
      'Safely remove unreachable or strongly bisimilar control states';

  @override
  String get pdaSimplificationAnalysisTitle => 'PDA Simplification';

  @override
  String get pdaSimplificationMissingPda =>
      'Create a PDA before simplifying it.';

  @override
  String get pdaSimplificationReviewTitle => 'Review PDA simplification';

  @override
  String pdaSimplificationActiveAcceptance(String mode) {
    return 'Active acceptance: $mode';
  }

  @override
  String get pdaSimplificationScope =>
      'This is a conservative structural reduction, not a globally minimal NPDA.';

  @override
  String get pdaSimplificationSkippedSemantic =>
      'Exact semantic usefulness is not available for general NPDAs, so uncertain states were retained.';

  @override
  String get pdaSimplificationChangesHeading => 'Proposed changes';

  @override
  String pdaSimplificationUnreachableChange(int count) {
    return 'Unreachable states removed: $count';
  }

  @override
  String pdaSimplificationMergeChange(int count) {
    return 'Strong-bisimulation merge groups: $count';
  }

  @override
  String pdaSimplificationDuplicateChange(int count) {
    return 'Redundant transitions removed: $count';
  }

  @override
  String get pdaSimplificationCancelHint =>
      'Review before applying. Cancel leaves the editor unchanged.';

  @override
  String get pdaSimplificationCancel => 'Cancel';

  @override
  String get pdaSimplificationApply => 'Apply simplification';

  @override
  String get pdaSimplificationNoChange =>
      'No supported simplification was found. The PDA was copied without structural changes.';

  @override
  String get pdaSimplificationCanceled =>
      'Simplification canceled. The editor PDA was not changed.';

  @override
  String get pdaSimplificationApplied => 'PDA simplification applied.';

  @override
  String get pdaSimplificationEditorChanged =>
      'Simplification canceled because the editor PDA changed during review.';

  @override
  String pdaSimplificationFailed(String error) {
    return 'Simplification failed: $error';
  }

  @override
  String get pdaAcceptanceFinalState => 'final state';

  @override
  String get pdaAcceptanceEmptyStack => 'empty stack';

  @override
  String get pdaAcceptanceBoth => 'final state and empty stack';

  @override
  String get pdaAcceptanceModeTitle => 'Acceptance mode';

  @override
  String get pdaAcceptanceFinalStateExplanation =>
      'The complete input must end in an accepting state. The stack may still contain symbols.';

  @override
  String get pdaAcceptanceEmptyStackExplanation =>
      'The complete input must leave the stack empty. The current state does not need to be accepting.';

  @override
  String get pdaAcceptanceBothExplanation =>
      'The complete input must end in an accepting state with an empty stack.';

  @override
  String get pdaAcceptanceFinalStateCompactExplanation =>
      'Input consumed; stack ignored.';

  @override
  String get pdaAcceptanceEmptyStackCompactExplanation =>
      'Input consumed; final state ignored.';

  @override
  String get pdaAcceptanceBothCompactExplanation =>
      'Input consumed; both conditions required.';

  @override
  String get executing => 'Executing';

  @override
  String get selected => 'Selected';

  @override
  String workflowLegacyText(String text) {
    return '$text';
  }

  @override
  String get retry => 'Retry';

  @override
  String get retrying => 'Retrying...';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get dismissMessage => 'Dismiss message';

  @override
  String get cancel => 'Cancel';

  @override
  String get loading => 'Loading';

  @override
  String get doubleTapToRetry => 'Double tap to retry';

  @override
  String get successBannerSemantics => 'Success banner';

  @override
  String get errorBannerSemantics => 'Error banner';

  @override
  String get warningBannerSemantics => 'Warning banner';

  @override
  String get infoBannerSemantics => 'Info banner';

  @override
  String get ok => 'OK';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get add => 'Add';

  @override
  String get update => 'Update';

  @override
  String get undo => 'Undo';

  @override
  String get fileOperationsTitle => 'File Operations';

  @override
  String get fileSectionFsa => 'FSA';

  @override
  String get fileSectionGrammar => 'Grammar';

  @override
  String get fileSectionPda => 'PDA';

  @override
  String get fileSectionTm => 'Turing Machine';

  @override
  String get fileSectionRegex => 'Regular expression';

  @override
  String get regexDocumentDialect => 'Dialect';

  @override
  String get regexDocumentDialectTuringLab => 'Turing Lab v1';

  @override
  String get regexDocumentTokenization => 'Tokenization';

  @override
  String get regexDocumentTokenizationUnicodeScalar => 'Unicode scalar values';

  @override
  String get saveAsJflap => 'Save as JFLAP';

  @override
  String get downloadJflap => 'Download JFLAP';

  @override
  String get loadJflap => 'Load JFLAP';

  @override
  String get saveAsJson => 'Save as JSON';

  @override
  String get downloadJson => 'Download JSON';

  @override
  String get loadJson => 'Load JSON';

  @override
  String get exportSvg => 'Export SVG';

  @override
  String get downloadSvg => 'Download SVG';

  @override
  String get exportPng => 'Export PNG';

  @override
  String get jsonUnreadableFileMessage =>
      'Turing Lab could not access the selected JSON file data. Pick the file again and keep it available until the import finishes.';

  @override
  String get saveAutomatonAsJflap => 'Save Automaton as JFLAP';

  @override
  String get saveAutomatonAsJson => 'Save Automaton as JSON';

  @override
  String get loadJflapAutomaton => 'Load JFLAP Automaton';

  @override
  String get loadAutomatonJson => 'Load Automaton JSON';

  @override
  String get exportAutomatonAsSvg => 'Export Automaton as SVG';

  @override
  String get exportAutomatonAsPng => 'Export Automaton as PNG';

  @override
  String get saveGrammarAsJflap => 'Save Grammar as JFLAP';

  @override
  String get loadJflapGrammar => 'Load JFLAP Grammar';

  @override
  String get exportGrammarAsSvg => 'Export Grammar as SVG';

  @override
  String get exportPdaAsSvg => 'Export PDA as SVG';

  @override
  String get exportTmAsSvg => 'Export Turing Machine as SVG';

  @override
  String get automatonSavedSuccessfully => 'Automaton saved successfully';

  @override
  String get automatonLoadedSuccessfully => 'Automaton loaded successfully';

  @override
  String get automatonExportedSuccessfully => 'Automaton exported successfully';

  @override
  String get grammarSavedSuccessfully => 'Grammar saved successfully';

  @override
  String get grammarLoadedSuccessfully => 'Grammar loaded successfully';

  @override
  String get grammarExportedSuccessfully => 'Grammar exported successfully';

  @override
  String get pdaExportedSuccessfully => 'PDA exported successfully';

  @override
  String get tmExportedSuccessfully => 'Turing machine exported successfully';

  @override
  String get saveCanceled => 'Save canceled.';

  @override
  String get exportCanceled => 'Export canceled.';

  @override
  String get importCanceled => 'Import canceled.';

  @override
  String downloadStartedFor(String fileName) {
    return 'Download started for $fileName';
  }

  @override
  String failedToSaveAutomaton(String error) {
    return 'Failed to save automaton: $error';
  }

  @override
  String errorSavingAutomaton(String error) {
    return 'Error saving automaton: $error';
  }

  @override
  String errorLoadingAutomaton(String error) {
    return 'Error loading automaton: $error';
  }

  @override
  String failedToExportAutomaton(String error) {
    return 'Failed to export automaton: $error';
  }

  @override
  String errorExportingAutomaton(String error) {
    return 'Error exporting automaton: $error';
  }

  @override
  String failedToSaveAutomatonJson(String error) {
    return 'Failed to save automaton JSON: $error';
  }

  @override
  String errorSavingAutomatonJson(String error) {
    return 'Error saving automaton JSON: $error';
  }

  @override
  String errorLoadingAutomatonJson(String error) {
    return 'Error loading automaton JSON: $error';
  }

  @override
  String failedToExportAutomatonPng(String error) {
    return 'Failed to export automaton PNG: $error';
  }

  @override
  String errorExportingAutomatonPng(String error) {
    return 'Error exporting automaton PNG: $error';
  }

  @override
  String failedToSaveGrammar(String error) {
    return 'Failed to save grammar: $error';
  }

  @override
  String errorSavingGrammar(String error) {
    return 'Error saving grammar: $error';
  }

  @override
  String errorLoadingGrammar(String error) {
    return 'Error loading grammar: $error';
  }

  @override
  String failedToExportGrammar(String error) {
    return 'Failed to export grammar: $error';
  }

  @override
  String errorExportingGrammar(String error) {
    return 'Error exporting grammar: $error';
  }

  @override
  String failedToExportPda(String error) {
    return 'Failed to export PDA: $error';
  }

  @override
  String errorExportingPda(String error) {
    return 'Error exporting PDA: $error';
  }

  @override
  String failedToExportTm(String error) {
    return 'Failed to export Turing machine: $error';
  }

  @override
  String errorExportingTm(String error) {
    return 'Error exporting Turing machine: $error';
  }

  @override
  String get importErrorDialogSemantics => 'Import error dialog';

  @override
  String get cancelImport => 'Cancel import';

  @override
  String get importErrorMalformedJff => 'Malformed JFLAP File';

  @override
  String get importErrorInvalidJson => 'Invalid JSON Structure';

  @override
  String get importErrorUnsupportedVersion => 'Unsupported File Version';

  @override
  String get importErrorInaccessibleFile => 'File Access Unavailable';

  @override
  String get importErrorCorruptedData => 'Corrupted Data Detected';

  @override
  String get importErrorInvalidAutomaton => 'Invalid Automaton Definition';

  @override
  String get importFriendlyMalformedJff =>
      'The selected JFLAP file could not be parsed. Please verify the file integrity and try again.';

  @override
  String get importFriendlyInvalidJson =>
      'The import contains JSON sections that are invalid. Fix the JSON structure and retry.';

  @override
  String get importFriendlyUnsupportedVersion =>
      'This file targets a newer JFLAP schema version. Export it again using a compatible version and retry.';

  @override
  String get importFriendlyInaccessibleFile =>
      'Turing Lab could not access the selected file. Pick it again from the system dialog and keep it available until the import finishes.';

  @override
  String get importFriendlyCorruptedData =>
      'The file appears to be corrupted or unreadable. Restore a valid backup before importing again.';

  @override
  String get importFriendlyInvalidAutomaton =>
      'The automaton definition is inconsistent. Review the transitions and states before retrying the import.';

  @override
  String get hideTechnicalDetails => 'Hide technical details';

  @override
  String get viewTechnicalDetails => 'View technical details';

  @override
  String get svgNoStatesDefined => 'No states defined';

  @override
  String get svgTmLegend => 'δ(q, s) = (q′, w, d) — read/write/move';

  @override
  String get loadAutomatonBeforeOperation =>
      'Load an automaton before running this operation.';

  @override
  String get operationRequiresDeterministicNoEpsilon =>
      'This operation requires a deterministic automaton without ε-transitions.';

  @override
  String get automatonHasNoLambdaTransitions =>
      'The current automaton does not contain ε-transitions.';

  @override
  String get automatonMustContainLambdaToRemove =>
      'The current automaton must contain ε-transitions to remove them.';

  @override
  String get lambdaTransitionsRemoved => 'ε-transitions removed successfully.';

  @override
  String get complementComputed => 'Complement computed successfully.';

  @override
  String get complementRequiresDeterministic =>
      'Complement is only available for deterministic automata without ε-transitions.';

  @override
  String get prefixClosureComputed => 'Prefix closure computed successfully.';

  @override
  String get prefixClosureRequiresDeterministic =>
      'Prefix closure is only available for deterministic automata without ε-transitions.';

  @override
  String get suffixClosureComputed => 'Suffix closure computed successfully.';

  @override
  String get suffixClosureRequiresDeterministic =>
      'Suffix closure is only available for deterministic automata without ε-transitions.';

  @override
  String get unionComputed => 'Union computed successfully.';

  @override
  String get binaryDfaRequiresDeterministic =>
      'Binary DFA operations require a deterministic automaton without ε-transitions.';

  @override
  String get concatenationComputed => 'Concatenation computed successfully.';

  @override
  String get loadFsaBeforeConcatenation =>
      'Load an FSA before computing the concatenation.';

  @override
  String get kleeneStarComputed => 'Kleene star computed successfully.';

  @override
  String get loadFsaBeforeKleeneStar =>
      'Load an FSA before applying Kleene star.';

  @override
  String get fsaLanguageReversed => 'FSA language reversed successfully.';

  @override
  String get loadFsaBeforeReverse =>
      'Load an FSA before reversing its language.';

  @override
  String get intersectionComputed => 'Intersection computed successfully.';

  @override
  String get differenceComputed => 'Difference computed successfully.';

  @override
  String get convertedToRegexWorkspace =>
      'Automaton converted to regex. Switched to Regex workspace.';

  @override
  String get convertedToGrammarWorkspace =>
      'Automaton converted to grammar. Switched to Grammar workspace.';

  @override
  String get grammarEditorTitle => 'Grammar Editor';

  @override
  String get defaultGrammarName => 'My Grammar';

  @override
  String get grammarInformation => 'Grammar Information';

  @override
  String get grammarNameLabel => 'Grammar Name';

  @override
  String get startSymbolLabel => 'Start Symbol';

  @override
  String get editProductionRule => 'Edit Production Rule';

  @override
  String get addProductionRule => 'Add Production Rule';

  @override
  String get leftSideVariable => 'Left Side (Variable)';

  @override
  String get rightSideProduction => 'Right Side (Production)';

  @override
  String get leftSideHint => 'e.g., S, A, B';

  @override
  String get rightSideHint => 'e.g., aA, bB, ε';

  @override
  String get leftSideHelper => 'Enter exactly one non-terminal symbol.';

  @override
  String get rightSideHelper => 'Use ε for the empty string.';

  @override
  String get insertEpsilon => 'Insert ε';

  @override
  String get noProductionRulesYet => 'No production rules yet';

  @override
  String get addFirstProductionRule => 'Add your first production rule above';

  @override
  String get clearAllProductionsTitle => 'Clear all productions?';

  @override
  String get clearAllProductionsMessage =>
      'This will remove every production rule from the current grammar.';

  @override
  String get productionsCleared => 'Productions cleared.';

  @override
  String get bothSidesRequired =>
      'Both left side and right side must be specified';

  @override
  String get leftSideMustBeNonterminal =>
      'Left side must contain a non-terminal symbol';

  @override
  String get leftSideExactlyOneNonterminal =>
      'Left side must contain exactly one non-terminal symbol';

  @override
  String get rightSideAtLeastOneSymbol =>
      'Right side must contain at least one symbol (or ε)';

  @override
  String get rightSideSingleLambda =>
      'Right side can contain only one ε symbol';

  @override
  String get lambdaMustBeOnlySymbol =>
      'ε must be the only symbol on the right side';

  @override
  String get sampleStringsTitle => 'Sample Strings';

  @override
  String get hideSamples => 'Hide samples';

  @override
  String get showSamples => 'Show samples';

  @override
  String get generateSampleStrings => 'Generate Sample Strings';

  @override
  String get generateMore => 'Generate More';

  @override
  String get noSampleStringsGenerated => 'No sample strings generated';

  @override
  String get generatedSamples => 'Generated Samples:';

  @override
  String get copyAll => 'Copy All';

  @override
  String get allSamplesCopied => 'All samples copied to clipboard';

  @override
  String get failedToCopyClipboard => 'Failed to copy to clipboard.';

  @override
  String get complexityAnalysisTitle => 'Complexity Analysis';

  @override
  String get hideDetails => 'Hide details';

  @override
  String get showDetails => 'Show details';

  @override
  String get analyzeComplexity => 'Analyze Complexity';

  @override
  String get reanalyze => 'Re-analyze';

  @override
  String get noOperatorsUsed => 'No operators used (literal expression)';

  @override
  String get operatorUnion => 'Union (|)';

  @override
  String get operatorConcatenation => 'Concatenation';

  @override
  String get operatorKleeneStar => 'Kleene Star (*)';

  @override
  String get operatorPlus => 'Plus (+)';

  @override
  String get operatorOptional => 'Optional (?)';

  @override
  String get openWitnessInSimulator => 'Open witness in Simulator';

  @override
  String get drawPdaBeforeConvertGrammar =>
      'Draw a PDA before converting to a grammar.';

  @override
  String get generatedGrammar => 'Generated Grammar';

  @override
  String get pumpingLemmaGameTitle => 'Pumping Lemma Game';

  @override
  String get pumpingWelcome => 'Welcome to the Pumping Lemma Game!';

  @override
  String get pumpingWelcomeBody =>
      'Test your understanding of the pumping lemma by determining whether given languages are regular or not.';

  @override
  String get startGame => 'Start Game';

  @override
  String get isLanguageRegular => 'Is this language regular?';

  @override
  String get yesItIsRegular => 'Yes, it is regular';

  @override
  String get noItIsNotRegular => 'No, it is not regular';

  @override
  String get submitAnswer => 'Submit Answer';

  @override
  String get correct => 'Correct!';

  @override
  String get incorrect => 'Incorrect';

  @override
  String get explanation => 'Explanation:';

  @override
  String get nextChallenge => 'Next Challenge';

  @override
  String get finishGame => 'Finish Game';

  @override
  String get challengeComplete => 'Challenge Complete!';

  @override
  String get practiceAgain => 'Practice Again';

  @override
  String get performanceExpert => 'Expert';

  @override
  String get performanceAdvanced => 'Advanced';

  @override
  String get performanceIntermediate => 'Intermediate';

  @override
  String get performanceBeginner => 'Beginner';

  @override
  String get progressTitle => 'Progress';

  @override
  String get overallProgress => 'Overall Progress';

  @override
  String get statistics => 'Statistics';

  @override
  String get accuracy => 'Accuracy';

  @override
  String get correctCount => 'Correct';

  @override
  String get attempts => 'Attempts';

  @override
  String get challengeHistory => 'Challenge History';

  @override
  String get noChallengesCompletedYet => 'No challenges completed yet';

  @override
  String get wrong => 'Wrong';

  @override
  String get retrySelected => 'Retry selected';

  @override
  String get exampleDfaEndsWithA => 'DFA - Ends with A';

  @override
  String get exampleDfaBinaryDivBy3 => 'DFA - Binary divisible by 3';

  @override
  String get exampleDfaParityAb => 'DFA - AB parity';

  @override
  String get exampleDfaContainsAb => 'DFA - Contains AB';

  @override
  String get exampleNfaLambdaAOrAb => 'NFA-ε - A or AB';

  @override
  String get exampleCfgPalindrome => 'CFG - Palindrome';

  @override
  String get exampleCfgBalancedParens => 'CFG - Balanced parentheses';

  @override
  String get exampleCfgAnBn => 'CFG - a^n b^n';

  @override
  String get exampleCfgEvenZeros => 'CFG - Even number of zeros';

  @override
  String get exampleCfgArithmetic => 'CFG - Arithmetic expressions';

  @override
  String get examplePdaBalancedParens => 'PDA - Balanced parentheses';

  @override
  String get examplePdaAnBn => 'PDA - a^n b^n';

  @override
  String get examplePdaPalindrome => 'PDA - Palindrome';

  @override
  String get examplePdaAnB2n => 'PDA - a^n b^2n';

  @override
  String get examplePdaWHashReverseW => 'PDA - w#reverse(w)';

  @override
  String get exampleTmAnBn => 'TM - a^n b^n';

  @override
  String get exampleTmBinaryToUnary => 'TM - Binary to unary';

  @override
  String get exampleTmCopyString => 'TM - String copy';

  @override
  String get exampleTmBinaryIncrement => 'TM - Binary increment';

  @override
  String get exampleTmPalindromeChecker => 'TM - Palindrome checker';

  @override
  String get exampleRegexRepeatA => 'Regex - Repetition of A';

  @override
  String get exampleRegexEndsWithAb => 'Regex - Ends with AB';

  @override
  String get exampleRegexBinaryStarts0 => 'Regex - Binary starting with 0';

  @override
  String get exampleRegexPairsAbOrBa => 'Regex - AB or BA pairs';

  @override
  String get exampleRegexBlocksAb => 'Regex - Blocks of A and B';

  @override
  String failedToLoadExample(String error) {
    return 'Failed to load example: $error';
  }

  @override
  String exampleLoaded(String name) {
    return 'Example loaded: $name';
  }

  @override
  String copiedQuoted(String value) {
    return 'Copied: \"$value\"';
  }

  @override
  String startSymbolValue(String symbol) {
    return 'Start symbol: $symbol';
  }

  @override
  String nonterminalsValue(String symbols) {
    return 'Non-terminals: $symbols';
  }

  @override
  String terminalsValue(String symbols) {
    return 'Terminals: $symbols';
  }

  @override
  String productionsCountLabel(int count) {
    return 'Productions ($count):';
  }

  @override
  String pumpingLevelDifficulty(int level, String difficulty) {
    return 'Level $level - $difficulty';
  }

  @override
  String challengeNumber(int number) {
    return 'Challenge $number';
  }

  @override
  String languageLabelValue(String language) {
    return 'Language: $language';
  }

  @override
  String streakBonus(int points) {
    return 'Streak bonus! +$points points';
  }

  @override
  String levelLabelValue(String level) {
    return 'Level: $level';
  }

  @override
  String challengeFallback(String id) {
    return 'Challenge $id';
  }

  @override
  String productionRulesCount(int count) {
    return 'Production Rules ($count)';
  }

  @override
  String ruleNumber(int number) {
    return 'Rule $number';
  }

  @override
  String sampleStringsGeneratedCount(int count) {
    return '$count sample string(s) generated';
  }

  @override
  String get acceptsEpsilon => 'Accepts ε';

  @override
  String shortestSample(String value) {
    return 'Shortest: \"$value\"';
  }

  @override
  String get complexityMetrics => 'Complexity Metrics';

  @override
  String get complexityScore => 'Complexity Score';

  @override
  String get starHeightDescription =>
      'Maximum nesting of Kleene star operators (*)';

  @override
  String get nestingDepthDescription => 'Maximum depth of parentheses nesting';

  @override
  String get complexityScoreDescription =>
      'Weighted sum of all complexity factors';

  @override
  String get operatorBreakdown => 'Operator Breakdown';

  @override
  String get alphabetLabel => 'Alphabet';

  @override
  String alphabetSizeCount(int count) {
    return 'Size: $count symbol(s)';
  }

  @override
  String get emptyAlphabetExpression =>
      'Empty alphabet (epsilon-only expression)';

  @override
  String get nestingShort => 'Nesting';

  @override
  String get complexitySimple => 'Simple';

  @override
  String get complexityModerate => 'Moderate';

  @override
  String get complexityComplex => 'Complex';

  @override
  String get complexitySimpleDescription =>
      'Easy to understand, low computational cost';

  @override
  String get complexityModerateDescription =>
      'Moderate complexity, some analysis required';

  @override
  String get complexityComplexDescription =>
      'High complexity, careful analysis recommended';

  @override
  String get tmOverviewTitle => 'Turing Machine Overview';

  @override
  String get tmOverviewBody =>
      'Monitor the structure of your machine and resolve issues before running simulations or algorithms.';

  @override
  String get tmBlockLibraryTitle => 'Building block library';

  @override
  String get tmBlockLibraryDescription =>
      'Reuse typed submachines with shared tapes and explicit call and return behavior.';

  @override
  String get tmBlockLibraryEmpty => 'No reusable blocks yet.';

  @override
  String get tmBlockCreate => 'Create block';

  @override
  String get tmBlockCreateTitle => 'Create a building block';

  @override
  String get tmBlockRenameTitle => 'Rename building block';

  @override
  String get tmBlockNameLabel => 'Block name';

  @override
  String get tmBlockOpen => 'Open block';

  @override
  String get tmBlockInsert => 'Insert on root canvas';

  @override
  String get tmBlockRename => 'Rename';

  @override
  String get tmBlockDuplicate => 'Duplicate';

  @override
  String get tmBlockDeleteReferencedTitle => 'Block is in use';

  @override
  String get tmBlockDeleteReferencedMessage =>
      'Deleting this block will convert every invocation node to an ordinary state. Transitions are preserved.';

  @override
  String get tmBlockDetachAndDelete => 'Detach and delete';

  @override
  String get tmBlockSharedTapeNotice =>
      'Calls share every tape and head position. Internal final states are ignored; a block returns when it halts.';

  @override
  String get tmBlockRootBreadcrumb => 'Root machine';

  @override
  String get tmBlockValid => 'Valid';

  @override
  String get tmBlockInvalid => 'Needs attention';

  @override
  String tmBlockRevision(int revision) {
    return 'Revision $revision';
  }

  @override
  String tmBlockMachineSummary(int states, int transitions) {
    return '$states states, $transitions transitions';
  }

  @override
  String get canvasManageBlocksAction => 'Building blocks';

  @override
  String get canvasManageBlocksHint =>
      'Open the reusable Turing machine block library';

  @override
  String get tapeSymbols => 'Tape Symbols';

  @override
  String get tmTapeCount => 'Tape count';

  @override
  String get tmDocumentVariant => 'Variant';

  @override
  String get tmDocumentVariantSingleTape => 'Single tape';

  @override
  String get tmDocumentVariantMultiTape => 'Multiple tapes';

  @override
  String get tmDocumentVariantBuildingBlocks => 'Building blocks';

  @override
  String get tmDecreaseTapeCount => 'Decrease tape count';

  @override
  String get tmIncreaseTapeCount => 'Increase tape count';

  @override
  String get tmTapeCountShrinkBlocked =>
      'Clear nonblank operations on the removed tapes before reducing the tape count.';

  @override
  String get moveDirections => 'Move Directions';

  @override
  String get simulationReady => 'Simulation Ready';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get nondeterministicTransitions => 'Nondeterministic Transitions';

  @override
  String get resolveNondeterminism =>
      'Resolve nondeterminism before running deterministic algorithms.';

  @override
  String editCell(int index) {
    return 'Edit Cell $index';
  }

  @override
  String get tapeAlphabetLabel => 'Tape Alphabet:';

  @override
  String get symbolLabel => 'Symbol';

  @override
  String get enterASymbol => 'Enter a symbol';

  @override
  String tapeHead(int position) {
    return 'Tape (Head: $position)';
  }

  @override
  String tapeCellSemantics(int index) {
    return 'Tape cell $index';
  }

  @override
  String tapeCellSymbolValue(String symbol) {
    return 'Symbol $symbol';
  }

  @override
  String tapeCellBlankValue(String symbol) {
    return 'Blank symbol $symbol';
  }

  @override
  String get tapeCellHeadState => 'under the tape head';

  @override
  String get tapeCellReadState => 'read in the last operation';

  @override
  String get tapeCellWrittenState => 'written in the last operation';

  @override
  String get tapeCellEditHint => 'Opens symbol editing for this tape cell.';

  @override
  String emptyTape(String symbol) {
    return 'Empty (□: $symbol)';
  }

  @override
  String get directionLeft => 'Left (L)';

  @override
  String get directionRight => 'Right (R)';

  @override
  String get directionStay => 'Stay (S)';

  @override
  String get egInitialStack => 'e.g., Z';

  @override
  String get currentStackState => 'Current Stack State';

  @override
  String get emptyParen => '(empty)';

  @override
  String highlightingStackCell(int index) {
    return 'Highlighting stack cell $index (from bottom)';
  }

  @override
  String get remainingInputColon => 'Remaining Input:';

  @override
  String get simulationFailed => 'Simulation failed';

  @override
  String timeMs(int ms) {
    return 'Time: $ms ms';
  }

  @override
  String durationMillisecondsValue(String value) {
    return '$value ms';
  }

  @override
  String get simulationSteps => 'Simulation Steps:';

  @override
  String get pleaseEnterInitialStackSymbol =>
      'Please enter an initial stack symbol';

  @override
  String get createPdaBeforeSimulating =>
      'Create a PDA on the canvas before simulating.';

  @override
  String get simulationCancelled => 'Simulation cancelled';

  @override
  String get pdaExamplesHint =>
      'Examples: aabb (for balanced parentheses), abab (for palindromes)';

  @override
  String stackCount(int count) {
    return 'Stack ($count)';
  }

  @override
  String emptyStack(String symbol) {
    return 'Empty\n(Z₀: $symbol)';
  }

  @override
  String stackCellSemantics(int position, int size) {
    return 'Stack cell $position of $size';
  }

  @override
  String stackCellSymbol(String symbol) {
    return 'symbol $symbol';
  }

  @override
  String get topOfStack => 'top of stack';

  @override
  String get highlighted => 'highlighted';

  @override
  String get beingRemoved => 'being removed';

  @override
  String get stackCellHintHighlight =>
      'Double tap to highlight this stack cell. Swipe right to highlight it.';

  @override
  String get stackCellHintClear =>
      'Double tap to clear the highlight. Swipe left to unhighlight this stack cell.';

  @override
  String get clearStack => 'Clear stack';

  @override
  String get clearStackHint => 'Removes every symbol from the stack view.';

  @override
  String overflowMax(int max) {
    return 'Overflow!\nMax: $max';
  }

  @override
  String get underflowPopOnEmpty => 'Underflow!\nPop on empty';

  @override
  String get topLabel => 'Top: ';

  @override
  String sizeLabel(int size) {
    return 'Size: $size';
  }

  @override
  String opLabel(String operation) {
    return 'Op: $operation';
  }

  @override
  String get topBadge => 'TOP';

  @override
  String get operationPreview => 'Operation Preview';

  @override
  String get pop => 'Pop';

  @override
  String get push => 'Push';

  @override
  String get emptyStackParen => '(empty stack)';

  @override
  String get inputLabel => 'Input';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Next';

  @override
  String get resetToFirstStep => 'Reset to First Step';

  @override
  String get firstStep => 'First step';

  @override
  String get lastStep => 'Last step';

  @override
  String stepNumberLabel(int number) {
    return 'Step $number';
  }

  @override
  String get determinismAnalysis => 'Determinism Analysis';

  @override
  String get typeLabel => 'Type: ';

  @override
  String get dfaHelpMessage =>
      'Deterministic Finite Automaton - each state has at most one transition per symbol';

  @override
  String get epsilonNfaHelpMessage =>
      'Nondeterministic Finite Automaton with ε-transitions';

  @override
  String get nfaHelpMessage =>
      'Nondeterministic Finite Automaton - some states have multiple transitions for the same symbol';

  @override
  String get hasEpsilonTransitions => 'Has ε (epsilon) transitions';

  @override
  String get nondeterministicStates => 'Nondeterministic states:';

  @override
  String get symbolsWithMultipleTransitions =>
      'Symbols with multiple transitions:';

  @override
  String get allTransitionsDeterministic => 'All transitions are deterministic';

  @override
  String get parser => 'Parser';

  @override
  String get editGrammar => 'Edit Grammar';

  @override
  String get transformationSteps => 'Transformation steps';

  @override
  String get applyGrammarStep => 'Apply the grammar produced by this step.';

  @override
  String get apply => 'Apply';

  @override
  String get noProductions => '(no productions)';

  @override
  String get beforeAfter => 'Before / After';

  @override
  String challengesCompleted(int completed, int total) {
    return '$completed / $total challenges completed';
  }

  @override
  String get score => 'Score';

  @override
  String get completeSomeChallengesHint =>
      'Complete some challenges to see your progress here';

  @override
  String get correctShort => 'Correct';

  @override
  String get equivalent => 'EQUIVALENT';

  @override
  String get notEquivalent => 'NOT EQUIVALENT';

  @override
  String get automatonA => 'Automaton A';

  @override
  String get automatonB => 'Automaton B';

  @override
  String get distinguishingStringFound => 'Distinguishing String Found';

  @override
  String get emptyStringEpsilon => 'ε (empty string)';

  @override
  String get distinguishingStringExplanation =>
      'This string is accepted by one automaton but rejected by the other, proving that the two automata recognize different languages.';

  @override
  String get statesA => 'States (A)';

  @override
  String get statesB => 'States (B)';

  @override
  String get transitionsA => 'Transitions (A)';

  @override
  String get transitionsB => 'Transitions (B)';

  @override
  String get productAutomaton => 'Product Automaton';

  @override
  String get optional => 'Optional';

  @override
  String get algorithmSteps => 'Algorithm Steps';

  @override
  String stepsCount(int count) {
    return '$count steps';
  }

  @override
  String stepNavigationPosition(int current, int total) {
    return '$current / $total';
  }

  @override
  String get collapseSidebar => 'Collapse Sidebar';

  @override
  String get info => 'Info';

  @override
  String get untitledAutomaton => 'Untitled Automaton';

  @override
  String get canvasPda => 'Canvas PDA';

  @override
  String get canvasTm => 'Canvas TM';

  @override
  String get automatonHasNoStates => 'Automaton has no states';

  @override
  String get cannotSimulateEmptyAutomaton => 'Cannot simulate empty automaton';

  @override
  String get pdaHasNoStates => 'PDA has no states';

  @override
  String get tmHasNoStates => 'TM has no states';

  @override
  String get automatonMustHaveAtLeastOneState =>
      'Automaton must have at least one state';

  @override
  String get cannotConvertEmptyAutomatonToRegex =>
      'Cannot convert empty automaton to regex';

  @override
  String get faMustHaveAtLeastOneState => 'FA must have at least one state';

  @override
  String get nfaMustHaveAtLeastOneState => 'NFA must have at least one state';

  @override
  String get dfaMustHaveAtLeastOneState => 'DFA must have at least one state';

  @override
  String get pdaMustHaveAtLeastOneState => 'PDA must have at least one state';

  @override
  String get tmMustHaveAtLeastOneState =>
      'Turing machine must have at least one state';

  @override
  String get tmMustHaveAtLeastOneStatePeriod =>
      'Turing machine must have at least one state.';

  @override
  String get automatonAMustHaveAtLeastOneState =>
      'Automaton A must have at least one state';

  @override
  String get automatonBMustHaveAtLeastOneState =>
      'Automaton B must have at least one state';

  @override
  String get cannotCreateGameWithEmptyAutomaton =>
      'Cannot create game with empty automaton';

  @override
  String get nfaToDfaTitle => 'NFA to DFA';

  @override
  String get nfaToDfaDescription =>
      'Convert non-deterministic to deterministic automaton';

  @override
  String get removeLambdaTitle => 'Remove ε-transitions';

  @override
  String get removeLambdaDescription =>
      'Eliminate epsilon transitions from the automaton';

  @override
  String get minimizeDfaTitle => 'Minimize DFA';

  @override
  String get minimizeDfaDescription =>
      'Minimize deterministic finite automaton';

  @override
  String get completeDfaTitle => 'Complete DFA';

  @override
  String get completeDfaDescription => 'Add trap state to make DFA complete';

  @override
  String get complementDfaTitle => 'Complement DFA';

  @override
  String get complementDfaDescription =>
      'Flip accepting states after completion';

  @override
  String get unionOfDfasTitle => 'Union of DFAs';

  @override
  String get unionOfDfasDescription =>
      'Combine this DFA with another automaton from file';

  @override
  String get concatenationOfFsasTitle => 'Concatenation of FSAs';

  @override
  String get concatenationOfFsasDescription =>
      'Append another automaton language using ε-transitions';

  @override
  String get kleeneStarTitle => 'Kleene Star';

  @override
  String get kleeneStarDescription =>
      'Accept zero or more repetitions of this FSA language';

  @override
  String get reverseFsaTitle => 'Reverse FSA';

  @override
  String get reverseFsaDescription =>
      'Accept the reverse of every word in this FSA language';

  @override
  String get intersectionOfDfasTitle => 'Intersection of DFAs';

  @override
  String get intersectionOfDfasDescription =>
      'Intersect this DFA with another automaton from file';

  @override
  String get differenceOfDfasTitle => 'Difference of DFAs';

  @override
  String get differenceOfDfasDescription =>
      'Compute the language difference with another DFA from file';

  @override
  String get prefixClosureTitle => 'Prefix Closure';

  @override
  String get prefixClosureDescription =>
      'Accept all prefixes of the DFA language';

  @override
  String get suffixClosureTitle => 'Suffix Closure';

  @override
  String get suffixClosureDescription =>
      'Accept all suffixes of the DFA language';

  @override
  String get faToRegexTitle => 'FA to Regex';

  @override
  String get faToRegexDescription =>
      'Convert finite automaton to regular expression';

  @override
  String get fsaToGrammarTitle => 'FSA to Grammar';

  @override
  String get fsaToGrammarDescription =>
      'Convert finite automaton to regular grammar';

  @override
  String get autoLayoutTitle => 'Auto Layout';

  @override
  String get autoLayoutDescription => 'Arrange states in a circle';

  @override
  String get automatonLayoutButtonSemantics => 'Arrange automaton states';

  @override
  String get automatonLayoutButtonHint =>
      'Preview deterministic graph layouts and transformations';

  @override
  String get automatonLayoutButtonTooltip => 'Arrange states';

  @override
  String get automatonLayoutCannotArrange => 'Cannot arrange states';

  @override
  String get automatonLayoutApplyFailed => 'The layout could not be applied.';

  @override
  String get automatonLayoutPreviewFailed => 'The layout preview failed.';

  @override
  String get automatonLayoutDocumentChanged =>
      'The document changed while the layout preview was open.';

  @override
  String get automatonLayoutAnnotationsChanged =>
      'Document annotations changed while the layout preview was open.';

  @override
  String get automatonLayoutChoosePreview =>
      'Choose a deterministic layout. Changes remain a preview until you apply them.';

  @override
  String get automatonLayoutLabel => 'Layout';

  @override
  String get automatonLayoutApplyTo => 'Apply to';

  @override
  String get automatonLayoutCircle => 'Circle';

  @override
  String get automatonLayoutTwoCircles => 'Two circles';

  @override
  String get automatonLayoutSpiral => 'Spiral';

  @override
  String get automatonLayoutHierarchical => 'Hierarchical';

  @override
  String get automatonLayoutSugiyama => 'Sugiyama layered';

  @override
  String get automatonLayoutPackComponents => 'Pack components';

  @override
  String get automatonLayoutSeededForce => 'Force-directed (seeded)';

  @override
  String get automatonLayoutSeededRandom => 'Random (seeded)';

  @override
  String get automatonLayoutReflectHorizontal => 'Reflect horizontally';

  @override
  String get automatonLayoutReflectVertical => 'Reflect vertically';

  @override
  String get automatonLayoutRotate90 => 'Rotate 90 degrees';

  @override
  String get automatonLayoutRotate180 => 'Rotate 180 degrees';

  @override
  String get automatonLayoutRotate270 => 'Rotate 270 degrees';

  @override
  String get automatonLayoutFitViewport => 'Fit to viewport';

  @override
  String get automatonLayoutFillViewport => 'Fill viewport';

  @override
  String get automatonLayoutRestoreSaved => 'Restore saved layout';

  @override
  String get automatonLayoutAllStates => 'All states';

  @override
  String get automatonLayoutSelectedComponent => 'Selected component';

  @override
  String get automatonLayoutSelectedStates => 'Selected states';

  @override
  String get automatonLayoutKeepSelected => 'Keep selected states in place';

  @override
  String get automatonLayoutRootState => 'Root state';

  @override
  String get automatonLayoutAutomatic => 'Automatic';

  @override
  String get automatonLayoutSeed => 'Seed';

  @override
  String get automatonLayoutSeedHelp =>
      'The same seed produces the same layout.';

  @override
  String get automatonLayoutTransformFreeNotes =>
      'Transform free notes with the graph';

  @override
  String get automatonLayoutAttachedNotesHelp =>
      'Attached notes always follow their state or transition.';

  @override
  String get automatonLayoutApply => 'Apply layout';

  @override
  String get automatonLayoutPreparingPreview => 'Preparing preview';

  @override
  String get automatonLayoutValidatingGraph => 'Validating graph';

  @override
  String get automatonLayoutComputing => 'Computing layout';

  @override
  String get automatonLayoutMeasuring => 'Measuring result';

  @override
  String get automatonLayoutComplete => 'Complete';

  @override
  String get automatonLayoutEmptyGraph => 'The graph has no nodes to lay out.';

  @override
  String get automatonLayoutInvalidTopology =>
      'Node and edge IDs must be non-empty and unique, and every edge endpoint must reference a node.';

  @override
  String get automatonLayoutInvalidPosition =>
      'Every input node position must be finite.';

  @override
  String get automatonLayoutInvalidBounds =>
      'Layout bounds and spacing must be finite and positive.';

  @override
  String get automatonLayoutCoordinatesClamped =>
      'Extreme layout coordinates were clamped to safe bounds.';

  @override
  String get automatonLayoutDenseGraph =>
      'This is a dense graph; crossing metrics are heuristic.';

  @override
  String get automatonLayoutSelectNode =>
      'Select at least one node for selected-node layout.';

  @override
  String get automatonLayoutSelectComponent =>
      'Select a node whose connected component will be laid out.';

  @override
  String get automatonLayoutNoRestore =>
      'No saved manual or previous layout is available to restore.';

  @override
  String get automatonLayoutCancelled =>
      'The layout computation was cancelled.';

  @override
  String automatonLayoutSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
      one: '1 selected',
    );
    return '$_temp0';
  }

  @override
  String automatonLayoutStateSpacing(int spacing) {
    return 'State spacing: $spacing';
  }

  @override
  String automatonLayoutLayerSpacing(int spacing) {
    return 'Layer spacing: $spacing';
  }

  @override
  String automatonLayoutForceIteration(int current, int total) {
    return 'Force iteration $current of $total';
  }

  @override
  String automatonLayoutProgressStatus(String stage, int percent) {
    return '$stage, $percent percent';
  }

  @override
  String automatonLayoutResultSummary(
    int nodeCount,
    int componentCount,
    int overlapCount,
    String crossingMeasurement,
    int edgeCrossingCount,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      nodeCount,
      locale: localeName,
      other: '$nodeCount states',
      one: '1 state',
    );
    String _temp1 = intl.Intl.pluralLogic(
      componentCount,
      locale: localeName,
      other: '$componentCount components',
      one: '1 component',
    );
    String _temp2 = intl.Intl.pluralLogic(
      overlapCount,
      locale: localeName,
      other: '$overlapCount overlaps',
      one: '1 overlap',
    );
    String _temp3 = intl.Intl.pluralLogic(
      edgeCrossingCount,
      locale: localeName,
      other: '$edgeCrossingCount edge crossings',
      one: '1 edge crossing',
    );
    String _temp4 = intl.Intl.selectLogic(crossingMeasurement, {
      'measured': '$_temp3',
      'notMeasured': 'edge crossings not measured',
      'other': 'edge crossings not measured',
    });
    return '$_temp0, $_temp1, $_temp2, $_temp4.';
  }

  @override
  String automatonLayoutArrangedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count states arranged. Undo restores the previous layout.',
      one: '1 state arranged. Undo restores the previous layout.',
    );
    return '$_temp0';
  }

  @override
  String automatonLayoutUnsupportedVersion(int version) {
    return 'Layout algorithm version $version is not supported.';
  }

  @override
  String automatonLayoutResourceLimit(
    int nodeCount,
    int maximumNodes,
    int edgeCount,
    int maximumEdges,
  ) {
    return 'The graph exceeds the configured layout limit ($nodeCount/$maximumNodes nodes, $edgeCount/$maximumEdges edges).';
  }

  @override
  String automatonLayoutNonFiniteCoordinate(String nodeId) {
    return 'Layout produced a non-finite coordinate for $nodeId.';
  }

  @override
  String automatonLayoutOverlapsRemain(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count possible node overlaps remain; review the preview before applying.',
      one:
          '1 possible node overlap remains; review the preview before applying.',
    );
    return '$_temp0';
  }

  @override
  String get compareEquivalenceDescription =>
      'Compare two DFAs for equivalence';

  @override
  String get clearAutomatonDescription => 'Clear current automaton';

  @override
  String get regexToNfaTitle => 'Regex to NFA';

  @override
  String get regexExampleHint => 'e.g., (a|b)*';

  @override
  String get convertToCnfTitle => 'Convert to CNF';

  @override
  String get convertToCnfDescription =>
      'Convert grammar to Chomsky Normal Form';

  @override
  String get convertToGnfTitle => 'Convert to GNF';

  @override
  String get convertToGnfDescription =>
      'Convert grammar to Greibach Normal Form';

  @override
  String get removeLeftRecursionTitle => 'Remove Left Recursion';

  @override
  String get removeLeftRecursionDescription =>
      'Eliminate direct and indirect left recursion';

  @override
  String get leftFactorTitle => 'Left Factor';

  @override
  String get leftFactorDescription => 'Apply left factoring to grammar';

  @override
  String get findFirstSetsTitle => 'Find First Sets';

  @override
  String get findFirstSetsDescription =>
      'Calculate FIRST sets for all variables';

  @override
  String get findFollowSetsTitle => 'Find Follow Sets';

  @override
  String get findFollowSetsDescription =>
      'Calculate FOLLOW sets for all variables';

  @override
  String get buildParseTableTitle => 'Build Parse Table';

  @override
  String get buildParseTableDescription =>
      'Generate an LL(1) predictive parse table';

  @override
  String get checkAmbiguityTitle => 'Check Ambiguity';

  @override
  String get checkAmbiguityDescription => 'Detect if grammar is ambiguous';

  @override
  String get convertRightLinearToFsaTitle =>
      'Convert Right-Linear Grammar to FSA';

  @override
  String get convertRightLinearToFsaDescription =>
      'Build an FSA from a right-linear grammar';

  @override
  String get convertGrammarToPdaGeneralTitle =>
      'Convert Grammar to PDA (General)';

  @override
  String get convertGrammarToPdaGeneralDescription =>
      'Build an equivalent PDA from the grammar';

  @override
  String get convertGrammarToPdaStandardTitle =>
      'Convert Grammar to PDA (Standard)';

  @override
  String get convertGrammarToPdaStandardDescription =>
      'Build a standard-form PDA from the grammar';

  @override
  String get convertGrammarToPdaGreibachTitle =>
      'Convert Grammar to PDA (Greibach)';

  @override
  String get convertGrammarToPdaGreibachDescription =>
      'Build a Greibach-form PDA from the grammar';

  @override
  String get leftRecursionRemovalResultTitle =>
      'Direct and Indirect Left Recursion Removal';

  @override
  String get leftFactoringAnalysisTitle => 'Left Factoring Analysis';

  @override
  String get firstSetsAnalysisTitle => 'FIRST Sets Analysis';

  @override
  String get followSetsAnalysisTitle => 'FOLLOW Sets Analysis';

  @override
  String get cnfConversionTitle => 'Chomsky Normal Form (CNF) Conversion';

  @override
  String get gnfConversionTitle => 'Greibach Normal Form (GNF) Conversion';

  @override
  String get convertToCfgTitle => 'Convert to CFG';

  @override
  String get convertToCfgDescription =>
      'Convert PDA to equivalent context-free grammar';

  @override
  String get checkDeterminismTitle => 'Check Determinism';

  @override
  String get checkDeterminismDescription => 'Determine if PDA is deterministic';

  @override
  String get findReachableStatesTitle => 'Find Reachable States';

  @override
  String get findReachableStatesDescription =>
      'Identify reachable states from initial state';

  @override
  String get languageAnalysisTitle => 'Language Analysis';

  @override
  String get languageAnalysisDescription =>
      'Prove emptiness and find a shortest accepted word';

  @override
  String get stackOperationsTitle => 'Stack Operations';

  @override
  String get stackOperationsDescription => 'Analyze stack operations and depth';

  @override
  String get pdaIsDeterministic =>
      'Result: PDA is deterministic (no conflicting transitions).';

  @override
  String get pdaIsNondeterministic => 'Result: PDA is NON-deterministic.';

  @override
  String get conflictingTransitions => 'Conflicting transitions:';

  @override
  String lambdaTransitionsPresent(int count) {
    return 'ε-transitions present: $count';
  }

  @override
  String totalTransitionsCount(int count) {
    return 'Total transitions: $count';
  }

  @override
  String reachableStatesCount(int count) {
    return 'Reachable states ($count):';
  }

  @override
  String unreachableStatesCount(int count) {
    return 'Unreachable states ($count):';
  }

  @override
  String get languageIsEmptyProved => 'Language is empty (proved).';

  @override
  String get languageIsNonEmptyProved => 'Language is non-empty (proved).';

  @override
  String acceptanceModeLabel(String mode) {
    return 'Acceptance mode: $mode';
  }

  @override
  String get acceptanceModeFinalState => 'final state';

  @override
  String get acceptanceModeEmptyStack => 'empty stack';

  @override
  String get acceptanceModeBoth => 'final state and empty stack';

  @override
  String get pdaEmptinessProofLine =>
      'Proof: mode-aware PDA normalization → CFG productivity fixed point.';

  @override
  String productiveNonterminalsCount(int count) {
    return 'Productive nonterminals: $count';
  }

  @override
  String shortestWitness(String witness) {
    return 'Shortest witness: $witness';
  }

  @override
  String terminalSymbolLength(int length) {
    return 'Terminal-symbol length: $length (multi-character terminals count as one symbol).';
  }

  @override
  String get equalLengthShortlex =>
      'Equal-length ties use deterministic shortlex order.';

  @override
  String get leftmostCfgDerivation => 'Leftmost CFG derivation:';

  @override
  String moreDerivationSteps(int count) {
    return '  … $count more step(s)';
  }

  @override
  String emptinessProofUnavailable(String message) {
    return 'Emptiness proof unavailable: $message\nNo conclusion about language emptiness was made.';
  }

  @override
  String get createPdaToAnalyzeDeterminism =>
      'Create a PDA to analyze determinism.';

  @override
  String get createPdaToAnalyzeReachability =>
      'Create a PDA to analyze reachability.';

  @override
  String initialStateWithLabel(String label) {
    return 'Initial state: $label';
  }

  @override
  String initialStackSymbolWithValue(String symbol) {
    return 'Initial stack symbol: $symbol';
  }

  @override
  String get grammarAnalysisTitle => 'Grammar Analysis';

  @override
  String get classifyGrammarTitle => 'Classify grammar';

  @override
  String get classifyGrammarDescription =>
      'Infer the strongest structural class and show evidence for failed restrictions.';

  @override
  String get copyClassificationReport => 'Copy classification report';

  @override
  String get classificationReportCopied => 'Classification report copied.';

  @override
  String get updateDeclaredGrammarType => 'Update declared type';

  @override
  String get updateDeclaredGrammarTypeTitle => 'Update grammar metadata?';

  @override
  String updateDeclaredGrammarTypeMessage(String type) {
    return 'Change the declared type to $type? The productions will not change.';
  }

  @override
  String get grammarStructureNotLanguageClass =>
      'This result classifies the written grammar, not the minimal class of its language.';

  @override
  String get declaredGrammarType => 'Declared type';

  @override
  String get inferredGrammarType => 'Inferred type';

  @override
  String get pdaAnalysisTitle => 'PDA Analysis';

  @override
  String get noAnalysisResultsYet => 'No analysis results yet';

  @override
  String get selectAlgorithmToAnalyzePda =>
      'Select an algorithm above to analyze your PDA';

  @override
  String get selectAlgorithmToAnalyzeGrammar =>
      'Select an algorithm above to analyze your grammar';

  @override
  String get selectAlgorithmToAnalyzeTm =>
      'Select an algorithm above to analyze your TM.';

  @override
  String get addAtLeastOneProductionRule =>
      'Add at least one production rule to enable conversions.';

  @override
  String get convertingToFsa => 'Converting to FSA...';

  @override
  String get convertingToPda => 'Converting to PDA...';

  @override
  String get convertingStandard => 'Converting (Standard)...';

  @override
  String get convertingGreibach => 'Converting (Greibach)...';

  @override
  String get parseString => 'Parse String';

  @override
  String get noParseResultsYet => 'No parse results yet';

  @override
  String get enterAStringAndClickParse =>
      'Enter a string and click Parse to see results';

  @override
  String get terminationAndCyclesTitle => 'Termination and Cycles';

  @override
  String get terminationAndCyclesDescription =>
      'Classify one input under explicit execution limits';

  @override
  String get reachabilityTitle => 'Reachability';

  @override
  String get reachabilityDescription =>
      'Compare structural reachability with bounded witnesses';

  @override
  String get languageExplorerTitle => 'Language Explorer';

  @override
  String get languageExplorerDescription =>
      'Classify a bounded shortlex sample into four outcomes';

  @override
  String get tapeTraceTitle => 'Tape Trace';

  @override
  String get tapeTraceDescription =>
      'Measure operations on one concrete execution branch';

  @override
  String get timeProfileTitle => 'Time Profile';

  @override
  String get timeProfileDescription =>
      'Measure transition steps by input length within bounds';

  @override
  String get spaceProfileTitle => 'Space Profile';

  @override
  String get spaceProfileDescription =>
      'Measure bounded tape-cell usage by input length';

  @override
  String get determinismCheckTitle => 'Determinism Check';

  @override
  String get reachableStatesAnalysisTitle => 'Reachable States Analysis';

  @override
  String get pdaToCfgConversionTitle => 'PDA to CFG Conversion';

  @override
  String pdaConversionFailure(String error) {
    return 'Conversion failed: $error';
  }

  @override
  String get pdaConversionCanceledDocumentUnchanged =>
      'Conversion canceled. The editor PDA was not changed.';

  @override
  String get pdaConversionCanceledPanelClosed =>
      'Conversion canceled because the panel was closed.';

  @override
  String get pdaConversionCanceledEditorChanged =>
      'Conversion canceled because the editor PDA changed during review.';

  @override
  String pdaNormalizationAppliedSummary(
    int beforeStates,
    int afterStates,
    int beforeTransitions,
    int afterTransitions,
  ) {
    return 'Applied normalization: $beforeStates → $afterStates states, $beforeTransitions → $afterTransitions transitions.';
  }

  @override
  String pdaGeneratedGrammarSummary(int productions, int nonterminals) {
    return 'Generated grammar has $productions productions and $nonterminals non-terminals.';
  }

  @override
  String get pdaToCfgInvalidProductionLimit =>
      'The PDA to CFG production limit must be greater than zero.';

  @override
  String get pdaToCfgCancelled => 'PDA-to-CFG conversion was canceled.';

  @override
  String get pdaToCfgEmptyPda => 'Cannot convert an empty PDA to a grammar.';

  @override
  String get pdaToCfgMissingInitialState =>
      'PDA must define an initial state before conversion.';

  @override
  String get pdaToCfgInitialStateOutsideSet =>
      'The PDA initial state must belong to the PDA state set before conversion.';

  @override
  String get pdaToCfgMissingAcceptingState =>
      'PDA must have at least one accepting state for conversion.';

  @override
  String get pdaToCfgAcceptingStateOutsideSet =>
      'Every accepting state must belong to the PDA state set before conversion.';

  @override
  String pdaToCfgEpsilonPop(String transition) {
    return 'PDA-to-CFG conversion requires every transition to pop exactly one stack symbol. Transition $transition uses an ε-pop. Normalize the PDA before conversion.';
  }

  @override
  String pdaToCfgProductionLimit(int limit) {
    return 'PDA-to-CFG conversion stopped at the $limit production limit.';
  }

  @override
  String get pdaToCfgNoProductions =>
      'No productions could be generated for this PDA.';

  @override
  String get stackOperationsAnalysisTitle => 'Stack Operations Analysis';

  @override
  String get createPdaToAnalyzeLanguage =>
      'Create a PDA to analyze its language.';

  @override
  String get createPdaToInspectStack =>
      'Create a PDA to inspect stack operations.';

  @override
  String get shortestWitnessOpened =>
      'Shortest-witness trace opened in the Simulator panel.';

  @override
  String pushOperationsCount(int count) {
    return 'Push operations ($count):';
  }

  @override
  String popOperationsCount(int count) {
    return 'Pop operations ($count):';
  }

  @override
  String stackSymbolsTouched(int count) {
    return 'Stack symbols touched ($count):';
  }

  @override
  String get noneValue => '  None';

  @override
  String pdaTransitionsCount(int pdaCount, int fsaCount) {
    return 'PDA transitions: $pdaCount, FSA transitions: $fsaCount';
  }

  @override
  String analysisFailedPrefix(String error) {
    return 'Analysis failed: $error';
  }

  @override
  String errorRunningAnalysis(String error) {
    return 'Error running analysis: $error';
  }

  @override
  String get repeatedCycleTrace => 'Repeated cycle trace';

  @override
  String get relatedExecutionTrace => 'Related execution trace';

  @override
  String get noInputLengthGroupEvaluated =>
      'No input-length group was evaluated.';

  @override
  String get noCandidatesEvaluated => 'No candidates were evaluated.';

  @override
  String get noTraceRecordedBoundedRun =>
      'No trace was recorded for this bounded run.';

  @override
  String get maximumTransitionStepWitness => 'Maximum transition-step witness';

  @override
  String get maximumExplorationDepthWitness =>
      'Maximum exploration-depth witness';

  @override
  String get maximumExploredConfigurationsWitness =>
      'Maximum explored-configurations witness';

  @override
  String get noTmAvailableToAnalyze =>
      'No Turing machine available. Draw states and transitions on the canvas to analyze.';

  @override
  String retainedConfigurations(int count) {
    return '$count retained configuration(s)';
  }

  @override
  String get initialConfiguration => 'Initial configuration';

  @override
  String get grammarParserExamplesHint =>
      'Examples: aabb, abab, aabbb (for S → aSb | ab)';

  @override
  String get parsingEllipsis => 'Parsing...';

  @override
  String get derivationTree => 'Derivation Tree';

  @override
  String derivationTreesAmbiguous(int count) {
    return 'Derivation Trees (showing first $count; ambiguous)';
  }

  @override
  String get cykSteps => 'CYK Steps';

  @override
  String get expectedColon => 'Expected:';

  @override
  String get failedToParseString => 'Failed to parse string';

  @override
  String failedToParseStringError(String error) {
    return 'Failed to parse string: $error';
  }

  @override
  String executionTimeLabel(String time) {
    return 'Execution time: $time';
  }

  @override
  String farthestPositionLabel(int position, int length) {
    return 'Farthest position: $position / $length';
  }

  @override
  String get examplesLabel => 'Examples:';

  @override
  String get hintForNextTime => 'Hint for next time:';

  @override
  String get pngExportNotSupportedOnWeb =>
      'PNG export is not supported on web.';

  @override
  String get documentsDirectoryNotAvailableOnWeb =>
      'Documents directory is not available on web.';

  @override
  String get pumpingChallenge1Description => 'Strings of only a\'s';

  @override
  String get pumpingChallenge1Explanation =>
      'This language is regular. It can be recognized by a simple automaton that accepts any number of a\'s.';

  @override
  String get pumpingChallenge1Hint =>
      'Think about whether a finite state machine can recognize this pattern.';

  @override
  String get pumpingChallenge1Proof1 =>
      'This is a regular language because it follows a simple pattern.';

  @override
  String get pumpingChallenge1Proof2 =>
      'A finite automaton can accept this by having a single state that loops on \"a\".';

  @override
  String get pumpingChallenge1Proof3 =>
      'The pumping lemma condition is satisfied since we can always find strings that can be pumped.';

  @override
  String get pumpingChallenge1Proof4 =>
      'For any pumping length p, we can choose x = ε, y = a^k (1 ≤ k ≤ p), z = a^(n-k) for n ≥ k.';

  @override
  String get pumpingChallenge1Proof5 =>
      'Then xy^iz ∈ L for all i ≥ 0 because it\'s still just a\'s.';

  @override
  String get pumpingChallenge2Description =>
      'Strings with a\'s followed by b\'s';

  @override
  String get pumpingChallenge2Explanation =>
      'This language is regular. It can be recognized by an automaton that accepts any number of a\'s followed by any number of b\'s.';

  @override
  String get pumpingChallenge2Hint =>
      'Consider if this can be recognized by counting states or a simple state machine.';

  @override
  String get pumpingChallenge2Proof1 =>
      'This language is regular because the two parts (a\'s and b\'s) are independent.';

  @override
  String get pumpingChallenge2Proof2 =>
      'A finite automaton can track whether we\'ve seen any b\'s yet.';

  @override
  String get pumpingChallenge2Proof3 =>
      'Once a b is seen, only b\'s are accepted.';

  @override
  String get pumpingChallenge2Proof4 =>
      'The pumping lemma is satisfied because we can pump either the a\'s or b\'s independently.';

  @override
  String get pumpingChallenge3Description =>
      'Strings with equal number of a\'s and b\'s';

  @override
  String get pumpingChallenge3Explanation =>
      'This language is not regular. For any pumping length p, the string a^p b^p can be pumped, but pumping the a\'s will break the balance.';

  @override
  String get pumpingChallenge3Hint =>
      'Try applying the pumping lemma with p = 2. What happens when you pump?';

  @override
  String get pumpingChallenge3Proof1 =>
      'This is a classic non-regular language.';

  @override
  String get pumpingChallenge3Proof2 =>
      'The pumping lemma says: for any p ≥ 1, there exists a string s = xyz where |xy| ≤ p, |y| ≥ 1, and xy^iz ∈ L for all i ≥ 0.';

  @override
  String get pumpingChallenge3Proof3 =>
      'For s = a^p b^p, we can choose x = a^(p-1), y = a, z = b^p.';

  @override
  String get pumpingChallenge3Proof4 =>
      'Then xy^2z = a^(p+1) b^p, which has more a\'s than b\'s, so it\'s not in L.';

  @override
  String get pumpingChallenge3Proof5 =>
      'This shows that no finite automaton can recognize this language.';

  @override
  String get pumpingChallenge4Description =>
      'Strings with equal number of a\'s, b\'s, and c\'s';

  @override
  String get pumpingChallenge4Explanation =>
      'This language is not regular. It requires counting three different symbols, which cannot be done with finite memory.';

  @override
  String get pumpingChallenge4Hint =>
      'Think about how many independent counters this would require.';

  @override
  String get pumpingChallenge4Proof1 =>
      'This language requires tracking three independent counters.';

  @override
  String get pumpingChallenge4Proof2 =>
      'No finite state machine can keep track of three separate counts simultaneously.';

  @override
  String get pumpingChallenge4Proof3 =>
      'Using the pumping lemma: choose a string with p a\'s, p b\'s, and p c\'s.';

  @override
  String get pumpingChallenge4Proof4 =>
      'Pumping the a\'s will break the balance between a\'s, b\'s, and c\'s.';

  @override
  String get pumpingChallenge4Proof5 =>
      'For s = a^p b^p c^p, choose x = a^(p-1), y = a, z = b^p c^p.';

  @override
  String get pumpingChallenge4Proof6 =>
      'Then xy^2z = a^(p+1) b^p c^p ∉ L because p+1 ≠ p ≠ p.';

  @override
  String get pumpingChallenge5Description =>
      'Strings that are concatenations of a word with itself';

  @override
  String get pumpingChallenge5Explanation =>
      'This language is not regular. It requires remembering the first half of the string to match the second half, which requires unbounded memory.';

  @override
  String get pumpingChallenge5Hint =>
      'What happens if you choose a very long string and try to apply the pumping lemma?';

  @override
  String get pumpingChallenge5Proof1 =>
      'This language requires remembering the entire first half of the string.';

  @override
  String get pumpingChallenge5Proof2 =>
      'No matter how large the pumping length p is, we can choose w with length > p.';

  @override
  String get pumpingChallenge5Proof3 =>
      'For s = ww where |w| > p, the first half has length > p.';

  @override
  String get pumpingChallenge5Proof4 =>
      'The pumping lemma cannot find a suitable decomposition that preserves the property.';

  @override
  String get pumpingChallenge5Proof5 =>
      'This is the language of duplicated strings, not the language of palindromes; palindromes are strings equal to their reverse.';

  @override
  String get pumpingChallenge6Description => 'Strings with even number of a\'s';

  @override
  String get pumpingChallenge6Explanation =>
      'This language is regular. It can be recognized by a finite automaton that tracks parity (even/odd number of a\'s).';

  @override
  String get pumpingChallenge6Hint =>
      'Think about modulo 2 instead of exact counting.';

  @override
  String get pumpingChallenge6Proof1 => 'This is actually a regular language!';

  @override
  String get pumpingChallenge6Proof2 =>
      'A 2-state automaton can track whether we\'ve seen an even or odd number of a\'s.';

  @override
  String get pumpingChallenge6Proof3 =>
      'Start in an \"even\" state, go to \"odd\" state on each \"a\", and back to \"even\" on the next \"a\".';

  @override
  String get pumpingChallenge6Proof4 => 'Accept only in the \"even\" state.';

  @override
  String get pumpingChallenge6Proof5 =>
      'The key insight is that we only need to track parity, not the exact count.';

  @override
  String get pumpingChallenge7Description =>
      'Union of equal a\'s and b\'s with strings of only a\'s';

  @override
  String get pumpingChallenge7Explanation =>
      'This language is not regular, but that cannot be proved merely by pointing to a subset. A pumping-lemma or closure-property argument is required.';

  @override
  String get pumpingChallenge7Hint =>
      'Consider what happens when you try to apply the pumping lemma to strings from the a^n b^n part.';

  @override
  String get pumpingChallenge7Proof1 =>
      'This language contains both a non-regular part (a^n b^n) and a regular part (a^m).';

  @override
  String get pumpingChallenge7Proof2 =>
      'The union of a non-regular language with a regular language may or may not be regular.';

  @override
  String get pumpingChallenge7Proof3 =>
      'Finding a non-regular subset is not enough to prove the whole language is non-regular.';

  @override
  String get pumpingChallenge7Proof4 =>
      'A valid proof can use the pumping lemma directly on strings a^p b^p from the mixed language.';

  @override
  String get pumpingChallenge7Proof5 =>
      'For s = a^p b^p, the same counterexample as before applies.';

  @override
  String get pumpingChallenge8Description =>
      'Palindromes over the alphabet a,b';

  @override
  String get pumpingChallenge8Explanation =>
      'Palindromes are not regular because they require unbounded memory to verify symmetry.';

  @override
  String get pumpingChallenge8Hint =>
      'Think about what happens to the center when you pump a long palindrome.';

  @override
  String get pumpingChallenge8Proof1 =>
      'Palindromes require checking that the string reads the same forwards and backwards.';

  @override
  String get pumpingChallenge8Proof2 =>
      'For long palindromes, you need to remember the first half to compare with the second half.';

  @override
  String get pumpingChallenge8Proof3 =>
      'Using the pumping lemma: for s = a^p b a^p, choose x = a^(p-1), y = a, z = b a^p.';

  @override
  String get pumpingChallenge8Proof4 =>
      'Then xy^2z = a^(p+1) b a^p, which is not a palindrome.';

  @override
  String get pumpingChallenge8Proof5 =>
      'The middle b is no longer centered properly.';

  @override
  String get selectDfaForUnion => 'Select DFA for union';

  @override
  String get buildingUnionAutomaton => 'Building union automaton...';

  @override
  String get unionComplete => 'Union complete';

  @override
  String get loadDfaBeforeUnion => 'Load a DFA before computing the union.';

  @override
  String get selectFsaForConcatenation => 'Select FSA for concatenation';

  @override
  String get buildingConcatenationNfa => 'Building concatenation NFA...';

  @override
  String get concatenationComplete => 'Concatenation complete';

  @override
  String get selectDfaForIntersection => 'Select DFA for intersection';

  @override
  String get buildingIntersectionAutomaton =>
      'Building intersection automaton...';

  @override
  String get intersectionComplete => 'Intersection complete';

  @override
  String get loadDfaBeforeIntersection =>
      'Load a DFA before computing the intersection.';

  @override
  String get selectDfaForDifference => 'Select DFA for difference';

  @override
  String get buildingDifferenceAutomaton => 'Building difference automaton...';

  @override
  String get differenceComplete => 'Difference complete';

  @override
  String get loadDfaBeforeDifference =>
      'Load a DFA before computing the difference.';

  @override
  String loadDfaBeforeExecuting(String algorithm) {
    return 'Load a DFA before executing $algorithm.';
  }

  @override
  String get loadDfaBeforeComparingEquivalence =>
      'Load a DFA before comparing equivalence.';

  @override
  String get selectDfaToCompare => 'Select DFA to compare';

  @override
  String get loadingAutomatonEllipsis => 'Loading automaton...';

  @override
  String get failedToLoadAutomatonStatus => 'Failed to load automaton';

  @override
  String get selectedFileUnreadable =>
      'Selected file did not contain readable data.';

  @override
  String algorithmFailedStatus(String algorithm) {
    return '$algorithm failed';
  }

  @override
  String algorithmFailedError(String algorithm, String error) {
    return '$algorithm failed: $error';
  }

  @override
  String get comparingAutomata => 'Comparing automata...';

  @override
  String get languageComparisonTitle => 'Language Comparison';

  @override
  String get currentAutomatonTitle => 'Current Automaton';

  @override
  String get comparedAutomatonTitle => 'Compared Automaton';

  @override
  String get grammarConvertedToAutomaton =>
      'Grammar converted to automaton. Switched to FSA workspace.';

  @override
  String get grammarConvertedToPdaGeneral =>
      'Grammar converted to PDA (general). Switched to PDA workspace.';

  @override
  String get grammarConvertedToPdaStandard =>
      'Grammar converted to PDA (standard). Switched to PDA workspace.';

  @override
  String get grammarConvertedToPdaGreibach =>
      'Grammar converted to PDA (Greibach). Switched to PDA workspace.';

  @override
  String get failedToConvertGrammarToAutomaton =>
      'Failed to convert grammar to automaton.';

  @override
  String get failedToConvertGrammarToPda => 'Failed to convert grammar to PDA.';

  @override
  String get originalGrammarLabel => 'Original Grammar:';

  @override
  String get transformedGrammarLabel => 'Transformed Grammar:';

  @override
  String get notesSection => 'Notes';

  @override
  String get derivationsSection => 'Derivations';

  @override
  String get conflictsSection => 'Conflicts';

  @override
  String get cnfConversionNote =>
      'Converted grammar to Chomsky Normal Form (CNF) using a step pipeline.';

  @override
  String get cnfRulesNote =>
      'CNF rules: A→BC (two nonterminals) or A→a (single terminal).';

  @override
  String get gnfConversionNote =>
      'Converted grammar to Greibach Normal Form (GNF).';

  @override
  String get gnfRulesNote =>
      'GNF rules: A→aα (terminal followed by nonterminals).';

  @override
  String get diagnosticsHeading => 'Diagnostics:';

  @override
  String cannotRunDueToValidation(String algorithm) {
    return 'Cannot run $algorithm due to grammar validation errors';
  }

  @override
  String get ll1ParseTableAnalysis => 'LL(1) Parse Table Analysis';

  @override
  String get ll1NoConflicts => 'LL(1) (no conflicts)';

  @override
  String get notLl1Conflicts => 'Not LL(1) (conflicts)';

  @override
  String get ll1Classification => 'LL(1) Classification';

  @override
  String classificationLabel(String status) {
    return 'Classification: $status';
  }

  @override
  String get cnfConversionFailed => 'CNF conversion failed.';

  @override
  String scoreLabel(int score) {
    return 'Score: $score';
  }

  @override
  String streakLabel(int count) {
    return 'Streak: $count';
  }

  @override
  String challengeProgress(int current, int total) {
    return 'Challenge $current/$total';
  }

  @override
  String get finalScore => 'Final Score';

  @override
  String get learningProgress => 'Learning Progress:';

  @override
  String get regularLanguagesTitle => 'Regular Languages';

  @override
  String get regularLanguagesProgressDesc =>
      'You understand basic regular language patterns';

  @override
  String get pumpingLemmaApplicationTitle => 'Pumping Lemma Application';

  @override
  String get pumpingLemmaApplicationDesc =>
      'You can identify when languages are not regular';

  @override
  String get advancedPatternsTitle => 'Advanced Patterns';

  @override
  String get advancedPatternsProgressDesc =>
      'You recognize complex non-regular languages';

  @override
  String get pumpingPerformanceOutstanding =>
      'Outstanding! You have mastered the pumping lemma and can identify regular and non-regular languages with confidence. You understand the theoretical foundations and can apply the lemma correctly to prove non-regularity.';

  @override
  String get pumpingPerformanceExcellent =>
      'Excellent work! You have a strong understanding of the pumping lemma. You can correctly identify most regular and non-regular languages, and your application of the lemma is generally sound.';

  @override
  String get pumpingPerformanceGood =>
      'Good progress! You\'re developing a solid foundation in the pumping lemma. You can identify basic patterns and are learning to apply the lemma systematically. Keep practicing to strengthen your skills.';

  @override
  String get pumpingPerformanceFirstSteps =>
      'You\'re taking the first steps in understanding the pumping lemma. This is a challenging concept that requires practice. Focus on understanding the basic proof technique and identifying when languages require unbounded memory.';

  @override
  String get pumpingDifficultyEasy => 'EASY';

  @override
  String get pumpingDifficultyMedium => 'MEDIUM';

  @override
  String get pumpingDifficultyHard => 'HARD';

  @override
  String evaluatedOf(int evaluated, int total) {
    return 'Evaluated $evaluated of $total';
  }

  @override
  String get estimatedCandidatesInvalid =>
      'Estimated candidates: invalid limits';

  @override
  String estimatedCandidatesScheduled(String requested, String scheduled) {
    return 'Estimated candidates: $requested; scheduled: $scheduled';
  }

  @override
  String stepStateTitle(int step, String state) {
    return 'Step $step • $state';
  }

  @override
  String headTapeSubtitle(int head, String tape) {
    return 'head $head • tape $tape';
  }

  @override
  String initialConfigurationAtHead(int head) {
    return 'Initial configuration at head $head';
  }

  @override
  String inputRetainedConfigurations(String input, int count) {
    return 'Input $input • $count retained configuration(s)';
  }

  @override
  String get words => 'Words';

  @override
  String transitionsConfigurationsProgress(
    int transitions,
    int configurations,
  ) {
    return '$transitions transition(s) • $configurations configuration(s) explored';
  }

  @override
  String get explorationCancelledKept =>
      'Exploration cancelled. Evaluated results were kept.';

  @override
  String get spaceProfilingCancelledKept =>
      'Space profiling cancelled. Evaluated rows were kept.';

  @override
  String get interoperabilityImportReviewTitle => 'Review import';

  @override
  String get interoperabilityExportReviewTitle => 'Review export';

  @override
  String get interoperabilityReviewPrompt =>
      'Check the detected document and compatibility report before continuing.';

  @override
  String get interoperabilityFileLabel => 'File';

  @override
  String get interoperabilityTypeLabel => 'Type';

  @override
  String get interoperabilityFormatLabel => 'Format';

  @override
  String get interoperabilityVersionLabel => 'Version';

  @override
  String get interoperabilityFidelityLabel => 'Fidelity';

  @override
  String get interoperabilityFidelityExact => 'Exact';

  @override
  String get interoperabilityFidelityNormalized => 'Normalized';

  @override
  String get interoperabilityFidelityLossy => 'Data loss';

  @override
  String get interoperabilityChangesTitle => 'Field-level report';

  @override
  String get interoperabilityLossyImportWarning =>
      'Some source data cannot be represented and will be lost if you replace the current document.';

  @override
  String get interoperabilityLossyExportWarning =>
      'Some document data cannot be represented in this format and will be omitted from the exported file.';

  @override
  String get interoperabilityReplaceDocument => 'Replace document';

  @override
  String get interoperabilityExportDocument => 'Export file';

  @override
  String get interoperabilityImportWithLoss => 'Import with data loss';

  @override
  String get interoperabilityExportWithLoss => 'Export with data loss';

  @override
  String interoperabilityDiagnosticPath(String path) {
    return 'Path: $path';
  }

  @override
  String interoperabilityDiagnosticLineColumn(int line, int column) {
    return 'Line $line, column $column';
  }

  @override
  String interoperabilityDiagnosticLine(int line) {
    return 'Line $line';
  }

  @override
  String get interoperabilityDiagnosticPreserved => 'Field preserved';

  @override
  String get interoperabilityDiagnosticNormalized => 'Field normalized';

  @override
  String get interoperabilityDiagnosticDropped => 'Field omitted';

  @override
  String get interoperabilityDiagnosticSourceValueRecorded =>
      'Source value recorded but hidden for privacy';

  @override
  String interoperabilityDiagnosticTechnicalCode(String code) {
    return 'Diagnostic code: $code';
  }

  @override
  String get interoperabilityUnsupportedTitle => 'Document not supported';

  @override
  String get interoperabilityAmbiguousTitle => 'Document type is ambiguous';

  @override
  String get interoperabilityMalformedTitle => 'Document cannot be read';

  @override
  String get interoperabilityResourceLimitTitle =>
      'Document exceeds a safety limit';

  @override
  String get interoperabilityInternalFailureTitle =>
      'Document operation failed';

  @override
  String get interoperabilityUnsupportedDocument =>
      'No registered codec recognizes this document.';

  @override
  String interopRegistrySniffIdentityMismatch(String codec) {
    return 'Codec $codec reported document identity outside its registration.';
  }

  @override
  String interopRegistrySniffFailed(String codec) {
    return 'Codec $codec could not inspect the document.';
  }

  @override
  String interopRegistryDecodedIdentityMismatch(String codec) {
    return 'Codec $codec returned a document outside its registered identity.';
  }

  @override
  String interopRegistryDecodeFailed(String codec) {
    return 'Codec $codec could not decode the document.';
  }

  @override
  String interopRegistrySchemaIdentityUnregistered(
    String schema,
    String system,
  ) {
    return 'Schema $schema is not registered for $system.';
  }

  @override
  String interopRegistryExportRouteUnavailable(
    String system,
    String format,
    int schemaVersion,
  ) {
    return 'No codec can export $system as $format with schema version $schemaVersion.';
  }

  @override
  String interopRegistryExportSchemaUnavailable(int schemaVersion) {
    return 'No codec can export schema version $schemaVersion.';
  }

  @override
  String interopRegistryEncodedMetadataMismatch(String codec) {
    return 'Codec $codec returned file metadata outside its registered format.';
  }

  @override
  String interopRegistryEncodeFailed(String codec) {
    return 'Codec $codec could not encode the document.';
  }

  @override
  String get interoperabilityUnsupportedFeature =>
      'This document uses a feature that is not supported yet.';

  @override
  String get interoperabilityUnsupportedSchema =>
      'This document version is not supported.';

  @override
  String get interoperabilityUnsupportedFormat =>
      'This format is not supported for the current document.';

  @override
  String get interoperabilityUnsupportedDirection =>
      'This format does not support the requested import or export action.';

  @override
  String interoperabilityAmbiguousDescription(String codecIds) {
    return 'More than one codec matched: $codecIds';
  }

  @override
  String get interoperabilityMalformedSyntax =>
      'The document syntax is invalid or incomplete.';

  @override
  String get interoperabilityMalformedUtf8 =>
      'The document is not valid UTF-8 text.';

  @override
  String get interoperabilityMalformedMissingField =>
      'A required field is missing.';

  @override
  String get interoperabilityMalformedInvalidValue =>
      'A field contains an invalid value.';

  @override
  String get interoperabilityMalformedDuplicateIdentity =>
      'The document contains a duplicate identifier.';

  @override
  String interoperabilityResourceLimitDescription(
    String limit,
    int actual,
    int maximum,
  ) {
    return 'Safety limit $limit: found $actual; maximum $maximum.';
  }

  @override
  String get interoperabilityInternalFailureDescription =>
      'Turing Lab could not complete this document operation. The active document was not changed.';

  @override
  String interoperabilityDiagnosticOffset(int offset) {
    return 'Offset $offset';
  }

  @override
  String interoperabilityRoadmapIssue(int issue) {
    return 'View roadmap issue #$issue';
  }

  @override
  String get interoperabilityLimitBytes => 'file size';

  @override
  String get interoperabilityLimitXmlDepth => 'XML nesting depth';

  @override
  String get interoperabilityLimitXmlElements => 'XML element count';

  @override
  String get interoperabilityLimitXmlDtdOrEntity =>
      'XML DTD or external entity';

  @override
  String get interoperabilityLimitJsonDepth => 'JSON nesting depth';

  @override
  String get interoperabilityLimitCollectionEntries => 'collection entry count';

  @override
  String get interoperabilityImportDocument => 'Import document';

  @override
  String interoperabilityExportAs(String format) {
    return 'Export as $format';
  }

  @override
  String get interoperabilityImportSucceeded =>
      'Document imported successfully.';

  @override
  String get interoperabilityExportSucceeded =>
      'Document exported successfully.';

  @override
  String get interoperabilityOperationFailed =>
      'The document operation could not be completed.';

  @override
  String get interoperabilityFormatJflapXml => 'JFLAP XML';

  @override
  String get interoperabilityFormatTuringLabJson => 'Turing Lab JSON';

  @override
  String get interoperabilityActiveDocument => 'Active document';

  @override
  String get homeNavigationMealyLabel => 'Mealy';

  @override
  String get homeNavigationMealyDescription =>
      'Edit and simulate Mealy transducers.';

  @override
  String get homeNavigationMooreLabel => 'Moore';

  @override
  String get homeNavigationMooreDescription =>
      'Edit and simulate Moore transducers.';

  @override
  String get homeNavigationUnrestrictedGrammarLabel => 'Unrestricted grammar';

  @override
  String get homeNavigationUnrestrictedGrammarDescription =>
      'Classify phrase-structure grammars and explore bounded derivations.';

  @override
  String get homeNavigationLSystemLabel => 'L-system';

  @override
  String get homeNavigationLSystemDescription =>
      'Expand parallel rewrite systems and render turtle graphics.';

  @override
  String get transducerInputSymbol => 'Input symbol';

  @override
  String get transducerInputRequired => 'Enter one input symbol.';

  @override
  String get transducerInputOutsideAlphabet =>
      'Choose a symbol from the input alphabet.';

  @override
  String get transducerOutputOutsideAlphabet =>
      'Use only tokens from the output alphabet.';

  @override
  String get transducerDuplicateInput =>
      'This state already has a transition for that input.';

  @override
  String get transducerInvalidTransition =>
      'The transition is not valid for this machine.';

  @override
  String get transducerOutputTokens => 'Output tokens';

  @override
  String get transducerOutputTokensHint =>
      'One token per line. Leave blank for empty output.';

  @override
  String get transducerEmptyOutput => 'empty output';

  @override
  String transducerTransitionSemantics(String input, String output) {
    return 'Input $input; output $output';
  }

  @override
  String transducerInputOnlySemantics(String input) {
    return 'Input $input';
  }

  @override
  String transducerStateOutputSemantics(String output) {
    return 'State output $output';
  }

  @override
  String get transducerSimulationTitle => 'Transducer simulation';

  @override
  String get transducerInputTokens => 'Input tokens';

  @override
  String get transducerInputTokensHint => 'One input token per line';

  @override
  String get transducerRun => 'Run';

  @override
  String get transducerCancel => 'Cancel run';

  @override
  String get transducerMaximumSteps => 'Maximum steps';

  @override
  String get transducerMaximumStepsInvalid =>
      'Enter zero or a positive whole number.';

  @override
  String get transducerOutput => 'Output';

  @override
  String get transducerInvalidMachine =>
      'The machine is invalid. Fix the reported states or transitions.';

  @override
  String get transducerInvalidInput =>
      'The input contains a symbol outside the input alphabet.';

  @override
  String get transducerUndefinedTransition =>
      'No transition is defined for the next input symbol.';

  @override
  String get transducerSimulationCancelled => 'The simulation was cancelled.';

  @override
  String get transducerSimulationBounded =>
      'The simulation stopped at the configured step limit.';

  @override
  String transducerExecutionInvalidMachine(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'The machine is invalid: $count diagnostics need attention.',
      one: 'The machine is invalid: one diagnostic needs attention.',
      zero: 'The machine is invalid.',
    );
    return '$_temp0';
  }

  @override
  String transducerExecutionInvalidInputSymbol(String symbol) {
    return 'Input symbol \"$symbol\" is outside the input alphabet.';
  }

  @override
  String transducerExecutionTokenizationFailure(int offset) {
    return 'The input cannot be tokenized at offset $offset.';
  }

  @override
  String transducerExecutionUndefinedTransition(String state, String symbol) {
    return 'No transition is defined from state $state for input symbol \"$symbol\".';
  }

  @override
  String transducerExecutionCancelled(int processed) {
    String _temp0 = intl.Intl.pluralLogic(
      processed,
      locale: localeName,
      other: 'The simulation was cancelled after $processed input tokens.',
      one: 'The simulation was cancelled after one input token.',
      zero:
          'The simulation was cancelled before any input tokens were processed.',
    );
    return '$_temp0';
  }

  @override
  String transducerExecutionBounded(int limit, int processed) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: '$limit-step limit',
      one: 'one-step limit',
    );
    String _temp1 = intl.Intl.pluralLogic(
      processed,
      locale: localeName,
      other: '$processed input tokens',
      one: 'one input token',
      zero: 'no input tokens',
    );
    return 'The simulation stopped at the $_temp0 after processing $_temp1.';
  }

  @override
  String transducerExecutionSuccess(int processed, int outputCount) {
    String _temp0 = intl.Intl.pluralLogic(
      processed,
      locale: localeName,
      other: 'The simulation completed after $processed input tokens.',
      one: 'The simulation completed after one input token.',
      zero: 'The simulation completed without consuming input.',
    );
    String _temp1 = intl.Intl.pluralLogic(
      outputCount,
      locale: localeName,
      other: '$outputCount output tokens were produced.',
      one: 'One output token was produced.',
      zero: 'No output tokens were produced.',
    );
    return '$_temp0 $_temp1';
  }

  @override
  String get parserXmlMalformedDocument =>
      'The JFLAP XML document is malformed.';

  @override
  String get parserGrammarXmlMissingGrammarElement =>
      'The JFLAP file does not contain a grammar element.';

  @override
  String get parserGrammarXmlMissingStartElement =>
      'The JFLAP grammar does not declare a start symbol.';

  @override
  String get parserGrammarXmlEmptyStartElement =>
      'The JFLAP grammar has an empty start symbol.';

  @override
  String parserGrammarXmlInvalidStartCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count were found',
      one: 'one was found',
      zero: 'none were found',
    );
    return 'The JFLAP grammar must declare one start symbol, but $_temp0.';
  }

  @override
  String parserGrammarXmlIncompleteProduction(int index) {
    return 'The production at index $index must contain both left and right elements.';
  }

  @override
  String get parserJflapXmlMissingAutomatonElement =>
      'The JFLAP file does not contain an automaton element.';

  @override
  String get parserJflapXmlEmptyAutomaton =>
      'The JFLAP automaton has no states and cannot be loaded into the editor.';

  @override
  String parserJflapXmlIncompleteTransition(int index) {
    return 'The transition at index $index must contain origin and destination states.';
  }

  @override
  String parserJflapXmlUnknownTransitionEndpoints(
    String fromState,
    String toState,
  ) {
    return 'The transition from $fromState to $toState references an unknown state.';
  }

  @override
  String parserJflapXmlUnexpectedRootElement(String actual) {
    return 'The JFLAP document root must be structure, not $actual.';
  }

  @override
  String structuredMessageUnknown(String code) {
    return 'Message unavailable ($code).';
  }

  @override
  String get transducerNoTrace => 'No trace steps';

  @override
  String get transducerEmptyInput => 'empty input';

  @override
  String transducerRemainingInputPreview(String preview, int count) {
    return '$preview ($count tokens remaining)';
  }

  @override
  String transducerTraceStep(
    int step,
    String source,
    String target,
    String transition,
  ) {
    return 'Step $step: $source to $target with $transition';
  }

  @override
  String transducerTraceDetails(
    String consumed,
    String remaining,
    String emitted,
    String cumulative,
  ) {
    return 'Consumed $consumed; remaining $remaining; emitted $emitted; cumulative $cumulative';
  }

  @override
  String get transducerMachineInfo => 'Machine details';

  @override
  String get transducerMachineValid => 'Valid machine';

  @override
  String get transducerMachineInvalid => 'Invalid machine';

  @override
  String get transducerMachineDeterministic => 'Deterministic';

  @override
  String get transducerMachineNondeterministic => 'Nondeterministic';

  @override
  String get transducerMachineComplete => 'Complete transition function';

  @override
  String get transducerMachinePartial => 'Partial transition function';

  @override
  String get transducerAnalysisMissingInitialState =>
      'Choose one initial state.';

  @override
  String transducerAnalysisMultipleInitialStates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'The machine has $count initial states.',
      one: 'The machine has one initial state.',
    );
    return '$_temp0';
  }

  @override
  String transducerAnalysisDuplicateStateId(String state) {
    return 'State identifier $state is duplicated.';
  }

  @override
  String transducerAnalysisDuplicateTransitionId(String transition) {
    return 'Transition identifier $transition is duplicated.';
  }

  @override
  String transducerAnalysisDanglingSourceState(String transition) {
    return 'Transition $transition starts at a missing state.';
  }

  @override
  String transducerAnalysisDanglingTargetState(String transition) {
    return 'Transition $transition points to a missing state.';
  }

  @override
  String transducerAnalysisInputSymbolOutsideAlphabet(
    String transition,
    String symbol,
  ) {
    return 'Transition $transition uses input $symbol, which is outside the alphabet.';
  }

  @override
  String transducerAnalysisOutputSymbolOutsideAlphabet(
    String subject,
    String symbol,
  ) {
    return 'The output for $subject uses $symbol, which is outside the alphabet.';
  }

  @override
  String transducerAnalysisNondeterministicTransition(
    String state,
    String symbol,
  ) {
    return 'State $state has more than one transition for input $symbol.';
  }

  @override
  String transducerAnalysisIncompleteTransitionFunction(
    String state,
    String symbol,
  ) {
    return 'State $state has no unique transition for input $symbol.';
  }

  @override
  String transducerAnalysisEmptyIdentifier(String entity) {
    String _temp0 = intl.Intl.selectLogic(entity, {
      'machine': 'The machine identifier cannot be empty.',
      'state': 'A state identifier cannot be empty.',
      'transition': 'A transition identifier cannot be empty.',
      'other': 'An identifier cannot be empty.',
    });
    return '$_temp0';
  }

  @override
  String transducerAnalysisEmptyInputSymbol(String subject) {
    return 'The input symbol for $subject cannot be empty.';
  }

  @override
  String transducerAnalysisEmptyOutputSymbol(String subject) {
    return 'The output symbol for $subject cannot be empty.';
  }

  @override
  String transducerAnalysisNegativeRevision(int revision) {
    return 'Document revision $revision is invalid.';
  }

  @override
  String get transducerInputAlphabet => 'Input alphabet';

  @override
  String get transducerOutputAlphabet => 'Output alphabet';

  @override
  String get transducerAlphabetHint => 'One symbol per line';

  @override
  String get transducerApplyAlphabets => 'Apply alphabets';

  @override
  String get transducerEditTransition => 'Edit transducer transition';

  @override
  String get transducerDeleteTransition => 'Delete transition';

  @override
  String get transducerDeleteState => 'Delete state';

  @override
  String get transducerEditState => 'Edit transducer state';

  @override
  String get transducerStateName => 'State name';

  @override
  String get transducerInitialState => 'Initial state';

  @override
  String get transducerSave => 'Save';

  @override
  String get transducerExamples => 'Examples';

  @override
  String get transducerExamplesUnavailable =>
      'Examples are not available for this workspace.';

  @override
  String get transducerExamplesLoadFailed => 'Examples could not be loaded.';

  @override
  String get transducerExamplesEmpty => 'No examples are available yet.';

  @override
  String get mealyExampleIdentityName => 'Identity transducer';

  @override
  String get mealyExampleIdentityDescription =>
      'Emits each binary input symbol unchanged.';

  @override
  String get mealyExampleParityName => 'Parity output';

  @override
  String get mealyExampleParityDescription =>
      'Emits the parity after each binary input symbol.';

  @override
  String get mealyExampleSequenceName => 'Sequence detector';

  @override
  String get mealyExampleSequenceDescription =>
      'Emits 1 when the latest two symbols are ab.';

  @override
  String get mealyExamplePartialName => 'Partial transducer';

  @override
  String get mealyExamplePartialDescription =>
      'Stops when input b has no transition from the current state.';

  @override
  String get mooreExampleParityName => 'Parity state output';

  @override
  String get mooreExampleParityDescription =>
      'Reports even or odd parity from the current state.';

  @override
  String get mooreExampleVendingName => 'Vending control';

  @override
  String get mooreExampleVendingDescription =>
      'Reports whether the vending controller is ready.';

  @override
  String get mooreExampleSequenceName => 'Sequence detector';

  @override
  String get mooreExampleSequenceDescription =>
      'Reports when the latest input suffix matches 10.';

  @override
  String get mooreExamplePartialName => 'Partial Moore machine';

  @override
  String get mooreExamplePartialDescription =>
      'Demonstrates undefined input without treating it as invalid.';

  @override
  String exampleSuggestedSimulationLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Suggested simulations',
      one: 'Suggested simulation',
    );
    return '$_temp0';
  }

  @override
  String exampleSuggestedSimulationSemantics(int count, String inputs) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Suggested simulations: $inputs.',
      one: 'Suggested simulation: $inputs.',
    );
    return '$_temp0';
  }

  @override
  String get transducerBatch => 'Batch inputs';

  @override
  String get transducerBatchHint =>
      'One JSON token array per line, for example [\"a\",\"b\"]';

  @override
  String get transducerBatchInputLabel => 'Input token arrays';

  @override
  String get transducerBatchEmpty => 'No batch inputs were provided.';

  @override
  String get transducerBatchSuccess => 'Completed';

  @override
  String get transducerRunBatch => 'Run batch';

  @override
  String get transducerComparison => 'Compare outputs';

  @override
  String get transducerComparisonMode => 'Comparison mode';

  @override
  String get transducerComparisonExact => 'Exact';

  @override
  String get transducerComparisonBounded => 'Bounded';

  @override
  String get transducerComparisonBound => 'Maximum input length';

  @override
  String get transducerCompareWithExample => 'Compare with example';

  @override
  String get transducerCompare => 'Compare';

  @override
  String transducerComparisonResult(String result) {
    return 'Comparison result: $result';
  }

  @override
  String get transducerLoadExample => 'Load example';

  @override
  String get transducerNoComparisonMachine => 'Choose a second machine.';

  @override
  String get transducerExactEquivalent => 'Exactly equivalent';

  @override
  String get transducerExactDifferent => 'Different, with an exact witness';

  @override
  String get transducerBoundedDifferent =>
      'Different within the selected bound';

  @override
  String get transducerBoundedInconclusive =>
      'No difference found within the selected bound';

  @override
  String get transducerComparisonInvalid =>
      'The machines cannot be compared with this mode.';

  @override
  String get transducerLeftOutput => 'Current output';

  @override
  String get transducerRightOutput => 'Compared output';

  @override
  String get transducerWitness => 'Witness input';

  @override
  String transducerInvalidBatchLine(int line) {
    return 'Line $line must be a JSON array of strings.';
  }

  @override
  String transducerSelectedMachine(String name) {
    return 'Selected machine: $name';
  }

  @override
  String transducerExploredPairs(int count) {
    return 'Explored pairs: $count';
  }

  @override
  String get initializationErrorTitle => 'Turing Lab could not finish startup.';

  @override
  String get initializationErrorMessage =>
      'Restart the app. Local settings and trace persistence may be unavailable until initialization succeeds.';

  @override
  String get helpRelatedTopics => 'Related topics';

  @override
  String get helpTopicUnavailable => 'This help topic is not available.';

  @override
  String get helpTopicUnavailableDescription =>
      'Browse the help tree or search for another topic.';

  @override
  String get contextualHelpPanelLabel => 'Contextual help panel';

  @override
  String get closeHelpPanel => 'Close help panel';

  @override
  String get viewAllRelatedHelp => 'View all related help';

  @override
  String get moreHelp => 'More Help';

  @override
  String get helpCenter => 'Help Center';

  @override
  String get workspaceSimulateTooltip => 'Simulate';

  @override
  String get workspaceAlgorithmsTooltip => 'Algorithms';

  @override
  String get workspaceAlgorithmsAndExamplesTooltip => 'Algorithms & Examples';

  @override
  String get workspaceParserTooltip => 'Parser';

  @override
  String get workspaceEditTooltip => 'Edit';

  @override
  String get workspaceMetricsTooltip => 'Metrics';

  @override
  String get workspaceMoreActionsTooltip => 'More workspace actions';

  @override
  String get workspaceExamplesTooltip => 'Examples';

  @override
  String get workspaceExamplesLoadingTooltip => 'Loading examples';

  @override
  String get workspaceExamplesUnavailableTooltip => 'Examples unavailable';

  @override
  String get workspaceExamplesLoadFailed => 'Examples could not be loaded.';

  @override
  String get workspaceExamplesEmpty => 'No examples are available yet.';

  @override
  String get keyboardShortcutsDialogLabel => 'Keyboard shortcuts dialog';

  @override
  String get keyboardShortcutsTitle => 'Keyboard Shortcuts';

  @override
  String get keyboardShortcutsCanvasOperations => 'Canvas Operations';

  @override
  String get keyboardShortcutsSimulationControls => 'Simulation Controls';

  @override
  String get keyboardShortcutsDialogShortcuts => 'Dialog Shortcuts';

  @override
  String get closeShortcutsDialog => 'Close shortcuts dialog';

  @override
  String get shortcutAlternativeSeparator => 'or';

  @override
  String get aboutDeveloperLabel => 'Developer';

  @override
  String get aboutProjectRepositoryLabel => 'Project repository';

  @override
  String get aboutProjectOpenError => 'Could not open the project repository.';

  @override
  String get aboutOpenSourceLicenses => 'Open Source Licenses';

  @override
  String get aboutLicensesIntro =>
      'Turing Lab is a Flutter reimplementation inspired by and compatible with JFLAP. It is not an official JFLAP release.';

  @override
  String get aboutTuringLabLicenseSummary =>
      'Turing Lab original Flutter code is licensed under Apache 2.0.';

  @override
  String get aboutJflapLicenseSummary =>
      'JFLAP-derived portions remain under the JFLAP 7.1 License.';

  @override
  String get aboutGraphViewLicenseSummary =>
      'Graph visualization library, forked and modified for Turing Lab. Original work by Nabil Mosharraf.';

  @override
  String get aboutAppleNoticesSummary =>
      'Bundled notices for the vendored GraphView fork and Apple-platform plugin dependencies.';

  @override
  String get aboutAppleNoticesTitle => 'Apple Platform Third-Party Notices';

  @override
  String get aboutPackageLicenses => 'Package licenses';

  @override
  String get aboutPackageLicensesDescription =>
      'Licenses reported by Flutter for bundled Dart and Flutter packages.';

  @override
  String get aboutAcknowledgments => 'JFLAP Acknowledgments';

  @override
  String get aboutJflapCreator =>
      'Original JFLAP creator and maintainer, Duke University.';

  @override
  String get aboutJflapTeam =>
      'Thomas Finley, Ryan Cavalcante, Stephen Reading, Bart Bressler, Jinghui Lim, Chris Morgan, Kyung Min (Jason) Lee, Jonathan Su, and Henry Qin.';

  @override
  String get aboutOriginalProject => 'JFLAP website: http://www.jflap.org';

  @override
  String get aboutOriginalProjectTitle => 'Original Project';

  @override
  String get aboutGraphViewFork =>
      'Turing Lab vendors a maintained fork of GraphView under the MIT license; Apple-platform third-party notices are bundled here.';

  @override
  String get aboutGraphViewForkTitle => 'GraphView Fork';

  @override
  String get aboutDistribution => 'Distribution';

  @override
  String get aboutDistributionDescription =>
      'Turing Lab is distributed as a free, non-monetized educational app while it includes JFLAP-derived material.';

  @override
  String get aboutLicenseExpandPrompt => 'Expand to load bundled license text.';

  @override
  String get aboutLicenseLoading => 'Loading bundled license text...';

  @override
  String get aboutLicenseLoadFailed => 'Failed to load license. Try again.';

  @override
  String helpDisclosureExpandSemanticLabel(String title) {
    return 'Expand $title';
  }

  @override
  String helpDisclosureCollapseSemanticLabel(String title) {
    return 'Collapse $title';
  }

  @override
  String helpSearchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
      zero: '0 results',
    );
    return '$_temp0';
  }

  @override
  String helpTopicSemanticLabel(String title) {
    return 'Help topic: $title';
  }

  @override
  String showHelpFor(String title) {
    return 'Show help for $title';
  }

  @override
  String navigateTo(String label) {
    return 'Navigate to $label';
  }

  @override
  String workspaceSelectorLabel(String label) {
    return 'Workspace: $label';
  }

  @override
  String get workspaceSelectorHint => 'Switch workspace';

  @override
  String workspaceDockShowPanel(String label) {
    return 'Show $label';
  }

  @override
  String workspaceDockHidePanel(String label) {
    return 'Hide $label';
  }

  @override
  String get workspaceDockResizePanel => 'Resize panel';

  @override
  String unableToLoadHelp(String category) {
    return 'Unable to load help for \"$category\".';
  }

  @override
  String noHelpItemsFound(String category) {
    return 'No help items found for \"$category\".';
  }

  @override
  String get includeNotesInVisualExports => 'Include notes in visual exports';

  @override
  String get includeNotesInVisualExportsDescription =>
      'Applies to SVG and PNG. Document exports always preserve notes.';

  @override
  String get documentNotesTitle => 'Document notes';

  @override
  String get documentNotesDescription => 'Non-semantic notes and annotations';

  @override
  String get documentNoteUndo => 'Undo note change';

  @override
  String get documentNoteRedo => 'Redo note change';

  @override
  String get documentNoteAdd => 'Add note';

  @override
  String get documentNoteSearch => 'Search notes';

  @override
  String get documentNoteNoMatches => 'No matching notes.';

  @override
  String get documentNoteEmpty => 'Empty note';

  @override
  String get documentNoteFree => 'Free note';

  @override
  String documentNoteAttachment(String type, String target) {
    return '$type: $target';
  }

  @override
  String get documentNoteActions => 'Note actions';

  @override
  String get documentNoteDuplicate => 'Duplicate';

  @override
  String get documentNoteDeleteTitle => 'Delete note?';

  @override
  String get documentNoteDeleteMessage =>
      'This removes the note from this document.';

  @override
  String documentNoteSemantics(String text) {
    return 'Note: $text';
  }

  @override
  String get documentNoteKeyboardHint =>
      'Press Enter to edit. Control D duplicates. Control C collapses.';

  @override
  String get documentNoteExpand => 'Expand note';

  @override
  String get documentNoteCollapse => 'Collapse note';

  @override
  String get documentNoteResize => 'Resize note';

  @override
  String get documentNoteEditTitle => 'Edit note';

  @override
  String get documentNoteTextLabel => 'Note text';

  @override
  String get documentNoteTextHelp =>
      'Use **bold**, _italic_, or `code`. Links and HTML are not interpreted.';

  @override
  String get documentNoteStyleLabel => 'Style';

  @override
  String get documentNoteAttachmentLabel => 'Attachment';

  @override
  String get documentNoteNoAttachment => 'None';

  @override
  String get documentNoteTargetIdLabel => 'Target ID';

  @override
  String get documentNoteStyleNote => 'Note';

  @override
  String get documentNoteStyleInformation => 'Information';

  @override
  String get documentNoteStyleWarning => 'Warning';

  @override
  String get documentNoteStyleQuestion => 'Question';

  @override
  String get documentNoteStyleTodo => 'To do';

  @override
  String get documentNoteTargetCanvas => 'Canvas';

  @override
  String get documentNoteTargetState => 'State';

  @override
  String get documentNoteTargetTransition => 'Transition';

  @override
  String get documentNoteTargetProduction => 'Production';

  @override
  String get documentNoteTargetTableCell => 'Table cell';

  @override
  String get automatonFragmentFilePickerTitle => 'Import compatible automaton';

  @override
  String get automatonFragmentUnreadableFile =>
      'The selected file could not be read.';

  @override
  String automatonFragmentImportedSummary(int states, int transitions) {
    String _temp0 = intl.Intl.pluralLogic(
      states,
      locale: localeName,
      other: '$states states',
      one: '1 state',
    );
    String _temp1 = intl.Intl.pluralLogic(
      transitions,
      locale: localeName,
      other: '$transitions transitions',
      one: '1 transition',
    );
    return 'Imported $_temp0 and $_temp1.';
  }

  @override
  String automatonFragmentImportFailed(String error) {
    return 'Automaton import failed: $error';
  }

  @override
  String get automatonFragmentCannotImport => 'Cannot import automaton';

  @override
  String get automatonFragmentPreviewTitle => 'Preview automaton import';

  @override
  String automatonFragmentSourceFidelity(String fidelity) {
    return 'Source fidelity: $fidelity. The source and destination remain unchanged until Apply.';
  }

  @override
  String get automatonFragmentStatesToImport => 'States to import';

  @override
  String get automatonFragmentInsertionAnchor => 'Insertion anchor';

  @override
  String get automatonFragmentInitialStateAfterImport =>
      'Initial state after import';

  @override
  String get automatonFragmentKeepCurrentInitialState =>
      'Keep current initial state';

  @override
  String get automatonFragmentUseImportedInitialState =>
      'Use imported initial state';

  @override
  String get automatonFragmentUseDestinationAcceptance =>
      'Use the destination PDA acceptance mode';

  @override
  String get automatonFragmentSourceModeDiffers =>
      'Required because the source mode differs.';

  @override
  String get automatonFragmentUseDestinationStackSymbol =>
      'Use the destination initial stack symbol';

  @override
  String get automatonFragmentSourceSymbolDiffers =>
      'Required because the source symbol differs.';

  @override
  String get automatonFragmentExactChanges => 'Exact changes';

  @override
  String automatonFragmentCloneSummary(
    int states,
    int transitions,
    int notes,
    int blocks,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      states,
      locale: localeName,
      other: '$states states',
      one: '1 state',
    );
    String _temp1 = intl.Intl.pluralLogic(
      transitions,
      locale: localeName,
      other: '$transitions transitions',
      one: '1 transition',
    );
    String _temp2 = intl.Intl.pluralLogic(
      notes,
      locale: localeName,
      other: '$notes notes',
      one: '1 note',
    );
    String _temp3 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks reusable blocks',
      one: '1 reusable block',
    );
    return '$_temp0, $_temp1, $_temp2, and $_temp3 will be cloned.';
  }

  @override
  String get automatonFragmentStructuralImportExplanation =>
      'This is a disconnected structural import. Algebraic operations and opening or replacing documents remain separate workflows.';

  @override
  String get automatonFragmentInputAlphabet => 'Input alphabet';

  @override
  String get automatonFragmentOutputAlphabet => 'Output alphabet';

  @override
  String get automatonFragmentStackAlphabet => 'Stack alphabet';

  @override
  String get automatonFragmentTapeAlphabet => 'Tape alphabet';

  @override
  String automatonFragmentAcceptanceModeUnchanged(String mode) {
    return 'Acceptance mode remains $mode.';
  }

  @override
  String automatonFragmentInitialStackSymbolUnchanged(String symbol) {
    return 'Initial stack symbol remains $symbol.';
  }

  @override
  String automatonFragmentTapeConfigurationUnchanged(int count, String symbol) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tapes',
      one: '1 tape',
    );
    return 'Tape configuration remains $_temp0 with blank symbol $symbol.';
  }

  @override
  String automatonFragmentInitialStateUnchanged(String state) {
    return 'Initial state remains $state.';
  }

  @override
  String automatonFragmentInitialStateChanged(String before, String after) {
    return 'Initial state changes from $before to $after.';
  }

  @override
  String get automatonFragmentUnset => 'unset';

  @override
  String automatonFragmentSetUnchanged(String label) {
    return '$label is unchanged.';
  }

  @override
  String automatonFragmentSetAdds(String label, String symbols) {
    return '$label adds: $symbols.';
  }

  @override
  String get unknownError => 'Unknown error';

  @override
  String get fileReadFailed => 'File read failed.';

  @override
  String get selectedFileBytesUnavailable =>
      'Selected file bytes are unavailable.';

  @override
  String get attachedNotesTitle => 'Attached notes';

  @override
  String attachedNotesStateDeletionMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count notes are attached to this state or its incident transitions. Choose what happens before deletion.',
      one:
          '1 note is attached to this state or one of its incident transitions. Choose what happens before deletion.',
    );
    return '$_temp0';
  }

  @override
  String attachedNotesTransitionDeletionMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count notes are attached to this transition. Choose what happens before deletion.',
      one:
          '1 note is attached to this transition. Choose what happens before deletion.',
    );
    return '$_temp0';
  }

  @override
  String get keepNotesUnlinked => 'Keep unlinked';

  @override
  String get detachNotes => 'Detach notes';

  @override
  String get deleteNotes => 'Delete notes';

  @override
  String grammarDependencySummaryCounts(int variableCount, int edgeCount) {
    String _temp0 = intl.Intl.pluralLogic(
      variableCount,
      locale: localeName,
      other: '$variableCount variables',
      one: '1 variable',
    );
    String _temp1 = intl.Intl.pluralLogic(
      edgeCount,
      locale: localeName,
      other: '$edgeCount dependency edges.',
      one: '1 dependency edge.',
    );
    return '$_temp0 and $_temp1';
  }

  @override
  String get grammarDependencyNoRecursionCycle =>
      'No recursion cycle was found in this graph mode.';

  @override
  String grammarDependencyRecursionCycleCount(int cycleCount) {
    String _temp0 = intl.Intl.pluralLogic(
      cycleCount,
      locale: localeName,
      other: '$cycleCount recursion cycles were found.',
      one: '1 recursion cycle was found.',
    );
    return '$_temp0';
  }

  @override
  String grammarDependencyUnreachableVariable(String variable) {
    return 'Unreachable variable: $variable.';
  }

  @override
  String grammarDependencyNonproductiveVariable(String variable) {
    return 'Nonproductive variable: $variable.';
  }

  @override
  String grammarLl1ConflictDetected(
    String conflictKind,
    String nonTerminal,
    String lookahead,
    String alternatives,
  ) {
    return '$conflictKind conflict in [$nonTerminal, $lookahead]: $alternatives.';
  }

  @override
  String get grammarAmbiguityNoLl1Conflicts =>
      'No LL(1) conflicts detected (grammar appears LL(1) for this analysis).';

  @override
  String get grammarAmbiguityLl1ConflictsDetected =>
      'LL(1) conflicts detected (grammar is not LL(1)).';

  @override
  String get grammarAmbiguityNonLl1DoesNotImplyAmbiguity =>
      'Note: Being non-LL(1) does not necessarily mean the grammar is ambiguous; it may still be unambiguous but require a stronger parser (e.g., LR/Earley).';

  @override
  String get grammarAnalysisEmptyProductions =>
      'The grammar has no productions.';

  @override
  String get grammarAnalysisNoLeftRecursion =>
      'No direct or indirect left recursion detected.';

  @override
  String get grammarStructuralStartSymbolMissing =>
      'Grammar has no start symbol.';

  @override
  String get grammarStructuralStartSymbolMissingReachability =>
      'Grammar has no start symbol; unreachable analysis was skipped.';

  @override
  String grammarStructuralStartSymbolNotNonterminal(String symbol) {
    return 'Start symbol $symbol is not declared as a non-terminal.';
  }

  @override
  String grammarStructuralStartSymbolNotNonterminalReachability(String symbol) {
    return 'Start symbol $symbol is not declared as a non-terminal; unreachable analysis may be inaccurate.';
  }

  @override
  String get grammarStructuralNoProductions => 'Grammar has no productions.';

  @override
  String get grammarStructuralNoProductionsProductivity =>
      'Grammar has no productions; productivity analysis was skipped.';

  @override
  String grammarStructuralProductionLeftSideEmpty(String productionId) {
    return 'Production $productionId has an empty left-hand side.';
  }

  @override
  String grammarStructuralProductionLeftSideNotSingleNonterminal(
    String productionId,
    String leftSide,
  ) {
    return 'Production $productionId left-hand side must be exactly one non-terminal for CFG tooling; got $leftSide.';
  }

  @override
  String grammarStructuralProductionLeftSideEmptySymbol(String productionId) {
    return 'Production $productionId left-hand side contains an empty symbol.';
  }

  @override
  String grammarStructuralProductionLeftSideNotNonterminal(
    String productionId,
    String symbol,
  ) {
    return 'Production $productionId left-hand side $symbol is not declared as a non-terminal.';
  }

  @override
  String grammarStructuralProductionUnknownSymbol(
    String productionId,
    String symbol,
  ) {
    return 'Production $productionId references unknown symbol $symbol.';
  }

  @override
  String grammarStructuralUnknownSymbolReachability(String symbol) {
    return 'Production references unknown symbol $symbol; treating it as a terminal for reachability purposes.';
  }

  @override
  String grammarStructuralUnknownSymbolProductivity(String symbol) {
    return 'Production references unknown symbol $symbol; treating it as a terminal for productivity purposes.';
  }

  @override
  String grammarStructuralLambdaProductionRhsNotEmpty(String productionId) {
    return 'Production $productionId is marked as lambda but has a non-empty right-hand side.';
  }

  @override
  String grammarStructuralProductionRhsEmpty(String productionId) {
    return 'Production $productionId has an empty right-hand side; use ε or mark it as epsilon.';
  }

  @override
  String grammarStructuralUnreachableNonterminals(int count, String symbols) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Found $count unreachable non-terminals',
      one: 'Found 1 unreachable non-terminal',
    );
    return '$_temp0: $symbols.';
  }

  @override
  String grammarStructuralUnproductiveNonterminals(int count, String symbols) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Found $count unproductive non-terminals',
      one: 'Found 1 unproductive non-terminal',
    );
    return '$_temp0: $symbols.';
  }

  @override
  String grammarStructuralUnproductiveProductions(String symbols) {
    return 'Productions for unproductive non-terminals ($symbols) cannot derive terminal strings.';
  }

  @override
  String get grammarLl1ConflictKindFirstFirst => 'FIRST/FIRST';

  @override
  String get grammarLl1ConflictKindFirstFollow => 'FIRST/FOLLOW';

  @override
  String fsaDeterminizationFailed(String automaton) {
    return 'Automaton $automaton could not be determinized.';
  }

  @override
  String batchValidationNonEmpty(String field) {
    return '$field must be non-empty.';
  }

  @override
  String batchValidationPositive(String field) {
    return '$field must be positive.';
  }

  @override
  String batchValidationNonNegative(String field) {
    return '$field must not be negative.';
  }

  @override
  String batchValidationMaximum(String field, int bound) {
    return '$field must not exceed $bound.';
  }

  @override
  String batchValidationCaseContext(int index, String caseId) {
    return 'Case $index ($caseId):';
  }

  @override
  String batchValidationDuplicateCaseId(String caseId) {
    return 'Duplicate case ID $caseId.';
  }

  @override
  String batchValidationExplicitTokensRequired(String caseId) {
    return 'Case $caseId: explicit tokenization requires tokens.';
  }

  @override
  String batchValidationUnknownCaseLimits(String caseId) {
    return 'Per-case limits reference unknown case $caseId.';
  }

  @override
  String get batchValidationSelectedTraceCaseRequired =>
      'Selected-case trace retention requires a known case ID.';

  @override
  String get batchExecutionScalarTokenizationRequired =>
      'This canonical simulator requires Unicode-scalar tokens.';

  @override
  String get batchExecutionKeyboardShortcuts =>
      'Run: Ctrl+Enter. Cancel: Escape.';

  @override
  String get batchExecutionGrammarTokenizationMismatch =>
      'The canonical grammar tokenizer cannot preserve this explicit token sequence.';

  @override
  String batchExecutionTmPolicyReason(String policy, String reason) {
    return 'Policy: $policy. Reason: $reason.';
  }

  @override
  String batchImportCaseLimit(int count, int bound) {
    return 'The input file contains $count cases; the limit is $bound.';
  }

  @override
  String batchImportMissingInputColumn(int row) {
    return 'CSV row $row has no input column.';
  }

  @override
  String batchImportDuplicateCaseId(String caseId) {
    return 'CSV contains duplicate case ID $caseId.';
  }

  @override
  String get batchImportCharactersAfterClosingQuote =>
      'CSV has characters after a closing quote.';

  @override
  String get batchImportQuoteRequiresEmptyField =>
      'A CSV quote must start an empty field.';

  @override
  String get batchImportUnclosedQuote => 'CSV contains an unclosed quote.';

  @override
  String get automataDiagnosticsCanvas => 'Canvas diagnostics';

  @override
  String automataDiagnosticsConflicts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Conflicts ($count)',
      one: 'Conflict (1)',
      zero: 'Conflicts (0)',
    );
    return '$_temp0';
  }

  @override
  String automataDiagnosticsConflictAction(String selected, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Clear the conflicting transition highlights, $count found',
      one: 'Clear the conflicting transition highlight, 1 found',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Highlight conflicting transitions, $count found',
      one: 'Highlight the conflicting transition, 1 found',
    );
    String _temp2 = intl.Intl.selectLogic(selected, {
      'true': '$_temp0',
      'other': '$_temp1',
    });
    return '$_temp2';
  }

  @override
  String get automataDiagnosticsConflictHint =>
      'Shows transitions that compete for the same input';

  @override
  String automataDiagnosticsEpsilon(int count) {
    return 'Epsilon ($count)';
  }

  @override
  String automataDiagnosticsEpsilonAction(String selected, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Clear the epsilon transition highlights, $count found',
      one: 'Clear the epsilon transition highlight, 1 found',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Highlight epsilon transitions, $count found',
      one: 'Highlight the epsilon transition, 1 found',
    );
    String _temp2 = intl.Intl.selectLogic(selected, {
      'true': '$_temp0',
      'other': '$_temp1',
    });
    return '$_temp2';
  }

  @override
  String get automataDiagnosticsEpsilonHint =>
      'Shows transitions that use the empty string';

  @override
  String get computationBranchesTitle => 'Computation branches';

  @override
  String get computationBranchesInspectorSemantic =>
      'Computation branch inspector';

  @override
  String get computationBranchesBranch => 'Branch';

  @override
  String get computationBranchesConfigurations => 'Configurations';

  @override
  String get computationBranchesConfigurationDetails => 'Configuration details';

  @override
  String get computationBranchesConfiguration => 'Configuration';

  @override
  String get computationBranchesOutcome => 'Outcome';

  @override
  String get computationBranchesHighlight => 'Highlight branch';

  @override
  String get computationBranchesSelectConfiguration =>
      'Select a configuration to inspect it.';

  @override
  String get computationBranchesNone =>
      'No computation branches were recorded.';

  @override
  String get computationBranchesNoConfigurations =>
      'This branch has no recorded configurations.';

  @override
  String get computationBranchesUnavailable => 'Branch inspection unavailable';

  @override
  String get computationBranchesPreviousBranch => 'Previous branch';

  @override
  String get computationBranchesNextBranch => 'Next branch';

  @override
  String get computationBranchesPreviousConfigurations =>
      'Previous configurations';

  @override
  String get computationBranchesNextConfigurations => 'Next configurations';

  @override
  String get computationBranchesAccepted => 'Accepted';

  @override
  String get computationBranchesRejected => 'Rejected';

  @override
  String get computationBranchesDead => 'Dead end';

  @override
  String get computationBranchesBoundedUnknown => 'Unknown at execution bound';

  @override
  String get computationBranchesCycle => 'Cycle detected';

  @override
  String get computationBranchesCancelled => 'Cancelled';

  @override
  String get computationBranchesFailed => 'Failed';

  @override
  String get computationBranchesSimulationNotRun =>
      'Run a simulation to inspect its branches.';

  @override
  String get computationBranchesNotRecorded =>
      'This simulation records a trace but not every explored branch.';

  @override
  String get computationBranchesDeterministic =>
      'This execution followed one deterministic path.';

  @override
  String get computationBranchesUnsupported =>
      'This simulation cannot provide branch data.';

  @override
  String get computationBranchesInspect => 'Inspect computation branches';

  @override
  String get computationBranchesHide => 'Hide computation branches';

  @override
  String get computationBranchesInspectHint =>
      'Review each recorded nondeterministic execution path';

  @override
  String computationBranchesBranchName(int index) {
    return 'Branch $index';
  }

  @override
  String computationBranchesConfigurationName(int index) {
    return 'Configuration $index';
  }

  @override
  String computationBranchesBranchPosition(int index, int total) {
    return 'Branch $index of $total';
  }

  @override
  String computationBranchesConfigurationRange(int start, int end, int total) {
    return 'Configurations $start-$end of $total';
  }

  @override
  String computationBranchesBranchOption(String branch, String outcome) {
    return '$branch · $outcome';
  }

  @override
  String computationBranchesBranchAnnouncement(
    String position,
    String branch,
    String outcome,
  ) {
    return '$position. $branch. $outcome.';
  }

  @override
  String computationBranchesConfigurationSemantic(
    String hasOutcome,
    String configuration,
    String outcome,
  ) {
    String _temp0 = intl.Intl.selectLogic(hasOutcome, {
      'true': 'Configuration: $configuration, outcome: $outcome',
      'other': 'Configuration: $configuration',
    });
    return '$_temp0';
  }

  @override
  String computationBranchesOutcomeSemantic(String outcome) {
    return 'Outcome: $outcome';
  }

  @override
  String computationBranchesUnavailableSemantic(String reason) {
    return 'Branch inspection unavailable. $reason';
  }

  @override
  String get languageComparisonInconclusive => 'Inconclusive within limits';

  @override
  String get languageComparisonAnalysisFailed => 'Analysis failed';

  @override
  String get languageComparisonInvalidInput => 'Invalid machine or input';

  @override
  String languageComparisonValidationEmptyStateSet(String automaton) {
    return '$automaton must have at least one state';
  }

  @override
  String languageComparisonValidationMissingInitialState(String automaton) {
    return '$automaton must have an initial state';
  }

  @override
  String languageComparisonValidationInitialStateOutsideSet(String automaton) {
    return 'The initial state of $automaton must belong to the state set';
  }

  @override
  String get languageComparisonConversionFailed => 'Conversion failed';

  @override
  String get languageComparisonLimitReached => 'Limit reached';

  @override
  String languageComparisonStatusSemantic(String status) {
    return 'Language Comparison: $status';
  }

  @override
  String languageComparisonWitnessSemantic(String value) {
    return 'Distinguishing string found: $value';
  }

  @override
  String languageComparisonStatisticsSemantic(
    int statesA,
    int statesB,
    int transitionsA,
    int transitionsB,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      statesA,
      locale: localeName,
      other: '$statesA states',
      one: '1 state',
    );
    String _temp1 = intl.Intl.pluralLogic(
      statesB,
      locale: localeName,
      other: '$statesB states',
      one: '1 state',
    );
    String _temp2 = intl.Intl.pluralLogic(
      transitionsA,
      locale: localeName,
      other: '$transitionsA transitions',
      one: '1 transition',
    );
    String _temp3 = intl.Intl.pluralLogic(
      transitionsB,
      locale: localeName,
      other: '$transitionsB transitions',
      one: '1 transition',
    );
    return 'Automaton A: $_temp0, automaton B: $_temp1, automaton A: $_temp2, automaton B: $_temp3';
  }

  @override
  String languageComparisonCanvasSemantic(
    String title,
    int stateCount,
    int transitionCount,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      stateCount,
      locale: localeName,
      other: '$stateCount states',
      one: '1 state',
    );
    String _temp1 = intl.Intl.pluralLogic(
      transitionCount,
      locale: localeName,
      other: '$transitionCount transitions',
      one: '1 transition',
    );
    return '$title. $_temp0, $_temp1';
  }

  @override
  String languageComparisonStepSemantic(int step, String title) {
    return 'Step $step: $title';
  }

  @override
  String get languageComparisonFailureMalformedExplanation =>
      'Check that both automata have states and an initial state.';

  @override
  String get languageComparisonFailureDeterminizationExplanation =>
      'One automaton could not be converted to a deterministic automaton.';

  @override
  String get languageComparisonFailureNormalizationExplanation =>
      'The automata could not be completed over a shared alphabet.';

  @override
  String get languageComparisonFailureProductExplanation =>
      'The product automaton could not be constructed.';

  @override
  String get languageComparisonFailureTimeoutExplanation =>
      'The comparison exceeded its time budget without deciding equivalence.';

  @override
  String get languageComparisonFailureStateLimitExplanation =>
      'The comparison reached its product-state limit without deciding equivalence.';

  @override
  String get languageComparisonFailureInternalExplanation =>
      'The comparison stopped because of an internal error.';

  @override
  String languageComparisonFailureSemantic(String reason, String explanation) {
    return '$reason. $explanation';
  }

  @override
  String get languageComparisonStepValidation => 'Validation';

  @override
  String get languageComparisonStepInitialization => 'Initialization';

  @override
  String get languageComparisonStepAlphabetNormalization =>
      'Alphabet Normalization';

  @override
  String get languageComparisonStepDfaConversion => 'DFA Conversion';

  @override
  String get languageComparisonStepDfaCompletion => 'DFA Completion';

  @override
  String get languageComparisonStepProductConstruction =>
      'Product Construction';

  @override
  String get languageComparisonStepProductStateCreated =>
      'Product State Created';

  @override
  String get languageComparisonStepProductTransition => 'Product Transition';

  @override
  String get languageComparisonStepProductComplete =>
      'Product Construction Complete';

  @override
  String get languageComparisonStepBfsSearch => 'BFS Search';

  @override
  String get languageComparisonStepInitialPairCheck => 'Initial Pair Check';

  @override
  String get languageComparisonStepStatePairVisit => 'State Pair Visit';

  @override
  String get languageComparisonStepCounterexampleFound =>
      'Counterexample Found';

  @override
  String get languageComparisonStepBfsComplete => 'BFS Complete';

  @override
  String get languageComparisonStepResult => 'Comparison Result';

  @override
  String get languageComparisonStepError => 'Comparison Error';

  @override
  String get languageComparisonStepUnknown => 'Unknown Step';

  @override
  String get languageComparisonDescriptionValidation =>
      'Validating input automata';

  @override
  String get languageComparisonDescriptionInitialization =>
      'Initialize product automaton construction';

  @override
  String get languageComparisonDescriptionAlphabet =>
      'Combining alphabets from both automata';

  @override
  String languageComparisonDescriptionNfaToDfa(String automaton) {
    return 'Converting automaton $automaton from NFA to DFA';
  }

  @override
  String languageComparisonDescriptionDfaCompletion(String automaton) {
    return 'Completing DFA $automaton with a sink state if needed';
  }

  @override
  String get languageComparisonDescriptionProductStart =>
      'Starting product automaton construction';

  @override
  String languageComparisonDescriptionProductState(String state) {
    return 'Created product state $state';
  }

  @override
  String languageComparisonDescriptionProductTransition(String symbol) {
    return 'Created a product transition on symbol $symbol';
  }

  @override
  String get languageComparisonDescriptionProductComplete =>
      'Product automaton construction complete';

  @override
  String get languageComparisonDescriptionBfsStart =>
      'Starting BFS search for a distinguishing string';

  @override
  String languageComparisonDescriptionInitialCheck(String different) {
    String _temp0 = intl.Intl.selectLogic(different, {
      'true':
          'The initial states have different acceptance; the empty string distinguishes them',
      'other': 'The initial states have the same acceptance status',
    });
    return '$_temp0';
  }

  @override
  String languageComparisonDescriptionExplorePair(
    String stateA,
    String stateB,
  ) {
    return 'Exploring state pair ($stateA, $stateB)';
  }

  @override
  String languageComparisonDescriptionCounterexample(String value) {
    return 'Found distinguishing string $value';
  }

  @override
  String get languageComparisonDescriptionBfsComplete =>
      'BFS complete; all state pairs were explored';

  @override
  String languageComparisonDescriptionResult(String equivalent) {
    String _temp0 = intl.Intl.selectLogic(equivalent, {
      'true': 'The automata are equivalent and recognize the same language',
      'other':
          'The automata are not equivalent; a distinguishing string was found',
    });
    return '$_temp0';
  }

  @override
  String get languageComparisonDescriptionError =>
      'The comparison stopped with an error';

  @override
  String get languageComparisonDescriptionUnknown =>
      'No localized description is available for this trace step.';

  @override
  String get languageComparisonDetailAutomaton => 'Automaton';

  @override
  String get languageComparisonDetailAutomatonAAlphabet =>
      'Automaton A alphabet';

  @override
  String get languageComparisonDetailAutomatonBAlphabet =>
      'Automaton B alphabet';

  @override
  String get languageComparisonDetailSharedAlphabet => 'Shared alphabet';

  @override
  String get languageComparisonDetailSinkState => 'Sink state';

  @override
  String get languageComparisonDetailAlphabetSize => 'Alphabet size';

  @override
  String get languageComparisonDetailStatePair => 'State pair';

  @override
  String get languageComparisonDetailProductState => 'Product state';

  @override
  String get languageComparisonDetailAccepting => 'Accepting';

  @override
  String get languageComparisonDetailTarget => 'Target';

  @override
  String get languageComparisonDetailAcceptingStates => 'Accepting states';

  @override
  String get languageComparisonDetailInitialPair => 'Initial pair';

  @override
  String get languageComparisonDetailAcceptance => 'Acceptance';

  @override
  String get languageComparisonDetailPath => 'Path';

  @override
  String get languageComparisonDetailPathLength => 'Path length';

  @override
  String get languageComparisonDetailDistinguishingString =>
      'Distinguishing string';

  @override
  String get languageComparisonDetailPairsExplored => 'Pairs explored';

  @override
  String get languageComparisonDetailEquivalent => 'Equivalent';

  @override
  String get languageComparisonDetailReason => 'Reason';

  @override
  String get languageComparisonDetailStage => 'Stage';

  @override
  String get languageComparisonDetailMessage => 'Message';

  @override
  String get languageComparisonDetailRawType => 'Raw type';

  @override
  String get languageComparisonValueUnknown => 'Unknown';

  @override
  String get languageComparisonValueAdded => 'Added';

  @override
  String get languageComparisonValueNotNeeded => 'Not needed';

  @override
  String get languageComparisonValueNew => 'New';

  @override
  String get languageComparisonValueExisting => 'Existing';

  @override
  String languageComparisonValueBeforeAfter(String before, String after) {
    return '$before → $after';
  }

  @override
  String languageComparisonValueStatePair(String stateA, String stateB) {
    return '$stateA / $stateB';
  }

  @override
  String languageComparisonValueAcceptance(String acceptsA, String acceptsB) {
    String _temp0 = intl.Intl.selectLogic(acceptsA, {
      'true': 'accepts input',
      'other': 'rejects input',
    });
    String _temp1 = intl.Intl.selectLogic(acceptsB, {
      'true': 'accepts input',
      'other': 'rejects input',
    });
    return 'Automaton A $_temp0; automaton B $_temp1';
  }

  @override
  String languageComparisonExecuting(String algorithm) {
    return 'Executing $algorithm';
  }

  @override
  String get languageComparisonComplete => 'Comparison complete';

  @override
  String get languageComparisonLegacyTitle => 'Equivalence comparison';

  @override
  String get languageComparisonLegacyEquivalent => 'Automata are equivalent';

  @override
  String get languageComparisonLegacyNotEquivalent =>
      'Automata are not equivalent';

  @override
  String get pumpingMessagePumpingLengthPositive =>
      'The pumping length must be positive.';

  @override
  String get pumpingMessageExponentNonNegative =>
      'The pump exponent must be non-negative.';

  @override
  String get pumpingMessageMaximumTokensNonNegative =>
      'The token limit must be non-negative.';

  @override
  String pumpingMessageRequiredTextNotEmpty(String field) {
    return 'The $field field must not be empty.';
  }

  @override
  String get pumpingMessageSuggestedWitnessNotEmpty =>
      'The suggested witness must not be empty.';

  @override
  String get pumpingMessageCustomTitleNotEmpty =>
      'The custom title must not be empty.';

  @override
  String get pumpingMessageWitnessRequiresPumpingLength =>
      'A witness requires a pumping length.';

  @override
  String pumpingMessageWitnessMinimumTokens(int minimum) {
    return 'The witness must contain at least $minimum tokens.';
  }

  @override
  String pumpingMessageDecompositionTheoremMismatch(
    String actual,
    String expected,
  ) {
    return 'The $actual decomposition cannot be used in a $expected session.';
  }

  @override
  String get pumpingMessageDecompositionWitnessMismatch =>
      'The decomposition does not reconstruct this witness.';

  @override
  String get pumpingMessageDecompositionConstraintViolation =>
      'The decomposition violates the theorem constraints.';

  @override
  String get pumpingMessageEnterPositivePumpingLength =>
      'Enter a positive integer for p.';

  @override
  String get pumpingMessageEnterNonNegativeExponent =>
      'Enter a non-negative integer for i.';

  @override
  String get pumpingMessageInvalidTokenArray =>
      'Enter a JSON array of string tokens.';

  @override
  String get pumpingMessageNoValidDecomposition =>
      'No valid decomposition is available.';

  @override
  String pumpingMessageDecompositionsEnumerated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count valid decompositions enumerated for this finite witness.',
      one: '1 valid decomposition enumerated for this finite witness.',
    );
    return '$_temp0';
  }

  @override
  String pumpingMessagePumpedWordBounded(int minimum, int maximum) {
    return 'The pumped word needs at least $minimum tokens; the limit is $maximum.';
  }

  @override
  String get pumpingMessageChooseBoundedExponent =>
      'Choose an exponent whose pumped word fits the token limit.';

  @override
  String get pumpingMessageCounterexampleEvidence =>
      'This exponent is concrete counterexample evidence for the selected decomposition.';

  @override
  String get pumpingMessageFiniteCheckInconclusive =>
      'The sampled word stayed in the language. This finite check proves no universal claim.';

  @override
  String get pumpingMessageSessionImported => 'Session imported.';

  @override
  String get pumpingMessageTransitionWrongStage =>
      'Complete the current quantifier step first.';

  @override
  String get pumpingMessageTransitionWrongPlayer =>
      'That choice belongs to the other player.';

  @override
  String get pumpingMessageTransitionWitnessTooShort =>
      'The witness must contain at least p tokens.';

  @override
  String get pumpingMessageTransitionWitnessOutsideLanguage =>
      'The selected witness is not in the language.';

  @override
  String simulationOutcomeTimeout(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'The simulation timed out after $seconds seconds.',
      one: 'The simulation timed out after one second.',
      zero: 'The simulation timed out in less than one second.',
    );
    return '$_temp0';
  }

  @override
  String simulationOutcomeProvenCycle(int steps) {
    String _temp0 = intl.Intl.pluralLogic(
      steps,
      locale: localeName,
      other:
          'The simulation detected a repeating configuration after $steps steps.',
      one: 'The simulation detected a repeating configuration after one step.',
      zero:
          'The simulation detected a repeating configuration before recording a step.',
    );
    return '$_temp0';
  }

  @override
  String get simulationOutcomeLegacyFailure =>
      'The simulation could not be completed.';

  @override
  String get tmMultiTapeTraceTitle => 'Synchronized multi-tape trace';

  @override
  String get tmMultiTapeNoTransition => 'No transition was executed.';

  @override
  String tmMultiTapeStep(int step, String fromState, String toState) {
    return 'Step $step: $fromState → $toState';
  }

  @override
  String tmMultiTapeAtomicTransition(String transitionId, int tapeCount) {
    String _temp0 = intl.Intl.pluralLogic(
      tapeCount,
      locale: localeName,
      other: '$tapeCount tapes updated atomically',
      one: '1 tape updated atomically',
    );
    return 'Transition $transitionId; $_temp0';
  }

  @override
  String get tmMultiTapeSpaceMetricsSemantic => 'Multi-tape space metrics';

  @override
  String get tmMultiTapeSpaceMetricsExplanation =>
      'Space is measured per tape as the visited logical-head span and maximum simultaneous nonblank cells.';

  @override
  String tmMultiTapeMetrics(int tapeNumber, int span, int nonblankCount) {
    return 'Tape $tapeNumber: span $span, maximum nonblank cells $nonblankCount';
  }

  @override
  String tmMultiTapeTotalNonblank(int count) {
    return 'Maximum total simultaneous nonblank cells: $count';
  }

  @override
  String tmMultiTapeConfigurationSemantic(
    int tapeNumber,
    int head,
    String operation,
  ) {
    return 'Tape $tapeNumber, head at $head, operation $operation';
  }

  @override
  String tmMultiTapeTitle(int tapeNumber) {
    return 'Tape $tapeNumber';
  }

  @override
  String tmMultiTapeHeadSummary(int head, String operation) {
    return 'Head $head · $operation';
  }

  @override
  String tmMultiTapeCellSemantic(int position, String symbol) {
    return 'Cell $position, $symbol';
  }

  @override
  String tmMultiTapeHeadCellSemantic(int position, String symbol) {
    return 'Cell $position, $symbol, head';
  }

  @override
  String tmMultiTapePosition(int position) {
    return '$position';
  }

  @override
  String get serviceSimulationRunnerStartFailed =>
      'The simulation worker could not start.';

  @override
  String get serviceSimulationRunnerExecutionFailed =>
      'The simulation could not be completed.';

  @override
  String get serviceSimulationRunnerWorkerFailed =>
      'The simulation worker failed.';

  @override
  String get serviceSimulationRunnerWorkerExitedUnexpectedly =>
      'The simulation worker exited unexpectedly.';

  @override
  String get serviceSimulationRunnerInvalidWorkerResponse =>
      'The simulation worker returned an invalid response.';

  @override
  String serviceTmBlockEditorDuplicateBlockId(String block) {
    return 'A machine already uses block ID $block.';
  }

  @override
  String serviceTmBlockEditorDuplicateBlockName(String name) {
    return 'A block already uses the name $name.';
  }

  @override
  String get serviceTmBlockEditorInvalidBlockName =>
      'Block names must be non-empty and unique.';

  @override
  String serviceTmBlockEditorReferencedBlock(String block) {
    return 'Block $block is still referenced. Choose an explicit resolution.';
  }

  @override
  String serviceTmBlockEditorMissingOwnerMachine(String machine) {
    return 'Machine $machine does not exist.';
  }

  @override
  String serviceTmBlockEditorMissingAnchorState(String state, String machine) {
    return 'State $state does not exist in $machine.';
  }

  @override
  String serviceTmBlockEditorStateAlreadyInvokesBlock(String state) {
    return 'State $state already invokes a block.';
  }

  @override
  String serviceTmBlockEditorDuplicateRootState(String state) {
    return 'State $state already exists in the root machine.';
  }

  @override
  String serviceTmBlockEditorMissingInvocation(String invocation) {
    return 'Invocation $invocation does not exist.';
  }

  @override
  String get serviceTmBlockEditorNothingToUndo =>
      'There is no building-block edit to undo.';

  @override
  String get serviceTmBlockEditorNothingToRedo =>
      'There is no building-block edit to redo.';

  @override
  String serviceTmBlockEditorMissingBlock(String block) {
    return 'Block $block does not exist.';
  }

  @override
  String serviceTmBlockEditorInvalidProject(String diagnostic) {
    String _temp0 = intl.Intl.selectLogic(diagnostic, {
      'duplicateMachineId': 'A block reuses the root machine ID.',
      'duplicateBlockName': 'Block names must be non-empty and unique.',
      'duplicateInvocationId': 'An invocation ID is duplicated.',
      'duplicateInvocationState': 'A state invokes more than one block.',
      'missingReference': 'An invocation references a missing block.',
      'revisionMismatch': 'An invocation uses an outdated block revision.',
      'missingAnchorState': 'An invocation has no graph state.',
      'missingInitialState': 'A block has no initial state.',
      'tapeCountMismatch':
          'A block uses a different tape count from the root machine.',
      'blankSymbolMismatch':
          'A block uses a different blank symbol from the root machine.',
      'nestedLibrary': 'A block contains an embedded library.',
      'recursiveDependency': 'The block dependency graph is recursive.',
      'other': 'The building-block project is invalid.',
    });
    return '$_temp0';
  }

  @override
  String get serviceManualConversionStoreMalformedPayload =>
      'The saved construction is malformed.';

  @override
  String serviceFileOperationsOperationFailed(String operation) {
    String _temp0 = intl.Intl.selectLogic(operation, {
      'read': 'The selected file could not be read.',
      'write': 'The file could not be saved.',
      'encodePng': 'The PNG image could not be encoded.',
      'exportPng': 'The PNG image could not be exported.',
      'exportSvg': 'The SVG document could not be exported.',
      'directory': 'The app documents directory is unavailable.',
      'create': 'A new file location could not be created.',
      'list': 'The saved files could not be listed.',
      'delete': 'The selected file could not be deleted.',
      'download': 'The download could not be started.',
      'other': 'The file operation could not be completed.',
    });
    return '$_temp0';
  }

  @override
  String serviceFileOperationsAccessDenied(String operation) {
    String _temp0 = intl.Intl.selectLogic(operation, {
      'read':
          'Turing Lab does not have permission to read the selected file. Pick it again and retry.',
      'write':
          'Turing Lab does not have permission to save to the selected location. Choose it again and retry.',
      'other':
          'Turing Lab does not have permission to access the selected location. Choose it again and retry.',
    });
    return '$_temp0';
  }

  @override
  String serviceFileOperationsLocationMissing(String operation) {
    String _temp0 = intl.Intl.selectLogic(operation, {
      'read':
          'The selected file is no longer available. Pick it again and retry.',
      'write':
          'The selected save location is no longer available. Choose another location and retry.',
      'delete': 'The selected file no longer exists.',
      'other':
          'The selected location is no longer available. Choose it again and retry.',
    });
    return '$_temp0';
  }

  @override
  String serviceFileOperationsAccessFailed(String operation) {
    String _temp0 = intl.Intl.selectLogic(operation, {
      'read':
          'The selected file could not be accessed for reading. Pick it again and retry.',
      'write':
          'The selected location could not be accessed for saving. Choose it again and retry.',
      'other':
          'The selected location could not be accessed. Choose it again and retry.',
    });
    return '$_temp0';
  }

  @override
  String serviceFileOperationsWebUnsupported(String operation) {
    String _temp0 = intl.Intl.selectLogic(operation, {
      'read':
          'Reading a browser file by path is not supported. Use the file picker instead.',
      'exportPng': 'PNG export is not available in the web app.',
      'directory':
          'The app documents directory is not available in the web app.',
      'create': 'Creating a local file path is not supported in the web app.',
      'list': 'Listing local files is not supported in the web app.',
      'delete':
          'Deleting a local file by path is not supported in the web app.',
      'other': 'This file operation is not supported in the web app.',
    });
    return '$_temp0';
  }

  @override
  String serviceFileOperationsCodecUnsupported(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'document': 'This document type is not supported.',
      'feature': 'This document uses an unsupported feature.',
      'schema': 'This document schema is not supported.',
      'format': 'This document format is not supported.',
      'direction':
          'This operation is not supported in the requested direction.',
      'other': 'This document operation is not supported.',
    });
    return '$_temp0';
  }

  @override
  String serviceFileOperationsCodecAmbiguous(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count compatible document codecs matched. Choose a specific format.',
      one:
          'One compatible document codec was identified, but the format remains ambiguous.',
      zero: 'No compatible document codec was identified.',
    );
    return '$_temp0';
  }

  @override
  String serviceFileOperationsCodecMalformed(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'syntax': 'The document syntax is malformed.',
      'invalidUtf8': 'The document is not valid UTF-8.',
      'missingField': 'The document is missing a required field.',
      'invalidValue': 'The document contains an invalid value.',
      'duplicateIdentity': 'The document contains a duplicate identifier.',
      'other': 'The document is malformed.',
    });
    return '$_temp0';
  }

  @override
  String serviceFileOperationsCodecResourceLimit(
    String limit,
    int actual,
    int maximum,
  ) {
    String _temp0 = intl.Intl.selectLogic(limit, {
      'bytes': 'The document uses $actual bytes; the limit is $maximum.',
      'xmlDepth': 'The XML nesting depth is $actual; the limit is $maximum.',
      'xmlElements':
          'The XML contains $actual elements; the limit is $maximum.',
      'xmlDtdOrEntity':
          'The XML contains a prohibited DTD or entity declaration.',
      'jsonDepth': 'The JSON nesting depth is $actual; the limit is $maximum.',
      'collectionEntries':
          'The document contains $actual collection entries; the limit is $maximum.',
      'other':
          'The document exceeds a resource limit ($actual used; maximum $maximum).',
    });
    return '$_temp0';
  }

  @override
  String serviceFileOperationsCodecInternalFailure(String stage) {
    String _temp0 = intl.Intl.selectLogic(stage, {
      'sniff':
          'The document format could not be identified because of an internal error.',
      'decode':
          'The document could not be decoded because of an internal error.',
      'encode':
          'The document could not be encoded because of an internal error.',
      'unknown': 'The document operation failed because of an internal error.',
      'other': 'The document operation failed because of an internal error.',
    });
    return '$_temp0';
  }

  @override
  String get serviceFileOperationsInteroperabilityReviewRequired =>
      'Review the compatibility changes before importing this document.';

  @override
  String get serviceFileOperationsLossyExportRequiresConfirmation =>
      'Review and confirm the compatibility changes before exporting this document.';

  @override
  String get serviceFileOperationsInvalidModelType =>
      'The document contains a different formal-system model than expected.';

  @override
  String get regexSimplificationStartTitle => 'Begin regex simplification';

  @override
  String regexSimplificationStartExplanation(
    String regex,
    int starHeight,
    int nestingDepth,
    int operatorCount,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      operatorCount,
      locale: localeName,
      other: '$operatorCount operators',
      one: 'one operator',
      zero: 'no operators',
    );
    return 'Starting with \"$regex\". Current complexity: star height $starHeight, nesting depth $nestingDepth, and $_temp0. Algebraic identities will be applied to find an equivalent simpler form.';
  }

  @override
  String get regexSimplificationAnalyzeTitle => 'Analyze regex complexity';

  @override
  String regexSimplificationAnalyzeExplanation(
    String regex,
    int starHeight,
    int nestingDepth,
    int alphabetSize,
    int operatorCount,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      alphabetSize,
      locale: localeName,
      other: '$alphabetSize distinct symbols',
      one: 'one distinct symbol',
      zero: 'no distinct symbols',
    );
    String _temp1 = intl.Intl.pluralLogic(
      operatorCount,
      locale: localeName,
      other: '$operatorCount operators',
      one: 'one operator',
      zero: 'no operators',
    );
    return 'Analyzing \"$regex\": star height $starHeight, nesting depth $nestingDepth, $_temp0, and $_temp1.';
  }

  @override
  String regexSimplificationApplyTitle(String ruleName) {
    return 'Apply $ruleName';
  }

  @override
  String regexSimplificationApplyExplanation(
    String ruleName,
    String matched,
    String positionDescription,
    String replacement,
    String ruleDescription,
    String lengthChangeDescription,
  ) {
    return 'Applying $ruleName. Matched \"$matched\" $positionDescription and replaced it with \"$replacement\". $ruleDescription. $lengthChangeDescription';
  }

  @override
  String get regexSimplificationPositionUnavailable =>
      'at an unavailable position';

  @override
  String regexSimplificationPositionValue(int position) {
    return 'at position $position';
  }

  @override
  String regexSimplificationLengthReduced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Saved $count characters.',
      one: 'Saved one character.',
    );
    return '$_temp0';
  }

  @override
  String get regexSimplificationLengthUnchanged =>
      'The expression length did not change.';

  @override
  String regexSimplificationLengthIncreased(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'The expression grew by $count characters.',
      one: 'The expression grew by one character.',
    );
    return '$_temp0';
  }

  @override
  String get regexSimplificationGenerateSamplesTitle =>
      'Generate sample strings';

  @override
  String regexSimplificationGenerateSamplesEmptyExplanation(String regex) {
    return 'No sample strings were generated for \"$regex\". The expression may accept the empty language.';
  }

  @override
  String regexSimplificationGenerateSamplesExplanation(
    String regex,
    int count,
    String samples,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sample strings',
      one: 'one sample string',
    );
    return 'Generated $_temp0 for \"$regex\": $samples. These strings belong to the language described by the expression.';
  }

  @override
  String get regexSimplificationNoRuleTitle => 'No further simplification';

  @override
  String regexSimplificationNoRuleExplanation(String regex, int ruleCount) {
    String _temp0 = intl.Intl.pluralLogic(
      ruleCount,
      locale: localeName,
      other: '$ruleCount rules were applied.',
      one: 'One rule was applied.',
      zero: 'No rules were applied.',
    );
    return 'All simplification rules were checked against \"$regex\", and none applies. The expression is in the simplest form available through these algebraic identities. $_temp0';
  }

  @override
  String get regexSimplificationCompletionTitle => 'Simplification complete';

  @override
  String regexSimplificationCompletionExplanation(
    String original,
    int originalLength,
    String simplified,
    int simplifiedLength,
    double reductionPercent,
    int ruleCount,
    int starHeight,
    int nestingDepth,
    int operatorCount,
  ) {
    final intl.NumberFormat reductionPercentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String reductionPercentString = reductionPercentNumberFormat.format(
      reductionPercent,
    );

    String _temp0 = intl.Intl.pluralLogic(
      ruleCount,
      locale: localeName,
      other: '$ruleCount rules were applied.',
      one: 'One rule was applied.',
      zero: 'No rules were applied.',
    );
    String _temp1 = intl.Intl.pluralLogic(
      operatorCount,
      locale: localeName,
      other: '$operatorCount operators',
      one: 'one operator',
      zero: 'no operators',
    );
    return 'Simplification changed \"$original\" ($originalLength characters) to \"$simplified\" ($simplifiedLength characters), a $reductionPercentString% reduction. $_temp0 Final metrics: star height $starHeight, nesting depth $nestingDepth, and $_temp1.';
  }

  @override
  String get regexSimplificationNoRuleSummary => 'No rule applied';

  @override
  String regexSimplificationRuleSummary(
    String ruleName,
    String matched,
    String replacement,
  ) {
    return '$ruleName: \"$matched\" → \"$replacement\"';
  }

  @override
  String regexSimplificationStepTypeLabel(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'start': 'Start',
      'analyze': 'Analyze',
      'applyRule': 'Apply rule',
      'noRuleApplicable': 'No rule applicable',
      'generateSamples': 'Generate samples',
      'completion': 'Completion',
      'other': 'Unknown step',
    });
    return '$_temp0';
  }

  @override
  String regexSimplificationStepTypeDescription(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'start': 'Initialize the regex simplification process',
      'analyze': 'Analyze the regex complexity metrics',
      'applyRule': 'Apply an algebraic simplification rule',
      'noRuleApplicable': 'Report that no further simplification rule applies',
      'generateSamples': 'Generate sample strings that match the regex',
      'completion': 'Complete the simplification process',
      'other': 'Unknown simplification step',
    });
    return '$_temp0';
  }

  @override
  String regexSimplificationRuleName(String rule) {
    String _temp0 = intl.Intl.selectLogic(rule, {
      'emptyUnion': 'Empty union (r|∅ → r)',
      'emptyUnionLeft': 'Empty union on the left (∅|r → r)',
      'emptySetConcatenation': 'Empty-set concatenation (r∅ → ∅)',
      'emptySetConcatenationLeft':
          'Empty-set concatenation on the left (∅r → ∅)',
      'emptyStringConcatenation': 'Empty-string concatenation (rε → r)',
      'emptyStringConcatenationLeft':
          'Empty-string concatenation on the left (εr → r)',
      'starIdempotence': 'Star idempotence (r** → r*)',
      'emptySetStar': 'Empty-set star (∅* → ε)',
      'emptyStringStar': 'Empty-string star (ε* → ε)',
      'unionIdempotence': 'Union idempotence (r|r → r)',
      'doubleStar': 'Double star ((r*)* → r*)',
      'plusToStar': 'Plus to star (ε|rr* → r*)',
      'plusToStarAlt': 'Alternative plus to star (ε|r*r → r*)',
      'plusExpansion': 'Plus expansion (r+ → rr*)',
      'optionalExpansion': 'Optional expansion (r? → ε|r)',
      'optionalStarSimplification': 'Optional star ((ε|r)* → r*)',
      'starConcatenationIdempotence':
          'Star concatenation idempotence (r*r* → r*)',
      'unionStarDistribution': 'Union-star distribution',
      'redundantParentheses': 'Remove redundant parentheses',
      'characterClassCreation': 'Create a character class',
      'other': 'Unknown simplification rule',
    });
    return '$_temp0';
  }

  @override
  String regexSimplificationRuleDescription(String rule) {
    String _temp0 = intl.Intl.selectLogic(rule, {
      'emptyUnion':
          'Union with the empty set has no effect; the result is the other operand',
      'emptyUnionLeft': 'The empty set on the left of a union has no effect',
      'emptySetConcatenation':
          'Concatenation with the empty set produces the empty set',
      'emptySetConcatenationLeft':
          'The empty set on the left of a concatenation produces the empty set',
      'emptyStringConcatenation':
          'Concatenation with the empty string has no effect',
      'emptyStringConcatenationLeft':
          'The empty string on the left of a concatenation has no effect',
      'starIdempotence':
          'Applying the Kleene star twice is equivalent to applying it once',
      'emptySetStar': 'The Kleene star of the empty set is the empty string',
      'emptyStringStar':
          'The Kleene star of the empty string is the empty string',
      'unionIdempotence':
          'A union of identical expressions simplifies to one copy',
      'doubleStar': 'The star of a starred expression simplifies to one star',
      'plusToStar':
          'The union of the empty string and one-or-more repetitions equals zero-or-more repetitions',
      'plusToStarAlt':
          'The alternative one-or-more form with the empty string equals zero-or-more repetitions',
      'plusExpansion':
          'The plus operator expands to a concatenation with a star',
      'optionalExpansion':
          'The optional operator expands to a union with the empty string',
      'optionalStarSimplification':
          'The star of an optional expression simplifies to a star',
      'starConcatenationIdempotence':
          'A concatenation of identical stars simplifies to one star',
      'unionStarDistribution':
          'The star distributes over a union in specific patterns',
      'redundantParentheses':
          'Parentheses that do not affect precedence can be removed',
      'characterClassCreation':
          'Several single-character alternatives can form a character class',
      'other': 'Unknown simplification rule',
    });
    return '$_temp0';
  }

  @override
  String get regexSimplificationEmptyInput =>
      'A regular expression is required.';

  @override
  String regexSimplificationUnmatchedClosingParenthesis(int position) {
    return 'Unmatched closing parenthesis at position $position.';
  }

  @override
  String regexSimplificationUnclosedOpeningParentheses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count opening parentheses are not closed.',
      one: 'One opening parenthesis is not closed.',
    );
    return '$_temp0';
  }

  @override
  String get tmTapeBranchDeterministic => 'Deterministic execution';

  @override
  String get tmTapeBranchAcceptingNtm => 'Accepting NTM branch';

  @override
  String get tmTapeBranchRejectingNtm => 'Rejecting NTM branch';

  @override
  String get tmTapeBranchCyclicNtm => 'Cyclic NTM branch';

  @override
  String get tmTapeBranchLongestBoundedNtm => 'Longest bounded NTM branch';

  @override
  String get tmTapeInputLabel => 'Input';

  @override
  String get tmTapeSelectedBranchLabel => 'Selected branch';

  @override
  String get tmTapeConclusionLabel => 'Conclusion';

  @override
  String get tmTapeConclusionExact => 'Exact for this input';

  @override
  String get tmTapeConclusionBounded => 'Bounded';

  @override
  String get tmTapeExecutedTransitionsLabel => 'Executed transitions';

  @override
  String get tmTapeConfigurationsExploredLabel => 'Configurations explored';

  @override
  String get tmTapeStepLimitLabel => 'Step limit';

  @override
  String get tmTapeConfigurationLimitLabel => 'Configuration limit';

  @override
  String get tmTapeTimeLimitLabel => 'Time limit';

  @override
  String get tmTapeLimitReachedLabel => 'Limit reached';

  @override
  String get tmTapeLimitSteps => 'Step limit';

  @override
  String get tmTapeLimitConfigurations => 'Configuration limit';

  @override
  String get tmTapeLimitTimeout => 'Time limit';

  @override
  String get tmTapeChangedWritesLabel => 'Writes that changed a cell';

  @override
  String get tmTapeHeadReversalsLabel => 'Head reversals';

  @override
  String get tmTapeVisitedHeadIntervalLabel => 'Visited head interval';

  @override
  String get tmTapeDistinctCellsVisitedLabel => 'Distinct cells visited';

  @override
  String get tmTapeMaximumNonblankLabel =>
      'Maximum simultaneous nonblank cells';

  @override
  String get tmTapeDeclaredAlphabetLabel => 'Declared tape alphabet';

  @override
  String get tmTapeReadsBySymbolLabel => 'Reads by symbol';

  @override
  String get tmTapeWritesByOldSymbolLabel => 'Writes by old symbol';

  @override
  String get tmTapeWritesByNewSymbolLabel => 'Writes by new symbol';

  @override
  String get tmTapeHeadMovementsLabel => 'Head movements';

  @override
  String get tmTapeTransitionCountsLabel => 'Transition execution counts';

  @override
  String get tmTapeUnexecutedTransitionsLabel =>
      'Defined but not executed transitions';

  @override
  String get tmTapeSparseDiffLabel => 'Sparse initial-to-final tape diff';

  @override
  String get tmTapeCellTouchRangeLabel =>
      'First and last step touching each cell';

  @override
  String tmTapeDurationSeconds(String seconds) {
    return '$seconds s';
  }

  @override
  String tmTapeNamedCount(String name, String count) {
    return '$name: $count';
  }

  @override
  String tmTapeHeadInterval(String minimum, String maximum) {
    return '$minimum…$maximum';
  }

  @override
  String tmTapeCellDiff(
    String position,
    String initialSymbol,
    String finalSymbol,
  ) {
    return '$position: $initialSymbol → $finalSymbol';
  }

  @override
  String tmTapeCellTouchRange(String position, String first, String last) {
    return '$position: $first…$last';
  }

  @override
  String tmTapeTraceSubtitle(String transition, String tape) {
    return '$transition\n$tape';
  }

  @override
  String get regexToNfaStartTitle => 'Begin Thompson\'s construction';

  @override
  String regexToNfaStartExplanation(String regex) {
    return 'Converting \"$regex\" to an NFA with Thompson\'s construction. The algorithm creates one fragment for each subexpression, then combines the fragments with ε-transitions.';
  }

  @override
  String regexToNfaBasicSymbolTitle(String symbol) {
    return 'Create an NFA for \"$symbol\"';
  }

  @override
  String regexToNfaBasicSymbolExplanation(
    String symbol,
    String positionDescription,
    String startState,
    String acceptState,
    int stateCount,
    int transitionCount,
    String transitions,
    int stackSize,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      stateCount,
      locale: localeName,
      other: '$stateCount states',
      one: 'one state',
    );
    String _temp1 = intl.Intl.pluralLogic(
      transitionCount,
      locale: localeName,
      other: '$transitionCount transitions',
      one: 'one transition',
    );
    return 'Processing \"$symbol\" $positionDescription. Created a fragment from $startState to $acceptState with $_temp0 and $_temp1: $transitions. Stack depth: $stackSize.';
  }

  @override
  String get regexToNfaConcatenationTitle => 'Apply concatenation';

  @override
  String regexToNfaConcatenationExplanation(
    String positionDescription,
    String firstFragment,
    String secondFragment,
    String startState,
    String acceptStates,
    String transitions,
    int stackSize,
  ) {
    return 'Concatenating \"$firstFragment\" and \"$secondFragment\" $positionDescription. Added ε-bridges: $transitions. The resulting fragment starts at $startState and accepts at $acceptStates. Stack depth: $stackSize.';
  }

  @override
  String get regexToNfaUnionTitle => 'Apply union';

  @override
  String regexToNfaUnionExplanation(
    String positionDescription,
    String pattern,
    String startState,
    String acceptState,
    String transitions,
    int stackSize,
  ) {
    return 'Creating a union for \"$pattern\" $positionDescription. Added start state $startState, accept state $acceptState, and ε-transitions: $transitions. Either branch can be followed. Stack depth: $stackSize.';
  }

  @override
  String get regexToNfaKleeneStarTitle => 'Apply Kleene star (*)';

  @override
  String regexToNfaKleeneStarExplanation(
    String fragment,
    String positionDescription,
    String startState,
    String acceptState,
    String transitions,
    int stackSize,
  ) {
    return 'Applying Kleene star to \"$fragment\" $positionDescription. The fragment now starts at $startState, accepts at $acceptState, and uses these ε-transitions: $transitions. It accepts zero or more repetitions. Stack depth: $stackSize.';
  }

  @override
  String get regexToNfaPlusTitle => 'Apply plus (+)';

  @override
  String regexToNfaPlusExplanation(
    String fragment,
    String positionDescription,
    String startState,
    String acceptState,
    String transitions,
    int stackSize,
  ) {
    return 'Applying plus to \"$fragment\" $positionDescription. The fragment now starts at $startState, accepts at $acceptState, and uses these ε-transitions: $transitions. It requires at least one repetition. Stack depth: $stackSize.';
  }

  @override
  String get regexToNfaOptionalTitle => 'Apply optional (?)';

  @override
  String regexToNfaOptionalExplanation(
    String fragment,
    String positionDescription,
    String startState,
    String acceptState,
    String transitions,
    int stackSize,
  ) {
    return 'Making \"$fragment\" optional $positionDescription. The fragment now starts at $startState, accepts at $acceptState, and uses these ε-transitions: $transitions. It accepts zero or one occurrence. Stack depth: $stackSize.';
  }

  @override
  String get regexToNfaCompleteTitle => 'Complete NFA construction';

  @override
  String regexToNfaCompleteExplanation(
    String startState,
    String acceptState,
    int stateCount,
    int transitionCount,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      stateCount,
      locale: localeName,
      other: '$stateCount states',
      one: 'one state',
    );
    String _temp1 = intl.Intl.pluralLogic(
      transitionCount,
      locale: localeName,
      other: '$transitionCount transitions',
      one: 'one transition',
    );
    return 'Thompson\'s construction is complete. The NFA starts at $startState, accepts at $acceptState, and has $_temp0 and $_temp1. It accepts the language described by the regular expression.';
  }

  @override
  String get regexToNfaPositionUnavailable => 'at an implicit position';

  @override
  String regexToNfaPositionValue(int position) {
    return 'at position $position';
  }

  @override
  String regexToNfaStepTypeLabel(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'start': 'Start',
      'basicSymbol': 'Basic symbol',
      'concatenation': 'Concatenation',
      'union': 'Union',
      'kleeneStar': 'Kleene star',
      'plus': 'Plus',
      'optional': 'Optional',
      'complete': 'Complete',
      'other': 'Unknown step',
    });
    return '$_temp0';
  }

  @override
  String regexToNfaStepTypeDescription(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'start': 'Initialize Thompson\'s construction',
      'basicSymbol': 'Create an NFA fragment for one symbol',
      'concatenation': 'Concatenate two NFA fragments',
      'union': 'Create a union of two NFA fragments',
      'kleeneStar': 'Accept zero or more repetitions',
      'plus': 'Accept one or more repetitions',
      'optional': 'Accept zero or one occurrence',
      'complete': 'Finish the NFA construction',
      'other': 'Unknown conversion step',
    });
    return '$_temp0';
  }

  @override
  String faToRegexStepTitle(String type, String state) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'validation': 'Validate input automaton',
      'addInitialState': 'Add new initial state $state',
      'addFinalState': 'Add new final state $state',
      'selectState': 'Select $state for elimination',
      'findIncoming': 'Find incoming transitions',
      'findOutgoing': 'Find outgoing transitions',
      'findSelfLoop': 'Check self-loops on $state',
      'createBypass': 'Create bypass transitions',
      'combineTransitions': 'Combine parallel transitions',
      'completeElimination': 'Complete elimination of $state',
      'extractRegex': 'Extract final regular expression',
      'completion': 'Conversion complete',
      'other': 'FA-to-regex step',
    });
    return '$_temp0';
  }

  @override
  String faToRegexStepTypeLabel(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'validation': 'Validation',
      'addInitialState': 'Add initial state',
      'addFinalState': 'Add final state',
      'selectState': 'Select state',
      'findIncoming': 'Find incoming transitions',
      'findOutgoing': 'Find outgoing transitions',
      'findSelfLoop': 'Find self-loop',
      'createBypass': 'Create bypass transitions',
      'combineTransitions': 'Combine transitions',
      'completeElimination': 'Complete elimination',
      'extractRegex': 'Extract regular expression',
      'completion': 'Completion',
      'other': 'FA-to-regex step',
    });
    return '$_temp0';
  }

  @override
  String faToRegexStepTypeDescription(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'validation': 'Validate the input automaton.',
      'addInitialState': 'Add a unique initial state for normalization.',
      'addFinalState': 'Add a unique final state for normalization.',
      'selectState': 'Select the next state to eliminate.',
      'findIncoming': 'Find transitions entering the selected state.',
      'findOutgoing': 'Find transitions leaving the selected state.',
      'findSelfLoop': 'Find and process self-loops on the selected state.',
      'createBypass': 'Create transitions that bypass the selected state.',
      'combineTransitions':
          'Combine parallel transitions with regular-expression union.',
      'completeElimination':
          'Remove the selected state after replacing its paths.',
      'extractRegex':
          'Extract the final regular expression from the simplified automaton.',
      'completion': 'Finish the FA-to-regex conversion.',
      'other': 'Process an FA-to-regex conversion step.',
    });
    return '$_temp0';
  }

  @override
  String faToRegexEliminationSummary(
    String hasState,
    String state,
    int incomingStateCount,
    int outgoingStateCount,
    String hasSelfLoop,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      incomingStateCount,
      locale: localeName,
      other: '$incomingStateCount incoming states',
      one: '1 incoming state',
      zero: 'no incoming states',
    );
    String _temp1 = intl.Intl.pluralLogic(
      outgoingStateCount,
      locale: localeName,
      other: '$outgoingStateCount outgoing states',
      one: '1 outgoing state',
      zero: 'no outgoing states',
    );
    String _temp2 = intl.Intl.selectLogic(hasSelfLoop, {
      'true': 'a self-loop.',
      'other': 'no self-loop.',
    });
    String _temp3 = intl.Intl.selectLogic(hasState, {
      'true': 'Eliminating $state: $_temp0, $_temp1, $_temp2',
      'other': 'No state is being eliminated.',
    });
    return '$_temp3';
  }

  @override
  String faToRegexValidationExplanation(
    int stateCount,
    int transitionCount,
    String hasInitialState,
    String hasAcceptingStates,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      stateCount,
      locale: localeName,
      other: '$stateCount states',
      one: 'one state',
    );
    String _temp1 = intl.Intl.pluralLogic(
      transitionCount,
      locale: localeName,
      other: '$transitionCount transitions',
      one: 'one transition',
    );
    String _temp2 = intl.Intl.selectLogic(hasInitialState, {
      'true': 'An initial state is present.',
      'other': 'No initial state was found.',
    });
    String _temp3 = intl.Intl.selectLogic(hasAcceptingStates, {
      'true': 'Accepting states are present.',
      'other': 'There are no accepting states, so the language is empty.',
    });
    return 'Validating the input finite automaton. It has $_temp0 and $_temp1. $_temp2 $_temp3';
  }

  @override
  String faToRegexAddInitialStateExplanation(String newState, String oldState) {
    return 'Adding the new initial state $newState, with an ε-transition to the original initial state $oldState. This leaves one initial state with no incoming transitions.';
  }

  @override
  String faToRegexAddFinalStateExplanation(String newState, String oldStates) {
    return 'Adding the new final state $newState. The original accepting states, $oldStates, receive ε-transitions to it, leaving one accepting state with no outgoing transitions.';
  }

  @override
  String faToRegexSelectStateExplanation(
    String state,
    int remainingStateCount,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      remainingStateCount,
      locale: localeName,
      other: '$remainingStateCount states will remain',
      one: 'one state will remain',
    );
    return 'Selecting $state for elimination. Equivalent direct transitions will replace paths through it; $_temp0.';
  }

  @override
  String faToRegexFindIncomingExplanation(
    String state,
    int transitionCount,
    String states,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      transitionCount,
      locale: localeName,
      other: '$transitionCount transitions',
      one: 'one transition',
      zero: 'none',
    );
    return 'Finding transitions into $state. Found $_temp0 from: $states.';
  }

  @override
  String faToRegexFindOutgoingExplanation(
    String state,
    int transitionCount,
    String states,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      transitionCount,
      locale: localeName,
      other: '$transitionCount transitions',
      one: 'one transition',
      zero: 'none',
    );
    return 'Finding transitions out of $state. Found $_temp0 to: $states.';
  }

  @override
  String faToRegexFindSelfLoopExplanation(
    String hasLoop,
    String state,
    String selfLoopRegex,
  ) {
    String _temp0 = intl.Intl.selectLogic(hasLoop, {
      'true':
          'Found a self-loop on $state and combined it as $selfLoopRegex; this expression is inserted between incoming and outgoing transitions.',
      'other':
          'No self-loop was found on $state; new transitions connect incoming and outgoing states directly.',
    });
    return '$_temp0';
  }

  @override
  String faToRegexCreateBypassExplanation(
    int transitionCount,
    String state,
    String pathRegex,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      transitionCount,
      locale: localeName,
      other: '$transitionCount transitions',
      one: 'one transition',
    );
    return 'Creating $_temp0 to bypass $state. Each combines an incoming label, the self-loop closure, and an outgoing label; for example: $pathRegex.';
  }

  @override
  String faToRegexCombineTransitionsExplanation(
    int regexCount,
    String fromState,
    String toState,
    String regexes,
    String resultingRegex,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      regexCount,
      locale: localeName,
      other: '$regexCount expressions',
      one: 'one expression',
    );
    return 'Combining $_temp0 from $fromState to $toState with union: $regexes. Result: $resultingRegex.';
  }

  @override
  String faToRegexCompleteEliminationExplanation(
    String state,
    int remainingStateCount,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      remainingStateCount,
      locale: localeName,
      other: '$remainingStateCount states remain',
      one: 'one state remains',
    );
    return 'Eliminated $state. Equivalent direct transitions now replace every path through it; $_temp0.';
  }

  @override
  String faToRegexExtractRegexExplanation(
    String initialState,
    String finalState,
    String regex,
  ) {
    return 'All intermediate states are gone. Reading the transitions from initial state $initialState to final state $finalState gives: $regex.';
  }

  @override
  String faToRegexCompletionExplanation(
    int originalStateCount,
    String regex,
    int stepCount,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      originalStateCount,
      locale: localeName,
      other: '$originalStateCount-state automaton',
      one: 'one-state automaton',
    );
    String _temp1 = intl.Intl.pluralLogic(
      stepCount,
      locale: localeName,
      other: '$stepCount steps',
      one: 'one step',
    );
    return 'Converted the $_temp0 to $regex in $_temp1. The regular expression accepts the same language.';
  }

  @override
  String bruteForceInvalidLimitNonNegative(String limit) {
    return '$limit must not be negative.';
  }

  @override
  String bruteForceInvalidLimitPositive(String limit) {
    return '$limit must be positive.';
  }

  @override
  String get bruteForceEmptyGrammar =>
      'Grammar must have at least one production.';

  @override
  String get bruteForceInvalidStartSymbol =>
      'The start symbol must be a declared non-terminal.';

  @override
  String bruteForceOverlappingSymbols(String symbols) {
    return 'Grammar symbols cannot be both terminals and non-terminals: $symbols.';
  }

  @override
  String get bruteForceMalformedProduction =>
      'CFG brute-force search requires one declared non-terminal on every production LHS.';

  @override
  String get bruteForceDuplicateProductionId =>
      'CFG brute-force search requires unique production IDs.';

  @override
  String bruteForceUndeclaredSymbol(String production, String symbol) {
    return 'Production $production references undeclared symbol \"$symbol\".';
  }

  @override
  String bruteForceInvalidInputSymbol(String symbol) {
    return 'Input string contains invalid symbol: $symbol.';
  }

  @override
  String grammarInputTokenizationInvalidSymbol(String symbol, int position) {
    return 'Input string contains invalid symbol $symbol at position $position.';
  }

  @override
  String get bruteForceCancelled => 'CFG brute-force search was cancelled.';

  @override
  String get bruteForceRejectedExhausted =>
      'The finite CFG derivation frontier was exhausted soundly.';

  @override
  String bruteForceAcceptedAtLimit(String limit) {
    return 'Accepted, but witness enumeration stopped at the $limit limit.';
  }

  @override
  String bruteForceBoundedAtLimit(String limit) {
    return 'No witness was found before the $limit limit stopped search.';
  }

  @override
  String get pdaSimulationEmptyStateSet =>
      'A PDA must have at least one state.';

  @override
  String get pdaSimulationMissingInitialState =>
      'A PDA must have an initial state.';

  @override
  String get pdaSimulationInitialStateOutsideSet =>
      'The initial state must belong to the PDA state set.';

  @override
  String get pdaSimulationAcceptingStateOutsideSet =>
      'Every accepting state must belong to the PDA state set.';

  @override
  String get automatonSimulationDfaRequired =>
      'A DFA is required: the automaton must be deterministic and have no ε-transitions.';

  @override
  String get automatonSimulationEmptyAutomaton =>
      'Cannot simulate an empty automaton.';

  @override
  String get automatonSimulationMissingInitialState =>
      'The automaton must have an initial state.';

  @override
  String get automatonSimulationInitialStateOutsideSet =>
      'The initial state must belong to the state set.';

  @override
  String get automatonSimulationAcceptingStateOutsideSet =>
      'Every accepting state must belong to the state set.';

  @override
  String automatonSimulationInvalidInputSymbol(String symbol) {
    return 'The input string contains an invalid symbol: $symbol.';
  }

  @override
  String automatonSimulationNoDfaTransition(String state, String symbol) {
    return 'No transition from state $state on symbol $symbol.';
  }

  @override
  String get automatonSimulationRejectedNoAcceptingState =>
      'Rejected: no accepting state was reached.';

  @override
  String automatonSimulationNoNfaTransition(String symbol) {
    return 'No transition was found for symbol $symbol.';
  }

  @override
  String get automatonSimulationNfaNotAccepted =>
      'Input not accepted: no accepting state was reached.';

  @override
  String automatonSimulationComputationTreeTimeout(int steps) {
    return 'The NFA computation tree timed out after $steps steps.';
  }

  @override
  String automatonSimulationComputationTreeInfiniteLoop(int steps) {
    return 'The NFA computation tree detected an infinite loop after $steps steps.';
  }

  @override
  String automatonSimulationDfaFailure(String error) {
    return 'Unable to simulate the DFA: $error.';
  }

  @override
  String automatonSimulationNfaFailure(String error) {
    return 'Unable to simulate the NFA: $error.';
  }

  @override
  String automatonSimulationAcceptedStringsFailure(String error) {
    return 'Unable to enumerate accepted strings: $error.';
  }

  @override
  String automatonSimulationRejectedStringsFailure(String error) {
    return 'Unable to enumerate rejected strings: $error.';
  }

  @override
  String get automatonSimulationTransitionAppliedTitle => 'Transition applied';

  @override
  String automatonSimulationReadSymbol(String symbol) {
    return 'Read symbol \"$symbol\" from the input.';
  }

  @override
  String automatonSimulationTransitionDetail(
    String fromState,
    String symbol,
    String toState,
  ) {
    return 'From state $fromState, the transition on \"$symbol\" leads to $toState.';
  }

  @override
  String get automatonSimulationComputedEpsilonClosureTitle =>
      'Computed ε-closure';

  @override
  String get automatonSimulationEpsilonClosureBeforeReading =>
      'Before reading input, an NFA may take ε-transitions (moves that consume no input).';

  @override
  String automatonSimulationEpsilonClosureReached(
    String initialState,
    String stateSet,
  ) {
    return 'Starting from $initialState, ε-transitions reach: $stateSet.';
  }

  @override
  String get automatonSimulationSymbolConsumedTitle => 'Symbol consumed';

  @override
  String get automatonSimulationNondeterministicStep =>
      'This NFA step may have multiple active states (nondeterminism).';

  @override
  String automatonSimulationActiveSetAfterTransitions(
    String symbol,
    String stateSet,
  ) {
    return 'After taking all transitions on \"$symbol\", the active state set is $stateSet.';
  }

  @override
  String get automatonSimulationExpandedViaEpsilonTitle =>
      'Expanded via ε-transitions';

  @override
  String automatonSimulationEpsilonAfterConsuming(String symbol) {
    return 'After consuming \"$symbol\", we also follow any ε-transitions (moves that consume no input).';
  }

  @override
  String automatonSimulationEpsilonClosureExpanded(
    String before,
    String after,
  ) {
    return 'The ε-closure expanded the active state set from $before to $after.';
  }

  @override
  String automatonSimulationInitialStateDescription(String state) {
    return 'Initial state $state';
  }

  @override
  String automatonSimulationConsumedSymbolDescription(
    String symbol,
    String state,
  ) {
    return 'Consumed $symbol; now at $state';
  }

  @override
  String get automatonSimulationInitialEpsilonClosureDescription =>
      'Initial ε-closure';

  @override
  String get fsaKleeneStarEmptyOperand =>
      'The Kleene-star operand must contain at least one state.';

  @override
  String get fsaKleeneStarMissingInitialState =>
      'The Kleene-star operand must have an initial state.';

  @override
  String get fsaKleeneStarInitialStateOutsideSet =>
      'The Kleene-star operand has an initial state outside its state set.';

  @override
  String get fsaKleeneStarAcceptingStateOutsideSet =>
      'The Kleene-star operand has an accepting state outside its state set.';

  @override
  String get fsaKleeneStarNonFsaTransition =>
      'The Kleene-star operand contains a non-FSA transition.';

  @override
  String get fsaKleeneStarUnknownTransitionEndpoint =>
      'The Kleene-star operand contains a transition with an unknown endpoint.';

  @override
  String fsaKleeneStarInvalidTransition(String transition) {
    return 'The Kleene-star operand contains an invalid transition: $transition.';
  }

  @override
  String get fsaKleeneStarDuplicateStateIds =>
      'The Kleene-star result contains duplicate state IDs.';

  @override
  String get fsaKleeneStarDuplicateTransitionIds =>
      'The Kleene-star result contains duplicate transition IDs.';

  @override
  String get fsaKleeneStarInvalidResult =>
      'The Kleene-star result is not a valid finite automaton.';

  @override
  String get fsaKleeneStarInternalFailure =>
      'The Kleene-star construction failed.';

  @override
  String get fsaKleeneStarCloneTitle => 'Clone the operand';

  @override
  String get fsaKleeneStarEntryTitle => 'Add the epsilon entry';

  @override
  String get fsaKleeneStarRepeatTitle => 'Add repeat transitions';

  @override
  String get fsaKleeneStarExitTitle => 'Add exit transitions';

  @override
  String get fsaKleeneStarCloneExplanation =>
      'Copy every operand state into a separate, deterministic ID namespace.';

  @override
  String get fsaKleeneStarEntryExplanation =>
      'Create an accepting initial state so the result accepts epsilon, then connect it to the cloned operand.';

  @override
  String get fsaKleeneStarRepeatExplanation =>
      'Connect every former accepting state back to the cloned initial state with epsilon.';

  @override
  String get fsaKleeneStarRepeatEmptyExplanation =>
      'The operand language is empty, so there are no accepting states to repeat.';

  @override
  String get fsaKleeneStarExitExplanation =>
      'Create a distinct accepting exit and connect every former accepting state to it with epsilon.';

  @override
  String get fsaKleeneStarExitEmptyExplanation =>
      'The distinct accepting exit remains unreachable because the operand language is empty.';

  @override
  String get fsaReversalEmptyOperand =>
      'The reversal operand must contain at least one state.';

  @override
  String get fsaReversalMissingInitialState =>
      'The reversal operand must have an initial state.';

  @override
  String get fsaReversalInitialStateOutsideSet =>
      'The reversal operand has an initial state outside its state set.';

  @override
  String get fsaReversalAcceptingStateOutsideSet =>
      'The reversal operand has an accepting state outside its state set.';

  @override
  String get fsaReversalNonFsaTransition =>
      'The reversal operand contains a non-FSA transition.';

  @override
  String get fsaReversalUnknownTransitionEndpoint =>
      'The reversal operand contains a transition with an unknown endpoint.';

  @override
  String fsaReversalInvalidTransition(String transition) {
    return 'The reversal operand contains an invalid transition: $transition.';
  }

  @override
  String get fsaReversalDuplicateStateIds =>
      'The reversal result contains duplicate state IDs.';

  @override
  String get fsaReversalDuplicateTransitionIds =>
      'The reversal result contains duplicate transition IDs.';

  @override
  String get fsaReversalInvalidResult =>
      'The reversal result is not a valid finite automaton.';

  @override
  String get fsaReversalInternalFailure => 'The reversal construction failed.';

  @override
  String get fsaReversalCloneTitle => 'Clone and mirror the states';

  @override
  String get fsaReversalReverseTitle => 'Reverse every transition';

  @override
  String get fsaReversalEntryTitle => 'Add the new entry';

  @override
  String get fsaReversalAcceptingTitle => 'Set the reversed accepting state';

  @override
  String get fsaReversalCloneExplanation =>
      'Copy every state into a deterministic ID namespace and mirror the layout for the reversed flow.';

  @override
  String get fsaReversalReverseExplanation =>
      'Swap the source and target of every symbol and epsilon transition.';

  @override
  String get fsaReversalEntryExplanation =>
      'Create a fresh initial state and connect it by epsilon to every former accepting state.';

  @override
  String get fsaReversalEntryEmptyExplanation =>
      'Create a fresh initial state. The operand has no accepting states, so it has no epsilon entry edges.';

  @override
  String get fsaReversalAcceptingExplanation =>
      'Make the clone of the former initial state the sole accepting state.';

  @override
  String get fsaConcatenationLeftOperand => 'left operand';

  @override
  String get fsaConcatenationRightOperand => 'right operand';

  @override
  String fsaConcatenationEmptyOperand(String operand) {
    return 'The $operand must contain at least one state.';
  }

  @override
  String fsaConcatenationMissingInitialState(String operand) {
    return 'The $operand must have an initial state.';
  }

  @override
  String fsaConcatenationInitialStateOutsideSet(String operand) {
    return 'The $operand has an initial state outside its state set.';
  }

  @override
  String fsaConcatenationAcceptingStateOutsideSet(String operand) {
    return 'The $operand has an accepting state outside its state set.';
  }

  @override
  String fsaConcatenationNonFsaTransition(String operand) {
    return 'The $operand contains a non-FSA transition.';
  }

  @override
  String fsaConcatenationUnknownTransitionEndpoint(String operand) {
    return 'The $operand contains a transition with an unknown endpoint.';
  }

  @override
  String fsaConcatenationInvalidTransition(String operand, String transition) {
    return 'The $operand contains an invalid transition: $transition.';
  }

  @override
  String get fsaConcatenationDuplicateStateIds =>
      'The concatenation result contains duplicate state IDs.';

  @override
  String get fsaConcatenationDuplicateTransitionIds =>
      'The concatenation result contains duplicate transition IDs.';

  @override
  String get fsaConcatenationInvalidResult =>
      'The concatenation result is not a valid finite automaton.';

  @override
  String get fsaConcatenationInternalFailure =>
      'The concatenation construction failed.';

  @override
  String fsaConcatenationCloneTitle(String operand) {
    return 'Clone the $operand';
  }

  @override
  String get fsaConcatenationConnectTitle => 'Connect the operands';

  @override
  String fsaConcatenationCloneExplanation(String operand) {
    return 'Copy every state from the $operand into a separate ID namespace.';
  }

  @override
  String get fsaConcatenationConnectExplanation =>
      'Add one epsilon bridge from each former accepting state of the left operand to the initial state of the right operand.';

  @override
  String get fsaConcatenationConnectEmptyExplanation =>
      'The left language is empty, so no epsilon bridge is needed.';

  @override
  String get faToRegexEmptyAutomaton =>
      'The finite automaton must contain at least one state.';

  @override
  String get faToRegexMissingInitialState =>
      'The finite automaton must have an initial state.';

  @override
  String get faToRegexInitialStateOutsideSet =>
      'The initial state must belong to the finite automaton\'s state set.';

  @override
  String get faToRegexAcceptingStateOutsideSet =>
      'Every accepting state must belong to the finite automaton\'s state set.';

  @override
  String get faToRegexSimplificationFailed =>
      'The regular-expression simplification step failed after conversion.';

  @override
  String get faToRegexInternalFailure => 'The FA-to-regex conversion failed.';

  @override
  String get grammarCnfTypeRegular => 'regular';

  @override
  String get grammarCnfTypeContextFree => 'context-free';

  @override
  String get grammarCnfTypeContextSensitive => 'context-sensitive';

  @override
  String get grammarCnfTypeUnrestricted => 'unrestricted';

  @override
  String grammarCnfGrammarNotCfg(String type) {
    return 'CNF conversion expects a context-free grammar; received grammar type $type. The conversion will be attempted anyway.';
  }

  @override
  String get grammarCnfStartSymbolRenameFailed =>
      'Failed to introduce a new start symbol for CNF conversion because no fresh name was available.';

  @override
  String grammarCnfNotStrictCnf(String violations) {
    return 'CNF conversion produced productions that are not strictly CNF-shaped: $violations';
  }

  @override
  String grammarCnfNullableSubsetLimitExceeded(
    String production,
    int nullablePositions,
    int subsets,
    int limit,
  ) {
    return 'Skipping epsilon expansion for production $production: $nullablePositions nullable positions would require $subsets subsets, exceeding the limit of $limit.';
  }

  @override
  String grammarCnfNewSymbolLimitReached(int limit) {
    return 'The CNF conversion reached its limit of $limit generated non-terminals.';
  }

  @override
  String get grammarCnfStartSymbolTitle => 'Introduce a new start symbol';

  @override
  String get grammarCnfStartSymbolRationale =>
      'A fresh start symbol keeps the start variable out of right-hand sides while preserving the language.';

  @override
  String get grammarCnfEpsilonTitle => 'Remove epsilon productions';

  @override
  String get grammarCnfEpsilonRationale =>
      'Nullable productions are expanded and epsilon productions are removed, except where the language requires epsilon.';

  @override
  String get grammarCnfUnitTitle => 'Remove unit productions';

  @override
  String get grammarCnfUnitRationale =>
      'Unit-production chains are replaced with the productions they reach.';

  @override
  String get grammarCnfUselessTitle => 'Remove useless symbols';

  @override
  String get grammarCnfUselessRationale =>
      'Unproductive and unreachable symbols are removed from the grammar.';

  @override
  String get grammarCnfBinarizeTitle => 'Replace terminals and binarize';

  @override
  String get grammarCnfBinarizeRationale =>
      'Terminals in long right-hand sides are isolated and productions are split into binary form.';

  @override
  String get pdaNormalizationEmptyPda => 'Cannot normalize an empty PDA.';

  @override
  String get pdaNormalizationMissingInitialState =>
      'The PDA must define an initial state before normalization.';

  @override
  String get pdaNormalizationInitialStateOutsideSet =>
      'The PDA initial state must belong to the PDA state set.';

  @override
  String pdaNormalizationInitialStackSymbolOutsideAlphabet(String symbol) {
    return 'The initial stack symbol $symbol must belong to the stack alphabet.';
  }

  @override
  String get pdaNormalizationMissingAcceptingState =>
      'The selected source mode requires at least one accepting state.';

  @override
  String get pdaNormalizationAcceptingStateOutsideSet =>
      'Every accepting state must belong to the PDA state set.';

  @override
  String get pdaNormalizationNonPdaTransition =>
      'PDA normalization only supports PDA transitions.';

  @override
  String pdaNormalizationTransitionEndpointOutsideSet(String transition) {
    return 'Transition $transition references a state outside the PDA.';
  }

  @override
  String pdaNormalizationTransitionPopSymbolOutsideAlphabet(
    String transition,
    String symbol,
  ) {
    return 'Transition $transition pops stack symbol $symbol, which is outside the stack alphabet.';
  }

  @override
  String pdaNormalizationTransitionPushSymbolOutsideAlphabet(
    String transition,
    String symbol,
  ) {
    return 'Transition $transition pushes stack symbol $symbol, which is outside the stack alphabet.';
  }

  @override
  String pdaNormalizationGrowthWarningSummary(int states, int transitions) {
    String _temp0 = intl.Intl.pluralLogic(
      states,
      locale: localeName,
      other: '$states states',
      one: 'one state',
      zero: 'no states',
    );
    String _temp1 = intl.Intl.pluralLogic(
      transitions,
      locale: localeName,
      other: '$transitions transitions',
      one: 'one transition',
      zero: 'no transitions',
    );
    return 'Normalization may increase the state and transition count. It generated $_temp0 and $_temp1.';
  }

  @override
  String get pdaNormalizationIntroducedNondeterminism =>
      'The conversion changed a deterministic source into a non-deterministic PDA.';

  @override
  String pdaNormalizationInitialStateDescription(String state) {
    return 'Fresh initial state that installs the bottom marker from source state $state.';
  }

  @override
  String get pdaNormalizationAcceptanceStateDescription =>
      'State reached after the simulated source stack empties.';

  @override
  String get pdaNormalizationDrainStateDescription =>
      'State that drains residual stack content after acceptance.';

  @override
  String pdaNormalizationInitializeTransitionDescription(String state) {
    return 'Installs the source initial stack above the bottom marker before entering state $state.';
  }

  @override
  String pdaNormalizationSinglePopTransitionDescription(String transition) {
    return 'Single-pop expansion of source transition $transition.';
  }

  @override
  String pdaNormalizationAcceptEmptyTransitionDescription(
    String state,
    String mode,
  ) {
    return 'Converts an empty source stack from state $state to $mode acceptance.';
  }

  @override
  String pdaNormalizationEnterDrainTransitionDescription(String state) {
    return 'Starts draining the stack from accepting state $state.';
  }

  @override
  String get pdaNormalizationDrainTransitionDescription =>
      'Pops one residual stack symbol in the drain state.';

  @override
  String get grammarGnfTransformFailed =>
      'The grammar could not be converted to Greibach Normal Form.';

  @override
  String get grammarGnfNotGnf =>
      'The conversion result does not satisfy Greibach Normal Form.';

  @override
  String get grammarGnfConvertTitle => 'Convert to Greibach Normal Form';

  @override
  String get grammarGnfConvertRationale =>
      'Each production is rewritten as A → aα: a terminal followed by zero or more non-terminals.';

  @override
  String get grammarToPdaEmptyGrammar =>
      'The grammar must contain at least one production.';

  @override
  String get grammarToPdaMissingStartSymbol =>
      'The grammar must have a start symbol.';

  @override
  String grammarToPdaUndeclaredStartSymbol(String symbol) {
    return 'Start symbol $symbol must be declared as a non-terminal.';
  }

  @override
  String grammarToPdaDuplicateProductionId(String production) {
    return 'Production ID $production is duplicated.';
  }

  @override
  String get grammarToPdaNotContextFree => 'The grammar is not context-free.';

  @override
  String grammarToPdaConversionTimedOut(int timeout) {
    return 'Grammar-to-PDA conversion timed out after $timeout seconds.';
  }

  @override
  String get grammarToPdaInternalConversionFailure =>
      'The grammar-to-PDA conversion failed.';

  @override
  String get grammarToPdaGnfConversionFailed =>
      'The grammar could not be converted to Greibach Normal Form for PDA construction.';

  @override
  String get grammarToPdaInvalidGnfResult =>
      'The Greibach conversion did not produce a valid GNF grammar.';

  @override
  String get grammarToPdaAnalysisFailed =>
      'The grammar-to-PDA conversion analysis failed.';

  @override
  String grammarToPdaAnalysisTimedOut(int timeout) {
    return 'Grammar-to-PDA analysis timed out after $timeout seconds.';
  }

  @override
  String get grammarToPdaValidateGrammarStep => 'Validate the grammar';

  @override
  String get grammarToPdaCreateInitialStateStep => 'Create the initial state';

  @override
  String get grammarToPdaCreateProcessingStateStep =>
      'Create the processing state';

  @override
  String get grammarToPdaCreateAcceptingStateStep =>
      'Create the accepting state';

  @override
  String get grammarToPdaAddTransitionsStep => 'Add transitions';

  @override
  String get pdaSimplificationEmptyPda => 'Cannot simplify an empty PDA.';

  @override
  String get pdaSimplificationMissingInitialState =>
      'The PDA must define an initial state before simplification.';

  @override
  String get pdaSimplificationInitialStateOutsideSet =>
      'The PDA initial state must belong to the PDA state set.';

  @override
  String get pdaSimplificationAcceptingStateOutsideSet =>
      'Every accepting state must belong to the PDA state set.';

  @override
  String pdaSimplificationMissingAcceptingState(String mode) {
    return 'Acceptance mode $mode requires at least one accepting state.';
  }

  @override
  String get pdaSimplificationInvalidPda =>
      'The PDA is not valid for simplification.';

  @override
  String get pdaSimplificationNonPdaTransition =>
      'PDA simplification only supports PDA transitions.';

  @override
  String pdaSimplificationTransitionEndpointOutsideSet(String transition) {
    return 'Transition $transition references a state outside the PDA.';
  }

  @override
  String pdaSimplificationInvalidTransition(String transition) {
    return 'Transition $transition is not valid for PDA simplification.';
  }

  @override
  String get pdaSimplificationInputAlphabetEmptySymbol =>
      'The PDA input alphabet cannot contain an empty symbol.';

  @override
  String get pdaSimplificationStackAlphabetEmptySymbol =>
      'The PDA stack alphabet cannot contain an empty symbol.';

  @override
  String pdaSimplificationTransitionInputSymbolOutsideAlphabet(
    String transition,
    String symbol,
  ) {
    return 'Transition $transition reads input symbol $symbol, which is outside the input alphabet.';
  }

  @override
  String pdaSimplificationDuplicateTransitionIds(String transition) {
    return 'Transition ID $transition is duplicated.';
  }

  @override
  String get pdaSimplificationBoundedLengthNegative =>
      'The bounded comparison length cannot be negative.';

  @override
  String get pdaSimplificationBoundedSymbolsEmpty =>
      'The bounded comparison alphabet cannot contain an empty symbol.';

  @override
  String pdaSimplificationBoundedSymbolOutsideAlphabet(String symbol) {
    return 'Bounded comparison symbol $symbol is outside the PDA input alphabet.';
  }

  @override
  String get pdaSimplificationValidationComplete => 'PDA validation completed.';

  @override
  String get pdaSimplificationEveryStateReachable =>
      'Every PDA state is structurally reachable.';

  @override
  String pdaSimplificationRemovedUnreachableStates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unreachable states',
      one: 'one unreachable state',
    );
    return 'Removed $_temp0.';
  }

  @override
  String get pdaSimplificationSemanticUsefulnessUnavailable =>
      'Exact semantic usefulness is unavailable for general NPDAs; uncertain states were retained.';

  @override
  String get pdaSimplificationSemanticUsefulnessDisabled =>
      'Semantic usefulness analysis was disabled.';

  @override
  String get pdaSimplificationStrongBisimulationComputed =>
      'Strong bisimulation groups were computed.';

  @override
  String get pdaSimplificationStrongBisimulationDisabled =>
      'Strong bisimulation analysis was disabled.';

  @override
  String get pdaSimplificationRebuildValidationComplete =>
      'The rebuilt PDA passed validation.';

  @override
  String pdaSimplificationBoundedSamplePassed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words',
      one: 'one word',
    );
    return 'The bounded comparison checked $_temp0 successfully.';
  }

  @override
  String get pdaSimplificationBoundedComparisonDisabled =>
      'Bounded language comparison was disabled.';

  @override
  String get pdaSimplificationInvalidRebuiltPda =>
      'The rebuilt PDA failed validation.';

  @override
  String pdaSimplificationBoundedComparisonInconclusive(String word) {
    return 'The bounded comparison was inconclusive for input word $word.';
  }

  @override
  String pdaSimplificationBoundedComparisonSimulationLimit(String word) {
    return 'The bounded comparison reached a simulation limit for input word $word; the result is inconclusive.';
  }

  @override
  String pdaSimplificationBoundedComparisonAcceptanceMismatch(String word) {
    return 'The original and simplified PDAs disagree on input word $word.';
  }

  @override
  String get fsaToGrammarEmptyAutomaton =>
      'The automaton must contain at least one state.';

  @override
  String get fsaToGrammarMissingInitialState =>
      'The automaton must have an initial state.';

  @override
  String get fsaToGrammarInitialStateOutsideSet =>
      'The initial state must belong to the automaton.';

  @override
  String get fsaToGrammarAcceptingStateOutsideSet =>
      'Every accepting state must belong to the automaton.';

  @override
  String get grammarToFsaMissingNonterminals =>
      'The grammar must declare at least one non-terminal.';

  @override
  String get grammarToFsaUndeclaredStartSymbol =>
      'The start symbol must be a declared non-terminal.';

  @override
  String grammarToFsaLeftSideNotSingle(String production) {
    return 'Production $production must have exactly one non-terminal on the left side.';
  }

  @override
  String grammarToFsaUnknownLeftNonterminal(String production, String symbol) {
    return 'Production $production uses unknown non-terminal $symbol.';
  }

  @override
  String grammarToFsaUnknownRightNonterminal(String production, String symbol) {
    return 'Production $production references undefined non-terminal $symbol.';
  }

  @override
  String grammarToFsaTooManyRightSymbols(String production) {
    return 'Production $production is not right-linear because its right side has too many symbols.';
  }

  @override
  String grammarToFsaFirstSymbolNotTerminal(String production) {
    return 'Production $production must start with a terminal symbol.';
  }

  @override
  String grammarToFsaLastSymbolNotNonterminal(String production) {
    return 'Production $production must end with a non-terminal symbol.';
  }

  @override
  String dfaOperationsMissingInitialState(String context) {
    String _temp0 = intl.Intl.selectLogic(context, {
      'dfa': 'DFA',
      'complementDfa': 'DFA for complement',
      'prefixClosure': 'DFA for prefix closure',
      'suffixClosure': 'DFA for suffix closure',
      'operandA': 'operand A',
      'operandB': 'operand B',
      'other': 'DFA',
    });
    return 'The $_temp0 must have a defined initial state.';
  }

  @override
  String dfaOperationsNondeterministic(String context) {
    String _temp0 = intl.Intl.selectLogic(context, {
      'dfa': 'DFA',
      'complementDfa': 'DFA for complement',
      'prefixClosure': 'DFA for prefix closure',
      'suffixClosure': 'DFA for suffix closure',
      'operandA': 'operand A',
      'operandB': 'operand B',
      'other': 'DFA',
    });
    return 'The $_temp0 must be deterministic (no nondeterministic transitions).';
  }

  @override
  String dfaOperationsEpsilonTransitionsNotAllowed(String context) {
    String _temp0 = intl.Intl.selectLogic(context, {
      'dfa': 'DFA',
      'complementDfa': 'DFA for complement',
      'prefixClosure': 'DFA for prefix closure',
      'suffixClosure': 'DFA for suffix closure',
      'operandA': 'operand A',
      'operandB': 'operand B',
      'other': 'DFA',
    });
    return 'The $_temp0 cannot contain ε (epsilon) transitions.';
  }

  @override
  String dfaOperationsSymbolOutsideAlphabet(String context, String symbol) {
    String _temp0 = intl.Intl.selectLogic(context, {
      'dfa': 'DFA',
      'complementDfa': 'DFA for complement',
      'prefixClosure': 'DFA for prefix closure',
      'suffixClosure': 'DFA for suffix closure',
      'operandA': 'operand A',
      'operandB': 'operand B',
      'other': 'DFA',
    });
    return 'The $_temp0 has a transition with a symbol outside the alphabet: \"$symbol\".';
  }

  @override
  String dfaOperationsEmptyAlphabetWithLabeledTransitions(String operand) {
    String _temp0 = intl.Intl.selectLogic(operand, {
      'a': 'Operand A',
      'b': 'Operand B',
      'other': 'The operand',
    });
    return '$_temp0 has labeled transitions, but the alphabet is empty.';
  }

  @override
  String get dfaOperationsBothOperandsMissingInitialState =>
      'Both DFAs must have a defined initial state.';

  @override
  String dfaOperationsOperationFailed(String operation) {
    String _temp0 = intl.Intl.selectLogic(operation, {
      'union': 'union',
      'intersection': 'intersection',
      'difference': 'difference',
      'complement': 'complement',
      'prefixClosure': 'prefix closure',
      'suffixClosure': 'suffix closure',
      'removeLambda': 'epsilon-transition removal',
      'other': 'operation',
    });
    return 'Error computing the DFA $_temp0.';
  }

  @override
  String get dfaOperationsEpsilonRemovalFailed =>
      'Error removing ε-transitions.';

  @override
  String get dfaMinimizationEmptyDfa => 'Cannot minimize an empty DFA.';

  @override
  String get dfaMinimizationMissingInitialState =>
      'The DFA must have an initial state.';

  @override
  String get dfaMinimizationInitialStateOutsideSet =>
      'The initial state must belong to the DFA state set.';

  @override
  String get dfaMinimizationAcceptingStateOutsideSet =>
      'Every accepting state must belong to the DFA state set.';

  @override
  String get dfaMinimizationNondeterministicInput =>
      'Input must be a deterministic automaton.';

  @override
  String get dfaMinimizationFailed => 'Error minimizing the DFA.';

  @override
  String get dfaMinimizationWithStepsFailed =>
      'Error minimizing the DFA with steps.';

  @override
  String get cfgToolkitReduceFailed => 'CFG reduction failed.';

  @override
  String get cfgToolkitToCnfFailed => 'CFG to CNF conversion failed.';

  @override
  String get cfgToolkitToGnfFailed => 'CFG to GNF conversion failed.';

  @override
  String get cykTimedOut => 'CYK parsing timed out.';

  @override
  String cykInputRejected(String input) {
    return 'The input string $input cannot be derived from the grammar.';
  }

  @override
  String get cykParseFailed => 'CYK parsing failed.';

  @override
  String get grammarParserEmptyGrammar =>
      'The grammar must contain at least one production.';

  @override
  String get grammarParserMissingStartSymbol =>
      'The grammar must have a start symbol.';

  @override
  String get grammarParserStartSymbolNotNonterminal =>
      'The start symbol must be a non-terminal.';

  @override
  String grammarParserInputRejected(String input) {
    return 'The input string $input cannot be derived from the grammar.';
  }

  @override
  String grammarParserAllStrategiesFailed(String strategy) {
    String _temp0 = intl.Intl.selectLogic(strategy, {
      'auto': 'available',
      'bruteForce': 'brute-force',
      'cyk': 'CYK',
      'll': 'LL(1)',
      'lr': 'LR(1)',
      'other': 'available',
    });
    return 'All $_temp0 parsing strategies failed.';
  }

  @override
  String get grammarParserGeneratedStringsFailed =>
      'Generating grammar strings failed.';

  @override
  String grammarParserLl1StepLimitInvalid(int limit) {
    return 'The LL(1) step limit must be greater than zero (received $limit).';
  }

  @override
  String grammarParserLl1Conflict(
    String nonTerminal,
    String lookahead,
    String alternatives,
  ) {
    return 'LL(1) conflict for non-terminal $nonTerminal with lookahead $lookahead: $alternatives.';
  }

  @override
  String get grammarParserLl1Cancelled => 'LL(1) parsing was cancelled.';

  @override
  String grammarParserLl1TimedOut(int timeout) {
    return 'LL(1) parsing timed out after $timeout ms.';
  }

  @override
  String grammarParserLl1StepLimitReached(int limit) {
    return 'LL(1) parsing reached its step limit of $limit.';
  }

  @override
  String grammarParserLl1TrailingInput(String lookahead, int position) {
    return 'Unexpected trailing input symbol $lookahead at position $position.';
  }

  @override
  String grammarParserLl1UnexpectedEnd(String expected) {
    return 'Unexpected end of input; expected $expected.';
  }

  @override
  String grammarParserLl1TerminalMismatch(
    String expected,
    String found,
    int position,
  ) {
    return 'Expected $expected at position $position, but found $found.';
  }

  @override
  String grammarParserLl1EmptyTableCell(
    String nonTerminal,
    String lookahead,
    String expected,
  ) {
    return 'The LL(1) table has no entry for $nonTerminal with lookahead $lookahead; expected $expected.';
  }

  @override
  String get grammarParserLl1EmptyStack =>
      'The LL(1) parser stack became empty before parsing completed.';

  @override
  String get grammarParserEarleyMalformedProduction =>
      'The grammar contains a production malformed for Earley parsing.';

  @override
  String get grammarParserEarleyMissingStartSymbol =>
      'Earley parsing requires a declared non-terminal start symbol.';

  @override
  String grammarParserEarleyTimedOut(int timeout) {
    return 'Earley parsing timed out after $timeout ms.';
  }

  @override
  String get grammarParserRecursiveDescentTimedOut =>
      'Recursive-descent parsing timed out.';

  @override
  String get grammarParserRecursiveDescentFailed =>
      'Recursive-descent parsing failed.';

  @override
  String get lr1ParserStaleConstruction =>
      'The LR(1) construction is stale; rebuild the parsing table.';

  @override
  String get lr1ParserInvalidGrammar =>
      'The grammar is invalid for LR(1) parsing.';

  @override
  String get lr1ParserMissingStartSymbol =>
      'The grammar must have a start symbol for LR(1) parsing.';

  @override
  String get lr1ParserMalformedProduction =>
      'The grammar contains a malformed production for LR(1) parsing.';

  @override
  String lr1ParserDuplicateProductionId(String production) {
    return 'Production $production has a duplicate identifier.';
  }

  @override
  String lr1ParserUndeclaredSymbol(String production, String symbol) {
    return 'Production $production uses undeclared symbol $symbol.';
  }

  @override
  String get lr1ParserConstructionCancelled =>
      'LR(1) table construction was cancelled.';

  @override
  String lr1ParserConstructionTimedOut(int timeout) {
    return 'LR(1) table construction timed out after $timeout ms.';
  }

  @override
  String get lr1ParserConstructionStateLimit =>
      'LR(1) table construction reached its state limit.';

  @override
  String get lr1ParserConstructionItemLimit =>
      'LR(1) table construction reached its item limit.';

  @override
  String lr1ParserConflict(String state, String lookahead) {
    return 'LR(1) conflict in state $state with lookahead $lookahead.';
  }

  @override
  String get lr1ParserCancelled => 'LR(1) parsing was cancelled.';

  @override
  String lr1ParserTimedOut(int timeout) {
    return 'LR(1) parsing timed out after $timeout ms.';
  }

  @override
  String lr1ParserStepLimitReached(int limit) {
    return 'LR(1) parsing reached its step limit of $limit.';
  }

  @override
  String lr1ParserEmptyActionCell(String state, String lookahead) {
    return 'No LR(1) action exists for state $state with lookahead $lookahead.';
  }

  @override
  String lr1ParserActionConflict(String state, String lookahead) {
    return 'Multiple LR(1) actions conflict in state $state with lookahead $lookahead.';
  }

  @override
  String get lr1ParserInvalidParserState =>
      'The LR(1) parser state is invalid.';

  @override
  String lr1ParserMissingGoto(String state, String nonTerminal) {
    return 'No LR(1) goto entry exists for state $state and non-terminal $nonTerminal.';
  }

  @override
  String lr1ParserShifted(String symbol, String targetState) {
    return 'Shift $symbol and enter parser state $targetState.';
  }

  @override
  String lr1ParserReduced(
    String production,
    String leftSide,
    String rightSide,
  ) {
    return 'Reduce by $production: $leftSide → $rightSide.';
  }

  @override
  String get lr1ParserAccepted => 'The LR(1) parser accepted the input.';

  @override
  String get tmSimulationEmptyMachine =>
      'Cannot simulate an empty Turing machine.';

  @override
  String get tmSimulationMissingInitialState =>
      'The Turing machine must have an initial state.';

  @override
  String get tmSimulationInitialStateOutsideSet =>
      'The initial state must belong to the Turing machine.';

  @override
  String get tmSimulationAcceptingStateOutsideSet =>
      'Every accepting state must belong to the Turing machine.';

  @override
  String tmSimulationInvalidInputSymbol(String symbol) {
    return 'The input contains a symbol outside the Turing machine alphabet: $symbol.';
  }

  @override
  String get tmSimulationOperationsPerBatchInvalid =>
      'Operations per batch must be greater than zero.';

  @override
  String tmSimulationNondeterministicConflict(
    int count,
    String state,
    String symbol,
  ) {
    return 'The machine has $count transitions for state $state on symbol $symbol.';
  }

  @override
  String get tmSimulationRejectedNoAcceptingConfiguration =>
      'No accepting configuration was found.';

  @override
  String get tmSimulationInputNotAccepted => 'The input was not accepted.';

  @override
  String get tmSimulationTimeout => 'The Turing machine simulation timed out.';

  @override
  String get tmSimulationInfiniteLoop => 'An infinite loop was detected.';

  @override
  String get tmSimulationStepLimit =>
      'Step limit reached; the result is inconclusive';

  @override
  String get tmSimulationConfigurationLimit =>
      'Configuration limit reached; the result is inconclusive';

  @override
  String get tmSimulationAcceptanceUnresolved =>
      'The bounded simulation did not resolve acceptance.';

  @override
  String tmSimulationDtmFailure(String error) {
    return 'DTM simulation failed: $error';
  }

  @override
  String tmSimulationNtmFailure(String error) {
    return 'NTM simulation failed: $error';
  }

  @override
  String tmSimulationGenericFailure(String error) {
    return 'Turing machine simulation failed: $error';
  }

  @override
  String tmSimulationAcceptedStringsFailure(String error) {
    return 'Finding accepted strings failed: $error';
  }

  @override
  String tmSimulationRejectedStringsFailure(String error) {
    return 'Finding rejected strings failed: $error';
  }

  @override
  String tmSimulationAnalysisFailure(String error) {
    return 'Turing machine analysis failed: $error';
  }

  @override
  String get tmSimulationTransitionTitle => 'Turing machine transition';

  @override
  String tmSimulationReadSymbol(String symbol, int position, String state) {
    return 'Read $symbol at tape position $position in state $state.';
  }

  @override
  String tmSimulationAppliedRule(
    String fromState,
    String readSymbol,
    String toState,
    String writeSymbol,
    String direction,
  ) {
    String _temp0 = intl.Intl.selectLogic(direction, {
      'L': 'left',
      'R': 'right',
      'S': 'stay',
      'other': '$direction',
    });
    return 'Applied rule: $fromState,$readSymbol → $toState,$writeSymbol,$_temp0.';
  }

  @override
  String tmSimulationWroteSymbol(String symbol, int position) {
    return 'Wrote $symbol at tape position $position.';
  }

  @override
  String tmSimulationMovedHead(String direction, int position) {
    String _temp0 = intl.Intl.selectLogic(direction, {
      'L': 'left',
      'R': 'right',
      'S': 'stay',
      'other': '$direction',
    });
    return 'Moved the head $_temp0 to position $position.';
  }

  @override
  String get tmExecutionEmptyMachine =>
      'The Turing machine must have at least one state.';

  @override
  String get tmExecutionMissingInitialState =>
      'The Turing machine must define a valid initial state.';

  @override
  String get tmExecutionStepLimitInvalid =>
      'The step limit must be greater than zero.';

  @override
  String get tmExecutionConfigurationLimitInvalid =>
      'The configuration limit must be greater than zero.';

  @override
  String get tmExecutionTimeoutInvalid =>
      'The timeout must be greater than zero.';

  @override
  String get tmExecutionOperationsPerBatchInvalid =>
      'Operations per batch must be greater than zero.';

  @override
  String tmExecutionInvalidInputSymbol(String symbol) {
    return 'The input contains a symbol outside the Turing machine alphabet: $symbol.';
  }

  @override
  String tmExecutionInvalidMachine(String detail) {
    return 'The Turing machine is invalid: $detail';
  }

  @override
  String get tmExecutionCancelled => 'TM execution analysis was cancelled.';

  @override
  String get tmExecutionTimeoutBeforeResolution =>
      'The timeout was reached before execution was resolved.';

  @override
  String tmExecutionEnteredFinalState(String policy) {
    String _temp0 = intl.Intl.selectLogic(policy, {
      'finalState': 'final-state',
      'halting': 'halting',
      'finalStateOrHalting': 'final-state-or-halting',
      'other': 'selected',
    });
    return 'The machine entered a final state under the $_temp0 policy.';
  }

  @override
  String tmExecutionHaltedAccepted(String policy) {
    String _temp0 = intl.Intl.selectLogic(policy, {
      'finalState': 'final-state',
      'halting': 'halting',
      'finalStateOrHalting': 'final-state-or-halting',
      'other': 'selected',
    });
    return 'The machine halted under the $_temp0 policy.';
  }

  @override
  String get tmExecutionHaltedRejected =>
      'The machine halted outside a final state.';

  @override
  String tmExecutionDeterministicConflict(
    int count,
    String state,
    String symbol,
  ) {
    return 'The deterministic machine has $count transitions for state $state on symbol $symbol.';
  }

  @override
  String get tmExecutionStepLimit =>
      'The step limit was reached without a resolved outcome.';

  @override
  String get tmExecutionConfigurationLimit =>
      'The configuration limit was reached without a resolved outcome.';

  @override
  String get tmExecutionDeterministicCycle =>
      'A deterministic cycle was detected.';

  @override
  String get tmExecutionBranchStepLimit =>
      'At least one branch reached the step limit.';

  @override
  String get tmExecutionEveryBranchRejected =>
      'Every reachable branch halted without acceptance.';

  @override
  String get tmExecutionExploredGraphRejected =>
      'The explored configuration graph contains no accepting configuration.';

  @override
  String get tmSpaceProfileEmptyMachine =>
      'The Turing machine must have at least one state.';

  @override
  String get tmSpaceProfileMissingInitialState =>
      'The Turing machine must define a valid initial state.';

  @override
  String get tmSpaceProfileMaxInputLengthInvalid =>
      'Maximum input length must be non-negative.';

  @override
  String get tmSpaceProfileCandidateCapInvalid =>
      'Candidate cap per length must be greater than zero.';

  @override
  String get tmSpaceProfileStepLimitInvalid =>
      'Step limit must be greater than zero.';

  @override
  String get tmSpaceProfileConfigurationLimitInvalid =>
      'Configuration limit must be greater than zero.';

  @override
  String get tmSpaceProfileTimeoutInvalid =>
      'Timeout must be greater than zero.';

  @override
  String get tmSpaceProfileOperationsPerBatchInvalid =>
      'Operations per batch must be greater than zero.';

  @override
  String get tmSpaceProfileMissingSpaceMetrics =>
      'Bounded execution did not return tape-space metrics.';

  @override
  String get tmTimeProfileMaxLengthInvalid =>
      'Maximum input length must be non-negative.';

  @override
  String get tmTimeProfileCandidateCapInvalid =>
      'Candidate cap per length must be greater than zero.';

  @override
  String get tmTimeProfileStepLimitInvalid =>
      'Step limit must be greater than zero.';

  @override
  String get tmTimeProfileConfigurationLimitInvalid =>
      'Configuration limit must be greater than zero.';

  @override
  String get tmTimeProfileTimeoutInvalid =>
      'Timeout must be greater than zero.';

  @override
  String get tmTimeProfileOperationsPerBatchInvalid =>
      'Operations per batch must be greater than zero.';

  @override
  String get tmTimeProfileComplete => 'The time profile completed.';

  @override
  String get tmTimeProfileIncomplete =>
      'The bounded profile is incomplete because a row was sampled or an execution remained unknown.';

  @override
  String get tmTimeProfileCancelled => 'Time profiling was cancelled.';

  @override
  String get tmTimeProfileInvalidMachine => 'The Turing machine is invalid.';

  @override
  String get tmReachabilityEmptyMachine =>
      'The Turing machine must have at least one state.';

  @override
  String get tmReachabilityInvalidInitialState =>
      'The Turing machine must define a valid initial state.';

  @override
  String get tmReachabilityInputsRequired =>
      'At least one input is required for reachability analysis.';

  @override
  String get tmReachabilityStepLimitInvalid =>
      'Step limit must be greater than zero.';

  @override
  String get tmReachabilityConfigurationLimitInvalid =>
      'Configuration limit must be greater than zero.';

  @override
  String get tmReachabilityTimeoutInvalid =>
      'Timeout must be greater than zero.';

  @override
  String get tmReachabilityOperationsPerBatchInvalid =>
      'Operations per batch must be greater than zero.';

  @override
  String get tmReachabilityNonTmTransition =>
      'The machine contains a transition that is not a Turing-machine transition.';

  @override
  String tmReachabilityTransitionEndpointOutsideSet(String transition) {
    return 'Transition $transition has an endpoint outside the machine state set.';
  }

  @override
  String tmReachabilityInputSymbolOutsideAlphabet(String input, String symbol) {
    return 'Input $input contains symbol $symbol outside the machine alphabet.';
  }

  @override
  String get tmReachabilityCancelled => 'Reachability analysis was cancelled.';

  @override
  String get tmReachabilityTimeout => 'Reachability analysis timed out.';

  @override
  String get tmReachabilityConfigurationLimit =>
      'Reachability analysis reached its configuration limit.';

  @override
  String get tmReachabilityStepLimit =>
      'Reachability analysis reached its step limit.';

  @override
  String get tmReachabilityComplete => 'Reachability analysis completed.';

  @override
  String get tmLanguageExplorerMaxInputLengthInvalid =>
      'Maximum input length must be non-negative.';

  @override
  String get tmLanguageExplorerCandidateCapInvalid =>
      'Candidate cap per length must be greater than zero.';

  @override
  String get tmLanguageExplorerStepLimitInvalid =>
      'Step limit must be greater than zero.';

  @override
  String get tmLanguageExplorerConfigurationLimitInvalid =>
      'Configuration limit must be greater than zero.';

  @override
  String get tmLanguageExplorerTimeoutInvalid =>
      'Timeout must be greater than zero.';

  @override
  String get tmLanguageExplorerOperationsPerBatchInvalid =>
      'Operations per batch must be greater than zero.';

  @override
  String get nfaToDfaEmptyAutomaton =>
      'The automaton must contain at least one state.';

  @override
  String get nfaToDfaMissingInitialState =>
      'The automaton must have an initial state.';

  @override
  String get nfaToDfaInitialStateOutsideSet =>
      'The initial state must belong to the automaton state set.';

  @override
  String get nfaToDfaAcceptingStateOutsideSet =>
      'Every accepting state must belong to the automaton state set.';

  @override
  String nfaToDfaStateLimitExceeded(int limit) {
    return 'NFA-to-DFA conversion reached the DFA state limit of $limit.';
  }

  @override
  String nfaToDfaConversionFailed(String error, String withSteps) {
    String _temp0 = intl.Intl.selectLogic(withSteps, {
      'true': ' (while recording steps)',
      'other': '',
    });
    return 'NFA-to-DFA conversion failed: $error$_temp0.';
  }

  @override
  String get pdaSimulationSearchLimitsNegative =>
      'Search limits must not be negative.';

  @override
  String get pdaSimulationMemoryLimitNegative =>
      'The PDA memory limit must not be negative.';

  @override
  String get pdaSimulationConfigurationsPerBatchInvalid =>
      'Configurations per batch must be greater than zero.';

  @override
  String pdaSimulationFailure(String operation, String error) {
    return 'PDA $operation failed: $error.';
  }

  @override
  String pdaSimulationAcceptedStringsFailure(String error) {
    return 'Finding accepted strings failed: $error.';
  }

  @override
  String pdaSimulationRejectedStringsFailure(String error) {
    return 'Finding rejected strings failed: $error.';
  }

  @override
  String get pdaSimulationTimeout => 'PDA simulation timed out.';

  @override
  String get pdaSimulationInfiniteLoop =>
      'PDA simulation detected an infinite loop.';

  @override
  String get pdaSimulationConfigurationLimit =>
      'PDA simulation reached its configuration limit.';

  @override
  String get pdaSimulationDepthLimit =>
      'PDA simulation reached its search-depth limit.';

  @override
  String get pdaSimulationMemoryLimit =>
      'PDA simulation reached its memory limit.';

  @override
  String get pdaSimulationStaleRequest =>
      'The PDA simulation result is stale and was discarded.';

  @override
  String get pdaSimulationRejectedNoAcceptingConfiguration =>
      'No accepting PDA configuration was found.';

  @override
  String get pdaSimulationTransitionTitle => 'PDA transition';

  @override
  String pdaSimulationReadInput(String symbol) {
    return 'Read input symbol $symbol.';
  }

  @override
  String pdaSimulationStackAction(String pop, String push) {
    return 'Pop $pop and push $push on the stack.';
  }

  @override
  String pdaSimulationStackTopChange(String before, String after) {
    return 'The stack top changes from $before to $after.';
  }

  @override
  String pdaSimulationPopMatches(String symbol) {
    return 'The stack pop matches $symbol.';
  }

  @override
  String get pdaSimulationNoPop => 'No stack symbol is popped.';

  @override
  String pdaSimulationPushed(String symbol) {
    return 'Pushed $symbol onto the stack.';
  }

  @override
  String get pdaSimulationNoPush => 'No stack symbol is pushed.';

  @override
  String get pdaSimulationEpsilonMove => 'This is an ε-move.';

  @override
  String get pdaAnalysisEmptyPda => 'The PDA must contain at least one state.';

  @override
  String get pdaAnalysisInvalidMaxInputLength =>
      'Maximum input length must not be negative.';

  @override
  String get pdaAnalysisInvalidTimeout => 'Timeout must be greater than zero.';

  @override
  String get pdaAnalysisTimedOut => 'PDA analysis timed out.';

  @override
  String pdaAnalysisFailure(String error) {
    return 'PDA analysis failed: $error.';
  }

  @override
  String get cfgToPdaEmptyGrammar =>
      'The grammar must contain at least one production.';

  @override
  String get cfgToPdaMissingStartSymbol =>
      'The grammar must have a start symbol.';

  @override
  String cfgToPdaUndeclaredStartSymbol(String symbol) {
    return 'Start symbol $symbol is not declared as a non-terminal.';
  }

  @override
  String cfgToPdaMalformedProduction(String production) {
    return 'Production $production is malformed.';
  }

  @override
  String cfgToPdaDuplicateProductionId(String production) {
    return 'Production ID $production is duplicated.';
  }

  @override
  String cfgToPdaUndeclaredSymbol(String production, String symbol) {
    return 'Production $production uses undeclared symbol $symbol.';
  }

  @override
  String get cfgToPdaLlAnalysisFailed =>
      'LL analysis failed while constructing the PDA.';

  @override
  String cfgToPdaLlConflict(
    String nonterminal,
    String lookahead,
    String productions,
  ) {
    return 'LL conflict for $nonterminal with lookahead $lookahead: $productions.';
  }

  @override
  String get cfgToPdaLrConstructionUnavailable =>
      'LR construction is unavailable for this grammar.';

  @override
  String cfgToPdaLrConflict(int state, String lookahead, String productions) {
    return 'LR conflict in state $state with lookahead $lookahead: $productions.';
  }

  @override
  String get cfgToPdaOutputInvalid =>
      'The CFG-to-PDA construction produced an invalid output.';

  @override
  String get tmMultiTapeCancelled => 'Multi-tape execution was cancelled.';

  @override
  String get tmMultiTapeTimeout => 'Multi-tape execution timed out.';

  @override
  String get tmMultiTapeConfigurationLimit =>
      'Multi-tape execution reached its configuration limit.';

  @override
  String tmMultiTapeEnteredFinalState(String policy) {
    return 'The multi-tape execution entered a final state under the $policy policy.';
  }

  @override
  String tmMultiTapeBranchEnteredFinalState(String policy) {
    return 'A multi-tape execution branch entered a final state under the $policy policy.';
  }

  @override
  String tmMultiTapeHaltedAccepted(String policy) {
    return 'Multi-tape execution halted with acceptance under the $policy policy.';
  }

  @override
  String tmMultiTapeBranchHaltedAccepted(String policy) {
    return 'A multi-tape execution branch halted with acceptance under the $policy policy.';
  }

  @override
  String get tmMultiTapeDeterministicConflict =>
      'The multi-tape machine has conflicting deterministic transitions.';

  @override
  String get tmMultiTapeDeterministicCycle =>
      'A deterministic cycle was detected during multi-tape execution.';

  @override
  String get tmMultiTapeStepLimit =>
      'Multi-tape execution reached its step limit.';

  @override
  String get tmMultiTapeHaltedRejected =>
      'Multi-tape execution halted without acceptance.';

  @override
  String get tmMultiTapeEveryBranchRejected =>
      'Every multi-tape execution branch was rejected.';

  @override
  String tmBuildingBlockDuplicateMachineId(String block) {
    return 'Building block $block reuses the root machine ID.';
  }

  @override
  String tmBuildingBlockEmptyBlockName(String block) {
    return 'Building block $block has an empty name.';
  }

  @override
  String tmBuildingBlockDuplicateBlockName(
    String firstBlock,
    String secondBlock,
  ) {
    return 'Building-block IDs $firstBlock and $secondBlock use the same name.';
  }

  @override
  String tmBuildingBlockMissingInitialState(String block) {
    return 'Building block $block has no initial state.';
  }

  @override
  String get tmBuildingBlockMissingRootInitialState =>
      'The root machine has no initial state.';

  @override
  String tmBuildingBlockTapeCountMismatch(
    String block,
    int blockTapes,
    int rootTapes,
  ) {
    return 'Building block $block uses $blockTapes tapes, but the root machine uses $rootTapes.';
  }

  @override
  String tmBuildingBlockBlankSymbolMismatch(String block) {
    return 'Building block $block uses a different blank symbol from the root machine.';
  }

  @override
  String tmBuildingBlockNestedLibrary(String block) {
    return 'Building block $block contains a nested block library.';
  }

  @override
  String tmBuildingBlockRecursiveDependency(String cycle) {
    return 'The building-block dependency graph is recursive: $cycle.';
  }

  @override
  String tmBuildingBlockDuplicateInvocationId(String invocation) {
    return 'Invocation ID $invocation is duplicated.';
  }

  @override
  String tmBuildingBlockDuplicateInvocationState(String state) {
    return 'State $state invokes more than one building block.';
  }

  @override
  String tmBuildingBlockMissingAnchorState(String invocation) {
    return 'Invocation $invocation has no anchor state.';
  }

  @override
  String tmBuildingBlockMissingReference(String invocation, String block) {
    return 'Invocation $invocation references missing block $block.';
  }

  @override
  String tmBuildingBlockRevisionMismatch(
    String invocation,
    int expected,
    String block,
    int actual,
  ) {
    return 'Invocation $invocation expects revision $expected of block $block, but found revision $actual.';
  }

  @override
  String tmBuildingBlockAcceptingRootInvocation(
    String invocation,
    String block,
  ) {
    return 'Root invocation $invocation of block $block cannot be accepting.';
  }

  @override
  String get tmBuildingBlockInvalidProject =>
      'The building-block project is invalid.';

  @override
  String get tmBuildingBlockCancelled =>
      'Building-block execution was cancelled.';

  @override
  String get tmBuildingBlockTimeout => 'Building-block execution timed out.';

  @override
  String get tmBuildingBlockConfigurationLimit =>
      'Building-block execution reached its configuration limit.';

  @override
  String get tmBuildingBlockCallDepthLimit =>
      'Building-block execution reached its call-depth limit.';

  @override
  String get tmBuildingBlockStepLimit =>
      'Building-block execution reached its step limit.';

  @override
  String tmBuildingBlockEnteredFinalState(String policy) {
    return 'Execution entered a final state under the $policy policy.';
  }

  @override
  String tmBuildingBlockHaltedAccepted(String policy) {
    return 'Building-block execution halted with acceptance under the $policy policy.';
  }

  @override
  String get tmBuildingBlockHaltedRejected =>
      'Building-block execution halted without acceptance.';

  @override
  String get tmBuildingBlockFiniteGraphRejected =>
      'The finite building-block graph rejected the input.';

  @override
  String get tmBuildingBlockRepeatedConfiguration =>
      'Building-block execution repeated a configuration.';

  @override
  String get tmToGrammarInvalidMachine =>
      'The Turing machine is invalid for conversion to an unrestricted grammar.';

  @override
  String tmToGrammarInvalidMachineDetail(String detail) {
    return 'The Turing machine is invalid for conversion: $detail.';
  }

  @override
  String get tmToGrammarMissingInitialState =>
      'The Turing machine must have an initial state.';

  @override
  String get tmToGrammarNoAcceptingState =>
      'The Turing machine has no accepting state; the converted language is empty.';

  @override
  String tmToGrammarMultiTapeUnsupported(int tapes) {
    return 'TM-to-grammar conversion does not support $tapes tapes.';
  }

  @override
  String get tmToGrammarMultiTapeUnsupportedGeneric =>
      'TM-to-grammar conversion does not support multi-tape machines.';

  @override
  String tmToGrammarBuildingBlocksUnsupported(String blocks) {
    return 'TM-to-grammar conversion does not support building blocks: $blocks.';
  }

  @override
  String get tmToGrammarBuildingBlocksUnsupportedGeneric =>
      'TM-to-grammar conversion does not support building blocks.';

  @override
  String tmToGrammarBlankInInputAlphabet(String symbol) {
    return 'The blank symbol $symbol cannot be in the input alphabet.';
  }

  @override
  String get tmToGrammarBlankInInputAlphabetGeneric =>
      'The blank symbol cannot be in the input alphabet.';

  @override
  String tmToGrammarInputOutsideTapeAlphabet(String symbol) {
    return 'Input symbol $symbol is outside the tape alphabet.';
  }

  @override
  String get tmToGrammarInputOutsideTapeAlphabetGeneric =>
      'An input symbol is outside the tape alphabet.';

  @override
  String tmToGrammarConstructionLimit(int limit) {
    return 'TM-to-grammar construction reached its production limit of $limit.';
  }

  @override
  String tmToGrammarConstructionLimitDetail(String detail) {
    return 'TM-to-grammar construction stopped: $detail.';
  }

  @override
  String get tmToGrammarConstructionLimitGeneric =>
      'TM-to-grammar construction reached its limit.';

  @override
  String tmToGrammarOutputInvalid(String detail) {
    return 'TM-to-grammar conversion produced invalid output: $detail.';
  }

  @override
  String get tmToGrammarOutputInvalidGeneric =>
      'TM-to-grammar conversion produced invalid output.';

  @override
  String tmToGrammarUnreachableState(String state) {
    return 'State $state is unreachable from the initial state.';
  }

  @override
  String get tmToGrammarUnreachableStateGeneric =>
      'An unreachable state was found.';

  @override
  String get dfaMinimizationStepInitialPartitionTitle =>
      'Create the initial partition';

  @override
  String dfaMinimizationStepInitialPartitionExplanation(
    String acceptingStates,
    String nonAcceptingStates,
  ) {
    return 'Initial partition: accepting states [$acceptingStates] and non-accepting states [$nonAcceptingStates].';
  }

  @override
  String get dfaMinimizationStepRemoveUnreachableTitle =>
      'Remove unreachable states';

  @override
  String dfaMinimizationStepRemoveUnreachableExplanation(
    String unreachableStates,
    int reachableStateCount,
  ) {
    return 'Removed unreachable states [$unreachableStates]; $reachableStateCount reachable states remain.';
  }

  @override
  String get dfaMinimizationStepSelectSetTitle => 'Select a partition set';

  @override
  String dfaMinimizationStepSelectSetExplanation(String states) {
    return 'Selected partition set [$states] for refinement.';
  }

  @override
  String dfaMinimizationStepFindPredecessorsTitle(String symbol) {
    return 'Find predecessors on $symbol';
  }

  @override
  String dfaMinimizationStepFindPredecessorsExplanation(
    String states,
    String symbol,
    String predecessors,
    String hasPredecessors,
  ) {
    String _temp0 = intl.Intl.selectLogic(hasPredecessors, {
      'true': '.',
      'other': '; no predecessors were found.',
    });
    return 'States [$states] have predecessors [$predecessors] on $symbol$_temp0';
  }

  @override
  String get dfaMinimizationStepSplitClassTitle => 'Split a partition class';

  @override
  String dfaMinimizationStepSplitClassExplanation(
    String splitStates,
    String symbol,
    String intersectionStates,
    String differenceStates,
    int oldPartitionSize,
    int newPartitionSize,
  ) {
    return 'Split [$splitStates] on $symbol into intersection [$intersectionStates] and difference [$differenceStates] ($oldPartitionSize classes became $newPartitionSize).';
  }

  @override
  String dfaMinimizationStepNoSplitTitle(String symbol) {
    return 'Keep the partition class for $symbol';
  }

  @override
  String dfaMinimizationStepNoSplitExplanation(String states, String symbol) {
    return 'Class [$states] remains stable for symbol $symbol.';
  }

  @override
  String get dfaMinimizationStepPartitionStableTitle => 'Partition is stable';

  @override
  String dfaMinimizationStepPartitionStableExplanation(int partitionSize) {
    return 'The partition is stable with $partitionSize classes.';
  }

  @override
  String dfaMinimizationStepCreateMinimizedStateTitle(String state) {
    return 'Create minimized state $state';
  }

  @override
  String dfaMinimizationStepCreateMinimizedStateExplanation(
    String state,
    String equivalenceClass,
    String isInitial,
    String isAccepting,
  ) {
    String _temp0 = intl.Intl.selectLogic(isInitial, {
      'true': 'yes',
      'other': 'no',
    });
    String _temp1 = intl.Intl.selectLogic(isAccepting, {
      'true': 'yes',
      'other': 'no',
    });
    return 'State $state represents [$equivalenceClass]; initial: $_temp0, accepting: $_temp1.';
  }

  @override
  String dfaMinimizationStepCreateMinimizedTransitionTitle(String symbol) {
    return 'Create minimized transition on $symbol';
  }

  @override
  String dfaMinimizationStepCreateMinimizedTransitionExplanation(
    String fromState,
    String toState,
    String symbol,
  ) {
    return 'Transition from $fromState to $toState on $symbol.';
  }

  @override
  String get dfaMinimizationStepCompletionTitle => 'Complete DFA minimization';

  @override
  String dfaMinimizationStepCompletionExplanation(
    int originalStateCount,
    int minimizedStateCount,
    int transitionCount,
    int reduction,
    String hasReduction,
  ) {
    String _temp0 = intl.Intl.selectLogic(hasReduction, {
      'true': ' and a reduction of $reduction states',
      'other': '',
    });
    return 'Minimization complete: $originalStateCount states became $minimizedStateCount, with $transitionCount transitions$_temp0.';
  }

  @override
  String fsaDeterminizerFailed(String automaton) {
    return 'Determinization failed for $automaton.';
  }

  @override
  String get validationFsaEmpty => 'The automaton has no states.';

  @override
  String get validationFsaNoInitial => 'The automaton has no initial state.';

  @override
  String validationFsaInvalidInitial(String state) {
    return 'Initial state $state is not in the state set.';
  }

  @override
  String get validationFsaEmptyAlphabet => 'The automaton has no alphabet.';

  @override
  String validationFsaInvalidAccepting(String state) {
    return 'Accepting state $state is not in the state set.';
  }

  @override
  String validationFsaBadFrom(String state) {
    return 'Transition source state $state is unknown.';
  }

  @override
  String validationFsaBadTo(String state) {
    return 'Transition target state $state is unknown.';
  }

  @override
  String validationFsaBadSymbol(String symbol) {
    return 'Transition symbol $symbol is outside the alphabet.';
  }

  @override
  String validationFsaNondeterministic(String state, int count, String symbol) {
    return 'State $state has $count transitions on $symbol.';
  }

  @override
  String get validationPdaEmpty => 'The PDA has no states.';

  @override
  String get validationPdaNoInitial => 'The PDA has no initial state.';

  @override
  String validationPdaInvalidInitial(String state) {
    return 'Initial state $state is not in the state set.';
  }

  @override
  String get validationPdaNoAccepting => 'The PDA has no accepting states.';

  @override
  String get validationPdaEmptyInputAlphabet =>
      'The PDA has no input alphabet.';

  @override
  String get validationPdaEmptyStackAlphabet =>
      'The PDA has no stack alphabet.';

  @override
  String validationPdaInvalidInitialStack(String symbol) {
    return 'Initial stack symbol $symbol is outside the stack alphabet.';
  }

  @override
  String validationPdaInvalidAccepting(String state) {
    return 'Accepting state $state is not in the state set.';
  }

  @override
  String validationPdaBadFrom(String state) {
    return 'Transition source state $state is unknown.';
  }

  @override
  String validationPdaBadTo(String state) {
    return 'Transition target state $state is unknown.';
  }

  @override
  String validationPdaBadInputSymbol(String symbol) {
    return 'Input symbol $symbol is outside the input alphabet.';
  }

  @override
  String validationPdaBadStackSymbol(String symbol) {
    return 'Stack symbol $symbol is outside the stack alphabet.';
  }

  @override
  String validationPdaBadPushSymbol(String symbol) {
    return 'Pushed stack symbol $symbol is outside the stack alphabet.';
  }

  @override
  String get nfaToDfaStepInitialEpsilonClosureTitle =>
      'Compute the initial ε-closure';

  @override
  String nfaToDfaStepInitialEpsilonClosureExplanation(
    String initialState,
    String epsilonClosure,
    String containsAcceptingState,
  ) {
    String _temp0 = intl.Intl.selectLogic(containsAcceptingState, {
      'true': ' and contains an accepting state',
      'other': '',
    });
    return 'The ε-closure of $initialState is $epsilonClosure$_temp0.';
  }

  @override
  String get nfaToDfaStepInitialEpsilonClosureStepTitle => 'Initial ε-closure';

  @override
  String nfaToDfaStepInitialState(String state) {
    return 'Start from state $state.';
  }

  @override
  String nfaToDfaStepEpsilonClosureReached(String stateSet) {
    return 'Reach $stateSet through ε-transitions.';
  }

  @override
  String get nfaToDfaStepInitialStateIsAccepting =>
      'The initial DFA state is accepting.';

  @override
  String nfaToDfaStepProcessSymbolTitle(String symbol) {
    return 'Process symbol $symbol';
  }

  @override
  String nfaToDfaStepProcessSymbolExplanation(
    String currentStates,
    String symbol,
    String reachableStates,
  ) {
    return 'From $currentStates, reading $symbol reaches $reachableStates before ε-closure.';
  }

  @override
  String get nfaToDfaStepProcessSymbolStepTitle => 'Process an input symbol';

  @override
  String nfaToDfaStepCurrentDfaStateSet(String stateSet) {
    return 'Use DFA state set $stateSet.';
  }

  @override
  String nfaToDfaStepCollectSymbolDestinations(String symbol) {
    return 'Follow NFA transitions labeled $symbol.';
  }

  @override
  String nfaToDfaStepReachableBeforeEpsilonClosure(String stateSet) {
    return 'Reach NFA states $stateSet.';
  }

  @override
  String get nfaToDfaStepEpsilonClosureOfReachableTitle =>
      'Compute ε-closure of reachable states';

  @override
  String nfaToDfaStepEpsilonClosureOfReachableExplanation(
    String reachableStates,
    String epsilonClosure,
    String isNewState,
    String containsAcceptingState,
  ) {
    String _temp0 = intl.Intl.selectLogic(isNewState, {
      'true': 'creates a new',
      'other': 'reuses an existing',
    });
    String _temp1 = intl.Intl.selectLogic(containsAcceptingState, {
      'true': ', which is accepting',
      'other': '',
    });
    return 'The ε-closure of $reachableStates is $epsilonClosure; it $_temp0 DFA state$_temp1.';
  }

  @override
  String get nfaToDfaStepEpsilonClosureOfReachableStepTitle =>
      'Close the reachable states under ε';

  @override
  String get nfaToDfaStepEpsilonTransitionsDoNotConsumeInput =>
      'ε-transitions do not consume input.';

  @override
  String nfaToDfaStepEpsilonClosureReachedFromStates(
    String reachableStates,
    String epsilonClosure,
  ) {
    return 'The ε-closure from $reachableStates is $epsilonClosure.';
  }

  @override
  String get nfaToDfaStepNewDfaStateSet => 'This set becomes a new DFA state.';

  @override
  String get nfaToDfaStepExistingDfaStateSet =>
      'This set matches an existing DFA state.';

  @override
  String get nfaToDfaStepAcceptingDfaStateSet =>
      'The DFA state set is accepting.';

  @override
  String nfaToDfaStepCreateDfaStateTitle(String state) {
    return 'Create DFA state $state';
  }

  @override
  String nfaToDfaStepCreateDfaStateExplanation(
    String state,
    String stateSet,
    String isAccepting,
  ) {
    String _temp0 = intl.Intl.selectLogic(isAccepting, {
      'true': 'accepting',
      'other': 'not accepting',
    });
    return 'DFA state $state represents $stateSet and is $_temp0.';
  }

  @override
  String get nfaToDfaStepCreateDfaStateStepTitle => 'Create a DFA state';

  @override
  String get nfaToDfaStepSubsetConstructionDistinctStateSets =>
      'Each distinct NFA state set becomes one DFA state.';

  @override
  String nfaToDfaStepDfaStateRepresentsNfaSet(String stateSet) {
    return 'The DFA state represents NFA set $stateSet.';
  }

  @override
  String get nfaToDfaStepAcceptingDfaState =>
      'Mark the DFA state as accepting.';

  @override
  String get nfaToDfaStepNonAcceptingDfaState =>
      'The DFA state is not accepting.';

  @override
  String nfaToDfaStepCreateDfaTransitionTitle(String symbol) {
    return 'Create DFA transition on $symbol';
  }

  @override
  String nfaToDfaStepCreateDfaTransitionExplanation(
    String fromState,
    String symbol,
    String toState,
    String fromStates,
    String toStates,
  ) {
    return 'Add $fromState —$symbol→ $toState for $fromStates to $toStates.';
  }

  @override
  String get nfaToDfaStepCreateDfaTransitionStepTitle =>
      'Create a DFA transition';

  @override
  String nfaToDfaStepNfaTransitionReachability(
    String fromStates,
    String symbol,
    String toStates,
  ) {
    return 'NFA states $fromStates on $symbol reach $toStates.';
  }

  @override
  String get nfaToDfaStepSingleDeterministicTransition =>
      'Record one deterministic transition for this state set and symbol.';

  @override
  String get nfaToDfaStepCompletionTitle => 'Complete NFA-to-DFA conversion';

  @override
  String nfaToDfaStepCompletionExplanation(
    int stateCount,
    int transitionCount,
    int acceptingStateCount,
  ) {
    return 'The DFA has $stateCount states, $transitionCount transitions, and $acceptingStateCount accepting states.';
  }

  @override
  String get nfaToDfaStepCompletionStepTitle => 'Conversion complete';

  @override
  String nfaToDfaStepCreatedStateCount(int count) {
    return 'Created $count DFA states.';
  }

  @override
  String nfaToDfaStepCreatedTransitionCount(int count) {
    return 'Created $count DFA transitions.';
  }

  @override
  String nfaToDfaStepMarkedAcceptingStateCount(int count) {
    return 'Marked $count DFA states as accepting.';
  }

  @override
  String get cykStepInitializeTitle => 'Initialize the CYK table';

  @override
  String cykStepInitializeExplanation(String input, int tableSize) {
    return 'Initialize a table for input $input with $tableSize tokens.';
  }

  @override
  String get cykStepInitializeStepTitle => 'Initialize the CYK table';

  @override
  String cykStepInitializeInputBullet(String input, int tableSize) {
    return 'Tokenize the input $input ($tableSize tokens).';
  }

  @override
  String get cykStepInitializeTableBullet => 'Create the triangular CYK table.';

  @override
  String cykStepFillBaseCaseTitle(String terminal) {
    return 'Fill the base case for $terminal';
  }

  @override
  String cykStepFillBaseCaseExplanation(
    int position,
    String terminal,
    String variables,
    String hasVariables,
  ) {
    String _temp0 = intl.Intl.selectLogic(hasVariables, {
      'true': '$variables',
      'other': 'no variables',
    });
    return 'At input position $position, terminal $terminal is derived by $_temp0.';
  }

  @override
  String cykStepFillBaseCaseStepTitle(String terminal) {
    return 'Fill a base-case cell for $terminal';
  }

  @override
  String cykStepFillBaseCaseFragmentBullet(int position, String terminal) {
    return 'The input fragment at position $position is $terminal.';
  }

  @override
  String get cykStepFillBaseCaseProductionBullet =>
      'Find productions that derive this terminal.';

  @override
  String cykStepFillBaseCaseEmptyBullet(String terminal) {
    return 'No nonterminal derives terminal $terminal.';
  }

  @override
  String cykStepFillBaseCaseAddedBullet(String variables) {
    return 'Add nonterminals $variables to the cell.';
  }

  @override
  String cykStepProcessCellTitle(int row, int column) {
    return 'Process cell [$row][$column]';
  }

  @override
  String cykStepProcessCellExplanation(
    int row,
    int column,
    String substring,
    int length,
  ) {
    return 'Process substring $substring at [$row][$column] with length $length.';
  }

  @override
  String cykStepProcessCellStepTitle(String substring) {
    return 'Process CYK cell $substring';
  }

  @override
  String cykStepProcessCellLocationBullet(int row, int column, int length) {
    return 'Locate substring $length at table cell [$row][$column].';
  }

  @override
  String get cykStepProcessCellSplitBullet =>
      'Try every split point in the substring.';

  @override
  String cykStepCheckSplitTitle(int splitPoint) {
    return 'Check the split at position $splitPoint';
  }

  @override
  String cykStepCheckSplitExplanation(
    String substring,
    String leftSubstring,
    String rightSubstring,
    int leftRow,
    int leftColumn,
    int rightRow,
    int rightColumn,
    String leftVariables,
    String rightVariables,
    String hasLeftVariables,
    String hasRightVariables,
  ) {
    String _temp0 = intl.Intl.selectLogic(hasLeftVariables, {
      'true': '$leftVariables',
      'other': 'empty',
    });
    String _temp1 = intl.Intl.selectLogic(hasRightVariables, {
      'true': '$rightVariables',
      'other': 'empty',
    });
    return 'Split $substring into $leftSubstring and $rightSubstring; inspect cells [$leftRow][$leftColumn] and [$rightRow][$rightColumn]. Left: $_temp0; right: $_temp1.';
  }

  @override
  String cykStepCheckSplitStepTitle(
    String leftSubstring,
    String rightSubstring,
  ) {
    return 'Check split $leftSubstring | $rightSubstring';
  }

  @override
  String cykStepCheckSplitLeftBullet(
    int row,
    int column,
    String variables,
    String hasVariables,
  ) {
    String _temp0 = intl.Intl.selectLogic(hasVariables, {
      'true': '$variables',
      'other': 'empty',
    });
    return 'Read the left cell [$row][$column]: $_temp0.';
  }

  @override
  String cykStepCheckSplitRightBullet(
    int row,
    int column,
    String variables,
    String hasVariables,
  ) {
    String _temp0 = intl.Intl.selectLogic(hasVariables, {
      'true': '$variables',
      'other': 'empty',
    });
    return 'Read the right cell [$row][$column]: $_temp0.';
  }

  @override
  String cykStepCheckSplitProductionBullet(int row, int column) {
    return 'At [$row][$column], look for a production combining the two cells.';
  }

  @override
  String cykStepApplyProductionTitle(
    String variable,
    String leftVariable,
    String rightVariable,
  ) {
    return 'Apply $variable → $leftVariable $rightVariable';
  }

  @override
  String cykStepApplyProductionExplanation(
    int row,
    int column,
    String variable,
    String leftVariable,
    String rightVariable,
    String substring,
  ) {
    return 'At [$row][$column], apply $variable → $leftVariable $rightVariable to $substring.';
  }

  @override
  String cykStepApplyProductionStepTitle(
    String variable,
    String leftVariable,
    String rightVariable,
  ) {
    return 'Apply $variable → $leftVariable $rightVariable';
  }

  @override
  String get cykStepApplyProductionCombineBullet =>
      'Combine nonterminals from the left and right cells.';

  @override
  String cykStepApplyProductionDerivationBullet(
    String leftVariable,
    String rightVariable,
    String variable,
    String substring,
  ) {
    return 'Use $leftVariable and $rightVariable to derive $variable for $substring.';
  }

  @override
  String cykStepApplyProductionAddBullet(int row, int column, String variable) {
    return 'Add $variable to cell [$row][$column].';
  }

  @override
  String cykStepCompleteCellTitle(int row, int column) {
    return 'Complete cell [$row][$column]';
  }

  @override
  String cykStepCompleteCellExplanation(
    int row,
    int column,
    String substring,
    String nonterminals,
    String hasNonterminals,
  ) {
    String _temp0 = intl.Intl.selectLogic(hasNonterminals, {
      'true': '$nonterminals',
      'other': 'no nonterminals',
    });
    return 'Cell [$row][$column] for $substring contains $_temp0.';
  }

  @override
  String cykStepCompleteCellStepTitle(int row, int column) {
    return 'Complete cell [$row][$column]';
  }

  @override
  String cykStepCompleteCellSubstringBullet(String substring) {
    return 'The cell covers substring $substring.';
  }

  @override
  String get cykStepCompleteCellEmptyBullet =>
      'The cell contains no nonterminals.';

  @override
  String cykStepCompleteCellNonterminalsBullet(String nonterminals) {
    return 'The cell contains nonterminals $nonterminals.';
  }

  @override
  String get cykStepCheckAcceptanceTitle => 'Check CYK acceptance';

  @override
  String cykStepCheckAcceptanceExplanation(
    String input,
    String startSymbol,
    String nonterminals,
    String hasNonterminals,
    String accepted,
  ) {
    String _temp0 = intl.Intl.selectLogic(hasNonterminals, {
      'true': '$nonterminals',
      'other': 'no nonterminals',
    });
    String _temp1 = intl.Intl.selectLogic(accepted, {
      'true': 'is present',
      'other': 'is absent',
    });
    return 'For input $input, the final cell has $_temp0; start symbol $startSymbol $_temp1.';
  }

  @override
  String get cykStepCheckAcceptanceStepTitle => 'Check acceptance';

  @override
  String cykStepCheckAcceptanceFinalCellBullet(String nonterminals) {
    return 'Inspect final-cell nonterminals $nonterminals.';
  }

  @override
  String cykStepCheckAcceptanceAcceptedBullet(String startSymbol) {
    return 'The start symbol $startSymbol is in the final cell.';
  }

  @override
  String cykStepCheckAcceptanceRejectedBullet(String startSymbol) {
    return 'The start symbol $startSymbol is not in the final cell.';
  }

  @override
  String get cykStepCompletionTitle => 'Complete CYK parsing';

  @override
  String cykStepCompletionExplanation(
    String input,
    int totalCells,
    int filledCells,
    String accepted,
  ) {
    String _temp0 = intl.Intl.selectLogic(accepted, {
      'true': 'the input is accepted',
      'other': 'the input is rejected',
    });
    return 'Parsed $input: filled $filledCells of $totalCells cells; $_temp0.';
  }

  @override
  String get cykStepCompletionStepTitle => 'Parsing complete';

  @override
  String cykStepCompletionFilledCellsBullet(int totalCells, int filledCells) {
    return 'Filled $filledCells of $totalCells table cells.';
  }

  @override
  String get cykStepCompletionAcceptedBullet =>
      'The input is accepted by the grammar.';

  @override
  String get cykStepCompletionRejectedBullet =>
      'The input is rejected by the grammar.';

  @override
  String get pdaLanguageEmptinessInvalidLimits =>
      'PDA language-analysis limits must be greater than zero.';

  @override
  String get pdaLanguageEmptinessCancelled =>
      'PDA language-emptiness analysis was cancelled.';

  @override
  String get pdaLanguageEmptinessWitnessReplayFailed =>
      'The CFG witness could not be replayed by the source PDA.';

  @override
  String get pdaLanguageEmptinessCfgInvalidLimits =>
      'CFG analysis limits must be greater than zero.';

  @override
  String get pdaLanguageEmptinessCfgMissingStartSymbol =>
      'The CFG start symbol must be a declared nonterminal.';

  @override
  String get pdaLanguageEmptinessCfgOverlappingSymbolSets =>
      'CFG terminals and nonterminals must be disjoint.';

  @override
  String pdaLanguageEmptinessCfgInvalidProductionLeft(String production) {
    return 'Production $production must have one declared nonterminal on its left side.';
  }

  @override
  String pdaLanguageEmptinessCfgInconsistentLambdaMetadata(String production) {
    return 'Production $production has inconsistent lambda metadata.';
  }

  @override
  String pdaLanguageEmptinessCfgEpsilonMixed(String production) {
    return 'Production $production mixes epsilon with other symbols.';
  }

  @override
  String pdaLanguageEmptinessCfgUndeclaredSymbol(
    String production,
    String symbol,
  ) {
    return 'Production $production uses undeclared symbol $symbol.';
  }

  @override
  String get pdaLanguageEmptinessCfgCancelled =>
      'CFG shortest-witness analysis was cancelled.';

  @override
  String pdaLanguageEmptinessCfgProductivityLimit(int limit) {
    return 'CFG productivity update limit exceeded ($limit).';
  }

  @override
  String pdaLanguageEmptinessCfgDerivationLimit(int limit) {
    return 'CFG derivation step limit exceeded ($limit).';
  }

  @override
  String get pdaLanguageEmptinessCfgWitnessMismatch =>
      'The reconstructed CFG derivation does not match its witness.';

  @override
  String pdaLanguageEmptinessCfgMissingProductiveChoice(String symbol) {
    return 'No productive choice exists for $symbol during derivation reconstruction.';
  }

  @override
  String get validationTmEmpty => 'The TM has no states.';

  @override
  String get validationTmNoInitial => 'The TM has no initial state.';

  @override
  String validationTmInvalidInitial(String state) {
    return 'Initial state $state is not in the state set.';
  }

  @override
  String get validationTmNoAccepting => 'The TM has no accepting states.';

  @override
  String get validationTmEmptyInputAlphabet => 'The TM has no input alphabet.';

  @override
  String get validationTmEmptyTapeAlphabet => 'The TM has no tape alphabet.';

  @override
  String get validationTmEmptyBlank => 'The blank symbol is empty.';

  @override
  String validationTmBlankNotInTape(String symbol) {
    return 'Blank symbol $symbol is not in the tape alphabet.';
  }

  @override
  String validationTmInputNotInTape(String symbol) {
    return 'Input symbol $symbol is not in the tape alphabet.';
  }

  @override
  String validationTmInvalidAccepting(String state) {
    return 'Accepting state $state is not in the state set.';
  }

  @override
  String validationTmBadFrom(String state) {
    return 'Transition source state $state is unknown.';
  }

  @override
  String validationTmBadTo(String state) {
    return 'Transition target state $state is unknown.';
  }

  @override
  String validationTmBadReadSymbol(String symbol) {
    return 'Transition reads symbol $symbol, which is not in the tape alphabet.';
  }

  @override
  String validationTmBadWriteSymbol(String symbol) {
    return 'Transition writes symbol $symbol, which is not in the tape alphabet.';
  }

  @override
  String validationTmBadMove(String direction) {
    return 'Transition has invalid move direction $direction.';
  }

  @override
  String get validationCfgEmpty => 'The grammar has no productions.';

  @override
  String get validationCfgNoNonterminals => 'The grammar has no nonterminals.';

  @override
  String get validationCfgNoTerminals => 'The grammar has no terminals.';

  @override
  String get validationCfgEmptyStart => 'The start symbol is empty.';

  @override
  String validationCfgBadStart(String symbol) {
    return 'Start symbol $symbol must be a nonterminal.';
  }

  @override
  String validationCfgEmptyLeft(int production) {
    return 'Production $production has an empty left side.';
  }

  @override
  String validationCfgBadLeft(int production, String symbol) {
    return 'Production $production left side $symbol is not a nonterminal.';
  }

  @override
  String validationCfgEmptyRight(int production) {
    return 'Production $production has an empty right side.';
  }

  @override
  String validationCfgBadSymbol(int production, String symbol) {
    return 'Production $production contains unknown symbol $symbol.';
  }

  @override
  String get validationInputEmpty => 'The input string is empty.';

  @override
  String validationInputInvalidSymbol(String symbol, int position) {
    return 'Input contains invalid symbol $symbol at position $position.';
  }

  @override
  String tmBuildingBlockEnterBlock(String machine) {
    return 'Enter building-block machine $machine.';
  }

  @override
  String tmBuildingBlockTransition(String transition) {
    return 'Apply transition $transition.';
  }

  @override
  String tmBuildingBlockReturnFromBlock(String machine) {
    return 'Return from building-block machine $machine.';
  }

  @override
  String get codecFsaJflapInvalidRoot => 'JFLAP XML root must be <structure>.';

  @override
  String codecFsaJflapUnsupportedDocumentType(String type) {
    return 'JFLAP document type $type is not an FSA document.';
  }

  @override
  String get codecFsaJflapBuildingBlocksUnsupported =>
      'JFLAP building blocks require the dedicated TM codec.';

  @override
  String get codecFsaJflapMissingAutomaton =>
      'JFLAP FSA is missing <automaton>.';

  @override
  String get codecFsaJflapMissingStateId =>
      'JFLAP state is missing a non-empty ID.';

  @override
  String codecFsaJflapDuplicateStateId(String state) {
    return 'State $state has a duplicate ID.';
  }

  @override
  String codecFsaJflapInvalidStateCoordinate(String state) {
    return 'State $state has an invalid coordinate.';
  }

  @override
  String get codecFsaJflapMultipleInitialStates =>
      'The FSA contains multiple initial states.';

  @override
  String get codecFsaJflapInvalidDocument => 'The FSA document is invalid.';

  @override
  String codecFsaJflapUnsupportedSchema(int version) {
    return 'FSA schema version $version is not supported.';
  }

  @override
  String get codecFsaJflapRequiresFsaDocument =>
      'The JFLAP codec requires an FSA document.';

  @override
  String get codecFsaJflapCanonicalOrderImport =>
      'States and transitions were ordered canonically during import.';

  @override
  String get codecFsaJflapCanonicalOrderExport =>
      'States and transitions were ordered canonically during export.';

  @override
  String codecFsaJflapStateTypeDropped(String state) {
    return 'State $state uses a type that JFLAP FSA cannot store.';
  }

  @override
  String codecFsaJflapStatePropertiesDropped(String state) {
    return 'State $state has properties that JFLAP FSA cannot store.';
  }

  @override
  String codecFsaJflapTransitionControlPointDropped(
    String transition,
    String controlPoint,
  ) {
    return 'The control point of transition $transition was dropped at $controlPoint.';
  }

  @override
  String codecFsaJflapTransitionDisplayLabelDropped(String transition) {
    return 'The separate display label of transition $transition was dropped.';
  }

  @override
  String codecFsaJflapExplicitEpsilonAliasInterpreted(String symbol) {
    return 'The explicit epsilon alias $symbol was interpreted as an empty read.';
  }

  @override
  String codecFsaJflapExplicitEpsilonAliasExportedEmpty(
    String aliases,
    String transition,
  ) {
    return 'Explicit epsilon aliases $aliases were exported as empty reads for transition $transition.';
  }

  @override
  String codecFsaJflapMultiSymbolTransitionExpanded(
    String transition,
    int count,
  ) {
    return 'Transition $transition was expanded into $count single-symbol transitions.';
  }

  @override
  String codecFsaJflapUnknownOptionalElement(String extension) {
    return 'Unknown optional XML element $extension was ignored.';
  }

  @override
  String codecFsaJflapUnknownOptionalAttribute(String extension) {
    return 'Unknown optional XML attribute $extension was ignored.';
  }

  @override
  String grammarAnalysisFirstProductionLhsUndeclared(String nonTerminal) {
    return 'FIRST cannot be computed because production LHS $nonTerminal is not a declared non-terminal.';
  }

  @override
  String grammarAnalysisFirstEpsilonEmptyProduction(String nonTerminal) {
    return 'FIRST($nonTerminal) gains epsilon from an empty production.';
  }

  @override
  String grammarAnalysisFirstEpsilonProduction(
    String nonTerminal,
    String production,
  ) {
    return 'FIRST($nonTerminal) gains epsilon because $production contains epsilon.';
  }

  @override
  String grammarAnalysisFirstTerminalProduction(
    String nonTerminal,
    String symbol,
    String production,
  ) {
    return 'FIRST($nonTerminal) gains terminal $symbol from $production.';
  }

  @override
  String grammarAnalysisFirstAbsorbsFirst(
    String nonTerminal,
    String source,
    String production,
  ) {
    return 'FIRST($nonTerminal) absorbs FIRST($source) minus epsilon via $production.';
  }

  @override
  String grammarAnalysisFirstEpsilonNullableProduction(
    String nonTerminal,
    String production,
  ) {
    return 'FIRST($nonTerminal) gains epsilon because all symbols in $production are nullable.';
  }

  @override
  String grammarAnalysisFirstSetsComputed(int count) {
    return 'Computed FIRST sets for $count non-terminals.';
  }

  @override
  String grammarAnalysisFollowStartSymbolUndeclared(String symbol) {
    return 'FOLLOW cannot be computed because start symbol $symbol is not a declared non-terminal.';
  }

  @override
  String grammarAnalysisFollowStartSymbolMissingEntry(String symbol) {
    return 'FOLLOW has no entry for start symbol $symbol.';
  }

  @override
  String grammarAnalysisFollowStartIncludesEndMarker(String symbol) {
    return 'FOLLOW($symbol) includes the end marker.';
  }

  @override
  String grammarAnalysisFollowProductionLhsUndeclared(String nonTerminal) {
    return 'FOLLOW cannot be computed because production LHS $nonTerminal is not a declared non-terminal.';
  }

  @override
  String grammarAnalysisFollowGainsFromSuffix(
    String nonTerminal,
    String symbols,
    String production,
  ) {
    return 'FOLLOW($nonTerminal) gains $symbols from the suffix in $production.';
  }

  @override
  String grammarAnalysisFollowAbsorbsFollow(
    String nonTerminal,
    String source,
    String production,
  ) {
    return 'FOLLOW($nonTerminal) absorbs FOLLOW($source) because the suffix in $production is nullable.';
  }

  @override
  String grammarAnalysisFollowSetsComputed(int count) {
    return 'Computed FOLLOW sets for $count non-terminals.';
  }

  @override
  String grammarAnalysisProcessingOrder(String nonTerminals) {
    return 'Processing non-terminals in order: $nonTerminals.';
  }

  @override
  String grammarAnalysisSubstitutionNote(String production, String via) {
    return 'Substitute $production using $via.';
  }

  @override
  String grammarAnalysisSubstitutionDerivation(
    String production,
    String replacements,
  ) {
    return 'Substitution of $production yields $replacements.';
  }

  @override
  String grammarAnalysisSubstitutionOperation(String nonTerminal, String via) {
    return 'Substitute productions for $nonTerminal via $via.';
  }

  @override
  String grammarAnalysisSubstitutionRationale(String nonTerminal, String via) {
    return 'Replace the leading $via in $nonTerminal with its current alternatives.';
  }

  @override
  String grammarAnalysisRemoveVacuousRecursionRationale(String nonTerminal) {
    return 'Remove vacuous $nonTerminal to $nonTerminal alternatives because they add no strings.';
  }

  @override
  String grammarAnalysisVacuousRecursionDerivation(String productions) {
    return 'Removed vacuous recursive alternatives: $productions.';
  }

  @override
  String grammarAnalysisRecursiveOnlyRationale(String nonTerminal) {
    return 'Remove recursive-only alternatives for $nonTerminal because they derive no terminal strings.';
  }

  @override
  String grammarAnalysisRecursiveOnlyDerivation(String nonTerminal) {
    return 'Removed recursive-only alternatives for $nonTerminal.';
  }

  @override
  String grammarAnalysisDirectRecursionIntroduced(
    String introduced,
    String nonTerminal,
  ) {
    return 'Introduced $introduced to remove direct recursion from $nonTerminal.';
  }

  @override
  String grammarAnalysisMoveRecursiveSuffixesRationale(
    String nonTerminal,
    String introduced,
  ) {
    return 'Move recursive suffixes of $nonTerminal to $introduced and add a terminating epsilon alternative.';
  }

  @override
  String grammarAnalysisDirectRecursionRewritten(
    String nonTerminal,
    String introduced,
  ) {
    return 'Rewrote direct recursion for $nonTerminal using $introduced.';
  }

  @override
  String grammarAnalysisDirectRecursionOperation(String nonTerminal) {
    return 'Remove direct recursion from $nonTerminal.';
  }

  @override
  String get grammarAnalysisLeftCornerCycleRemains =>
      'A left-corner cycle remains after transformation.';

  @override
  String get grammarAnalysisLeftRecursionRemoved =>
      'Left recursion was removed.';

  @override
  String grammarPredictiveFactoringIntroduced(
    String introduced,
    String prefix,
    String nonTerminal,
    int productionCount,
  ) {
    return 'Introduced non-terminal $introduced to factor prefix $prefix from $nonTerminal ($productionCount productions).';
  }

  @override
  String grammarPredictiveFactoringDerivation(
    int productionCount,
    String nonTerminal,
    String prefix,
    String introduced,
  ) {
    return 'Factored $productionCount productions of $nonTerminal as $nonTerminal → $prefix$introduced.';
  }

  @override
  String grammarPredictiveFactoringSuffix(String introduced, String suffix) {
    return 'The remaining suffix for $introduced is $suffix.';
  }

  @override
  String get grammarPredictiveNoFactoringNeeded =>
      'No common prefixes requiring factoring were found.';

  @override
  String grammarPredictiveProductionLhsUndeclared(String nonTerminal) {
    return 'The production left side $nonTerminal is not a declared non-terminal, so the LL(1) table cannot be built.';
  }

  @override
  String grammarPredictiveMissingTableRow(String nonTerminal) {
    return 'The LL(1) table has no row for non-terminal $nonTerminal.';
  }

  @override
  String grammarPredictiveMissingFollowOrTableEntry(String nonTerminal) {
    return 'The FOLLOW set or LL(1) table entry is missing for non-terminal $nonTerminal.';
  }

  @override
  String grammarPredictiveTablePlacementFirst(
    String production,
    String nonTerminal,
    String lookahead,
  ) {
    return 'Placed $production in LL(1) table[$nonTerminal, $lookahead] using FIRST.';
  }

  @override
  String grammarPredictiveTablePlacementFollow(
    String production,
    String nonTerminal,
    String lookahead,
  ) {
    return 'Placed $production in LL(1) table[$nonTerminal, $lookahead] using FOLLOW.';
  }

  @override
  String grammarPredictiveTableConstructed(int count) {
    return 'Constructed an LL(1) parse table with $count non-terminals.';
  }

  @override
  String get grammarPredictiveTableNoConflicts =>
      'No conflicts were detected in the LL(1) parse table.';

  @override
  String grammarPredictiveTableConflictsDetected(int count) {
    return 'Detected $count conflict(s) in the LL(1) parse table.';
  }

  @override
  String codecGrammarJflapUnsupportedDocumentType(String type) {
    return 'JFLAP document type $type is not a grammar document.';
  }

  @override
  String get codecGrammarJflapEmptyGrammar =>
      'The JFLAP grammar contains no productions.';

  @override
  String codecGrammarJflapMissingProductionSide(int index) {
    return 'Production $index is missing a non-empty left or right side.';
  }

  @override
  String get codecGrammarJflapStartSymbolUndetermined =>
      'The grammar start symbol could not be determined.';

  @override
  String codecGrammarJflapUnknownGrammarTypePreserved(String type) {
    return 'Unknown grammar type $type was preserved for re-export.';
  }

  @override
  String codecGrammarJflapUnknownOptionalElement(String extension) {
    return 'Unknown optional XML data $extension was preserved with provenance.';
  }

  @override
  String get codecGrammarJflapTokenizationNormalized =>
      'JFLAP grammar text was normalized to token arrays.';

  @override
  String get codecGrammarJflapRequiresGrammarDocument =>
      'The Grammar JFLAP codec requires a Grammar document.';

  @override
  String codecGrammarJflapUnsupportedSchema(int version) {
    return 'Grammar schema version $version is not supported.';
  }

  @override
  String get codecGrammarJflapInvalidDocument =>
      'The Grammar document is invalid.';

  @override
  String codecGrammarJflapTokenBoundariesLossy(String tokens) {
    return 'Token boundaries $tokens cannot be preserved in JFLAP grammar XML.';
  }

  @override
  String codecGrammarJflapClassificationLossy(String classification) {
    return 'Grammar classification $classification cannot be preserved in JFLAP XML.';
  }

  @override
  String get codecLSystemJflapInvalidRoot =>
      'The L-system JFLAP document must have a <structure> root.';

  @override
  String codecLSystemJflapUnsupportedDocumentType(String type) {
    return 'JFLAP document type $type is not an L-system document.';
  }

  @override
  String get codecLSystemJflapMissingAxiom =>
      'The JFLAP L-system document is missing an axiom.';

  @override
  String get codecLSystemJflapMalformedXml =>
      'The L-system JFLAP XML is malformed.';

  @override
  String get codecLSystemJflapInvalidUtf8 =>
      'The L-system JFLAP document is not valid UTF-8.';

  @override
  String get codecLSystemJflapEmptyPredecessor =>
      'An L-system production has an empty predecessor.';

  @override
  String codecLSystemJflapInvalidContextPredecessor(String production) {
    return 'The context-sensitive predecessor $production is invalid.';
  }

  @override
  String codecLSystemJflapInvalidParameter(String parameter) {
    return 'The L-system parameter $parameter is invalid.';
  }

  @override
  String codecLSystemJflapInvalidParameterValue(
    String parameter,
    String value,
  ) {
    return 'The L-system parameter $parameter has invalid value $value.';
  }

  @override
  String codecLSystemJflapInvalidExtension(String extension) {
    return 'The L-system extension $extension is invalid.';
  }

  @override
  String codecLSystemJflapInvalidProductionMetadata(String field) {
    return 'L-system production metadata field $field is invalid.';
  }

  @override
  String get codecLSystemJflapInvalidCommandMapping =>
      'The L-system command mapping is invalid.';

  @override
  String get codecLSystemJflapInvalidDocument =>
      'The L-system document is invalid.';

  @override
  String get codecLSystemJflapRequiresLSystemDocument =>
      'The JFLAP codec requires an L-system document.';

  @override
  String codecLSystemJflapUnsupportedSchema(int version) {
    return 'L-system schema version $version is not supported.';
  }

  @override
  String get codecLSystemJflapDecodeFailed =>
      'The L-system JFLAP document could not be decoded.';

  @override
  String get codecLSystemJflapEncodeFailed =>
      'The L-system could not be encoded as JFLAP XML.';

  @override
  String codecLSystemJflapAdvancedVariantPreserved(String variants) {
    return 'Unsupported L-system variants $variants were preserved for re-export.';
  }

  @override
  String codecLSystemJflapParametersPreserved(String parameters) {
    return 'L-system parameters $parameters were preserved.';
  }

  @override
  String codecLSystemJflapExecutionExtensionRestored(String features) {
    return 'L-system execution extensions $features were restored.';
  }

  @override
  String get codecLSystemJflapElementsPreserved =>
      'Additional L-system XML elements were preserved.';

  @override
  String codecLSystemJflapExecutionExtension(String features) {
    return 'L-system execution extension details $features are stored in Turing Lab parameters.';
  }

  @override
  String codecLSystemJflapAdvancedVariantExtension(String variants) {
    return 'Advanced L-system variants $variants are stored in the Turing Lab extension.';
  }

  @override
  String get codecVersionedJsonInvalidUtf8 =>
      'The JSON document is not valid UTF-8.';

  @override
  String get codecVersionedJsonRootMustBeObject =>
      'The JSON document root must be an object.';

  @override
  String get codecVersionedJsonMalformedJson =>
      'The JSON document is malformed.';

  @override
  String get codecVersionedJsonUnsupportedDocument =>
      'The JSON payload is not a recognized Turing Lab document.';

  @override
  String get codecVersionedJsonLegacyEnvelopeMigrated =>
      'Legacy JSON was migrated to the current document envelope.';

  @override
  String codecVersionedJsonUnknownFieldPreserved(String scope, String field) {
    return 'Unknown $scope field $field was preserved.';
  }

  @override
  String get codecVersionedJsonEnvelopeVersionInvalid =>
      'The JSON envelope version must be a positive integer.';

  @override
  String codecVersionedJsonUnsupportedEnvelopeVersion(int version) {
    return 'JSON envelope version $version is not supported.';
  }

  @override
  String get codecVersionedJsonMissingDocument =>
      'The JSON envelope is missing its document object.';

  @override
  String codecVersionedJsonDocumentKeyMismatch(String system) {
    return 'The JSON envelope does not describe the expected $system document.';
  }

  @override
  String get codecVersionedJsonMissingSchema =>
      'The JSON envelope is missing its schema object.';

  @override
  String get codecVersionedJsonSchemaIdentityInvalid =>
      'The JSON envelope schema identity is invalid.';

  @override
  String codecVersionedJsonUnsupportedSchemaVersion(int version) {
    return 'JSON schema version $version is not supported.';
  }

  @override
  String get codecVersionedJsonMissingPayload =>
      'The JSON envelope is missing its payload object.';

  @override
  String get codecVersionedJsonSourceMetadataInvalid =>
      'The JSON source metadata must be an object.';

  @override
  String codecVersionedJsonSourceFieldInvalid(String field) {
    return 'JSON source field $field must be a string.';
  }

  @override
  String get codecVersionedJsonExtensionsInvalid =>
      'The JSON extensions value must be an object.';

  @override
  String codecVersionedJsonMigrationPathMissing(int version) {
    return 'No JSON migration path exists from schema version $version.';
  }

  @override
  String get codecVersionedJsonMigrationRejected =>
      'The JSON schema migration rejected the payload.';

  @override
  String get codecVersionedJsonMigrationInvalidValue =>
      'The JSON schema migration received an invalid value.';

  @override
  String get codecVersionedJsonMigrationFailed =>
      'The JSON schema migration failed.';

  @override
  String codecVersionedJsonSchemaMigrated(int from, int to) {
    return 'The JSON payload was migrated from schema $from to schema $to.';
  }

  @override
  String get codecVersionedJsonExtensionKeysInvalid =>
      'JSON extension keys must be strings.';

  @override
  String get codecVersionedJsonPayloadValueTypeInvalid =>
      'The JSON document payload contains an invalid value type.';

  @override
  String get codecVersionedJsonDecoderValueTypeInvalid =>
      'The JSON document decoder received an invalid value.';

  @override
  String get codecVersionedJsonDecoderFailed =>
      'The JSON document model could not be decoded.';

  @override
  String codecVersionedJsonEncodeDocumentMismatch(String system) {
    return 'This JSON codec cannot encode the $system document.';
  }

  @override
  String get codecVersionedJsonEncodeSchemaUnsupported =>
      'The JSON document schema version is not supported for export.';

  @override
  String get codecVersionedJsonEncodeValueInvalid =>
      'The document contains data that cannot be represented as JSON.';

  @override
  String get codecVersionedJsonEncoderFailed =>
      'The JSON document model could not be encoded.';

  @override
  String get codecVersionedJsonSourceMetadataNormalized =>
      'Source metadata was normalized for the exported JSON document.';

  @override
  String get codecVersionedJsonUnknownFieldsSidecarNormalized =>
      'Unknown JSON fields were emitted in the extension sidecar.';

  @override
  String get codecVersionedJsonEnvelopeSerializationFailed =>
      'The JSON document envelope could not be serialized.';

  @override
  String get codecRegexJflapUnsupportedDocument =>
      'The JFLAP payload is not a regular-expression document.';

  @override
  String get codecRegexJflapMultipleExpressions =>
      'The JFLAP document contains multiple regular expressions.';

  @override
  String get codecRegexJflapMultipleExtensions =>
      'The JFLAP document contains multiple Turing Lab extensions.';

  @override
  String get codecRegexJflapInvalidExtension =>
      'The Turing Lab regular-expression extension is invalid.';

  @override
  String get codecRegexJflapExtensionMismatch =>
      'The Turing Lab regular-expression extension does not match the source.';

  @override
  String get codecRegexJflapDialectNormalized =>
      'The regular expression dialect was normalized during import.';

  @override
  String get codecRegexJflapUnsupportedDialect =>
      'JFLAP export supports only the Turing Lab v1 Unicode-scalar regular-expression dialect.';

  @override
  String get codecRegexJflapNonBmpSymbol =>
      'JFLAP cannot safely preserve regular-expression symbols outside the Basic Multilingual Plane.';

  @override
  String codecRegexJflapEscapeUnsupported(String symbol) {
    return 'JFLAP has no escape syntax for the literal \"$symbol\".';
  }

  @override
  String get codecRegexJflapEmptyLanguageUnsupported =>
      'JFLAP 7.1 cannot reopen the empty-language symbol with equivalent semantics.';

  @override
  String codecRegexJflapReservedLiteral(String symbol) {
    return 'The literal \"$symbol\" has reserved or profile-dependent meaning in JFLAP.';
  }

  @override
  String codecRegexJflapUnsupportedConstruct(String symbol) {
    return 'The JFLAP regular-expression dialect does not support the \"$symbol\" construct.';
  }

  @override
  String codecRegexJflapProfileDependentSymbol(String symbol) {
    return 'The JFLAP symbol \"$symbol\" depends on a global profile. Use ! for portable epsilon.';
  }

  @override
  String get codecRegexJflapInvalidDocument =>
      'The regular-expression document is invalid.';

  @override
  String get codecRegexJflapMalformedDocument =>
      'The regular-expression JFLAP document is malformed.';

  @override
  String get codecRegexJflapExpectedRegexDocument =>
      'The JFLAP codec requires a regular-expression document.';

  @override
  String get codecRegexJflapTuringLabExtensionPortability =>
      'Turing Lab regular-expression extension data cannot be represented in JFLAP and was dropped.';

  @override
  String get codecRegexJflapEmptySetInteroperability =>
      'The empty-set symbol was normalized for JFLAP interoperability.';

  @override
  String get codecRegexJflapUnbalancedParentheses =>
      'JFLAP regular-expression parentheses are unbalanced.';

  @override
  String get codecRegexJflapMalformedOperators =>
      'JFLAP regular-expression operators are malformed.';

  @override
  String get codecRegexJflapUnionMissingOperand =>
      'JFLAP regular-expression union is missing an operand.';

  @override
  String get codecRegexJflapEpsilonLeftConcatenation =>
      'JFLAP epsilon cannot be concatenated on its left.';

  @override
  String get codecRegexJflapEpsilonRightConcatenation =>
      'JFLAP epsilon cannot be concatenated on its right.';

  @override
  String get codecRegexJflapEscapeMissingSymbol =>
      'JFLAP regular-expression escape must be followed by a symbol.';

  @override
  String get codecRegexJflapInvalidSource =>
      'The regular-expression source is invalid.';

  @override
  String get codecRegexJsonUnexpectedDecoderType =>
      'The regular-expression JSON decoder received an unexpected value type.';

  @override
  String get codecRegexJsonSourceOfTruthInvalid =>
      'The regular-expression JSON source of truth is invalid.';

  @override
  String get codecRegexJsonCanonicalAstMismatch =>
      'The regular-expression JSON source does not match its canonical AST.';

  @override
  String get codecRegexJsonExpectedRegexDocument =>
      'The JSON codec requires a regular-expression document.';

  @override
  String get codecRegexJsonInvalidDocument =>
      'The regular-expression JSON document is invalid.';

  @override
  String get codecRegexJsonUnsupportedDialect =>
      'The regular-expression JSON dialect is not supported.';

  @override
  String get codecRegexJsonInvalidSource =>
      'The regular-expression JSON source is invalid.';

  @override
  String get codecRegexJsonUnexpectedValidationOutcome =>
      'The regular-expression JSON validation returned an unexpected outcome.';

  @override
  String get codecPdaJflapInvalidUtf8 =>
      'The PDA JFLAP document is not valid UTF-8.';

  @override
  String get codecPdaJflapMalformedXml => 'The PDA JFLAP XML is malformed.';

  @override
  String get codecPdaJflapInvalidRoot =>
      'The PDA JFLAP XML root must be <structure>.';

  @override
  String codecPdaJflapUnsupportedDocumentType(String type) {
    return 'JFLAP document type $type is not a PDA document.';
  }

  @override
  String get codecPdaJflapMissingAutomaton =>
      'The JFLAP PDA document is missing <automaton>.';

  @override
  String get codecPdaJflapMissingStateId =>
      'A PDA JFLAP state is missing a non-empty ID.';

  @override
  String codecPdaJflapDuplicateStateId(String state) {
    return 'PDA state $state has a duplicate ID.';
  }

  @override
  String codecPdaJflapInvalidStateCoordinate(String state) {
    return 'PDA state $state has an invalid coordinate.';
  }

  @override
  String get codecPdaJflapInvalidDocument => 'The PDA document is invalid.';

  @override
  String codecPdaJflapUnknownTransitionEndpoints(String from, String to) {
    return 'A PDA transition references unknown states $from and $to.';
  }

  @override
  String get codecPdaJflapInvalidTransitionId =>
      'The PDA transition ID is invalid.';

  @override
  String get codecPdaJflapDuplicateTransitionId =>
      'The PDA transition ID is duplicated.';

  @override
  String get codecPdaJflapInvalidAcceptanceMode =>
      'The PDA acceptance mode is invalid.';

  @override
  String get codecPdaJflapMalformedExtension =>
      'The Turing Lab PDA extension is malformed.';

  @override
  String get codecPdaJflapCanonicalOrderImport =>
      'PDA states and transitions were ordered canonically during import.';

  @override
  String get codecPdaJflapStaleTokenExtension =>
      'The PDA token extension was stale and was ignored.';

  @override
  String get codecPdaJflapExplicitEpsilonAliasInterpreted =>
      'An explicit epsilon alias was interpreted as an empty input.';

  @override
  String get codecPdaJflapPopWordTreatedAsAtomicToken =>
      'A multi-character pop word was treated as one stack token.';

  @override
  String get codecPdaJflapAcceptanceModeAssumedFinalState =>
      'JFLAP acceptance mode was assumed to be final-state mode.';

  @override
  String get codecPdaJflapRequiresPdaDocument =>
      'The JFLAP codec requires a PDA document.';

  @override
  String codecPdaJflapUnsupportedSchema(int version) {
    return 'PDA schema version $version is not supported.';
  }

  @override
  String get codecPdaJflapExtensionPortability =>
      'PDA extension data cannot be represented in standard JFLAP and was dropped.';

  @override
  String get codecPdaJflapInitialStackSymbolNotPortable =>
      'The PDA initial stack symbol is not portable to standard JFLAP.';

  @override
  String get codecPdaJflapAcceptanceModeNotPortable =>
      'The PDA acceptance mode is not portable to standard JFLAP.';

  @override
  String get codecPdaJflapAtomicPopTokenNotPortable =>
      'An atomic PDA pop token is not portable to standard JFLAP.';

  @override
  String get codecPdaJflapAtomicPushTokenNotPortable =>
      'An atomic PDA push token is not portable to standard JFLAP.';

  @override
  String codecPdaJflapUnknownOptionalElement(String extension) {
    return 'Unknown optional XML element $extension was preserved.';
  }

  @override
  String codecPdaJflapUnknownOptionalAttribute(String extension) {
    return 'Unknown optional XML attribute $extension was preserved.';
  }

  @override
  String get codecPdaJflapInvalidNotePosition =>
      'A PDA note has an invalid position.';

  @override
  String get codecPdaJflapNotesNormalized =>
      'PDA notes were normalized during import.';

  @override
  String get codecPdaJflapNotePresentationDropped =>
      'PDA note presentation data was dropped.';

  @override
  String get codecPdaJflapUnknownDiagnostic =>
      'The PDA document contains an unknown diagnostic.';

  @override
  String get codecPdaJsonUnexpectedDocumentType =>
      'The PDA JSON decoder returned an unexpected document type.';

  @override
  String get codecPdaJsonInvalidDocument => 'The PDA JSON document is invalid.';

  @override
  String get codecTmJflapInvalidUtf8 =>
      'The TM JFLAP document is not valid UTF-8.';

  @override
  String get codecTmJflapMalformedXml => 'The TM JFLAP XML is malformed.';

  @override
  String get codecTmJflapInvalidRoot =>
      'The TM JFLAP XML root must be <structure>.';

  @override
  String codecTmJflapUnsupportedDocumentType(String type) {
    return 'JFLAP document type $type is not a Turing machine document.';
  }

  @override
  String get codecTmJflapUnsupportedFeature =>
      'The TM JFLAP document uses an unsupported feature.';

  @override
  String get codecTmJflapInvalidTapeCount => 'The TM tape count is invalid.';

  @override
  String get codecTmJflapMissingAutomaton =>
      'The TM JFLAP document is missing <automaton>.';

  @override
  String get codecTmJflapMalformedExtension =>
      'The Turing Lab TM extension is malformed.';

  @override
  String get codecTmJflapCanonicalOrderImport =>
      'TM states and transitions were ordered canonically during import.';

  @override
  String get codecTmJflapCanonicalOrderExport =>
      'TM states and transitions were ordered canonically during export.';

  @override
  String get codecTmJflapVariantMismatch =>
      'The TM variant does not match the document.';

  @override
  String get codecTmJflapTapeCountMismatch =>
      'The TM tape count does not match the document.';

  @override
  String get codecTmJflapBlankSymbolInvalid =>
      'The TM blank symbol is invalid.';

  @override
  String get codecTmJflapAcceptancePolicyInvalid =>
      'The TM acceptance policy is invalid.';

  @override
  String get codecTmJflapIncompleteExtension =>
      'The Turing Lab TM extension is incomplete.';

  @override
  String get codecTmJflapExtensionSchemaInvalid =>
      'The Turing Lab TM extension schema is invalid.';

  @override
  String get codecTmJflapMissingStateId =>
      'A TM JFLAP state is missing a non-empty ID.';

  @override
  String codecTmJflapDuplicateStateId(String state) {
    return 'TM state $state has a duplicate ID.';
  }

  @override
  String codecTmJflapInvalidStateCoordinate(String state) {
    return 'TM state $state has an invalid coordinate.';
  }

  @override
  String codecTmJflapInvalidStateType(String state) {
    return 'TM state $state has an invalid type.';
  }

  @override
  String codecTmJflapInvalidStateProperties(String state) {
    return 'TM state $state has invalid properties.';
  }

  @override
  String get codecTmJflapInvalidInitialStateCount =>
      'The TM document must contain exactly one initial state.';

  @override
  String codecTmJflapUnknownTransitionEndpoints(String from, String to) {
    return 'A TM transition references unknown states $from and $to.';
  }

  @override
  String get codecTmJflapInvalidTapeIndex => 'The TM tape index is invalid.';

  @override
  String codecTmJflapDuplicateTapeOperation(String operation) {
    return 'The TM transition contains a duplicate tape operation: $operation.';
  }

  @override
  String get codecTmJflapUnsupportedReadPredicate =>
      'The TM read predicate is not supported by JFLAP.';

  @override
  String get codecTmJflapInvalidReadSymbol => 'The TM read symbol is invalid.';

  @override
  String get codecTmJflapInvalidWriteSymbol =>
      'The TM write symbol is invalid.';

  @override
  String get codecTmJflapInvalidMove => 'The TM movement must be L, R, or S.';

  @override
  String get codecTmJflapInvalidTransitionExtension =>
      'The Turing Lab TM transition extension is invalid.';

  @override
  String get codecTmJflapInvalidTransitionId =>
      'The TM transition ID is invalid.';

  @override
  String get codecTmJflapDuplicateTransitionId =>
      'The TM transition ID is duplicated.';

  @override
  String codecTmJflapInvalidTransitionLabel(String transition) {
    return 'TM transition $transition has an invalid label.';
  }

  @override
  String codecTmJflapInvalidTransitionType(String transition) {
    return 'TM transition $transition has an invalid type.';
  }

  @override
  String get codecTmJflapInvalidControlPoint =>
      'A TM transition has an invalid control point.';

  @override
  String get codecTmJflapTransitionIdentitiesReconstructed =>
      'TM transition identities were reconstructed during import.';

  @override
  String get codecTmJflapInvalidMetadata => 'The TM metadata is invalid.';

  @override
  String get codecTmJflapInvalidDocument => 'The TM document is invalid.';

  @override
  String get codecTmJflapRequiresTmDocument =>
      'The JFLAP codec requires a Turing machine document.';

  @override
  String codecTmJflapUnsupportedSchema(int version) {
    return 'TM schema version $version is not supported.';
  }

  @override
  String get codecTmJflapUnsupportedTapeCount =>
      'The TM tape count is not supported.';

  @override
  String codecTmJflapUnsupportedOperation(
    String transition,
    String operation,
    String symbol,
  ) {
    return 'TM transition $transition uses unsupported operation $operation on $symbol.';
  }

  @override
  String get codecTmJflapBuildingBlockVariantMismatch =>
      'The building-block TM variant does not match its XML.';

  @override
  String codecTmJflapRecursiveDependency(String block) {
    return 'The TM building blocks contain a recursive dependency at $block.';
  }

  @override
  String codecTmJflapMissingBlockDefinition(String block) {
    return 'The TM building-block definition $block is missing.';
  }

  @override
  String codecTmJflapAmbiguousBlockDefinition(String block) {
    return 'The TM building-block definition $block is ambiguous.';
  }

  @override
  String get codecTmJflapAcceptancePolicyConflict =>
      'The TM root and machine acceptance policies conflict.';

  @override
  String get codecTmJflapMachineSchemaInvalid =>
      'The building-block machine has an invalid Turing Lab schema.';

  @override
  String get codecTmJflapMachineVariantInvalid =>
      'The building-block machine has an invalid TM variant.';

  @override
  String get codecTmJflapMachineTapeCountMismatch =>
      'The building-block machine has a mismatched tape count.';

  @override
  String get codecTmJflapMachineBlankSymbolMismatch =>
      'The building-block machine has a mismatched blank symbol.';

  @override
  String codecTmJflapMissingBlockTag(String block) {
    return 'The TM block $block is missing its tag.';
  }

  @override
  String get codecTmJflapInvalidNodeId =>
      'A TM building-block node ID is invalid.';

  @override
  String get codecTmJflapDuplicateNodeId =>
      'A TM building-block node ID is duplicated.';

  @override
  String codecTmJflapInvalidNodeCoordinate(String node) {
    return 'TM node $node has an invalid coordinate.';
  }

  @override
  String codecTmJflapInvalidNodeStateType(String node) {
    return 'TM node $node has an invalid state type.';
  }

  @override
  String codecTmJflapInvalidNodeProperties(String node) {
    return 'TM node $node has invalid properties.';
  }

  @override
  String codecTmJflapMissingBlockTagReference(String block) {
    return 'The TM building block $block has no tag reference.';
  }

  @override
  String get codecTmJflapInvalidOrDuplicateTapeIndex =>
      'A TM tape index is invalid or duplicated.';

  @override
  String get codecTmJflapTransitionIdentityConflict =>
      'TM transition identity extensions disagree.';

  @override
  String get codecTmJflapBuildingBlocksImported =>
      'TM building blocks were imported.';

  @override
  String get codecTmJflapSharedTapes => 'TM building blocks use shared tapes.';

  @override
  String get codecTmJflapUnknownBuildingBlockExtensionDropped =>
      'An unknown TM building-block extension was dropped.';

  @override
  String get codecTmJflapBuildingBlocksExported =>
      'TM building blocks were exported.';

  @override
  String get codecTmJflapExtensionIdentities =>
      'TM extension identities were normalized.';

  @override
  String get codecTmJflapExtensionPortability =>
      'TM extension data cannot be represented in standard JFLAP and was dropped.';

  @override
  String codecTmJflapUnknownOptionalElement(String extension) {
    return 'Unknown optional XML element $extension was preserved.';
  }

  @override
  String codecTmJflapUnknownOptionalAttribute(String extension) {
    return 'Unknown optional XML attribute $extension was preserved.';
  }

  @override
  String get codecTmJflapInvalidNotePosition =>
      'A TM note has an invalid position.';

  @override
  String get codecTmJflapNotesNormalized =>
      'TM notes were normalized during import.';

  @override
  String get codecTmJflapNotePresentationDropped =>
      'TM note presentation data was dropped.';

  @override
  String get codecTmJflapUnknownDiagnostic =>
      'The TM document contains an unknown diagnostic.';

  @override
  String get codecTmJsonUnexpectedDocumentType =>
      'The TM JSON decoder returned an unexpected document type.';

  @override
  String get codecTmJsonInvalidDocument => 'The TM JSON document is invalid.';

  @override
  String get codecTmJsonVariantMismatch =>
      'The TM JSON variant does not match the document.';

  @override
  String get codecTmJsonVariantInferred =>
      'The TM variant was inferred from the JSON document.';

  @override
  String get codecTmJsonOperationVectorsMigrated =>
      'TM operation vectors were migrated to the current format.';

  @override
  String get codecTmJsonEndpointsMigratedToIds =>
      'TM transition endpoints were migrated to stable IDs.';
}
