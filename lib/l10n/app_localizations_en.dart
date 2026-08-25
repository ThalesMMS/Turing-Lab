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
  String get workspaceStatusLambdaTransitions => 'λ-transitions present';

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
      String id, String from, String to, String label) {
    return 'Transition $id from $from to $to labeled $label.';
  }

  @override
  String get canvasViewportEditHint =>
      'Use keyboard shortcuts or toolbar controls to edit the canvas.';

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
      'Adds a state at the viewport centre and keeps Add State mode active.';

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
  String get pdaLambdaInput => 'λ-input';

  @override
  String get pdaInputSymbolRequired => 'Enter a symbol or enable λ-input';

  @override
  String get pdaPopSymbol => 'Pop symbol';

  @override
  String get pdaLambdaPop => 'λ-pop';

  @override
  String get pdaPopSymbolRequired => 'Enter a symbol or enable λ-pop';

  @override
  String get pdaPushSymbol => 'Push symbol';

  @override
  String get pdaLambdaPush => 'λ-push';

  @override
  String get pdaPushSymbolRequired => 'Enter a symbol or enable λ-push';

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
  String get settingsSectionSymbols => 'Symbols';

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
  String get settingsEmptyStringTitle => 'Empty String Symbol';

  @override
  String get settingsEmptyStringDescription =>
      'Symbol used to represent empty string (λ or ε)';

  @override
  String get settingsLambdaOption => 'λ (Lambda)';

  @override
  String get settingsEpsilonOption => 'ε (Epsilon)';

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
      'PDA and TM: SVG export. JFLAP XML and JSON round trips are outside the current release scope.';

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
    return 'Step $current of $total';
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
      String consumed, String state, String nextState, String remaining) {
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
      'The current automaton does not contain λ-transitions.';

  @override
  String get automatonMustContainLambdaToRemove =>
      'The current automaton must contain λ-transitions to remove them.';

  @override
  String get lambdaTransitionsRemoved => 'λ-transitions removed successfully.';

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
  String get rightSideHelper => 'Use λ/ε for the empty string.';

  @override
  String get insertLambda => 'Insert λ';

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
      'Right side must contain at least one symbol (or λ/ε)';

  @override
  String get rightSideSingleLambda =>
      'Right side can contain only one λ/ε symbol';

  @override
  String get lambdaMustBeOnlySymbol =>
      'λ/ε must be the only symbol on the right side';

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
  String get hideGame => 'Hide Game';

  @override
  String get showGame => 'Show Game';

  @override
  String get showHelp => 'Show Help';

  @override
  String get hideProgress => 'Hide Progress';

  @override
  String get showProgress => 'Show Progress';

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
  String get exampleNfaLambdaAOrAb => 'NFA-λ - A or AB';

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
  String get tapeSymbols => 'Tape Symbols';

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
  String get removeLambdaTitle => 'Remove λ-transitions';

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
      'Generate LL(1) or LR(1) parse table';

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
    return 'Lambda transitions present: $count';
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
  String get pdaAnalysisTitle => 'PDA Analysis';

  @override
  String get tmAnalysisTitle => 'TM Analysis';

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
      int transitions, int configurations) {
    return '$transitions transition(s) • $configurations configuration(s) explored';
  }

  @override
  String get explorationCancelledKept =>
      'Exploration cancelled. Evaluated results were kept.';

  @override
  String get spaceProfilingCancelledKept =>
      'Space profiling cancelled. Evaluated rows were kept.';
}
