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
  String get executing => 'Executing';

  @override
  String get selected => 'Selected';

  @override
  String workflowLegacyText(String text) {
    return '$text';
  }
}
