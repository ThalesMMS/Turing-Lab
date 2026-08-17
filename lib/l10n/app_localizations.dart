import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt')
  ];

  /// Title for the transition selection dialog.
  ///
  /// In en, this message translates to:
  /// **'Select transition'**
  String get selectTransition;

  /// Action label for creating a new transition from the selection dialog.
  ///
  /// In en, this message translates to:
  /// **'Create new transition'**
  String get createNewTransition;

  /// No description provided for @canvasViewportStateCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 states} =1{1 state} other{{count} states}}'**
  String canvasViewportStateCount(int count);

  /// No description provided for @canvasViewportTransitionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 transitions} =1{1 transition} other{{count} transitions}}'**
  String canvasViewportTransitionCount(int count);

  /// No description provided for @workspaceStatusNoAutomaton.
  ///
  /// In en, this message translates to:
  /// **'No automaton defined'**
  String get workspaceStatusNoAutomaton;

  /// No description provided for @workspaceStatusMissingInitialState.
  ///
  /// In en, this message translates to:
  /// **'Missing start state'**
  String get workspaceStatusMissingInitialState;

  /// No description provided for @workspaceStatusNoAcceptingStates.
  ///
  /// In en, this message translates to:
  /// **'No accepting states'**
  String get workspaceStatusNoAcceptingStates;

  /// No description provided for @workspaceStatusNondeterministic.
  ///
  /// In en, this message translates to:
  /// **'Nondeterministic transitions'**
  String get workspaceStatusNondeterministic;

  /// No description provided for @workspaceStatusLambdaTransitions.
  ///
  /// In en, this message translates to:
  /// **'λ-transitions present'**
  String get workspaceStatusLambdaTransitions;

  /// No description provided for @workspaceStatusCounts.
  ///
  /// In en, this message translates to:
  /// **'{states} · {transitions}'**
  String workspaceStatusCounts(String states, String transitions);

  /// No description provided for @workspaceStatusWithWarnings.
  ///
  /// In en, this message translates to:
  /// **'⚠ {warnings} · {counts}'**
  String workspaceStatusWithWarnings(String warnings, String counts);

  /// No description provided for @workspaceHelpUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Help content is not available right now.'**
  String get workspaceHelpUnavailable;

  /// No description provided for @collapseCanvasPanel.
  ///
  /// In en, this message translates to:
  /// **'Collapse {label} panel'**
  String collapseCanvasPanel(String label);

  /// No description provided for @expandCanvasPanel.
  ///
  /// In en, this message translates to:
  /// **'Expand {label} panel'**
  String expandCanvasPanel(String label);

  /// No description provided for @canvasViewportSemantics.
  ///
  /// In en, this message translates to:
  /// **'Automaton canvas viewport. {states}, {transitions}.'**
  String canvasViewportSemantics(String states, String transitions);

  /// No description provided for @canvasStateSemantics.
  ///
  /// In en, this message translates to:
  /// **'State {name}.'**
  String canvasStateSemantics(String name);

  /// No description provided for @canvasInitialStateSemantics.
  ///
  /// In en, this message translates to:
  /// **'Initial state.'**
  String get canvasInitialStateSemantics;

  /// No description provided for @canvasAcceptingStateSemantics.
  ///
  /// In en, this message translates to:
  /// **'Accepting state.'**
  String get canvasAcceptingStateSemantics;

  /// No description provided for @canvasOutgoingTransitionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 outgoing transitions.} =1{1 outgoing transition.} other{{count} outgoing transitions.}}'**
  String canvasOutgoingTransitionCount(int count);

  /// No description provided for @canvasIncomingTransitionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 incoming transitions.} =1{1 incoming transition.} other{{count} incoming transitions.}}'**
  String canvasIncomingTransitionCount(int count);

  /// No description provided for @canvasUnlabeledTransition.
  ///
  /// In en, this message translates to:
  /// **'unlabeled'**
  String get canvasUnlabeledTransition;

  /// No description provided for @canvasSelectedTransitionSemantics.
  ///
  /// In en, this message translates to:
  /// **'Selected transition.'**
  String get canvasSelectedTransitionSemantics;

  /// No description provided for @canvasTransitionSemantics.
  ///
  /// In en, this message translates to:
  /// **'Transition {id} from {from} to {to} labeled {label}.'**
  String canvasTransitionSemantics(
      String id, String from, String to, String label);

  /// No description provided for @canvasViewportEditHint.
  ///
  /// In en, this message translates to:
  /// **'Use keyboard shortcuts or toolbar controls to edit the canvas.'**
  String get canvasViewportEditHint;

  /// No description provided for @canvasStateEditHint.
  ///
  /// In en, this message translates to:
  /// **'Activate to edit state details. Drag to move in selection mode.'**
  String get canvasStateEditHint;

  /// No description provided for @canvasStateReadOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'Read-only state.'**
  String get canvasStateReadOnlyHint;

  /// No description provided for @canvasAddTransitionPrompt.
  ///
  /// In en, this message translates to:
  /// **'Add transition...'**
  String get canvasAddTransitionPrompt;

  /// No description provided for @canvasChooseTargetState.
  ///
  /// In en, this message translates to:
  /// **'Choose target state'**
  String get canvasChooseTargetState;

  /// No description provided for @dismissTransitionEditor.
  ///
  /// In en, this message translates to:
  /// **'Dismiss transition editor'**
  String get dismissTransitionEditor;

  /// No description provided for @stateLabel.
  ///
  /// In en, this message translates to:
  /// **'State label'**
  String get stateLabel;

  /// No description provided for @initialState.
  ///
  /// In en, this message translates to:
  /// **'Initial state'**
  String get initialState;

  /// No description provided for @acceptingState.
  ///
  /// In en, this message translates to:
  /// **'Accepting state'**
  String get acceptingState;

  /// No description provided for @deleteState.
  ///
  /// In en, this message translates to:
  /// **'Delete state'**
  String get deleteState;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @canvasActionSemantics.
  ///
  /// In en, this message translates to:
  /// **'Canvas action: {action}'**
  String canvasActionSemantics(String action);

  /// No description provided for @canvasSelectAction.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get canvasSelectAction;

  /// No description provided for @canvasAddStateAction.
  ///
  /// In en, this message translates to:
  /// **'Add state'**
  String get canvasAddStateAction;

  /// No description provided for @canvasAddTransitionAction.
  ///
  /// In en, this message translates to:
  /// **'Add transition'**
  String get canvasAddTransitionAction;

  /// No description provided for @canvasUndoAction.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get canvasUndoAction;

  /// No description provided for @canvasRedoAction.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get canvasRedoAction;

  /// No description provided for @canvasZoomOutAction.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get canvasZoomOutAction;

  /// No description provided for @canvasZoomInAction.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get canvasZoomInAction;

  /// No description provided for @canvasFitToContentAction.
  ///
  /// In en, this message translates to:
  /// **'Fit to content'**
  String get canvasFitToContentAction;

  /// No description provided for @canvasResetViewAction.
  ///
  /// In en, this message translates to:
  /// **'Reset view'**
  String get canvasResetViewAction;

  /// No description provided for @canvasClearAction.
  ///
  /// In en, this message translates to:
  /// **'Clear canvas'**
  String get canvasClearAction;

  /// No description provided for @canvasHelpAction.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get canvasHelpAction;

  /// No description provided for @canvasHelpShortcutsAction.
  ///
  /// In en, this message translates to:
  /// **'Help & Shortcuts'**
  String get canvasHelpShortcutsAction;

  /// No description provided for @canvasSelectHint.
  ///
  /// In en, this message translates to:
  /// **'Activates selection mode for moving and editing states.'**
  String get canvasSelectHint;

  /// No description provided for @canvasAddStateHint.
  ///
  /// In en, this message translates to:
  /// **'Adds a new state to the automaton canvas.'**
  String get canvasAddStateHint;

  /// No description provided for @canvasAddTransitionHint.
  ///
  /// In en, this message translates to:
  /// **'Activates transition mode to connect two states.'**
  String get canvasAddTransitionHint;

  /// No description provided for @canvasUndoHint.
  ///
  /// In en, this message translates to:
  /// **'Reverts the most recent canvas change.'**
  String get canvasUndoHint;

  /// No description provided for @canvasRedoHint.
  ///
  /// In en, this message translates to:
  /// **'Restores the most recently undone canvas change.'**
  String get canvasRedoHint;

  /// No description provided for @canvasZoomOutHint.
  ///
  /// In en, this message translates to:
  /// **'Decreases the canvas zoom level.'**
  String get canvasZoomOutHint;

  /// No description provided for @canvasZoomInHint.
  ///
  /// In en, this message translates to:
  /// **'Increases the canvas zoom level.'**
  String get canvasZoomInHint;

  /// No description provided for @canvasFitToContentHint.
  ///
  /// In en, this message translates to:
  /// **'Zooms and pans to show the full automaton.'**
  String get canvasFitToContentHint;

  /// No description provided for @canvasResetViewHint.
  ///
  /// In en, this message translates to:
  /// **'Resets the canvas zoom and pan position.'**
  String get canvasResetViewHint;

  /// No description provided for @canvasClearHint.
  ///
  /// In en, this message translates to:
  /// **'Removes all states and transitions from the canvas.'**
  String get canvasClearHint;

  /// No description provided for @canvasHelpShortcutsHint.
  ///
  /// In en, this message translates to:
  /// **'Opens canvas help and keyboard shortcut information.'**
  String get canvasHelpShortcutsHint;

  /// No description provided for @pdaInputSymbol.
  ///
  /// In en, this message translates to:
  /// **'Input symbol'**
  String get pdaInputSymbol;

  /// No description provided for @pdaLambdaInput.
  ///
  /// In en, this message translates to:
  /// **'λ-input'**
  String get pdaLambdaInput;

  /// No description provided for @pdaInputSymbolRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a symbol or enable λ-input'**
  String get pdaInputSymbolRequired;

  /// No description provided for @pdaPopSymbol.
  ///
  /// In en, this message translates to:
  /// **'Pop symbol'**
  String get pdaPopSymbol;

  /// No description provided for @pdaLambdaPop.
  ///
  /// In en, this message translates to:
  /// **'λ-pop'**
  String get pdaLambdaPop;

  /// No description provided for @pdaPopSymbolRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a symbol or enable λ-pop'**
  String get pdaPopSymbolRequired;

  /// No description provided for @pdaPushSymbol.
  ///
  /// In en, this message translates to:
  /// **'Push symbol'**
  String get pdaPushSymbol;

  /// No description provided for @pdaLambdaPush.
  ///
  /// In en, this message translates to:
  /// **'λ-push'**
  String get pdaLambdaPush;

  /// No description provided for @pdaPushSymbolRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a symbol or enable λ-push'**
  String get pdaPushSymbolRequired;

  /// No description provided for @tmReadSymbol.
  ///
  /// In en, this message translates to:
  /// **'Read symbol'**
  String get tmReadSymbol;

  /// No description provided for @tmReadSymbolRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a read symbol'**
  String get tmReadSymbolRequired;

  /// No description provided for @tmWriteSymbol.
  ///
  /// In en, this message translates to:
  /// **'Write symbol'**
  String get tmWriteSymbol;

  /// No description provided for @tmWriteSymbolRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a write symbol'**
  String get tmWriteSymbolRequired;

  /// No description provided for @tmDirection.
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get tmDirection;

  /// No description provided for @transitionEditorCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get transitionEditorCancel;

  /// No description provided for @transitionEditorDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get transitionEditorDelete;

  /// No description provided for @transitionEditorSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get transitionEditorSave;

  /// No description provided for @transitionLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get transitionLabel;

  /// No description provided for @transitionEditLabelSemantics.
  ///
  /// In en, this message translates to:
  /// **'Edit transition label'**
  String get transitionEditLabelSemantics;

  /// Tooltip for opening contextual help for the current regex workflow.
  ///
  /// In en, this message translates to:
  /// **'Context-Aware Help'**
  String get contextAwareHelp;

  /// Label for the algorithms section.
  ///
  /// In en, this message translates to:
  /// **'Algorithms'**
  String get algorithms;

  /// No description provided for @settingsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsPageTitle;

  /// No description provided for @settingsSaveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get settingsSaveTooltip;

  /// No description provided for @settingsResetTooltip.
  ///
  /// In en, this message translates to:
  /// **'Reset to Defaults'**
  String get settingsResetTooltip;

  /// No description provided for @settingsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load settings. Please try again.'**
  String get settingsLoadError;

  /// No description provided for @settingsSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Settings saved.'**
  String get settingsSaveSuccess;

  /// No description provided for @settingsSaveError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save settings. Please try again.'**
  String get settingsSaveError;

  /// No description provided for @settingsApplyError.
  ///
  /// In en, this message translates to:
  /// **'Settings were saved, but could not be applied. Restart Turing Lab to refresh them.'**
  String get settingsApplyError;

  /// No description provided for @settingsResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Settings reset to defaults.'**
  String get settingsResetSuccess;

  /// No description provided for @settingsSectionSymbols.
  ///
  /// In en, this message translates to:
  /// **'Symbols'**
  String get settingsSectionSymbols;

  /// No description provided for @settingsSectionTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsSectionTheme;

  /// No description provided for @settingsSectionLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsSectionLanguage;

  /// No description provided for @settingsSectionCanvas.
  ///
  /// In en, this message translates to:
  /// **'Canvas'**
  String get settingsSectionCanvas;

  /// No description provided for @settingsSectionGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsSectionGeneral;

  /// No description provided for @settingsSectionActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get settingsSectionActions;

  /// No description provided for @settingsEmptyStringTitle.
  ///
  /// In en, this message translates to:
  /// **'Empty String Symbol'**
  String get settingsEmptyStringTitle;

  /// No description provided for @settingsEmptyStringDescription.
  ///
  /// In en, this message translates to:
  /// **'Symbol used to represent empty string (λ or ε)'**
  String get settingsEmptyStringDescription;

  /// No description provided for @settingsLambdaOption.
  ///
  /// In en, this message translates to:
  /// **'λ (Lambda)'**
  String get settingsLambdaOption;

  /// No description provided for @settingsEpsilonOption.
  ///
  /// In en, this message translates to:
  /// **'ε (Epsilon)'**
  String get settingsEpsilonOption;

  /// No description provided for @settingsThemeModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get settingsThemeModeTitle;

  /// No description provided for @settingsThemeModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred theme'**
  String get settingsThemeModeDescription;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get settingsLanguageTitle;

  /// No description provided for @settingsLanguageDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose the language used by Turing Lab'**
  String get settingsLanguageDescription;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguagePortuguese.
  ///
  /// In en, this message translates to:
  /// **'Português'**
  String get settingsLanguagePortuguese;

  /// No description provided for @settingsShowGridTitle.
  ///
  /// In en, this message translates to:
  /// **'Show Grid'**
  String get settingsShowGridTitle;

  /// No description provided for @settingsShowGridDescription.
  ///
  /// In en, this message translates to:
  /// **'Display grid lines on canvas'**
  String get settingsShowGridDescription;

  /// No description provided for @settingsShowCoordinatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Show Coordinates'**
  String get settingsShowCoordinatesTitle;

  /// No description provided for @settingsShowCoordinatesDescription.
  ///
  /// In en, this message translates to:
  /// **'Display coordinate information'**
  String get settingsShowCoordinatesDescription;

  /// No description provided for @settingsGridSizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Grid Size'**
  String get settingsGridSizeTitle;

  /// No description provided for @settingsGridSizeDescription.
  ///
  /// In en, this message translates to:
  /// **'Size of grid cells'**
  String get settingsGridSizeDescription;

  /// No description provided for @settingsNodeSizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Node Size'**
  String get settingsNodeSizeTitle;

  /// No description provided for @settingsNodeSizeDescription.
  ///
  /// In en, this message translates to:
  /// **'Size of automaton nodes'**
  String get settingsNodeSizeDescription;

  /// No description provided for @settingsFontSizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get settingsFontSizeTitle;

  /// No description provided for @settingsFontSizeDescription.
  ///
  /// In en, this message translates to:
  /// **'Text size in the interface'**
  String get settingsFontSizeDescription;

  /// No description provided for @settingsAutoSaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto Save'**
  String get settingsAutoSaveTitle;

  /// No description provided for @settingsAutoSaveDescription.
  ///
  /// In en, this message translates to:
  /// **'Automatically save changes'**
  String get settingsAutoSaveDescription;

  /// No description provided for @settingsShowTooltipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Show Tooltips'**
  String get settingsShowTooltipsTitle;

  /// No description provided for @settingsShowTooltipsDescription.
  ///
  /// In en, this message translates to:
  /// **'Display helpful tooltips'**
  String get settingsShowTooltipsDescription;

  /// Tooltip for opening the app help page from the home page.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get homeHelpTooltip;

  /// Tooltip for opening app settings from the home page.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get homeSettingsTooltip;

  /// Navigation label for the finite state automata workspace.
  ///
  /// In en, this message translates to:
  /// **'FSA'**
  String get homeNavigationFsaLabel;

  /// Short navigation description for the finite state automata workspace.
  ///
  /// In en, this message translates to:
  /// **'Finite State Automata'**
  String get homeNavigationFsaDescription;

  /// Navigation label for the grammar workspace.
  ///
  /// In en, this message translates to:
  /// **'Grammar'**
  String get homeNavigationGrammarLabel;

  /// Short navigation description for the grammar workspace.
  ///
  /// In en, this message translates to:
  /// **'Context-Free Grammars'**
  String get homeNavigationGrammarDescription;

  /// Navigation label for the pushdown automata workspace.
  ///
  /// In en, this message translates to:
  /// **'PDA'**
  String get homeNavigationPdaLabel;

  /// Short navigation description for the pushdown automata workspace.
  ///
  /// In en, this message translates to:
  /// **'Pushdown Automata'**
  String get homeNavigationPdaDescription;

  /// Navigation label for the Turing machine workspace.
  ///
  /// In en, this message translates to:
  /// **'TM'**
  String get homeNavigationTmLabel;

  /// Short navigation description for the Turing machine workspace.
  ///
  /// In en, this message translates to:
  /// **'Turing Machines'**
  String get homeNavigationTmDescription;

  /// Navigation label for the regular expression workspace.
  ///
  /// In en, this message translates to:
  /// **'Regex'**
  String get homeNavigationRegexLabel;

  /// Short navigation description for the regular expression workspace.
  ///
  /// In en, this message translates to:
  /// **'Regular Expressions'**
  String get homeNavigationRegexDescription;

  /// Navigation label for the pumping lemma workspace.
  ///
  /// In en, this message translates to:
  /// **'Pumping'**
  String get homeNavigationPumpingLabel;

  /// Short navigation description for the pumping lemma workspace.
  ///
  /// In en, this message translates to:
  /// **'Pumping Lemma'**
  String get homeNavigationPumpingDescription;

  /// Title for the help and documentation page.
  ///
  /// In en, this message translates to:
  /// **'Help & Documentation'**
  String get helpPageTitle;

  /// Tooltip for opening help search.
  ///
  /// In en, this message translates to:
  /// **'Search Help'**
  String get helpSearchTooltip;

  /// Title for the quick start help dialog.
  ///
  /// In en, this message translates to:
  /// **'Quick Start Guide'**
  String get helpQuickStartTitle;

  /// Body text for the quick start help dialog.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Turing Lab. Here is a quick way to get started:\n\n1. Choose a workspace such as FSA, Grammar, PDA, TM, or Regex.\n2. Start with a blank workspace or open a supported example or file.\n3. Use the editor to build your machine or grammar. Double-tap a state for quick actions.\n4. Run simulations to test your work.\n5. Use algorithms to transform structures.\n\nTips:\n• Use navigation tabs or section chips to switch workspaces quickly.\n• Double-tap a state to open its quick action menu.\n• Pinch to zoom on the canvas.\n• Tap the Quick Start icon whenever you need a refresher.'**
  String get helpQuickStartBody;

  /// Confirmation button label for dismissing help dialogs.
  ///
  /// In en, this message translates to:
  /// **'Got it!'**
  String get helpGotIt;

  /// Placeholder label for the help search field.
  ///
  /// In en, this message translates to:
  /// **'Search help...'**
  String get helpSearchFieldLabel;

  /// Tooltip for clearing the help search query.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get helpSearchClear;

  /// Tooltip for closing help search.
  ///
  /// In en, this message translates to:
  /// **'Close search'**
  String get helpSearchClose;

  /// Title shown in the help search view.
  ///
  /// In en, this message translates to:
  /// **'Search Help'**
  String get helpSearchTitle;

  /// Subtitle shown in the help search view.
  ///
  /// In en, this message translates to:
  /// **'Find tutorials, shortcuts, and theory explanations'**
  String get helpSearchSubtitle;

  /// Message title shown when help search has no matches.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get helpSearchNoResults;

  /// Suggestion shown when help search has no matches.
  ///
  /// In en, this message translates to:
  /// **'Try different keywords or check your spelling'**
  String get helpSearchNoResultsDescription;

  /// Help section label for getting started documentation.
  ///
  /// In en, this message translates to:
  /// **'Getting Started'**
  String get helpSectionGettingStarted;

  /// Help section label for finite state automata documentation.
  ///
  /// In en, this message translates to:
  /// **'FSA'**
  String get helpSectionFsa;

  /// Help section label for grammar documentation.
  ///
  /// In en, this message translates to:
  /// **'Grammar'**
  String get helpSectionGrammar;

  /// Help section label for pushdown automata documentation.
  ///
  /// In en, this message translates to:
  /// **'PDA'**
  String get helpSectionPda;

  /// Help section label for Turing machine documentation.
  ///
  /// In en, this message translates to:
  /// **'Turing Machine'**
  String get helpSectionTm;

  /// Help section label for regular expression documentation.
  ///
  /// In en, this message translates to:
  /// **'Regular Expression'**
  String get helpSectionRegex;

  /// Help section label for pumping lemma documentation.
  ///
  /// In en, this message translates to:
  /// **'Pumping Lemma'**
  String get helpSectionPumping;

  /// Help section label for file operation documentation.
  ///
  /// In en, this message translates to:
  /// **'File Operations'**
  String get helpSectionFileOperations;

  /// Help section label for troubleshooting documentation.
  ///
  /// In en, this message translates to:
  /// **'Troubleshooting'**
  String get helpSectionTroubleshooting;

  /// Help section label for project and license information.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get helpSectionAbout;

  /// Title for the regular expression page.
  ///
  /// In en, this message translates to:
  /// **'Regular Expression'**
  String get regularExpressionTitle;

  /// Form label for the primary regular expression input.
  ///
  /// In en, this message translates to:
  /// **'Regular Expression:'**
  String get regularExpressionLabel;

  /// Hint text shown in the regular expression input.
  ///
  /// In en, this message translates to:
  /// **'Enter regular expression (e.g., a*b+)'**
  String get regularExpressionHint;

  /// Button label for validating the entered regular expression.
  ///
  /// In en, this message translates to:
  /// **'Validate Regex'**
  String get validateRegex;

  /// Validation message shown when no regular expression was entered.
  ///
  /// In en, this message translates to:
  /// **'Enter a regular expression to validate.'**
  String get enterRegexToValidate;

  /// Status message shown when the regular expression is valid.
  ///
  /// In en, this message translates to:
  /// **'Valid regex'**
  String get validRegex;

  /// Status message shown when the regular expression is invalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid regex'**
  String get invalidRegex;

  /// Form label for the test string input.
  ///
  /// In en, this message translates to:
  /// **'Test String:'**
  String get testStringLabel;

  /// Hint text shown in the test string input.
  ///
  /// In en, this message translates to:
  /// **'Enter string to test'**
  String get testStringHint;

  /// Tooltip for the test string action.
  ///
  /// In en, this message translates to:
  /// **'Test String'**
  String get testStringTooltip;

  /// Result label shown when the test string matches the regular expression.
  ///
  /// In en, this message translates to:
  /// **'Matches!'**
  String get matches;

  /// Result label shown when the test string does not match the regular expression.
  ///
  /// In en, this message translates to:
  /// **'Does not match'**
  String get doesNotMatch;

  /// Section label for regular-expression-to-automaton conversion actions.
  ///
  /// In en, this message translates to:
  /// **'Convert to Automaton:'**
  String get convertToAutomaton;

  /// Button label for converting the regular expression to an NFA.
  ///
  /// In en, this message translates to:
  /// **'Convert to NFA'**
  String get convertToNfa;

  /// Button label for converting the regular expression to a DFA.
  ///
  /// In en, this message translates to:
  /// **'Convert to DFA'**
  String get convertToDfa;

  /// Switch label for simplifying converted regex output.
  ///
  /// In en, this message translates to:
  /// **'Simplify Output'**
  String get simplifyOutput;

  /// Subtitle explaining the simplify output switch.
  ///
  /// In en, this message translates to:
  /// **'Apply algebraic simplifications to converted automata'**
  String get simplifyOutputSubtitle;

  /// Section label for comparing two regular expressions.
  ///
  /// In en, this message translates to:
  /// **'Compare Regular Expressions:'**
  String get compareRegularExpressions;

  /// Hint text for the comparison regular expression input.
  ///
  /// In en, this message translates to:
  /// **'Enter second regular expression'**
  String get comparisonRegexHint;

  /// Button label for checking whether two regular expressions are equivalent.
  ///
  /// In en, this message translates to:
  /// **'Compare Equivalence'**
  String get compareEquivalence;

  /// Title for the regular expression help dialog.
  ///
  /// In en, this message translates to:
  /// **'Regex Help'**
  String get regexHelp;

  /// Help text listing common regular expression patterns and meanings.
  ///
  /// In en, this message translates to:
  /// **'Common patterns:\n• a* - zero or more a\'s\n• a+ - one or more a\'s\n• a? - zero or one a\n• a|b - a or b\n• (ab)* - zero or more ab\'s\n• [abc] - any of a, b, or c'**
  String get regexHelpPatterns;

  /// Header for a converted regular expression after simplification.
  ///
  /// In en, this message translates to:
  /// **'Converted Regex (Simplified)'**
  String get convertedRegexSimplified;

  /// Header for a converted regular expression before simplification.
  ///
  /// In en, this message translates to:
  /// **'Converted Regex (Raw)'**
  String get convertedRegexRaw;

  /// Snackbar message shown after copying a regular expression.
  ///
  /// In en, this message translates to:
  /// **'Regex copied to clipboard'**
  String get regexCopiedToClipboard;

  /// Tooltip or button label for copying text to the clipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy to clipboard'**
  String get copyToClipboard;

  /// Tooltip shown when the simplify output toggle is on.
  ///
  /// In en, this message translates to:
  /// **'Toggle off to see raw output'**
  String get toggleOffRawOutput;

  /// Tooltip shown when the simplify output toggle is off.
  ///
  /// In en, this message translates to:
  /// **'Toggle on to see simplified output'**
  String get toggleOnSimplifiedOutput;

  /// Snackbar message shown before conversion when the regex input is invalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid regular expression first'**
  String get enterValidRegexFirst;

  /// Error message shown when regex-to-NFA conversion fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to convert regex to NFA'**
  String get failedConvertRegexToNfa;

  /// Success message shown after converting a regex to an NFA.
  ///
  /// In en, this message translates to:
  /// **'Converted regex to NFA. View it in the FSA workspace.'**
  String get convertedRegexToNfa;

  /// Error message shown when NFA-to-DFA conversion fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to convert NFA to DFA'**
  String get failedConvertNfaToDfa;

  /// Success message shown after converting a regex through NFA to DFA.
  ///
  /// In en, this message translates to:
  /// **'Converted regex to DFA. Opening the DFA in the FSA workspace.'**
  String get convertedRegexToDfa;

  /// Error message shown when regex simplification fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to simplify regex'**
  String get failedSimplifyRegex;

  /// Error message shown when regex complexity analysis fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to analyze regex'**
  String get failedAnalyzeRegex;

  /// Error message shown when sample string generation fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate sample strings'**
  String get failedGenerateSampleStrings;

  /// Title for the regex simplification steps panel.
  ///
  /// In en, this message translates to:
  /// **'Simplification Steps'**
  String get simplificationSteps;

  /// Tooltip or button label for hiding simplification steps.
  ///
  /// In en, this message translates to:
  /// **'Hide steps'**
  String get hideSteps;

  /// Tooltip or button label for showing simplification steps.
  ///
  /// In en, this message translates to:
  /// **'Show steps'**
  String get showSteps;

  /// Button label for running regex simplification with step details.
  ///
  /// In en, this message translates to:
  /// **'Simplify with Steps'**
  String get simplifyWithSteps;

  /// Button label for clearing regex simplification results.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Button label for rerunning regex simplification.
  ///
  /// In en, this message translates to:
  /// **'Re-simplify'**
  String get resimplify;

  /// Label for the original regex value.
  ///
  /// In en, this message translates to:
  /// **'Original:'**
  String get originalLabel;

  /// Label suffix for the number of simplification rules applied.
  ///
  /// In en, this message translates to:
  /// **'rule(s) applied'**
  String get rulesAppliedLabel;

  /// Label for the simplified regex value.
  ///
  /// In en, this message translates to:
  /// **'Simplified:'**
  String get simplifiedLabel;

  /// Snackbar message shown after copying a simplified regex.
  ///
  /// In en, this message translates to:
  /// **'Simplified regex copied to clipboard'**
  String get simplifiedRegexCopiedToClipboard;

  /// Tooltip or button label for copying the simplified regex.
  ///
  /// In en, this message translates to:
  /// **'Copy simplified regex'**
  String get copySimplifiedRegex;

  /// Short status label indicating saved work.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// Abbreviation for a character count.
  ///
  /// In en, this message translates to:
  /// **'chars'**
  String get charactersAbbreviation;

  /// Label for the percentage reduction metric.
  ///
  /// In en, this message translates to:
  /// **'Reduction'**
  String get reduction;

  /// Label for elapsed processing time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// Label for a simplification step number.
  ///
  /// In en, this message translates to:
  /// **'Step'**
  String get stepLabel;

  /// Separator label between current and total step counts.
  ///
  /// In en, this message translates to:
  /// **'of'**
  String get ofLabel;

  /// Tooltip or button label for moving to the previous simplification step.
  ///
  /// In en, this message translates to:
  /// **'Previous Step'**
  String get previousStep;

  /// Tooltip or button label for moving to the next simplification step.
  ///
  /// In en, this message translates to:
  /// **'Next Step'**
  String get nextStep;

  /// Header for the list of all simplification steps.
  ///
  /// In en, this message translates to:
  /// **'All Steps:'**
  String get allSteps;

  /// Label for the before-and-after transformation section.
  ///
  /// In en, this message translates to:
  /// **'Transformation'**
  String get transformation;

  /// Label for the expression before a simplification step.
  ///
  /// In en, this message translates to:
  /// **'Before'**
  String get before;

  /// Label for the expression after a simplification step.
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get after;

  /// Label for the simplification rule used by a step.
  ///
  /// In en, this message translates to:
  /// **'Rule'**
  String get rule;

  /// Metric label for regular expression star height.
  ///
  /// In en, this message translates to:
  /// **'Star Height'**
  String get starHeight;

  /// Metric label for regular expression nesting depth.
  ///
  /// In en, this message translates to:
  /// **'Nesting Depth'**
  String get nestingDepth;

  /// Metric label for the number of regex operators.
  ///
  /// In en, this message translates to:
  /// **'Operators'**
  String get operators;

  /// Warning shown when saved before/after conversion snapshots cannot be deserialized.
  ///
  /// In en, this message translates to:
  /// **'Conversion comparison unavailable. Saved snapshots could not be read.'**
  String get conversionComparisonUnavailable;

  /// Label for the before-and-after automaton conversion comparison.
  ///
  /// In en, this message translates to:
  /// **'Conversion result'**
  String get conversionComparisonResult;

  /// No description provided for @simulation.
  ///
  /// In en, this message translates to:
  /// **'Simulation'**
  String get simulation;

  /// No description provided for @inputString.
  ///
  /// In en, this message translates to:
  /// **'Input String'**
  String get inputString;

  /// No description provided for @simulationInputHint.
  ///
  /// In en, this message translates to:
  /// **'Leave blank for ε; whitespace is preserved'**
  String get simulationInputHint;

  /// No description provided for @simulationInputString.
  ///
  /// In en, this message translates to:
  /// **'Simulation input string'**
  String get simulationInputString;

  /// No description provided for @simulate.
  ///
  /// In en, this message translates to:
  /// **'Simulate'**
  String get simulate;

  /// No description provided for @simulating.
  ///
  /// In en, this message translates to:
  /// **'Simulating...'**
  String get simulating;

  /// No description provided for @cancelSimulation.
  ///
  /// In en, this message translates to:
  /// **'Cancel simulation'**
  String get cancelSimulation;

  /// No description provided for @runSimulation.
  ///
  /// In en, this message translates to:
  /// **'Run simulation'**
  String get runSimulation;

  /// No description provided for @runSimulationHint.
  ///
  /// In en, this message translates to:
  /// **'Runs the machine using the currently entered input string.'**
  String get runSimulationHint;

  /// No description provided for @simulationInputSemantics.
  ///
  /// In en, this message translates to:
  /// **'Simulation input: {label}'**
  String simulationInputSemantics(String label);

  /// No description provided for @simulationEditHint.
  ///
  /// In en, this message translates to:
  /// **'{hint}. Double tap to edit.'**
  String simulationEditHint(String hint);

  /// No description provided for @simulationResult.
  ///
  /// In en, this message translates to:
  /// **'Simulation Result'**
  String get simulationResult;

  /// No description provided for @regexResult.
  ///
  /// In en, this message translates to:
  /// **'Regex Result'**
  String get regexResult;

  /// No description provided for @regularExpression.
  ///
  /// In en, this message translates to:
  /// **'Regular Expression'**
  String get regularExpression;

  /// No description provided for @stepByStepMode.
  ///
  /// In en, this message translates to:
  /// **'Step-by-Step Mode'**
  String get stepByStepMode;

  /// No description provided for @stepByStepModeSemantics.
  ///
  /// In en, this message translates to:
  /// **'Step-by-step mode'**
  String get stepByStepModeSemantics;

  /// No description provided for @stepByStepExecution.
  ///
  /// In en, this message translates to:
  /// **'Step-by-Step Execution'**
  String get stepByStepExecution;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @expand.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get expand;

  /// No description provided for @collapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get collapse;

  /// No description provided for @noStepsRecorded.
  ///
  /// In en, this message translates to:
  /// **'No steps recorded'**
  String get noStepsRecorded;

  /// No description provided for @noStepsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No steps available'**
  String get noStepsAvailable;

  /// No description provided for @noSteps.
  ///
  /// In en, this message translates to:
  /// **'No steps'**
  String get noSteps;

  /// No description provided for @timeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timeline;

  /// No description provided for @timelineScrubber.
  ///
  /// In en, this message translates to:
  /// **'Timeline scrubber'**
  String get timelineScrubber;

  /// No description provided for @timelineNavigationHint.
  ///
  /// In en, this message translates to:
  /// **'Drag to navigate through simulation steps'**
  String get timelineNavigationHint;

  /// No description provided for @stepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepOf(int current, int total);

  /// No description provided for @activeStepOf.
  ///
  /// In en, this message translates to:
  /// **'Active step {current} of {total}'**
  String activeStepOf(int current, int total);

  /// No description provided for @pdaTrace.
  ///
  /// In en, this message translates to:
  /// **'PDA Trace ({count} steps)'**
  String pdaTrace(int count);

  /// No description provided for @tmTrace.
  ///
  /// In en, this message translates to:
  /// **'TM Trace ({count} steps)'**
  String tmTrace(int count);

  /// No description provided for @traceRemaining.
  ///
  /// In en, this message translates to:
  /// **'rem'**
  String get traceRemaining;

  /// No description provided for @traceStack.
  ///
  /// In en, this message translates to:
  /// **'stack'**
  String get traceStack;

  /// No description provided for @traceTape.
  ///
  /// In en, this message translates to:
  /// **'tape'**
  String get traceTape;

  /// No description provided for @pdaStackPanelLabel.
  ///
  /// In en, this message translates to:
  /// **'Stack'**
  String get pdaStackPanelLabel;

  /// No description provided for @timeout.
  ///
  /// In en, this message translates to:
  /// **'Timeout'**
  String get timeout;

  /// No description provided for @infiniteLoop.
  ///
  /// In en, this message translates to:
  /// **'Infinite Loop'**
  String get infiniteLoop;

  /// No description provided for @steps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get steps;

  /// No description provided for @states.
  ///
  /// In en, this message translates to:
  /// **'States'**
  String get states;

  /// No description provided for @executionPath.
  ///
  /// In en, this message translates to:
  /// **'Execution Path'**
  String get executionPath;

  /// No description provided for @transitions.
  ///
  /// In en, this message translates to:
  /// **'Transitions'**
  String get transitions;

  /// No description provided for @animationSpeed.
  ///
  /// In en, this message translates to:
  /// **'Animation speed'**
  String get animationSpeed;

  /// No description provided for @selectPlaybackSpeed.
  ///
  /// In en, this message translates to:
  /// **'Select playback speed'**
  String get selectPlaybackSpeed;

  /// No description provided for @speed.
  ///
  /// In en, this message translates to:
  /// **'Speed:'**
  String get speed;

  /// No description provided for @slowSpeed.
  ///
  /// In en, this message translates to:
  /// **'Slow {speed}'**
  String slowSpeed(String speed);

  /// No description provided for @normalSpeed.
  ///
  /// In en, this message translates to:
  /// **'Normal speed'**
  String get normalSpeed;

  /// No description provided for @fastSpeed.
  ///
  /// In en, this message translates to:
  /// **'Fast {speed}'**
  String fastSpeed(String speed);

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get on;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @stepByStepToggleHint.
  ///
  /// In en, this message translates to:
  /// **'Turns manual simulation review on or off for the current result.'**
  String get stepByStepToggleHint;

  /// No description provided for @simulationStartDescription.
  ///
  /// In en, this message translates to:
  /// **'Start at {state} with input {input}.'**
  String simulationStartDescription(String state, String input);

  /// No description provided for @simulationFinalDescription.
  ///
  /// In en, this message translates to:
  /// **'Final configuration {state} – input {verdict}.'**
  String simulationFinalDescription(String state, String verdict);

  /// No description provided for @simulationReadDescription.
  ///
  /// In en, this message translates to:
  /// **'Read \"{consumed}\" from {state} → {nextState} with {remaining}.'**
  String simulationReadDescription(
      String consumed, String state, String nextState, String remaining);

  /// No description provided for @noInputRemaining.
  ///
  /// In en, this message translates to:
  /// **'no input remaining'**
  String get noInputRemaining;

  /// No description provided for @remainingQuoted.
  ///
  /// In en, this message translates to:
  /// **'remaining \"{input}\"'**
  String remainingQuoted(String input);

  /// No description provided for @consumedValue.
  ///
  /// In en, this message translates to:
  /// **'Consumed: \"{value}\"'**
  String consumedValue(String value);

  /// No description provided for @nextStateValue.
  ///
  /// In en, this message translates to:
  /// **'Next state: {state}'**
  String nextStateValue(String state);

  /// No description provided for @remainingInputValue.
  ///
  /// In en, this message translates to:
  /// **'Remaining input: {input}'**
  String remainingInputValue(String input);

  /// No description provided for @previousSimulationStep.
  ///
  /// In en, this message translates to:
  /// **'Previous simulation step'**
  String get previousSimulationStep;

  /// No description provided for @previousSimulationStepHint.
  ///
  /// In en, this message translates to:
  /// **'Moves to the prior recorded simulation step.'**
  String get previousSimulationStepHint;

  /// No description provided for @nextSimulationStep.
  ///
  /// In en, this message translates to:
  /// **'Next simulation step'**
  String get nextSimulationStep;

  /// No description provided for @nextSimulationStepHint.
  ///
  /// In en, this message translates to:
  /// **'Advances to the next recorded simulation step.'**
  String get nextSimulationStepHint;

  /// No description provided for @playSimulationSteps.
  ///
  /// In en, this message translates to:
  /// **'Play simulation steps'**
  String get playSimulationSteps;

  /// No description provided for @pauseSimulationPlayback.
  ///
  /// In en, this message translates to:
  /// **'Pause simulation playback'**
  String get pauseSimulationPlayback;

  /// No description provided for @playSimulationHint.
  ///
  /// In en, this message translates to:
  /// **'Automatically advances through the recorded simulation steps.'**
  String get playSimulationHint;

  /// No description provided for @pauseSimulationHint.
  ///
  /// In en, this message translates to:
  /// **'Pauses automatic playback of simulation steps.'**
  String get pauseSimulationHint;

  /// No description provided for @resetSimulationSteps.
  ///
  /// In en, this message translates to:
  /// **'Reset simulation steps'**
  String get resetSimulationSteps;

  /// No description provided for @resetSimulationStepsHint.
  ///
  /// In en, this message translates to:
  /// **'Returns the step-by-step view to the first recorded step.'**
  String get resetSimulationStepsHint;

  /// No description provided for @resetToFirst.
  ///
  /// In en, this message translates to:
  /// **'Reset to First'**
  String get resetToFirst;

  /// No description provided for @jumpToLast.
  ///
  /// In en, this message translates to:
  /// **'Jump to Last'**
  String get jumpToLast;

  /// No description provided for @previousStepLower.
  ///
  /// In en, this message translates to:
  /// **'Previous step'**
  String get previousStepLower;

  /// No description provided for @nextStepLower.
  ///
  /// In en, this message translates to:
  /// **'Next step'**
  String get nextStepLower;

  /// No description provided for @hiddenStepsSummary.
  ///
  /// In en, this message translates to:
  /// **'{before} before, {after} after hidden'**
  String hiddenStepsSummary(int before, int after);

  /// No description provided for @noSimulationResults.
  ///
  /// In en, this message translates to:
  /// **'No simulation results yet'**
  String get noSimulationResults;

  /// No description provided for @simulationEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Enter an input string and activate Simulate to see results'**
  String get simulationEmptyHint;

  /// No description provided for @accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @acceptedLower.
  ///
  /// In en, this message translates to:
  /// **'accepted'**
  String get acceptedLower;

  /// No description provided for @rejectedLower.
  ///
  /// In en, this message translates to:
  /// **'rejected'**
  String get rejectedLower;

  /// No description provided for @regexAlphabetLabel.
  ///
  /// In en, this message translates to:
  /// **'Alphabet / universe'**
  String get regexAlphabetLabel;

  /// No description provided for @regexAlphabetHelper.
  ///
  /// In en, this message translates to:
  /// **'Characters used by ., \\D, \\W, and \\S (spaces count).'**
  String get regexAlphabetHelper;

  /// No description provided for @regexAlphabetEmptyError.
  ///
  /// In en, this message translates to:
  /// **'Alphabet cannot be empty.'**
  String get regexAlphabetEmptyError;

  /// No description provided for @suggestedFixes.
  ///
  /// In en, this message translates to:
  /// **'Suggested fixes'**
  String get suggestedFixes;

  /// No description provided for @algorithmAction.
  ///
  /// In en, this message translates to:
  /// **'Algorithm action: {title}'**
  String algorithmAction(String title);

  /// No description provided for @algorithmUnavailableHint.
  ///
  /// In en, this message translates to:
  /// **'Unavailable. {description}'**
  String algorithmUnavailableHint(String description);

  /// No description provided for @algorithmStartHint.
  ///
  /// In en, this message translates to:
  /// **'Double tap to start. {description}'**
  String algorithmStartHint(String description);

  /// No description provided for @executing.
  ///
  /// In en, this message translates to:
  /// **'Executing'**
  String get executing;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// Transitional adapter for legacy algorithm prose localized at render time.
  ///
  /// In en, this message translates to:
  /// **'{text}'**
  String workflowLegacyText(String text);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
