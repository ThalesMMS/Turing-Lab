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

  /// No description provided for @conversionReplaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace loaded result?'**
  String get conversionReplaceTitle;

  /// No description provided for @conversionReplaceCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get conversionReplaceCancel;

  /// No description provided for @conversionReplaceConfirm.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get conversionReplaceConfirm;

  /// No description provided for @conversionReplaceAutomatonMessage.
  ///
  /// In en, this message translates to:
  /// **'An automaton is already loaded. Do you want to replace it?'**
  String get conversionReplaceAutomatonMessage;

  /// No description provided for @conversionReplaceGrammarMessage.
  ///
  /// In en, this message translates to:
  /// **'A grammar is already loaded. Do you want to replace it?'**
  String get conversionReplaceGrammarMessage;

  /// No description provided for @conversionReplacePushdownAutomatonMessage.
  ///
  /// In en, this message translates to:
  /// **'A pushdown automaton is already loaded. Do you want to replace it?'**
  String get conversionReplacePushdownAutomatonMessage;

  /// No description provided for @conversionReplaceTuringMachineMessage.
  ///
  /// In en, this message translates to:
  /// **'A Turing machine is already loaded. Do you want to replace it?'**
  String get conversionReplaceTuringMachineMessage;

  /// No description provided for @conversionReplaceRegexMessage.
  ///
  /// In en, this message translates to:
  /// **'A regex is already loaded. Do you want to replace it?'**
  String get conversionReplaceRegexMessage;

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

  /// No description provided for @canvasExpandToolbarAction.
  ///
  /// In en, this message translates to:
  /// **'Expand toolbar'**
  String get canvasExpandToolbarAction;

  /// No description provided for @canvasCollapseToolbarAction.
  ///
  /// In en, this message translates to:
  /// **'Collapse toolbar'**
  String get canvasCollapseToolbarAction;

  /// No description provided for @canvasMoreActions.
  ///
  /// In en, this message translates to:
  /// **'More canvas actions'**
  String get canvasMoreActions;

  /// No description provided for @canvasZoomLevel.
  ///
  /// In en, this message translates to:
  /// **'Zoom {percent}%'**
  String canvasZoomLevel(int percent);

  /// No description provided for @canvasSelectHint.
  ///
  /// In en, this message translates to:
  /// **'Activates selection mode for moving and editing states.'**
  String get canvasSelectHint;

  /// No description provided for @canvasAddStateHint.
  ///
  /// In en, this message translates to:
  /// **'Adds a state at the viewport centre and keeps Add State mode active.'**
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

  /// No description provided for @canvasExpandToolbarHint.
  ///
  /// In en, this message translates to:
  /// **'Shows history, viewport, clear, and help actions.'**
  String get canvasExpandToolbarHint;

  /// No description provided for @canvasCollapseToolbarHint.
  ///
  /// In en, this message translates to:
  /// **'Hides secondary canvas actions.'**
  String get canvasCollapseToolbarHint;

  /// No description provided for @canvasMoreActionsHint.
  ///
  /// In en, this message translates to:
  /// **'Opens the secondary canvas action menu.'**
  String get canvasMoreActionsHint;

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

  /// No description provided for @settingsSectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsSectionAbout;

  /// No description provided for @settingsAboutTileTitle.
  ///
  /// In en, this message translates to:
  /// **'About Turing Lab'**
  String get settingsAboutTileTitle;

  /// No description provided for @settingsAboutTileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Product overview, platforms, and credits'**
  String get settingsAboutTileSubtitle;

  /// No description provided for @aboutPageTitle.
  ///
  /// In en, this message translates to:
  /// **'About Turing Lab'**
  String get aboutPageTitle;

  /// No description provided for @aboutEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Formal languages and automata'**
  String get aboutEyebrow;

  /// No description provided for @aboutLead.
  ///
  /// In en, this message translates to:
  /// **'A Flutter-based toolkit for constructing, transforming, and simulating formal language models.'**
  String get aboutLead;

  /// No description provided for @aboutDetail.
  ///
  /// In en, this message translates to:
  /// **'It provides dedicated workspaces for finite-state automata, context-free grammars, pushdown automata, Turing machines, regular expressions, and pumping lemma exercises.'**
  String get aboutDetail;

  /// No description provided for @aboutDevelopmentStatus.
  ///
  /// In en, this message translates to:
  /// **'Development status: Apple and Android builds are currently under testing.'**
  String get aboutDevelopmentStatus;

  /// No description provided for @aboutViewSource.
  ///
  /// In en, this message translates to:
  /// **'View source'**
  String get aboutViewSource;

  /// No description provided for @aboutReadDocumentation.
  ///
  /// In en, this message translates to:
  /// **'Read documentation'**
  String get aboutReadDocumentation;

  /// No description provided for @aboutReportIssue.
  ///
  /// In en, this message translates to:
  /// **'Report an issue'**
  String get aboutReportIssue;

  /// No description provided for @aboutCapabilitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Supported models and workflows'**
  String get aboutCapabilitiesTitle;

  /// No description provided for @aboutCapabilitiesIntro.
  ///
  /// In en, this message translates to:
  /// **'The current scope is organized around six independent workspaces. File support and transformations vary by model.'**
  String get aboutCapabilitiesIntro;

  /// No description provided for @aboutCapabilityEditing.
  ///
  /// In en, this message translates to:
  /// **'Editing'**
  String get aboutCapabilityEditing;

  /// No description provided for @aboutCapabilitySimulation.
  ///
  /// In en, this message translates to:
  /// **'Simulation'**
  String get aboutCapabilitySimulation;

  /// No description provided for @aboutCapabilityTransformations.
  ///
  /// In en, this message translates to:
  /// **'Transformations'**
  String get aboutCapabilityTransformations;

  /// No description provided for @aboutCapabilityImportExport.
  ///
  /// In en, this message translates to:
  /// **'Import/export'**
  String get aboutCapabilityImportExport;

  /// No description provided for @aboutWorkspaceFsa.
  ///
  /// In en, this message translates to:
  /// **'Finite-state automata'**
  String get aboutWorkspaceFsa;

  /// No description provided for @aboutWorkspaceFsaEditing.
  ///
  /// In en, this message translates to:
  /// **'State and transition canvas'**
  String get aboutWorkspaceFsaEditing;

  /// No description provided for @aboutWorkspaceFsaSimulation.
  ///
  /// In en, this message translates to:
  /// **'Step-by-step acceptance traces'**
  String get aboutWorkspaceFsaSimulation;

  /// No description provided for @aboutWorkspaceFsaTransformations.
  ///
  /// In en, this message translates to:
  /// **'NFA/DFA/regex conversion and DFA minimisation'**
  String get aboutWorkspaceFsaTransformations;

  /// No description provided for @aboutWorkspaceFsaFiles.
  ///
  /// In en, this message translates to:
  /// **'JFLAP XML, JSON, SVG, and native PNG'**
  String get aboutWorkspaceFsaFiles;

  /// No description provided for @aboutWorkspaceGrammar.
  ///
  /// In en, this message translates to:
  /// **'Context-free grammars'**
  String get aboutWorkspaceGrammar;

  /// No description provided for @aboutWorkspaceGrammarEditing.
  ///
  /// In en, this message translates to:
  /// **'Grammar and production editor'**
  String get aboutWorkspaceGrammarEditing;

  /// No description provided for @aboutWorkspaceGrammarSimulation.
  ///
  /// In en, this message translates to:
  /// **'Parsing and validation'**
  String get aboutWorkspaceGrammarSimulation;

  /// No description provided for @aboutWorkspaceGrammarTransformations.
  ///
  /// In en, this message translates to:
  /// **'FIRST/FOLLOW analysis, LL(1) diagnostics, and CNF conversion'**
  String get aboutWorkspaceGrammarTransformations;

  /// No description provided for @aboutWorkspaceGrammarFiles.
  ///
  /// In en, this message translates to:
  /// **'JFLAP grammar and SVG'**
  String get aboutWorkspaceGrammarFiles;

  /// No description provided for @aboutWorkspacePda.
  ///
  /// In en, this message translates to:
  /// **'Pushdown automata'**
  String get aboutWorkspacePda;

  /// No description provided for @aboutWorkspacePdaEditing.
  ///
  /// In en, this message translates to:
  /// **'State and transition canvas'**
  String get aboutWorkspacePdaEditing;

  /// No description provided for @aboutWorkspacePdaSimulation.
  ///
  /// In en, this message translates to:
  /// **'Input and stack traces'**
  String get aboutWorkspacePdaSimulation;

  /// No description provided for @aboutWorkspacePdaTransformations.
  ///
  /// In en, this message translates to:
  /// **'Not applicable'**
  String get aboutWorkspacePdaTransformations;

  /// No description provided for @aboutWorkspacePdaFiles.
  ///
  /// In en, this message translates to:
  /// **'SVG export'**
  String get aboutWorkspacePdaFiles;

  /// No description provided for @aboutWorkspaceTm.
  ///
  /// In en, this message translates to:
  /// **'Turing machines'**
  String get aboutWorkspaceTm;

  /// No description provided for @aboutWorkspaceTmEditing.
  ///
  /// In en, this message translates to:
  /// **'State and transition canvas'**
  String get aboutWorkspaceTmEditing;

  /// No description provided for @aboutWorkspaceTmSimulation.
  ///
  /// In en, this message translates to:
  /// **'Tape and transition traces'**
  String get aboutWorkspaceTmSimulation;

  /// No description provided for @aboutWorkspaceTmTransformations.
  ///
  /// In en, this message translates to:
  /// **'Not applicable'**
  String get aboutWorkspaceTmTransformations;

  /// No description provided for @aboutWorkspaceTmFiles.
  ///
  /// In en, this message translates to:
  /// **'SVG export'**
  String get aboutWorkspaceTmFiles;

  /// No description provided for @aboutWorkspaceRegex.
  ///
  /// In en, this message translates to:
  /// **'Regular expressions'**
  String get aboutWorkspaceRegex;

  /// No description provided for @aboutWorkspaceRegexEditing.
  ///
  /// In en, this message translates to:
  /// **'Expression editor'**
  String get aboutWorkspaceRegexEditing;

  /// No description provided for @aboutWorkspaceRegexSimulation.
  ///
  /// In en, this message translates to:
  /// **'Match testing and comparison'**
  String get aboutWorkspaceRegexSimulation;

  /// No description provided for @aboutWorkspaceRegexTransformations.
  ///
  /// In en, this message translates to:
  /// **'Simplification and automaton conversion'**
  String get aboutWorkspaceRegexTransformations;

  /// No description provided for @aboutWorkspaceRegexFiles.
  ///
  /// In en, this message translates to:
  /// **'Not applicable'**
  String get aboutWorkspaceRegexFiles;

  /// No description provided for @aboutWorkspacePumping.
  ///
  /// In en, this message translates to:
  /// **'Pumping lemma'**
  String get aboutWorkspacePumping;

  /// No description provided for @aboutWorkspacePumpingEditing.
  ///
  /// In en, this message translates to:
  /// **'Guided case workflow'**
  String get aboutWorkspacePumpingEditing;

  /// No description provided for @aboutWorkspacePumpingSimulation.
  ///
  /// In en, this message translates to:
  /// **'Decomposition validation'**
  String get aboutWorkspacePumpingSimulation;

  /// No description provided for @aboutWorkspacePumpingTransformations.
  ///
  /// In en, this message translates to:
  /// **'Not applicable'**
  String get aboutWorkspacePumpingTransformations;

  /// No description provided for @aboutWorkspacePumpingFiles.
  ///
  /// In en, this message translates to:
  /// **'Not applicable'**
  String get aboutWorkspacePumpingFiles;

  /// No description provided for @aboutFiniteAutomataTitle.
  ///
  /// In en, this message translates to:
  /// **'Finite automata'**
  String get aboutFiniteAutomataTitle;

  /// No description provided for @aboutFiniteAutomataBody.
  ///
  /// In en, this message translates to:
  /// **'Finite-state workflows include conversion between nondeterministic and deterministic automata, regular-expression conversion, DFA minimisation, and acceptance traces.'**
  String get aboutFiniteAutomataBody;

  /// No description provided for @aboutGrammarAnalysisTitle.
  ///
  /// In en, this message translates to:
  /// **'Grammar analysis'**
  String get aboutGrammarAnalysisTitle;

  /// No description provided for @aboutGrammarAnalysisBody.
  ///
  /// In en, this message translates to:
  /// **'Grammar tooling provides parsing diagnostics, FIRST and FOLLOW sets, LL(1) conflict reporting, and a best-effort Chomsky normal form pipeline.'**
  String get aboutGrammarAnalysisBody;

  /// No description provided for @aboutExecutionTracesTitle.
  ///
  /// In en, this message translates to:
  /// **'Execution traces'**
  String get aboutExecutionTracesTitle;

  /// No description provided for @aboutExecutionTracesBody.
  ///
  /// In en, this message translates to:
  /// **'FSA, PDA, and TM simulations expose intermediate configurations through state, transition, stack, or tape traces appropriate to each model.'**
  String get aboutExecutionTracesBody;

  /// No description provided for @aboutFormatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Local execution and bounded file compatibility'**
  String get aboutFormatsTitle;

  /// No description provided for @aboutFormatsIntro.
  ///
  /// In en, this message translates to:
  /// **'Turing Lab does not require an account or a developer-operated backend. Editing, simulation, diagnostics, and bundled examples run locally.'**
  String get aboutFormatsIntro;

  /// No description provided for @aboutFormatFsa.
  ///
  /// In en, this message translates to:
  /// **'FSA: JFLAP XML and JSON import/export, SVG export, and PNG export on native platforms.'**
  String get aboutFormatFsa;

  /// No description provided for @aboutFormatGrammar.
  ///
  /// In en, this message translates to:
  /// **'Grammar: JFLAP grammar import/export and SVG export.'**
  String get aboutFormatGrammar;

  /// No description provided for @aboutFormatPdaTm.
  ///
  /// In en, this message translates to:
  /// **'PDA and TM: SVG export. JFLAP XML and JSON round trips are outside the current release scope.'**
  String get aboutFormatPdaTm;

  /// No description provided for @aboutFormatWebLimitation.
  ///
  /// In en, this message translates to:
  /// **'Web limitation: PNG export is unavailable in web builds.'**
  String get aboutFormatWebLimitation;

  /// No description provided for @aboutPlatformsTitle.
  ///
  /// In en, this message translates to:
  /// **'Current validation status'**
  String get aboutPlatformsTitle;

  /// No description provided for @aboutPlatformsIntro.
  ///
  /// In en, this message translates to:
  /// **'Testing builds are undergoing platform validation and release preparation. Experimental targets may have incomplete platform integration and are not part of the current release scope.'**
  String get aboutPlatformsIntro;

  /// No description provided for @aboutStatusTesting.
  ///
  /// In en, this message translates to:
  /// **'Testing'**
  String get aboutStatusTesting;

  /// No description provided for @aboutStatusExperimental.
  ///
  /// In en, this message translates to:
  /// **'Experimental'**
  String get aboutStatusExperimental;

  /// No description provided for @aboutPlatformIos.
  ///
  /// In en, this message translates to:
  /// **'iOS and iPadOS'**
  String get aboutPlatformIos;

  /// No description provided for @aboutPlatformMacos.
  ///
  /// In en, this message translates to:
  /// **'macOS'**
  String get aboutPlatformMacos;

  /// No description provided for @aboutPlatformAndroid.
  ///
  /// In en, this message translates to:
  /// **'Android'**
  String get aboutPlatformAndroid;

  /// No description provided for @aboutPlatformWeb.
  ///
  /// In en, this message translates to:
  /// **'Web'**
  String get aboutPlatformWeb;

  /// No description provided for @aboutPlatformWindows.
  ///
  /// In en, this message translates to:
  /// **'Windows'**
  String get aboutPlatformWindows;

  /// No description provided for @aboutPlatformLinux.
  ///
  /// In en, this message translates to:
  /// **'Linux'**
  String get aboutPlatformLinux;

  /// No description provided for @aboutScreenshotsTitle.
  ///
  /// In en, this message translates to:
  /// **'Application workspaces'**
  String get aboutScreenshotsTitle;

  /// No description provided for @aboutScreenshotsIntro.
  ///
  /// In en, this message translates to:
  /// **'Captured from controlled mobile and tablet testing configurations.'**
  String get aboutScreenshotsIntro;

  /// No description provided for @aboutScreenshotFsa.
  ///
  /// In en, this message translates to:
  /// **'Finite-state automata. Automaton canvas, simulation result, and step-by-step trace.'**
  String get aboutScreenshotFsa;

  /// No description provided for @aboutScreenshotGrammar.
  ///
  /// In en, this message translates to:
  /// **'Context-free grammars. Production editing and grammar transformations.'**
  String get aboutScreenshotGrammar;

  /// No description provided for @aboutScreenshotTm.
  ///
  /// In en, this message translates to:
  /// **'Turing machines. Tape simulation, transition editing, and machine-specific analysis.'**
  String get aboutScreenshotTm;

  /// No description provided for @aboutAttribution.
  ///
  /// In en, this message translates to:
  /// **'Turing Lab is inspired by the original JFLAP project. Turing Lab is not affiliated with, endorsed by, or an official release of JFLAP, Duke University, or Susan H. Rodger.'**
  String get aboutAttribution;

  /// No description provided for @aboutOpenLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get aboutOpenLicenses;

  /// No description provided for @aboutOpenPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get aboutOpenPrivacy;

  /// No description provided for @aboutOpenSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get aboutOpenSupport;

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

  /// No description provided for @viewOnCanvas.
  ///
  /// In en, this message translates to:
  /// **'View on Canvas'**
  String get viewOnCanvas;

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

  /// No description provided for @pdaNormalizationReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review PDA normalization'**
  String get pdaNormalizationReviewTitle;

  /// No description provided for @pdaNormalizationSourceAcceptance.
  ///
  /// In en, this message translates to:
  /// **'Source acceptance: {mode}'**
  String pdaNormalizationSourceAcceptance(String mode);

  /// No description provided for @pdaNormalizationTargetAcceptance.
  ///
  /// In en, this message translates to:
  /// **'Target acceptance: {mode}'**
  String pdaNormalizationTargetAcceptance(String mode);

  /// No description provided for @pdaNormalizationStateCount.
  ///
  /// In en, this message translates to:
  /// **'States: {before} → {after}'**
  String pdaNormalizationStateCount(int before, int after);

  /// No description provided for @pdaNormalizationTransitionCount.
  ///
  /// In en, this message translates to:
  /// **'Transitions: {before} → {after}'**
  String pdaNormalizationTransitionCount(int before, int after);

  /// No description provided for @pdaNormalizationNewStackSymbol.
  ///
  /// In en, this message translates to:
  /// **'New stack symbol: {symbol}'**
  String pdaNormalizationNewStackSymbol(String symbol);

  /// No description provided for @pdaNormalizationGrowthWarning.
  ///
  /// In en, this message translates to:
  /// **'Normalization may increase the state and transition count. Acceptance conversion may also introduce non-determinism.'**
  String get pdaNormalizationGrowthWarning;

  /// No description provided for @pdaNormalizationCancelHint.
  ///
  /// In en, this message translates to:
  /// **'Review the counts before applying. Cancel leaves the editor unchanged.'**
  String get pdaNormalizationCancelHint;

  /// No description provided for @pdaNormalizationCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get pdaNormalizationCancel;

  /// No description provided for @pdaNormalizationApplyAndConvert.
  ///
  /// In en, this message translates to:
  /// **'Apply and convert'**
  String get pdaNormalizationApplyAndConvert;

  /// No description provided for @pdaSimplificationButtonTitle.
  ///
  /// In en, this message translates to:
  /// **'Simplify PDA'**
  String get pdaSimplificationButtonTitle;

  /// No description provided for @pdaSimplificationButtonDescription.
  ///
  /// In en, this message translates to:
  /// **'Safely remove unreachable or strongly bisimilar control states'**
  String get pdaSimplificationButtonDescription;

  /// No description provided for @pdaSimplificationAnalysisTitle.
  ///
  /// In en, this message translates to:
  /// **'PDA Simplification'**
  String get pdaSimplificationAnalysisTitle;

  /// No description provided for @pdaSimplificationMissingPda.
  ///
  /// In en, this message translates to:
  /// **'Create a PDA before simplifying it.'**
  String get pdaSimplificationMissingPda;

  /// No description provided for @pdaSimplificationReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review PDA simplification'**
  String get pdaSimplificationReviewTitle;

  /// No description provided for @pdaSimplificationActiveAcceptance.
  ///
  /// In en, this message translates to:
  /// **'Active acceptance: {mode}'**
  String pdaSimplificationActiveAcceptance(String mode);

  /// No description provided for @pdaSimplificationScope.
  ///
  /// In en, this message translates to:
  /// **'This is a conservative structural reduction, not a globally minimal NPDA.'**
  String get pdaSimplificationScope;

  /// No description provided for @pdaSimplificationSkippedSemantic.
  ///
  /// In en, this message translates to:
  /// **'Exact semantic usefulness is not available for general NPDAs, so uncertain states were retained.'**
  String get pdaSimplificationSkippedSemantic;

  /// No description provided for @pdaSimplificationChangesHeading.
  ///
  /// In en, this message translates to:
  /// **'Proposed changes'**
  String get pdaSimplificationChangesHeading;

  /// No description provided for @pdaSimplificationUnreachableChange.
  ///
  /// In en, this message translates to:
  /// **'Unreachable states removed: {count}'**
  String pdaSimplificationUnreachableChange(int count);

  /// No description provided for @pdaSimplificationMergeChange.
  ///
  /// In en, this message translates to:
  /// **'Strong-bisimulation merge groups: {count}'**
  String pdaSimplificationMergeChange(int count);

  /// No description provided for @pdaSimplificationDuplicateChange.
  ///
  /// In en, this message translates to:
  /// **'Redundant transitions removed: {count}'**
  String pdaSimplificationDuplicateChange(int count);

  /// No description provided for @pdaSimplificationCancelHint.
  ///
  /// In en, this message translates to:
  /// **'Review before applying. Cancel leaves the editor unchanged.'**
  String get pdaSimplificationCancelHint;

  /// No description provided for @pdaSimplificationCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get pdaSimplificationCancel;

  /// No description provided for @pdaSimplificationApply.
  ///
  /// In en, this message translates to:
  /// **'Apply simplification'**
  String get pdaSimplificationApply;

  /// No description provided for @pdaSimplificationNoChange.
  ///
  /// In en, this message translates to:
  /// **'No supported simplification was found. The PDA was copied without structural changes.'**
  String get pdaSimplificationNoChange;

  /// No description provided for @pdaSimplificationCanceled.
  ///
  /// In en, this message translates to:
  /// **'Simplification canceled. The editor PDA was not changed.'**
  String get pdaSimplificationCanceled;

  /// No description provided for @pdaSimplificationApplied.
  ///
  /// In en, this message translates to:
  /// **'PDA simplification applied.'**
  String get pdaSimplificationApplied;

  /// No description provided for @pdaSimplificationEditorChanged.
  ///
  /// In en, this message translates to:
  /// **'Simplification canceled because the editor PDA changed during review.'**
  String get pdaSimplificationEditorChanged;

  /// No description provided for @pdaSimplificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Simplification failed: {error}'**
  String pdaSimplificationFailed(String error);

  /// No description provided for @pdaAcceptanceFinalState.
  ///
  /// In en, this message translates to:
  /// **'final state'**
  String get pdaAcceptanceFinalState;

  /// No description provided for @pdaAcceptanceEmptyStack.
  ///
  /// In en, this message translates to:
  /// **'empty stack'**
  String get pdaAcceptanceEmptyStack;

  /// No description provided for @pdaAcceptanceBoth.
  ///
  /// In en, this message translates to:
  /// **'final state and empty stack'**
  String get pdaAcceptanceBoth;

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

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @retrying.
  ///
  /// In en, this message translates to:
  /// **'Retrying...'**
  String get retrying;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @dismissMessage.
  ///
  /// In en, this message translates to:
  /// **'Dismiss message'**
  String get dismissMessage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @doubleTapToRetry.
  ///
  /// In en, this message translates to:
  /// **'Double tap to retry'**
  String get doubleTapToRetry;

  /// No description provided for @successBannerSemantics.
  ///
  /// In en, this message translates to:
  /// **'Success banner'**
  String get successBannerSemantics;

  /// No description provided for @errorBannerSemantics.
  ///
  /// In en, this message translates to:
  /// **'Error banner'**
  String get errorBannerSemantics;

  /// No description provided for @warningBannerSemantics.
  ///
  /// In en, this message translates to:
  /// **'Warning banner'**
  String get warningBannerSemantics;

  /// No description provided for @infoBannerSemantics.
  ///
  /// In en, this message translates to:
  /// **'Info banner'**
  String get infoBannerSemantics;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @fileOperationsTitle.
  ///
  /// In en, this message translates to:
  /// **'File Operations'**
  String get fileOperationsTitle;

  /// No description provided for @fileSectionFsa.
  ///
  /// In en, this message translates to:
  /// **'FSA'**
  String get fileSectionFsa;

  /// No description provided for @fileSectionGrammar.
  ///
  /// In en, this message translates to:
  /// **'Grammar'**
  String get fileSectionGrammar;

  /// No description provided for @fileSectionPda.
  ///
  /// In en, this message translates to:
  /// **'PDA'**
  String get fileSectionPda;

  /// No description provided for @fileSectionTm.
  ///
  /// In en, this message translates to:
  /// **'Turing Machine'**
  String get fileSectionTm;

  /// No description provided for @saveAsJflap.
  ///
  /// In en, this message translates to:
  /// **'Save as JFLAP'**
  String get saveAsJflap;

  /// No description provided for @downloadJflap.
  ///
  /// In en, this message translates to:
  /// **'Download JFLAP'**
  String get downloadJflap;

  /// No description provided for @loadJflap.
  ///
  /// In en, this message translates to:
  /// **'Load JFLAP'**
  String get loadJflap;

  /// No description provided for @saveAsJson.
  ///
  /// In en, this message translates to:
  /// **'Save as JSON'**
  String get saveAsJson;

  /// No description provided for @downloadJson.
  ///
  /// In en, this message translates to:
  /// **'Download JSON'**
  String get downloadJson;

  /// No description provided for @loadJson.
  ///
  /// In en, this message translates to:
  /// **'Load JSON'**
  String get loadJson;

  /// No description provided for @exportSvg.
  ///
  /// In en, this message translates to:
  /// **'Export SVG'**
  String get exportSvg;

  /// No description provided for @downloadSvg.
  ///
  /// In en, this message translates to:
  /// **'Download SVG'**
  String get downloadSvg;

  /// No description provided for @exportPng.
  ///
  /// In en, this message translates to:
  /// **'Export PNG'**
  String get exportPng;

  /// No description provided for @jsonUnreadableFileMessage.
  ///
  /// In en, this message translates to:
  /// **'Turing Lab could not access the selected JSON file data. Pick the file again and keep it available until the import finishes.'**
  String get jsonUnreadableFileMessage;

  /// No description provided for @saveAutomatonAsJflap.
  ///
  /// In en, this message translates to:
  /// **'Save Automaton as JFLAP'**
  String get saveAutomatonAsJflap;

  /// No description provided for @saveAutomatonAsJson.
  ///
  /// In en, this message translates to:
  /// **'Save Automaton as JSON'**
  String get saveAutomatonAsJson;

  /// No description provided for @loadJflapAutomaton.
  ///
  /// In en, this message translates to:
  /// **'Load JFLAP Automaton'**
  String get loadJflapAutomaton;

  /// No description provided for @loadAutomatonJson.
  ///
  /// In en, this message translates to:
  /// **'Load Automaton JSON'**
  String get loadAutomatonJson;

  /// No description provided for @exportAutomatonAsSvg.
  ///
  /// In en, this message translates to:
  /// **'Export Automaton as SVG'**
  String get exportAutomatonAsSvg;

  /// No description provided for @exportAutomatonAsPng.
  ///
  /// In en, this message translates to:
  /// **'Export Automaton as PNG'**
  String get exportAutomatonAsPng;

  /// No description provided for @saveGrammarAsJflap.
  ///
  /// In en, this message translates to:
  /// **'Save Grammar as JFLAP'**
  String get saveGrammarAsJflap;

  /// No description provided for @loadJflapGrammar.
  ///
  /// In en, this message translates to:
  /// **'Load JFLAP Grammar'**
  String get loadJflapGrammar;

  /// No description provided for @exportGrammarAsSvg.
  ///
  /// In en, this message translates to:
  /// **'Export Grammar as SVG'**
  String get exportGrammarAsSvg;

  /// No description provided for @exportPdaAsSvg.
  ///
  /// In en, this message translates to:
  /// **'Export PDA as SVG'**
  String get exportPdaAsSvg;

  /// No description provided for @exportTmAsSvg.
  ///
  /// In en, this message translates to:
  /// **'Export Turing Machine as SVG'**
  String get exportTmAsSvg;

  /// No description provided for @automatonSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Automaton saved successfully'**
  String get automatonSavedSuccessfully;

  /// No description provided for @automatonLoadedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Automaton loaded successfully'**
  String get automatonLoadedSuccessfully;

  /// No description provided for @automatonExportedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Automaton exported successfully'**
  String get automatonExportedSuccessfully;

  /// No description provided for @grammarSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Grammar saved successfully'**
  String get grammarSavedSuccessfully;

  /// No description provided for @grammarLoadedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Grammar loaded successfully'**
  String get grammarLoadedSuccessfully;

  /// No description provided for @grammarExportedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Grammar exported successfully'**
  String get grammarExportedSuccessfully;

  /// No description provided for @pdaExportedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'PDA exported successfully'**
  String get pdaExportedSuccessfully;

  /// No description provided for @tmExportedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Turing machine exported successfully'**
  String get tmExportedSuccessfully;

  /// No description provided for @saveCanceled.
  ///
  /// In en, this message translates to:
  /// **'Save canceled.'**
  String get saveCanceled;

  /// No description provided for @exportCanceled.
  ///
  /// In en, this message translates to:
  /// **'Export canceled.'**
  String get exportCanceled;

  /// No description provided for @importCanceled.
  ///
  /// In en, this message translates to:
  /// **'Import canceled.'**
  String get importCanceled;

  /// No description provided for @downloadStartedFor.
  ///
  /// In en, this message translates to:
  /// **'Download started for {fileName}'**
  String downloadStartedFor(String fileName);

  /// No description provided for @failedToSaveAutomaton.
  ///
  /// In en, this message translates to:
  /// **'Failed to save automaton: {error}'**
  String failedToSaveAutomaton(String error);

  /// No description provided for @errorSavingAutomaton.
  ///
  /// In en, this message translates to:
  /// **'Error saving automaton: {error}'**
  String errorSavingAutomaton(String error);

  /// No description provided for @errorLoadingAutomaton.
  ///
  /// In en, this message translates to:
  /// **'Error loading automaton: {error}'**
  String errorLoadingAutomaton(String error);

  /// No description provided for @failedToExportAutomaton.
  ///
  /// In en, this message translates to:
  /// **'Failed to export automaton: {error}'**
  String failedToExportAutomaton(String error);

  /// No description provided for @errorExportingAutomaton.
  ///
  /// In en, this message translates to:
  /// **'Error exporting automaton: {error}'**
  String errorExportingAutomaton(String error);

  /// No description provided for @failedToSaveAutomatonJson.
  ///
  /// In en, this message translates to:
  /// **'Failed to save automaton JSON: {error}'**
  String failedToSaveAutomatonJson(String error);

  /// No description provided for @errorSavingAutomatonJson.
  ///
  /// In en, this message translates to:
  /// **'Error saving automaton JSON: {error}'**
  String errorSavingAutomatonJson(String error);

  /// No description provided for @errorLoadingAutomatonJson.
  ///
  /// In en, this message translates to:
  /// **'Error loading automaton JSON: {error}'**
  String errorLoadingAutomatonJson(String error);

  /// No description provided for @failedToExportAutomatonPng.
  ///
  /// In en, this message translates to:
  /// **'Failed to export automaton PNG: {error}'**
  String failedToExportAutomatonPng(String error);

  /// No description provided for @errorExportingAutomatonPng.
  ///
  /// In en, this message translates to:
  /// **'Error exporting automaton PNG: {error}'**
  String errorExportingAutomatonPng(String error);

  /// No description provided for @failedToSaveGrammar.
  ///
  /// In en, this message translates to:
  /// **'Failed to save grammar: {error}'**
  String failedToSaveGrammar(String error);

  /// No description provided for @errorSavingGrammar.
  ///
  /// In en, this message translates to:
  /// **'Error saving grammar: {error}'**
  String errorSavingGrammar(String error);

  /// No description provided for @errorLoadingGrammar.
  ///
  /// In en, this message translates to:
  /// **'Error loading grammar: {error}'**
  String errorLoadingGrammar(String error);

  /// No description provided for @failedToExportGrammar.
  ///
  /// In en, this message translates to:
  /// **'Failed to export grammar: {error}'**
  String failedToExportGrammar(String error);

  /// No description provided for @errorExportingGrammar.
  ///
  /// In en, this message translates to:
  /// **'Error exporting grammar: {error}'**
  String errorExportingGrammar(String error);

  /// No description provided for @failedToExportPda.
  ///
  /// In en, this message translates to:
  /// **'Failed to export PDA: {error}'**
  String failedToExportPda(String error);

  /// No description provided for @errorExportingPda.
  ///
  /// In en, this message translates to:
  /// **'Error exporting PDA: {error}'**
  String errorExportingPda(String error);

  /// No description provided for @failedToExportTm.
  ///
  /// In en, this message translates to:
  /// **'Failed to export Turing machine: {error}'**
  String failedToExportTm(String error);

  /// No description provided for @errorExportingTm.
  ///
  /// In en, this message translates to:
  /// **'Error exporting Turing machine: {error}'**
  String errorExportingTm(String error);

  /// No description provided for @importErrorDialogSemantics.
  ///
  /// In en, this message translates to:
  /// **'Import error dialog'**
  String get importErrorDialogSemantics;

  /// No description provided for @cancelImport.
  ///
  /// In en, this message translates to:
  /// **'Cancel import'**
  String get cancelImport;

  /// No description provided for @importErrorMalformedJff.
  ///
  /// In en, this message translates to:
  /// **'Malformed JFLAP File'**
  String get importErrorMalformedJff;

  /// No description provided for @importErrorInvalidJson.
  ///
  /// In en, this message translates to:
  /// **'Invalid JSON Structure'**
  String get importErrorInvalidJson;

  /// No description provided for @importErrorUnsupportedVersion.
  ///
  /// In en, this message translates to:
  /// **'Unsupported File Version'**
  String get importErrorUnsupportedVersion;

  /// No description provided for @importErrorInaccessibleFile.
  ///
  /// In en, this message translates to:
  /// **'File Access Unavailable'**
  String get importErrorInaccessibleFile;

  /// No description provided for @importErrorCorruptedData.
  ///
  /// In en, this message translates to:
  /// **'Corrupted Data Detected'**
  String get importErrorCorruptedData;

  /// No description provided for @importErrorInvalidAutomaton.
  ///
  /// In en, this message translates to:
  /// **'Invalid Automaton Definition'**
  String get importErrorInvalidAutomaton;

  /// No description provided for @importFriendlyMalformedJff.
  ///
  /// In en, this message translates to:
  /// **'The selected JFLAP file could not be parsed. Please verify the file integrity and try again.'**
  String get importFriendlyMalformedJff;

  /// No description provided for @importFriendlyInvalidJson.
  ///
  /// In en, this message translates to:
  /// **'The import contains JSON sections that are invalid. Fix the JSON structure and retry.'**
  String get importFriendlyInvalidJson;

  /// No description provided for @importFriendlyUnsupportedVersion.
  ///
  /// In en, this message translates to:
  /// **'This file targets a newer JFLAP schema version. Export it again using a compatible version and retry.'**
  String get importFriendlyUnsupportedVersion;

  /// No description provided for @importFriendlyInaccessibleFile.
  ///
  /// In en, this message translates to:
  /// **'Turing Lab could not access the selected file. Pick it again from the system dialog and keep it available until the import finishes.'**
  String get importFriendlyInaccessibleFile;

  /// No description provided for @importFriendlyCorruptedData.
  ///
  /// In en, this message translates to:
  /// **'The file appears to be corrupted or unreadable. Restore a valid backup before importing again.'**
  String get importFriendlyCorruptedData;

  /// No description provided for @importFriendlyInvalidAutomaton.
  ///
  /// In en, this message translates to:
  /// **'The automaton definition is inconsistent. Review the transitions and states before retrying the import.'**
  String get importFriendlyInvalidAutomaton;

  /// No description provided for @hideTechnicalDetails.
  ///
  /// In en, this message translates to:
  /// **'Hide technical details'**
  String get hideTechnicalDetails;

  /// No description provided for @viewTechnicalDetails.
  ///
  /// In en, this message translates to:
  /// **'View technical details'**
  String get viewTechnicalDetails;

  /// No description provided for @svgNoStatesDefined.
  ///
  /// In en, this message translates to:
  /// **'No states defined'**
  String get svgNoStatesDefined;

  /// No description provided for @svgTmLegend.
  ///
  /// In en, this message translates to:
  /// **'δ(q, s) = (q′, w, d) — read/write/move'**
  String get svgTmLegend;

  /// No description provided for @loadAutomatonBeforeOperation.
  ///
  /// In en, this message translates to:
  /// **'Load an automaton before running this operation.'**
  String get loadAutomatonBeforeOperation;

  /// No description provided for @operationRequiresDeterministicNoEpsilon.
  ///
  /// In en, this message translates to:
  /// **'This operation requires a deterministic automaton without ε-transitions.'**
  String get operationRequiresDeterministicNoEpsilon;

  /// No description provided for @automatonHasNoLambdaTransitions.
  ///
  /// In en, this message translates to:
  /// **'The current automaton does not contain λ-transitions.'**
  String get automatonHasNoLambdaTransitions;

  /// No description provided for @automatonMustContainLambdaToRemove.
  ///
  /// In en, this message translates to:
  /// **'The current automaton must contain λ-transitions to remove them.'**
  String get automatonMustContainLambdaToRemove;

  /// No description provided for @lambdaTransitionsRemoved.
  ///
  /// In en, this message translates to:
  /// **'λ-transitions removed successfully.'**
  String get lambdaTransitionsRemoved;

  /// No description provided for @complementComputed.
  ///
  /// In en, this message translates to:
  /// **'Complement computed successfully.'**
  String get complementComputed;

  /// No description provided for @complementRequiresDeterministic.
  ///
  /// In en, this message translates to:
  /// **'Complement is only available for deterministic automata without ε-transitions.'**
  String get complementRequiresDeterministic;

  /// No description provided for @prefixClosureComputed.
  ///
  /// In en, this message translates to:
  /// **'Prefix closure computed successfully.'**
  String get prefixClosureComputed;

  /// No description provided for @prefixClosureRequiresDeterministic.
  ///
  /// In en, this message translates to:
  /// **'Prefix closure is only available for deterministic automata without ε-transitions.'**
  String get prefixClosureRequiresDeterministic;

  /// No description provided for @suffixClosureComputed.
  ///
  /// In en, this message translates to:
  /// **'Suffix closure computed successfully.'**
  String get suffixClosureComputed;

  /// No description provided for @suffixClosureRequiresDeterministic.
  ///
  /// In en, this message translates to:
  /// **'Suffix closure is only available for deterministic automata without ε-transitions.'**
  String get suffixClosureRequiresDeterministic;

  /// No description provided for @unionComputed.
  ///
  /// In en, this message translates to:
  /// **'Union computed successfully.'**
  String get unionComputed;

  /// No description provided for @binaryDfaRequiresDeterministic.
  ///
  /// In en, this message translates to:
  /// **'Binary DFA operations require a deterministic automaton without ε-transitions.'**
  String get binaryDfaRequiresDeterministic;

  /// No description provided for @concatenationComputed.
  ///
  /// In en, this message translates to:
  /// **'Concatenation computed successfully.'**
  String get concatenationComputed;

  /// No description provided for @loadFsaBeforeConcatenation.
  ///
  /// In en, this message translates to:
  /// **'Load an FSA before computing the concatenation.'**
  String get loadFsaBeforeConcatenation;

  /// No description provided for @kleeneStarComputed.
  ///
  /// In en, this message translates to:
  /// **'Kleene star computed successfully.'**
  String get kleeneStarComputed;

  /// No description provided for @loadFsaBeforeKleeneStar.
  ///
  /// In en, this message translates to:
  /// **'Load an FSA before applying Kleene star.'**
  String get loadFsaBeforeKleeneStar;

  /// No description provided for @fsaLanguageReversed.
  ///
  /// In en, this message translates to:
  /// **'FSA language reversed successfully.'**
  String get fsaLanguageReversed;

  /// No description provided for @loadFsaBeforeReverse.
  ///
  /// In en, this message translates to:
  /// **'Load an FSA before reversing its language.'**
  String get loadFsaBeforeReverse;

  /// No description provided for @intersectionComputed.
  ///
  /// In en, this message translates to:
  /// **'Intersection computed successfully.'**
  String get intersectionComputed;

  /// No description provided for @differenceComputed.
  ///
  /// In en, this message translates to:
  /// **'Difference computed successfully.'**
  String get differenceComputed;

  /// No description provided for @convertedToRegexWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Automaton converted to regex. Switched to Regex workspace.'**
  String get convertedToRegexWorkspace;

  /// No description provided for @convertedToGrammarWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Automaton converted to grammar. Switched to Grammar workspace.'**
  String get convertedToGrammarWorkspace;

  /// No description provided for @grammarEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Grammar Editor'**
  String get grammarEditorTitle;

  /// No description provided for @defaultGrammarName.
  ///
  /// In en, this message translates to:
  /// **'My Grammar'**
  String get defaultGrammarName;

  /// No description provided for @grammarInformation.
  ///
  /// In en, this message translates to:
  /// **'Grammar Information'**
  String get grammarInformation;

  /// No description provided for @grammarNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Grammar Name'**
  String get grammarNameLabel;

  /// No description provided for @startSymbolLabel.
  ///
  /// In en, this message translates to:
  /// **'Start Symbol'**
  String get startSymbolLabel;

  /// No description provided for @editProductionRule.
  ///
  /// In en, this message translates to:
  /// **'Edit Production Rule'**
  String get editProductionRule;

  /// No description provided for @addProductionRule.
  ///
  /// In en, this message translates to:
  /// **'Add Production Rule'**
  String get addProductionRule;

  /// No description provided for @leftSideVariable.
  ///
  /// In en, this message translates to:
  /// **'Left Side (Variable)'**
  String get leftSideVariable;

  /// No description provided for @rightSideProduction.
  ///
  /// In en, this message translates to:
  /// **'Right Side (Production)'**
  String get rightSideProduction;

  /// No description provided for @leftSideHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., S, A, B'**
  String get leftSideHint;

  /// No description provided for @rightSideHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., aA, bB, ε'**
  String get rightSideHint;

  /// No description provided for @leftSideHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter exactly one non-terminal symbol.'**
  String get leftSideHelper;

  /// No description provided for @rightSideHelper.
  ///
  /// In en, this message translates to:
  /// **'Use λ/ε for the empty string.'**
  String get rightSideHelper;

  /// No description provided for @insertLambda.
  ///
  /// In en, this message translates to:
  /// **'Insert λ'**
  String get insertLambda;

  /// No description provided for @insertEpsilon.
  ///
  /// In en, this message translates to:
  /// **'Insert ε'**
  String get insertEpsilon;

  /// No description provided for @noProductionRulesYet.
  ///
  /// In en, this message translates to:
  /// **'No production rules yet'**
  String get noProductionRulesYet;

  /// No description provided for @addFirstProductionRule.
  ///
  /// In en, this message translates to:
  /// **'Add your first production rule above'**
  String get addFirstProductionRule;

  /// No description provided for @clearAllProductionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear all productions?'**
  String get clearAllProductionsTitle;

  /// No description provided for @clearAllProductionsMessage.
  ///
  /// In en, this message translates to:
  /// **'This will remove every production rule from the current grammar.'**
  String get clearAllProductionsMessage;

  /// No description provided for @productionsCleared.
  ///
  /// In en, this message translates to:
  /// **'Productions cleared.'**
  String get productionsCleared;

  /// No description provided for @bothSidesRequired.
  ///
  /// In en, this message translates to:
  /// **'Both left side and right side must be specified'**
  String get bothSidesRequired;

  /// No description provided for @leftSideMustBeNonterminal.
  ///
  /// In en, this message translates to:
  /// **'Left side must contain a non-terminal symbol'**
  String get leftSideMustBeNonterminal;

  /// No description provided for @leftSideExactlyOneNonterminal.
  ///
  /// In en, this message translates to:
  /// **'Left side must contain exactly one non-terminal symbol'**
  String get leftSideExactlyOneNonterminal;

  /// No description provided for @rightSideAtLeastOneSymbol.
  ///
  /// In en, this message translates to:
  /// **'Right side must contain at least one symbol (or λ/ε)'**
  String get rightSideAtLeastOneSymbol;

  /// No description provided for @rightSideSingleLambda.
  ///
  /// In en, this message translates to:
  /// **'Right side can contain only one λ/ε symbol'**
  String get rightSideSingleLambda;

  /// No description provided for @lambdaMustBeOnlySymbol.
  ///
  /// In en, this message translates to:
  /// **'λ/ε must be the only symbol on the right side'**
  String get lambdaMustBeOnlySymbol;

  /// No description provided for @sampleStringsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sample Strings'**
  String get sampleStringsTitle;

  /// No description provided for @hideSamples.
  ///
  /// In en, this message translates to:
  /// **'Hide samples'**
  String get hideSamples;

  /// No description provided for @showSamples.
  ///
  /// In en, this message translates to:
  /// **'Show samples'**
  String get showSamples;

  /// No description provided for @generateSampleStrings.
  ///
  /// In en, this message translates to:
  /// **'Generate Sample Strings'**
  String get generateSampleStrings;

  /// No description provided for @generateMore.
  ///
  /// In en, this message translates to:
  /// **'Generate More'**
  String get generateMore;

  /// No description provided for @noSampleStringsGenerated.
  ///
  /// In en, this message translates to:
  /// **'No sample strings generated'**
  String get noSampleStringsGenerated;

  /// No description provided for @generatedSamples.
  ///
  /// In en, this message translates to:
  /// **'Generated Samples:'**
  String get generatedSamples;

  /// No description provided for @copyAll.
  ///
  /// In en, this message translates to:
  /// **'Copy All'**
  String get copyAll;

  /// No description provided for @allSamplesCopied.
  ///
  /// In en, this message translates to:
  /// **'All samples copied to clipboard'**
  String get allSamplesCopied;

  /// No description provided for @failedToCopyClipboard.
  ///
  /// In en, this message translates to:
  /// **'Failed to copy to clipboard.'**
  String get failedToCopyClipboard;

  /// No description provided for @complexityAnalysisTitle.
  ///
  /// In en, this message translates to:
  /// **'Complexity Analysis'**
  String get complexityAnalysisTitle;

  /// No description provided for @hideDetails.
  ///
  /// In en, this message translates to:
  /// **'Hide details'**
  String get hideDetails;

  /// No description provided for @showDetails.
  ///
  /// In en, this message translates to:
  /// **'Show details'**
  String get showDetails;

  /// No description provided for @analyzeComplexity.
  ///
  /// In en, this message translates to:
  /// **'Analyze Complexity'**
  String get analyzeComplexity;

  /// No description provided for @reanalyze.
  ///
  /// In en, this message translates to:
  /// **'Re-analyze'**
  String get reanalyze;

  /// No description provided for @noOperatorsUsed.
  ///
  /// In en, this message translates to:
  /// **'No operators used (literal expression)'**
  String get noOperatorsUsed;

  /// No description provided for @operatorUnion.
  ///
  /// In en, this message translates to:
  /// **'Union (|)'**
  String get operatorUnion;

  /// No description provided for @operatorConcatenation.
  ///
  /// In en, this message translates to:
  /// **'Concatenation'**
  String get operatorConcatenation;

  /// No description provided for @operatorKleeneStar.
  ///
  /// In en, this message translates to:
  /// **'Kleene Star (*)'**
  String get operatorKleeneStar;

  /// No description provided for @operatorPlus.
  ///
  /// In en, this message translates to:
  /// **'Plus (+)'**
  String get operatorPlus;

  /// No description provided for @operatorOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional (?)'**
  String get operatorOptional;

  /// No description provided for @openWitnessInSimulator.
  ///
  /// In en, this message translates to:
  /// **'Open witness in Simulator'**
  String get openWitnessInSimulator;

  /// No description provided for @drawPdaBeforeConvertGrammar.
  ///
  /// In en, this message translates to:
  /// **'Draw a PDA before converting to a grammar.'**
  String get drawPdaBeforeConvertGrammar;

  /// No description provided for @generatedGrammar.
  ///
  /// In en, this message translates to:
  /// **'Generated Grammar'**
  String get generatedGrammar;

  /// No description provided for @pumpingLemmaGameTitle.
  ///
  /// In en, this message translates to:
  /// **'Pumping Lemma Game'**
  String get pumpingLemmaGameTitle;

  /// No description provided for @pumpingWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to the Pumping Lemma Game!'**
  String get pumpingWelcome;

  /// No description provided for @pumpingWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Test your understanding of the pumping lemma by determining whether given languages are regular or not.'**
  String get pumpingWelcomeBody;

  /// No description provided for @startGame.
  ///
  /// In en, this message translates to:
  /// **'Start Game'**
  String get startGame;

  /// No description provided for @isLanguageRegular.
  ///
  /// In en, this message translates to:
  /// **'Is this language regular?'**
  String get isLanguageRegular;

  /// No description provided for @yesItIsRegular.
  ///
  /// In en, this message translates to:
  /// **'Yes, it is regular'**
  String get yesItIsRegular;

  /// No description provided for @noItIsNotRegular.
  ///
  /// In en, this message translates to:
  /// **'No, it is not regular'**
  String get noItIsNotRegular;

  /// No description provided for @submitAnswer.
  ///
  /// In en, this message translates to:
  /// **'Submit Answer'**
  String get submitAnswer;

  /// No description provided for @correct.
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get correct;

  /// No description provided for @incorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect'**
  String get incorrect;

  /// No description provided for @explanation.
  ///
  /// In en, this message translates to:
  /// **'Explanation:'**
  String get explanation;

  /// No description provided for @nextChallenge.
  ///
  /// In en, this message translates to:
  /// **'Next Challenge'**
  String get nextChallenge;

  /// No description provided for @finishGame.
  ///
  /// In en, this message translates to:
  /// **'Finish Game'**
  String get finishGame;

  /// No description provided for @challengeComplete.
  ///
  /// In en, this message translates to:
  /// **'Challenge Complete!'**
  String get challengeComplete;

  /// No description provided for @practiceAgain.
  ///
  /// In en, this message translates to:
  /// **'Practice Again'**
  String get practiceAgain;

  /// No description provided for @performanceExpert.
  ///
  /// In en, this message translates to:
  /// **'Expert'**
  String get performanceExpert;

  /// No description provided for @performanceAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get performanceAdvanced;

  /// No description provided for @performanceIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get performanceIntermediate;

  /// No description provided for @performanceBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get performanceBeginner;

  /// No description provided for @hideGame.
  ///
  /// In en, this message translates to:
  /// **'Hide Game'**
  String get hideGame;

  /// No description provided for @showGame.
  ///
  /// In en, this message translates to:
  /// **'Show Game'**
  String get showGame;

  /// No description provided for @showHelp.
  ///
  /// In en, this message translates to:
  /// **'Show Help'**
  String get showHelp;

  /// No description provided for @hideProgress.
  ///
  /// In en, this message translates to:
  /// **'Hide Progress'**
  String get hideProgress;

  /// No description provided for @showProgress.
  ///
  /// In en, this message translates to:
  /// **'Show Progress'**
  String get showProgress;

  /// No description provided for @progressTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progressTitle;

  /// No description provided for @overallProgress.
  ///
  /// In en, this message translates to:
  /// **'Overall Progress'**
  String get overallProgress;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @accuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get accuracy;

  /// No description provided for @correctCount.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get correctCount;

  /// No description provided for @attempts.
  ///
  /// In en, this message translates to:
  /// **'Attempts'**
  String get attempts;

  /// No description provided for @challengeHistory.
  ///
  /// In en, this message translates to:
  /// **'Challenge History'**
  String get challengeHistory;

  /// No description provided for @noChallengesCompletedYet.
  ///
  /// In en, this message translates to:
  /// **'No challenges completed yet'**
  String get noChallengesCompletedYet;

  /// No description provided for @wrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong'**
  String get wrong;

  /// No description provided for @retrySelected.
  ///
  /// In en, this message translates to:
  /// **'Retry selected'**
  String get retrySelected;

  /// No description provided for @exampleDfaEndsWithA.
  ///
  /// In en, this message translates to:
  /// **'DFA - Ends with A'**
  String get exampleDfaEndsWithA;

  /// No description provided for @exampleDfaBinaryDivBy3.
  ///
  /// In en, this message translates to:
  /// **'DFA - Binary divisible by 3'**
  String get exampleDfaBinaryDivBy3;

  /// No description provided for @exampleDfaParityAb.
  ///
  /// In en, this message translates to:
  /// **'DFA - AB parity'**
  String get exampleDfaParityAb;

  /// No description provided for @exampleDfaContainsAb.
  ///
  /// In en, this message translates to:
  /// **'DFA - Contains AB'**
  String get exampleDfaContainsAb;

  /// No description provided for @exampleNfaLambdaAOrAb.
  ///
  /// In en, this message translates to:
  /// **'NFA-λ - A or AB'**
  String get exampleNfaLambdaAOrAb;

  /// No description provided for @exampleCfgPalindrome.
  ///
  /// In en, this message translates to:
  /// **'CFG - Palindrome'**
  String get exampleCfgPalindrome;

  /// No description provided for @exampleCfgBalancedParens.
  ///
  /// In en, this message translates to:
  /// **'CFG - Balanced parentheses'**
  String get exampleCfgBalancedParens;

  /// No description provided for @exampleCfgAnBn.
  ///
  /// In en, this message translates to:
  /// **'CFG - a^n b^n'**
  String get exampleCfgAnBn;

  /// No description provided for @exampleCfgEvenZeros.
  ///
  /// In en, this message translates to:
  /// **'CFG - Even number of zeros'**
  String get exampleCfgEvenZeros;

  /// No description provided for @exampleCfgArithmetic.
  ///
  /// In en, this message translates to:
  /// **'CFG - Arithmetic expressions'**
  String get exampleCfgArithmetic;

  /// No description provided for @examplePdaBalancedParens.
  ///
  /// In en, this message translates to:
  /// **'PDA - Balanced parentheses'**
  String get examplePdaBalancedParens;

  /// No description provided for @examplePdaAnBn.
  ///
  /// In en, this message translates to:
  /// **'PDA - a^n b^n'**
  String get examplePdaAnBn;

  /// No description provided for @examplePdaPalindrome.
  ///
  /// In en, this message translates to:
  /// **'PDA - Palindrome'**
  String get examplePdaPalindrome;

  /// No description provided for @examplePdaAnB2n.
  ///
  /// In en, this message translates to:
  /// **'PDA - a^n b^2n'**
  String get examplePdaAnB2n;

  /// No description provided for @examplePdaWHashReverseW.
  ///
  /// In en, this message translates to:
  /// **'PDA - w#reverse(w)'**
  String get examplePdaWHashReverseW;

  /// No description provided for @exampleTmAnBn.
  ///
  /// In en, this message translates to:
  /// **'TM - a^n b^n'**
  String get exampleTmAnBn;

  /// No description provided for @exampleTmBinaryToUnary.
  ///
  /// In en, this message translates to:
  /// **'TM - Binary to unary'**
  String get exampleTmBinaryToUnary;

  /// No description provided for @exampleTmCopyString.
  ///
  /// In en, this message translates to:
  /// **'TM - String copy'**
  String get exampleTmCopyString;

  /// No description provided for @exampleTmBinaryIncrement.
  ///
  /// In en, this message translates to:
  /// **'TM - Binary increment'**
  String get exampleTmBinaryIncrement;

  /// No description provided for @exampleTmPalindromeChecker.
  ///
  /// In en, this message translates to:
  /// **'TM - Palindrome checker'**
  String get exampleTmPalindromeChecker;

  /// No description provided for @exampleRegexRepeatA.
  ///
  /// In en, this message translates to:
  /// **'Regex - Repetition of A'**
  String get exampleRegexRepeatA;

  /// No description provided for @exampleRegexEndsWithAb.
  ///
  /// In en, this message translates to:
  /// **'Regex - Ends with AB'**
  String get exampleRegexEndsWithAb;

  /// No description provided for @exampleRegexBinaryStarts0.
  ///
  /// In en, this message translates to:
  /// **'Regex - Binary starting with 0'**
  String get exampleRegexBinaryStarts0;

  /// No description provided for @exampleRegexPairsAbOrBa.
  ///
  /// In en, this message translates to:
  /// **'Regex - AB or BA pairs'**
  String get exampleRegexPairsAbOrBa;

  /// No description provided for @exampleRegexBlocksAb.
  ///
  /// In en, this message translates to:
  /// **'Regex - Blocks of A and B'**
  String get exampleRegexBlocksAb;

  /// No description provided for @failedToLoadExample.
  ///
  /// In en, this message translates to:
  /// **'Failed to load example: {error}'**
  String failedToLoadExample(String error);

  /// No description provided for @exampleLoaded.
  ///
  /// In en, this message translates to:
  /// **'Example loaded: {name}'**
  String exampleLoaded(String name);

  /// No description provided for @copiedQuoted.
  ///
  /// In en, this message translates to:
  /// **'Copied: \"{value}\"'**
  String copiedQuoted(String value);

  /// No description provided for @startSymbolValue.
  ///
  /// In en, this message translates to:
  /// **'Start symbol: {symbol}'**
  String startSymbolValue(String symbol);

  /// No description provided for @nonterminalsValue.
  ///
  /// In en, this message translates to:
  /// **'Non-terminals: {symbols}'**
  String nonterminalsValue(String symbols);

  /// No description provided for @terminalsValue.
  ///
  /// In en, this message translates to:
  /// **'Terminals: {symbols}'**
  String terminalsValue(String symbols);

  /// No description provided for @productionsCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Productions ({count}):'**
  String productionsCountLabel(int count);

  /// No description provided for @pumpingLevelDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Level {level} - {difficulty}'**
  String pumpingLevelDifficulty(int level, String difficulty);

  /// No description provided for @challengeNumber.
  ///
  /// In en, this message translates to:
  /// **'Challenge {number}'**
  String challengeNumber(int number);

  /// No description provided for @languageLabelValue.
  ///
  /// In en, this message translates to:
  /// **'Language: {language}'**
  String languageLabelValue(String language);

  /// No description provided for @streakBonus.
  ///
  /// In en, this message translates to:
  /// **'Streak bonus! +{points} points'**
  String streakBonus(int points);

  /// No description provided for @levelLabelValue.
  ///
  /// In en, this message translates to:
  /// **'Level: {level}'**
  String levelLabelValue(String level);

  /// No description provided for @challengeFallback.
  ///
  /// In en, this message translates to:
  /// **'Challenge {id}'**
  String challengeFallback(String id);

  /// No description provided for @productionRulesCount.
  ///
  /// In en, this message translates to:
  /// **'Production Rules ({count})'**
  String productionRulesCount(int count);

  /// No description provided for @ruleNumber.
  ///
  /// In en, this message translates to:
  /// **'Rule {number}'**
  String ruleNumber(int number);

  /// No description provided for @sampleStringsGeneratedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} sample string(s) generated'**
  String sampleStringsGeneratedCount(int count);

  /// No description provided for @acceptsEpsilon.
  ///
  /// In en, this message translates to:
  /// **'Accepts ε'**
  String get acceptsEpsilon;

  /// No description provided for @shortestSample.
  ///
  /// In en, this message translates to:
  /// **'Shortest: \"{value}\"'**
  String shortestSample(String value);

  /// No description provided for @complexityMetrics.
  ///
  /// In en, this message translates to:
  /// **'Complexity Metrics'**
  String get complexityMetrics;

  /// No description provided for @complexityScore.
  ///
  /// In en, this message translates to:
  /// **'Complexity Score'**
  String get complexityScore;

  /// No description provided for @starHeightDescription.
  ///
  /// In en, this message translates to:
  /// **'Maximum nesting of Kleene star operators (*)'**
  String get starHeightDescription;

  /// No description provided for @nestingDepthDescription.
  ///
  /// In en, this message translates to:
  /// **'Maximum depth of parentheses nesting'**
  String get nestingDepthDescription;

  /// No description provided for @complexityScoreDescription.
  ///
  /// In en, this message translates to:
  /// **'Weighted sum of all complexity factors'**
  String get complexityScoreDescription;

  /// No description provided for @operatorBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Operator Breakdown'**
  String get operatorBreakdown;

  /// No description provided for @alphabetLabel.
  ///
  /// In en, this message translates to:
  /// **'Alphabet'**
  String get alphabetLabel;

  /// No description provided for @alphabetSizeCount.
  ///
  /// In en, this message translates to:
  /// **'Size: {count} symbol(s)'**
  String alphabetSizeCount(int count);

  /// No description provided for @emptyAlphabetExpression.
  ///
  /// In en, this message translates to:
  /// **'Empty alphabet (epsilon-only expression)'**
  String get emptyAlphabetExpression;

  /// No description provided for @nestingShort.
  ///
  /// In en, this message translates to:
  /// **'Nesting'**
  String get nestingShort;

  /// No description provided for @complexitySimple.
  ///
  /// In en, this message translates to:
  /// **'Simple'**
  String get complexitySimple;

  /// No description provided for @complexityModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get complexityModerate;

  /// No description provided for @complexityComplex.
  ///
  /// In en, this message translates to:
  /// **'Complex'**
  String get complexityComplex;

  /// No description provided for @complexitySimpleDescription.
  ///
  /// In en, this message translates to:
  /// **'Easy to understand, low computational cost'**
  String get complexitySimpleDescription;

  /// No description provided for @complexityModerateDescription.
  ///
  /// In en, this message translates to:
  /// **'Moderate complexity, some analysis required'**
  String get complexityModerateDescription;

  /// No description provided for @complexityComplexDescription.
  ///
  /// In en, this message translates to:
  /// **'High complexity, careful analysis recommended'**
  String get complexityComplexDescription;

  /// No description provided for @tmOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Turing Machine Overview'**
  String get tmOverviewTitle;

  /// No description provided for @tmOverviewBody.
  ///
  /// In en, this message translates to:
  /// **'Monitor the structure of your machine and resolve issues before running simulations or algorithms.'**
  String get tmOverviewBody;

  /// No description provided for @tapeSymbols.
  ///
  /// In en, this message translates to:
  /// **'Tape Symbols'**
  String get tapeSymbols;

  /// No description provided for @moveDirections.
  ///
  /// In en, this message translates to:
  /// **'Move Directions'**
  String get moveDirections;

  /// No description provided for @simulationReady.
  ///
  /// In en, this message translates to:
  /// **'Simulation Ready'**
  String get simulationReady;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @nondeterministicTransitions.
  ///
  /// In en, this message translates to:
  /// **'Nondeterministic Transitions'**
  String get nondeterministicTransitions;

  /// No description provided for @resolveNondeterminism.
  ///
  /// In en, this message translates to:
  /// **'Resolve nondeterminism before running deterministic algorithms.'**
  String get resolveNondeterminism;

  /// No description provided for @editCell.
  ///
  /// In en, this message translates to:
  /// **'Edit Cell {index}'**
  String editCell(int index);

  /// No description provided for @tapeAlphabetLabel.
  ///
  /// In en, this message translates to:
  /// **'Tape Alphabet:'**
  String get tapeAlphabetLabel;

  /// No description provided for @symbolLabel.
  ///
  /// In en, this message translates to:
  /// **'Symbol'**
  String get symbolLabel;

  /// No description provided for @enterASymbol.
  ///
  /// In en, this message translates to:
  /// **'Enter a symbol'**
  String get enterASymbol;

  /// No description provided for @tapeHead.
  ///
  /// In en, this message translates to:
  /// **'Tape (Head: {position})'**
  String tapeHead(int position);

  /// No description provided for @emptyTape.
  ///
  /// In en, this message translates to:
  /// **'Empty (□: {symbol})'**
  String emptyTape(String symbol);

  /// No description provided for @directionLeft.
  ///
  /// In en, this message translates to:
  /// **'Left (L)'**
  String get directionLeft;

  /// No description provided for @directionRight.
  ///
  /// In en, this message translates to:
  /// **'Right (R)'**
  String get directionRight;

  /// No description provided for @directionStay.
  ///
  /// In en, this message translates to:
  /// **'Stay (S)'**
  String get directionStay;

  /// No description provided for @egInitialStack.
  ///
  /// In en, this message translates to:
  /// **'e.g., Z'**
  String get egInitialStack;

  /// No description provided for @currentStackState.
  ///
  /// In en, this message translates to:
  /// **'Current Stack State'**
  String get currentStackState;

  /// No description provided for @emptyParen.
  ///
  /// In en, this message translates to:
  /// **'(empty)'**
  String get emptyParen;

  /// No description provided for @highlightingStackCell.
  ///
  /// In en, this message translates to:
  /// **'Highlighting stack cell {index} (from bottom)'**
  String highlightingStackCell(int index);

  /// No description provided for @remainingInputColon.
  ///
  /// In en, this message translates to:
  /// **'Remaining Input:'**
  String get remainingInputColon;

  /// No description provided for @simulationFailed.
  ///
  /// In en, this message translates to:
  /// **'Simulation failed'**
  String get simulationFailed;

  /// No description provided for @timeMs.
  ///
  /// In en, this message translates to:
  /// **'Time: {ms} ms'**
  String timeMs(int ms);

  /// No description provided for @simulationSteps.
  ///
  /// In en, this message translates to:
  /// **'Simulation Steps:'**
  String get simulationSteps;

  /// No description provided for @pleaseEnterInitialStackSymbol.
  ///
  /// In en, this message translates to:
  /// **'Please enter an initial stack symbol'**
  String get pleaseEnterInitialStackSymbol;

  /// No description provided for @createPdaBeforeSimulating.
  ///
  /// In en, this message translates to:
  /// **'Create a PDA on the canvas before simulating.'**
  String get createPdaBeforeSimulating;

  /// No description provided for @simulationCancelled.
  ///
  /// In en, this message translates to:
  /// **'Simulation cancelled'**
  String get simulationCancelled;

  /// No description provided for @pdaExamplesHint.
  ///
  /// In en, this message translates to:
  /// **'Examples: aabb (for balanced parentheses), abab (for palindromes)'**
  String get pdaExamplesHint;

  /// No description provided for @stackCount.
  ///
  /// In en, this message translates to:
  /// **'Stack ({count})'**
  String stackCount(int count);

  /// No description provided for @emptyStack.
  ///
  /// In en, this message translates to:
  /// **'Empty\n(Z₀: {symbol})'**
  String emptyStack(String symbol);

  /// No description provided for @stackCellSemantics.
  ///
  /// In en, this message translates to:
  /// **'Stack cell {position} of {size}'**
  String stackCellSemantics(int position, int size);

  /// No description provided for @stackCellSymbol.
  ///
  /// In en, this message translates to:
  /// **'symbol {symbol}'**
  String stackCellSymbol(String symbol);

  /// No description provided for @topOfStack.
  ///
  /// In en, this message translates to:
  /// **'top of stack'**
  String get topOfStack;

  /// No description provided for @highlighted.
  ///
  /// In en, this message translates to:
  /// **'highlighted'**
  String get highlighted;

  /// No description provided for @beingRemoved.
  ///
  /// In en, this message translates to:
  /// **'being removed'**
  String get beingRemoved;

  /// No description provided for @stackCellHintHighlight.
  ///
  /// In en, this message translates to:
  /// **'Double tap to highlight this stack cell. Swipe right to highlight it.'**
  String get stackCellHintHighlight;

  /// No description provided for @stackCellHintClear.
  ///
  /// In en, this message translates to:
  /// **'Double tap to clear the highlight. Swipe left to unhighlight this stack cell.'**
  String get stackCellHintClear;

  /// No description provided for @clearStack.
  ///
  /// In en, this message translates to:
  /// **'Clear stack'**
  String get clearStack;

  /// No description provided for @clearStackHint.
  ///
  /// In en, this message translates to:
  /// **'Removes every symbol from the stack view.'**
  String get clearStackHint;

  /// No description provided for @overflowMax.
  ///
  /// In en, this message translates to:
  /// **'Overflow!\nMax: {max}'**
  String overflowMax(int max);

  /// No description provided for @underflowPopOnEmpty.
  ///
  /// In en, this message translates to:
  /// **'Underflow!\nPop on empty'**
  String get underflowPopOnEmpty;

  /// No description provided for @topLabel.
  ///
  /// In en, this message translates to:
  /// **'Top: '**
  String get topLabel;

  /// No description provided for @sizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Size: {size}'**
  String sizeLabel(int size);

  /// No description provided for @opLabel.
  ///
  /// In en, this message translates to:
  /// **'Op: {operation}'**
  String opLabel(String operation);

  /// No description provided for @topBadge.
  ///
  /// In en, this message translates to:
  /// **'TOP'**
  String get topBadge;

  /// No description provided for @operationPreview.
  ///
  /// In en, this message translates to:
  /// **'Operation Preview'**
  String get operationPreview;

  /// No description provided for @pop.
  ///
  /// In en, this message translates to:
  /// **'Pop'**
  String get pop;

  /// No description provided for @push.
  ///
  /// In en, this message translates to:
  /// **'Push'**
  String get push;

  /// No description provided for @emptyStackParen.
  ///
  /// In en, this message translates to:
  /// **'(empty stack)'**
  String get emptyStackParen;

  /// No description provided for @inputLabel.
  ///
  /// In en, this message translates to:
  /// **'Input'**
  String get inputLabel;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @resetToFirstStep.
  ///
  /// In en, this message translates to:
  /// **'Reset to First Step'**
  String get resetToFirstStep;

  /// No description provided for @firstStep.
  ///
  /// In en, this message translates to:
  /// **'First step'**
  String get firstStep;

  /// No description provided for @lastStep.
  ///
  /// In en, this message translates to:
  /// **'Last step'**
  String get lastStep;

  /// No description provided for @stepNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Step {number}'**
  String stepNumberLabel(int number);

  /// No description provided for @determinismAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Determinism Analysis'**
  String get determinismAnalysis;

  /// No description provided for @typeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type: '**
  String get typeLabel;

  /// No description provided for @dfaHelpMessage.
  ///
  /// In en, this message translates to:
  /// **'Deterministic Finite Automaton - each state has at most one transition per symbol'**
  String get dfaHelpMessage;

  /// No description provided for @epsilonNfaHelpMessage.
  ///
  /// In en, this message translates to:
  /// **'Nondeterministic Finite Automaton with ε-transitions'**
  String get epsilonNfaHelpMessage;

  /// No description provided for @nfaHelpMessage.
  ///
  /// In en, this message translates to:
  /// **'Nondeterministic Finite Automaton - some states have multiple transitions for the same symbol'**
  String get nfaHelpMessage;

  /// No description provided for @hasEpsilonTransitions.
  ///
  /// In en, this message translates to:
  /// **'Has ε (epsilon) transitions'**
  String get hasEpsilonTransitions;

  /// No description provided for @nondeterministicStates.
  ///
  /// In en, this message translates to:
  /// **'Nondeterministic states:'**
  String get nondeterministicStates;

  /// No description provided for @symbolsWithMultipleTransitions.
  ///
  /// In en, this message translates to:
  /// **'Symbols with multiple transitions:'**
  String get symbolsWithMultipleTransitions;

  /// No description provided for @allTransitionsDeterministic.
  ///
  /// In en, this message translates to:
  /// **'All transitions are deterministic'**
  String get allTransitionsDeterministic;

  /// No description provided for @parser.
  ///
  /// In en, this message translates to:
  /// **'Parser'**
  String get parser;

  /// No description provided for @editGrammar.
  ///
  /// In en, this message translates to:
  /// **'Edit Grammar'**
  String get editGrammar;

  /// No description provided for @transformationSteps.
  ///
  /// In en, this message translates to:
  /// **'Transformation steps'**
  String get transformationSteps;

  /// No description provided for @applyGrammarStep.
  ///
  /// In en, this message translates to:
  /// **'Apply the grammar produced by this step.'**
  String get applyGrammarStep;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @noProductions.
  ///
  /// In en, this message translates to:
  /// **'(no productions)'**
  String get noProductions;

  /// No description provided for @beforeAfter.
  ///
  /// In en, this message translates to:
  /// **'Before / After'**
  String get beforeAfter;

  /// No description provided for @challengesCompleted.
  ///
  /// In en, this message translates to:
  /// **'{completed} / {total} challenges completed'**
  String challengesCompleted(int completed, int total);

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get score;

  /// No description provided for @completeSomeChallengesHint.
  ///
  /// In en, this message translates to:
  /// **'Complete some challenges to see your progress here'**
  String get completeSomeChallengesHint;

  /// No description provided for @correctShort.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get correctShort;

  /// No description provided for @equivalent.
  ///
  /// In en, this message translates to:
  /// **'EQUIVALENT'**
  String get equivalent;

  /// No description provided for @notEquivalent.
  ///
  /// In en, this message translates to:
  /// **'NOT EQUIVALENT'**
  String get notEquivalent;

  /// No description provided for @automatonA.
  ///
  /// In en, this message translates to:
  /// **'Automaton A'**
  String get automatonA;

  /// No description provided for @automatonB.
  ///
  /// In en, this message translates to:
  /// **'Automaton B'**
  String get automatonB;

  /// No description provided for @distinguishingStringFound.
  ///
  /// In en, this message translates to:
  /// **'Distinguishing String Found'**
  String get distinguishingStringFound;

  /// No description provided for @emptyStringEpsilon.
  ///
  /// In en, this message translates to:
  /// **'ε (empty string)'**
  String get emptyStringEpsilon;

  /// No description provided for @distinguishingStringExplanation.
  ///
  /// In en, this message translates to:
  /// **'This string is accepted by one automaton but rejected by the other, proving that the two automata recognize different languages.'**
  String get distinguishingStringExplanation;

  /// No description provided for @statesA.
  ///
  /// In en, this message translates to:
  /// **'States (A)'**
  String get statesA;

  /// No description provided for @statesB.
  ///
  /// In en, this message translates to:
  /// **'States (B)'**
  String get statesB;

  /// No description provided for @transitionsA.
  ///
  /// In en, this message translates to:
  /// **'Transitions (A)'**
  String get transitionsA;

  /// No description provided for @transitionsB.
  ///
  /// In en, this message translates to:
  /// **'Transitions (B)'**
  String get transitionsB;

  /// No description provided for @productAutomaton.
  ///
  /// In en, this message translates to:
  /// **'Product Automaton'**
  String get productAutomaton;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @algorithmSteps.
  ///
  /// In en, this message translates to:
  /// **'Algorithm Steps'**
  String get algorithmSteps;

  /// No description provided for @stepsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} steps'**
  String stepsCount(int count);

  /// No description provided for @collapseSidebar.
  ///
  /// In en, this message translates to:
  /// **'Collapse Sidebar'**
  String get collapseSidebar;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @untitledAutomaton.
  ///
  /// In en, this message translates to:
  /// **'Untitled Automaton'**
  String get untitledAutomaton;

  /// No description provided for @canvasPda.
  ///
  /// In en, this message translates to:
  /// **'Canvas PDA'**
  String get canvasPda;

  /// No description provided for @canvasTm.
  ///
  /// In en, this message translates to:
  /// **'Canvas TM'**
  String get canvasTm;

  /// No description provided for @automatonHasNoStates.
  ///
  /// In en, this message translates to:
  /// **'Automaton has no states'**
  String get automatonHasNoStates;

  /// No description provided for @cannotSimulateEmptyAutomaton.
  ///
  /// In en, this message translates to:
  /// **'Cannot simulate empty automaton'**
  String get cannotSimulateEmptyAutomaton;

  /// No description provided for @pdaHasNoStates.
  ///
  /// In en, this message translates to:
  /// **'PDA has no states'**
  String get pdaHasNoStates;

  /// No description provided for @tmHasNoStates.
  ///
  /// In en, this message translates to:
  /// **'TM has no states'**
  String get tmHasNoStates;

  /// No description provided for @automatonMustHaveAtLeastOneState.
  ///
  /// In en, this message translates to:
  /// **'Automaton must have at least one state'**
  String get automatonMustHaveAtLeastOneState;

  /// No description provided for @cannotConvertEmptyAutomatonToRegex.
  ///
  /// In en, this message translates to:
  /// **'Cannot convert empty automaton to regex'**
  String get cannotConvertEmptyAutomatonToRegex;

  /// No description provided for @faMustHaveAtLeastOneState.
  ///
  /// In en, this message translates to:
  /// **'FA must have at least one state'**
  String get faMustHaveAtLeastOneState;

  /// No description provided for @nfaMustHaveAtLeastOneState.
  ///
  /// In en, this message translates to:
  /// **'NFA must have at least one state'**
  String get nfaMustHaveAtLeastOneState;

  /// No description provided for @dfaMustHaveAtLeastOneState.
  ///
  /// In en, this message translates to:
  /// **'DFA must have at least one state'**
  String get dfaMustHaveAtLeastOneState;

  /// No description provided for @pdaMustHaveAtLeastOneState.
  ///
  /// In en, this message translates to:
  /// **'PDA must have at least one state'**
  String get pdaMustHaveAtLeastOneState;

  /// No description provided for @tmMustHaveAtLeastOneState.
  ///
  /// In en, this message translates to:
  /// **'Turing machine must have at least one state'**
  String get tmMustHaveAtLeastOneState;

  /// No description provided for @tmMustHaveAtLeastOneStatePeriod.
  ///
  /// In en, this message translates to:
  /// **'Turing machine must have at least one state.'**
  String get tmMustHaveAtLeastOneStatePeriod;

  /// No description provided for @automatonAMustHaveAtLeastOneState.
  ///
  /// In en, this message translates to:
  /// **'Automaton A must have at least one state'**
  String get automatonAMustHaveAtLeastOneState;

  /// No description provided for @automatonBMustHaveAtLeastOneState.
  ///
  /// In en, this message translates to:
  /// **'Automaton B must have at least one state'**
  String get automatonBMustHaveAtLeastOneState;

  /// No description provided for @cannotCreateGameWithEmptyAutomaton.
  ///
  /// In en, this message translates to:
  /// **'Cannot create game with empty automaton'**
  String get cannotCreateGameWithEmptyAutomaton;

  /// No description provided for @nfaToDfaTitle.
  ///
  /// In en, this message translates to:
  /// **'NFA to DFA'**
  String get nfaToDfaTitle;

  /// No description provided for @nfaToDfaDescription.
  ///
  /// In en, this message translates to:
  /// **'Convert non-deterministic to deterministic automaton'**
  String get nfaToDfaDescription;

  /// No description provided for @removeLambdaTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove λ-transitions'**
  String get removeLambdaTitle;

  /// No description provided for @removeLambdaDescription.
  ///
  /// In en, this message translates to:
  /// **'Eliminate epsilon transitions from the automaton'**
  String get removeLambdaDescription;

  /// No description provided for @minimizeDfaTitle.
  ///
  /// In en, this message translates to:
  /// **'Minimize DFA'**
  String get minimizeDfaTitle;

  /// No description provided for @minimizeDfaDescription.
  ///
  /// In en, this message translates to:
  /// **'Minimize deterministic finite automaton'**
  String get minimizeDfaDescription;

  /// No description provided for @completeDfaTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete DFA'**
  String get completeDfaTitle;

  /// No description provided for @completeDfaDescription.
  ///
  /// In en, this message translates to:
  /// **'Add trap state to make DFA complete'**
  String get completeDfaDescription;

  /// No description provided for @complementDfaTitle.
  ///
  /// In en, this message translates to:
  /// **'Complement DFA'**
  String get complementDfaTitle;

  /// No description provided for @complementDfaDescription.
  ///
  /// In en, this message translates to:
  /// **'Flip accepting states after completion'**
  String get complementDfaDescription;

  /// No description provided for @unionOfDfasTitle.
  ///
  /// In en, this message translates to:
  /// **'Union of DFAs'**
  String get unionOfDfasTitle;

  /// No description provided for @unionOfDfasDescription.
  ///
  /// In en, this message translates to:
  /// **'Combine this DFA with another automaton from file'**
  String get unionOfDfasDescription;

  /// No description provided for @concatenationOfFsasTitle.
  ///
  /// In en, this message translates to:
  /// **'Concatenation of FSAs'**
  String get concatenationOfFsasTitle;

  /// No description provided for @concatenationOfFsasDescription.
  ///
  /// In en, this message translates to:
  /// **'Append another automaton language using ε-transitions'**
  String get concatenationOfFsasDescription;

  /// No description provided for @kleeneStarTitle.
  ///
  /// In en, this message translates to:
  /// **'Kleene Star'**
  String get kleeneStarTitle;

  /// No description provided for @kleeneStarDescription.
  ///
  /// In en, this message translates to:
  /// **'Accept zero or more repetitions of this FSA language'**
  String get kleeneStarDescription;

  /// No description provided for @reverseFsaTitle.
  ///
  /// In en, this message translates to:
  /// **'Reverse FSA'**
  String get reverseFsaTitle;

  /// No description provided for @reverseFsaDescription.
  ///
  /// In en, this message translates to:
  /// **'Accept the reverse of every word in this FSA language'**
  String get reverseFsaDescription;

  /// No description provided for @intersectionOfDfasTitle.
  ///
  /// In en, this message translates to:
  /// **'Intersection of DFAs'**
  String get intersectionOfDfasTitle;

  /// No description provided for @intersectionOfDfasDescription.
  ///
  /// In en, this message translates to:
  /// **'Intersect this DFA with another automaton from file'**
  String get intersectionOfDfasDescription;

  /// No description provided for @differenceOfDfasTitle.
  ///
  /// In en, this message translates to:
  /// **'Difference of DFAs'**
  String get differenceOfDfasTitle;

  /// No description provided for @differenceOfDfasDescription.
  ///
  /// In en, this message translates to:
  /// **'Compute the language difference with another DFA from file'**
  String get differenceOfDfasDescription;

  /// No description provided for @prefixClosureTitle.
  ///
  /// In en, this message translates to:
  /// **'Prefix Closure'**
  String get prefixClosureTitle;

  /// No description provided for @prefixClosureDescription.
  ///
  /// In en, this message translates to:
  /// **'Accept all prefixes of the DFA language'**
  String get prefixClosureDescription;

  /// No description provided for @suffixClosureTitle.
  ///
  /// In en, this message translates to:
  /// **'Suffix Closure'**
  String get suffixClosureTitle;

  /// No description provided for @suffixClosureDescription.
  ///
  /// In en, this message translates to:
  /// **'Accept all suffixes of the DFA language'**
  String get suffixClosureDescription;

  /// No description provided for @faToRegexTitle.
  ///
  /// In en, this message translates to:
  /// **'FA to Regex'**
  String get faToRegexTitle;

  /// No description provided for @faToRegexDescription.
  ///
  /// In en, this message translates to:
  /// **'Convert finite automaton to regular expression'**
  String get faToRegexDescription;

  /// No description provided for @fsaToGrammarTitle.
  ///
  /// In en, this message translates to:
  /// **'FSA to Grammar'**
  String get fsaToGrammarTitle;

  /// No description provided for @fsaToGrammarDescription.
  ///
  /// In en, this message translates to:
  /// **'Convert finite automaton to regular grammar'**
  String get fsaToGrammarDescription;

  /// No description provided for @autoLayoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto Layout'**
  String get autoLayoutTitle;

  /// No description provided for @autoLayoutDescription.
  ///
  /// In en, this message translates to:
  /// **'Arrange states in a circle'**
  String get autoLayoutDescription;

  /// No description provided for @compareEquivalenceDescription.
  ///
  /// In en, this message translates to:
  /// **'Compare two DFAs for equivalence'**
  String get compareEquivalenceDescription;

  /// No description provided for @clearAutomatonDescription.
  ///
  /// In en, this message translates to:
  /// **'Clear current automaton'**
  String get clearAutomatonDescription;

  /// No description provided for @regexToNfaTitle.
  ///
  /// In en, this message translates to:
  /// **'Regex to NFA'**
  String get regexToNfaTitle;

  /// No description provided for @regexExampleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., (a|b)*'**
  String get regexExampleHint;

  /// No description provided for @convertToCnfTitle.
  ///
  /// In en, this message translates to:
  /// **'Convert to CNF'**
  String get convertToCnfTitle;

  /// No description provided for @convertToCnfDescription.
  ///
  /// In en, this message translates to:
  /// **'Convert grammar to Chomsky Normal Form'**
  String get convertToCnfDescription;

  /// No description provided for @convertToGnfTitle.
  ///
  /// In en, this message translates to:
  /// **'Convert to GNF'**
  String get convertToGnfTitle;

  /// No description provided for @convertToGnfDescription.
  ///
  /// In en, this message translates to:
  /// **'Convert grammar to Greibach Normal Form'**
  String get convertToGnfDescription;

  /// No description provided for @removeLeftRecursionTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Left Recursion'**
  String get removeLeftRecursionTitle;

  /// No description provided for @removeLeftRecursionDescription.
  ///
  /// In en, this message translates to:
  /// **'Eliminate direct and indirect left recursion'**
  String get removeLeftRecursionDescription;

  /// No description provided for @leftFactorTitle.
  ///
  /// In en, this message translates to:
  /// **'Left Factor'**
  String get leftFactorTitle;

  /// No description provided for @leftFactorDescription.
  ///
  /// In en, this message translates to:
  /// **'Apply left factoring to grammar'**
  String get leftFactorDescription;

  /// No description provided for @findFirstSetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Find First Sets'**
  String get findFirstSetsTitle;

  /// No description provided for @findFirstSetsDescription.
  ///
  /// In en, this message translates to:
  /// **'Calculate FIRST sets for all variables'**
  String get findFirstSetsDescription;

  /// No description provided for @findFollowSetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Find Follow Sets'**
  String get findFollowSetsTitle;

  /// No description provided for @findFollowSetsDescription.
  ///
  /// In en, this message translates to:
  /// **'Calculate FOLLOW sets for all variables'**
  String get findFollowSetsDescription;

  /// No description provided for @buildParseTableTitle.
  ///
  /// In en, this message translates to:
  /// **'Build Parse Table'**
  String get buildParseTableTitle;

  /// No description provided for @buildParseTableDescription.
  ///
  /// In en, this message translates to:
  /// **'Generate LL(1) or LR(1) parse table'**
  String get buildParseTableDescription;

  /// No description provided for @checkAmbiguityTitle.
  ///
  /// In en, this message translates to:
  /// **'Check Ambiguity'**
  String get checkAmbiguityTitle;

  /// No description provided for @checkAmbiguityDescription.
  ///
  /// In en, this message translates to:
  /// **'Detect if grammar is ambiguous'**
  String get checkAmbiguityDescription;

  /// No description provided for @convertRightLinearToFsaTitle.
  ///
  /// In en, this message translates to:
  /// **'Convert Right-Linear Grammar to FSA'**
  String get convertRightLinearToFsaTitle;

  /// No description provided for @convertRightLinearToFsaDescription.
  ///
  /// In en, this message translates to:
  /// **'Build an FSA from a right-linear grammar'**
  String get convertRightLinearToFsaDescription;

  /// No description provided for @convertGrammarToPdaGeneralTitle.
  ///
  /// In en, this message translates to:
  /// **'Convert Grammar to PDA (General)'**
  String get convertGrammarToPdaGeneralTitle;

  /// No description provided for @convertGrammarToPdaGeneralDescription.
  ///
  /// In en, this message translates to:
  /// **'Build an equivalent PDA from the grammar'**
  String get convertGrammarToPdaGeneralDescription;

  /// No description provided for @convertGrammarToPdaStandardTitle.
  ///
  /// In en, this message translates to:
  /// **'Convert Grammar to PDA (Standard)'**
  String get convertGrammarToPdaStandardTitle;

  /// No description provided for @convertGrammarToPdaStandardDescription.
  ///
  /// In en, this message translates to:
  /// **'Build a standard-form PDA from the grammar'**
  String get convertGrammarToPdaStandardDescription;

  /// No description provided for @convertGrammarToPdaGreibachTitle.
  ///
  /// In en, this message translates to:
  /// **'Convert Grammar to PDA (Greibach)'**
  String get convertGrammarToPdaGreibachTitle;

  /// No description provided for @convertGrammarToPdaGreibachDescription.
  ///
  /// In en, this message translates to:
  /// **'Build a Greibach-form PDA from the grammar'**
  String get convertGrammarToPdaGreibachDescription;

  /// No description provided for @leftRecursionRemovalResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Direct and Indirect Left Recursion Removal'**
  String get leftRecursionRemovalResultTitle;

  /// No description provided for @leftFactoringAnalysisTitle.
  ///
  /// In en, this message translates to:
  /// **'Left Factoring Analysis'**
  String get leftFactoringAnalysisTitle;

  /// No description provided for @firstSetsAnalysisTitle.
  ///
  /// In en, this message translates to:
  /// **'FIRST Sets Analysis'**
  String get firstSetsAnalysisTitle;

  /// No description provided for @followSetsAnalysisTitle.
  ///
  /// In en, this message translates to:
  /// **'FOLLOW Sets Analysis'**
  String get followSetsAnalysisTitle;

  /// No description provided for @cnfConversionTitle.
  ///
  /// In en, this message translates to:
  /// **'Chomsky Normal Form (CNF) Conversion'**
  String get cnfConversionTitle;

  /// No description provided for @gnfConversionTitle.
  ///
  /// In en, this message translates to:
  /// **'Greibach Normal Form (GNF) Conversion'**
  String get gnfConversionTitle;

  /// No description provided for @convertToCfgTitle.
  ///
  /// In en, this message translates to:
  /// **'Convert to CFG'**
  String get convertToCfgTitle;

  /// No description provided for @convertToCfgDescription.
  ///
  /// In en, this message translates to:
  /// **'Convert PDA to equivalent context-free grammar'**
  String get convertToCfgDescription;

  /// No description provided for @checkDeterminismTitle.
  ///
  /// In en, this message translates to:
  /// **'Check Determinism'**
  String get checkDeterminismTitle;

  /// No description provided for @checkDeterminismDescription.
  ///
  /// In en, this message translates to:
  /// **'Determine if PDA is deterministic'**
  String get checkDeterminismDescription;

  /// No description provided for @findReachableStatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Find Reachable States'**
  String get findReachableStatesTitle;

  /// No description provided for @findReachableStatesDescription.
  ///
  /// In en, this message translates to:
  /// **'Identify reachable states from initial state'**
  String get findReachableStatesDescription;

  /// No description provided for @languageAnalysisTitle.
  ///
  /// In en, this message translates to:
  /// **'Language Analysis'**
  String get languageAnalysisTitle;

  /// No description provided for @languageAnalysisDescription.
  ///
  /// In en, this message translates to:
  /// **'Prove emptiness and find a shortest accepted word'**
  String get languageAnalysisDescription;

  /// No description provided for @stackOperationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Stack Operations'**
  String get stackOperationsTitle;

  /// No description provided for @stackOperationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Analyze stack operations and depth'**
  String get stackOperationsDescription;

  /// No description provided for @pdaIsDeterministic.
  ///
  /// In en, this message translates to:
  /// **'Result: PDA is deterministic (no conflicting transitions).'**
  String get pdaIsDeterministic;

  /// No description provided for @pdaIsNondeterministic.
  ///
  /// In en, this message translates to:
  /// **'Result: PDA is NON-deterministic.'**
  String get pdaIsNondeterministic;

  /// No description provided for @conflictingTransitions.
  ///
  /// In en, this message translates to:
  /// **'Conflicting transitions:'**
  String get conflictingTransitions;

  /// No description provided for @lambdaTransitionsPresent.
  ///
  /// In en, this message translates to:
  /// **'Lambda transitions present: {count}'**
  String lambdaTransitionsPresent(int count);

  /// No description provided for @totalTransitionsCount.
  ///
  /// In en, this message translates to:
  /// **'Total transitions: {count}'**
  String totalTransitionsCount(int count);

  /// No description provided for @reachableStatesCount.
  ///
  /// In en, this message translates to:
  /// **'Reachable states ({count}):'**
  String reachableStatesCount(int count);

  /// No description provided for @unreachableStatesCount.
  ///
  /// In en, this message translates to:
  /// **'Unreachable states ({count}):'**
  String unreachableStatesCount(int count);

  /// No description provided for @languageIsEmptyProved.
  ///
  /// In en, this message translates to:
  /// **'Language is empty (proved).'**
  String get languageIsEmptyProved;

  /// No description provided for @languageIsNonEmptyProved.
  ///
  /// In en, this message translates to:
  /// **'Language is non-empty (proved).'**
  String get languageIsNonEmptyProved;

  /// No description provided for @acceptanceModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Acceptance mode: {mode}'**
  String acceptanceModeLabel(String mode);

  /// No description provided for @acceptanceModeFinalState.
  ///
  /// In en, this message translates to:
  /// **'final state'**
  String get acceptanceModeFinalState;

  /// No description provided for @acceptanceModeEmptyStack.
  ///
  /// In en, this message translates to:
  /// **'empty stack'**
  String get acceptanceModeEmptyStack;

  /// No description provided for @acceptanceModeBoth.
  ///
  /// In en, this message translates to:
  /// **'final state and empty stack'**
  String get acceptanceModeBoth;

  /// No description provided for @pdaEmptinessProofLine.
  ///
  /// In en, this message translates to:
  /// **'Proof: mode-aware PDA normalization → CFG productivity fixed point.'**
  String get pdaEmptinessProofLine;

  /// No description provided for @productiveNonterminalsCount.
  ///
  /// In en, this message translates to:
  /// **'Productive nonterminals: {count}'**
  String productiveNonterminalsCount(int count);

  /// No description provided for @shortestWitness.
  ///
  /// In en, this message translates to:
  /// **'Shortest witness: {witness}'**
  String shortestWitness(String witness);

  /// No description provided for @terminalSymbolLength.
  ///
  /// In en, this message translates to:
  /// **'Terminal-symbol length: {length} (multi-character terminals count as one symbol).'**
  String terminalSymbolLength(int length);

  /// No description provided for @equalLengthShortlex.
  ///
  /// In en, this message translates to:
  /// **'Equal-length ties use deterministic shortlex order.'**
  String get equalLengthShortlex;

  /// No description provided for @leftmostCfgDerivation.
  ///
  /// In en, this message translates to:
  /// **'Leftmost CFG derivation:'**
  String get leftmostCfgDerivation;

  /// No description provided for @moreDerivationSteps.
  ///
  /// In en, this message translates to:
  /// **'  … {count} more step(s)'**
  String moreDerivationSteps(int count);

  /// No description provided for @emptinessProofUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Emptiness proof unavailable: {message}\nNo conclusion about language emptiness was made.'**
  String emptinessProofUnavailable(String message);

  /// No description provided for @createPdaToAnalyzeDeterminism.
  ///
  /// In en, this message translates to:
  /// **'Create a PDA to analyze determinism.'**
  String get createPdaToAnalyzeDeterminism;

  /// No description provided for @createPdaToAnalyzeReachability.
  ///
  /// In en, this message translates to:
  /// **'Create a PDA to analyze reachability.'**
  String get createPdaToAnalyzeReachability;

  /// No description provided for @initialStateWithLabel.
  ///
  /// In en, this message translates to:
  /// **'Initial state: {label}'**
  String initialStateWithLabel(String label);

  /// No description provided for @initialStackSymbolWithValue.
  ///
  /// In en, this message translates to:
  /// **'Initial stack symbol: {symbol}'**
  String initialStackSymbolWithValue(String symbol);

  /// No description provided for @grammarAnalysisTitle.
  ///
  /// In en, this message translates to:
  /// **'Grammar Analysis'**
  String get grammarAnalysisTitle;

  /// No description provided for @pdaAnalysisTitle.
  ///
  /// In en, this message translates to:
  /// **'PDA Analysis'**
  String get pdaAnalysisTitle;

  /// No description provided for @tmAnalysisTitle.
  ///
  /// In en, this message translates to:
  /// **'TM Analysis'**
  String get tmAnalysisTitle;

  /// No description provided for @noAnalysisResultsYet.
  ///
  /// In en, this message translates to:
  /// **'No analysis results yet'**
  String get noAnalysisResultsYet;

  /// No description provided for @selectAlgorithmToAnalyzePda.
  ///
  /// In en, this message translates to:
  /// **'Select an algorithm above to analyze your PDA'**
  String get selectAlgorithmToAnalyzePda;

  /// No description provided for @selectAlgorithmToAnalyzeGrammar.
  ///
  /// In en, this message translates to:
  /// **'Select an algorithm above to analyze your grammar'**
  String get selectAlgorithmToAnalyzeGrammar;

  /// No description provided for @selectAlgorithmToAnalyzeTm.
  ///
  /// In en, this message translates to:
  /// **'Select an algorithm above to analyze your TM.'**
  String get selectAlgorithmToAnalyzeTm;

  /// No description provided for @addAtLeastOneProductionRule.
  ///
  /// In en, this message translates to:
  /// **'Add at least one production rule to enable conversions.'**
  String get addAtLeastOneProductionRule;

  /// No description provided for @convertingToFsa.
  ///
  /// In en, this message translates to:
  /// **'Converting to FSA...'**
  String get convertingToFsa;

  /// No description provided for @convertingToPda.
  ///
  /// In en, this message translates to:
  /// **'Converting to PDA...'**
  String get convertingToPda;

  /// No description provided for @convertingStandard.
  ///
  /// In en, this message translates to:
  /// **'Converting (Standard)...'**
  String get convertingStandard;

  /// No description provided for @convertingGreibach.
  ///
  /// In en, this message translates to:
  /// **'Converting (Greibach)...'**
  String get convertingGreibach;

  /// No description provided for @parseString.
  ///
  /// In en, this message translates to:
  /// **'Parse String'**
  String get parseString;

  /// No description provided for @noParseResultsYet.
  ///
  /// In en, this message translates to:
  /// **'No parse results yet'**
  String get noParseResultsYet;

  /// No description provided for @enterAStringAndClickParse.
  ///
  /// In en, this message translates to:
  /// **'Enter a string and click Parse to see results'**
  String get enterAStringAndClickParse;

  /// No description provided for @terminationAndCyclesTitle.
  ///
  /// In en, this message translates to:
  /// **'Termination and Cycles'**
  String get terminationAndCyclesTitle;

  /// No description provided for @terminationAndCyclesDescription.
  ///
  /// In en, this message translates to:
  /// **'Classify one input under explicit execution limits'**
  String get terminationAndCyclesDescription;

  /// No description provided for @reachabilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Reachability'**
  String get reachabilityTitle;

  /// No description provided for @reachabilityDescription.
  ///
  /// In en, this message translates to:
  /// **'Compare structural reachability with bounded witnesses'**
  String get reachabilityDescription;

  /// No description provided for @languageExplorerTitle.
  ///
  /// In en, this message translates to:
  /// **'Language Explorer'**
  String get languageExplorerTitle;

  /// No description provided for @languageExplorerDescription.
  ///
  /// In en, this message translates to:
  /// **'Classify a bounded shortlex sample into four outcomes'**
  String get languageExplorerDescription;

  /// No description provided for @tapeTraceTitle.
  ///
  /// In en, this message translates to:
  /// **'Tape Trace'**
  String get tapeTraceTitle;

  /// No description provided for @tapeTraceDescription.
  ///
  /// In en, this message translates to:
  /// **'Measure operations on one concrete execution branch'**
  String get tapeTraceDescription;

  /// No description provided for @timeProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Time Profile'**
  String get timeProfileTitle;

  /// No description provided for @timeProfileDescription.
  ///
  /// In en, this message translates to:
  /// **'Measure transition steps by input length within bounds'**
  String get timeProfileDescription;

  /// No description provided for @spaceProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Space Profile'**
  String get spaceProfileTitle;

  /// No description provided for @spaceProfileDescription.
  ///
  /// In en, this message translates to:
  /// **'Measure bounded tape-cell usage by input length'**
  String get spaceProfileDescription;

  /// No description provided for @determinismCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Determinism Check'**
  String get determinismCheckTitle;

  /// No description provided for @reachableStatesAnalysisTitle.
  ///
  /// In en, this message translates to:
  /// **'Reachable States Analysis'**
  String get reachableStatesAnalysisTitle;

  /// No description provided for @pdaToCfgConversionTitle.
  ///
  /// In en, this message translates to:
  /// **'PDA to CFG Conversion'**
  String get pdaToCfgConversionTitle;

  /// No description provided for @stackOperationsAnalysisTitle.
  ///
  /// In en, this message translates to:
  /// **'Stack Operations Analysis'**
  String get stackOperationsAnalysisTitle;

  /// No description provided for @createPdaToAnalyzeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Create a PDA to analyze its language.'**
  String get createPdaToAnalyzeLanguage;

  /// No description provided for @createPdaToInspectStack.
  ///
  /// In en, this message translates to:
  /// **'Create a PDA to inspect stack operations.'**
  String get createPdaToInspectStack;

  /// No description provided for @shortestWitnessOpened.
  ///
  /// In en, this message translates to:
  /// **'Shortest-witness trace opened in the Simulator panel.'**
  String get shortestWitnessOpened;

  /// No description provided for @pushOperationsCount.
  ///
  /// In en, this message translates to:
  /// **'Push operations ({count}):'**
  String pushOperationsCount(int count);

  /// No description provided for @popOperationsCount.
  ///
  /// In en, this message translates to:
  /// **'Pop operations ({count}):'**
  String popOperationsCount(int count);

  /// No description provided for @stackSymbolsTouched.
  ///
  /// In en, this message translates to:
  /// **'Stack symbols touched ({count}):'**
  String stackSymbolsTouched(int count);

  /// No description provided for @noneValue.
  ///
  /// In en, this message translates to:
  /// **'  None'**
  String get noneValue;

  /// No description provided for @pdaTransitionsCount.
  ///
  /// In en, this message translates to:
  /// **'PDA transitions: {pdaCount}, FSA transitions: {fsaCount}'**
  String pdaTransitionsCount(int pdaCount, int fsaCount);

  /// No description provided for @analysisFailedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Analysis failed: {error}'**
  String analysisFailedPrefix(String error);

  /// No description provided for @errorRunningAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Error running analysis: {error}'**
  String errorRunningAnalysis(String error);

  /// No description provided for @repeatedCycleTrace.
  ///
  /// In en, this message translates to:
  /// **'Repeated cycle trace'**
  String get repeatedCycleTrace;

  /// No description provided for @relatedExecutionTrace.
  ///
  /// In en, this message translates to:
  /// **'Related execution trace'**
  String get relatedExecutionTrace;

  /// No description provided for @noInputLengthGroupEvaluated.
  ///
  /// In en, this message translates to:
  /// **'No input-length group was evaluated.'**
  String get noInputLengthGroupEvaluated;

  /// No description provided for @noCandidatesEvaluated.
  ///
  /// In en, this message translates to:
  /// **'No candidates were evaluated.'**
  String get noCandidatesEvaluated;

  /// No description provided for @noTraceRecordedBoundedRun.
  ///
  /// In en, this message translates to:
  /// **'No trace was recorded for this bounded run.'**
  String get noTraceRecordedBoundedRun;

  /// No description provided for @maximumTransitionStepWitness.
  ///
  /// In en, this message translates to:
  /// **'Maximum transition-step witness'**
  String get maximumTransitionStepWitness;

  /// No description provided for @maximumExplorationDepthWitness.
  ///
  /// In en, this message translates to:
  /// **'Maximum exploration-depth witness'**
  String get maximumExplorationDepthWitness;

  /// No description provided for @maximumExploredConfigurationsWitness.
  ///
  /// In en, this message translates to:
  /// **'Maximum explored-configurations witness'**
  String get maximumExploredConfigurationsWitness;

  /// No description provided for @noTmAvailableToAnalyze.
  ///
  /// In en, this message translates to:
  /// **'No Turing machine available. Draw states and transitions on the canvas to analyze.'**
  String get noTmAvailableToAnalyze;

  /// No description provided for @retainedConfigurations.
  ///
  /// In en, this message translates to:
  /// **'{count} retained configuration(s)'**
  String retainedConfigurations(int count);

  /// No description provided for @initialConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Initial configuration'**
  String get initialConfiguration;

  /// No description provided for @grammarParserExamplesHint.
  ///
  /// In en, this message translates to:
  /// **'Examples: aabb, abab, aabbb (for S → aSb | ab)'**
  String get grammarParserExamplesHint;

  /// No description provided for @parsingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Parsing...'**
  String get parsingEllipsis;

  /// No description provided for @derivationTree.
  ///
  /// In en, this message translates to:
  /// **'Derivation Tree'**
  String get derivationTree;

  /// No description provided for @derivationTreesAmbiguous.
  ///
  /// In en, this message translates to:
  /// **'Derivation Trees (showing first {count}; ambiguous)'**
  String derivationTreesAmbiguous(int count);

  /// No description provided for @cykSteps.
  ///
  /// In en, this message translates to:
  /// **'CYK Steps'**
  String get cykSteps;

  /// No description provided for @expectedColon.
  ///
  /// In en, this message translates to:
  /// **'Expected:'**
  String get expectedColon;

  /// No description provided for @failedToParseString.
  ///
  /// In en, this message translates to:
  /// **'Failed to parse string'**
  String get failedToParseString;

  /// No description provided for @failedToParseStringError.
  ///
  /// In en, this message translates to:
  /// **'Failed to parse string: {error}'**
  String failedToParseStringError(String error);

  /// No description provided for @executionTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Execution time: {time}'**
  String executionTimeLabel(String time);

  /// No description provided for @farthestPositionLabel.
  ///
  /// In en, this message translates to:
  /// **'Farthest position: {position} / {length}'**
  String farthestPositionLabel(int position, int length);

  /// No description provided for @examplesLabel.
  ///
  /// In en, this message translates to:
  /// **'Examples:'**
  String get examplesLabel;

  /// No description provided for @hintForNextTime.
  ///
  /// In en, this message translates to:
  /// **'Hint for next time:'**
  String get hintForNextTime;

  /// No description provided for @pngExportNotSupportedOnWeb.
  ///
  /// In en, this message translates to:
  /// **'PNG export is not supported on web.'**
  String get pngExportNotSupportedOnWeb;

  /// No description provided for @documentsDirectoryNotAvailableOnWeb.
  ///
  /// In en, this message translates to:
  /// **'Documents directory is not available on web.'**
  String get documentsDirectoryNotAvailableOnWeb;

  /// No description provided for @pumpingChallenge1Description.
  ///
  /// In en, this message translates to:
  /// **'Strings of only a\'s'**
  String get pumpingChallenge1Description;

  /// No description provided for @pumpingChallenge1Explanation.
  ///
  /// In en, this message translates to:
  /// **'This language is regular. It can be recognized by a simple automaton that accepts any number of a\'s.'**
  String get pumpingChallenge1Explanation;

  /// No description provided for @pumpingChallenge1Hint.
  ///
  /// In en, this message translates to:
  /// **'Think about whether a finite state machine can recognize this pattern.'**
  String get pumpingChallenge1Hint;

  /// No description provided for @pumpingChallenge1Proof1.
  ///
  /// In en, this message translates to:
  /// **'This is a regular language because it follows a simple pattern.'**
  String get pumpingChallenge1Proof1;

  /// No description provided for @pumpingChallenge1Proof2.
  ///
  /// In en, this message translates to:
  /// **'A finite automaton can accept this by having a single state that loops on \"a\".'**
  String get pumpingChallenge1Proof2;

  /// No description provided for @pumpingChallenge1Proof3.
  ///
  /// In en, this message translates to:
  /// **'The pumping lemma condition is satisfied since we can always find strings that can be pumped.'**
  String get pumpingChallenge1Proof3;

  /// No description provided for @pumpingChallenge1Proof4.
  ///
  /// In en, this message translates to:
  /// **'For any pumping length p, we can choose x = ε, y = a^k (1 ≤ k ≤ p), z = a^(n-k) for n ≥ k.'**
  String get pumpingChallenge1Proof4;

  /// No description provided for @pumpingChallenge1Proof5.
  ///
  /// In en, this message translates to:
  /// **'Then xy^iz ∈ L for all i ≥ 0 because it\'s still just a\'s.'**
  String get pumpingChallenge1Proof5;

  /// No description provided for @pumpingChallenge2Description.
  ///
  /// In en, this message translates to:
  /// **'Strings with a\'s followed by b\'s'**
  String get pumpingChallenge2Description;

  /// No description provided for @pumpingChallenge2Explanation.
  ///
  /// In en, this message translates to:
  /// **'This language is regular. It can be recognized by an automaton that accepts any number of a\'s followed by any number of b\'s.'**
  String get pumpingChallenge2Explanation;

  /// No description provided for @pumpingChallenge2Hint.
  ///
  /// In en, this message translates to:
  /// **'Consider if this can be recognized by counting states or a simple state machine.'**
  String get pumpingChallenge2Hint;

  /// No description provided for @pumpingChallenge2Proof1.
  ///
  /// In en, this message translates to:
  /// **'This language is regular because the two parts (a\'s and b\'s) are independent.'**
  String get pumpingChallenge2Proof1;

  /// No description provided for @pumpingChallenge2Proof2.
  ///
  /// In en, this message translates to:
  /// **'A finite automaton can track whether we\'ve seen any b\'s yet.'**
  String get pumpingChallenge2Proof2;

  /// No description provided for @pumpingChallenge2Proof3.
  ///
  /// In en, this message translates to:
  /// **'Once a b is seen, only b\'s are accepted.'**
  String get pumpingChallenge2Proof3;

  /// No description provided for @pumpingChallenge2Proof4.
  ///
  /// In en, this message translates to:
  /// **'The pumping lemma is satisfied because we can pump either the a\'s or b\'s independently.'**
  String get pumpingChallenge2Proof4;

  /// No description provided for @pumpingChallenge3Description.
  ///
  /// In en, this message translates to:
  /// **'Strings with equal number of a\'s and b\'s'**
  String get pumpingChallenge3Description;

  /// No description provided for @pumpingChallenge3Explanation.
  ///
  /// In en, this message translates to:
  /// **'This language is not regular. For any pumping length p, the string a^p b^p can be pumped, but pumping the a\'s will break the balance.'**
  String get pumpingChallenge3Explanation;

  /// No description provided for @pumpingChallenge3Hint.
  ///
  /// In en, this message translates to:
  /// **'Try applying the pumping lemma with p = 2. What happens when you pump?'**
  String get pumpingChallenge3Hint;

  /// No description provided for @pumpingChallenge3Proof1.
  ///
  /// In en, this message translates to:
  /// **'This is a classic non-regular language.'**
  String get pumpingChallenge3Proof1;

  /// No description provided for @pumpingChallenge3Proof2.
  ///
  /// In en, this message translates to:
  /// **'The pumping lemma says: for any p ≥ 1, there exists a string s = xyz where |xy| ≤ p, |y| ≥ 1, and xy^iz ∈ L for all i ≥ 0.'**
  String get pumpingChallenge3Proof2;

  /// No description provided for @pumpingChallenge3Proof3.
  ///
  /// In en, this message translates to:
  /// **'For s = a^p b^p, we can choose x = a^(p-1), y = a, z = b^p.'**
  String get pumpingChallenge3Proof3;

  /// No description provided for @pumpingChallenge3Proof4.
  ///
  /// In en, this message translates to:
  /// **'Then xy^2z = a^(p+1) b^p, which has more a\'s than b\'s, so it\'s not in L.'**
  String get pumpingChallenge3Proof4;

  /// No description provided for @pumpingChallenge3Proof5.
  ///
  /// In en, this message translates to:
  /// **'This shows that no finite automaton can recognize this language.'**
  String get pumpingChallenge3Proof5;

  /// No description provided for @pumpingChallenge4Description.
  ///
  /// In en, this message translates to:
  /// **'Strings with equal number of a\'s, b\'s, and c\'s'**
  String get pumpingChallenge4Description;

  /// No description provided for @pumpingChallenge4Explanation.
  ///
  /// In en, this message translates to:
  /// **'This language is not regular. It requires counting three different symbols, which cannot be done with finite memory.'**
  String get pumpingChallenge4Explanation;

  /// No description provided for @pumpingChallenge4Hint.
  ///
  /// In en, this message translates to:
  /// **'Think about how many independent counters this would require.'**
  String get pumpingChallenge4Hint;

  /// No description provided for @pumpingChallenge4Proof1.
  ///
  /// In en, this message translates to:
  /// **'This language requires tracking three independent counters.'**
  String get pumpingChallenge4Proof1;

  /// No description provided for @pumpingChallenge4Proof2.
  ///
  /// In en, this message translates to:
  /// **'No finite state machine can keep track of three separate counts simultaneously.'**
  String get pumpingChallenge4Proof2;

  /// No description provided for @pumpingChallenge4Proof3.
  ///
  /// In en, this message translates to:
  /// **'Using the pumping lemma: choose a string with p a\'s, p b\'s, and p c\'s.'**
  String get pumpingChallenge4Proof3;

  /// No description provided for @pumpingChallenge4Proof4.
  ///
  /// In en, this message translates to:
  /// **'Pumping the a\'s will break the balance between a\'s, b\'s, and c\'s.'**
  String get pumpingChallenge4Proof4;

  /// No description provided for @pumpingChallenge4Proof5.
  ///
  /// In en, this message translates to:
  /// **'For s = a^p b^p c^p, choose x = a^(p-1), y = a, z = b^p c^p.'**
  String get pumpingChallenge4Proof5;

  /// No description provided for @pumpingChallenge4Proof6.
  ///
  /// In en, this message translates to:
  /// **'Then xy^2z = a^(p+1) b^p c^p ∉ L because p+1 ≠ p ≠ p.'**
  String get pumpingChallenge4Proof6;

  /// No description provided for @pumpingChallenge5Description.
  ///
  /// In en, this message translates to:
  /// **'Strings that are concatenations of a word with itself'**
  String get pumpingChallenge5Description;

  /// No description provided for @pumpingChallenge5Explanation.
  ///
  /// In en, this message translates to:
  /// **'This language is not regular. It requires remembering the first half of the string to match the second half, which requires unbounded memory.'**
  String get pumpingChallenge5Explanation;

  /// No description provided for @pumpingChallenge5Hint.
  ///
  /// In en, this message translates to:
  /// **'What happens if you choose a very long string and try to apply the pumping lemma?'**
  String get pumpingChallenge5Hint;

  /// No description provided for @pumpingChallenge5Proof1.
  ///
  /// In en, this message translates to:
  /// **'This language requires remembering the entire first half of the string.'**
  String get pumpingChallenge5Proof1;

  /// No description provided for @pumpingChallenge5Proof2.
  ///
  /// In en, this message translates to:
  /// **'No matter how large the pumping length p is, we can choose w with length > p.'**
  String get pumpingChallenge5Proof2;

  /// No description provided for @pumpingChallenge5Proof3.
  ///
  /// In en, this message translates to:
  /// **'For s = ww where |w| > p, the first half has length > p.'**
  String get pumpingChallenge5Proof3;

  /// No description provided for @pumpingChallenge5Proof4.
  ///
  /// In en, this message translates to:
  /// **'The pumping lemma cannot find a suitable decomposition that preserves the property.'**
  String get pumpingChallenge5Proof4;

  /// No description provided for @pumpingChallenge5Proof5.
  ///
  /// In en, this message translates to:
  /// **'This is the language of duplicated strings, not the language of palindromes; palindromes are strings equal to their reverse.'**
  String get pumpingChallenge5Proof5;

  /// No description provided for @pumpingChallenge6Description.
  ///
  /// In en, this message translates to:
  /// **'Strings with even number of a\'s'**
  String get pumpingChallenge6Description;

  /// No description provided for @pumpingChallenge6Explanation.
  ///
  /// In en, this message translates to:
  /// **'This language is regular. It can be recognized by a finite automaton that tracks parity (even/odd number of a\'s).'**
  String get pumpingChallenge6Explanation;

  /// No description provided for @pumpingChallenge6Hint.
  ///
  /// In en, this message translates to:
  /// **'Think about modulo 2 instead of exact counting.'**
  String get pumpingChallenge6Hint;

  /// No description provided for @pumpingChallenge6Proof1.
  ///
  /// In en, this message translates to:
  /// **'This is actually a regular language!'**
  String get pumpingChallenge6Proof1;

  /// No description provided for @pumpingChallenge6Proof2.
  ///
  /// In en, this message translates to:
  /// **'A 2-state automaton can track whether we\'ve seen an even or odd number of a\'s.'**
  String get pumpingChallenge6Proof2;

  /// No description provided for @pumpingChallenge6Proof3.
  ///
  /// In en, this message translates to:
  /// **'Start in an \"even\" state, go to \"odd\" state on each \"a\", and back to \"even\" on the next \"a\".'**
  String get pumpingChallenge6Proof3;

  /// No description provided for @pumpingChallenge6Proof4.
  ///
  /// In en, this message translates to:
  /// **'Accept only in the \"even\" state.'**
  String get pumpingChallenge6Proof4;

  /// No description provided for @pumpingChallenge6Proof5.
  ///
  /// In en, this message translates to:
  /// **'The key insight is that we only need to track parity, not the exact count.'**
  String get pumpingChallenge6Proof5;

  /// No description provided for @pumpingChallenge7Description.
  ///
  /// In en, this message translates to:
  /// **'Union of equal a\'s and b\'s with strings of only a\'s'**
  String get pumpingChallenge7Description;

  /// No description provided for @pumpingChallenge7Explanation.
  ///
  /// In en, this message translates to:
  /// **'This language is not regular, but that cannot be proved merely by pointing to a subset. A pumping-lemma or closure-property argument is required.'**
  String get pumpingChallenge7Explanation;

  /// No description provided for @pumpingChallenge7Hint.
  ///
  /// In en, this message translates to:
  /// **'Consider what happens when you try to apply the pumping lemma to strings from the a^n b^n part.'**
  String get pumpingChallenge7Hint;

  /// No description provided for @pumpingChallenge7Proof1.
  ///
  /// In en, this message translates to:
  /// **'This language contains both a non-regular part (a^n b^n) and a regular part (a^m).'**
  String get pumpingChallenge7Proof1;

  /// No description provided for @pumpingChallenge7Proof2.
  ///
  /// In en, this message translates to:
  /// **'The union of a non-regular language with a regular language may or may not be regular.'**
  String get pumpingChallenge7Proof2;

  /// No description provided for @pumpingChallenge7Proof3.
  ///
  /// In en, this message translates to:
  /// **'Finding a non-regular subset is not enough to prove the whole language is non-regular.'**
  String get pumpingChallenge7Proof3;

  /// No description provided for @pumpingChallenge7Proof4.
  ///
  /// In en, this message translates to:
  /// **'A valid proof can use the pumping lemma directly on strings a^p b^p from the mixed language.'**
  String get pumpingChallenge7Proof4;

  /// No description provided for @pumpingChallenge7Proof5.
  ///
  /// In en, this message translates to:
  /// **'For s = a^p b^p, the same counterexample as before applies.'**
  String get pumpingChallenge7Proof5;

  /// No description provided for @pumpingChallenge8Description.
  ///
  /// In en, this message translates to:
  /// **'Palindromes over the alphabet a,b'**
  String get pumpingChallenge8Description;

  /// No description provided for @pumpingChallenge8Explanation.
  ///
  /// In en, this message translates to:
  /// **'Palindromes are not regular because they require unbounded memory to verify symmetry.'**
  String get pumpingChallenge8Explanation;

  /// No description provided for @pumpingChallenge8Hint.
  ///
  /// In en, this message translates to:
  /// **'Think about what happens to the center when you pump a long palindrome.'**
  String get pumpingChallenge8Hint;

  /// No description provided for @pumpingChallenge8Proof1.
  ///
  /// In en, this message translates to:
  /// **'Palindromes require checking that the string reads the same forwards and backwards.'**
  String get pumpingChallenge8Proof1;

  /// No description provided for @pumpingChallenge8Proof2.
  ///
  /// In en, this message translates to:
  /// **'For long palindromes, you need to remember the first half to compare with the second half.'**
  String get pumpingChallenge8Proof2;

  /// No description provided for @pumpingChallenge8Proof3.
  ///
  /// In en, this message translates to:
  /// **'Using the pumping lemma: for s = a^p b a^p, choose x = a^(p-1), y = a, z = b a^p.'**
  String get pumpingChallenge8Proof3;

  /// No description provided for @pumpingChallenge8Proof4.
  ///
  /// In en, this message translates to:
  /// **'Then xy^2z = a^(p+1) b a^p, which is not a palindrome.'**
  String get pumpingChallenge8Proof4;

  /// No description provided for @pumpingChallenge8Proof5.
  ///
  /// In en, this message translates to:
  /// **'The middle b is no longer centered properly.'**
  String get pumpingChallenge8Proof5;

  /// No description provided for @selectDfaForUnion.
  ///
  /// In en, this message translates to:
  /// **'Select DFA for union'**
  String get selectDfaForUnion;

  /// No description provided for @buildingUnionAutomaton.
  ///
  /// In en, this message translates to:
  /// **'Building union automaton...'**
  String get buildingUnionAutomaton;

  /// No description provided for @unionComplete.
  ///
  /// In en, this message translates to:
  /// **'Union complete'**
  String get unionComplete;

  /// No description provided for @loadDfaBeforeUnion.
  ///
  /// In en, this message translates to:
  /// **'Load a DFA before computing the union.'**
  String get loadDfaBeforeUnion;

  /// No description provided for @selectFsaForConcatenation.
  ///
  /// In en, this message translates to:
  /// **'Select FSA for concatenation'**
  String get selectFsaForConcatenation;

  /// No description provided for @buildingConcatenationNfa.
  ///
  /// In en, this message translates to:
  /// **'Building concatenation NFA...'**
  String get buildingConcatenationNfa;

  /// No description provided for @concatenationComplete.
  ///
  /// In en, this message translates to:
  /// **'Concatenation complete'**
  String get concatenationComplete;

  /// No description provided for @selectDfaForIntersection.
  ///
  /// In en, this message translates to:
  /// **'Select DFA for intersection'**
  String get selectDfaForIntersection;

  /// No description provided for @buildingIntersectionAutomaton.
  ///
  /// In en, this message translates to:
  /// **'Building intersection automaton...'**
  String get buildingIntersectionAutomaton;

  /// No description provided for @intersectionComplete.
  ///
  /// In en, this message translates to:
  /// **'Intersection complete'**
  String get intersectionComplete;

  /// No description provided for @loadDfaBeforeIntersection.
  ///
  /// In en, this message translates to:
  /// **'Load a DFA before computing the intersection.'**
  String get loadDfaBeforeIntersection;

  /// No description provided for @selectDfaForDifference.
  ///
  /// In en, this message translates to:
  /// **'Select DFA for difference'**
  String get selectDfaForDifference;

  /// No description provided for @buildingDifferenceAutomaton.
  ///
  /// In en, this message translates to:
  /// **'Building difference automaton...'**
  String get buildingDifferenceAutomaton;

  /// No description provided for @differenceComplete.
  ///
  /// In en, this message translates to:
  /// **'Difference complete'**
  String get differenceComplete;

  /// No description provided for @loadDfaBeforeDifference.
  ///
  /// In en, this message translates to:
  /// **'Load a DFA before computing the difference.'**
  String get loadDfaBeforeDifference;

  /// No description provided for @loadDfaBeforeExecuting.
  ///
  /// In en, this message translates to:
  /// **'Load a DFA before executing {algorithm}.'**
  String loadDfaBeforeExecuting(String algorithm);

  /// No description provided for @loadDfaBeforeComparingEquivalence.
  ///
  /// In en, this message translates to:
  /// **'Load a DFA before comparing equivalence.'**
  String get loadDfaBeforeComparingEquivalence;

  /// No description provided for @selectDfaToCompare.
  ///
  /// In en, this message translates to:
  /// **'Select DFA to compare'**
  String get selectDfaToCompare;

  /// No description provided for @loadingAutomatonEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Loading automaton...'**
  String get loadingAutomatonEllipsis;

  /// No description provided for @failedToLoadAutomatonStatus.
  ///
  /// In en, this message translates to:
  /// **'Failed to load automaton'**
  String get failedToLoadAutomatonStatus;

  /// No description provided for @selectedFileUnreadable.
  ///
  /// In en, this message translates to:
  /// **'Selected file did not contain readable data.'**
  String get selectedFileUnreadable;

  /// No description provided for @algorithmFailedStatus.
  ///
  /// In en, this message translates to:
  /// **'{algorithm} failed'**
  String algorithmFailedStatus(String algorithm);

  /// No description provided for @algorithmFailedError.
  ///
  /// In en, this message translates to:
  /// **'{algorithm} failed: {error}'**
  String algorithmFailedError(String algorithm, String error);

  /// No description provided for @comparingAutomata.
  ///
  /// In en, this message translates to:
  /// **'Comparing automata...'**
  String get comparingAutomata;

  /// No description provided for @languageComparisonTitle.
  ///
  /// In en, this message translates to:
  /// **'Language Comparison'**
  String get languageComparisonTitle;

  /// No description provided for @currentAutomatonTitle.
  ///
  /// In en, this message translates to:
  /// **'Current Automaton'**
  String get currentAutomatonTitle;

  /// No description provided for @comparedAutomatonTitle.
  ///
  /// In en, this message translates to:
  /// **'Compared Automaton'**
  String get comparedAutomatonTitle;

  /// No description provided for @grammarConvertedToAutomaton.
  ///
  /// In en, this message translates to:
  /// **'Grammar converted to automaton. Switched to FSA workspace.'**
  String get grammarConvertedToAutomaton;

  /// No description provided for @grammarConvertedToPdaGeneral.
  ///
  /// In en, this message translates to:
  /// **'Grammar converted to PDA (general). Switched to PDA workspace.'**
  String get grammarConvertedToPdaGeneral;

  /// No description provided for @grammarConvertedToPdaStandard.
  ///
  /// In en, this message translates to:
  /// **'Grammar converted to PDA (standard). Switched to PDA workspace.'**
  String get grammarConvertedToPdaStandard;

  /// No description provided for @grammarConvertedToPdaGreibach.
  ///
  /// In en, this message translates to:
  /// **'Grammar converted to PDA (Greibach). Switched to PDA workspace.'**
  String get grammarConvertedToPdaGreibach;

  /// No description provided for @failedToConvertGrammarToAutomaton.
  ///
  /// In en, this message translates to:
  /// **'Failed to convert grammar to automaton.'**
  String get failedToConvertGrammarToAutomaton;

  /// No description provided for @failedToConvertGrammarToPda.
  ///
  /// In en, this message translates to:
  /// **'Failed to convert grammar to PDA.'**
  String get failedToConvertGrammarToPda;

  /// No description provided for @originalGrammarLabel.
  ///
  /// In en, this message translates to:
  /// **'Original Grammar:'**
  String get originalGrammarLabel;

  /// No description provided for @transformedGrammarLabel.
  ///
  /// In en, this message translates to:
  /// **'Transformed Grammar:'**
  String get transformedGrammarLabel;

  /// No description provided for @notesSection.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesSection;

  /// No description provided for @derivationsSection.
  ///
  /// In en, this message translates to:
  /// **'Derivations'**
  String get derivationsSection;

  /// No description provided for @conflictsSection.
  ///
  /// In en, this message translates to:
  /// **'Conflicts'**
  String get conflictsSection;

  /// No description provided for @cnfConversionNote.
  ///
  /// In en, this message translates to:
  /// **'Converted grammar to Chomsky Normal Form (CNF) using a step pipeline.'**
  String get cnfConversionNote;

  /// No description provided for @cnfRulesNote.
  ///
  /// In en, this message translates to:
  /// **'CNF rules: A→BC (two nonterminals) or A→a (single terminal).'**
  String get cnfRulesNote;

  /// No description provided for @gnfConversionNote.
  ///
  /// In en, this message translates to:
  /// **'Converted grammar to Greibach Normal Form (GNF).'**
  String get gnfConversionNote;

  /// No description provided for @gnfRulesNote.
  ///
  /// In en, this message translates to:
  /// **'GNF rules: A→aα (terminal followed by nonterminals).'**
  String get gnfRulesNote;

  /// No description provided for @diagnosticsHeading.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics:'**
  String get diagnosticsHeading;

  /// No description provided for @cannotRunDueToValidation.
  ///
  /// In en, this message translates to:
  /// **'Cannot run {algorithm} due to grammar validation errors'**
  String cannotRunDueToValidation(String algorithm);

  /// No description provided for @ll1ParseTableAnalysis.
  ///
  /// In en, this message translates to:
  /// **'LL(1) Parse Table Analysis'**
  String get ll1ParseTableAnalysis;

  /// No description provided for @ll1NoConflicts.
  ///
  /// In en, this message translates to:
  /// **'LL(1) (no conflicts)'**
  String get ll1NoConflicts;

  /// No description provided for @notLl1Conflicts.
  ///
  /// In en, this message translates to:
  /// **'Not LL(1) (conflicts)'**
  String get notLl1Conflicts;

  /// No description provided for @ll1Classification.
  ///
  /// In en, this message translates to:
  /// **'LL(1) Classification'**
  String get ll1Classification;

  /// No description provided for @classificationLabel.
  ///
  /// In en, this message translates to:
  /// **'Classification: {status}'**
  String classificationLabel(String status);

  /// No description provided for @cnfConversionFailed.
  ///
  /// In en, this message translates to:
  /// **'CNF conversion failed.'**
  String get cnfConversionFailed;

  /// No description provided for @scoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Score: {score}'**
  String scoreLabel(int score);

  /// No description provided for @streakLabel.
  ///
  /// In en, this message translates to:
  /// **'Streak: {count}'**
  String streakLabel(int count);

  /// No description provided for @challengeProgress.
  ///
  /// In en, this message translates to:
  /// **'Challenge {current}/{total}'**
  String challengeProgress(int current, int total);

  /// No description provided for @finalScore.
  ///
  /// In en, this message translates to:
  /// **'Final Score'**
  String get finalScore;

  /// No description provided for @learningProgress.
  ///
  /// In en, this message translates to:
  /// **'Learning Progress:'**
  String get learningProgress;

  /// No description provided for @regularLanguagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Regular Languages'**
  String get regularLanguagesTitle;

  /// No description provided for @regularLanguagesProgressDesc.
  ///
  /// In en, this message translates to:
  /// **'You understand basic regular language patterns'**
  String get regularLanguagesProgressDesc;

  /// No description provided for @pumpingLemmaApplicationTitle.
  ///
  /// In en, this message translates to:
  /// **'Pumping Lemma Application'**
  String get pumpingLemmaApplicationTitle;

  /// No description provided for @pumpingLemmaApplicationDesc.
  ///
  /// In en, this message translates to:
  /// **'You can identify when languages are not regular'**
  String get pumpingLemmaApplicationDesc;

  /// No description provided for @advancedPatternsTitle.
  ///
  /// In en, this message translates to:
  /// **'Advanced Patterns'**
  String get advancedPatternsTitle;

  /// No description provided for @advancedPatternsProgressDesc.
  ///
  /// In en, this message translates to:
  /// **'You recognize complex non-regular languages'**
  String get advancedPatternsProgressDesc;

  /// No description provided for @pumpingPerformanceOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding! You have mastered the pumping lemma and can identify regular and non-regular languages with confidence. You understand the theoretical foundations and can apply the lemma correctly to prove non-regularity.'**
  String get pumpingPerformanceOutstanding;

  /// No description provided for @pumpingPerformanceExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent work! You have a strong understanding of the pumping lemma. You can correctly identify most regular and non-regular languages, and your application of the lemma is generally sound.'**
  String get pumpingPerformanceExcellent;

  /// No description provided for @pumpingPerformanceGood.
  ///
  /// In en, this message translates to:
  /// **'Good progress! You\'re developing a solid foundation in the pumping lemma. You can identify basic patterns and are learning to apply the lemma systematically. Keep practicing to strengthen your skills.'**
  String get pumpingPerformanceGood;

  /// No description provided for @pumpingPerformanceFirstSteps.
  ///
  /// In en, this message translates to:
  /// **'You\'re taking the first steps in understanding the pumping lemma. This is a challenging concept that requires practice. Focus on understanding the basic proof technique and identifying when languages require unbounded memory.'**
  String get pumpingPerformanceFirstSteps;

  /// No description provided for @pumpingDifficultyEasy.
  ///
  /// In en, this message translates to:
  /// **'EASY'**
  String get pumpingDifficultyEasy;

  /// No description provided for @pumpingDifficultyMedium.
  ///
  /// In en, this message translates to:
  /// **'MEDIUM'**
  String get pumpingDifficultyMedium;

  /// No description provided for @pumpingDifficultyHard.
  ///
  /// In en, this message translates to:
  /// **'HARD'**
  String get pumpingDifficultyHard;

  /// No description provided for @evaluatedOf.
  ///
  /// In en, this message translates to:
  /// **'Evaluated {evaluated} of {total}'**
  String evaluatedOf(int evaluated, int total);

  /// No description provided for @estimatedCandidatesInvalid.
  ///
  /// In en, this message translates to:
  /// **'Estimated candidates: invalid limits'**
  String get estimatedCandidatesInvalid;

  /// No description provided for @estimatedCandidatesScheduled.
  ///
  /// In en, this message translates to:
  /// **'Estimated candidates: {requested}; scheduled: {scheduled}'**
  String estimatedCandidatesScheduled(String requested, String scheduled);

  /// No description provided for @stepStateTitle.
  ///
  /// In en, this message translates to:
  /// **'Step {step} • {state}'**
  String stepStateTitle(int step, String state);

  /// No description provided for @headTapeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'head {head} • tape {tape}'**
  String headTapeSubtitle(int head, String tape);

  /// No description provided for @initialConfigurationAtHead.
  ///
  /// In en, this message translates to:
  /// **'Initial configuration at head {head}'**
  String initialConfigurationAtHead(int head);

  /// No description provided for @inputRetainedConfigurations.
  ///
  /// In en, this message translates to:
  /// **'Input {input} • {count} retained configuration(s)'**
  String inputRetainedConfigurations(String input, int count);

  /// No description provided for @words.
  ///
  /// In en, this message translates to:
  /// **'Words'**
  String get words;

  /// No description provided for @transitionsConfigurationsProgress.
  ///
  /// In en, this message translates to:
  /// **'{transitions} transition(s) • {configurations} configuration(s) explored'**
  String transitionsConfigurationsProgress(int transitions, int configurations);

  /// No description provided for @explorationCancelledKept.
  ///
  /// In en, this message translates to:
  /// **'Exploration cancelled. Evaluated results were kept.'**
  String get explorationCancelledKept;

  /// No description provided for @spaceProfilingCancelledKept.
  ///
  /// In en, this message translates to:
  /// **'Space profiling cancelled. Evaluated rows were kept.'**
  String get spaceProfilingCancelledKept;
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
