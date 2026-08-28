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
    Locale('pt'),
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

  /// Shared interface message used by workspace_helpers.dart.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 states} =1{1 state} other{{count} states}}'**
  String canvasViewportStateCount(int count);

  /// Shared interface message used by workspace_helpers.dart.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 transitions} =1{1 transition} other{{count} transitions}}'**
  String canvasViewportTransitionCount(int count);

  /// Shared interface message used by workspace_helpers.dart.
  ///
  /// In en, this message translates to:
  /// **'No automaton defined'**
  String get workspaceStatusNoAutomaton;

  /// Shared interface message used by workspace_helpers.dart.
  ///
  /// In en, this message translates to:
  /// **'Missing start state'**
  String get workspaceStatusMissingInitialState;

  /// Shared interface message used by workspace_helpers.dart.
  ///
  /// In en, this message translates to:
  /// **'No accepting states'**
  String get workspaceStatusNoAcceptingStates;

  /// Shared interface message used by workspace_helpers.dart.
  ///
  /// In en, this message translates to:
  /// **'Nondeterministic transitions'**
  String get workspaceStatusNondeterministic;

  /// Shared interface message used by workspace_helpers.dart.
  ///
  /// In en, this message translates to:
  /// **'ε-transitions present'**
  String get workspaceStatusLambdaTransitions;

  /// Shared interface message used by workspace_helpers.dart.
  ///
  /// In en, this message translates to:
  /// **'{states} · {transitions}'**
  String workspaceStatusCounts(String states, String transitions);

  /// Shared interface message used by workspace_helpers.dart.
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
    String id,
    String from,
    String to,
    String label,
  );

  /// Shared interface message used by automaton_graphview_canvas.dart.
  ///
  /// In en, this message translates to:
  /// **'Use keyboard shortcuts or toolbar controls to edit the canvas.'**
  String get canvasViewportEditHint;

  /// Shared interface message used by automaton_graphview_canvas.dart.
  ///
  /// In en, this message translates to:
  /// **'This canvas is read-only. Pan or zoom to inspect the automaton.'**
  String get canvasViewportReadOnlyHint;

  /// Shared interface message used by automaton_graphview_canvas.dart.
  ///
  /// In en, this message translates to:
  /// **'Activate to edit state details. Drag to move in selection mode.'**
  String get canvasStateEditHint;

  /// Shared interface message used by automaton_graphview_canvas.dart.
  ///
  /// In en, this message translates to:
  /// **'Read-only state.'**
  String get canvasStateReadOnlyHint;

  /// Shared interface message used by automaton_graphview_canvas.dart.
  ///
  /// In en, this message translates to:
  /// **'Add transition...'**
  String get canvasAddTransitionPrompt;

  /// Shared interface message used by automaton_graphview_canvas.dart.
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

  /// Shared interface message used by file_operations_panel_converters.dart.
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

  /// Shared interface message used by document_interoperability_failure_dialog.dart, error_banner.dart, and help_icon_mapper.dart.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Shared interface message used by conversion_replacement_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'Replace loaded result?'**
  String get conversionReplaceTitle;

  /// Shared interface message used by conversion_replacement_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get conversionReplaceCancel;

  /// Shared interface message used by conversion_replacement_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get conversionReplaceConfirm;

  /// Shared interface message used by conversion_replacement_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'An automaton is already loaded. Do you want to replace it?'**
  String get conversionReplaceAutomatonMessage;

  /// Shared interface message used by conversion_replacement_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'A grammar is already loaded. Do you want to replace it?'**
  String get conversionReplaceGrammarMessage;

  /// Shared interface message used by conversion_replacement_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'A pushdown automaton is already loaded. Do you want to replace it?'**
  String get conversionReplacePushdownAutomatonMessage;

  /// Shared interface message used by conversion_replacement_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'A Turing machine is already loaded. Do you want to replace it?'**
  String get conversionReplaceTuringMachineMessage;

  /// Shared interface message used by conversion_replacement_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'A regex is already loaded. Do you want to replace it?'**
  String get conversionReplaceRegexMessage;

  /// Shared interface message used by graphview_canvas_toolbar.dart.
  ///
  /// In en, this message translates to:
  /// **'Canvas action: {action}'**
  String canvasActionSemantics(String action);

  /// Shared interface message used by graphview_canvas_toolbar.dart.
  ///
  /// In en, this message translates to:
  /// **'Canvas action: {action}. Destructive action.'**
  String canvasDestructiveActionSemantics(String action);

  /// Shared interface message used by graphview_canvas_toolbar.dart.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get canvasSelectAction;

  /// Shared interface message used by graphview_canvas_toolbar.dart.
  ///
  /// In en, this message translates to:
  /// **'Add state'**
  String get canvasAddStateAction;

  /// Shared interface message used by graphview_canvas_toolbar.dart.
  ///
  /// In en, this message translates to:
  /// **'Add transition'**
  String get canvasAddTransitionAction;

  /// Shared interface message used by graphview_canvas_toolbar.dart.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get canvasUndoAction;

  /// Shared interface message used by graphview_canvas_toolbar.dart.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get canvasRedoAction;

  /// Shared interface message used by graphview_canvas_toolbar.dart.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get canvasZoomOutAction;

  /// Shared interface message used by graphview_canvas_toolbar.dart.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get canvasZoomInAction;

  /// Shared interface message used by graphview_canvas_toolbar.dart.
  ///
  /// In en, this message translates to:
  /// **'Fit to content'**
  String get canvasFitToContentAction;

  /// Shared interface message used by graphview_canvas_toolbar.dart.
  ///
  /// In en, this message translates to:
  /// **'Reset view'**
  String get canvasResetViewAction;

  /// Document action that opens the transactional automaton layout preview.
  ///
  /// In en, this message translates to:
  /// **'Arrange automaton states'**
  String get canvasArrangeAutomatonAction;

  /// Document action that previews and combines a compatible automaton.
  ///
  /// In en, this message translates to:
  /// **'Import automaton'**
  String get canvasImportAutomatonAction;

  /// Document action that opens the note manager.
  ///
  /// In en, this message translates to:
  /// **'Document notes'**
  String get canvasDocumentNotesAction;

  /// Shared interface message used by graphview_canvas_toolbar.dart.
  ///
  /// In en, this message translates to:
  /// **'Clear canvas'**
  String get canvasClearAction;

  /// No description provided for @canvasHelpAction.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get canvasHelpAction;

  /// Shared interface message used by graphview_canvas_toolbar.dart.
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

  /// Shared interface message used by graphview_canvas_toolbar.dart.
  ///
  /// In en, this message translates to:
  /// **'More canvas actions'**
  String get canvasMoreActions;

  /// Shared interface message used by graphview_canvas_toolbar.dart.
  ///
  /// In en, this message translates to:
  /// **'Zoom {percent}%'**
  String canvasZoomLevel(int percent);

  /// Shared interface message used by graphview_canvas_toolbar.dart.
  ///
  /// In en, this message translates to:
  /// **'Activates selection mode for moving and editing states.'**
  String get canvasSelectHint;

  /// Shared interface message used by graphview_canvas_toolbar.dart.
  ///
  /// In en, this message translates to:
  /// **'Toggles Add State mode; tap the canvas to place a state.'**
  String get canvasAddStateHint;

  /// Shared interface message used by graphview_canvas_toolbar.dart.
  ///
  /// In en, this message translates to:
  /// **'Activates transition mode to connect two states.'**
  String get canvasAddTransitionHint;

  /// Shared interface message used by graphview_canvas_toolbar.dart.
  ///
  /// In en, this message translates to:
  /// **'Reverts the most recent canvas change.'**
  String get canvasUndoHint;

  /// Shared interface message used by graphview_canvas_toolbar.dart.
  ///
  /// In en, this message translates to:
  /// **'Restores the most recently undone canvas change.'**
  String get canvasRedoHint;

  /// Shared interface message used by graphview_canvas_toolbar.dart.
  ///
  /// In en, this message translates to:
  /// **'Decreases the canvas zoom level.'**
  String get canvasZoomOutHint;

  /// Shared interface message used by graphview_canvas_toolbar.dart.
  ///
  /// In en, this message translates to:
  /// **'Increases the canvas zoom level.'**
  String get canvasZoomInHint;

  /// Shared interface message used by graphview_canvas_toolbar.dart.
  ///
  /// In en, this message translates to:
  /// **'Zooms and pans to show the full automaton.'**
  String get canvasFitToContentHint;

  /// Shared interface message used by graphview_canvas_toolbar.dart.
  ///
  /// In en, this message translates to:
  /// **'Resets the canvas zoom and pan position.'**
  String get canvasResetViewHint;

  /// Accessibility hint for the arrange automaton action.
  ///
  /// In en, this message translates to:
  /// **'Previews a layout before applying it to this automaton.'**
  String get canvasArrangeAutomatonHint;

  /// Accessibility hint for the automaton import action.
  ///
  /// In en, this message translates to:
  /// **'Previews and combines a compatible automaton with this document.'**
  String get canvasImportAutomatonHint;

  /// Accessibility hint for the document notes action.
  ///
  /// In en, this message translates to:
  /// **'Opens the notes for this document.'**
  String get canvasDocumentNotesHint;

  /// Shared interface message used by graphview_canvas_toolbar.dart.
  ///
  /// In en, this message translates to:
  /// **'Removes all states and transitions from the canvas.'**
  String get canvasClearHint;

  /// Shared interface message used by graphview_canvas_toolbar.dart.
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

  /// Shared interface message used by graphview_canvas_toolbar.dart.
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
  /// **'ε-input'**
  String get pdaLambdaInput;

  /// No description provided for @pdaInputSymbolRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a symbol or enable ε-input'**
  String get pdaInputSymbolRequired;

  /// No description provided for @pdaPopSymbol.
  ///
  /// In en, this message translates to:
  /// **'Pop symbol'**
  String get pdaPopSymbol;

  /// No description provided for @pdaLambdaPop.
  ///
  /// In en, this message translates to:
  /// **'ε-pop'**
  String get pdaLambdaPop;

  /// No description provided for @pdaPopSymbolRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a symbol or enable ε-pop'**
  String get pdaPopSymbolRequired;

  /// No description provided for @pdaPushSymbol.
  ///
  /// In en, this message translates to:
  /// **'Push symbol'**
  String get pdaPushSymbol;

  /// No description provided for @pdaLambdaPush.
  ///
  /// In en, this message translates to:
  /// **'ε-push'**
  String get pdaLambdaPush;

  /// No description provided for @pdaPushSymbolRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a symbol or enable ε-push'**
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

  /// Title for the combined algorithms and examples surface.
  ///
  /// In en, this message translates to:
  /// **'Algorithms & Examples'**
  String get algorithmsAndExamples;

  /// Shared interface message used by settings_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsPageTitle;

  /// Shared interface message used by settings_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get settingsSaveTooltip;

  /// Shared interface message used by settings_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Reset to Defaults'**
  String get settingsResetTooltip;

  /// Shared interface message used by settings_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Failed to load settings. Please try again.'**
  String get settingsLoadError;

  /// Shared interface message used by settings_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Settings saved.'**
  String get settingsSaveSuccess;

  /// Shared interface message used by settings_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Failed to save settings. Please try again.'**
  String get settingsSaveError;

  /// Shared interface message used by settings_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Settings were saved, but could not be applied. Restart Turing Lab to refresh them.'**
  String get settingsApplyError;

  /// Shared interface message used by settings_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Settings reset to defaults.'**
  String get settingsResetSuccess;

  /// Shared interface message used by settings_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsSectionTheme;

  /// Shared interface message used by settings_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsSectionLanguage;

  /// Shared interface message used by settings_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Canvas'**
  String get settingsSectionCanvas;

  /// Shared interface message used by settings_page.dart.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsSectionGeneral;

  /// Shared interface message used by settings_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get settingsSectionActions;

  /// Shared interface message used by settings_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get settingsThemeModeTitle;

  /// Shared interface message used by settings_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred theme'**
  String get settingsThemeModeDescription;

  /// Shared interface message used by settings_page.dart.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// Shared interface message used by settings_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// Shared interface message used by settings_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// Shared interface message used by settings_page.dart.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get settingsLanguageTitle;

  /// Shared interface message used by settings_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Choose the language used by Turing Lab'**
  String get settingsLanguageDescription;

  /// Shared interface message used by settings_page.dart.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// Shared interface message used by settings_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Português'**
  String get settingsLanguagePortuguese;

  /// Shared interface message used by settings_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Show Grid'**
  String get settingsShowGridTitle;

  /// Shared interface message used by settings_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Display grid lines on canvas'**
  String get settingsShowGridDescription;

  /// Shared interface message used by settings_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Show Coordinates'**
  String get settingsShowCoordinatesTitle;

  /// Shared interface message used by settings_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Display coordinate information'**
  String get settingsShowCoordinatesDescription;

  /// Shared interface message used by settings_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Grid Size'**
  String get settingsGridSizeTitle;

  /// Shared interface message used by settings_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Size of grid cells'**
  String get settingsGridSizeDescription;

  /// Shared interface message used by settings_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Node Size'**
  String get settingsNodeSizeTitle;

  /// Shared interface message used by settings_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Size of automaton nodes'**
  String get settingsNodeSizeDescription;

  /// Shared interface message used by settings_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get settingsFontSizeTitle;

  /// Shared interface message used by settings_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Text size in the interface'**
  String get settingsFontSizeDescription;

  /// Shared interface message used by settings_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Auto Save'**
  String get settingsAutoSaveTitle;

  /// Shared interface message used by settings_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Automatically save changes'**
  String get settingsAutoSaveDescription;

  /// Shared interface message used by settings_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Show Tooltips'**
  String get settingsShowTooltipsTitle;

  /// Shared interface message used by settings_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Display helpful tooltips'**
  String get settingsShowTooltipsDescription;

  /// Shared interface message used by settings_page.dart.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsSectionAbout;

  /// Shared interface message used by settings_page.dart.
  ///
  /// In en, this message translates to:
  /// **'About Turing Lab'**
  String get settingsAboutTileTitle;

  /// Shared interface message used by settings_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Product overview, platforms, and credits'**
  String get settingsAboutTileSubtitle;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'About Turing Lab'**
  String get aboutPageTitle;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Formal languages and automata'**
  String get aboutEyebrow;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'A Flutter-based toolkit for constructing, transforming, and simulating formal language models.'**
  String get aboutLead;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'It provides dedicated workspaces for finite-state automata, context-free grammars, pushdown automata, Turing machines, regular expressions, and pumping lemma exercises.'**
  String get aboutDetail;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Development status: Apple and Android builds are currently under testing.'**
  String get aboutDevelopmentStatus;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'View source'**
  String get aboutViewSource;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Read documentation'**
  String get aboutReadDocumentation;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Report an issue'**
  String get aboutReportIssue;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Supported models and workflows'**
  String get aboutCapabilitiesTitle;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'The current scope is organized around six independent workspaces. File support and transformations vary by model.'**
  String get aboutCapabilitiesIntro;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Editing'**
  String get aboutCapabilityEditing;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Simulation'**
  String get aboutCapabilitySimulation;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Transformations'**
  String get aboutCapabilityTransformations;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Import/export'**
  String get aboutCapabilityImportExport;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Finite-state automata'**
  String get aboutWorkspaceFsa;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'State and transition canvas'**
  String get aboutWorkspaceFsaEditing;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Step-by-step acceptance traces'**
  String get aboutWorkspaceFsaSimulation;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'NFA/DFA/regex conversion and DFA minimisation'**
  String get aboutWorkspaceFsaTransformations;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'JFLAP XML, JSON, SVG, and native PNG'**
  String get aboutWorkspaceFsaFiles;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Context-free grammars'**
  String get aboutWorkspaceGrammar;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Grammar and production editor'**
  String get aboutWorkspaceGrammarEditing;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Parsing and validation'**
  String get aboutWorkspaceGrammarSimulation;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'FIRST/FOLLOW analysis, LL(1) diagnostics, and CNF conversion'**
  String get aboutWorkspaceGrammarTransformations;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'JFLAP grammar and SVG'**
  String get aboutWorkspaceGrammarFiles;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Pushdown automata'**
  String get aboutWorkspacePda;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'State and transition canvas'**
  String get aboutWorkspacePdaEditing;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Input and stack traces'**
  String get aboutWorkspacePdaSimulation;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Not applicable'**
  String get aboutWorkspacePdaTransformations;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'SVG export'**
  String get aboutWorkspacePdaFiles;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Turing machines'**
  String get aboutWorkspaceTm;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'State and transition canvas'**
  String get aboutWorkspaceTmEditing;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Tape and transition traces'**
  String get aboutWorkspaceTmSimulation;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Not applicable'**
  String get aboutWorkspaceTmTransformations;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'SVG export'**
  String get aboutWorkspaceTmFiles;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Regular expressions'**
  String get aboutWorkspaceRegex;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Expression editor'**
  String get aboutWorkspaceRegexEditing;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Match testing and comparison'**
  String get aboutWorkspaceRegexSimulation;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Simplification and automaton conversion'**
  String get aboutWorkspaceRegexTransformations;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Not applicable'**
  String get aboutWorkspaceRegexFiles;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Pumping lemma'**
  String get aboutWorkspacePumping;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Guided case workflow'**
  String get aboutWorkspacePumpingEditing;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Decomposition validation'**
  String get aboutWorkspacePumpingSimulation;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Not applicable'**
  String get aboutWorkspacePumpingTransformations;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Not applicable'**
  String get aboutWorkspacePumpingFiles;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Finite automata'**
  String get aboutFiniteAutomataTitle;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Finite-state workflows include conversion between nondeterministic and deterministic automata, regular-expression conversion, DFA minimisation, and acceptance traces.'**
  String get aboutFiniteAutomataBody;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Grammar analysis'**
  String get aboutGrammarAnalysisTitle;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Grammar tooling provides parsing diagnostics, FIRST and FOLLOW sets, LL(1) conflict reporting, and a best-effort Chomsky normal form pipeline.'**
  String get aboutGrammarAnalysisBody;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Execution traces'**
  String get aboutExecutionTracesTitle;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'FSA, PDA, and TM simulations expose intermediate configurations through state, transition, stack, or tape traces appropriate to each model.'**
  String get aboutExecutionTracesBody;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Local execution and bounded file compatibility'**
  String get aboutFormatsTitle;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Turing Lab does not require an account or a developer-operated backend. Editing, simulation, diagnostics, and bundled examples run locally.'**
  String get aboutFormatsIntro;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'FSA: JFLAP XML and JSON import/export, SVG export, and PNG export on native platforms.'**
  String get aboutFormatFsa;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Grammar: JFLAP grammar import/export and SVG export.'**
  String get aboutFormatGrammar;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'PDA: SVG export. TM: JFLAP XML and JSON import/export plus SVG export.'**
  String get aboutFormatPdaTm;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Web limitation: PNG export is unavailable in web builds.'**
  String get aboutFormatWebLimitation;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Current validation status'**
  String get aboutPlatformsTitle;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Testing builds are undergoing platform validation and release preparation. Experimental targets may have incomplete platform integration and are not part of the current release scope.'**
  String get aboutPlatformsIntro;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Testing'**
  String get aboutStatusTesting;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Experimental'**
  String get aboutStatusExperimental;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'iOS and iPadOS'**
  String get aboutPlatformIos;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'macOS'**
  String get aboutPlatformMacos;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Android'**
  String get aboutPlatformAndroid;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Web'**
  String get aboutPlatformWeb;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Windows'**
  String get aboutPlatformWindows;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Linux'**
  String get aboutPlatformLinux;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Application workspaces'**
  String get aboutScreenshotsTitle;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Captured from controlled mobile and tablet testing configurations.'**
  String get aboutScreenshotsIntro;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Finite-state automata. Automaton canvas, simulation result, and step-by-step trace.'**
  String get aboutScreenshotFsa;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Context-free grammars. Production editing and grammar transformations.'**
  String get aboutScreenshotGrammar;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Turing machines. Tape simulation, transition editing, and machine-specific analysis.'**
  String get aboutScreenshotTm;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Turing Lab is inspired by the original JFLAP project. Turing Lab is not affiliated with, endorsed by, or an official release of JFLAP, Duke University, or Susan H. Rodger.'**
  String get aboutAttribution;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get aboutOpenLicenses;

  /// Shared interface message used by about_page.dart.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get aboutOpenPrivacy;

  /// Shared interface message used by about_page.dart.
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

  /// Navigation label for the regular pumping lemma workspace.
  ///
  /// In en, this message translates to:
  /// **'Regular pumping'**
  String get homeNavigationRegularPumpingLabel;

  /// Short navigation description for the regular pumping lemma workspace.
  ///
  /// In en, this message translates to:
  /// **'Regular pumping lemma'**
  String get homeNavigationRegularPumpingDescription;

  /// Navigation label for the context-free pumping lemma workspace.
  ///
  /// In en, this message translates to:
  /// **'Context-free pumping'**
  String get homeNavigationContextFreePumpingLabel;

  /// Short navigation description for the context-free pumping lemma workspace.
  ///
  /// In en, this message translates to:
  /// **'Context-free pumping lemma'**
  String get homeNavigationContextFreePumpingDescription;

  /// Heading on the compatibility chooser for the former single pumping lemma route.
  ///
  /// In en, this message translates to:
  /// **'Choose a pumping lemma environment'**
  String get choosePumpingLemmaEnvironment;

  /// Explanation on the pumping lemma environment chooser.
  ///
  /// In en, this message translates to:
  /// **'Regular and context-free pumping lemmas have different decompositions and proof obligations.'**
  String get choosePumpingLemmaEnvironmentDescription;

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

  /// Title of the regex batch testing section.
  ///
  /// In en, this message translates to:
  /// **'Batch testing'**
  String get regexBatchTestingTitle;

  /// Subtitle of the regex batch testing section.
  ///
  /// In en, this message translates to:
  /// **'Match ordered, bounded input cases'**
  String get regexBatchTestingSubtitle;

  /// Title of the regex batch execution panel.
  ///
  /// In en, this message translates to:
  /// **'Regex batch execution'**
  String get regexBatchExecutionTitle;

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

  /// Shared interface message used by automaton_workspace_scaffold.dart and workspace_quick_actions_provider.dart.
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

  /// Shared interface message used by default_workspace_presentation_modules.dart and workspace_quick_actions_provider.dart.
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

  /// Shared interface message used by step_navigation_controls.dart.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// Shared interface message used by step_navigation_controls.dart.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// Shared interface message used by base_trace_viewer.dart.
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

  /// Locale-formatted simulation step label.
  ///
  /// In en, this message translates to:
  /// **'Step {step}'**
  String stepNumber(int step);

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

  /// Shared interface message used by conversion_replacement_dialog.dart and file_operations_panel_converters.dart.
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

  /// Accessible label for the playback speed slider.
  ///
  /// In en, this message translates to:
  /// **'Select playback speed'**
  String get selectPlaybackSpeed;

  /// Shared interface message used by step_navigation_controls.dart.
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

  /// Locale-formatted playback speed followed by the multiplier unit.
  ///
  /// In en, this message translates to:
  /// **'{speed}x'**
  String playbackSpeedMultiplier(String speed);

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
    String consumed,
    String state,
    String nextState,
    String remaining,
  );

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

  /// No description provided for @pdaAcceptanceModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Acceptance mode'**
  String get pdaAcceptanceModeTitle;

  /// No description provided for @pdaAcceptanceFinalStateExplanation.
  ///
  /// In en, this message translates to:
  /// **'The complete input must end in an accepting state. The stack may still contain symbols.'**
  String get pdaAcceptanceFinalStateExplanation;

  /// No description provided for @pdaAcceptanceEmptyStackExplanation.
  ///
  /// In en, this message translates to:
  /// **'The complete input must leave the stack empty. The current state does not need to be accepting.'**
  String get pdaAcceptanceEmptyStackExplanation;

  /// No description provided for @pdaAcceptanceBothExplanation.
  ///
  /// In en, this message translates to:
  /// **'The complete input must end in an accepting state with an empty stack.'**
  String get pdaAcceptanceBothExplanation;

  /// No description provided for @pdaAcceptanceFinalStateCompactExplanation.
  ///
  /// In en, this message translates to:
  /// **'Input consumed; stack ignored.'**
  String get pdaAcceptanceFinalStateCompactExplanation;

  /// No description provided for @pdaAcceptanceEmptyStackCompactExplanation.
  ///
  /// In en, this message translates to:
  /// **'Input consumed; final state ignored.'**
  String get pdaAcceptanceEmptyStackCompactExplanation;

  /// No description provided for @pdaAcceptanceBothCompactExplanation.
  ///
  /// In en, this message translates to:
  /// **'Input consumed; both conditions required.'**
  String get pdaAcceptanceBothCompactExplanation;

  /// No description provided for @executing.
  ///
  /// In en, this message translates to:
  /// **'Executing'**
  String get executing;

  /// Shared interface message used by workspace_dock.dart.
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

  /// Shared interface message used by error_banner.dart.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// Shared interface message used by error_banner.dart.
  ///
  /// In en, this message translates to:
  /// **'Dismiss message'**
  String get dismissMessage;

  /// Shared interface message used by automaton_graphview_canvas.dart, document_interoperability_review_dialog.dart, and import_error_dialog.dart.
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

  /// Shared interface message used by error_banner.dart.
  ///
  /// In en, this message translates to:
  /// **'Success banner'**
  String get successBannerSemantics;

  /// Shared interface message used by error_banner.dart.
  ///
  /// In en, this message translates to:
  /// **'Error banner'**
  String get errorBannerSemantics;

  /// Shared interface message used by error_banner.dart.
  ///
  /// In en, this message translates to:
  /// **'Warning banner'**
  String get warningBannerSemantics;

  /// Shared interface message used by error_banner.dart.
  ///
  /// In en, this message translates to:
  /// **'Info banner'**
  String get infoBannerSemantics;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Shared interface message used by default_workspace_presentation_modules.dart, help_icon_mapper.dart, and workspace_quick_actions_bar.dart.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Shared interface message used by automaton_graphview_canvas.dart.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Shared interface message used by graphview_canvas_toolbar.dart, help_search_highlight.dart, and help_tree_view.dart.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// Shared interface message used by automaton_graphview_canvas.dart and graphview_canvas_toolbar.dart.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// Shared interface message used by file_operations_panel_visual_export.dart and file_operations_panel.dart.
  ///
  /// In en, this message translates to:
  /// **'File Operations'**
  String get fileOperationsTitle;

  /// Shared interface message used by file_operations_panel_fsa_actions.dart and file_operations_panel.dart.
  ///
  /// In en, this message translates to:
  /// **'FSA'**
  String get fileSectionFsa;

  /// Shared interface message used by file_operations_panel.dart.
  ///
  /// In en, this message translates to:
  /// **'Grammar'**
  String get fileSectionGrammar;

  /// Shared interface message used by file_operations_panel.dart.
  ///
  /// In en, this message translates to:
  /// **'PDA'**
  String get fileSectionPda;

  /// Shared interface message used by file_operations_panel.dart.
  ///
  /// In en, this message translates to:
  /// **'Turing Machine'**
  String get fileSectionTm;

  /// No description provided for @fileSectionRegex.
  ///
  /// In en, this message translates to:
  /// **'Regular expression'**
  String get fileSectionRegex;

  /// No description provided for @regexDocumentDialect.
  ///
  /// In en, this message translates to:
  /// **'Dialect'**
  String get regexDocumentDialect;

  /// No description provided for @regexDocumentDialectTuringLab.
  ///
  /// In en, this message translates to:
  /// **'Turing Lab v1'**
  String get regexDocumentDialectTuringLab;

  /// No description provided for @regexDocumentTokenization.
  ///
  /// In en, this message translates to:
  /// **'Tokenization'**
  String get regexDocumentTokenization;

  /// No description provided for @regexDocumentTokenizationUnicodeScalar.
  ///
  /// In en, this message translates to:
  /// **'Unicode scalar values'**
  String get regexDocumentTokenizationUnicodeScalar;

  /// Shared interface message used by file_operations_panel.dart.
  ///
  /// In en, this message translates to:
  /// **'Save as JFLAP'**
  String get saveAsJflap;

  /// Shared interface message used by file_operations_panel.dart.
  ///
  /// In en, this message translates to:
  /// **'Download JFLAP'**
  String get downloadJflap;

  /// Shared interface message used by file_operations_panel.dart.
  ///
  /// In en, this message translates to:
  /// **'Load JFLAP'**
  String get loadJflap;

  /// Shared interface message used by file_operations_panel.dart.
  ///
  /// In en, this message translates to:
  /// **'Save as JSON'**
  String get saveAsJson;

  /// Shared interface message used by file_operations_panel.dart.
  ///
  /// In en, this message translates to:
  /// **'Download JSON'**
  String get downloadJson;

  /// Shared interface message used by file_operations_panel.dart.
  ///
  /// In en, this message translates to:
  /// **'Load JSON'**
  String get loadJson;

  /// Shared interface message used by file_operations_panel.dart.
  ///
  /// In en, this message translates to:
  /// **'Export SVG'**
  String get exportSvg;

  /// Shared interface message used by file_operations_panel.dart.
  ///
  /// In en, this message translates to:
  /// **'Download SVG'**
  String get downloadSvg;

  /// Shared interface message used by file_operations_panel.dart.
  ///
  /// In en, this message translates to:
  /// **'Export PNG'**
  String get exportPng;

  /// Shared interface message used by file_operations_panel_converters.dart.
  ///
  /// In en, this message translates to:
  /// **'Turing Lab could not access the selected JSON file data. Pick the file again and keep it available until the import finishes.'**
  String get jsonUnreadableFileMessage;

  /// Shared interface message used by file_operations_panel_fsa_actions.dart.
  ///
  /// In en, this message translates to:
  /// **'Save Automaton as JFLAP'**
  String get saveAutomatonAsJflap;

  /// Shared interface message used by file_operations_panel_fsa_actions.dart.
  ///
  /// In en, this message translates to:
  /// **'Save Automaton as JSON'**
  String get saveAutomatonAsJson;

  /// Shared interface message used by file_operations_panel_fsa_actions.dart.
  ///
  /// In en, this message translates to:
  /// **'Load JFLAP Automaton'**
  String get loadJflapAutomaton;

  /// Shared interface message used by file_operations_panel_fsa_actions.dart.
  ///
  /// In en, this message translates to:
  /// **'Load Automaton JSON'**
  String get loadAutomatonJson;

  /// Shared interface message used by file_operations_panel_fsa_actions.dart.
  ///
  /// In en, this message translates to:
  /// **'Export Automaton as SVG'**
  String get exportAutomatonAsSvg;

  /// Shared interface message used by file_operations_panel_fsa_actions.dart.
  ///
  /// In en, this message translates to:
  /// **'Export Automaton as PNG'**
  String get exportAutomatonAsPng;

  /// Shared interface message used by file_operations_panel_machine_actions.dart.
  ///
  /// In en, this message translates to:
  /// **'Save Grammar as JFLAP'**
  String get saveGrammarAsJflap;

  /// Shared interface message used by file_operations_panel_machine_actions.dart.
  ///
  /// In en, this message translates to:
  /// **'Load JFLAP Grammar'**
  String get loadJflapGrammar;

  /// Shared interface message used by file_operations_panel_machine_actions.dart.
  ///
  /// In en, this message translates to:
  /// **'Export Grammar as SVG'**
  String get exportGrammarAsSvg;

  /// Shared interface message used by file_operations_panel_machine_actions.dart.
  ///
  /// In en, this message translates to:
  /// **'Export PDA as SVG'**
  String get exportPdaAsSvg;

  /// Shared interface message used by file_operations_panel_machine_actions.dart.
  ///
  /// In en, this message translates to:
  /// **'Export Turing Machine as SVG'**
  String get exportTmAsSvg;

  /// Shared interface message used by file_operations_panel_fsa_actions.dart.
  ///
  /// In en, this message translates to:
  /// **'Automaton saved successfully'**
  String get automatonSavedSuccessfully;

  /// Shared interface message used by file_operations_panel_fsa_actions.dart.
  ///
  /// In en, this message translates to:
  /// **'Automaton loaded successfully'**
  String get automatonLoadedSuccessfully;

  /// Shared interface message used by file_operations_panel_fsa_actions.dart.
  ///
  /// In en, this message translates to:
  /// **'Automaton exported successfully'**
  String get automatonExportedSuccessfully;

  /// Shared interface message used by file_operations_panel_machine_actions.dart.
  ///
  /// In en, this message translates to:
  /// **'Grammar saved successfully'**
  String get grammarSavedSuccessfully;

  /// Shared interface message used by file_operations_panel_machine_actions.dart.
  ///
  /// In en, this message translates to:
  /// **'Grammar loaded successfully'**
  String get grammarLoadedSuccessfully;

  /// Shared interface message used by file_operations_panel_machine_actions.dart.
  ///
  /// In en, this message translates to:
  /// **'Grammar exported successfully'**
  String get grammarExportedSuccessfully;

  /// Shared interface message used by file_operations_panel_machine_actions.dart.
  ///
  /// In en, this message translates to:
  /// **'PDA exported successfully'**
  String get pdaExportedSuccessfully;

  /// Shared interface message used by file_operations_panel_machine_actions.dart.
  ///
  /// In en, this message translates to:
  /// **'Turing machine exported successfully'**
  String get tmExportedSuccessfully;

  /// Shared interface message used by file_operations_panel_machine_actions.dart and file_operations_panel_picker_helpers.dart.
  ///
  /// In en, this message translates to:
  /// **'Save canceled.'**
  String get saveCanceled;

  /// Shared interface message used by file_operations_panel_fsa_actions.dart, file_operations_panel_interoperability.dart, and file_operations_panel_machine_actions.dart.
  ///
  /// In en, this message translates to:
  /// **'Export canceled.'**
  String get exportCanceled;

  /// Shared interface message used by file_operations_panel_fsa_actions.dart, file_operations_panel_interoperability.dart, and file_operations_panel_machine_actions.dart.
  ///
  /// In en, this message translates to:
  /// **'Import canceled.'**
  String get importCanceled;

  /// Shared interface message used by file_operations_panel_fsa_actions.dart and file_operations_panel_machine_actions.dart.
  ///
  /// In en, this message translates to:
  /// **'Download started for {fileName}'**
  String downloadStartedFor(String fileName);

  /// Shared interface message used by file_operations_panel_fsa_actions.dart.
  ///
  /// In en, this message translates to:
  /// **'Failed to save automaton: {error}'**
  String failedToSaveAutomaton(String error);

  /// Shared interface message used by file_operations_panel_fsa_actions.dart.
  ///
  /// In en, this message translates to:
  /// **'Error saving automaton: {error}'**
  String errorSavingAutomaton(String error);

  /// Shared interface message used by file_operations_panel_fsa_actions.dart.
  ///
  /// In en, this message translates to:
  /// **'Error loading automaton: {error}'**
  String errorLoadingAutomaton(String error);

  /// Shared interface message used by file_operations_panel_fsa_actions.dart.
  ///
  /// In en, this message translates to:
  /// **'Failed to export automaton: {error}'**
  String failedToExportAutomaton(String error);

  /// Shared interface message used by file_operations_panel_fsa_actions.dart.
  ///
  /// In en, this message translates to:
  /// **'Error exporting automaton: {error}'**
  String errorExportingAutomaton(String error);

  /// Shared interface message used by file_operations_panel_fsa_actions.dart.
  ///
  /// In en, this message translates to:
  /// **'Failed to save automaton JSON: {error}'**
  String failedToSaveAutomatonJson(String error);

  /// Shared interface message used by file_operations_panel_fsa_actions.dart.
  ///
  /// In en, this message translates to:
  /// **'Error saving automaton JSON: {error}'**
  String errorSavingAutomatonJson(String error);

  /// Shared interface message used by file_operations_panel_fsa_actions.dart.
  ///
  /// In en, this message translates to:
  /// **'Error loading automaton JSON: {error}'**
  String errorLoadingAutomatonJson(String error);

  /// Shared interface message used by file_operations_panel_fsa_actions.dart.
  ///
  /// In en, this message translates to:
  /// **'Failed to export automaton PNG: {error}'**
  String failedToExportAutomatonPng(String error);

  /// Shared interface message used by file_operations_panel_fsa_actions.dart.
  ///
  /// In en, this message translates to:
  /// **'Error exporting automaton PNG: {error}'**
  String errorExportingAutomatonPng(String error);

  /// Shared interface message used by file_operations_panel_machine_actions.dart.
  ///
  /// In en, this message translates to:
  /// **'Failed to save grammar: {error}'**
  String failedToSaveGrammar(String error);

  /// Shared interface message used by file_operations_panel_machine_actions.dart.
  ///
  /// In en, this message translates to:
  /// **'Error saving grammar: {error}'**
  String errorSavingGrammar(String error);

  /// Shared interface message used by file_operations_panel_machine_actions.dart.
  ///
  /// In en, this message translates to:
  /// **'Error loading grammar: {error}'**
  String errorLoadingGrammar(String error);

  /// Shared interface message used by file_operations_panel_machine_actions.dart.
  ///
  /// In en, this message translates to:
  /// **'Failed to export grammar: {error}'**
  String failedToExportGrammar(String error);

  /// Shared interface message used by file_operations_panel_machine_actions.dart.
  ///
  /// In en, this message translates to:
  /// **'Error exporting grammar: {error}'**
  String errorExportingGrammar(String error);

  /// Shared interface message used by file_operations_panel_machine_actions.dart.
  ///
  /// In en, this message translates to:
  /// **'Failed to export PDA: {error}'**
  String failedToExportPda(String error);

  /// Shared interface message used by file_operations_panel_machine_actions.dart.
  ///
  /// In en, this message translates to:
  /// **'Error exporting PDA: {error}'**
  String errorExportingPda(String error);

  /// Shared interface message used by file_operations_panel_machine_actions.dart.
  ///
  /// In en, this message translates to:
  /// **'Failed to export Turing machine: {error}'**
  String failedToExportTm(String error);

  /// Shared interface message used by file_operations_panel_machine_actions.dart.
  ///
  /// In en, this message translates to:
  /// **'Error exporting Turing machine: {error}'**
  String errorExportingTm(String error);

  /// Shared interface message used by import_error_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'Import error dialog'**
  String get importErrorDialogSemantics;

  /// Shared interface message used by import_error_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'Cancel import'**
  String get cancelImport;

  /// Shared interface message used by import_error_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'Malformed JFLAP File'**
  String get importErrorMalformedJff;

  /// Shared interface message used by import_error_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'Invalid JSON Structure'**
  String get importErrorInvalidJson;

  /// Shared interface message used by import_error_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'Unsupported File Version'**
  String get importErrorUnsupportedVersion;

  /// Shared interface message used by import_error_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'File Access Unavailable'**
  String get importErrorInaccessibleFile;

  /// Shared interface message used by import_error_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'Corrupted Data Detected'**
  String get importErrorCorruptedData;

  /// Shared interface message used by import_error_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'Invalid Automaton Definition'**
  String get importErrorInvalidAutomaton;

  /// Shared interface message used by file_operations_panel_feedback.dart.
  ///
  /// In en, this message translates to:
  /// **'The selected JFLAP file could not be parsed. Please verify the file integrity and try again.'**
  String get importFriendlyMalformedJff;

  /// Shared interface message used by file_operations_panel_feedback.dart.
  ///
  /// In en, this message translates to:
  /// **'The import contains JSON sections that are invalid. Fix the JSON structure and retry.'**
  String get importFriendlyInvalidJson;

  /// Shared interface message used by file_operations_panel_feedback.dart.
  ///
  /// In en, this message translates to:
  /// **'This file targets a newer JFLAP schema version. Export it again using a compatible version and retry.'**
  String get importFriendlyUnsupportedVersion;

  /// Shared interface message used by file_operations_panel_feedback.dart.
  ///
  /// In en, this message translates to:
  /// **'Turing Lab could not access the selected file. Pick it again from the system dialog and keep it available until the import finishes.'**
  String get importFriendlyInaccessibleFile;

  /// Shared interface message used by file_operations_panel_feedback.dart.
  ///
  /// In en, this message translates to:
  /// **'The file appears to be corrupted or unreadable. Restore a valid backup before importing again.'**
  String get importFriendlyCorruptedData;

  /// Shared interface message used by file_operations_panel_feedback.dart.
  ///
  /// In en, this message translates to:
  /// **'The automaton definition is inconsistent. Review the transitions and states before retrying the import.'**
  String get importFriendlyInvalidAutomaton;

  /// Shared interface message used by import_error_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'Hide technical details'**
  String get hideTechnicalDetails;

  /// Shared interface message used by import_error_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'View technical details'**
  String get viewTechnicalDetails;

  /// Shared interface message used by file_operations_panel.dart.
  ///
  /// In en, this message translates to:
  /// **'No states defined'**
  String get svgNoStatesDefined;

  /// Shared interface message used by file_operations_panel.dart.
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
  /// **'The current automaton does not contain ε-transitions.'**
  String get automatonHasNoLambdaTransitions;

  /// No description provided for @automatonMustContainLambdaToRemove.
  ///
  /// In en, this message translates to:
  /// **'The current automaton must contain ε-transitions to remove them.'**
  String get automatonMustContainLambdaToRemove;

  /// No description provided for @lambdaTransitionsRemoved.
  ///
  /// In en, this message translates to:
  /// **'ε-transitions removed successfully.'**
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
  /// **'Use ε for the empty string.'**
  String get rightSideHelper;

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
  /// **'Right side must contain at least one symbol (or ε)'**
  String get rightSideAtLeastOneSymbol;

  /// No description provided for @rightSideSingleLambda.
  ///
  /// In en, this message translates to:
  /// **'Right side can contain only one ε symbol'**
  String get rightSideSingleLambda;

  /// No description provided for @lambdaMustBeOnlySymbol.
  ///
  /// In en, this message translates to:
  /// **'ε must be the only symbol on the right side'**
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

  /// Shared interface message used by pumping_lemma_page.dart, pumping_lemma_progress.dart, and workspace_quick_actions_bar.dart.
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
  /// **'NFA-ε - A or AB'**
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

  /// No description provided for @tmBlockLibraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Building block library'**
  String get tmBlockLibraryTitle;

  /// No description provided for @tmBlockLibraryDescription.
  ///
  /// In en, this message translates to:
  /// **'Reuse typed submachines with shared tapes and explicit call and return behavior.'**
  String get tmBlockLibraryDescription;

  /// No description provided for @tmBlockLibraryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No reusable blocks yet.'**
  String get tmBlockLibraryEmpty;

  /// No description provided for @tmBlockCreate.
  ///
  /// In en, this message translates to:
  /// **'Create block'**
  String get tmBlockCreate;

  /// No description provided for @tmBlockCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a building block'**
  String get tmBlockCreateTitle;

  /// No description provided for @tmBlockRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename building block'**
  String get tmBlockRenameTitle;

  /// No description provided for @tmBlockNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Block name'**
  String get tmBlockNameLabel;

  /// No description provided for @tmBlockOpen.
  ///
  /// In en, this message translates to:
  /// **'Open block'**
  String get tmBlockOpen;

  /// No description provided for @tmBlockInsert.
  ///
  /// In en, this message translates to:
  /// **'Insert on root canvas'**
  String get tmBlockInsert;

  /// No description provided for @tmBlockRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get tmBlockRename;

  /// No description provided for @tmBlockDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get tmBlockDuplicate;

  /// No description provided for @tmBlockDeleteReferencedTitle.
  ///
  /// In en, this message translates to:
  /// **'Block is in use'**
  String get tmBlockDeleteReferencedTitle;

  /// No description provided for @tmBlockDeleteReferencedMessage.
  ///
  /// In en, this message translates to:
  /// **'Deleting this block will convert every invocation node to an ordinary state. Transitions are preserved.'**
  String get tmBlockDeleteReferencedMessage;

  /// No description provided for @tmBlockDetachAndDelete.
  ///
  /// In en, this message translates to:
  /// **'Detach and delete'**
  String get tmBlockDetachAndDelete;

  /// No description provided for @tmBlockSharedTapeNotice.
  ///
  /// In en, this message translates to:
  /// **'Calls share every tape and head position. Internal final states are ignored; a block returns when it halts.'**
  String get tmBlockSharedTapeNotice;

  /// No description provided for @tmBlockRootBreadcrumb.
  ///
  /// In en, this message translates to:
  /// **'Root machine'**
  String get tmBlockRootBreadcrumb;

  /// No description provided for @tmBlockValid.
  ///
  /// In en, this message translates to:
  /// **'Valid'**
  String get tmBlockValid;

  /// No description provided for @tmBlockInvalid.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get tmBlockInvalid;

  /// No description provided for @tmBlockRevision.
  ///
  /// In en, this message translates to:
  /// **'Revision {revision}'**
  String tmBlockRevision(int revision);

  /// No description provided for @tmBlockMachineSummary.
  ///
  /// In en, this message translates to:
  /// **'{states} states, {transitions} transitions'**
  String tmBlockMachineSummary(int states, int transitions);

  /// Shared interface message used by graphview_canvas_toolbar.dart.
  ///
  /// In en, this message translates to:
  /// **'Building blocks'**
  String get canvasManageBlocksAction;

  /// Shared interface message used by graphview_canvas_toolbar.dart.
  ///
  /// In en, this message translates to:
  /// **'Open the reusable Turing machine block library'**
  String get canvasManageBlocksHint;

  /// No description provided for @tapeSymbols.
  ///
  /// In en, this message translates to:
  /// **'Tape Symbols'**
  String get tapeSymbols;

  /// No description provided for @tmTapeCount.
  ///
  /// In en, this message translates to:
  /// **'Tape count'**
  String get tmTapeCount;

  /// No description provided for @tmDocumentVariant.
  ///
  /// In en, this message translates to:
  /// **'Variant'**
  String get tmDocumentVariant;

  /// No description provided for @tmDocumentVariantSingleTape.
  ///
  /// In en, this message translates to:
  /// **'Single tape'**
  String get tmDocumentVariantSingleTape;

  /// No description provided for @tmDocumentVariantMultiTape.
  ///
  /// In en, this message translates to:
  /// **'Multiple tapes'**
  String get tmDocumentVariantMultiTape;

  /// No description provided for @tmDocumentVariantBuildingBlocks.
  ///
  /// In en, this message translates to:
  /// **'Building blocks'**
  String get tmDocumentVariantBuildingBlocks;

  /// No description provided for @tmDecreaseTapeCount.
  ///
  /// In en, this message translates to:
  /// **'Decrease tape count'**
  String get tmDecreaseTapeCount;

  /// No description provided for @tmIncreaseTapeCount.
  ///
  /// In en, this message translates to:
  /// **'Increase tape count'**
  String get tmIncreaseTapeCount;

  /// No description provided for @tmTapeCountShrinkBlocked.
  ///
  /// In en, this message translates to:
  /// **'Clear nonblank operations on the removed tapes before reducing the tape count.'**
  String get tmTapeCountShrinkBlocked;

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

  /// Shared interface message used by workspace_quick_actions_provider.dart.
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

  /// Accessible name for a Turing-machine tape cell.
  ///
  /// In en, this message translates to:
  /// **'Tape cell {index}'**
  String tapeCellSemantics(int index);

  /// Accessible value for a nonblank Turing-machine tape cell.
  ///
  /// In en, this message translates to:
  /// **'Symbol {symbol}'**
  String tapeCellSymbolValue(String symbol);

  /// Accessible value for a blank Turing-machine tape cell.
  ///
  /// In en, this message translates to:
  /// **'Blank symbol {symbol}'**
  String tapeCellBlankValue(String symbol);

  /// Accessible state for the tape cell under the Turing-machine head.
  ///
  /// In en, this message translates to:
  /// **'under the tape head'**
  String get tapeCellHeadState;

  /// Accessible state for the tape cell read by the last operation.
  ///
  /// In en, this message translates to:
  /// **'read in the last operation'**
  String get tapeCellReadState;

  /// Accessible state for the tape cell written by the last operation.
  ///
  /// In en, this message translates to:
  /// **'written in the last operation'**
  String get tapeCellWrittenState;

  /// Accessible hint for an editable Turing-machine tape cell.
  ///
  /// In en, this message translates to:
  /// **'Opens symbol editing for this tape cell.'**
  String get tapeCellEditHint;

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

  /// Locale-formatted duration value expressed in milliseconds.
  ///
  /// In en, this message translates to:
  /// **'{value} ms'**
  String durationMillisecondsValue(String value);

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

  /// Shared interface message used by automaton_graphview_canvas.dart, conversion_replacement_dialog.dart, and document_interoperability_failure_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'Pop'**
  String get pop;

  /// Shared interface message used by help_navigation.dart, home_page.dart, and settings_page.dart.
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

  /// Shared interface message used by step_navigation_controls.dart.
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

  /// Compact current-step position shown by shared step navigation controls.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total}'**
  String stepNavigationPosition(int current, int total);

  /// No description provided for @collapseSidebar.
  ///
  /// In en, this message translates to:
  /// **'Collapse Sidebar'**
  String get collapseSidebar;

  /// Shared interface message used by app_snackbar.dart, automaton_workspace_scaffold.dart, and error_banner.dart.
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
  /// **'Remove ε-transitions'**
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

  /// No description provided for @automatonLayoutButtonSemantics.
  ///
  /// In en, this message translates to:
  /// **'Arrange automaton states'**
  String get automatonLayoutButtonSemantics;

  /// No description provided for @automatonLayoutButtonHint.
  ///
  /// In en, this message translates to:
  /// **'Preview deterministic graph layouts and transformations'**
  String get automatonLayoutButtonHint;

  /// No description provided for @automatonLayoutButtonTooltip.
  ///
  /// In en, this message translates to:
  /// **'Arrange states'**
  String get automatonLayoutButtonTooltip;

  /// No description provided for @automatonLayoutCannotArrange.
  ///
  /// In en, this message translates to:
  /// **'Cannot arrange states'**
  String get automatonLayoutCannotArrange;

  /// No description provided for @automatonLayoutApplyFailed.
  ///
  /// In en, this message translates to:
  /// **'The layout could not be applied.'**
  String get automatonLayoutApplyFailed;

  /// No description provided for @automatonLayoutPreviewFailed.
  ///
  /// In en, this message translates to:
  /// **'The layout preview failed.'**
  String get automatonLayoutPreviewFailed;

  /// No description provided for @automatonLayoutDocumentChanged.
  ///
  /// In en, this message translates to:
  /// **'The document changed while the layout preview was open.'**
  String get automatonLayoutDocumentChanged;

  /// No description provided for @automatonLayoutAnnotationsChanged.
  ///
  /// In en, this message translates to:
  /// **'Document annotations changed while the layout preview was open.'**
  String get automatonLayoutAnnotationsChanged;

  /// No description provided for @automatonLayoutChoosePreview.
  ///
  /// In en, this message translates to:
  /// **'Choose a deterministic layout. Changes remain a preview until you apply them.'**
  String get automatonLayoutChoosePreview;

  /// No description provided for @automatonLayoutLabel.
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get automatonLayoutLabel;

  /// No description provided for @automatonLayoutApplyTo.
  ///
  /// In en, this message translates to:
  /// **'Apply to'**
  String get automatonLayoutApplyTo;

  /// No description provided for @automatonLayoutCircle.
  ///
  /// In en, this message translates to:
  /// **'Circle'**
  String get automatonLayoutCircle;

  /// No description provided for @automatonLayoutTwoCircles.
  ///
  /// In en, this message translates to:
  /// **'Two circles'**
  String get automatonLayoutTwoCircles;

  /// No description provided for @automatonLayoutSpiral.
  ///
  /// In en, this message translates to:
  /// **'Spiral'**
  String get automatonLayoutSpiral;

  /// No description provided for @automatonLayoutHierarchical.
  ///
  /// In en, this message translates to:
  /// **'Hierarchical'**
  String get automatonLayoutHierarchical;

  /// No description provided for @automatonLayoutSugiyama.
  ///
  /// In en, this message translates to:
  /// **'Sugiyama layered'**
  String get automatonLayoutSugiyama;

  /// No description provided for @automatonLayoutPackComponents.
  ///
  /// In en, this message translates to:
  /// **'Pack components'**
  String get automatonLayoutPackComponents;

  /// No description provided for @automatonLayoutSeededForce.
  ///
  /// In en, this message translates to:
  /// **'Force-directed (seeded)'**
  String get automatonLayoutSeededForce;

  /// No description provided for @automatonLayoutSeededRandom.
  ///
  /// In en, this message translates to:
  /// **'Random (seeded)'**
  String get automatonLayoutSeededRandom;

  /// No description provided for @automatonLayoutReflectHorizontal.
  ///
  /// In en, this message translates to:
  /// **'Reflect horizontally'**
  String get automatonLayoutReflectHorizontal;

  /// No description provided for @automatonLayoutReflectVertical.
  ///
  /// In en, this message translates to:
  /// **'Reflect vertically'**
  String get automatonLayoutReflectVertical;

  /// No description provided for @automatonLayoutRotate90.
  ///
  /// In en, this message translates to:
  /// **'Rotate 90 degrees'**
  String get automatonLayoutRotate90;

  /// No description provided for @automatonLayoutRotate180.
  ///
  /// In en, this message translates to:
  /// **'Rotate 180 degrees'**
  String get automatonLayoutRotate180;

  /// No description provided for @automatonLayoutRotate270.
  ///
  /// In en, this message translates to:
  /// **'Rotate 270 degrees'**
  String get automatonLayoutRotate270;

  /// No description provided for @automatonLayoutFitViewport.
  ///
  /// In en, this message translates to:
  /// **'Fit to viewport'**
  String get automatonLayoutFitViewport;

  /// No description provided for @automatonLayoutFillViewport.
  ///
  /// In en, this message translates to:
  /// **'Fill viewport'**
  String get automatonLayoutFillViewport;

  /// No description provided for @automatonLayoutRestoreSaved.
  ///
  /// In en, this message translates to:
  /// **'Restore saved layout'**
  String get automatonLayoutRestoreSaved;

  /// No description provided for @automatonLayoutAllStates.
  ///
  /// In en, this message translates to:
  /// **'All states'**
  String get automatonLayoutAllStates;

  /// No description provided for @automatonLayoutSelectedComponent.
  ///
  /// In en, this message translates to:
  /// **'Selected component'**
  String get automatonLayoutSelectedComponent;

  /// No description provided for @automatonLayoutSelectedStates.
  ///
  /// In en, this message translates to:
  /// **'Selected states'**
  String get automatonLayoutSelectedStates;

  /// No description provided for @automatonLayoutKeepSelected.
  ///
  /// In en, this message translates to:
  /// **'Keep selected states in place'**
  String get automatonLayoutKeepSelected;

  /// No description provided for @automatonLayoutRootState.
  ///
  /// In en, this message translates to:
  /// **'Root state'**
  String get automatonLayoutRootState;

  /// No description provided for @automatonLayoutAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get automatonLayoutAutomatic;

  /// No description provided for @automatonLayoutSeed.
  ///
  /// In en, this message translates to:
  /// **'Seed'**
  String get automatonLayoutSeed;

  /// No description provided for @automatonLayoutSeedHelp.
  ///
  /// In en, this message translates to:
  /// **'The same seed produces the same layout.'**
  String get automatonLayoutSeedHelp;

  /// No description provided for @automatonLayoutTransformFreeNotes.
  ///
  /// In en, this message translates to:
  /// **'Transform free notes with the graph'**
  String get automatonLayoutTransformFreeNotes;

  /// No description provided for @automatonLayoutAttachedNotesHelp.
  ///
  /// In en, this message translates to:
  /// **'Attached notes always follow their state or transition.'**
  String get automatonLayoutAttachedNotesHelp;

  /// No description provided for @automatonLayoutApply.
  ///
  /// In en, this message translates to:
  /// **'Apply layout'**
  String get automatonLayoutApply;

  /// No description provided for @automatonLayoutPreparingPreview.
  ///
  /// In en, this message translates to:
  /// **'Preparing preview'**
  String get automatonLayoutPreparingPreview;

  /// No description provided for @automatonLayoutValidatingGraph.
  ///
  /// In en, this message translates to:
  /// **'Validating graph'**
  String get automatonLayoutValidatingGraph;

  /// No description provided for @automatonLayoutComputing.
  ///
  /// In en, this message translates to:
  /// **'Computing layout'**
  String get automatonLayoutComputing;

  /// No description provided for @automatonLayoutMeasuring.
  ///
  /// In en, this message translates to:
  /// **'Measuring result'**
  String get automatonLayoutMeasuring;

  /// No description provided for @automatonLayoutComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get automatonLayoutComplete;

  /// No description provided for @automatonLayoutEmptyGraph.
  ///
  /// In en, this message translates to:
  /// **'The graph has no nodes to lay out.'**
  String get automatonLayoutEmptyGraph;

  /// No description provided for @automatonLayoutInvalidTopology.
  ///
  /// In en, this message translates to:
  /// **'Node and edge IDs must be non-empty and unique, and every edge endpoint must reference a node.'**
  String get automatonLayoutInvalidTopology;

  /// No description provided for @automatonLayoutInvalidPosition.
  ///
  /// In en, this message translates to:
  /// **'Every input node position must be finite.'**
  String get automatonLayoutInvalidPosition;

  /// No description provided for @automatonLayoutInvalidBounds.
  ///
  /// In en, this message translates to:
  /// **'Layout bounds and spacing must be finite and positive.'**
  String get automatonLayoutInvalidBounds;

  /// No description provided for @automatonLayoutCoordinatesClamped.
  ///
  /// In en, this message translates to:
  /// **'Extreme layout coordinates were clamped to safe bounds.'**
  String get automatonLayoutCoordinatesClamped;

  /// No description provided for @automatonLayoutDenseGraph.
  ///
  /// In en, this message translates to:
  /// **'This is a dense graph; crossing metrics are heuristic.'**
  String get automatonLayoutDenseGraph;

  /// No description provided for @automatonLayoutSelectNode.
  ///
  /// In en, this message translates to:
  /// **'Select at least one node for selected-node layout.'**
  String get automatonLayoutSelectNode;

  /// No description provided for @automatonLayoutSelectComponent.
  ///
  /// In en, this message translates to:
  /// **'Select a node whose connected component will be laid out.'**
  String get automatonLayoutSelectComponent;

  /// No description provided for @automatonLayoutNoRestore.
  ///
  /// In en, this message translates to:
  /// **'No saved manual or previous layout is available to restore.'**
  String get automatonLayoutNoRestore;

  /// No description provided for @automatonLayoutCancelled.
  ///
  /// In en, this message translates to:
  /// **'The layout computation was cancelled.'**
  String get automatonLayoutCancelled;

  /// Selected automaton states shown in the layout dialog.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 selected} other{{count} selected}}'**
  String automatonLayoutSelectedCount(int count);

  /// Current state spacing in the layout dialog.
  ///
  /// In en, this message translates to:
  /// **'State spacing: {spacing}'**
  String automatonLayoutStateSpacing(int spacing);

  /// Current layer spacing in the layout dialog.
  ///
  /// In en, this message translates to:
  /// **'Layer spacing: {spacing}'**
  String automatonLayoutLayerSpacing(int spacing);

  /// Progress for the seeded force layout.
  ///
  /// In en, this message translates to:
  /// **'Force iteration {current} of {total}'**
  String automatonLayoutForceIteration(int current, int total);

  /// Accessible layout preview progress.
  ///
  /// In en, this message translates to:
  /// **'{stage}, {percent} percent'**
  String automatonLayoutProgressStatus(String stage, int percent);

  /// Accessible metrics for the layout preview. crossingMeasurement is measured or notMeasured.
  ///
  /// In en, this message translates to:
  /// **'{nodeCount, plural, =1{1 state} other{{nodeCount} states}}, {componentCount, plural, =1{1 component} other{{componentCount} components}}, {overlapCount, plural, =1{1 overlap} other{{overlapCount} overlaps}}, {crossingMeasurement, select, measured{{edgeCrossingCount, plural, =1{1 edge crossing} other{{edgeCrossingCount} edge crossings}}} notMeasured{edge crossings not measured} other{edge crossings not measured}}.'**
  String automatonLayoutResultSummary(
    int nodeCount,
    int componentCount,
    int overlapCount,
    String crossingMeasurement,
    int edgeCrossingCount,
  );

  /// Confirmation after applying a layout.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 state arranged. Undo restores the previous layout.} other{{count} states arranged. Undo restores the previous layout.}}'**
  String automatonLayoutArrangedCount(int count);

  /// Unsupported graph layout algorithm version.
  ///
  /// In en, this message translates to:
  /// **'Layout algorithm version {version} is not supported.'**
  String automatonLayoutUnsupportedVersion(int version);

  /// Graph layout resource limit diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The graph exceeds the configured layout limit ({nodeCount}/{maximumNodes} nodes, {edgeCount}/{maximumEdges} edges).'**
  String automatonLayoutResourceLimit(
    int nodeCount,
    int maximumNodes,
    int edgeCount,
    int maximumEdges,
  );

  /// Graph layout coordinate diagnostic. The node identifier is user-authored and must remain unchanged.
  ///
  /// In en, this message translates to:
  /// **'Layout produced a non-finite coordinate for {nodeId}.'**
  String automatonLayoutNonFiniteCoordinate(String nodeId);

  /// Possible overlaps remaining in the layout preview.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 possible node overlap remains; review the preview before applying.} other{{count} possible node overlaps remain; review the preview before applying.}}'**
  String automatonLayoutOverlapsRemain(int count);

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
  /// **'Generate an LL(1) predictive parse table'**
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
  /// **'ε-transitions present: {count}'**
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

  /// No description provided for @classifyGrammarTitle.
  ///
  /// In en, this message translates to:
  /// **'Classify grammar'**
  String get classifyGrammarTitle;

  /// No description provided for @classifyGrammarDescription.
  ///
  /// In en, this message translates to:
  /// **'Infer the strongest structural class and show evidence for failed restrictions.'**
  String get classifyGrammarDescription;

  /// No description provided for @copyClassificationReport.
  ///
  /// In en, this message translates to:
  /// **'Copy classification report'**
  String get copyClassificationReport;

  /// No description provided for @classificationReportCopied.
  ///
  /// In en, this message translates to:
  /// **'Classification report copied.'**
  String get classificationReportCopied;

  /// No description provided for @updateDeclaredGrammarType.
  ///
  /// In en, this message translates to:
  /// **'Update declared type'**
  String get updateDeclaredGrammarType;

  /// No description provided for @updateDeclaredGrammarTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Update grammar metadata?'**
  String get updateDeclaredGrammarTypeTitle;

  /// No description provided for @updateDeclaredGrammarTypeMessage.
  ///
  /// In en, this message translates to:
  /// **'Change the declared type to {type}? The productions will not change.'**
  String updateDeclaredGrammarTypeMessage(String type);

  /// No description provided for @grammarStructureNotLanguageClass.
  ///
  /// In en, this message translates to:
  /// **'This result classifies the written grammar, not the minimal class of its language.'**
  String get grammarStructureNotLanguageClass;

  /// No description provided for @declaredGrammarType.
  ///
  /// In en, this message translates to:
  /// **'Declared type'**
  String get declaredGrammarType;

  /// No description provided for @inferredGrammarType.
  ///
  /// In en, this message translates to:
  /// **'Inferred type'**
  String get inferredGrammarType;

  /// No description provided for @pdaAnalysisTitle.
  ///
  /// In en, this message translates to:
  /// **'PDA Analysis'**
  String get pdaAnalysisTitle;

  /// Shared interface message used by tm_algorithm_result_shell.dart.
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

  /// Shared interface message used by tm_algorithm_result_shell.dart.
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

  /// Error shown when PDA-to-CFG conversion or its normalization fails.
  ///
  /// In en, this message translates to:
  /// **'Conversion failed: {error}'**
  String pdaConversionFailure(String error);

  /// No description provided for @pdaConversionCanceledDocumentUnchanged.
  ///
  /// In en, this message translates to:
  /// **'Conversion canceled. The editor PDA was not changed.'**
  String get pdaConversionCanceledDocumentUnchanged;

  /// No description provided for @pdaConversionCanceledPanelClosed.
  ///
  /// In en, this message translates to:
  /// **'Conversion canceled because the panel was closed.'**
  String get pdaConversionCanceledPanelClosed;

  /// No description provided for @pdaConversionCanceledEditorChanged.
  ///
  /// In en, this message translates to:
  /// **'Conversion canceled because the editor PDA changed during review.'**
  String get pdaConversionCanceledEditorChanged;

  /// Summary shown after PDA normalization is accepted for conversion.
  ///
  /// In en, this message translates to:
  /// **'Applied normalization: {beforeStates} → {afterStates} states, {beforeTransitions} → {afterTransitions} transitions.'**
  String pdaNormalizationAppliedSummary(
    int beforeStates,
    int afterStates,
    int beforeTransitions,
    int afterTransitions,
  );

  /// Summary of the grammar produced by PDA-to-CFG conversion.
  ///
  /// In en, this message translates to:
  /// **'Generated grammar has {productions} productions and {nonterminals} non-terminals.'**
  String pdaGeneratedGrammarSummary(int productions, int nonterminals);

  /// Validation message shown when PDA-to-CFG receives a non-positive production limit.
  ///
  /// In en, this message translates to:
  /// **'The PDA to CFG production limit must be greater than zero.'**
  String get pdaToCfgInvalidProductionLimit;

  /// Message shown when PDA-to-CFG conversion is canceled before completion.
  ///
  /// In en, this message translates to:
  /// **'PDA-to-CFG conversion was canceled.'**
  String get pdaToCfgCancelled;

  /// Validation message shown when PDA-to-CFG receives an empty PDA.
  ///
  /// In en, this message translates to:
  /// **'Cannot convert an empty PDA to a grammar.'**
  String get pdaToCfgEmptyPda;

  /// Validation message shown when PDA-to-CFG receives a PDA without an initial state.
  ///
  /// In en, this message translates to:
  /// **'PDA must define an initial state before conversion.'**
  String get pdaToCfgMissingInitialState;

  /// Validation message shown when PDA-to-CFG receives an initial state outside the PDA state set.
  ///
  /// In en, this message translates to:
  /// **'The PDA initial state must belong to the PDA state set before conversion.'**
  String get pdaToCfgInitialStateOutsideSet;

  /// Validation message shown when PDA-to-CFG receives a PDA without accepting states.
  ///
  /// In en, this message translates to:
  /// **'PDA must have at least one accepting state for conversion.'**
  String get pdaToCfgMissingAcceptingState;

  /// Validation message shown when PDA-to-CFG receives an accepting state outside the PDA state set.
  ///
  /// In en, this message translates to:
  /// **'Every accepting state must belong to the PDA state set before conversion.'**
  String get pdaToCfgAcceptingStateOutsideSet;

  /// Validation message shown when a PDA transition uses an epsilon pop that must be normalized before PDA-to-CFG conversion.
  ///
  /// In en, this message translates to:
  /// **'PDA-to-CFG conversion requires every transition to pop exactly one stack symbol. Transition {transition} uses an ε-pop. Normalize the PDA before conversion.'**
  String pdaToCfgEpsilonPop(String transition);

  /// Message shown when the bounded PDA-to-CFG production construction reaches its limit.
  ///
  /// In en, this message translates to:
  /// **'PDA-to-CFG conversion stopped at the {limit} production limit.'**
  String pdaToCfgProductionLimit(int limit);

  /// Message shown when PDA-to-CFG completes without generating productions.
  ///
  /// In en, this message translates to:
  /// **'No productions could be generated for this PDA.'**
  String get pdaToCfgNoProductions;

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

  /// Shared interface message used by document_interoperability_review_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'Review import'**
  String get interoperabilityImportReviewTitle;

  /// Shared interface message used by document_interoperability_review_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'Review export'**
  String get interoperabilityExportReviewTitle;

  /// Shared interface message used by document_interoperability_review_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'Check the detected document and compatibility report before continuing.'**
  String get interoperabilityReviewPrompt;

  /// Shared interface message used by document_interoperability_review_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get interoperabilityFileLabel;

  /// Shared interface message used by document_interoperability_review_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get interoperabilityTypeLabel;

  /// Shared interface message used by document_interoperability_review_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get interoperabilityFormatLabel;

  /// Shared interface message used by document_interoperability_review_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get interoperabilityVersionLabel;

  /// Shared interface message used by document_interoperability_review_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'Fidelity'**
  String get interoperabilityFidelityLabel;

  /// Shared interface message used by document_interoperability_review_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'Exact'**
  String get interoperabilityFidelityExact;

  /// Shared interface message used by document_interoperability_review_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'Normalized'**
  String get interoperabilityFidelityNormalized;

  /// Shared interface message used by document_interoperability_review_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'Data loss'**
  String get interoperabilityFidelityLossy;

  /// Shared interface message used by document_interoperability_review_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'Field-level report'**
  String get interoperabilityChangesTitle;

  /// Shared interface message used by document_interoperability_review_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'Some source data cannot be represented and will be lost if you replace the current document.'**
  String get interoperabilityLossyImportWarning;

  /// Shared interface message used by document_interoperability_review_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'Some document data cannot be represented in this format and will be omitted from the exported file.'**
  String get interoperabilityLossyExportWarning;

  /// Shared interface message used by document_interoperability_review_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'Replace document'**
  String get interoperabilityReplaceDocument;

  /// Shared interface message used by document_interoperability_review_dialog.dart, file_operations_panel_interoperability.dart, and file_operations_panel_visual_export.dart.
  ///
  /// In en, this message translates to:
  /// **'Export file'**
  String get interoperabilityExportDocument;

  /// Shared interface message used by document_interoperability_review_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'Import with data loss'**
  String get interoperabilityImportWithLoss;

  /// Shared interface message used by document_interoperability_review_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'Export with data loss'**
  String get interoperabilityExportWithLoss;

  /// Shared interface message used by document_interoperability_failure_dialog.dart and document_interoperability_review_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'Path: {path}'**
  String interoperabilityDiagnosticPath(String path);

  /// Shared interface message used by document_interoperability_failure_dialog.dart and document_interoperability_review_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'Line {line}, column {column}'**
  String interoperabilityDiagnosticLineColumn(int line, int column);

  /// Shared interface message used by document_interoperability_failure_dialog.dart and document_interoperability_review_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'Line {line}'**
  String interoperabilityDiagnosticLine(int line);

  /// Shared interface message used by document_interoperability_review_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'Field preserved'**
  String get interoperabilityDiagnosticPreserved;

  /// Shared interface message used by document_interoperability_review_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'Field normalized'**
  String get interoperabilityDiagnosticNormalized;

  /// Shared interface message used by document_interoperability_review_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'Field omitted'**
  String get interoperabilityDiagnosticDropped;

  /// Shared interface message used by document_interoperability_review_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'Source value recorded but hidden for privacy'**
  String get interoperabilityDiagnosticSourceValueRecorded;

  /// Shared interface message used by document_interoperability_review_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'Diagnostic code: {code}'**
  String interoperabilityDiagnosticTechnicalCode(String code);

  /// Shared interface message used by document_interoperability_failure_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'Document not supported'**
  String get interoperabilityUnsupportedTitle;

  /// Shared interface message used by document_interoperability_failure_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'Document type is ambiguous'**
  String get interoperabilityAmbiguousTitle;

  /// Shared interface message used by document_interoperability_failure_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'Document cannot be read'**
  String get interoperabilityMalformedTitle;

  /// Shared interface message used by document_interoperability_failure_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'Document exceeds a safety limit'**
  String get interoperabilityResourceLimitTitle;

  /// Shared interface message used by document_interoperability_failure_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'Document operation failed'**
  String get interoperabilityInternalFailureTitle;

  /// Shared interface message used by document_interoperability_failure_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'No registered codec recognizes this document.'**
  String get interoperabilityUnsupportedDocument;

  /// Structured interoperability registry failure.
  ///
  /// In en, this message translates to:
  /// **'Codec {codec} reported document identity outside its registration.'**
  String interopRegistrySniffIdentityMismatch(String codec);

  /// Structured interoperability registry failure.
  ///
  /// In en, this message translates to:
  /// **'Codec {codec} could not inspect the document.'**
  String interopRegistrySniffFailed(String codec);

  /// Structured interoperability registry failure.
  ///
  /// In en, this message translates to:
  /// **'Codec {codec} returned a document outside its registered identity.'**
  String interopRegistryDecodedIdentityMismatch(String codec);

  /// Structured interoperability registry failure.
  ///
  /// In en, this message translates to:
  /// **'Codec {codec} could not decode the document.'**
  String interopRegistryDecodeFailed(String codec);

  /// Structured interoperability registry failure.
  ///
  /// In en, this message translates to:
  /// **'Schema {schema} is not registered for {system}.'**
  String interopRegistrySchemaIdentityUnregistered(
    String schema,
    String system,
  );

  /// Structured interoperability registry failure.
  ///
  /// In en, this message translates to:
  /// **'No codec can export {system} as {format} with schema version {schemaVersion}.'**
  String interopRegistryExportRouteUnavailable(
    String system,
    String format,
    int schemaVersion,
  );

  /// Structured interoperability registry failure.
  ///
  /// In en, this message translates to:
  /// **'No codec can export schema version {schemaVersion}.'**
  String interopRegistryExportSchemaUnavailable(int schemaVersion);

  /// Structured interoperability registry failure.
  ///
  /// In en, this message translates to:
  /// **'Codec {codec} returned file metadata outside its registered format.'**
  String interopRegistryEncodedMetadataMismatch(String codec);

  /// Structured interoperability registry failure.
  ///
  /// In en, this message translates to:
  /// **'Codec {codec} could not encode the document.'**
  String interopRegistryEncodeFailed(String codec);

  /// Shared interface message used by document_interoperability_failure_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'This document uses a feature that is not supported yet.'**
  String get interoperabilityUnsupportedFeature;

  /// Shared interface message used by document_interoperability_failure_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'This document version is not supported.'**
  String get interoperabilityUnsupportedSchema;

  /// Shared interface message used by document_interoperability_failure_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'This format is not supported for the current document.'**
  String get interoperabilityUnsupportedFormat;

  /// Shared interface message used by document_interoperability_failure_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'This format does not support the requested import or export action.'**
  String get interoperabilityUnsupportedDirection;

  /// Shared interface message used by document_interoperability_failure_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'More than one codec matched: {codecIds}'**
  String interoperabilityAmbiguousDescription(String codecIds);

  /// Shared interface message used by document_interoperability_failure_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'The document syntax is invalid or incomplete.'**
  String get interoperabilityMalformedSyntax;

  /// Shared interface message used by document_interoperability_failure_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'The document is not valid UTF-8 text.'**
  String get interoperabilityMalformedUtf8;

  /// Shared interface message used by document_interoperability_failure_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'A required field is missing.'**
  String get interoperabilityMalformedMissingField;

  /// Shared interface message used by document_interoperability_failure_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'A field contains an invalid value.'**
  String get interoperabilityMalformedInvalidValue;

  /// Shared interface message used by document_interoperability_failure_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'The document contains a duplicate identifier.'**
  String get interoperabilityMalformedDuplicateIdentity;

  /// Shared interface message used by document_interoperability_failure_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'Safety limit {limit}: found {actual}; maximum {maximum}.'**
  String interoperabilityResourceLimitDescription(
    String limit,
    int actual,
    int maximum,
  );

  /// Shared interface message used by document_interoperability_failure_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'Turing Lab could not complete this document operation. The active document was not changed.'**
  String get interoperabilityInternalFailureDescription;

  /// Shared interface message used by document_interoperability_failure_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'Offset {offset}'**
  String interoperabilityDiagnosticOffset(int offset);

  /// Shared interface message used by document_interoperability_failure_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'View roadmap issue #{issue}'**
  String interoperabilityRoadmapIssue(int issue);

  /// Shared interface message used by document_interoperability_failure_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'file size'**
  String get interoperabilityLimitBytes;

  /// Shared interface message used by document_interoperability_failure_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'XML nesting depth'**
  String get interoperabilityLimitXmlDepth;

  /// Shared interface message used by document_interoperability_failure_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'XML element count'**
  String get interoperabilityLimitXmlElements;

  /// Shared interface message used by document_interoperability_failure_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'XML DTD or external entity'**
  String get interoperabilityLimitXmlDtdOrEntity;

  /// Shared interface message used by document_interoperability_failure_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'JSON nesting depth'**
  String get interoperabilityLimitJsonDepth;

  /// Shared interface message used by document_interoperability_failure_dialog.dart.
  ///
  /// In en, this message translates to:
  /// **'collection entry count'**
  String get interoperabilityLimitCollectionEntries;

  /// Shared interface message used by file_operations_panel_interoperability.dart.
  ///
  /// In en, this message translates to:
  /// **'Import document'**
  String get interoperabilityImportDocument;

  /// Shared interface message used by file_operations_panel_interoperability.dart and file_operations_panel_visual_export.dart.
  ///
  /// In en, this message translates to:
  /// **'Export as {format}'**
  String interoperabilityExportAs(String format);

  /// Shared interface message used by file_operations_panel_interoperability.dart.
  ///
  /// In en, this message translates to:
  /// **'Document imported successfully.'**
  String get interoperabilityImportSucceeded;

  /// Shared interface message used by file_operations_panel_interoperability.dart and file_operations_panel_visual_export.dart.
  ///
  /// In en, this message translates to:
  /// **'Document exported successfully.'**
  String get interoperabilityExportSucceeded;

  /// Shared interface message used by file_operations_panel_interoperability.dart and file_operations_panel_visual_export.dart.
  ///
  /// In en, this message translates to:
  /// **'The document operation could not be completed.'**
  String get interoperabilityOperationFailed;

  /// No description provided for @interoperabilityFormatJflapXml.
  ///
  /// In en, this message translates to:
  /// **'JFLAP XML'**
  String get interoperabilityFormatJflapXml;

  /// No description provided for @interoperabilityFormatTuringLabJson.
  ///
  /// In en, this message translates to:
  /// **'Turing Lab JSON'**
  String get interoperabilityFormatTuringLabJson;

  /// Shared interface message used by file_operations_panel_interoperability.dart.
  ///
  /// In en, this message translates to:
  /// **'Active document'**
  String get interoperabilityActiveDocument;

  /// Shared interface message used by default_workspace_presentation_modules.dart.
  ///
  /// In en, this message translates to:
  /// **'Mealy'**
  String get homeNavigationMealyLabel;

  /// Shared interface message used by default_workspace_presentation_modules.dart.
  ///
  /// In en, this message translates to:
  /// **'Edit and simulate Mealy transducers.'**
  String get homeNavigationMealyDescription;

  /// Shared interface message used by default_workspace_presentation_modules.dart.
  ///
  /// In en, this message translates to:
  /// **'Moore'**
  String get homeNavigationMooreLabel;

  /// Shared interface message used by default_workspace_presentation_modules.dart.
  ///
  /// In en, this message translates to:
  /// **'Edit and simulate Moore transducers.'**
  String get homeNavigationMooreDescription;

  /// Shared interface message used by default_workspace_presentation_modules.dart.
  ///
  /// In en, this message translates to:
  /// **'Unrestricted grammar'**
  String get homeNavigationUnrestrictedGrammarLabel;

  /// Shared interface message used by default_workspace_presentation_modules.dart.
  ///
  /// In en, this message translates to:
  /// **'Classify phrase-structure grammars and explore bounded derivations.'**
  String get homeNavigationUnrestrictedGrammarDescription;

  /// Shared interface message used by default_workspace_presentation_modules.dart.
  ///
  /// In en, this message translates to:
  /// **'L-system'**
  String get homeNavigationLSystemLabel;

  /// Shared interface message used by default_workspace_presentation_modules.dart.
  ///
  /// In en, this message translates to:
  /// **'Expand parallel rewrite systems and render turtle graphics.'**
  String get homeNavigationLSystemDescription;

  /// No description provided for @transducerInputSymbol.
  ///
  /// In en, this message translates to:
  /// **'Input symbol'**
  String get transducerInputSymbol;

  /// No description provided for @transducerInputRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter one input symbol.'**
  String get transducerInputRequired;

  /// No description provided for @transducerInputOutsideAlphabet.
  ///
  /// In en, this message translates to:
  /// **'Choose a symbol from the input alphabet.'**
  String get transducerInputOutsideAlphabet;

  /// No description provided for @transducerOutputOutsideAlphabet.
  ///
  /// In en, this message translates to:
  /// **'Use only tokens from the output alphabet.'**
  String get transducerOutputOutsideAlphabet;

  /// No description provided for @transducerDuplicateInput.
  ///
  /// In en, this message translates to:
  /// **'This state already has a transition for that input.'**
  String get transducerDuplicateInput;

  /// No description provided for @transducerInvalidTransition.
  ///
  /// In en, this message translates to:
  /// **'The transition is not valid for this machine.'**
  String get transducerInvalidTransition;

  /// No description provided for @transducerOutputTokens.
  ///
  /// In en, this message translates to:
  /// **'Output tokens'**
  String get transducerOutputTokens;

  /// No description provided for @transducerOutputTokensHint.
  ///
  /// In en, this message translates to:
  /// **'One token per line. Leave blank for empty output.'**
  String get transducerOutputTokensHint;

  /// No description provided for @transducerEmptyOutput.
  ///
  /// In en, this message translates to:
  /// **'empty output'**
  String get transducerEmptyOutput;

  /// No description provided for @transducerTransitionSemantics.
  ///
  /// In en, this message translates to:
  /// **'Input {input}; output {output}'**
  String transducerTransitionSemantics(String input, String output);

  /// No description provided for @transducerInputOnlySemantics.
  ///
  /// In en, this message translates to:
  /// **'Input {input}'**
  String transducerInputOnlySemantics(String input);

  /// No description provided for @transducerStateOutputSemantics.
  ///
  /// In en, this message translates to:
  /// **'State output {output}'**
  String transducerStateOutputSemantics(String output);

  /// No description provided for @transducerSimulationTitle.
  ///
  /// In en, this message translates to:
  /// **'Transducer simulation'**
  String get transducerSimulationTitle;

  /// No description provided for @transducerInputTokens.
  ///
  /// In en, this message translates to:
  /// **'Input tokens'**
  String get transducerInputTokens;

  /// No description provided for @transducerInputTokensHint.
  ///
  /// In en, this message translates to:
  /// **'One input token per line'**
  String get transducerInputTokensHint;

  /// No description provided for @transducerRun.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get transducerRun;

  /// No description provided for @transducerCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel run'**
  String get transducerCancel;

  /// No description provided for @transducerMaximumSteps.
  ///
  /// In en, this message translates to:
  /// **'Maximum steps'**
  String get transducerMaximumSteps;

  /// No description provided for @transducerMaximumStepsInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter zero or a positive whole number.'**
  String get transducerMaximumStepsInvalid;

  /// No description provided for @transducerOutput.
  ///
  /// In en, this message translates to:
  /// **'Output'**
  String get transducerOutput;

  /// No description provided for @transducerInvalidMachine.
  ///
  /// In en, this message translates to:
  /// **'The machine is invalid. Fix the reported states or transitions.'**
  String get transducerInvalidMachine;

  /// No description provided for @transducerInvalidInput.
  ///
  /// In en, this message translates to:
  /// **'The input contains a symbol outside the input alphabet.'**
  String get transducerInvalidInput;

  /// No description provided for @transducerUndefinedTransition.
  ///
  /// In en, this message translates to:
  /// **'No transition is defined for the next input symbol.'**
  String get transducerUndefinedTransition;

  /// No description provided for @transducerSimulationCancelled.
  ///
  /// In en, this message translates to:
  /// **'The simulation was cancelled.'**
  String get transducerSimulationCancelled;

  /// No description provided for @transducerSimulationBounded.
  ///
  /// In en, this message translates to:
  /// **'The simulation stopped at the configured step limit.'**
  String get transducerSimulationBounded;

  /// Structured transducer outcome for an invalid machine.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{The machine is invalid.} =1{The machine is invalid: one diagnostic needs attention.} other{The machine is invalid: {count} diagnostics need attention.}}'**
  String transducerExecutionInvalidMachine(int count);

  /// Structured transducer outcome for an invalid input symbol.
  ///
  /// In en, this message translates to:
  /// **'Input symbol \"{symbol}\" is outside the input alphabet.'**
  String transducerExecutionInvalidInputSymbol(String symbol);

  /// Structured transducer outcome for a tokenization failure.
  ///
  /// In en, this message translates to:
  /// **'The input cannot be tokenized at offset {offset}.'**
  String transducerExecutionTokenizationFailure(int offset);

  /// Structured transducer outcome for a missing transition.
  ///
  /// In en, this message translates to:
  /// **'No transition is defined from state {state} for input symbol \"{symbol}\".'**
  String transducerExecutionUndefinedTransition(String state, String symbol);

  /// Structured transducer outcome for cancellation.
  ///
  /// In en, this message translates to:
  /// **'{processed, plural, =0{The simulation was cancelled before any input tokens were processed.} =1{The simulation was cancelled after one input token.} other{The simulation was cancelled after {processed} input tokens.}}'**
  String transducerExecutionCancelled(int processed);

  /// Structured transducer outcome for a bounded run.
  ///
  /// In en, this message translates to:
  /// **'The simulation stopped at the {limit, plural, =1{one-step limit} other{{limit}-step limit}} after processing {processed, plural, =0{no input tokens} =1{one input token} other{{processed} input tokens}}.'**
  String transducerExecutionBounded(int limit, int processed);

  /// Structured transducer outcome for a successful run.
  ///
  /// In en, this message translates to:
  /// **'{processed, plural, =0{The simulation completed without consuming input.} =1{The simulation completed after one input token.} other{The simulation completed after {processed} input tokens.}} {outputCount, plural, =0{No output tokens were produced.} =1{One output token was produced.} other{{outputCount} output tokens were produced.}}'**
  String transducerExecutionSuccess(int processed, int outputCount);

  /// Structured parser diagnostic for malformed JFLAP XML.
  ///
  /// In en, this message translates to:
  /// **'The JFLAP XML document is malformed.'**
  String get parserXmlMalformedDocument;

  /// Structured grammar XML diagnostic for a missing grammar element.
  ///
  /// In en, this message translates to:
  /// **'The JFLAP file does not contain a grammar element.'**
  String get parserGrammarXmlMissingGrammarElement;

  /// Structured grammar XML diagnostic for a missing start element.
  ///
  /// In en, this message translates to:
  /// **'The JFLAP grammar does not declare a start symbol.'**
  String get parserGrammarXmlMissingStartElement;

  /// Structured grammar XML diagnostic for an empty start element.
  ///
  /// In en, this message translates to:
  /// **'The JFLAP grammar has an empty start symbol.'**
  String get parserGrammarXmlEmptyStartElement;

  /// Structured grammar XML diagnostic for a start element with the wrong symbol count.
  ///
  /// In en, this message translates to:
  /// **'The JFLAP grammar must declare one start symbol, but {count, plural, =0{none were found} =1{one was found} other{{count} were found}}.'**
  String parserGrammarXmlInvalidStartCount(int count);

  /// Structured grammar XML diagnostic for an incomplete production.
  ///
  /// In en, this message translates to:
  /// **'The production at index {index} must contain both left and right elements.'**
  String parserGrammarXmlIncompleteProduction(int index);

  /// Structured JFLAP XML diagnostic for a missing automaton element.
  ///
  /// In en, this message translates to:
  /// **'The JFLAP file does not contain an automaton element.'**
  String get parserJflapXmlMissingAutomatonElement;

  /// Structured JFLAP XML diagnostic for an empty automaton.
  ///
  /// In en, this message translates to:
  /// **'The JFLAP automaton has no states and cannot be loaded into the editor.'**
  String get parserJflapXmlEmptyAutomaton;

  /// Structured JFLAP XML diagnostic for an incomplete transition.
  ///
  /// In en, this message translates to:
  /// **'The transition at index {index} must contain origin and destination states.'**
  String parserJflapXmlIncompleteTransition(int index);

  /// Structured JFLAP XML diagnostic for unknown transition endpoints.
  ///
  /// In en, this message translates to:
  /// **'The transition from {fromState} to {toState} references an unknown state.'**
  String parserJflapXmlUnknownTransitionEndpoints(
    String fromState,
    String toState,
  );

  /// Structured JFLAP XML diagnostic for an unexpected root element.
  ///
  /// In en, this message translates to:
  /// **'The JFLAP document root must be structure, not {actual}.'**
  String parserJflapXmlUnexpectedRootElement(String actual);

  /// Safe fallback for an unknown structured domain message.
  ///
  /// In en, this message translates to:
  /// **'Message unavailable ({code}).'**
  String structuredMessageUnknown(String code);

  /// No description provided for @transducerNoTrace.
  ///
  /// In en, this message translates to:
  /// **'No trace steps'**
  String get transducerNoTrace;

  /// No description provided for @transducerEmptyInput.
  ///
  /// In en, this message translates to:
  /// **'empty input'**
  String get transducerEmptyInput;

  /// No description provided for @transducerRemainingInputPreview.
  ///
  /// In en, this message translates to:
  /// **'{preview} ({count} tokens remaining)'**
  String transducerRemainingInputPreview(String preview, int count);

  /// No description provided for @transducerTraceStep.
  ///
  /// In en, this message translates to:
  /// **'Step {step}: {source} to {target} with {transition}'**
  String transducerTraceStep(
    int step,
    String source,
    String target,
    String transition,
  );

  /// No description provided for @transducerTraceDetails.
  ///
  /// In en, this message translates to:
  /// **'Consumed {consumed}; remaining {remaining}; emitted {emitted}; cumulative {cumulative}'**
  String transducerTraceDetails(
    String consumed,
    String remaining,
    String emitted,
    String cumulative,
  );

  /// No description provided for @transducerMachineInfo.
  ///
  /// In en, this message translates to:
  /// **'Machine details'**
  String get transducerMachineInfo;

  /// No description provided for @transducerMachineValid.
  ///
  /// In en, this message translates to:
  /// **'Valid machine'**
  String get transducerMachineValid;

  /// No description provided for @transducerMachineInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid machine'**
  String get transducerMachineInvalid;

  /// No description provided for @transducerMachineDeterministic.
  ///
  /// In en, this message translates to:
  /// **'Deterministic'**
  String get transducerMachineDeterministic;

  /// No description provided for @transducerMachineNondeterministic.
  ///
  /// In en, this message translates to:
  /// **'Nondeterministic'**
  String get transducerMachineNondeterministic;

  /// No description provided for @transducerMachineComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete transition function'**
  String get transducerMachineComplete;

  /// No description provided for @transducerMachinePartial.
  ///
  /// In en, this message translates to:
  /// **'Partial transition function'**
  String get transducerMachinePartial;

  /// Structured transducer analysis diagnostic for a missing initial state.
  ///
  /// In en, this message translates to:
  /// **'Choose one initial state.'**
  String get transducerAnalysisMissingInitialState;

  /// Structured transducer analysis diagnostic for multiple initial states.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{The machine has one initial state.} other{The machine has {count} initial states.}}'**
  String transducerAnalysisMultipleInitialStates(int count);

  /// Structured transducer analysis diagnostic for a duplicate state identifier.
  ///
  /// In en, this message translates to:
  /// **'State identifier {state} is duplicated.'**
  String transducerAnalysisDuplicateStateId(String state);

  /// Structured transducer analysis diagnostic for a duplicate transition identifier.
  ///
  /// In en, this message translates to:
  /// **'Transition identifier {transition} is duplicated.'**
  String transducerAnalysisDuplicateTransitionId(String transition);

  /// Structured transducer analysis diagnostic for a missing source state.
  ///
  /// In en, this message translates to:
  /// **'Transition {transition} starts at a missing state.'**
  String transducerAnalysisDanglingSourceState(String transition);

  /// Structured transducer analysis diagnostic for a missing target state.
  ///
  /// In en, this message translates to:
  /// **'Transition {transition} points to a missing state.'**
  String transducerAnalysisDanglingTargetState(String transition);

  /// Structured transducer analysis diagnostic for an input outside the alphabet.
  ///
  /// In en, this message translates to:
  /// **'Transition {transition} uses input {symbol}, which is outside the alphabet.'**
  String transducerAnalysisInputSymbolOutsideAlphabet(
    String transition,
    String symbol,
  );

  /// Structured transducer analysis diagnostic for an output outside the alphabet.
  ///
  /// In en, this message translates to:
  /// **'The output for {subject} uses {symbol}, which is outside the alphabet.'**
  String transducerAnalysisOutputSymbolOutsideAlphabet(
    String subject,
    String symbol,
  );

  /// Structured transducer analysis diagnostic for nondeterminism.
  ///
  /// In en, this message translates to:
  /// **'State {state} has more than one transition for input {symbol}.'**
  String transducerAnalysisNondeterministicTransition(
    String state,
    String symbol,
  );

  /// Structured transducer analysis warning for an incomplete transition function.
  ///
  /// In en, this message translates to:
  /// **'State {state} has no unique transition for input {symbol}.'**
  String transducerAnalysisIncompleteTransitionFunction(
    String state,
    String symbol,
  );

  /// Structured transducer analysis diagnostic for an empty identifier.
  ///
  /// In en, this message translates to:
  /// **'{entity, select, machine{The machine identifier cannot be empty.} state{A state identifier cannot be empty.} transition{A transition identifier cannot be empty.} other{An identifier cannot be empty.}}'**
  String transducerAnalysisEmptyIdentifier(String entity);

  /// Structured transducer analysis diagnostic for an empty input symbol.
  ///
  /// In en, this message translates to:
  /// **'The input symbol for {subject} cannot be empty.'**
  String transducerAnalysisEmptyInputSymbol(String subject);

  /// Structured transducer analysis diagnostic for an empty output symbol.
  ///
  /// In en, this message translates to:
  /// **'The output symbol for {subject} cannot be empty.'**
  String transducerAnalysisEmptyOutputSymbol(String subject);

  /// Structured transducer analysis diagnostic for a negative revision.
  ///
  /// In en, this message translates to:
  /// **'Document revision {revision} is invalid.'**
  String transducerAnalysisNegativeRevision(int revision);

  /// No description provided for @transducerInputAlphabet.
  ///
  /// In en, this message translates to:
  /// **'Input alphabet'**
  String get transducerInputAlphabet;

  /// No description provided for @transducerOutputAlphabet.
  ///
  /// In en, this message translates to:
  /// **'Output alphabet'**
  String get transducerOutputAlphabet;

  /// No description provided for @transducerAlphabetHint.
  ///
  /// In en, this message translates to:
  /// **'One symbol per line'**
  String get transducerAlphabetHint;

  /// No description provided for @transducerApplyAlphabets.
  ///
  /// In en, this message translates to:
  /// **'Apply alphabets'**
  String get transducerApplyAlphabets;

  /// No description provided for @transducerEditTransition.
  ///
  /// In en, this message translates to:
  /// **'Edit transducer transition'**
  String get transducerEditTransition;

  /// No description provided for @transducerDeleteTransition.
  ///
  /// In en, this message translates to:
  /// **'Delete transition'**
  String get transducerDeleteTransition;

  /// No description provided for @transducerDeleteState.
  ///
  /// In en, this message translates to:
  /// **'Delete state'**
  String get transducerDeleteState;

  /// No description provided for @transducerEditState.
  ///
  /// In en, this message translates to:
  /// **'Edit transducer state'**
  String get transducerEditState;

  /// No description provided for @transducerStateName.
  ///
  /// In en, this message translates to:
  /// **'State name'**
  String get transducerStateName;

  /// No description provided for @transducerInitialState.
  ///
  /// In en, this message translates to:
  /// **'Initial state'**
  String get transducerInitialState;

  /// No description provided for @transducerSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get transducerSave;

  /// No description provided for @transducerExamples.
  ///
  /// In en, this message translates to:
  /// **'Examples'**
  String get transducerExamples;

  /// No description provided for @transducerExamplesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Examples are not available for this workspace.'**
  String get transducerExamplesUnavailable;

  /// No description provided for @transducerExamplesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Examples could not be loaded.'**
  String get transducerExamplesLoadFailed;

  /// No description provided for @transducerExamplesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No examples are available yet.'**
  String get transducerExamplesEmpty;

  /// No description provided for @mealyExampleIdentityName.
  ///
  /// In en, this message translates to:
  /// **'Identity transducer'**
  String get mealyExampleIdentityName;

  /// No description provided for @mealyExampleIdentityDescription.
  ///
  /// In en, this message translates to:
  /// **'Emits each binary input symbol unchanged.'**
  String get mealyExampleIdentityDescription;

  /// No description provided for @mealyExampleParityName.
  ///
  /// In en, this message translates to:
  /// **'Parity output'**
  String get mealyExampleParityName;

  /// No description provided for @mealyExampleParityDescription.
  ///
  /// In en, this message translates to:
  /// **'Emits the parity after each binary input symbol.'**
  String get mealyExampleParityDescription;

  /// No description provided for @mealyExampleSequenceName.
  ///
  /// In en, this message translates to:
  /// **'Sequence detector'**
  String get mealyExampleSequenceName;

  /// No description provided for @mealyExampleSequenceDescription.
  ///
  /// In en, this message translates to:
  /// **'Emits 1 when the latest two symbols are ab.'**
  String get mealyExampleSequenceDescription;

  /// No description provided for @mealyExamplePartialName.
  ///
  /// In en, this message translates to:
  /// **'Partial transducer'**
  String get mealyExamplePartialName;

  /// No description provided for @mealyExamplePartialDescription.
  ///
  /// In en, this message translates to:
  /// **'Stops when input b has no transition from the current state.'**
  String get mealyExamplePartialDescription;

  /// No description provided for @mooreExampleParityName.
  ///
  /// In en, this message translates to:
  /// **'Parity state output'**
  String get mooreExampleParityName;

  /// No description provided for @mooreExampleParityDescription.
  ///
  /// In en, this message translates to:
  /// **'Reports even or odd parity from the current state.'**
  String get mooreExampleParityDescription;

  /// No description provided for @mooreExampleVendingName.
  ///
  /// In en, this message translates to:
  /// **'Vending control'**
  String get mooreExampleVendingName;

  /// No description provided for @mooreExampleVendingDescription.
  ///
  /// In en, this message translates to:
  /// **'Reports whether the vending controller is ready.'**
  String get mooreExampleVendingDescription;

  /// No description provided for @mooreExampleSequenceName.
  ///
  /// In en, this message translates to:
  /// **'Sequence detector'**
  String get mooreExampleSequenceName;

  /// No description provided for @mooreExampleSequenceDescription.
  ///
  /// In en, this message translates to:
  /// **'Reports when the latest input suffix matches 10.'**
  String get mooreExampleSequenceDescription;

  /// No description provided for @mooreExamplePartialName.
  ///
  /// In en, this message translates to:
  /// **'Partial Moore machine'**
  String get mooreExamplePartialName;

  /// No description provided for @mooreExamplePartialDescription.
  ///
  /// In en, this message translates to:
  /// **'Demonstrates undefined input without treating it as invalid.'**
  String get mooreExamplePartialDescription;

  /// Label shown before locale-neutral example inputs.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Suggested simulation} other{Suggested simulations}}'**
  String exampleSuggestedSimulationLabel(int count);

  /// Accessible description of the locale-neutral inputs suggested for an example.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Suggested simulation: {inputs}.} other{Suggested simulations: {inputs}.}}'**
  String exampleSuggestedSimulationSemantics(int count, String inputs);

  /// No description provided for @transducerBatch.
  ///
  /// In en, this message translates to:
  /// **'Batch inputs'**
  String get transducerBatch;

  /// No description provided for @transducerBatchHint.
  ///
  /// In en, this message translates to:
  /// **'One JSON token array per line, for example [\"a\",\"b\"]'**
  String get transducerBatchHint;

  /// No description provided for @transducerBatchInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Input token arrays'**
  String get transducerBatchInputLabel;

  /// No description provided for @transducerBatchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No batch inputs were provided.'**
  String get transducerBatchEmpty;

  /// No description provided for @transducerBatchSuccess.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get transducerBatchSuccess;

  /// No description provided for @transducerRunBatch.
  ///
  /// In en, this message translates to:
  /// **'Run batch'**
  String get transducerRunBatch;

  /// No description provided for @transducerComparison.
  ///
  /// In en, this message translates to:
  /// **'Compare outputs'**
  String get transducerComparison;

  /// No description provided for @transducerComparisonMode.
  ///
  /// In en, this message translates to:
  /// **'Comparison mode'**
  String get transducerComparisonMode;

  /// No description provided for @transducerComparisonExact.
  ///
  /// In en, this message translates to:
  /// **'Exact'**
  String get transducerComparisonExact;

  /// No description provided for @transducerComparisonBounded.
  ///
  /// In en, this message translates to:
  /// **'Bounded'**
  String get transducerComparisonBounded;

  /// No description provided for @transducerComparisonBound.
  ///
  /// In en, this message translates to:
  /// **'Maximum input length'**
  String get transducerComparisonBound;

  /// No description provided for @transducerCompareWithExample.
  ///
  /// In en, this message translates to:
  /// **'Compare with example'**
  String get transducerCompareWithExample;

  /// No description provided for @transducerCompare.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get transducerCompare;

  /// No description provided for @transducerComparisonResult.
  ///
  /// In en, this message translates to:
  /// **'Comparison result: {result}'**
  String transducerComparisonResult(String result);

  /// No description provided for @transducerLoadExample.
  ///
  /// In en, this message translates to:
  /// **'Load example'**
  String get transducerLoadExample;

  /// No description provided for @transducerNoComparisonMachine.
  ///
  /// In en, this message translates to:
  /// **'Choose a second machine.'**
  String get transducerNoComparisonMachine;

  /// No description provided for @transducerExactEquivalent.
  ///
  /// In en, this message translates to:
  /// **'Exactly equivalent'**
  String get transducerExactEquivalent;

  /// No description provided for @transducerExactDifferent.
  ///
  /// In en, this message translates to:
  /// **'Different, with an exact witness'**
  String get transducerExactDifferent;

  /// No description provided for @transducerBoundedDifferent.
  ///
  /// In en, this message translates to:
  /// **'Different within the selected bound'**
  String get transducerBoundedDifferent;

  /// No description provided for @transducerBoundedInconclusive.
  ///
  /// In en, this message translates to:
  /// **'No difference found within the selected bound'**
  String get transducerBoundedInconclusive;

  /// No description provided for @transducerComparisonInvalid.
  ///
  /// In en, this message translates to:
  /// **'The machines cannot be compared with this mode.'**
  String get transducerComparisonInvalid;

  /// No description provided for @transducerLeftOutput.
  ///
  /// In en, this message translates to:
  /// **'Current output'**
  String get transducerLeftOutput;

  /// No description provided for @transducerRightOutput.
  ///
  /// In en, this message translates to:
  /// **'Compared output'**
  String get transducerRightOutput;

  /// No description provided for @transducerWitness.
  ///
  /// In en, this message translates to:
  /// **'Witness input'**
  String get transducerWitness;

  /// No description provided for @transducerInvalidBatchLine.
  ///
  /// In en, this message translates to:
  /// **'Line {line} must be a JSON array of strings.'**
  String transducerInvalidBatchLine(int line);

  /// No description provided for @transducerSelectedMachine.
  ///
  /// In en, this message translates to:
  /// **'Selected machine: {name}'**
  String transducerSelectedMachine(String name);

  /// No description provided for @transducerExploredPairs.
  ///
  /// In en, this message translates to:
  /// **'Explored pairs: {count}'**
  String transducerExploredPairs(int count);

  /// Title shown when application dependencies cannot be initialized.
  ///
  /// In en, this message translates to:
  /// **'Turing Lab could not finish startup.'**
  String get initializationErrorTitle;

  /// Recovery guidance shown when application startup fails.
  ///
  /// In en, this message translates to:
  /// **'Restart the app. Local settings and trace persistence may be unavailable until initialization succeeds.'**
  String get initializationErrorMessage;

  /// Heading above links to related help topics.
  ///
  /// In en, this message translates to:
  /// **'Related topics'**
  String get helpRelatedTopics;

  /// Title shown when a requested help topic cannot be displayed.
  ///
  /// In en, this message translates to:
  /// **'This help topic is not available.'**
  String get helpTopicUnavailable;

  /// Recovery guidance for an unavailable help topic.
  ///
  /// In en, this message translates to:
  /// **'Browse the help tree or search for another topic.'**
  String get helpTopicUnavailableDescription;

  /// Accessibility label for the contextual help panel.
  ///
  /// In en, this message translates to:
  /// **'Contextual help panel'**
  String get contextualHelpPanelLabel;

  /// Tooltip and accessibility label for closing contextual help.
  ///
  /// In en, this message translates to:
  /// **'Close help panel'**
  String get closeHelpPanel;

  /// Action that opens the complete related-help list.
  ///
  /// In en, this message translates to:
  /// **'View all related help'**
  String get viewAllRelatedHelp;

  /// Heading for additional help links.
  ///
  /// In en, this message translates to:
  /// **'More Help'**
  String get moreHelp;

  /// Label for the central help destination.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// Tooltip for the workspace simulation action.
  ///
  /// In en, this message translates to:
  /// **'Simulate'**
  String get workspaceSimulateTooltip;

  /// Tooltip for the workspace algorithms action.
  ///
  /// In en, this message translates to:
  /// **'Algorithms'**
  String get workspaceAlgorithmsTooltip;

  /// Tooltip for the combined workspace algorithms and examples action.
  ///
  /// In en, this message translates to:
  /// **'Algorithms & Examples'**
  String get workspaceAlgorithmsAndExamplesTooltip;

  /// Tooltip for the workspace parser action.
  ///
  /// In en, this message translates to:
  /// **'Parser'**
  String get workspaceParserTooltip;

  /// Tooltip for the workspace edit action.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get workspaceEditTooltip;

  /// Tooltip for the workspace metrics action.
  ///
  /// In en, this message translates to:
  /// **'Metrics'**
  String get workspaceMetricsTooltip;

  /// Tooltip for the workspace overflow menu.
  ///
  /// In en, this message translates to:
  /// **'More workspace actions'**
  String get workspaceMoreActionsTooltip;

  /// Tooltip for opening workspace examples.
  ///
  /// In en, this message translates to:
  /// **'Examples'**
  String get workspaceExamplesTooltip;

  /// Tooltip while workspace examples are loading.
  ///
  /// In en, this message translates to:
  /// **'Loading examples'**
  String get workspaceExamplesLoadingTooltip;

  /// Tooltip when workspace examples cannot be opened.
  ///
  /// In en, this message translates to:
  /// **'Examples unavailable'**
  String get workspaceExamplesUnavailableTooltip;

  /// Error message shown when workspace examples fail to load.
  ///
  /// In en, this message translates to:
  /// **'Examples could not be loaded.'**
  String get workspaceExamplesLoadFailed;

  /// Empty-state message for a workspace with no examples.
  ///
  /// In en, this message translates to:
  /// **'No examples are available yet.'**
  String get workspaceExamplesEmpty;

  /// Accessibility label for the keyboard shortcuts dialog.
  ///
  /// In en, this message translates to:
  /// **'Keyboard shortcuts dialog'**
  String get keyboardShortcutsDialogLabel;

  /// Title of the keyboard shortcuts dialog.
  ///
  /// In en, this message translates to:
  /// **'Keyboard Shortcuts'**
  String get keyboardShortcutsTitle;

  /// Heading for canvas keyboard shortcuts.
  ///
  /// In en, this message translates to:
  /// **'Canvas Operations'**
  String get keyboardShortcutsCanvasOperations;

  /// Heading for simulation keyboard shortcuts.
  ///
  /// In en, this message translates to:
  /// **'Simulation Controls'**
  String get keyboardShortcutsSimulationControls;

  /// Heading for dialog keyboard shortcuts.
  ///
  /// In en, this message translates to:
  /// **'Dialog Shortcuts'**
  String get keyboardShortcutsDialogShortcuts;

  /// Tooltip and accessibility label for closing the shortcuts dialog.
  ///
  /// In en, this message translates to:
  /// **'Close shortcuts dialog'**
  String get closeShortcutsDialog;

  /// Word placed between alternative keyboard shortcuts.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get shortcutAlternativeSeparator;

  /// Label for the developer field on the About page.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get aboutDeveloperLabel;

  /// Label for the project repository link.
  ///
  /// In en, this message translates to:
  /// **'Project repository'**
  String get aboutProjectRepositoryLabel;

  /// Error shown when the project repository link cannot be opened.
  ///
  /// In en, this message translates to:
  /// **'Could not open the project repository.'**
  String get aboutProjectOpenError;

  /// Heading for open-source license information.
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get aboutOpenSourceLicenses;

  /// Introductory compatibility notice above the license list.
  ///
  /// In en, this message translates to:
  /// **'Turing Lab is a Flutter reimplementation inspired by and compatible with JFLAP. It is not an official JFLAP release.'**
  String get aboutLicensesIntro;

  /// Summary of the Turing Lab source-code license.
  ///
  /// In en, this message translates to:
  /// **'Turing Lab original Flutter code is licensed under Apache 2.0.'**
  String get aboutTuringLabLicenseSummary;

  /// Summary of the license for JFLAP-derived material.
  ///
  /// In en, this message translates to:
  /// **'JFLAP-derived portions remain under the JFLAP 7.1 License.'**
  String get aboutJflapLicenseSummary;

  /// Summary of the vendored GraphView fork license.
  ///
  /// In en, this message translates to:
  /// **'Graph visualization library, forked and modified for Turing Lab. Original work by Nabil Mosharraf.'**
  String get aboutGraphViewLicenseSummary;

  /// Summary of bundled Apple-platform third-party notices.
  ///
  /// In en, this message translates to:
  /// **'Bundled notices for the vendored GraphView fork and Apple-platform plugin dependencies.'**
  String get aboutAppleNoticesSummary;

  /// Title for Apple-platform third-party notices.
  ///
  /// In en, this message translates to:
  /// **'Apple Platform Third-Party Notices'**
  String get aboutAppleNoticesTitle;

  /// Heading for Flutter package licenses.
  ///
  /// In en, this message translates to:
  /// **'Package licenses'**
  String get aboutPackageLicenses;

  /// Description of the Flutter package license list.
  ///
  /// In en, this message translates to:
  /// **'Licenses reported by Flutter for bundled Dart and Flutter packages.'**
  String get aboutPackageLicensesDescription;

  /// Heading for JFLAP acknowledgments.
  ///
  /// In en, this message translates to:
  /// **'JFLAP Acknowledgments'**
  String get aboutAcknowledgments;

  /// Acknowledgment of JFLAP's original creator and maintainer.
  ///
  /// In en, this message translates to:
  /// **'Original JFLAP creator and maintainer, Duke University.'**
  String get aboutJflapCreator;

  /// Names of acknowledged JFLAP contributors.
  ///
  /// In en, this message translates to:
  /// **'Thomas Finley, Ryan Cavalcante, Stephen Reading, Bart Bressler, Jinghui Lim, Chris Morgan, Kyung Min (Jason) Lee, Jonathan Su, and Henry Qin.'**
  String get aboutJflapTeam;

  /// Label and URL for the original JFLAP project.
  ///
  /// In en, this message translates to:
  /// **'JFLAP website: http://www.jflap.org'**
  String get aboutOriginalProject;

  /// Heading for the original JFLAP project.
  ///
  /// In en, this message translates to:
  /// **'Original Project'**
  String get aboutOriginalProjectTitle;

  /// Description of the vendored GraphView fork.
  ///
  /// In en, this message translates to:
  /// **'Turing Lab vendors a maintained fork of GraphView under the MIT license; Apple-platform third-party notices are bundled here.'**
  String get aboutGraphViewFork;

  /// Heading for the GraphView fork acknowledgment.
  ///
  /// In en, this message translates to:
  /// **'GraphView Fork'**
  String get aboutGraphViewForkTitle;

  /// Heading for the distribution notice.
  ///
  /// In en, this message translates to:
  /// **'Distribution'**
  String get aboutDistribution;

  /// Distribution terms for builds containing JFLAP-derived material.
  ///
  /// In en, this message translates to:
  /// **'Turing Lab is distributed as a free, non-monetized educational app while it includes JFLAP-derived material.'**
  String get aboutDistributionDescription;

  /// Prompt shown before lazily loading bundled license text.
  ///
  /// In en, this message translates to:
  /// **'Expand to load bundled license text.'**
  String get aboutLicenseExpandPrompt;

  /// Progress message while bundled license text is loading.
  ///
  /// In en, this message translates to:
  /// **'Loading bundled license text...'**
  String get aboutLicenseLoading;

  /// Generic error shown when bundled license text cannot be loaded.
  ///
  /// In en, this message translates to:
  /// **'Failed to load license. Try again.'**
  String get aboutLicenseLoadFailed;

  /// Accessibility label for expanding a help disclosure.
  ///
  /// In en, this message translates to:
  /// **'Expand {title}'**
  String helpDisclosureExpandSemanticLabel(String title);

  /// Accessibility label for collapsing a help disclosure.
  ///
  /// In en, this message translates to:
  /// **'Collapse {title}'**
  String helpDisclosureCollapseSemanticLabel(String title);

  /// Number of matching help search results.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 results} =1{1 result} other{{count} results}}'**
  String helpSearchResultCount(int count);

  /// Accessibility label for a help topic.
  ///
  /// In en, this message translates to:
  /// **'Help topic: {title}'**
  String helpTopicSemanticLabel(String title);

  /// Tooltip for opening help related to a named workspace or control.
  ///
  /// In en, this message translates to:
  /// **'Show help for {title}'**
  String showHelpFor(String title);

  /// Accessibility label for navigating to a named destination.
  ///
  /// In en, this message translates to:
  /// **'Navigate to {label}'**
  String navigateTo(String label);

  /// Accessibility label for the current workspace selector.
  ///
  /// In en, this message translates to:
  /// **'Workspace: {label}'**
  String workspaceSelectorLabel(String label);

  /// Accessibility hint for the workspace selector.
  ///
  /// In en, this message translates to:
  /// **'Switch workspace'**
  String get workspaceSelectorHint;

  /// Tooltip for opening a named workspace dock panel.
  ///
  /// In en, this message translates to:
  /// **'Show {label}'**
  String workspaceDockShowPanel(String label);

  /// Tooltip for closing a named workspace dock panel.
  ///
  /// In en, this message translates to:
  /// **'Hide {label}'**
  String workspaceDockHidePanel(String label);

  /// Accessibility label for the workspace dock resize handle.
  ///
  /// In en, this message translates to:
  /// **'Resize panel'**
  String get workspaceDockResizePanel;

  /// Error shown when contextual help cannot be loaded.
  ///
  /// In en, this message translates to:
  /// **'Unable to load help for \"{category}\".'**
  String unableToLoadHelp(String category);

  /// Empty-state message when a help category has no items.
  ///
  /// In en, this message translates to:
  /// **'No help items found for \"{category}\".'**
  String noHelpItemsFound(String category);

  /// Setting that includes document notes in rendered image exports.
  ///
  /// In en, this message translates to:
  /// **'Include notes in visual exports'**
  String get includeNotesInVisualExports;

  /// Scope explanation for including notes in visual exports.
  ///
  /// In en, this message translates to:
  /// **'Applies to SVG and PNG. Document exports always preserve notes.'**
  String get includeNotesInVisualExportsDescription;

  /// Title of the document note manager.
  ///
  /// In en, this message translates to:
  /// **'Document notes'**
  String get documentNotesTitle;

  /// Description of document notes.
  ///
  /// In en, this message translates to:
  /// **'Non-semantic notes and annotations'**
  String get documentNotesDescription;

  /// No description provided for @documentNoteUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo note change'**
  String get documentNoteUndo;

  /// No description provided for @documentNoteRedo.
  ///
  /// In en, this message translates to:
  /// **'Redo note change'**
  String get documentNoteRedo;

  /// No description provided for @documentNoteAdd.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get documentNoteAdd;

  /// No description provided for @documentNoteSearch.
  ///
  /// In en, this message translates to:
  /// **'Search notes'**
  String get documentNoteSearch;

  /// No description provided for @documentNoteNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matching notes.'**
  String get documentNoteNoMatches;

  /// No description provided for @documentNoteEmpty.
  ///
  /// In en, this message translates to:
  /// **'Empty note'**
  String get documentNoteEmpty;

  /// No description provided for @documentNoteFree.
  ///
  /// In en, this message translates to:
  /// **'Free note'**
  String get documentNoteFree;

  /// Localized note attachment type followed by the user-authored target identifier.
  ///
  /// In en, this message translates to:
  /// **'{type}: {target}'**
  String documentNoteAttachment(String type, String target);

  /// No description provided for @documentNoteActions.
  ///
  /// In en, this message translates to:
  /// **'Note actions'**
  String get documentNoteActions;

  /// No description provided for @documentNoteDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get documentNoteDuplicate;

  /// No description provided for @documentNoteDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete note?'**
  String get documentNoteDeleteTitle;

  /// No description provided for @documentNoteDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'This removes the note from this document.'**
  String get documentNoteDeleteMessage;

  /// Screen-reader label that preserves the user-authored note text.
  ///
  /// In en, this message translates to:
  /// **'Note: {text}'**
  String documentNoteSemantics(String text);

  /// No description provided for @documentNoteKeyboardHint.
  ///
  /// In en, this message translates to:
  /// **'Press Enter to edit. Control D duplicates. Control C collapses.'**
  String get documentNoteKeyboardHint;

  /// No description provided for @documentNoteExpand.
  ///
  /// In en, this message translates to:
  /// **'Expand note'**
  String get documentNoteExpand;

  /// No description provided for @documentNoteCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse note'**
  String get documentNoteCollapse;

  /// No description provided for @documentNoteResize.
  ///
  /// In en, this message translates to:
  /// **'Resize note'**
  String get documentNoteResize;

  /// No description provided for @documentNoteEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get documentNoteEditTitle;

  /// No description provided for @documentNoteTextLabel.
  ///
  /// In en, this message translates to:
  /// **'Note text'**
  String get documentNoteTextLabel;

  /// No description provided for @documentNoteTextHelp.
  ///
  /// In en, this message translates to:
  /// **'Use **bold**, _italic_, or `code`. Links and HTML are not interpreted.'**
  String get documentNoteTextHelp;

  /// No description provided for @documentNoteStyleLabel.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get documentNoteStyleLabel;

  /// No description provided for @documentNoteAttachmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get documentNoteAttachmentLabel;

  /// No description provided for @documentNoteNoAttachment.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get documentNoteNoAttachment;

  /// No description provided for @documentNoteTargetIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Target ID'**
  String get documentNoteTargetIdLabel;

  /// No description provided for @documentNoteStyleNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get documentNoteStyleNote;

  /// No description provided for @documentNoteStyleInformation.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get documentNoteStyleInformation;

  /// No description provided for @documentNoteStyleWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get documentNoteStyleWarning;

  /// No description provided for @documentNoteStyleQuestion.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get documentNoteStyleQuestion;

  /// No description provided for @documentNoteStyleTodo.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get documentNoteStyleTodo;

  /// No description provided for @documentNoteTargetCanvas.
  ///
  /// In en, this message translates to:
  /// **'Canvas'**
  String get documentNoteTargetCanvas;

  /// No description provided for @documentNoteTargetState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get documentNoteTargetState;

  /// No description provided for @documentNoteTargetTransition.
  ///
  /// In en, this message translates to:
  /// **'Transition'**
  String get documentNoteTargetTransition;

  /// No description provided for @documentNoteTargetProduction.
  ///
  /// In en, this message translates to:
  /// **'Production'**
  String get documentNoteTargetProduction;

  /// No description provided for @documentNoteTargetTableCell.
  ///
  /// In en, this message translates to:
  /// **'Table cell'**
  String get documentNoteTargetTableCell;

  /// No description provided for @automatonFragmentFilePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Import compatible automaton'**
  String get automatonFragmentFilePickerTitle;

  /// No description provided for @automatonFragmentUnreadableFile.
  ///
  /// In en, this message translates to:
  /// **'The selected file could not be read.'**
  String get automatonFragmentUnreadableFile;

  /// Success message after combining an automaton.
  ///
  /// In en, this message translates to:
  /// **'Imported {states, plural, =1{1 state} other{{states} states}} and {transitions, plural, =1{1 transition} other{{transitions} transitions}}.'**
  String automatonFragmentImportedSummary(int states, int transitions);

  /// No description provided for @automatonFragmentImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Automaton import failed: {error}'**
  String automatonFragmentImportFailed(String error);

  /// No description provided for @automatonFragmentCannotImport.
  ///
  /// In en, this message translates to:
  /// **'Cannot import automaton'**
  String get automatonFragmentCannotImport;

  /// No description provided for @automatonFragmentPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Preview automaton import'**
  String get automatonFragmentPreviewTitle;

  /// No description provided for @automatonFragmentSourceFidelity.
  ///
  /// In en, this message translates to:
  /// **'Source fidelity: {fidelity}. The source and destination remain unchanged until Apply.'**
  String automatonFragmentSourceFidelity(String fidelity);

  /// No description provided for @automatonFragmentStatesToImport.
  ///
  /// In en, this message translates to:
  /// **'States to import'**
  String get automatonFragmentStatesToImport;

  /// No description provided for @automatonFragmentInsertionAnchor.
  ///
  /// In en, this message translates to:
  /// **'Insertion anchor'**
  String get automatonFragmentInsertionAnchor;

  /// No description provided for @automatonFragmentInitialStateAfterImport.
  ///
  /// In en, this message translates to:
  /// **'Initial state after import'**
  String get automatonFragmentInitialStateAfterImport;

  /// No description provided for @automatonFragmentKeepCurrentInitialState.
  ///
  /// In en, this message translates to:
  /// **'Keep current initial state'**
  String get automatonFragmentKeepCurrentInitialState;

  /// No description provided for @automatonFragmentUseImportedInitialState.
  ///
  /// In en, this message translates to:
  /// **'Use imported initial state'**
  String get automatonFragmentUseImportedInitialState;

  /// No description provided for @automatonFragmentUseDestinationAcceptance.
  ///
  /// In en, this message translates to:
  /// **'Use the destination PDA acceptance mode'**
  String get automatonFragmentUseDestinationAcceptance;

  /// No description provided for @automatonFragmentSourceModeDiffers.
  ///
  /// In en, this message translates to:
  /// **'Required because the source mode differs.'**
  String get automatonFragmentSourceModeDiffers;

  /// No description provided for @automatonFragmentUseDestinationStackSymbol.
  ///
  /// In en, this message translates to:
  /// **'Use the destination initial stack symbol'**
  String get automatonFragmentUseDestinationStackSymbol;

  /// No description provided for @automatonFragmentSourceSymbolDiffers.
  ///
  /// In en, this message translates to:
  /// **'Required because the source symbol differs.'**
  String get automatonFragmentSourceSymbolDiffers;

  /// No description provided for @automatonFragmentExactChanges.
  ///
  /// In en, this message translates to:
  /// **'Exact changes'**
  String get automatonFragmentExactChanges;

  /// No description provided for @automatonFragmentCloneSummary.
  ///
  /// In en, this message translates to:
  /// **'{states, plural, =1{1 state} other{{states} states}}, {transitions, plural, =1{1 transition} other{{transitions} transitions}}, {notes, plural, =1{1 note} other{{notes} notes}}, and {blocks, plural, =1{1 reusable block} other{{blocks} reusable blocks}} will be cloned.'**
  String automatonFragmentCloneSummary(
    int states,
    int transitions,
    int notes,
    int blocks,
  );

  /// No description provided for @automatonFragmentStructuralImportExplanation.
  ///
  /// In en, this message translates to:
  /// **'This is a disconnected structural import. Algebraic operations and opening or replacing documents remain separate workflows.'**
  String get automatonFragmentStructuralImportExplanation;

  /// No description provided for @automatonFragmentInputAlphabet.
  ///
  /// In en, this message translates to:
  /// **'Input alphabet'**
  String get automatonFragmentInputAlphabet;

  /// No description provided for @automatonFragmentOutputAlphabet.
  ///
  /// In en, this message translates to:
  /// **'Output alphabet'**
  String get automatonFragmentOutputAlphabet;

  /// No description provided for @automatonFragmentStackAlphabet.
  ///
  /// In en, this message translates to:
  /// **'Stack alphabet'**
  String get automatonFragmentStackAlphabet;

  /// No description provided for @automatonFragmentTapeAlphabet.
  ///
  /// In en, this message translates to:
  /// **'Tape alphabet'**
  String get automatonFragmentTapeAlphabet;

  /// No description provided for @automatonFragmentAcceptanceModeUnchanged.
  ///
  /// In en, this message translates to:
  /// **'Acceptance mode remains {mode}.'**
  String automatonFragmentAcceptanceModeUnchanged(String mode);

  /// No description provided for @automatonFragmentInitialStackSymbolUnchanged.
  ///
  /// In en, this message translates to:
  /// **'Initial stack symbol remains {symbol}.'**
  String automatonFragmentInitialStackSymbolUnchanged(String symbol);

  /// No description provided for @automatonFragmentTapeConfigurationUnchanged.
  ///
  /// In en, this message translates to:
  /// **'Tape configuration remains {count, plural, =1{1 tape} other{{count} tapes}} with blank symbol {symbol}.'**
  String automatonFragmentTapeConfigurationUnchanged(int count, String symbol);

  /// No description provided for @automatonFragmentInitialStateUnchanged.
  ///
  /// In en, this message translates to:
  /// **'Initial state remains {state}.'**
  String automatonFragmentInitialStateUnchanged(String state);

  /// No description provided for @automatonFragmentInitialStateChanged.
  ///
  /// In en, this message translates to:
  /// **'Initial state changes from {before} to {after}.'**
  String automatonFragmentInitialStateChanged(String before, String after);

  /// No description provided for @automatonFragmentUnset.
  ///
  /// In en, this message translates to:
  /// **'unset'**
  String get automatonFragmentUnset;

  /// No description provided for @automatonFragmentSetUnchanged.
  ///
  /// In en, this message translates to:
  /// **'{label} is unchanged.'**
  String automatonFragmentSetUnchanged(String label);

  /// No description provided for @automatonFragmentSetAdds.
  ///
  /// In en, this message translates to:
  /// **'{label} adds: {symbols}.'**
  String automatonFragmentSetAdds(String label, String symbols);

  /// Fallback when an operation fails without a specific error message.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknownError;

  /// Fallback error shown when a selected file cannot be read.
  ///
  /// In en, this message translates to:
  /// **'File read failed.'**
  String get fileReadFailed;

  /// Error shown when a selected file has neither accessible bytes nor a readable path.
  ///
  /// In en, this message translates to:
  /// **'Selected file bytes are unavailable.'**
  String get selectedFileBytesUnavailable;

  /// Title of the dialog shown before deleting a canvas target with attached notes.
  ///
  /// In en, this message translates to:
  /// **'Attached notes'**
  String get attachedNotesTitle;

  /// Warning shown before deleting a state whose state or incident transitions have attached notes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 note is attached to this state or one of its incident transitions. Choose what happens before deletion.} other{{count} notes are attached to this state or its incident transitions. Choose what happens before deletion.}}'**
  String attachedNotesStateDeletionMessage(int count);

  /// Warning shown before deleting a transition with attached notes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 note is attached to this transition. Choose what happens before deletion.} other{{count} notes are attached to this transition. Choose what happens before deletion.}}'**
  String attachedNotesTransitionDeletionMessage(int count);

  /// Action that keeps notes after their canvas target is deleted.
  ///
  /// In en, this message translates to:
  /// **'Keep unlinked'**
  String get keepNotesUnlinked;

  /// Action that detaches notes from a canvas target before deletion.
  ///
  /// In en, this message translates to:
  /// **'Detach notes'**
  String get detachNotes;

  /// Action that deletes notes together with their canvas target.
  ///
  /// In en, this message translates to:
  /// **'Delete notes'**
  String get deleteNotes;

  /// Accessible structured summary of a variable dependency graph.
  ///
  /// In en, this message translates to:
  /// **'{variableCount, plural, =1{1 variable} other{{variableCount} variables}} and {edgeCount, plural, =1{1 dependency edge.} other{{edgeCount} dependency edges.}}'**
  String grammarDependencySummaryCounts(int variableCount, int edgeCount);

  /// Accessible structured summary when a variable dependency graph has no recursion cycle.
  ///
  /// In en, this message translates to:
  /// **'No recursion cycle was found in this graph mode.'**
  String get grammarDependencyNoRecursionCycle;

  /// Accessible structured summary of recursion cycles in a variable dependency graph.
  ///
  /// In en, this message translates to:
  /// **'{cycleCount, plural, =1{1 recursion cycle was found.} other{{cycleCount} recursion cycles were found.}}'**
  String grammarDependencyRecursionCycleCount(int cycleCount);

  /// Accessible structured summary naming an unreachable formal grammar variable.
  ///
  /// In en, this message translates to:
  /// **'Unreachable variable: {variable}.'**
  String grammarDependencyUnreachableVariable(String variable);

  /// Accessible structured summary naming a nonproductive formal grammar variable.
  ///
  /// In en, this message translates to:
  /// **'Nonproductive variable: {variable}.'**
  String grammarDependencyNonproductiveVariable(String variable);

  /// Structured description of competing productions in an LL(1) parse-table cell.
  ///
  /// In en, this message translates to:
  /// **'{conflictKind} conflict in [{nonTerminal}, {lookahead}]: {alternatives}.'**
  String grammarLl1ConflictDetected(
    String conflictKind,
    String nonTerminal,
    String lookahead,
    String alternatives,
  );

  /// Informational ambiguity-check note when no LL(1) conflicts are detected.
  ///
  /// In en, this message translates to:
  /// **'No LL(1) conflicts detected (grammar appears LL(1) for this analysis).'**
  String get grammarAmbiguityNoLl1Conflicts;

  /// Ambiguity-check note when LL(1) conflicts are detected.
  ///
  /// In en, this message translates to:
  /// **'LL(1) conflicts detected (grammar is not LL(1)).'**
  String get grammarAmbiguityLl1ConflictsDetected;

  /// Limitation note explaining that LL(1) conflicts do not prove grammar ambiguity.
  ///
  /// In en, this message translates to:
  /// **'Note: Being non-LL(1) does not necessarily mean the grammar is ambiguous; it may still be unambiguous but require a stronger parser (e.g., LR/Earley).'**
  String get grammarAmbiguityNonLl1DoesNotImplyAmbiguity;

  /// Validation error shown when a grammar analysis requires at least one production.
  ///
  /// In en, this message translates to:
  /// **'The grammar has no productions.'**
  String get grammarAnalysisEmptyProductions;

  /// Informational result shown when left-recursion analysis finds no direct or indirect cycle.
  ///
  /// In en, this message translates to:
  /// **'No direct or indirect left recursion detected.'**
  String get grammarAnalysisNoLeftRecursion;

  /// Structural grammar validation error shown when the grammar has no start symbol.
  ///
  /// In en, this message translates to:
  /// **'Grammar has no start symbol.'**
  String get grammarStructuralStartSymbolMissing;

  /// Structural grammar analysis message shown when reachability cannot run without a start symbol.
  ///
  /// In en, this message translates to:
  /// **'Grammar has no start symbol; unreachable analysis was skipped.'**
  String get grammarStructuralStartSymbolMissingReachability;

  /// Structural grammar validation error naming a start symbol that is not a declared non-terminal.
  ///
  /// In en, this message translates to:
  /// **'Start symbol {symbol} is not declared as a non-terminal.'**
  String grammarStructuralStartSymbolNotNonterminal(String symbol);

  /// Structural grammar reachability warning naming an invalid start symbol.
  ///
  /// In en, this message translates to:
  /// **'Start symbol {symbol} is not declared as a non-terminal; unreachable analysis may be inaccurate.'**
  String grammarStructuralStartSymbolNotNonterminalReachability(String symbol);

  /// Structural grammar validation warning shown when no productions are defined.
  ///
  /// In en, this message translates to:
  /// **'Grammar has no productions.'**
  String get grammarStructuralNoProductions;

  /// Structural grammar productivity message shown when no productions are defined.
  ///
  /// In en, this message translates to:
  /// **'Grammar has no productions; productivity analysis was skipped.'**
  String get grammarStructuralNoProductionsProductivity;

  /// Structural grammar validation error for a production with no left-hand side.
  ///
  /// In en, this message translates to:
  /// **'Production {productionId} has an empty left-hand side.'**
  String grammarStructuralProductionLeftSideEmpty(String productionId);

  /// Structural grammar validation error for a production whose left-hand side is not a single non-terminal.
  ///
  /// In en, this message translates to:
  /// **'Production {productionId} left-hand side must be exactly one non-terminal for CFG tooling; got {leftSide}.'**
  String grammarStructuralProductionLeftSideNotSingleNonterminal(
    String productionId,
    String leftSide,
  );

  /// Structural grammar validation error for an empty symbol in a production left-hand side.
  ///
  /// In en, this message translates to:
  /// **'Production {productionId} left-hand side contains an empty symbol.'**
  String grammarStructuralProductionLeftSideEmptySymbol(String productionId);

  /// Structural grammar validation error naming a left-hand-side symbol that is not a declared non-terminal.
  ///
  /// In en, this message translates to:
  /// **'Production {productionId} left-hand side {symbol} is not declared as a non-terminal.'**
  String grammarStructuralProductionLeftSideNotNonterminal(
    String productionId,
    String symbol,
  );

  /// Structural grammar validation warning naming an unknown symbol referenced by a production.
  ///
  /// In en, this message translates to:
  /// **'Production {productionId} references unknown symbol {symbol}.'**
  String grammarStructuralProductionUnknownSymbol(
    String productionId,
    String symbol,
  );

  /// Structural grammar reachability warning for an undeclared symbol treated as a terminal.
  ///
  /// In en, this message translates to:
  /// **'Production references unknown symbol {symbol}; treating it as a terminal for reachability purposes.'**
  String grammarStructuralUnknownSymbolReachability(String symbol);

  /// Structural grammar productivity warning for an undeclared symbol treated as a terminal.
  ///
  /// In en, this message translates to:
  /// **'Production references unknown symbol {symbol}; treating it as a terminal for productivity purposes.'**
  String grammarStructuralUnknownSymbolProductivity(String symbol);

  /// Structural grammar validation error for a lambda production with a non-empty right-hand side.
  ///
  /// In en, this message translates to:
  /// **'Production {productionId} is marked as lambda but has a non-empty right-hand side.'**
  String grammarStructuralLambdaProductionRhsNotEmpty(String productionId);

  /// Structural grammar validation error for a production with an empty right-hand side that is not marked epsilon.
  ///
  /// In en, this message translates to:
  /// **'Production {productionId} has an empty right-hand side; use ε or mark it as epsilon.'**
  String grammarStructuralProductionRhsEmpty(String productionId);

  /// Structural grammar analysis summary naming unreachable non-terminals.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Found 1 unreachable non-terminal} other{Found {count} unreachable non-terminals}}: {symbols}.'**
  String grammarStructuralUnreachableNonterminals(int count, String symbols);

  /// Structural grammar analysis summary naming non-terminals that cannot derive terminal strings.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Found 1 unproductive non-terminal} other{Found {count} unproductive non-terminals}}: {symbols}.'**
  String grammarStructuralUnproductiveNonterminals(int count, String symbols);

  /// Structural grammar analysis note naming why productions for unproductive non-terminals cannot derive terminal strings.
  ///
  /// In en, this message translates to:
  /// **'Productions for unproductive non-terminals ({symbols}) cannot derive terminal strings.'**
  String grammarStructuralUnproductiveProductions(String symbols);

  /// Label for an LL(1) FIRST/FIRST parse-table conflict.
  ///
  /// In en, this message translates to:
  /// **'FIRST/FIRST'**
  String get grammarLl1ConflictKindFirstFirst;

  /// Label for an LL(1) FIRST/FOLLOW parse-table conflict.
  ///
  /// In en, this message translates to:
  /// **'FIRST/FOLLOW'**
  String get grammarLl1ConflictKindFirstFollow;

  /// Failure shown when an automaton could not be converted to a DFA for a comparison.
  ///
  /// In en, this message translates to:
  /// **'Automaton {automaton} could not be determinized.'**
  String fsaDeterminizationFailed(String automaton);

  /// Structured batch validation issue.
  ///
  /// In en, this message translates to:
  /// **'{field} must be non-empty.'**
  String batchValidationNonEmpty(String field);

  /// Structured batch validation issue.
  ///
  /// In en, this message translates to:
  /// **'{field} must be positive.'**
  String batchValidationPositive(String field);

  /// Structured batch validation issue.
  ///
  /// In en, this message translates to:
  /// **'{field} must not be negative.'**
  String batchValidationNonNegative(String field);

  /// Structured batch validation upper bound.
  ///
  /// In en, this message translates to:
  /// **'{field} must not exceed {bound}.'**
  String batchValidationMaximum(String field, int bound);

  /// Context for structured validation issues in one batch case.
  ///
  /// In en, this message translates to:
  /// **'Case {index} ({caseId}):'**
  String batchValidationCaseContext(int index, String caseId);

  /// Structured batch validation issue.
  ///
  /// In en, this message translates to:
  /// **'Duplicate case ID {caseId}.'**
  String batchValidationDuplicateCaseId(String caseId);

  /// Structured batch validation issue.
  ///
  /// In en, this message translates to:
  /// **'Case {caseId}: explicit tokenization requires tokens.'**
  String batchValidationExplicitTokensRequired(String caseId);

  /// Structured batch validation issue.
  ///
  /// In en, this message translates to:
  /// **'Per-case limits reference unknown case {caseId}.'**
  String batchValidationUnknownCaseLimits(String caseId);

  /// Structured batch validation issue.
  ///
  /// In en, this message translates to:
  /// **'Selected-case trace retention requires a known case ID.'**
  String get batchValidationSelectedTraceCaseRequired;

  /// Structured batch tokenization failure.
  ///
  /// In en, this message translates to:
  /// **'This canonical simulator requires Unicode-scalar tokens.'**
  String get batchExecutionScalarTokenizationRequired;

  /// Tooltip listing the batch execution keyboard shortcuts.
  ///
  /// In en, this message translates to:
  /// **'Run: Ctrl+Enter. Cancel: Escape.'**
  String get batchExecutionKeyboardShortcuts;

  /// Structured batch tokenization failure.
  ///
  /// In en, this message translates to:
  /// **'The canonical grammar tokenizer cannot preserve this explicit token sequence.'**
  String get batchExecutionGrammarTokenizationMismatch;

  /// Structured TM acceptance policy and reason for a batch result.
  ///
  /// In en, this message translates to:
  /// **'Policy: {policy}. Reason: {reason}.'**
  String batchExecutionTmPolicyReason(String policy, String reason);

  /// Structured batch import failure.
  ///
  /// In en, this message translates to:
  /// **'The input file contains {count} cases; the limit is {bound}.'**
  String batchImportCaseLimit(int count, int bound);

  /// Structured batch import failure.
  ///
  /// In en, this message translates to:
  /// **'CSV row {row} has no input column.'**
  String batchImportMissingInputColumn(int row);

  /// Structured batch import failure.
  ///
  /// In en, this message translates to:
  /// **'CSV contains duplicate case ID {caseId}.'**
  String batchImportDuplicateCaseId(String caseId);

  /// Structured batch import failure.
  ///
  /// In en, this message translates to:
  /// **'CSV has characters after a closing quote.'**
  String get batchImportCharactersAfterClosingQuote;

  /// Structured batch import failure.
  ///
  /// In en, this message translates to:
  /// **'A CSV quote must start an empty field.'**
  String get batchImportQuoteRequiresEmptyField;

  /// Structured batch import failure.
  ///
  /// In en, this message translates to:
  /// **'CSV contains an unclosed quote.'**
  String get batchImportUnclosedQuote;

  /// Accessible name for the automaton diagnostic highlight controls.
  ///
  /// In en, this message translates to:
  /// **'Canvas diagnostics'**
  String get automataDiagnosticsCanvas;

  /// No description provided for @automataDiagnosticsConflicts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Conflicts (0)} =1{Conflict (1)} other{Conflicts ({count})}}'**
  String automataDiagnosticsConflicts(int count);

  /// No description provided for @automataDiagnosticsConflictAction.
  ///
  /// In en, this message translates to:
  /// **'{selected, select, true{{count, plural, =1{Clear the conflicting transition highlight, 1 found} other{Clear the conflicting transition highlights, {count} found}}} other{{count, plural, =1{Highlight the conflicting transition, 1 found} other{Highlight conflicting transitions, {count} found}}}}'**
  String automataDiagnosticsConflictAction(String selected, int count);

  /// No description provided for @automataDiagnosticsConflictHint.
  ///
  /// In en, this message translates to:
  /// **'Shows transitions that compete for the same input'**
  String get automataDiagnosticsConflictHint;

  /// No description provided for @automataDiagnosticsEpsilon.
  ///
  /// In en, this message translates to:
  /// **'Epsilon ({count})'**
  String automataDiagnosticsEpsilon(int count);

  /// No description provided for @automataDiagnosticsEpsilonAction.
  ///
  /// In en, this message translates to:
  /// **'{selected, select, true{{count, plural, =1{Clear the epsilon transition highlight, 1 found} other{Clear the epsilon transition highlights, {count} found}}} other{{count, plural, =1{Highlight the epsilon transition, 1 found} other{Highlight epsilon transitions, {count} found}}}}'**
  String automataDiagnosticsEpsilonAction(String selected, int count);

  /// No description provided for @automataDiagnosticsEpsilonHint.
  ///
  /// In en, this message translates to:
  /// **'Shows transitions that use the empty string'**
  String get automataDiagnosticsEpsilonHint;

  /// No description provided for @computationBranchesTitle.
  ///
  /// In en, this message translates to:
  /// **'Computation branches'**
  String get computationBranchesTitle;

  /// No description provided for @computationBranchesInspectorSemantic.
  ///
  /// In en, this message translates to:
  /// **'Computation branch inspector'**
  String get computationBranchesInspectorSemantic;

  /// No description provided for @computationBranchesBranch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get computationBranchesBranch;

  /// No description provided for @computationBranchesConfigurations.
  ///
  /// In en, this message translates to:
  /// **'Configurations'**
  String get computationBranchesConfigurations;

  /// No description provided for @computationBranchesConfigurationDetails.
  ///
  /// In en, this message translates to:
  /// **'Configuration details'**
  String get computationBranchesConfigurationDetails;

  /// No description provided for @computationBranchesConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Configuration'**
  String get computationBranchesConfiguration;

  /// No description provided for @computationBranchesOutcome.
  ///
  /// In en, this message translates to:
  /// **'Outcome'**
  String get computationBranchesOutcome;

  /// No description provided for @computationBranchesHighlight.
  ///
  /// In en, this message translates to:
  /// **'Highlight branch'**
  String get computationBranchesHighlight;

  /// No description provided for @computationBranchesSelectConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Select a configuration to inspect it.'**
  String get computationBranchesSelectConfiguration;

  /// No description provided for @computationBranchesNone.
  ///
  /// In en, this message translates to:
  /// **'No computation branches were recorded.'**
  String get computationBranchesNone;

  /// No description provided for @computationBranchesNoConfigurations.
  ///
  /// In en, this message translates to:
  /// **'This branch has no recorded configurations.'**
  String get computationBranchesNoConfigurations;

  /// No description provided for @computationBranchesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Branch inspection unavailable'**
  String get computationBranchesUnavailable;

  /// No description provided for @computationBranchesPreviousBranch.
  ///
  /// In en, this message translates to:
  /// **'Previous branch'**
  String get computationBranchesPreviousBranch;

  /// No description provided for @computationBranchesNextBranch.
  ///
  /// In en, this message translates to:
  /// **'Next branch'**
  String get computationBranchesNextBranch;

  /// No description provided for @computationBranchesPreviousConfigurations.
  ///
  /// In en, this message translates to:
  /// **'Previous configurations'**
  String get computationBranchesPreviousConfigurations;

  /// No description provided for @computationBranchesNextConfigurations.
  ///
  /// In en, this message translates to:
  /// **'Next configurations'**
  String get computationBranchesNextConfigurations;

  /// No description provided for @computationBranchesAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get computationBranchesAccepted;

  /// No description provided for @computationBranchesRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get computationBranchesRejected;

  /// No description provided for @computationBranchesDead.
  ///
  /// In en, this message translates to:
  /// **'Dead end'**
  String get computationBranchesDead;

  /// No description provided for @computationBranchesBoundedUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown at execution bound'**
  String get computationBranchesBoundedUnknown;

  /// No description provided for @computationBranchesCycle.
  ///
  /// In en, this message translates to:
  /// **'Cycle detected'**
  String get computationBranchesCycle;

  /// No description provided for @computationBranchesCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get computationBranchesCancelled;

  /// No description provided for @computationBranchesFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get computationBranchesFailed;

  /// No description provided for @computationBranchesSimulationNotRun.
  ///
  /// In en, this message translates to:
  /// **'Run a simulation to inspect its branches.'**
  String get computationBranchesSimulationNotRun;

  /// No description provided for @computationBranchesNotRecorded.
  ///
  /// In en, this message translates to:
  /// **'This simulation records a trace but not every explored branch.'**
  String get computationBranchesNotRecorded;

  /// No description provided for @computationBranchesDeterministic.
  ///
  /// In en, this message translates to:
  /// **'This execution followed one deterministic path.'**
  String get computationBranchesDeterministic;

  /// No description provided for @computationBranchesUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This simulation cannot provide branch data.'**
  String get computationBranchesUnsupported;

  /// No description provided for @computationBranchesInspect.
  ///
  /// In en, this message translates to:
  /// **'Inspect computation branches'**
  String get computationBranchesInspect;

  /// No description provided for @computationBranchesHide.
  ///
  /// In en, this message translates to:
  /// **'Hide computation branches'**
  String get computationBranchesHide;

  /// No description provided for @computationBranchesInspectHint.
  ///
  /// In en, this message translates to:
  /// **'Review each recorded nondeterministic execution path'**
  String get computationBranchesInspectHint;

  /// No description provided for @computationBranchesBranchName.
  ///
  /// In en, this message translates to:
  /// **'Branch {index}'**
  String computationBranchesBranchName(int index);

  /// No description provided for @computationBranchesConfigurationName.
  ///
  /// In en, this message translates to:
  /// **'Configuration {index}'**
  String computationBranchesConfigurationName(int index);

  /// No description provided for @computationBranchesBranchPosition.
  ///
  /// In en, this message translates to:
  /// **'Branch {index} of {total}'**
  String computationBranchesBranchPosition(int index, int total);

  /// No description provided for @computationBranchesConfigurationRange.
  ///
  /// In en, this message translates to:
  /// **'Configurations {start}-{end} of {total}'**
  String computationBranchesConfigurationRange(int start, int end, int total);

  /// No description provided for @computationBranchesBranchOption.
  ///
  /// In en, this message translates to:
  /// **'{branch} · {outcome}'**
  String computationBranchesBranchOption(String branch, String outcome);

  /// No description provided for @computationBranchesBranchAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'{position}. {branch}. {outcome}.'**
  String computationBranchesBranchAnnouncement(
    String position,
    String branch,
    String outcome,
  );

  /// No description provided for @computationBranchesConfigurationSemantic.
  ///
  /// In en, this message translates to:
  /// **'{hasOutcome, select, true{Configuration: {configuration}, outcome: {outcome}} other{Configuration: {configuration}}}'**
  String computationBranchesConfigurationSemantic(
    String hasOutcome,
    String configuration,
    String outcome,
  );

  /// No description provided for @computationBranchesOutcomeSemantic.
  ///
  /// In en, this message translates to:
  /// **'Outcome: {outcome}'**
  String computationBranchesOutcomeSemantic(String outcome);

  /// No description provided for @computationBranchesUnavailableSemantic.
  ///
  /// In en, this message translates to:
  /// **'Branch inspection unavailable. {reason}'**
  String computationBranchesUnavailableSemantic(String reason);

  /// No description provided for @languageComparisonInconclusive.
  ///
  /// In en, this message translates to:
  /// **'Inconclusive within limits'**
  String get languageComparisonInconclusive;

  /// No description provided for @languageComparisonAnalysisFailed.
  ///
  /// In en, this message translates to:
  /// **'Analysis failed'**
  String get languageComparisonAnalysisFailed;

  /// No description provided for @languageComparisonInvalidInput.
  ///
  /// In en, this message translates to:
  /// **'Invalid machine or input'**
  String get languageComparisonInvalidInput;

  /// Structured language-comparison validation message for an empty state set.
  ///
  /// In en, this message translates to:
  /// **'{automaton} must have at least one state'**
  String languageComparisonValidationEmptyStateSet(String automaton);

  /// Structured language-comparison validation message for a missing initial state.
  ///
  /// In en, this message translates to:
  /// **'{automaton} must have an initial state'**
  String languageComparisonValidationMissingInitialState(String automaton);

  /// Structured language-comparison validation message for an initial state outside the state set.
  ///
  /// In en, this message translates to:
  /// **'The initial state of {automaton} must belong to the state set'**
  String languageComparisonValidationInitialStateOutsideSet(String automaton);

  /// No description provided for @languageComparisonConversionFailed.
  ///
  /// In en, this message translates to:
  /// **'Conversion failed'**
  String get languageComparisonConversionFailed;

  /// No description provided for @languageComparisonLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Limit reached'**
  String get languageComparisonLimitReached;

  /// No description provided for @languageComparisonStatusSemantic.
  ///
  /// In en, this message translates to:
  /// **'Language Comparison: {status}'**
  String languageComparisonStatusSemantic(String status);

  /// No description provided for @languageComparisonWitnessSemantic.
  ///
  /// In en, this message translates to:
  /// **'Distinguishing string found: {value}'**
  String languageComparisonWitnessSemantic(String value);

  /// No description provided for @languageComparisonStatisticsSemantic.
  ///
  /// In en, this message translates to:
  /// **'Automaton A: {statesA, plural, =1{1 state} other{{statesA} states}}, automaton B: {statesB, plural, =1{1 state} other{{statesB} states}}, automaton A: {transitionsA, plural, =1{1 transition} other{{transitionsA} transitions}}, automaton B: {transitionsB, plural, =1{1 transition} other{{transitionsB} transitions}}'**
  String languageComparisonStatisticsSemantic(
    int statesA,
    int statesB,
    int transitionsA,
    int transitionsB,
  );

  /// No description provided for @languageComparisonCanvasSemantic.
  ///
  /// In en, this message translates to:
  /// **'{title}. {stateCount, plural, =1{1 state} other{{stateCount} states}}, {transitionCount, plural, =1{1 transition} other{{transitionCount} transitions}}'**
  String languageComparisonCanvasSemantic(
    String title,
    int stateCount,
    int transitionCount,
  );

  /// No description provided for @languageComparisonStepSemantic.
  ///
  /// In en, this message translates to:
  /// **'Step {step}: {title}'**
  String languageComparisonStepSemantic(int step, String title);

  /// No description provided for @languageComparisonFailureMalformedExplanation.
  ///
  /// In en, this message translates to:
  /// **'Check that both automata have states and an initial state.'**
  String get languageComparisonFailureMalformedExplanation;

  /// No description provided for @languageComparisonFailureDeterminizationExplanation.
  ///
  /// In en, this message translates to:
  /// **'One automaton could not be converted to a deterministic automaton.'**
  String get languageComparisonFailureDeterminizationExplanation;

  /// No description provided for @languageComparisonFailureNormalizationExplanation.
  ///
  /// In en, this message translates to:
  /// **'The automata could not be completed over a shared alphabet.'**
  String get languageComparisonFailureNormalizationExplanation;

  /// No description provided for @languageComparisonFailureProductExplanation.
  ///
  /// In en, this message translates to:
  /// **'The product automaton could not be constructed.'**
  String get languageComparisonFailureProductExplanation;

  /// No description provided for @languageComparisonFailureTimeoutExplanation.
  ///
  /// In en, this message translates to:
  /// **'The comparison exceeded its time budget without deciding equivalence.'**
  String get languageComparisonFailureTimeoutExplanation;

  /// No description provided for @languageComparisonFailureStateLimitExplanation.
  ///
  /// In en, this message translates to:
  /// **'The comparison reached its product-state limit without deciding equivalence.'**
  String get languageComparisonFailureStateLimitExplanation;

  /// No description provided for @languageComparisonFailureInternalExplanation.
  ///
  /// In en, this message translates to:
  /// **'The comparison stopped because of an internal error.'**
  String get languageComparisonFailureInternalExplanation;

  /// No description provided for @languageComparisonFailureSemantic.
  ///
  /// In en, this message translates to:
  /// **'{reason}. {explanation}'**
  String languageComparisonFailureSemantic(String reason, String explanation);

  /// No description provided for @languageComparisonStepValidation.
  ///
  /// In en, this message translates to:
  /// **'Validation'**
  String get languageComparisonStepValidation;

  /// No description provided for @languageComparisonStepInitialization.
  ///
  /// In en, this message translates to:
  /// **'Initialization'**
  String get languageComparisonStepInitialization;

  /// No description provided for @languageComparisonStepAlphabetNormalization.
  ///
  /// In en, this message translates to:
  /// **'Alphabet Normalization'**
  String get languageComparisonStepAlphabetNormalization;

  /// No description provided for @languageComparisonStepDfaConversion.
  ///
  /// In en, this message translates to:
  /// **'DFA Conversion'**
  String get languageComparisonStepDfaConversion;

  /// No description provided for @languageComparisonStepDfaCompletion.
  ///
  /// In en, this message translates to:
  /// **'DFA Completion'**
  String get languageComparisonStepDfaCompletion;

  /// No description provided for @languageComparisonStepProductConstruction.
  ///
  /// In en, this message translates to:
  /// **'Product Construction'**
  String get languageComparisonStepProductConstruction;

  /// No description provided for @languageComparisonStepProductStateCreated.
  ///
  /// In en, this message translates to:
  /// **'Product State Created'**
  String get languageComparisonStepProductStateCreated;

  /// No description provided for @languageComparisonStepProductTransition.
  ///
  /// In en, this message translates to:
  /// **'Product Transition'**
  String get languageComparisonStepProductTransition;

  /// No description provided for @languageComparisonStepProductComplete.
  ///
  /// In en, this message translates to:
  /// **'Product Construction Complete'**
  String get languageComparisonStepProductComplete;

  /// No description provided for @languageComparisonStepBfsSearch.
  ///
  /// In en, this message translates to:
  /// **'BFS Search'**
  String get languageComparisonStepBfsSearch;

  /// No description provided for @languageComparisonStepInitialPairCheck.
  ///
  /// In en, this message translates to:
  /// **'Initial Pair Check'**
  String get languageComparisonStepInitialPairCheck;

  /// No description provided for @languageComparisonStepStatePairVisit.
  ///
  /// In en, this message translates to:
  /// **'State Pair Visit'**
  String get languageComparisonStepStatePairVisit;

  /// No description provided for @languageComparisonStepCounterexampleFound.
  ///
  /// In en, this message translates to:
  /// **'Counterexample Found'**
  String get languageComparisonStepCounterexampleFound;

  /// No description provided for @languageComparisonStepBfsComplete.
  ///
  /// In en, this message translates to:
  /// **'BFS Complete'**
  String get languageComparisonStepBfsComplete;

  /// No description provided for @languageComparisonStepResult.
  ///
  /// In en, this message translates to:
  /// **'Comparison Result'**
  String get languageComparisonStepResult;

  /// No description provided for @languageComparisonStepError.
  ///
  /// In en, this message translates to:
  /// **'Comparison Error'**
  String get languageComparisonStepError;

  /// No description provided for @languageComparisonStepUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown Step'**
  String get languageComparisonStepUnknown;

  /// No description provided for @languageComparisonDescriptionValidation.
  ///
  /// In en, this message translates to:
  /// **'Validating input automata'**
  String get languageComparisonDescriptionValidation;

  /// No description provided for @languageComparisonDescriptionInitialization.
  ///
  /// In en, this message translates to:
  /// **'Initialize product automaton construction'**
  String get languageComparisonDescriptionInitialization;

  /// No description provided for @languageComparisonDescriptionAlphabet.
  ///
  /// In en, this message translates to:
  /// **'Combining alphabets from both automata'**
  String get languageComparisonDescriptionAlphabet;

  /// No description provided for @languageComparisonDescriptionNfaToDfa.
  ///
  /// In en, this message translates to:
  /// **'Converting automaton {automaton} from NFA to DFA'**
  String languageComparisonDescriptionNfaToDfa(String automaton);

  /// No description provided for @languageComparisonDescriptionDfaCompletion.
  ///
  /// In en, this message translates to:
  /// **'Completing DFA {automaton} with a sink state if needed'**
  String languageComparisonDescriptionDfaCompletion(String automaton);

  /// No description provided for @languageComparisonDescriptionProductStart.
  ///
  /// In en, this message translates to:
  /// **'Starting product automaton construction'**
  String get languageComparisonDescriptionProductStart;

  /// No description provided for @languageComparisonDescriptionProductState.
  ///
  /// In en, this message translates to:
  /// **'Created product state {state}'**
  String languageComparisonDescriptionProductState(String state);

  /// No description provided for @languageComparisonDescriptionProductTransition.
  ///
  /// In en, this message translates to:
  /// **'Created a product transition on symbol {symbol}'**
  String languageComparisonDescriptionProductTransition(String symbol);

  /// No description provided for @languageComparisonDescriptionProductComplete.
  ///
  /// In en, this message translates to:
  /// **'Product automaton construction complete'**
  String get languageComparisonDescriptionProductComplete;

  /// No description provided for @languageComparisonDescriptionBfsStart.
  ///
  /// In en, this message translates to:
  /// **'Starting BFS search for a distinguishing string'**
  String get languageComparisonDescriptionBfsStart;

  /// No description provided for @languageComparisonDescriptionInitialCheck.
  ///
  /// In en, this message translates to:
  /// **'{different, select, true{The initial states have different acceptance; the empty string distinguishes them} other{The initial states have the same acceptance status}}'**
  String languageComparisonDescriptionInitialCheck(String different);

  /// No description provided for @languageComparisonDescriptionExplorePair.
  ///
  /// In en, this message translates to:
  /// **'Exploring state pair ({stateA}, {stateB})'**
  String languageComparisonDescriptionExplorePair(String stateA, String stateB);

  /// No description provided for @languageComparisonDescriptionCounterexample.
  ///
  /// In en, this message translates to:
  /// **'Found distinguishing string {value}'**
  String languageComparisonDescriptionCounterexample(String value);

  /// No description provided for @languageComparisonDescriptionBfsComplete.
  ///
  /// In en, this message translates to:
  /// **'BFS complete; all state pairs were explored'**
  String get languageComparisonDescriptionBfsComplete;

  /// No description provided for @languageComparisonDescriptionResult.
  ///
  /// In en, this message translates to:
  /// **'{equivalent, select, true{The automata are equivalent and recognize the same language} other{The automata are not equivalent; a distinguishing string was found}}'**
  String languageComparisonDescriptionResult(String equivalent);

  /// No description provided for @languageComparisonDescriptionError.
  ///
  /// In en, this message translates to:
  /// **'The comparison stopped with an error'**
  String get languageComparisonDescriptionError;

  /// No description provided for @languageComparisonDescriptionUnknown.
  ///
  /// In en, this message translates to:
  /// **'No localized description is available for this trace step.'**
  String get languageComparisonDescriptionUnknown;

  /// No description provided for @languageComparisonDetailAutomaton.
  ///
  /// In en, this message translates to:
  /// **'Automaton'**
  String get languageComparisonDetailAutomaton;

  /// No description provided for @languageComparisonDetailAutomatonAAlphabet.
  ///
  /// In en, this message translates to:
  /// **'Automaton A alphabet'**
  String get languageComparisonDetailAutomatonAAlphabet;

  /// No description provided for @languageComparisonDetailAutomatonBAlphabet.
  ///
  /// In en, this message translates to:
  /// **'Automaton B alphabet'**
  String get languageComparisonDetailAutomatonBAlphabet;

  /// No description provided for @languageComparisonDetailSharedAlphabet.
  ///
  /// In en, this message translates to:
  /// **'Shared alphabet'**
  String get languageComparisonDetailSharedAlphabet;

  /// No description provided for @languageComparisonDetailSinkState.
  ///
  /// In en, this message translates to:
  /// **'Sink state'**
  String get languageComparisonDetailSinkState;

  /// No description provided for @languageComparisonDetailAlphabetSize.
  ///
  /// In en, this message translates to:
  /// **'Alphabet size'**
  String get languageComparisonDetailAlphabetSize;

  /// No description provided for @languageComparisonDetailStatePair.
  ///
  /// In en, this message translates to:
  /// **'State pair'**
  String get languageComparisonDetailStatePair;

  /// No description provided for @languageComparisonDetailProductState.
  ///
  /// In en, this message translates to:
  /// **'Product state'**
  String get languageComparisonDetailProductState;

  /// No description provided for @languageComparisonDetailAccepting.
  ///
  /// In en, this message translates to:
  /// **'Accepting'**
  String get languageComparisonDetailAccepting;

  /// No description provided for @languageComparisonDetailTarget.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get languageComparisonDetailTarget;

  /// No description provided for @languageComparisonDetailAcceptingStates.
  ///
  /// In en, this message translates to:
  /// **'Accepting states'**
  String get languageComparisonDetailAcceptingStates;

  /// No description provided for @languageComparisonDetailInitialPair.
  ///
  /// In en, this message translates to:
  /// **'Initial pair'**
  String get languageComparisonDetailInitialPair;

  /// No description provided for @languageComparisonDetailAcceptance.
  ///
  /// In en, this message translates to:
  /// **'Acceptance'**
  String get languageComparisonDetailAcceptance;

  /// No description provided for @languageComparisonDetailPath.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get languageComparisonDetailPath;

  /// No description provided for @languageComparisonDetailPathLength.
  ///
  /// In en, this message translates to:
  /// **'Path length'**
  String get languageComparisonDetailPathLength;

  /// No description provided for @languageComparisonDetailDistinguishingString.
  ///
  /// In en, this message translates to:
  /// **'Distinguishing string'**
  String get languageComparisonDetailDistinguishingString;

  /// No description provided for @languageComparisonDetailPairsExplored.
  ///
  /// In en, this message translates to:
  /// **'Pairs explored'**
  String get languageComparisonDetailPairsExplored;

  /// No description provided for @languageComparisonDetailEquivalent.
  ///
  /// In en, this message translates to:
  /// **'Equivalent'**
  String get languageComparisonDetailEquivalent;

  /// No description provided for @languageComparisonDetailReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get languageComparisonDetailReason;

  /// No description provided for @languageComparisonDetailStage.
  ///
  /// In en, this message translates to:
  /// **'Stage'**
  String get languageComparisonDetailStage;

  /// No description provided for @languageComparisonDetailMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get languageComparisonDetailMessage;

  /// No description provided for @languageComparisonDetailRawType.
  ///
  /// In en, this message translates to:
  /// **'Raw type'**
  String get languageComparisonDetailRawType;

  /// No description provided for @languageComparisonValueUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get languageComparisonValueUnknown;

  /// No description provided for @languageComparisonValueAdded.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get languageComparisonValueAdded;

  /// No description provided for @languageComparisonValueNotNeeded.
  ///
  /// In en, this message translates to:
  /// **'Not needed'**
  String get languageComparisonValueNotNeeded;

  /// No description provided for @languageComparisonValueNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get languageComparisonValueNew;

  /// No description provided for @languageComparisonValueExisting.
  ///
  /// In en, this message translates to:
  /// **'Existing'**
  String get languageComparisonValueExisting;

  /// No description provided for @languageComparisonValueBeforeAfter.
  ///
  /// In en, this message translates to:
  /// **'{before} → {after}'**
  String languageComparisonValueBeforeAfter(String before, String after);

  /// No description provided for @languageComparisonValueStatePair.
  ///
  /// In en, this message translates to:
  /// **'{stateA} / {stateB}'**
  String languageComparisonValueStatePair(String stateA, String stateB);

  /// No description provided for @languageComparisonValueAcceptance.
  ///
  /// In en, this message translates to:
  /// **'Automaton A {acceptsA, select, true{accepts input} other{rejects input}}; automaton B {acceptsB, select, true{accepts input} other{rejects input}}'**
  String languageComparisonValueAcceptance(String acceptsA, String acceptsB);

  /// No description provided for @languageComparisonExecuting.
  ///
  /// In en, this message translates to:
  /// **'Executing {algorithm}'**
  String languageComparisonExecuting(String algorithm);

  /// No description provided for @languageComparisonComplete.
  ///
  /// In en, this message translates to:
  /// **'Comparison complete'**
  String get languageComparisonComplete;

  /// No description provided for @languageComparisonLegacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Equivalence comparison'**
  String get languageComparisonLegacyTitle;

  /// No description provided for @languageComparisonLegacyEquivalent.
  ///
  /// In en, this message translates to:
  /// **'Automata are equivalent'**
  String get languageComparisonLegacyEquivalent;

  /// No description provided for @languageComparisonLegacyNotEquivalent.
  ///
  /// In en, this message translates to:
  /// **'Automata are not equivalent'**
  String get languageComparisonLegacyNotEquivalent;

  /// No description provided for @pumpingMessagePumpingLengthPositive.
  ///
  /// In en, this message translates to:
  /// **'The pumping length must be positive.'**
  String get pumpingMessagePumpingLengthPositive;

  /// No description provided for @pumpingMessageExponentNonNegative.
  ///
  /// In en, this message translates to:
  /// **'The pump exponent must be non-negative.'**
  String get pumpingMessageExponentNonNegative;

  /// No description provided for @pumpingMessageMaximumTokensNonNegative.
  ///
  /// In en, this message translates to:
  /// **'The token limit must be non-negative.'**
  String get pumpingMessageMaximumTokensNonNegative;

  /// No description provided for @pumpingMessageRequiredTextNotEmpty.
  ///
  /// In en, this message translates to:
  /// **'The {field} field must not be empty.'**
  String pumpingMessageRequiredTextNotEmpty(String field);

  /// No description provided for @pumpingMessageSuggestedWitnessNotEmpty.
  ///
  /// In en, this message translates to:
  /// **'The suggested witness must not be empty.'**
  String get pumpingMessageSuggestedWitnessNotEmpty;

  /// No description provided for @pumpingMessageCustomTitleNotEmpty.
  ///
  /// In en, this message translates to:
  /// **'The custom title must not be empty.'**
  String get pumpingMessageCustomTitleNotEmpty;

  /// No description provided for @pumpingMessageWitnessRequiresPumpingLength.
  ///
  /// In en, this message translates to:
  /// **'A witness requires a pumping length.'**
  String get pumpingMessageWitnessRequiresPumpingLength;

  /// No description provided for @pumpingMessageWitnessMinimumTokens.
  ///
  /// In en, this message translates to:
  /// **'The witness must contain at least {minimum} tokens.'**
  String pumpingMessageWitnessMinimumTokens(int minimum);

  /// No description provided for @pumpingMessageDecompositionTheoremMismatch.
  ///
  /// In en, this message translates to:
  /// **'The {actual} decomposition cannot be used in a {expected} session.'**
  String pumpingMessageDecompositionTheoremMismatch(
    String actual,
    String expected,
  );

  /// No description provided for @pumpingMessageDecompositionWitnessMismatch.
  ///
  /// In en, this message translates to:
  /// **'The decomposition does not reconstruct this witness.'**
  String get pumpingMessageDecompositionWitnessMismatch;

  /// No description provided for @pumpingMessageDecompositionConstraintViolation.
  ///
  /// In en, this message translates to:
  /// **'The decomposition violates the theorem constraints.'**
  String get pumpingMessageDecompositionConstraintViolation;

  /// No description provided for @pumpingMessageEnterPositivePumpingLength.
  ///
  /// In en, this message translates to:
  /// **'Enter a positive integer for p.'**
  String get pumpingMessageEnterPositivePumpingLength;

  /// No description provided for @pumpingMessageEnterNonNegativeExponent.
  ///
  /// In en, this message translates to:
  /// **'Enter a non-negative integer for i.'**
  String get pumpingMessageEnterNonNegativeExponent;

  /// No description provided for @pumpingMessageInvalidTokenArray.
  ///
  /// In en, this message translates to:
  /// **'Enter a JSON array of string tokens.'**
  String get pumpingMessageInvalidTokenArray;

  /// No description provided for @pumpingMessageNoValidDecomposition.
  ///
  /// In en, this message translates to:
  /// **'No valid decomposition is available.'**
  String get pumpingMessageNoValidDecomposition;

  /// No description provided for @pumpingMessageDecompositionsEnumerated.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 valid decomposition enumerated for this finite witness.} other{{count} valid decompositions enumerated for this finite witness.}}'**
  String pumpingMessageDecompositionsEnumerated(int count);

  /// No description provided for @pumpingMessagePumpedWordBounded.
  ///
  /// In en, this message translates to:
  /// **'The pumped word needs at least {minimum} tokens; the limit is {maximum}.'**
  String pumpingMessagePumpedWordBounded(int minimum, int maximum);

  /// No description provided for @pumpingMessageChooseBoundedExponent.
  ///
  /// In en, this message translates to:
  /// **'Choose an exponent whose pumped word fits the token limit.'**
  String get pumpingMessageChooseBoundedExponent;

  /// No description provided for @pumpingMessageCounterexampleEvidence.
  ///
  /// In en, this message translates to:
  /// **'This exponent is concrete counterexample evidence for the selected decomposition.'**
  String get pumpingMessageCounterexampleEvidence;

  /// No description provided for @pumpingMessageFiniteCheckInconclusive.
  ///
  /// In en, this message translates to:
  /// **'The sampled word stayed in the language. This finite check proves no universal claim.'**
  String get pumpingMessageFiniteCheckInconclusive;

  /// No description provided for @pumpingMessageSessionImported.
  ///
  /// In en, this message translates to:
  /// **'Session imported.'**
  String get pumpingMessageSessionImported;

  /// No description provided for @pumpingMessageTransitionWrongStage.
  ///
  /// In en, this message translates to:
  /// **'Complete the current quantifier step first.'**
  String get pumpingMessageTransitionWrongStage;

  /// No description provided for @pumpingMessageTransitionWrongPlayer.
  ///
  /// In en, this message translates to:
  /// **'That choice belongs to the other player.'**
  String get pumpingMessageTransitionWrongPlayer;

  /// No description provided for @pumpingMessageTransitionWitnessTooShort.
  ///
  /// In en, this message translates to:
  /// **'The witness must contain at least p tokens.'**
  String get pumpingMessageTransitionWitnessTooShort;

  /// No description provided for @pumpingMessageTransitionWitnessOutsideLanguage.
  ///
  /// In en, this message translates to:
  /// **'The selected witness is not in the language.'**
  String get pumpingMessageTransitionWitnessOutsideLanguage;

  /// Timeout result for a persisted simulation, with the elapsed duration rounded down to whole seconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds, plural, =0{The simulation timed out in less than one second.} =1{The simulation timed out after one second.} other{The simulation timed out after {seconds} seconds.}}'**
  String simulationOutcomeTimeout(int seconds);

  /// Simulation result when an exact repeated configuration proves a cycle.
  ///
  /// In en, this message translates to:
  /// **'{steps, plural, =0{The simulation detected a repeating configuration before recording a step.} =1{The simulation detected a repeating configuration after one step.} other{The simulation detected a repeating configuration after {steps} steps.}}'**
  String simulationOutcomeProvenCycle(int steps);

  /// Safe localized fallback for a simulation result restored from a legacy text-only failure.
  ///
  /// In en, this message translates to:
  /// **'The simulation could not be completed.'**
  String get simulationOutcomeLegacyFailure;

  /// Heading for a synchronized multi-tape Turing machine execution trace.
  ///
  /// In en, this message translates to:
  /// **'Synchronized multi-tape trace'**
  String get tmMultiTapeTraceTitle;

  /// Empty state for a multi-tape execution trace.
  ///
  /// In en, this message translates to:
  /// **'No transition was executed.'**
  String get tmMultiTapeNoTransition;

  /// Summary of one multi-tape trace step. State identifiers are user-authored formal content.
  ///
  /// In en, this message translates to:
  /// **'Step {step}: {fromState} → {toState}'**
  String tmMultiTapeStep(int step, String fromState, String toState);

  /// Transition identifier and number of tapes changed by one atomic multi-tape step.
  ///
  /// In en, this message translates to:
  /// **'Transition {transitionId}; {tapeCount, plural, =1{1 tape updated atomically} other{{tapeCount} tapes updated atomically}}'**
  String tmMultiTapeAtomicTransition(String transitionId, int tapeCount);

  /// Accessible label for the multi-tape space metrics card.
  ///
  /// In en, this message translates to:
  /// **'Multi-tape space metrics'**
  String get tmMultiTapeSpaceMetricsSemantic;

  /// Explanation of how multi-tape space usage is measured.
  ///
  /// In en, this message translates to:
  /// **'Space is measured per tape as the visited logical-head span and maximum simultaneous nonblank cells.'**
  String get tmMultiTapeSpaceMetricsExplanation;

  /// Per-tape space metrics for a multi-tape execution.
  ///
  /// In en, this message translates to:
  /// **'Tape {tapeNumber}: span {span}, maximum nonblank cells {nonblankCount}'**
  String tmMultiTapeMetrics(int tapeNumber, int span, int nonblankCount);

  /// Maximum total number of nonblank cells across all tapes.
  ///
  /// In en, this message translates to:
  /// **'Maximum total simultaneous nonblank cells: {count}'**
  String tmMultiTapeTotalNonblank(int count);

  /// Accessible summary of one tape in the selected multi-tape configuration. The operation is formal notation.
  ///
  /// In en, this message translates to:
  /// **'Tape {tapeNumber}, head at {head}, operation {operation}'**
  String tmMultiTapeConfigurationSemantic(
    int tapeNumber,
    int head,
    String operation,
  );

  /// Title of one tape in a multi-tape configuration.
  ///
  /// In en, this message translates to:
  /// **'Tape {tapeNumber}'**
  String tmMultiTapeTitle(int tapeNumber);

  /// Head position and formal operation for one tape.
  ///
  /// In en, this message translates to:
  /// **'Head {head} · {operation}'**
  String tmMultiTapeHeadSummary(int head, String operation);

  /// Accessible label for an inactive tape cell. The symbol is user-authored formal content.
  ///
  /// In en, this message translates to:
  /// **'Cell {position}, {symbol}'**
  String tmMultiTapeCellSemantic(int position, String symbol);

  /// Accessible label for the tape cell under the head. The symbol is user-authored formal content.
  ///
  /// In en, this message translates to:
  /// **'Cell {position}, {symbol}, head'**
  String tmMultiTapeHeadCellSemantic(int position, String symbol);

  /// Formal logical position shown under a Turing machine tape cell.
  ///
  /// In en, this message translates to:
  /// **'{position}'**
  String tmMultiTapePosition(int position);

  /// No description provided for @serviceSimulationRunnerStartFailed.
  ///
  /// In en, this message translates to:
  /// **'The simulation worker could not start.'**
  String get serviceSimulationRunnerStartFailed;

  /// No description provided for @serviceSimulationRunnerExecutionFailed.
  ///
  /// In en, this message translates to:
  /// **'The simulation could not be completed.'**
  String get serviceSimulationRunnerExecutionFailed;

  /// No description provided for @serviceSimulationRunnerWorkerFailed.
  ///
  /// In en, this message translates to:
  /// **'The simulation worker failed.'**
  String get serviceSimulationRunnerWorkerFailed;

  /// No description provided for @serviceSimulationRunnerWorkerExitedUnexpectedly.
  ///
  /// In en, this message translates to:
  /// **'The simulation worker exited unexpectedly.'**
  String get serviceSimulationRunnerWorkerExitedUnexpectedly;

  /// No description provided for @serviceSimulationRunnerInvalidWorkerResponse.
  ///
  /// In en, this message translates to:
  /// **'The simulation worker returned an invalid response.'**
  String get serviceSimulationRunnerInvalidWorkerResponse;

  /// TM building-block editor error for a duplicate block ID.
  ///
  /// In en, this message translates to:
  /// **'A machine already uses block ID {block}.'**
  String serviceTmBlockEditorDuplicateBlockId(String block);

  /// TM building-block editor error for a duplicate user-authored block name.
  ///
  /// In en, this message translates to:
  /// **'A block already uses the name {name}.'**
  String serviceTmBlockEditorDuplicateBlockName(String name);

  /// No description provided for @serviceTmBlockEditorInvalidBlockName.
  ///
  /// In en, this message translates to:
  /// **'Block names must be non-empty and unique.'**
  String get serviceTmBlockEditorInvalidBlockName;

  /// TM building-block editor error when deletion requires an explicit reference resolution.
  ///
  /// In en, this message translates to:
  /// **'Block {block} is still referenced. Choose an explicit resolution.'**
  String serviceTmBlockEditorReferencedBlock(String block);

  /// TM building-block editor error for a missing owner machine.
  ///
  /// In en, this message translates to:
  /// **'Machine {machine} does not exist.'**
  String serviceTmBlockEditorMissingOwnerMachine(String machine);

  /// TM building-block editor error for a missing invocation anchor state.
  ///
  /// In en, this message translates to:
  /// **'State {state} does not exist in {machine}.'**
  String serviceTmBlockEditorMissingAnchorState(String state, String machine);

  /// TM building-block editor error when a state already owns another invocation.
  ///
  /// In en, this message translates to:
  /// **'State {state} already invokes a block.'**
  String serviceTmBlockEditorStateAlreadyInvokesBlock(String state);

  /// TM building-block editor error for a duplicate root state.
  ///
  /// In en, this message translates to:
  /// **'State {state} already exists in the root machine.'**
  String serviceTmBlockEditorDuplicateRootState(String state);

  /// TM building-block editor error for a missing invocation.
  ///
  /// In en, this message translates to:
  /// **'Invocation {invocation} does not exist.'**
  String serviceTmBlockEditorMissingInvocation(String invocation);

  /// No description provided for @serviceTmBlockEditorNothingToUndo.
  ///
  /// In en, this message translates to:
  /// **'There is no building-block edit to undo.'**
  String get serviceTmBlockEditorNothingToUndo;

  /// No description provided for @serviceTmBlockEditorNothingToRedo.
  ///
  /// In en, this message translates to:
  /// **'There is no building-block edit to redo.'**
  String get serviceTmBlockEditorNothingToRedo;

  /// TM building-block editor error for a missing block.
  ///
  /// In en, this message translates to:
  /// **'Block {block} does not exist.'**
  String serviceTmBlockEditorMissingBlock(String block);

  /// Localized reason for a rejected TM building-block project edit.
  ///
  /// In en, this message translates to:
  /// **'{diagnostic, select, duplicateMachineId{A block reuses the root machine ID.} duplicateBlockName{Block names must be non-empty and unique.} duplicateInvocationId{An invocation ID is duplicated.} duplicateInvocationState{A state invokes more than one block.} missingReference{An invocation references a missing block.} revisionMismatch{An invocation uses an outdated block revision.} missingAnchorState{An invocation has no graph state.} missingInitialState{A block has no initial state.} tapeCountMismatch{A block uses a different tape count from the root machine.} blankSymbolMismatch{A block uses a different blank symbol from the root machine.} nestedLibrary{A block contains an embedded library.} recursiveDependency{The block dependency graph is recursive.} other{The building-block project is invalid.}}'**
  String serviceTmBlockEditorInvalidProject(String diagnostic);

  /// No description provided for @serviceManualConversionStoreMalformedPayload.
  ///
  /// In en, this message translates to:
  /// **'The saved construction is malformed.'**
  String get serviceManualConversionStoreMalformedPayload;

  /// Safe file-operation failure that does not expose internal exceptions.
  ///
  /// In en, this message translates to:
  /// **'{operation, select, read{The selected file could not be read.} write{The file could not be saved.} encodePng{The PNG image could not be encoded.} exportPng{The PNG image could not be exported.} exportSvg{The SVG document could not be exported.} directory{The app documents directory is unavailable.} create{A new file location could not be created.} list{The saved files could not be listed.} delete{The selected file could not be deleted.} download{The download could not be started.} other{The file operation could not be completed.}}'**
  String serviceFileOperationsOperationFailed(String operation);

  /// File-operation failure when the platform denies access to the selected location.
  ///
  /// In en, this message translates to:
  /// **'{operation, select, read{Turing Lab does not have permission to read the selected file. Pick it again and retry.} write{Turing Lab does not have permission to save to the selected location. Choose it again and retry.} other{Turing Lab does not have permission to access the selected location. Choose it again and retry.}}'**
  String serviceFileOperationsAccessDenied(String operation);

  /// File-operation failure when the selected file or directory no longer exists.
  ///
  /// In en, this message translates to:
  /// **'{operation, select, read{The selected file is no longer available. Pick it again and retry.} write{The selected save location is no longer available. Choose another location and retry.} delete{The selected file no longer exists.} other{The selected location is no longer available. Choose it again and retry.}}'**
  String serviceFileOperationsLocationMissing(String operation);

  /// Safe fallback for an unclassified platform file-access failure.
  ///
  /// In en, this message translates to:
  /// **'{operation, select, read{The selected file could not be accessed for reading. Pick it again and retry.} write{The selected location could not be accessed for saving. Choose it again and retry.} other{The selected location could not be accessed. Choose it again and retry.}}'**
  String serviceFileOperationsAccessFailed(String operation);

  /// File operation that is intentionally unavailable in the browser implementation.
  ///
  /// In en, this message translates to:
  /// **'{operation, select, read{Reading a browser file by path is not supported. Use the file picker instead.} exportPng{PNG export is not available in the web app.} directory{The app documents directory is not available in the web app.} create{Creating a local file path is not supported in the web app.} list{Listing local files is not supported in the web app.} delete{Deleting a local file by path is not supported in the web app.} other{This file operation is not supported in the web app.}}'**
  String serviceFileOperationsWebUnsupported(String operation);

  /// Localized fallback when a document codec reports an unsupported operation without a more specific structured message.
  ///
  /// In en, this message translates to:
  /// **'{reason, select, document{This document type is not supported.} feature{This document uses an unsupported feature.} schema{This document schema is not supported.} format{This document format is not supported.} direction{This operation is not supported in the requested direction.} other{This document operation is not supported.}}'**
  String serviceFileOperationsCodecUnsupported(String reason);

  /// Error shown when document data matches an ambiguous number of codecs.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No compatible document codec was identified.} =1{One compatible document codec was identified, but the format remains ambiguous.} other{{count} compatible document codecs matched. Choose a specific format.}}'**
  String serviceFileOperationsCodecAmbiguous(int count);

  /// Localized fallback when a malformed document has no more specific structured parser message.
  ///
  /// In en, this message translates to:
  /// **'{reason, select, syntax{The document syntax is malformed.} invalidUtf8{The document is not valid UTF-8.} missingField{The document is missing a required field.} invalidValue{The document contains an invalid value.} duplicateIdentity{The document contains a duplicate identifier.} other{The document is malformed.}}'**
  String serviceFileOperationsCodecMalformed(String reason);

  /// Document import error with locale-formatted resource usage and configured limit.
  ///
  /// In en, this message translates to:
  /// **'{limit, select, bytes{The document uses {actual} bytes; the limit is {maximum}.} xmlDepth{The XML nesting depth is {actual}; the limit is {maximum}.} xmlElements{The XML contains {actual} elements; the limit is {maximum}.} xmlDtdOrEntity{The XML contains a prohibited DTD or entity declaration.} jsonDepth{The JSON nesting depth is {actual}; the limit is {maximum}.} collectionEntries{The document contains {actual} collection entries; the limit is {maximum}.} other{The document exceeds a resource limit ({actual} used; maximum {maximum}).}}'**
  String serviceFileOperationsCodecResourceLimit(
    String limit,
    int actual,
    int maximum,
  );

  /// Safe document-operation error that does not expose an internal exception.
  ///
  /// In en, this message translates to:
  /// **'{stage, select, sniff{The document format could not be identified because of an internal error.} decode{The document could not be decoded because of an internal error.} encode{The document could not be encoded because of an internal error.} unknown{The document operation failed because of an internal error.} other{The document operation failed because of an internal error.}}'**
  String serviceFileOperationsCodecInternalFailure(String stage);

  /// Import error used by model-only callers when extensions or lossy changes require the interoperability review workflow.
  ///
  /// In en, this message translates to:
  /// **'Review the compatibility changes before importing this document.'**
  String get serviceFileOperationsInteroperabilityReviewRequired;

  /// Export error used when a lossy codec result requires explicit confirmation.
  ///
  /// In en, this message translates to:
  /// **'Review and confirm the compatibility changes before exporting this document.'**
  String get serviceFileOperationsLossyExportRequiresConfirmation;

  /// Import error shown when a codec returns a model of the wrong formal-system type.
  ///
  /// In en, this message translates to:
  /// **'The document contains a different formal-system model than expected.'**
  String get serviceFileOperationsInvalidModelType;

  /// Title of the first regex simplification step.
  ///
  /// In en, this message translates to:
  /// **'Begin regex simplification'**
  String get regexSimplificationStartTitle;

  /// Explanation of the initial regex simplification state.
  ///
  /// In en, this message translates to:
  /// **'Starting with \"{regex}\". Current complexity: star height {starHeight}, nesting depth {nestingDepth}, and {operatorCount, plural, =0{no operators} =1{one operator} other{{operatorCount} operators}}. Algebraic identities will be applied to find an equivalent simpler form.'**
  String regexSimplificationStartExplanation(
    String regex,
    int starHeight,
    int nestingDepth,
    int operatorCount,
  );

  /// Title of a regex complexity analysis step.
  ///
  /// In en, this message translates to:
  /// **'Analyze regex complexity'**
  String get regexSimplificationAnalyzeTitle;

  /// Explanation of the regex complexity metrics.
  ///
  /// In en, this message translates to:
  /// **'Analyzing \"{regex}\": star height {starHeight}, nesting depth {nestingDepth}, {alphabetSize, plural, =0{no distinct symbols} =1{one distinct symbol} other{{alphabetSize} distinct symbols}}, and {operatorCount, plural, =0{no operators} =1{one operator} other{{operatorCount} operators}}.'**
  String regexSimplificationAnalyzeExplanation(
    String regex,
    int starHeight,
    int nestingDepth,
    int alphabetSize,
    int operatorCount,
  );

  /// Title of a regex rule application step.
  ///
  /// In en, this message translates to:
  /// **'Apply {ruleName}'**
  String regexSimplificationApplyTitle(String ruleName);

  /// Explanation of a regex rule application.
  ///
  /// In en, this message translates to:
  /// **'Applying {ruleName}. Matched \"{matched}\" {positionDescription} and replaced it with \"{replacement}\". {ruleDescription}. {lengthChangeDescription}'**
  String regexSimplificationApplyExplanation(
    String ruleName,
    String matched,
    String positionDescription,
    String replacement,
    String ruleDescription,
    String lengthChangeDescription,
  );

  /// Position phrase when a regex rule does not report an index.
  ///
  /// In en, this message translates to:
  /// **'at an unavailable position'**
  String get regexSimplificationPositionUnavailable;

  /// Position phrase for a regex rule match.
  ///
  /// In en, this message translates to:
  /// **'at position {position}'**
  String regexSimplificationPositionValue(int position);

  /// Length change after a regex simplification reduced the expression.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Saved one character.} other{Saved {count} characters.}}'**
  String regexSimplificationLengthReduced(int count);

  /// Length change after a regex transformation preserved the expression length.
  ///
  /// In en, this message translates to:
  /// **'The expression length did not change.'**
  String get regexSimplificationLengthUnchanged;

  /// Length change after a regex transformation expanded the expression.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{The expression grew by one character.} other{The expression grew by {count} characters.}}'**
  String regexSimplificationLengthIncreased(int count);

  /// Title of a regex sample generation step.
  ///
  /// In en, this message translates to:
  /// **'Generate sample strings'**
  String get regexSimplificationGenerateSamplesTitle;

  /// Explanation when regex sample generation returns no strings.
  ///
  /// In en, this message translates to:
  /// **'No sample strings were generated for \"{regex}\". The expression may accept the empty language.'**
  String regexSimplificationGenerateSamplesEmptyExplanation(String regex);

  /// Explanation listing generated regex samples.
  ///
  /// In en, this message translates to:
  /// **'Generated {count, plural, =1{one sample string} other{{count} sample strings}} for \"{regex}\": {samples}. These strings belong to the language described by the expression.'**
  String regexSimplificationGenerateSamplesExplanation(
    String regex,
    int count,
    String samples,
  );

  /// Title shown when no regex simplification rule applies.
  ///
  /// In en, this message translates to:
  /// **'No further simplification'**
  String get regexSimplificationNoRuleTitle;

  /// Explanation shown when regex simplification cannot continue.
  ///
  /// In en, this message translates to:
  /// **'All simplification rules were checked against \"{regex}\", and none applies. The expression is in the simplest form available through these algebraic identities. {ruleCount, plural, =0{No rules were applied.} =1{One rule was applied.} other{{ruleCount} rules were applied.}}'**
  String regexSimplificationNoRuleExplanation(String regex, int ruleCount);

  /// Title of the final regex simplification step.
  ///
  /// In en, this message translates to:
  /// **'Simplification complete'**
  String get regexSimplificationCompletionTitle;

  /// Summary of completed regex simplification.
  ///
  /// In en, this message translates to:
  /// **'Simplification changed \"{original}\" ({originalLength} characters) to \"{simplified}\" ({simplifiedLength} characters), a {reductionPercent}% reduction. {ruleCount, plural, =0{No rules were applied.} =1{One rule was applied.} other{{ruleCount} rules were applied.}} Final metrics: star height {starHeight}, nesting depth {nestingDepth}, and {operatorCount, plural, =0{no operators} =1{one operator} other{{operatorCount} operators}}.'**
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
  );

  /// Short summary for a regex step without a rule.
  ///
  /// In en, this message translates to:
  /// **'No rule applied'**
  String get regexSimplificationNoRuleSummary;

  /// Short summary of a regex rule replacement.
  ///
  /// In en, this message translates to:
  /// **'{ruleName}: \"{matched}\" → \"{replacement}\"'**
  String regexSimplificationRuleSummary(
    String ruleName,
    String matched,
    String replacement,
  );

  /// Localized label for a regex simplification step type.
  ///
  /// In en, this message translates to:
  /// **'{type, select, start{Start} analyze{Analyze} applyRule{Apply rule} noRuleApplicable{No rule applicable} generateSamples{Generate samples} completion{Completion} other{Unknown step}}'**
  String regexSimplificationStepTypeLabel(String type);

  /// Localized description of a regex simplification step type.
  ///
  /// In en, this message translates to:
  /// **'{type, select, start{Initialize the regex simplification process} analyze{Analyze the regex complexity metrics} applyRule{Apply an algebraic simplification rule} noRuleApplicable{Report that no further simplification rule applies} generateSamples{Generate sample strings that match the regex} completion{Complete the simplification process} other{Unknown simplification step}}'**
  String regexSimplificationStepTypeDescription(String type);

  /// Localized name of a regex simplification rule.
  ///
  /// In en, this message translates to:
  /// **'{rule, select, emptyUnion{Empty union (r|∅ → r)} emptyUnionLeft{Empty union on the left (∅|r → r)} emptySetConcatenation{Empty-set concatenation (r∅ → ∅)} emptySetConcatenationLeft{Empty-set concatenation on the left (∅r → ∅)} emptyStringConcatenation{Empty-string concatenation (rε → r)} emptyStringConcatenationLeft{Empty-string concatenation on the left (εr → r)} starIdempotence{Star idempotence (r** → r*)} emptySetStar{Empty-set star (∅* → ε)} emptyStringStar{Empty-string star (ε* → ε)} unionIdempotence{Union idempotence (r|r → r)} doubleStar{Double star ((r*)* → r*)} plusToStar{Plus to star (ε|rr* → r*)} plusToStarAlt{Alternative plus to star (ε|r*r → r*)} plusExpansion{Plus expansion (r+ → rr*)} optionalExpansion{Optional expansion (r? → ε|r)} optionalStarSimplification{Optional star ((ε|r)* → r*)} starConcatenationIdempotence{Star concatenation idempotence (r*r* → r*)} unionStarDistribution{Union-star distribution} redundantParentheses{Remove redundant parentheses} characterClassCreation{Create a character class} other{Unknown simplification rule}}'**
  String regexSimplificationRuleName(String rule);

  /// Localized explanation of a regex simplification rule.
  ///
  /// In en, this message translates to:
  /// **'{rule, select, emptyUnion{Union with the empty set has no effect; the result is the other operand} emptyUnionLeft{The empty set on the left of a union has no effect} emptySetConcatenation{Concatenation with the empty set produces the empty set} emptySetConcatenationLeft{The empty set on the left of a concatenation produces the empty set} emptyStringConcatenation{Concatenation with the empty string has no effect} emptyStringConcatenationLeft{The empty string on the left of a concatenation has no effect} starIdempotence{Applying the Kleene star twice is equivalent to applying it once} emptySetStar{The Kleene star of the empty set is the empty string} emptyStringStar{The Kleene star of the empty string is the empty string} unionIdempotence{A union of identical expressions simplifies to one copy} doubleStar{The star of a starred expression simplifies to one star} plusToStar{The union of the empty string and one-or-more repetitions equals zero-or-more repetitions} plusToStarAlt{The alternative one-or-more form with the empty string equals zero-or-more repetitions} plusExpansion{The plus operator expands to a concatenation with a star} optionalExpansion{The optional operator expands to a union with the empty string} optionalStarSimplification{The star of an optional expression simplifies to a star} starConcatenationIdempotence{A concatenation of identical stars simplifies to one star} unionStarDistribution{The star distributes over a union in specific patterns} redundantParentheses{Parentheses that do not affect precedence can be removed} characterClassCreation{Several single-character alternatives can form a character class} other{Unknown simplification rule}}'**
  String regexSimplificationRuleDescription(String rule);

  /// Validation error shown when regex simplification receives an empty expression.
  ///
  /// In en, this message translates to:
  /// **'A regular expression is required.'**
  String get regexSimplificationEmptyInput;

  /// Validation error identifying a closing parenthesis without a matching opening parenthesis.
  ///
  /// In en, this message translates to:
  /// **'Unmatched closing parenthesis at position {position}.'**
  String regexSimplificationUnmatchedClosingParenthesis(int position);

  /// Validation error reporting opening parentheses that have no matching close.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{One opening parenthesis is not closed.} other{{count} opening parentheses are not closed.}}'**
  String regexSimplificationUnclosedOpeningParentheses(int count);

  /// No description provided for @tmTapeBranchDeterministic.
  ///
  /// In en, this message translates to:
  /// **'Deterministic execution'**
  String get tmTapeBranchDeterministic;

  /// No description provided for @tmTapeBranchAcceptingNtm.
  ///
  /// In en, this message translates to:
  /// **'Accepting NTM branch'**
  String get tmTapeBranchAcceptingNtm;

  /// No description provided for @tmTapeBranchRejectingNtm.
  ///
  /// In en, this message translates to:
  /// **'Rejecting NTM branch'**
  String get tmTapeBranchRejectingNtm;

  /// No description provided for @tmTapeBranchCyclicNtm.
  ///
  /// In en, this message translates to:
  /// **'Cyclic NTM branch'**
  String get tmTapeBranchCyclicNtm;

  /// No description provided for @tmTapeBranchLongestBoundedNtm.
  ///
  /// In en, this message translates to:
  /// **'Longest bounded NTM branch'**
  String get tmTapeBranchLongestBoundedNtm;

  /// No description provided for @tmTapeInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Input'**
  String get tmTapeInputLabel;

  /// No description provided for @tmTapeSelectedBranchLabel.
  ///
  /// In en, this message translates to:
  /// **'Selected branch'**
  String get tmTapeSelectedBranchLabel;

  /// No description provided for @tmTapeConclusionLabel.
  ///
  /// In en, this message translates to:
  /// **'Conclusion'**
  String get tmTapeConclusionLabel;

  /// No description provided for @tmTapeConclusionExact.
  ///
  /// In en, this message translates to:
  /// **'Exact for this input'**
  String get tmTapeConclusionExact;

  /// No description provided for @tmTapeConclusionBounded.
  ///
  /// In en, this message translates to:
  /// **'Bounded'**
  String get tmTapeConclusionBounded;

  /// No description provided for @tmTapeExecutedTransitionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Executed transitions'**
  String get tmTapeExecutedTransitionsLabel;

  /// No description provided for @tmTapeConfigurationsExploredLabel.
  ///
  /// In en, this message translates to:
  /// **'Configurations explored'**
  String get tmTapeConfigurationsExploredLabel;

  /// No description provided for @tmTapeStepLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'Step limit'**
  String get tmTapeStepLimitLabel;

  /// No description provided for @tmTapeConfigurationLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'Configuration limit'**
  String get tmTapeConfigurationLimitLabel;

  /// No description provided for @tmTapeTimeLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'Time limit'**
  String get tmTapeTimeLimitLabel;

  /// No description provided for @tmTapeLimitReachedLabel.
  ///
  /// In en, this message translates to:
  /// **'Limit reached'**
  String get tmTapeLimitReachedLabel;

  /// No description provided for @tmTapeLimitSteps.
  ///
  /// In en, this message translates to:
  /// **'Step limit'**
  String get tmTapeLimitSteps;

  /// No description provided for @tmTapeLimitConfigurations.
  ///
  /// In en, this message translates to:
  /// **'Configuration limit'**
  String get tmTapeLimitConfigurations;

  /// No description provided for @tmTapeLimitTimeout.
  ///
  /// In en, this message translates to:
  /// **'Time limit'**
  String get tmTapeLimitTimeout;

  /// No description provided for @tmTapeChangedWritesLabel.
  ///
  /// In en, this message translates to:
  /// **'Writes that changed a cell'**
  String get tmTapeChangedWritesLabel;

  /// No description provided for @tmTapeHeadReversalsLabel.
  ///
  /// In en, this message translates to:
  /// **'Head reversals'**
  String get tmTapeHeadReversalsLabel;

  /// No description provided for @tmTapeVisitedHeadIntervalLabel.
  ///
  /// In en, this message translates to:
  /// **'Visited head interval'**
  String get tmTapeVisitedHeadIntervalLabel;

  /// No description provided for @tmTapeDistinctCellsVisitedLabel.
  ///
  /// In en, this message translates to:
  /// **'Distinct cells visited'**
  String get tmTapeDistinctCellsVisitedLabel;

  /// No description provided for @tmTapeMaximumNonblankLabel.
  ///
  /// In en, this message translates to:
  /// **'Maximum simultaneous nonblank cells'**
  String get tmTapeMaximumNonblankLabel;

  /// No description provided for @tmTapeDeclaredAlphabetLabel.
  ///
  /// In en, this message translates to:
  /// **'Declared tape alphabet'**
  String get tmTapeDeclaredAlphabetLabel;

  /// No description provided for @tmTapeReadsBySymbolLabel.
  ///
  /// In en, this message translates to:
  /// **'Reads by symbol'**
  String get tmTapeReadsBySymbolLabel;

  /// No description provided for @tmTapeWritesByOldSymbolLabel.
  ///
  /// In en, this message translates to:
  /// **'Writes by old symbol'**
  String get tmTapeWritesByOldSymbolLabel;

  /// No description provided for @tmTapeWritesByNewSymbolLabel.
  ///
  /// In en, this message translates to:
  /// **'Writes by new symbol'**
  String get tmTapeWritesByNewSymbolLabel;

  /// No description provided for @tmTapeHeadMovementsLabel.
  ///
  /// In en, this message translates to:
  /// **'Head movements'**
  String get tmTapeHeadMovementsLabel;

  /// No description provided for @tmTapeTransitionCountsLabel.
  ///
  /// In en, this message translates to:
  /// **'Transition execution counts'**
  String get tmTapeTransitionCountsLabel;

  /// No description provided for @tmTapeUnexecutedTransitionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Defined but not executed transitions'**
  String get tmTapeUnexecutedTransitionsLabel;

  /// No description provided for @tmTapeSparseDiffLabel.
  ///
  /// In en, this message translates to:
  /// **'Sparse initial-to-final tape diff'**
  String get tmTapeSparseDiffLabel;

  /// No description provided for @tmTapeCellTouchRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'First and last step touching each cell'**
  String get tmTapeCellTouchRangeLabel;

  /// Configured Turing machine execution time limit in seconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s'**
  String tmTapeDurationSeconds(String seconds);

  /// Formal metric name and its locale-formatted count.
  ///
  /// In en, this message translates to:
  /// **'{name}: {count}'**
  String tmTapeNamedCount(String name, String count);

  /// Minimum and maximum logical positions visited by the tape head.
  ///
  /// In en, this message translates to:
  /// **'{minimum}…{maximum}'**
  String tmTapeHeadInterval(String minimum, String maximum);

  /// Formal initial and final contents of one changed tape cell.
  ///
  /// In en, this message translates to:
  /// **'{position}: {initialSymbol} → {finalSymbol}'**
  String tmTapeCellDiff(
    String position,
    String initialSymbol,
    String finalSymbol,
  );

  /// First and last execution step that touched one tape cell.
  ///
  /// In en, this message translates to:
  /// **'{position}: {first}…{last}'**
  String tmTapeCellTouchRange(String position, String first, String last);

  /// Two-line trace summary containing the formal transition and localized tape-head state.
  ///
  /// In en, this message translates to:
  /// **'{transition}\n{tape}'**
  String tmTapeTraceSubtitle(String transition, String tape);

  /// Title of the initial regex-to-NFA conversion step.
  ///
  /// In en, this message translates to:
  /// **'Begin Thompson\'s construction'**
  String get regexToNfaStartTitle;

  /// Explanation of the initial regex-to-NFA conversion step.
  ///
  /// In en, this message translates to:
  /// **'Converting \"{regex}\" to an NFA with Thompson\'s construction. The algorithm creates one fragment for each subexpression, then combines the fragments with ε-transitions.'**
  String regexToNfaStartExplanation(String regex);

  /// Title of a Thompson-construction step for one regex symbol.
  ///
  /// In en, this message translates to:
  /// **'Create an NFA for \"{symbol}\"'**
  String regexToNfaBasicSymbolTitle(String symbol);

  /// Explanation of a Thompson fragment created for one symbol or character set.
  ///
  /// In en, this message translates to:
  /// **'Processing \"{symbol}\" {positionDescription}. Created a fragment from {startState} to {acceptState} with {stateCount, plural, =1{one state} other{{stateCount} states}} and {transitionCount, plural, =1{one transition} other{{transitionCount} transitions}}: {transitions}. Stack depth: {stackSize}.'**
  String regexToNfaBasicSymbolExplanation(
    String symbol,
    String positionDescription,
    String startState,
    String acceptState,
    int stateCount,
    int transitionCount,
    String transitions,
    int stackSize,
  );

  /// Title of a Thompson-construction concatenation step.
  ///
  /// In en, this message translates to:
  /// **'Apply concatenation'**
  String get regexToNfaConcatenationTitle;

  /// Explanation of a Thompson-construction concatenation step.
  ///
  /// In en, this message translates to:
  /// **'Concatenating \"{firstFragment}\" and \"{secondFragment}\" {positionDescription}. Added ε-bridges: {transitions}. The resulting fragment starts at {startState} and accepts at {acceptStates}. Stack depth: {stackSize}.'**
  String regexToNfaConcatenationExplanation(
    String positionDescription,
    String firstFragment,
    String secondFragment,
    String startState,
    String acceptStates,
    String transitions,
    int stackSize,
  );

  /// Title of a Thompson-construction union step.
  ///
  /// In en, this message translates to:
  /// **'Apply union'**
  String get regexToNfaUnionTitle;

  /// Explanation of a Thompson-construction union step.
  ///
  /// In en, this message translates to:
  /// **'Creating a union for \"{pattern}\" {positionDescription}. Added start state {startState}, accept state {acceptState}, and ε-transitions: {transitions}. Either branch can be followed. Stack depth: {stackSize}.'**
  String regexToNfaUnionExplanation(
    String positionDescription,
    String pattern,
    String startState,
    String acceptState,
    String transitions,
    int stackSize,
  );

  /// Title of a Thompson-construction Kleene-star step.
  ///
  /// In en, this message translates to:
  /// **'Apply Kleene star (*)'**
  String get regexToNfaKleeneStarTitle;

  /// Explanation of a Thompson-construction Kleene-star step.
  ///
  /// In en, this message translates to:
  /// **'Applying Kleene star to \"{fragment}\" {positionDescription}. The fragment now starts at {startState}, accepts at {acceptState}, and uses these ε-transitions: {transitions}. It accepts zero or more repetitions. Stack depth: {stackSize}.'**
  String regexToNfaKleeneStarExplanation(
    String fragment,
    String positionDescription,
    String startState,
    String acceptState,
    String transitions,
    int stackSize,
  );

  /// Title of a Thompson-construction plus step.
  ///
  /// In en, this message translates to:
  /// **'Apply plus (+)'**
  String get regexToNfaPlusTitle;

  /// Explanation of a Thompson-construction plus step.
  ///
  /// In en, this message translates to:
  /// **'Applying plus to \"{fragment}\" {positionDescription}. The fragment now starts at {startState}, accepts at {acceptState}, and uses these ε-transitions: {transitions}. It requires at least one repetition. Stack depth: {stackSize}.'**
  String regexToNfaPlusExplanation(
    String fragment,
    String positionDescription,
    String startState,
    String acceptState,
    String transitions,
    int stackSize,
  );

  /// Title of a Thompson-construction optional step.
  ///
  /// In en, this message translates to:
  /// **'Apply optional (?)'**
  String get regexToNfaOptionalTitle;

  /// Explanation of a Thompson-construction optional step.
  ///
  /// In en, this message translates to:
  /// **'Making \"{fragment}\" optional {positionDescription}. The fragment now starts at {startState}, accepts at {acceptState}, and uses these ε-transitions: {transitions}. It accepts zero or one occurrence. Stack depth: {stackSize}.'**
  String regexToNfaOptionalExplanation(
    String fragment,
    String positionDescription,
    String startState,
    String acceptState,
    String transitions,
    int stackSize,
  );

  /// Title of the final regex-to-NFA conversion step.
  ///
  /// In en, this message translates to:
  /// **'Complete NFA construction'**
  String get regexToNfaCompleteTitle;

  /// Explanation of the completed regex-to-NFA conversion.
  ///
  /// In en, this message translates to:
  /// **'Thompson\'s construction is complete. The NFA starts at {startState}, accepts at {acceptState}, and has {stateCount, plural, =1{one state} other{{stateCount} states}} and {transitionCount, plural, =1{one transition} other{{transitionCount} transitions}}. It accepts the language described by the regular expression.'**
  String regexToNfaCompleteExplanation(
    String startState,
    String acceptState,
    int stateCount,
    int transitionCount,
  );

  /// Position phrase for a regex-to-NFA operation without a source index.
  ///
  /// In en, this message translates to:
  /// **'at an implicit position'**
  String get regexToNfaPositionUnavailable;

  /// Position phrase for a regex-to-NFA operation.
  ///
  /// In en, this message translates to:
  /// **'at position {position}'**
  String regexToNfaPositionValue(int position);

  /// Localized label for a regex-to-NFA step type.
  ///
  /// In en, this message translates to:
  /// **'{type, select, start{Start} basicSymbol{Basic symbol} concatenation{Concatenation} union{Union} kleeneStar{Kleene star} plus{Plus} optional{Optional} complete{Complete} other{Unknown step}}'**
  String regexToNfaStepTypeLabel(String type);

  /// Localized description of a regex-to-NFA step type.
  ///
  /// In en, this message translates to:
  /// **'{type, select, start{Initialize Thompson\'s construction} basicSymbol{Create an NFA fragment for one symbol} concatenation{Concatenate two NFA fragments} union{Create a union of two NFA fragments} kleeneStar{Accept zero or more repetitions} plus{Accept one or more repetitions} optional{Accept zero or one occurrence} complete{Finish the NFA construction} other{Unknown conversion step}}'**
  String regexToNfaStepTypeDescription(String type);

  /// Localized title for an FA-to-regex state-elimination step.
  ///
  /// In en, this message translates to:
  /// **'{type, select, validation{Validate input automaton} addInitialState{Add new initial state {state}} addFinalState{Add new final state {state}} selectState{Select {state} for elimination} findIncoming{Find incoming transitions} findOutgoing{Find outgoing transitions} findSelfLoop{Check self-loops on {state}} createBypass{Create bypass transitions} combineTransitions{Combine parallel transitions} completeElimination{Complete elimination of {state}} extractRegex{Extract final regular expression} completion{Conversion complete} other{FA-to-regex step}}'**
  String faToRegexStepTitle(String type, String state);

  /// Localized label for an FA-to-regex step type.
  ///
  /// In en, this message translates to:
  /// **'{type, select, validation{Validation} addInitialState{Add initial state} addFinalState{Add final state} selectState{Select state} findIncoming{Find incoming transitions} findOutgoing{Find outgoing transitions} findSelfLoop{Find self-loop} createBypass{Create bypass transitions} combineTransitions{Combine transitions} completeElimination{Complete elimination} extractRegex{Extract regular expression} completion{Completion} other{FA-to-regex step}}'**
  String faToRegexStepTypeLabel(String type);

  /// Localized description of an FA-to-regex step type.
  ///
  /// In en, this message translates to:
  /// **'{type, select, validation{Validate the input automaton.} addInitialState{Add a unique initial state for normalization.} addFinalState{Add a unique final state for normalization.} selectState{Select the next state to eliminate.} findIncoming{Find transitions entering the selected state.} findOutgoing{Find transitions leaving the selected state.} findSelfLoop{Find and process self-loops on the selected state.} createBypass{Create transitions that bypass the selected state.} combineTransitions{Combine parallel transitions with regular-expression union.} completeElimination{Remove the selected state after replacing its paths.} extractRegex{Extract the final regular expression from the simplified automaton.} completion{Finish the FA-to-regex conversion.} other{Process an FA-to-regex conversion step.}}'**
  String faToRegexStepTypeDescription(String type);

  /// Localized summary of the state currently being eliminated.
  ///
  /// In en, this message translates to:
  /// **'{hasState, select, true{Eliminating {state}: {incomingStateCount, plural, =0{no incoming states} =1{1 incoming state} other{{incomingStateCount} incoming states}}, {outgoingStateCount, plural, =0{no outgoing states} =1{1 outgoing state} other{{outgoingStateCount} outgoing states}}, {hasSelfLoop, select, true{a self-loop.} other{no self-loop.}}} other{No state is being eliminated.}}'**
  String faToRegexEliminationSummary(
    String hasState,
    String state,
    int incomingStateCount,
    int outgoingStateCount,
    String hasSelfLoop,
  );

  /// Validation result before FA-to-regex conversion.
  ///
  /// In en, this message translates to:
  /// **'Validating the input finite automaton. It has {stateCount, plural, =1{one state} other{{stateCount} states}} and {transitionCount, plural, =1{one transition} other{{transitionCount} transitions}}. {hasInitialState, select, true{An initial state is present.} other{No initial state was found.}} {hasAcceptingStates, select, true{Accepting states are present.} other{There are no accepting states, so the language is empty.}}'**
  String faToRegexValidationExplanation(
    int stateCount,
    int transitionCount,
    String hasInitialState,
    String hasAcceptingStates,
  );

  /// Explanation of initial-state normalization.
  ///
  /// In en, this message translates to:
  /// **'Adding the new initial state {newState}, with an ε-transition to the original initial state {oldState}. This leaves one initial state with no incoming transitions.'**
  String faToRegexAddInitialStateExplanation(String newState, String oldState);

  /// Explanation of accepting-state normalization.
  ///
  /// In en, this message translates to:
  /// **'Adding the new final state {newState}. The original accepting states, {oldStates}, receive ε-transitions to it, leaving one accepting state with no outgoing transitions.'**
  String faToRegexAddFinalStateExplanation(String newState, String oldStates);

  /// Explanation of state selection for elimination.
  ///
  /// In en, this message translates to:
  /// **'Selecting {state} for elimination. Equivalent direct transitions will replace paths through it; {remainingStateCount, plural, =1{one state will remain} other{{remainingStateCount} states will remain}}.'**
  String faToRegexSelectStateExplanation(String state, int remainingStateCount);

  /// Explanation of incoming-transition discovery.
  ///
  /// In en, this message translates to:
  /// **'Finding transitions into {state}. Found {transitionCount, plural, =0{none} =1{one transition} other{{transitionCount} transitions}} from: {states}.'**
  String faToRegexFindIncomingExplanation(
    String state,
    int transitionCount,
    String states,
  );

  /// Explanation of outgoing-transition discovery.
  ///
  /// In en, this message translates to:
  /// **'Finding transitions out of {state}. Found {transitionCount, plural, =0{none} =1{one transition} other{{transitionCount} transitions}} to: {states}.'**
  String faToRegexFindOutgoingExplanation(
    String state,
    int transitionCount,
    String states,
  );

  /// Explanation of self-loop processing.
  ///
  /// In en, this message translates to:
  /// **'{hasLoop, select, true{Found a self-loop on {state} and combined it as {selfLoopRegex}; this expression is inserted between incoming and outgoing transitions.} other{No self-loop was found on {state}; new transitions connect incoming and outgoing states directly.}}'**
  String faToRegexFindSelfLoopExplanation(
    String hasLoop,
    String state,
    String selfLoopRegex,
  );

  /// Explanation of bypass-transition creation.
  ///
  /// In en, this message translates to:
  /// **'Creating {transitionCount, plural, =1{one transition} other{{transitionCount} transitions}} to bypass {state}. Each combines an incoming label, the self-loop closure, and an outgoing label; for example: {pathRegex}.'**
  String faToRegexCreateBypassExplanation(
    int transitionCount,
    String state,
    String pathRegex,
  );

  /// Explanation of parallel-transition combination.
  ///
  /// In en, this message translates to:
  /// **'Combining {regexCount, plural, =1{one expression} other{{regexCount} expressions}} from {fromState} to {toState} with union: {regexes}. Result: {resultingRegex}.'**
  String faToRegexCombineTransitionsExplanation(
    int regexCount,
    String fromState,
    String toState,
    String regexes,
    String resultingRegex,
  );

  /// Explanation of completed state elimination.
  ///
  /// In en, this message translates to:
  /// **'Eliminated {state}. Equivalent direct transitions now replace every path through it; {remainingStateCount, plural, =1{one state remains} other{{remainingStateCount} states remain}}.'**
  String faToRegexCompleteEliminationExplanation(
    String state,
    int remainingStateCount,
  );

  /// Explanation of final regular-expression extraction.
  ///
  /// In en, this message translates to:
  /// **'All intermediate states are gone. Reading the transitions from initial state {initialState} to final state {finalState} gives: {regex}.'**
  String faToRegexExtractRegexExplanation(
    String initialState,
    String finalState,
    String regex,
  );

  /// Explanation of completed FA-to-regex conversion.
  ///
  /// In en, this message translates to:
  /// **'Converted the {originalStateCount, plural, =1{one-state automaton} other{{originalStateCount}-state automaton}} to {regex} in {stepCount, plural, =1{one step} other{{stepCount} steps}}. The regular expression accepts the same language.'**
  String faToRegexCompletionExplanation(
    int originalStateCount,
    String regex,
    int stepCount,
  );

  /// Validation message for a bounded CFG brute-force limit that cannot be negative.
  ///
  /// In en, this message translates to:
  /// **'{limit} must not be negative.'**
  String bruteForceInvalidLimitNonNegative(String limit);

  /// Validation message for a bounded CFG brute-force limit that must be positive.
  ///
  /// In en, this message translates to:
  /// **'{limit} must be positive.'**
  String bruteForceInvalidLimitPositive(String limit);

  /// Bounded CFG brute-force validation message for an empty grammar.
  ///
  /// In en, this message translates to:
  /// **'Grammar must have at least one production.'**
  String get bruteForceEmptyGrammar;

  /// Bounded CFG brute-force validation message for an undeclared start symbol.
  ///
  /// In en, this message translates to:
  /// **'The start symbol must be a declared non-terminal.'**
  String get bruteForceInvalidStartSymbol;

  /// Bounded CFG brute-force validation message for symbols declared in both sets.
  ///
  /// In en, this message translates to:
  /// **'Grammar symbols cannot be both terminals and non-terminals: {symbols}.'**
  String bruteForceOverlappingSymbols(String symbols);

  /// Bounded CFG brute-force validation message for a malformed production.
  ///
  /// In en, this message translates to:
  /// **'CFG brute-force search requires one declared non-terminal on every production LHS.'**
  String get bruteForceMalformedProduction;

  /// Bounded CFG brute-force validation message for duplicate production IDs.
  ///
  /// In en, this message translates to:
  /// **'CFG brute-force search requires unique production IDs.'**
  String get bruteForceDuplicateProductionId;

  /// Bounded CFG brute-force validation message for an undeclared RHS symbol.
  ///
  /// In en, this message translates to:
  /// **'Production {production} references undeclared symbol \"{symbol}\".'**
  String bruteForceUndeclaredSymbol(String production, String symbol);

  /// Bounded CFG brute-force validation message for an input symbol outside the terminal alphabet.
  ///
  /// In en, this message translates to:
  /// **'Input string contains invalid symbol: {symbol}.'**
  String bruteForceInvalidInputSymbol(String symbol);

  /// Structured grammar tokenizer diagnostic for an input symbol outside the terminal alphabet.
  ///
  /// In en, this message translates to:
  /// **'Input string contains invalid symbol {symbol} at position {position}.'**
  String grammarInputTokenizationInvalidSymbol(String symbol, int position);

  /// Bounded CFG brute-force cancellation outcome.
  ///
  /// In en, this message translates to:
  /// **'CFG brute-force search was cancelled.'**
  String get bruteForceCancelled;

  /// Bounded CFG brute-force rejection after exhausting the finite derivation frontier.
  ///
  /// In en, this message translates to:
  /// **'The finite CFG derivation frontier was exhausted soundly.'**
  String get bruteForceRejectedExhausted;

  /// Bounded CFG brute-force acceptance with witness enumeration stopped by a limit.
  ///
  /// In en, this message translates to:
  /// **'Accepted, but witness enumeration stopped at the {limit} limit.'**
  String bruteForceAcceptedAtLimit(String limit);

  /// Bounded CFG brute-force inconclusive outcome after a search limit.
  ///
  /// In en, this message translates to:
  /// **'No witness was found before the {limit} limit stopped search.'**
  String bruteForceBoundedAtLimit(String limit);

  /// Validation message shown when PDA simulation receives an empty state set.
  ///
  /// In en, this message translates to:
  /// **'A PDA must have at least one state.'**
  String get pdaSimulationEmptyStateSet;

  /// Validation message shown when PDA simulation has no initial state.
  ///
  /// In en, this message translates to:
  /// **'A PDA must have an initial state.'**
  String get pdaSimulationMissingInitialState;

  /// Validation message shown when a PDA initial state is outside its state set.
  ///
  /// In en, this message translates to:
  /// **'The initial state must belong to the PDA state set.'**
  String get pdaSimulationInitialStateOutsideSet;

  /// Validation message shown when a PDA accepting state is outside its state set.
  ///
  /// In en, this message translates to:
  /// **'Every accepting state must belong to the PDA state set.'**
  String get pdaSimulationAcceptingStateOutsideSet;

  /// Validation message shown when a DFA simulation receives a non-deterministic or epsilon-transition automaton.
  ///
  /// In en, this message translates to:
  /// **'A DFA is required: the automaton must be deterministic and have no ε-transitions.'**
  String get automatonSimulationDfaRequired;

  /// Validation message shown when a finite-automaton simulation has no states.
  ///
  /// In en, this message translates to:
  /// **'Cannot simulate an empty automaton.'**
  String get automatonSimulationEmptyAutomaton;

  /// Validation message shown when a finite automaton has no initial state.
  ///
  /// In en, this message translates to:
  /// **'The automaton must have an initial state.'**
  String get automatonSimulationMissingInitialState;

  /// Validation message shown when an automaton initial state is not in its state set.
  ///
  /// In en, this message translates to:
  /// **'The initial state must belong to the state set.'**
  String get automatonSimulationInitialStateOutsideSet;

  /// Validation message shown when an accepting state is not in the automaton state set.
  ///
  /// In en, this message translates to:
  /// **'Every accepting state must belong to the state set.'**
  String get automatonSimulationAcceptingStateOutsideSet;

  /// Validation message shown when a DFA input symbol is outside the automaton alphabet.
  ///
  /// In en, this message translates to:
  /// **'The input string contains an invalid symbol: {symbol}.'**
  String automatonSimulationInvalidInputSymbol(String symbol);

  /// DFA simulation rejection when no transition matches the current state and input symbol.
  ///
  /// In en, this message translates to:
  /// **'No transition from state {state} on symbol {symbol}.'**
  String automatonSimulationNoDfaTransition(String state, String symbol);

  /// DFA simulation rejection after consuming all input without reaching an accepting state.
  ///
  /// In en, this message translates to:
  /// **'Rejected: no accepting state was reached.'**
  String get automatonSimulationRejectedNoAcceptingState;

  /// NFA simulation rejection when no state has a transition for the input symbol.
  ///
  /// In en, this message translates to:
  /// **'No transition was found for symbol {symbol}.'**
  String automatonSimulationNoNfaTransition(String symbol);

  /// NFA simulation rejection after no accepting state remains reachable.
  ///
  /// In en, this message translates to:
  /// **'Input not accepted: no accepting state was reached.'**
  String get automatonSimulationNfaNotAccepted;

  /// Warning shown when NFA computation-tree expansion reaches its time limit.
  ///
  /// In en, this message translates to:
  /// **'The NFA computation tree timed out after {steps} steps.'**
  String automatonSimulationComputationTreeTimeout(int steps);

  /// Warning shown when NFA computation-tree expansion detects an infinite loop.
  ///
  /// In en, this message translates to:
  /// **'The NFA computation tree detected an infinite loop after {steps} steps.'**
  String automatonSimulationComputationTreeInfiniteLoop(int steps);

  /// Unexpected DFA simulation failure with a diagnostic detail.
  ///
  /// In en, this message translates to:
  /// **'Unable to simulate the DFA: {error}.'**
  String automatonSimulationDfaFailure(String error);

  /// Unexpected NFA simulation failure with a diagnostic detail.
  ///
  /// In en, this message translates to:
  /// **'Unable to simulate the NFA: {error}.'**
  String automatonSimulationNfaFailure(String error);

  /// Unexpected failure while enumerating strings accepted by an automaton.
  ///
  /// In en, this message translates to:
  /// **'Unable to enumerate accepted strings: {error}.'**
  String automatonSimulationAcceptedStringsFailure(String error);

  /// Unexpected failure while enumerating strings rejected by an automaton.
  ///
  /// In en, this message translates to:
  /// **'Unable to enumerate rejected strings: {error}.'**
  String automatonSimulationRejectedStringsFailure(String error);

  /// Title for a DFA step explanation.
  ///
  /// In en, this message translates to:
  /// **'Transition applied'**
  String get automatonSimulationTransitionAppliedTitle;

  /// Step explanation describing the input symbol consumed by an automaton.
  ///
  /// In en, this message translates to:
  /// **'Read symbol \"{symbol}\" from the input.'**
  String automatonSimulationReadSymbol(String symbol);

  /// Step explanation describing a DFA transition.
  ///
  /// In en, this message translates to:
  /// **'From state {fromState}, the transition on \"{symbol}\" leads to {toState}.'**
  String automatonSimulationTransitionDetail(
    String fromState,
    String symbol,
    String toState,
  );

  /// Title for an NFA epsilon-closure step explanation.
  ///
  /// In en, this message translates to:
  /// **'Computed ε-closure'**
  String get automatonSimulationComputedEpsilonClosureTitle;

  /// Step explanation describing the NFA epsilon closure before input consumption.
  ///
  /// In en, this message translates to:
  /// **'Before reading input, an NFA may take ε-transitions (moves that consume no input).'**
  String get automatonSimulationEpsilonClosureBeforeReading;

  /// Step explanation listing states reached by an initial epsilon closure.
  ///
  /// In en, this message translates to:
  /// **'Starting from {initialState}, ε-transitions reach: {stateSet}.'**
  String automatonSimulationEpsilonClosureReached(
    String initialState,
    String stateSet,
  );

  /// Title for an NFA input-consumption step explanation.
  ///
  /// In en, this message translates to:
  /// **'Symbol consumed'**
  String get automatonSimulationSymbolConsumedTitle;

  /// Step explanation calling out an NFA's multiple active states.
  ///
  /// In en, this message translates to:
  /// **'This NFA step may have multiple active states (nondeterminism).'**
  String get automatonSimulationNondeterministicStep;

  /// Step explanation listing the active NFA state set after consuming a symbol.
  ///
  /// In en, this message translates to:
  /// **'After taking all transitions on \"{symbol}\", the active state set is {stateSet}.'**
  String automatonSimulationActiveSetAfterTransitions(
    String symbol,
    String stateSet,
  );

  /// Title for an NFA epsilon-closure expansion step explanation.
  ///
  /// In en, this message translates to:
  /// **'Expanded via ε-transitions'**
  String get automatonSimulationExpandedViaEpsilonTitle;

  /// Step explanation describing epsilon transitions after an NFA consumes a symbol.
  ///
  /// In en, this message translates to:
  /// **'After consuming \"{symbol}\", we also follow any ε-transitions (moves that consume no input).'**
  String automatonSimulationEpsilonAfterConsuming(String symbol);

  /// Step explanation comparing NFA active state sets before and after epsilon closure.
  ///
  /// In en, this message translates to:
  /// **'The ε-closure expanded the active state set from {before} to {after}.'**
  String automatonSimulationEpsilonClosureExpanded(String before, String after);

  /// Description for an NFA computation-tree node at an initial state.
  ///
  /// In en, this message translates to:
  /// **'Initial state {state}'**
  String automatonSimulationInitialStateDescription(String state);

  /// Description for an NFA computation-tree node reached after consuming an input symbol.
  ///
  /// In en, this message translates to:
  /// **'Consumed {symbol}; now at {state}'**
  String automatonSimulationConsumedSymbolDescription(
    String symbol,
    String state,
  );

  /// Description for the virtual root of an NFA computation tree with an initial epsilon closure.
  ///
  /// In en, this message translates to:
  /// **'Initial ε-closure'**
  String get automatonSimulationInitialEpsilonClosureDescription;

  /// Validation message for an empty FSA Kleene-star operand.
  ///
  /// In en, this message translates to:
  /// **'The Kleene-star operand must contain at least one state.'**
  String get fsaKleeneStarEmptyOperand;

  /// Validation message for a Kleene-star operand without an initial state.
  ///
  /// In en, this message translates to:
  /// **'The Kleene-star operand must have an initial state.'**
  String get fsaKleeneStarMissingInitialState;

  /// Validation message for an initial state outside a Kleene-star operand state set.
  ///
  /// In en, this message translates to:
  /// **'The Kleene-star operand has an initial state outside its state set.'**
  String get fsaKleeneStarInitialStateOutsideSet;

  /// Validation message for an accepting state outside a Kleene-star operand state set.
  ///
  /// In en, this message translates to:
  /// **'The Kleene-star operand has an accepting state outside its state set.'**
  String get fsaKleeneStarAcceptingStateOutsideSet;

  /// Validation message for a non-FSA transition in a Kleene-star operand.
  ///
  /// In en, this message translates to:
  /// **'The Kleene-star operand contains a non-FSA transition.'**
  String get fsaKleeneStarNonFsaTransition;

  /// Validation message for an unknown transition endpoint in a Kleene-star operand.
  ///
  /// In en, this message translates to:
  /// **'The Kleene-star operand contains a transition with an unknown endpoint.'**
  String get fsaKleeneStarUnknownTransitionEndpoint;

  /// Validation message for an invalid transition in a Kleene-star operand.
  ///
  /// In en, this message translates to:
  /// **'The Kleene-star operand contains an invalid transition: {transition}.'**
  String fsaKleeneStarInvalidTransition(String transition);

  /// Analysis message for duplicate state IDs in a Kleene-star result.
  ///
  /// In en, this message translates to:
  /// **'The Kleene-star result contains duplicate state IDs.'**
  String get fsaKleeneStarDuplicateStateIds;

  /// Analysis message for duplicate transition IDs in a Kleene-star result.
  ///
  /// In en, this message translates to:
  /// **'The Kleene-star result contains duplicate transition IDs.'**
  String get fsaKleeneStarDuplicateTransitionIds;

  /// Analysis message for an invalid Kleene-star result.
  ///
  /// In en, this message translates to:
  /// **'The Kleene-star result is not a valid finite automaton.'**
  String get fsaKleeneStarInvalidResult;

  /// Safe fallback for an unexpected Kleene-star construction failure.
  ///
  /// In en, this message translates to:
  /// **'The Kleene-star construction failed.'**
  String get fsaKleeneStarInternalFailure;

  /// Title for the first FSA Kleene-star construction step.
  ///
  /// In en, this message translates to:
  /// **'Clone the operand'**
  String get fsaKleeneStarCloneTitle;

  /// Title for the epsilon-entry FSA Kleene-star construction step.
  ///
  /// In en, this message translates to:
  /// **'Add the epsilon entry'**
  String get fsaKleeneStarEntryTitle;

  /// Title for the repeat-transition FSA Kleene-star construction step.
  ///
  /// In en, this message translates to:
  /// **'Add repeat transitions'**
  String get fsaKleeneStarRepeatTitle;

  /// Title for the exit-transition FSA Kleene-star construction step.
  ///
  /// In en, this message translates to:
  /// **'Add exit transitions'**
  String get fsaKleeneStarExitTitle;

  /// Explanation for cloning FSA Kleene-star operand states.
  ///
  /// In en, this message translates to:
  /// **'Copy every operand state into a separate, deterministic ID namespace.'**
  String get fsaKleeneStarCloneExplanation;

  /// Explanation for adding the FSA Kleene-star epsilon entry.
  ///
  /// In en, this message translates to:
  /// **'Create an accepting initial state so the result accepts epsilon, then connect it to the cloned operand.'**
  String get fsaKleeneStarEntryExplanation;

  /// Explanation for adding FSA Kleene-star repeat transitions.
  ///
  /// In en, this message translates to:
  /// **'Connect every former accepting state back to the cloned initial state with epsilon.'**
  String get fsaKleeneStarRepeatExplanation;

  /// Explanation for an empty-language FSA Kleene-star repeat step.
  ///
  /// In en, this message translates to:
  /// **'The operand language is empty, so there are no accepting states to repeat.'**
  String get fsaKleeneStarRepeatEmptyExplanation;

  /// Explanation for adding FSA Kleene-star exit transitions.
  ///
  /// In en, this message translates to:
  /// **'Create a distinct accepting exit and connect every former accepting state to it with epsilon.'**
  String get fsaKleeneStarExitExplanation;

  /// Explanation for an empty-language FSA Kleene-star exit step.
  ///
  /// In en, this message translates to:
  /// **'The distinct accepting exit remains unreachable because the operand language is empty.'**
  String get fsaKleeneStarExitEmptyExplanation;

  /// Validation message for an empty FSA reversal operand.
  ///
  /// In en, this message translates to:
  /// **'The reversal operand must contain at least one state.'**
  String get fsaReversalEmptyOperand;

  /// Validation message for an FSA reversal operand without an initial state.
  ///
  /// In en, this message translates to:
  /// **'The reversal operand must have an initial state.'**
  String get fsaReversalMissingInitialState;

  /// Validation message for an initial state outside an FSA reversal operand state set.
  ///
  /// In en, this message translates to:
  /// **'The reversal operand has an initial state outside its state set.'**
  String get fsaReversalInitialStateOutsideSet;

  /// Validation message for an accepting state outside an FSA reversal operand state set.
  ///
  /// In en, this message translates to:
  /// **'The reversal operand has an accepting state outside its state set.'**
  String get fsaReversalAcceptingStateOutsideSet;

  /// Validation message for a non-FSA transition in an FSA reversal operand.
  ///
  /// In en, this message translates to:
  /// **'The reversal operand contains a non-FSA transition.'**
  String get fsaReversalNonFsaTransition;

  /// Validation message for an unknown transition endpoint in an FSA reversal operand.
  ///
  /// In en, this message translates to:
  /// **'The reversal operand contains a transition with an unknown endpoint.'**
  String get fsaReversalUnknownTransitionEndpoint;

  /// Validation message for an invalid transition in an FSA reversal operand.
  ///
  /// In en, this message translates to:
  /// **'The reversal operand contains an invalid transition: {transition}.'**
  String fsaReversalInvalidTransition(String transition);

  /// Analysis message for duplicate state IDs in an FSA reversal result.
  ///
  /// In en, this message translates to:
  /// **'The reversal result contains duplicate state IDs.'**
  String get fsaReversalDuplicateStateIds;

  /// Analysis message for duplicate transition IDs in an FSA reversal result.
  ///
  /// In en, this message translates to:
  /// **'The reversal result contains duplicate transition IDs.'**
  String get fsaReversalDuplicateTransitionIds;

  /// Analysis message for an invalid FSA reversal result.
  ///
  /// In en, this message translates to:
  /// **'The reversal result is not a valid finite automaton.'**
  String get fsaReversalInvalidResult;

  /// Safe fallback for an unexpected FSA reversal construction failure.
  ///
  /// In en, this message translates to:
  /// **'The reversal construction failed.'**
  String get fsaReversalInternalFailure;

  /// Title for the first FSA reversal construction step.
  ///
  /// In en, this message translates to:
  /// **'Clone and mirror the states'**
  String get fsaReversalCloneTitle;

  /// Title for the transition-reversal FSA construction step.
  ///
  /// In en, this message translates to:
  /// **'Reverse every transition'**
  String get fsaReversalReverseTitle;

  /// Title for the entry-state FSA reversal construction step.
  ///
  /// In en, this message translates to:
  /// **'Add the new entry'**
  String get fsaReversalEntryTitle;

  /// Title for the final FSA reversal construction step.
  ///
  /// In en, this message translates to:
  /// **'Set the reversed accepting state'**
  String get fsaReversalAcceptingTitle;

  /// Explanation for cloning and mirroring FSA reversal states.
  ///
  /// In en, this message translates to:
  /// **'Copy every state into a deterministic ID namespace and mirror the layout for the reversed flow.'**
  String get fsaReversalCloneExplanation;

  /// Explanation for reversing FSA transition directions.
  ///
  /// In en, this message translates to:
  /// **'Swap the source and target of every symbol and epsilon transition.'**
  String get fsaReversalReverseExplanation;

  /// Explanation for adding the FSA reversal entry state and edges.
  ///
  /// In en, this message translates to:
  /// **'Create a fresh initial state and connect it by epsilon to every former accepting state.'**
  String get fsaReversalEntryExplanation;

  /// Explanation for an FSA reversal operand without accepting states.
  ///
  /// In en, this message translates to:
  /// **'Create a fresh initial state. The operand has no accepting states, so it has no epsilon entry edges.'**
  String get fsaReversalEntryEmptyExplanation;

  /// Explanation for selecting the accepting state in FSA reversal.
  ///
  /// In en, this message translates to:
  /// **'Make the clone of the former initial state the sole accepting state.'**
  String get fsaReversalAcceptingExplanation;

  /// Label used for the left FSA operand in concatenation diagnostics and steps.
  ///
  /// In en, this message translates to:
  /// **'left operand'**
  String get fsaConcatenationLeftOperand;

  /// Label used for the right FSA operand in concatenation diagnostics and steps.
  ///
  /// In en, this message translates to:
  /// **'right operand'**
  String get fsaConcatenationRightOperand;

  /// Validation message for an empty FSA concatenation operand.
  ///
  /// In en, this message translates to:
  /// **'The {operand} must contain at least one state.'**
  String fsaConcatenationEmptyOperand(String operand);

  /// Validation message for an FSA concatenation operand without an initial state.
  ///
  /// In en, this message translates to:
  /// **'The {operand} must have an initial state.'**
  String fsaConcatenationMissingInitialState(String operand);

  /// Validation message for an initial state outside an FSA concatenation operand state set.
  ///
  /// In en, this message translates to:
  /// **'The {operand} has an initial state outside its state set.'**
  String fsaConcatenationInitialStateOutsideSet(String operand);

  /// Validation message for an accepting state outside an FSA concatenation operand state set.
  ///
  /// In en, this message translates to:
  /// **'The {operand} has an accepting state outside its state set.'**
  String fsaConcatenationAcceptingStateOutsideSet(String operand);

  /// Validation message for a non-FSA transition in an FSA concatenation operand.
  ///
  /// In en, this message translates to:
  /// **'The {operand} contains a non-FSA transition.'**
  String fsaConcatenationNonFsaTransition(String operand);

  /// Validation message for an unknown transition endpoint in an FSA concatenation operand.
  ///
  /// In en, this message translates to:
  /// **'The {operand} contains a transition with an unknown endpoint.'**
  String fsaConcatenationUnknownTransitionEndpoint(String operand);

  /// Validation message for an invalid transition in an FSA concatenation operand.
  ///
  /// In en, this message translates to:
  /// **'The {operand} contains an invalid transition: {transition}.'**
  String fsaConcatenationInvalidTransition(String operand, String transition);

  /// Analysis message for duplicate state IDs in an FSA concatenation result.
  ///
  /// In en, this message translates to:
  /// **'The concatenation result contains duplicate state IDs.'**
  String get fsaConcatenationDuplicateStateIds;

  /// Analysis message for duplicate transition IDs in an FSA concatenation result.
  ///
  /// In en, this message translates to:
  /// **'The concatenation result contains duplicate transition IDs.'**
  String get fsaConcatenationDuplicateTransitionIds;

  /// Analysis message for an invalid FSA concatenation result.
  ///
  /// In en, this message translates to:
  /// **'The concatenation result is not a valid finite automaton.'**
  String get fsaConcatenationInvalidResult;

  /// Safe fallback for an unexpected FSA concatenation construction failure.
  ///
  /// In en, this message translates to:
  /// **'The concatenation construction failed.'**
  String get fsaConcatenationInternalFailure;

  /// Title for an FSA concatenation operand-cloning step.
  ///
  /// In en, this message translates to:
  /// **'Clone the {operand}'**
  String fsaConcatenationCloneTitle(String operand);

  /// Title for the FSA concatenation bridge step.
  ///
  /// In en, this message translates to:
  /// **'Connect the operands'**
  String get fsaConcatenationConnectTitle;

  /// Explanation for cloning an FSA concatenation operand.
  ///
  /// In en, this message translates to:
  /// **'Copy every state from the {operand} into a separate ID namespace.'**
  String fsaConcatenationCloneExplanation(String operand);

  /// Explanation for connecting non-empty FSA concatenation operands.
  ///
  /// In en, this message translates to:
  /// **'Add one epsilon bridge from each former accepting state of the left operand to the initial state of the right operand.'**
  String get fsaConcatenationConnectExplanation;

  /// Explanation for an FSA concatenation with no bridge transitions.
  ///
  /// In en, this message translates to:
  /// **'The left language is empty, so no epsilon bridge is needed.'**
  String get fsaConcatenationConnectEmptyExplanation;

  /// Validation message for an empty FA-to-regex input.
  ///
  /// In en, this message translates to:
  /// **'The finite automaton must contain at least one state.'**
  String get faToRegexEmptyAutomaton;

  /// Validation message for an FA-to-regex input without an initial state.
  ///
  /// In en, this message translates to:
  /// **'The finite automaton must have an initial state.'**
  String get faToRegexMissingInitialState;

  /// Validation message for an initial state outside an FA-to-regex input state set.
  ///
  /// In en, this message translates to:
  /// **'The initial state must belong to the finite automaton\'s state set.'**
  String get faToRegexInitialStateOutsideSet;

  /// Validation message for an accepting state outside an FA-to-regex input state set.
  ///
  /// In en, this message translates to:
  /// **'Every accepting state must belong to the finite automaton\'s state set.'**
  String get faToRegexAcceptingStateOutsideSet;

  /// Analysis message when optional FA-to-regex simplification fails.
  ///
  /// In en, this message translates to:
  /// **'The regular-expression simplification step failed after conversion.'**
  String get faToRegexSimplificationFailed;

  /// Safe fallback for an unexpected FA-to-regex conversion failure.
  ///
  /// In en, this message translates to:
  /// **'The FA-to-regex conversion failed.'**
  String get faToRegexInternalFailure;

  /// Localized grammar type label used by CNF diagnostics.
  ///
  /// In en, this message translates to:
  /// **'regular'**
  String get grammarCnfTypeRegular;

  /// Localized grammar type label used by CNF diagnostics.
  ///
  /// In en, this message translates to:
  /// **'context-free'**
  String get grammarCnfTypeContextFree;

  /// Localized grammar type label used by CNF diagnostics.
  ///
  /// In en, this message translates to:
  /// **'context-sensitive'**
  String get grammarCnfTypeContextSensitive;

  /// Localized grammar type label used by CNF diagnostics.
  ///
  /// In en, this message translates to:
  /// **'unrestricted'**
  String get grammarCnfTypeUnrestricted;

  /// Warning shown when CNF conversion receives a grammar that is not context-free.
  ///
  /// In en, this message translates to:
  /// **'CNF conversion expects a context-free grammar; received grammar type {type}. The conversion will be attempted anyway.'**
  String grammarCnfGrammarNotCfg(String type);

  /// Error shown when CNF conversion cannot introduce a fresh start symbol.
  ///
  /// In en, this message translates to:
  /// **'Failed to introduce a new start symbol for CNF conversion because no fresh name was available.'**
  String get grammarCnfStartSymbolRenameFailed;

  /// Warning summarizing productions that do not satisfy strict CNF shape.
  ///
  /// In en, this message translates to:
  /// **'CNF conversion produced productions that are not strictly CNF-shaped: {violations}'**
  String grammarCnfNotStrictCnf(String violations);

  /// Error shown when bounded epsilon expansion during CNF conversion exceeds its configured limit.
  ///
  /// In en, this message translates to:
  /// **'Skipping epsilon expansion for production {production}: {nullablePositions} nullable positions would require {subsets} subsets, exceeding the limit of {limit}.'**
  String grammarCnfNullableSubsetLimitExceeded(
    String production,
    int nullablePositions,
    int subsets,
    int limit,
  );

  /// Warning shown when CNF conversion reaches its generated-symbol bound.
  ///
  /// In en, this message translates to:
  /// **'The CNF conversion reached its limit of {limit} generated non-terminals.'**
  String grammarCnfNewSymbolLimitReached(int limit);

  /// Title for the CNF step that introduces a fresh start symbol.
  ///
  /// In en, this message translates to:
  /// **'Introduce a new start symbol'**
  String get grammarCnfStartSymbolTitle;

  /// Rationale for introducing a fresh CNF start symbol.
  ///
  /// In en, this message translates to:
  /// **'A fresh start symbol keeps the start variable out of right-hand sides while preserving the language.'**
  String get grammarCnfStartSymbolRationale;

  /// Title for the CNF epsilon-production removal step.
  ///
  /// In en, this message translates to:
  /// **'Remove epsilon productions'**
  String get grammarCnfEpsilonTitle;

  /// Rationale for removing epsilon productions during CNF conversion.
  ///
  /// In en, this message translates to:
  /// **'Nullable productions are expanded and epsilon productions are removed, except where the language requires epsilon.'**
  String get grammarCnfEpsilonRationale;

  /// Title for the CNF unit-production removal step.
  ///
  /// In en, this message translates to:
  /// **'Remove unit productions'**
  String get grammarCnfUnitTitle;

  /// Rationale for removing unit productions during CNF conversion.
  ///
  /// In en, this message translates to:
  /// **'Unit-production chains are replaced with the productions they reach.'**
  String get grammarCnfUnitRationale;

  /// Title for the CNF useless-symbol removal step.
  ///
  /// In en, this message translates to:
  /// **'Remove useless symbols'**
  String get grammarCnfUselessTitle;

  /// Rationale for removing useless symbols during CNF conversion.
  ///
  /// In en, this message translates to:
  /// **'Unproductive and unreachable symbols are removed from the grammar.'**
  String get grammarCnfUselessRationale;

  /// Title for the CNF terminal replacement and binarization step.
  ///
  /// In en, this message translates to:
  /// **'Replace terminals and binarize'**
  String get grammarCnfBinarizeTitle;

  /// Rationale for terminal replacement and binarization during CNF conversion.
  ///
  /// In en, this message translates to:
  /// **'Terminals in long right-hand sides are isolated and productions are split into binary form.'**
  String get grammarCnfBinarizeRationale;

  /// Validation message for an empty PDA normalization input.
  ///
  /// In en, this message translates to:
  /// **'Cannot normalize an empty PDA.'**
  String get pdaNormalizationEmptyPda;

  /// Validation message for a PDA without an initial state during normalization.
  ///
  /// In en, this message translates to:
  /// **'The PDA must define an initial state before normalization.'**
  String get pdaNormalizationMissingInitialState;

  /// Validation message for a PDA initial state outside its state set.
  ///
  /// In en, this message translates to:
  /// **'The PDA initial state must belong to the PDA state set.'**
  String get pdaNormalizationInitialStateOutsideSet;

  /// Validation message for an initial stack symbol outside the PDA stack alphabet.
  ///
  /// In en, this message translates to:
  /// **'The initial stack symbol {symbol} must belong to the stack alphabet.'**
  String pdaNormalizationInitialStackSymbolOutsideAlphabet(String symbol);

  /// Validation message when PDA normalization requires an accepting state but none exists.
  ///
  /// In en, this message translates to:
  /// **'The selected source mode requires at least one accepting state.'**
  String get pdaNormalizationMissingAcceptingState;

  /// Validation message for a PDA accepting state outside its state set.
  ///
  /// In en, this message translates to:
  /// **'Every accepting state must belong to the PDA state set.'**
  String get pdaNormalizationAcceptingStateOutsideSet;

  /// Validation message for a transition that is not a PDA transition.
  ///
  /// In en, this message translates to:
  /// **'PDA normalization only supports PDA transitions.'**
  String get pdaNormalizationNonPdaTransition;

  /// Validation message for a PDA transition endpoint outside the state set.
  ///
  /// In en, this message translates to:
  /// **'Transition {transition} references a state outside the PDA.'**
  String pdaNormalizationTransitionEndpointOutsideSet(String transition);

  /// Validation message for a PDA transition pop symbol outside the stack alphabet.
  ///
  /// In en, this message translates to:
  /// **'Transition {transition} pops stack symbol {symbol}, which is outside the stack alphabet.'**
  String pdaNormalizationTransitionPopSymbolOutsideAlphabet(
    String transition,
    String symbol,
  );

  /// Validation message for a PDA transition push symbol outside the stack alphabet.
  ///
  /// In en, this message translates to:
  /// **'Transition {transition} pushes stack symbol {symbol}, which is outside the stack alphabet.'**
  String pdaNormalizationTransitionPushSymbolOutsideAlphabet(
    String transition,
    String symbol,
  );

  /// Warning summarizing the states and transitions generated during PDA normalization.
  ///
  /// In en, this message translates to:
  /// **'Normalization may increase the state and transition count. It generated {states, plural, =0{no states} =1{one state} other{{states} states}} and {transitions, plural, =0{no transitions} =1{one transition} other{{transitions} transitions}}.'**
  String pdaNormalizationGrowthWarningSummary(int states, int transitions);

  /// Warning shown when PDA normalization introduces nondeterminism.
  ///
  /// In en, this message translates to:
  /// **'The conversion changed a deterministic source into a non-deterministic PDA.'**
  String get pdaNormalizationIntroducedNondeterminism;

  /// Provenance description for the generated PDA initial state.
  ///
  /// In en, this message translates to:
  /// **'Fresh initial state that installs the bottom marker from source state {state}.'**
  String pdaNormalizationInitialStateDescription(String state);

  /// Provenance description for the generated PDA acceptance state.
  ///
  /// In en, this message translates to:
  /// **'State reached after the simulated source stack empties.'**
  String get pdaNormalizationAcceptanceStateDescription;

  /// Provenance description for the generated PDA drain state.
  ///
  /// In en, this message translates to:
  /// **'State that drains residual stack content after acceptance.'**
  String get pdaNormalizationDrainStateDescription;

  /// Provenance description for the generated PDA initialization transition.
  ///
  /// In en, this message translates to:
  /// **'Installs the source initial stack above the bottom marker before entering state {state}.'**
  String pdaNormalizationInitializeTransitionDescription(String state);

  /// Provenance description for a generated single-pop PDA transition.
  ///
  /// In en, this message translates to:
  /// **'Single-pop expansion of source transition {transition}.'**
  String pdaNormalizationSinglePopTransitionDescription(String transition);

  /// Provenance description for the generated empty-stack acceptance transition.
  ///
  /// In en, this message translates to:
  /// **'Converts an empty source stack from state {state} to {mode} acceptance.'**
  String pdaNormalizationAcceptEmptyTransitionDescription(
    String state,
    String mode,
  );

  /// Provenance description for the generated transition into the PDA drain state.
  ///
  /// In en, this message translates to:
  /// **'Starts draining the stack from accepting state {state}.'**
  String pdaNormalizationEnterDrainTransitionDescription(String state);

  /// Provenance description for the generated PDA drain transition.
  ///
  /// In en, this message translates to:
  /// **'Pops one residual stack symbol in the drain state.'**
  String get pdaNormalizationDrainTransitionDescription;

  /// Error shown when GNF conversion fails.
  ///
  /// In en, this message translates to:
  /// **'The grammar could not be converted to Greibach Normal Form.'**
  String get grammarGnfTransformFailed;

  /// Warning shown when a GNF conversion result fails the final shape check.
  ///
  /// In en, this message translates to:
  /// **'The conversion result does not satisfy Greibach Normal Form.'**
  String get grammarGnfNotGnf;

  /// Title for the GNF grammar transformation step.
  ///
  /// In en, this message translates to:
  /// **'Convert to Greibach Normal Form'**
  String get grammarGnfConvertTitle;

  /// Rationale for converting a grammar to Greibach Normal Form.
  ///
  /// In en, this message translates to:
  /// **'Each production is rewritten as A → aα: a terminal followed by zero or more non-terminals.'**
  String get grammarGnfConvertRationale;

  /// Validation message for an empty grammar passed to the grammar-to-PDA converter.
  ///
  /// In en, this message translates to:
  /// **'The grammar must contain at least one production.'**
  String get grammarToPdaEmptyGrammar;

  /// Validation message for a grammar without a start symbol during grammar-to-PDA conversion.
  ///
  /// In en, this message translates to:
  /// **'The grammar must have a start symbol.'**
  String get grammarToPdaMissingStartSymbol;

  /// Validation message naming an undeclared grammar start symbol.
  ///
  /// In en, this message translates to:
  /// **'Start symbol {symbol} must be declared as a non-terminal.'**
  String grammarToPdaUndeclaredStartSymbol(String symbol);

  /// Validation message naming a duplicate production identifier.
  ///
  /// In en, this message translates to:
  /// **'Production ID {production} is duplicated.'**
  String grammarToPdaDuplicateProductionId(String production);

  /// Validation message when grammar-to-PDA conversion requires a context-free grammar.
  ///
  /// In en, this message translates to:
  /// **'The grammar is not context-free.'**
  String get grammarToPdaNotContextFree;

  /// Message shown when grammar-to-PDA conversion reaches its time bound.
  ///
  /// In en, this message translates to:
  /// **'Grammar-to-PDA conversion timed out after {timeout} seconds.'**
  String grammarToPdaConversionTimedOut(int timeout);

  /// Safe fallback for an unexpected grammar-to-PDA conversion failure.
  ///
  /// In en, this message translates to:
  /// **'The grammar-to-PDA conversion failed.'**
  String get grammarToPdaInternalConversionFailure;

  /// Message shown when the GNF prerequisite for grammar-to-PDA conversion fails.
  ///
  /// In en, this message translates to:
  /// **'The grammar could not be converted to Greibach Normal Form for PDA construction.'**
  String get grammarToPdaGnfConversionFailed;

  /// Message shown when the GNF prerequisite produces an invalid grammar.
  ///
  /// In en, this message translates to:
  /// **'The Greibach conversion did not produce a valid GNF grammar.'**
  String get grammarToPdaInvalidGnfResult;

  /// Safe fallback for an unexpected grammar-to-PDA analysis failure.
  ///
  /// In en, this message translates to:
  /// **'The grammar-to-PDA conversion analysis failed.'**
  String get grammarToPdaAnalysisFailed;

  /// Message shown when grammar-to-PDA analysis reaches its time bound.
  ///
  /// In en, this message translates to:
  /// **'Grammar-to-PDA analysis timed out after {timeout} seconds.'**
  String grammarToPdaAnalysisTimedOut(int timeout);

  /// Analysis step label for grammar-to-PDA validation.
  ///
  /// In en, this message translates to:
  /// **'Validate the grammar'**
  String get grammarToPdaValidateGrammarStep;

  /// Analysis step label for creating the grammar-to-PDA initial state.
  ///
  /// In en, this message translates to:
  /// **'Create the initial state'**
  String get grammarToPdaCreateInitialStateStep;

  /// Analysis step label for creating the grammar-to-PDA processing state.
  ///
  /// In en, this message translates to:
  /// **'Create the processing state'**
  String get grammarToPdaCreateProcessingStateStep;

  /// Analysis step label for creating the grammar-to-PDA accepting state.
  ///
  /// In en, this message translates to:
  /// **'Create the accepting state'**
  String get grammarToPdaCreateAcceptingStateStep;

  /// Analysis step label for adding grammar-to-PDA transitions.
  ///
  /// In en, this message translates to:
  /// **'Add transitions'**
  String get grammarToPdaAddTransitionsStep;

  /// Validation message for an empty PDA passed to simplification.
  ///
  /// In en, this message translates to:
  /// **'Cannot simplify an empty PDA.'**
  String get pdaSimplificationEmptyPda;

  /// Validation message for a PDA without an initial state during simplification.
  ///
  /// In en, this message translates to:
  /// **'The PDA must define an initial state before simplification.'**
  String get pdaSimplificationMissingInitialState;

  /// Validation message for a PDA initial state outside its state set during simplification.
  ///
  /// In en, this message translates to:
  /// **'The PDA initial state must belong to the PDA state set.'**
  String get pdaSimplificationInitialStateOutsideSet;

  /// Validation message for a PDA accepting state outside its state set during simplification.
  ///
  /// In en, this message translates to:
  /// **'Every accepting state must belong to the PDA state set.'**
  String get pdaSimplificationAcceptingStateOutsideSet;

  /// Validation message when the selected PDA acceptance mode requires an accepting state.
  ///
  /// In en, this message translates to:
  /// **'Acceptance mode {mode} requires at least one accepting state.'**
  String pdaSimplificationMissingAcceptingState(String mode);

  /// Validation message for a PDA that fails model validation before simplification.
  ///
  /// In en, this message translates to:
  /// **'The PDA is not valid for simplification.'**
  String get pdaSimplificationInvalidPda;

  /// Validation message for a transition that is not a PDA transition.
  ///
  /// In en, this message translates to:
  /// **'PDA simplification only supports PDA transitions.'**
  String get pdaSimplificationNonPdaTransition;

  /// Validation message for a PDA transition endpoint outside its state set.
  ///
  /// In en, this message translates to:
  /// **'Transition {transition} references a state outside the PDA.'**
  String pdaSimplificationTransitionEndpointOutsideSet(String transition);

  /// Validation message naming an invalid PDA transition.
  ///
  /// In en, this message translates to:
  /// **'Transition {transition} is not valid for PDA simplification.'**
  String pdaSimplificationInvalidTransition(String transition);

  /// Validation message for an empty input-alphabet symbol.
  ///
  /// In en, this message translates to:
  /// **'The PDA input alphabet cannot contain an empty symbol.'**
  String get pdaSimplificationInputAlphabetEmptySymbol;

  /// Validation message for an empty stack-alphabet symbol.
  ///
  /// In en, this message translates to:
  /// **'The PDA stack alphabet cannot contain an empty symbol.'**
  String get pdaSimplificationStackAlphabetEmptySymbol;

  /// Validation message for a PDA transition input symbol outside the input alphabet.
  ///
  /// In en, this message translates to:
  /// **'Transition {transition} reads input symbol {symbol}, which is outside the input alphabet.'**
  String pdaSimplificationTransitionInputSymbolOutsideAlphabet(
    String transition,
    String symbol,
  );

  /// Validation message naming duplicate PDA transition IDs.
  ///
  /// In en, this message translates to:
  /// **'Transition ID {transition} is duplicated.'**
  String pdaSimplificationDuplicateTransitionIds(String transition);

  /// Validation message for a negative bounded-comparison length.
  ///
  /// In en, this message translates to:
  /// **'The bounded comparison length cannot be negative.'**
  String get pdaSimplificationBoundedLengthNegative;

  /// Validation message for an empty symbol in the bounded-comparison alphabet.
  ///
  /// In en, this message translates to:
  /// **'The bounded comparison alphabet cannot contain an empty symbol.'**
  String get pdaSimplificationBoundedSymbolsEmpty;

  /// Validation message for a bounded-comparison symbol outside the PDA alphabet.
  ///
  /// In en, this message translates to:
  /// **'Bounded comparison symbol {symbol} is outside the PDA input alphabet.'**
  String pdaSimplificationBoundedSymbolOutsideAlphabet(String symbol);

  /// Phase label for completed PDA simplification validation.
  ///
  /// In en, this message translates to:
  /// **'PDA validation completed.'**
  String get pdaSimplificationValidationComplete;

  /// Phase label when no unreachable PDA states are found.
  ///
  /// In en, this message translates to:
  /// **'Every PDA state is structurally reachable.'**
  String get pdaSimplificationEveryStateReachable;

  /// Phase summary for states removed by structural reachability.
  ///
  /// In en, this message translates to:
  /// **'Removed {count, plural, =1{one unreachable state} other{{count} unreachable states}}.'**
  String pdaSimplificationRemovedUnreachableStates(int count);

  /// Warning explaining why semantic usefulness pruning was skipped.
  ///
  /// In en, this message translates to:
  /// **'Exact semantic usefulness is unavailable for general NPDAs; uncertain states were retained.'**
  String get pdaSimplificationSemanticUsefulnessUnavailable;

  /// Phase label when semantic usefulness analysis is disabled.
  ///
  /// In en, this message translates to:
  /// **'Semantic usefulness analysis was disabled.'**
  String get pdaSimplificationSemanticUsefulnessDisabled;

  /// Phase label for completed strong-bisimulation analysis.
  ///
  /// In en, this message translates to:
  /// **'Strong bisimulation groups were computed.'**
  String get pdaSimplificationStrongBisimulationComputed;

  /// Phase label when strong-bisimulation analysis is disabled.
  ///
  /// In en, this message translates to:
  /// **'Strong bisimulation analysis was disabled.'**
  String get pdaSimplificationStrongBisimulationDisabled;

  /// Phase label for successful validation of the simplified PDA.
  ///
  /// In en, this message translates to:
  /// **'The rebuilt PDA passed validation.'**
  String get pdaSimplificationRebuildValidationComplete;

  /// Phase summary for a successful finite PDA comparison sample.
  ///
  /// In en, this message translates to:
  /// **'The bounded comparison checked {count, plural, =1{one word} other{{count} words}} successfully.'**
  String pdaSimplificationBoundedSamplePassed(int count);

  /// Phase label when bounded language comparison is disabled.
  ///
  /// In en, this message translates to:
  /// **'Bounded language comparison was disabled.'**
  String get pdaSimplificationBoundedComparisonDisabled;

  /// Analysis message when the simplified PDA fails post-rebuild validation.
  ///
  /// In en, this message translates to:
  /// **'The rebuilt PDA failed validation.'**
  String get pdaSimplificationInvalidRebuiltPda;

  /// Message for a bounded PDA comparison that could not complete because a simulation failed.
  ///
  /// In en, this message translates to:
  /// **'The bounded comparison was inconclusive for input word {word}.'**
  String pdaSimplificationBoundedComparisonInconclusive(String word);

  /// Message for a bounded PDA comparison that reaches a simulation limit.
  ///
  /// In en, this message translates to:
  /// **'The bounded comparison reached a simulation limit for input word {word}; the result is inconclusive.'**
  String pdaSimplificationBoundedComparisonSimulationLimit(String word);

  /// Message for a bounded PDA comparison that finds an acceptance mismatch.
  ///
  /// In en, this message translates to:
  /// **'The original and simplified PDAs disagree on input word {word}.'**
  String pdaSimplificationBoundedComparisonAcceptanceMismatch(String word);

  /// Validation message for an empty FSA passed to grammar conversion.
  ///
  /// In en, this message translates to:
  /// **'The automaton must contain at least one state.'**
  String get fsaToGrammarEmptyAutomaton;

  /// Validation message for an FSA without an initial state during grammar conversion.
  ///
  /// In en, this message translates to:
  /// **'The automaton must have an initial state.'**
  String get fsaToGrammarMissingInitialState;

  /// Validation message for an FSA initial state outside its state set.
  ///
  /// In en, this message translates to:
  /// **'The initial state must belong to the automaton.'**
  String get fsaToGrammarInitialStateOutsideSet;

  /// Validation message for an FSA accepting state outside its state set.
  ///
  /// In en, this message translates to:
  /// **'Every accepting state must belong to the automaton.'**
  String get fsaToGrammarAcceptingStateOutsideSet;

  /// Validation message for grammar-to-FSA conversion without non-terminals.
  ///
  /// In en, this message translates to:
  /// **'The grammar must declare at least one non-terminal.'**
  String get grammarToFsaMissingNonterminals;

  /// Validation message for a grammar start symbol outside its non-terminal set.
  ///
  /// In en, this message translates to:
  /// **'The start symbol must be a declared non-terminal.'**
  String get grammarToFsaUndeclaredStartSymbol;

  /// Validation message for a production with an invalid left side.
  ///
  /// In en, this message translates to:
  /// **'Production {production} must have exactly one non-terminal on the left side.'**
  String grammarToFsaLeftSideNotSingle(String production);

  /// Validation message for an unknown non-terminal on a production left side.
  ///
  /// In en, this message translates to:
  /// **'Production {production} uses unknown non-terminal {symbol}.'**
  String grammarToFsaUnknownLeftNonterminal(String production, String symbol);

  /// Validation message for an undefined non-terminal referenced on a production right side.
  ///
  /// In en, this message translates to:
  /// **'Production {production} references undefined non-terminal {symbol}.'**
  String grammarToFsaUnknownRightNonterminal(String production, String symbol);

  /// Validation message for a production with more than two right-side symbols.
  ///
  /// In en, this message translates to:
  /// **'Production {production} is not right-linear because its right side has too many symbols.'**
  String grammarToFsaTooManyRightSymbols(String production);

  /// Validation message for a right-linear production without a terminal first symbol.
  ///
  /// In en, this message translates to:
  /// **'Production {production} must start with a terminal symbol.'**
  String grammarToFsaFirstSymbolNotTerminal(String production);

  /// Validation message for a two-symbol production without a non-terminal tail.
  ///
  /// In en, this message translates to:
  /// **'Production {production} must end with a non-terminal symbol.'**
  String grammarToFsaLastSymbolNotNonterminal(String production);

  /// Validation message when a DFA operation operand lacks an initial state.
  ///
  /// In en, this message translates to:
  /// **'The {context, select, dfa {DFA} complementDfa {DFA for complement} prefixClosure {DFA for prefix closure} suffixClosure {DFA for suffix closure} operandA {operand A} operandB {operand B} other {DFA}} must have a defined initial state.'**
  String dfaOperationsMissingInitialState(String context);

  /// Validation message when a DFA operation receives nondeterministic input.
  ///
  /// In en, this message translates to:
  /// **'The {context, select, dfa {DFA} complementDfa {DFA for complement} prefixClosure {DFA for prefix closure} suffixClosure {DFA for suffix closure} operandA {operand A} operandB {operand B} other {DFA}} must be deterministic (no nondeterministic transitions).'**
  String dfaOperationsNondeterministic(String context);

  /// Validation message when epsilon transitions are not supported by a DFA operation.
  ///
  /// In en, this message translates to:
  /// **'The {context, select, dfa {DFA} complementDfa {DFA for complement} prefixClosure {DFA for prefix closure} suffixClosure {DFA for suffix closure} operandA {operand A} operandB {operand B} other {DFA}} cannot contain ε (epsilon) transitions.'**
  String dfaOperationsEpsilonTransitionsNotAllowed(String context);

  /// Validation message when a transition symbol is absent from a DFA operation alphabet.
  ///
  /// In en, this message translates to:
  /// **'The {context, select, dfa {DFA} complementDfa {DFA for complement} prefixClosure {DFA for prefix closure} suffixClosure {DFA for suffix closure} operandA {operand A} operandB {operand B} other {DFA}} has a transition with a symbol outside the alphabet: \"{symbol}\".'**
  String dfaOperationsSymbolOutsideAlphabet(String context, String symbol);

  /// Validation message for a DFA operand with labeled transitions and an empty alphabet.
  ///
  /// In en, this message translates to:
  /// **'{operand, select, a {Operand A} b {Operand B} other {The operand}} has labeled transitions, but the alphabet is empty.'**
  String dfaOperationsEmptyAlphabetWithLabeledTransitions(String operand);

  /// Validation message when a binary DFA operation lacks an initial state on an operand.
  ///
  /// In en, this message translates to:
  /// **'Both DFAs must have a defined initial state.'**
  String get dfaOperationsBothOperandsMissingInitialState;

  /// Fallback analysis message when a DFA operation throws.
  ///
  /// In en, this message translates to:
  /// **'Error computing the DFA {operation, select, union {union} intersection {intersection} difference {difference} complement {complement} prefixClosure {prefix closure} suffixClosure {suffix closure} removeLambda {epsilon-transition removal} other {operation}}.'**
  String dfaOperationsOperationFailed(String operation);

  /// Analysis message when epsilon-transition removal fails.
  ///
  /// In en, this message translates to:
  /// **'Error removing ε-transitions.'**
  String get dfaOperationsEpsilonRemovalFailed;

  /// Validation message when DFA minimization receives no states.
  ///
  /// In en, this message translates to:
  /// **'Cannot minimize an empty DFA.'**
  String get dfaMinimizationEmptyDfa;

  /// Validation message when the DFA to minimize has no initial state.
  ///
  /// In en, this message translates to:
  /// **'The DFA must have an initial state.'**
  String get dfaMinimizationMissingInitialState;

  /// Validation message when the initial state is outside the DFA state set.
  ///
  /// In en, this message translates to:
  /// **'The initial state must belong to the DFA state set.'**
  String get dfaMinimizationInitialStateOutsideSet;

  /// Validation message when an accepting state is outside the DFA state set.
  ///
  /// In en, this message translates to:
  /// **'Every accepting state must belong to the DFA state set.'**
  String get dfaMinimizationAcceptingStateOutsideSet;

  /// Validation message when minimization receives a nondeterministic automaton.
  ///
  /// In en, this message translates to:
  /// **'Input must be a deterministic automaton.'**
  String get dfaMinimizationNondeterministicInput;

  /// Analysis message when DFA minimization fails.
  ///
  /// In en, this message translates to:
  /// **'Error minimizing the DFA.'**
  String get dfaMinimizationFailed;

  /// Analysis message when stepped DFA minimization fails.
  ///
  /// In en, this message translates to:
  /// **'Error minimizing the DFA with steps.'**
  String get dfaMinimizationWithStepsFailed;

  /// Transformation message when CFG reduction fails.
  ///
  /// In en, this message translates to:
  /// **'CFG reduction failed.'**
  String get cfgToolkitReduceFailed;

  /// Transformation message when CFG to CNF conversion fails.
  ///
  /// In en, this message translates to:
  /// **'CFG to CNF conversion failed.'**
  String get cfgToolkitToCnfFailed;

  /// Transformation message when CFG to GNF conversion fails.
  ///
  /// In en, this message translates to:
  /// **'CFG to GNF conversion failed.'**
  String get cfgToolkitToGnfFailed;

  /// Parsing message when CYK reaches its timeout.
  ///
  /// In en, this message translates to:
  /// **'CYK parsing timed out.'**
  String get cykTimedOut;

  /// Parsing message when CYK rejects an input string.
  ///
  /// In en, this message translates to:
  /// **'The input string {input} cannot be derived from the grammar.'**
  String cykInputRejected(String input);

  /// Analysis message when CYK parsing fails unexpectedly.
  ///
  /// In en, this message translates to:
  /// **'CYK parsing failed.'**
  String get cykParseFailed;

  /// Validation message for a parser invoked with an empty grammar.
  ///
  /// In en, this message translates to:
  /// **'The grammar must contain at least one production.'**
  String get grammarParserEmptyGrammar;

  /// Validation message for a grammar without a start symbol.
  ///
  /// In en, this message translates to:
  /// **'The grammar must have a start symbol.'**
  String get grammarParserMissingStartSymbol;

  /// Validation message when a grammar start symbol is not a non-terminal.
  ///
  /// In en, this message translates to:
  /// **'The start symbol must be a non-terminal.'**
  String get grammarParserStartSymbolNotNonterminal;

  /// Parsing message when a grammar parser rejects input.
  ///
  /// In en, this message translates to:
  /// **'The input string {input} cannot be derived from the grammar.'**
  String grammarParserInputRejected(String input);

  /// Parsing message when every selected grammar parser strategy fails.
  ///
  /// In en, this message translates to:
  /// **'All {strategy, select, auto {available} bruteForce {brute-force} cyk {CYK} ll {LL(1)} lr {LR(1)} other {available}} parsing strategies failed.'**
  String grammarParserAllStrategiesFailed(String strategy);

  /// Analysis message when generated grammar strings cannot be produced.
  ///
  /// In en, this message translates to:
  /// **'Generating grammar strings failed.'**
  String get grammarParserGeneratedStringsFailed;

  /// Validation message for a non-positive LL(1) step limit.
  ///
  /// In en, this message translates to:
  /// **'The LL(1) step limit must be greater than zero (received {limit}).'**
  String grammarParserLl1StepLimitInvalid(int limit);

  /// Warning describing an LL(1) parsing-table conflict.
  ///
  /// In en, this message translates to:
  /// **'LL(1) conflict for non-terminal {nonTerminal} with lookahead {lookahead}: {alternatives}.'**
  String grammarParserLl1Conflict(
    String nonTerminal,
    String lookahead,
    String alternatives,
  );

  /// Parsing message when LL(1) parsing is cancelled.
  ///
  /// In en, this message translates to:
  /// **'LL(1) parsing was cancelled.'**
  String get grammarParserLl1Cancelled;

  /// Warning when LL(1) parsing reaches its timeout.
  ///
  /// In en, this message translates to:
  /// **'LL(1) parsing timed out after {timeout} ms.'**
  String grammarParserLl1TimedOut(int timeout);

  /// Warning when LL(1) parsing reaches its step limit.
  ///
  /// In en, this message translates to:
  /// **'LL(1) parsing reached its step limit of {limit}.'**
  String grammarParserLl1StepLimitReached(int limit);

  /// Parsing message for input left after an LL(1) parse.
  ///
  /// In en, this message translates to:
  /// **'Unexpected trailing input symbol {lookahead} at position {position}.'**
  String grammarParserLl1TrailingInput(String lookahead, int position);

  /// Parsing message for an unexpected LL(1) input end.
  ///
  /// In en, this message translates to:
  /// **'Unexpected end of input; expected {expected}.'**
  String grammarParserLl1UnexpectedEnd(String expected);

  /// Parsing message for an LL(1) terminal mismatch.
  ///
  /// In en, this message translates to:
  /// **'Expected {expected} at position {position}, but found {found}.'**
  String grammarParserLl1TerminalMismatch(
    String expected,
    String found,
    int position,
  );

  /// Parsing message for an empty LL(1) table cell.
  ///
  /// In en, this message translates to:
  /// **'The LL(1) table has no entry for {nonTerminal} with lookahead {lookahead}; expected {expected}.'**
  String grammarParserLl1EmptyTableCell(
    String nonTerminal,
    String lookahead,
    String expected,
  );

  /// Warning when the LL(1) parser stack empties unexpectedly.
  ///
  /// In en, this message translates to:
  /// **'The LL(1) parser stack became empty before parsing completed.'**
  String get grammarParserLl1EmptyStack;

  /// Validation message for an Earley-incompatible production.
  ///
  /// In en, this message translates to:
  /// **'The grammar contains a production malformed for Earley parsing.'**
  String get grammarParserEarleyMalformedProduction;

  /// Validation message for an Earley grammar without a declared start symbol.
  ///
  /// In en, this message translates to:
  /// **'Earley parsing requires a declared non-terminal start symbol.'**
  String get grammarParserEarleyMissingStartSymbol;

  /// Warning when Earley parsing reaches its timeout.
  ///
  /// In en, this message translates to:
  /// **'Earley parsing timed out after {timeout} ms.'**
  String grammarParserEarleyTimedOut(int timeout);

  /// Parsing message when recursive-descent parsing reaches its timeout.
  ///
  /// In en, this message translates to:
  /// **'Recursive-descent parsing timed out.'**
  String get grammarParserRecursiveDescentTimedOut;

  /// Analysis message when recursive-descent parsing fails unexpectedly.
  ///
  /// In en, this message translates to:
  /// **'Recursive-descent parsing failed.'**
  String get grammarParserRecursiveDescentFailed;

  /// Analysis message when an LR(1) parse uses an outdated construction.
  ///
  /// In en, this message translates to:
  /// **'The LR(1) construction is stale; rebuild the parsing table.'**
  String get lr1ParserStaleConstruction;

  /// Validation message for an LR(1)-incompatible grammar.
  ///
  /// In en, this message translates to:
  /// **'The grammar is invalid for LR(1) parsing.'**
  String get lr1ParserInvalidGrammar;

  /// Validation message for LR(1) construction without a start symbol.
  ///
  /// In en, this message translates to:
  /// **'The grammar must have a start symbol for LR(1) parsing.'**
  String get lr1ParserMissingStartSymbol;

  /// Validation message for a malformed LR(1) production.
  ///
  /// In en, this message translates to:
  /// **'The grammar contains a malformed production for LR(1) parsing.'**
  String get lr1ParserMalformedProduction;

  /// Validation message for a duplicate LR(1) production identifier.
  ///
  /// In en, this message translates to:
  /// **'Production {production} has a duplicate identifier.'**
  String lr1ParserDuplicateProductionId(String production);

  /// Validation message for an undeclared symbol in an LR(1) production.
  ///
  /// In en, this message translates to:
  /// **'Production {production} uses undeclared symbol {symbol}.'**
  String lr1ParserUndeclaredSymbol(String production, String symbol);

  /// Warning when LR(1) table construction is cancelled.
  ///
  /// In en, this message translates to:
  /// **'LR(1) table construction was cancelled.'**
  String get lr1ParserConstructionCancelled;

  /// Warning when LR(1) table construction reaches its timeout.
  ///
  /// In en, this message translates to:
  /// **'LR(1) table construction timed out after {timeout} ms.'**
  String lr1ParserConstructionTimedOut(int timeout);

  /// Warning when LR(1) table construction reaches its state limit.
  ///
  /// In en, this message translates to:
  /// **'LR(1) table construction reached its state limit.'**
  String get lr1ParserConstructionStateLimit;

  /// Warning when LR(1) table construction reaches its item limit.
  ///
  /// In en, this message translates to:
  /// **'LR(1) table construction reached its item limit.'**
  String get lr1ParserConstructionItemLimit;

  /// Warning describing an LR(1) table conflict.
  ///
  /// In en, this message translates to:
  /// **'LR(1) conflict in state {state} with lookahead {lookahead}.'**
  String lr1ParserConflict(String state, String lookahead);

  /// Parsing message when LR(1) parsing is cancelled.
  ///
  /// In en, this message translates to:
  /// **'LR(1) parsing was cancelled.'**
  String get lr1ParserCancelled;

  /// Warning when LR(1) parsing reaches its timeout.
  ///
  /// In en, this message translates to:
  /// **'LR(1) parsing timed out after {timeout} ms.'**
  String lr1ParserTimedOut(int timeout);

  /// Warning when LR(1) parsing reaches its step limit.
  ///
  /// In en, this message translates to:
  /// **'LR(1) parsing reached its step limit of {limit}.'**
  String lr1ParserStepLimitReached(int limit);

  /// Parsing message for an empty LR(1) action-table cell.
  ///
  /// In en, this message translates to:
  /// **'No LR(1) action exists for state {state} with lookahead {lookahead}.'**
  String lr1ParserEmptyActionCell(String state, String lookahead);

  /// Warning describing an LR(1) action conflict.
  ///
  /// In en, this message translates to:
  /// **'Multiple LR(1) actions conflict in state {state} with lookahead {lookahead}.'**
  String lr1ParserActionConflict(String state, String lookahead);

  /// Analysis message for an invalid LR(1) parser state.
  ///
  /// In en, this message translates to:
  /// **'The LR(1) parser state is invalid.'**
  String get lr1ParserInvalidParserState;

  /// Analysis message for a missing LR(1) goto entry.
  ///
  /// In en, this message translates to:
  /// **'No LR(1) goto entry exists for state {state} and non-terminal {nonTerminal}.'**
  String lr1ParserMissingGoto(String state, String nonTerminal);

  /// Informational LR(1) parsing step for a shift.
  ///
  /// In en, this message translates to:
  /// **'Shift {symbol} and enter parser state {targetState}.'**
  String lr1ParserShifted(String symbol, String targetState);

  /// Informational LR(1) parsing step for a reduction.
  ///
  /// In en, this message translates to:
  /// **'Reduce by {production}: {leftSide} → {rightSide}.'**
  String lr1ParserReduced(String production, String leftSide, String rightSide);

  /// Informational LR(1) parsing step for acceptance.
  ///
  /// In en, this message translates to:
  /// **'The LR(1) parser accepted the input.'**
  String get lr1ParserAccepted;

  /// Validation message when TM simulation receives no states.
  ///
  /// In en, this message translates to:
  /// **'Cannot simulate an empty Turing machine.'**
  String get tmSimulationEmptyMachine;

  /// Validation message when TM simulation has no initial state.
  ///
  /// In en, this message translates to:
  /// **'The Turing machine must have an initial state.'**
  String get tmSimulationMissingInitialState;

  /// Validation message when a TM initial state is outside its state set.
  ///
  /// In en, this message translates to:
  /// **'The initial state must belong to the Turing machine.'**
  String get tmSimulationInitialStateOutsideSet;

  /// Validation message when a TM accepting state is outside its state set.
  ///
  /// In en, this message translates to:
  /// **'Every accepting state must belong to the Turing machine.'**
  String get tmSimulationAcceptingStateOutsideSet;

  /// Validation message for a TM input symbol outside the alphabet.
  ///
  /// In en, this message translates to:
  /// **'The input contains a symbol outside the Turing machine alphabet: {symbol}.'**
  String tmSimulationInvalidInputSymbol(String symbol);

  /// Validation message for a non-positive TM operations-per-batch limit.
  ///
  /// In en, this message translates to:
  /// **'Operations per batch must be greater than zero.'**
  String get tmSimulationOperationsPerBatchInvalid;

  /// Simulation message describing conflicting TM transitions.
  ///
  /// In en, this message translates to:
  /// **'The machine has {count} transitions for state {state} on symbol {symbol}.'**
  String tmSimulationNondeterministicConflict(
    int count,
    String state,
    String symbol,
  );

  /// Simulation outcome when no NTM branch accepts.
  ///
  /// In en, this message translates to:
  /// **'No accepting configuration was found.'**
  String get tmSimulationRejectedNoAcceptingConfiguration;

  /// Simulation outcome for a rejected input.
  ///
  /// In en, this message translates to:
  /// **'The input was not accepted.'**
  String get tmSimulationInputNotAccepted;

  /// Warning when a TM simulation reaches its timeout.
  ///
  /// In en, this message translates to:
  /// **'The Turing machine simulation timed out.'**
  String get tmSimulationTimeout;

  /// Warning when TM simulation detects a repeated configuration.
  ///
  /// In en, this message translates to:
  /// **'An infinite loop was detected.'**
  String get tmSimulationInfiniteLoop;

  /// Warning when TM simulation reaches its step limit.
  ///
  /// In en, this message translates to:
  /// **'Step limit reached; the result is inconclusive'**
  String get tmSimulationStepLimit;

  /// Warning when TM simulation reaches its configuration limit.
  ///
  /// In en, this message translates to:
  /// **'Configuration limit reached; the result is inconclusive'**
  String get tmSimulationConfigurationLimit;

  /// Failure detail for deterministic TM simulation.
  ///
  /// In en, this message translates to:
  /// **'DTM simulation failed: {error}'**
  String tmSimulationDtmFailure(String error);

  /// Failure detail for nondeterministic TM simulation.
  ///
  /// In en, this message translates to:
  /// **'NTM simulation failed: {error}'**
  String tmSimulationNtmFailure(String error);

  /// Failure detail for generic TM simulation.
  ///
  /// In en, this message translates to:
  /// **'Turing machine simulation failed: {error}'**
  String tmSimulationGenericFailure(String error);

  /// Failure detail when accepted-string enumeration fails.
  ///
  /// In en, this message translates to:
  /// **'Finding accepted strings failed: {error}'**
  String tmSimulationAcceptedStringsFailure(String error);

  /// Failure detail when rejected-string enumeration fails.
  ///
  /// In en, this message translates to:
  /// **'Finding rejected strings failed: {error}'**
  String tmSimulationRejectedStringsFailure(String error);

  /// Failure detail for generic TM analysis.
  ///
  /// In en, this message translates to:
  /// **'Turing machine analysis failed: {error}'**
  String tmSimulationAnalysisFailure(String error);

  /// Title for a TM transition trace explanation.
  ///
  /// In en, this message translates to:
  /// **'Turing machine transition'**
  String get tmSimulationTransitionTitle;

  /// Trace explanation for reading a TM tape symbol.
  ///
  /// In en, this message translates to:
  /// **'Read {symbol} at tape position {position} in state {state}.'**
  String tmSimulationReadSymbol(String symbol, int position, String state);

  /// Trace explanation for applying a TM transition rule.
  ///
  /// In en, this message translates to:
  /// **'Applied rule: {fromState},{readSymbol} → {toState},{writeSymbol},{direction, select, L {left} R {right} S {stay} other {{direction}}}.'**
  String tmSimulationAppliedRule(
    String fromState,
    String readSymbol,
    String toState,
    String writeSymbol,
    String direction,
  );

  /// Trace explanation for writing a TM tape symbol.
  ///
  /// In en, this message translates to:
  /// **'Wrote {symbol} at tape position {position}.'**
  String tmSimulationWroteSymbol(String symbol, int position);

  /// Trace explanation for moving a TM tape head.
  ///
  /// In en, this message translates to:
  /// **'Moved the head {direction, select, L {left} R {right} S {stay} other {{direction}}} to position {position}.'**
  String tmSimulationMovedHead(String direction, int position);

  /// Validation message for bounded TM execution with no states.
  ///
  /// In en, this message translates to:
  /// **'The Turing machine must have at least one state.'**
  String get tmExecutionEmptyMachine;

  /// Validation message for bounded TM execution without a valid initial state.
  ///
  /// In en, this message translates to:
  /// **'The Turing machine must define a valid initial state.'**
  String get tmExecutionMissingInitialState;

  /// Validation message for a non-positive TM step limit.
  ///
  /// In en, this message translates to:
  /// **'The step limit must be greater than zero.'**
  String get tmExecutionStepLimitInvalid;

  /// Validation message for a non-positive TM configuration limit.
  ///
  /// In en, this message translates to:
  /// **'The configuration limit must be greater than zero.'**
  String get tmExecutionConfigurationLimitInvalid;

  /// Validation message for a non-positive TM timeout.
  ///
  /// In en, this message translates to:
  /// **'The timeout must be greater than zero.'**
  String get tmExecutionTimeoutInvalid;

  /// Validation message for a non-positive TM operations-per-batch limit.
  ///
  /// In en, this message translates to:
  /// **'Operations per batch must be greater than zero.'**
  String get tmExecutionOperationsPerBatchInvalid;

  /// Validation message for a TM execution input symbol outside the alphabet.
  ///
  /// In en, this message translates to:
  /// **'The input contains a symbol outside the Turing machine alphabet: {symbol}.'**
  String tmExecutionInvalidInputSymbol(String symbol);

  /// Validation message for an invalid TM discovered during execution analysis.
  ///
  /// In en, this message translates to:
  /// **'The Turing machine is invalid: {detail}'**
  String tmExecutionInvalidMachine(String detail);

  /// Analysis outcome when bounded TM execution is cancelled.
  ///
  /// In en, this message translates to:
  /// **'TM execution analysis was cancelled.'**
  String get tmExecutionCancelled;

  /// Warning when bounded TM execution times out before an outcome.
  ///
  /// In en, this message translates to:
  /// **'The timeout was reached before execution was resolved.'**
  String get tmExecutionTimeoutBeforeResolution;

  /// Analysis outcome when a TM enters a final state.
  ///
  /// In en, this message translates to:
  /// **'The machine entered a final state under the {policy, select, finalState {final-state} halting {halting} finalStateOrHalting {final-state-or-halting} other {selected}} policy.'**
  String tmExecutionEnteredFinalState(String policy);

  /// Analysis outcome when a TM halts accepted.
  ///
  /// In en, this message translates to:
  /// **'The machine halted under the {policy, select, finalState {final-state} halting {halting} finalStateOrHalting {final-state-or-halting} other {selected}} policy.'**
  String tmExecutionHaltedAccepted(String policy);

  /// Analysis outcome when a TM halts rejected.
  ///
  /// In en, this message translates to:
  /// **'The machine halted outside a final state.'**
  String get tmExecutionHaltedRejected;

  /// Analysis message describing a deterministic TM transition conflict.
  ///
  /// In en, this message translates to:
  /// **'The deterministic machine has {count} transitions for state {state} on symbol {symbol}.'**
  String tmExecutionDeterministicConflict(
    int count,
    String state,
    String symbol,
  );

  /// Warning when deterministic TM execution reaches its step limit.
  ///
  /// In en, this message translates to:
  /// **'The step limit was reached without a resolved outcome.'**
  String get tmExecutionStepLimit;

  /// Warning when TM execution reaches its configuration limit.
  ///
  /// In en, this message translates to:
  /// **'The configuration limit was reached without a resolved outcome.'**
  String get tmExecutionConfigurationLimit;

  /// Warning when deterministic TM execution detects a cycle.
  ///
  /// In en, this message translates to:
  /// **'A deterministic cycle was detected.'**
  String get tmExecutionDeterministicCycle;

  /// Warning when a nondeterministic TM branch reaches its step limit.
  ///
  /// In en, this message translates to:
  /// **'At least one branch reached the step limit.'**
  String get tmExecutionBranchStepLimit;

  /// Analysis outcome when every NTM branch rejects.
  ///
  /// In en, this message translates to:
  /// **'Every reachable branch halted without acceptance.'**
  String get tmExecutionEveryBranchRejected;

  /// Analysis outcome when the explored NTM graph has no accepting configuration.
  ///
  /// In en, this message translates to:
  /// **'The explored configuration graph contains no accepting configuration.'**
  String get tmExecutionExploredGraphRejected;

  /// Validation message for TM space profiling with no states.
  ///
  /// In en, this message translates to:
  /// **'The Turing machine must have at least one state.'**
  String get tmSpaceProfileEmptyMachine;

  /// Validation message for TM space profiling without a valid initial state.
  ///
  /// In en, this message translates to:
  /// **'The Turing machine must define a valid initial state.'**
  String get tmSpaceProfileMissingInitialState;

  /// Validation message for a negative TM space-profile input length.
  ///
  /// In en, this message translates to:
  /// **'Maximum input length must be non-negative.'**
  String get tmSpaceProfileMaxInputLengthInvalid;

  /// Validation message for a non-positive TM space-profile candidate cap.
  ///
  /// In en, this message translates to:
  /// **'Candidate cap per length must be greater than zero.'**
  String get tmSpaceProfileCandidateCapInvalid;

  /// Validation message for a non-positive TM space-profile step limit.
  ///
  /// In en, this message translates to:
  /// **'Step limit must be greater than zero.'**
  String get tmSpaceProfileStepLimitInvalid;

  /// Validation message for a non-positive TM space-profile configuration limit.
  ///
  /// In en, this message translates to:
  /// **'Configuration limit must be greater than zero.'**
  String get tmSpaceProfileConfigurationLimitInvalid;

  /// Validation message for a non-positive TM space-profile timeout.
  ///
  /// In en, this message translates to:
  /// **'Timeout must be greater than zero.'**
  String get tmSpaceProfileTimeoutInvalid;

  /// Validation message for a non-positive TM space-profile batch size.
  ///
  /// In en, this message translates to:
  /// **'Operations per batch must be greater than zero.'**
  String get tmSpaceProfileOperationsPerBatchInvalid;

  /// Analysis message when TM space metrics are absent.
  ///
  /// In en, this message translates to:
  /// **'Bounded execution did not return tape-space metrics.'**
  String get tmSpaceProfileMissingSpaceMetrics;

  /// Validation message for a negative TM time-profile input length.
  ///
  /// In en, this message translates to:
  /// **'Maximum input length must be non-negative.'**
  String get tmTimeProfileMaxLengthInvalid;

  /// Validation message for a non-positive TM time-profile candidate cap.
  ///
  /// In en, this message translates to:
  /// **'Candidate cap per length must be greater than zero.'**
  String get tmTimeProfileCandidateCapInvalid;

  /// Validation message for a non-positive TM time-profile step limit.
  ///
  /// In en, this message translates to:
  /// **'Step limit must be greater than zero.'**
  String get tmTimeProfileStepLimitInvalid;

  /// Validation message for a non-positive TM time-profile configuration limit.
  ///
  /// In en, this message translates to:
  /// **'Configuration limit must be greater than zero.'**
  String get tmTimeProfileConfigurationLimitInvalid;

  /// Validation message for a non-positive TM time-profile timeout.
  ///
  /// In en, this message translates to:
  /// **'Timeout must be greater than zero.'**
  String get tmTimeProfileTimeoutInvalid;

  /// Validation message for a non-positive TM time-profile batch size.
  ///
  /// In en, this message translates to:
  /// **'Operations per batch must be greater than zero.'**
  String get tmTimeProfileOperationsPerBatchInvalid;

  /// Analysis status for a completed TM time profile.
  ///
  /// In en, this message translates to:
  /// **'The time profile completed.'**
  String get tmTimeProfileComplete;

  /// Analysis status for an incomplete TM time profile.
  ///
  /// In en, this message translates to:
  /// **'The bounded profile is incomplete because a row was sampled or an execution remained unknown.'**
  String get tmTimeProfileIncomplete;

  /// Analysis status when TM time profiling is cancelled.
  ///
  /// In en, this message translates to:
  /// **'Time profiling was cancelled.'**
  String get tmTimeProfileCancelled;

  /// Analysis status for an invalid TM time profile.
  ///
  /// In en, this message translates to:
  /// **'The Turing machine is invalid.'**
  String get tmTimeProfileInvalidMachine;

  /// Validation message for TM reachability with no states.
  ///
  /// In en, this message translates to:
  /// **'The Turing machine must have at least one state.'**
  String get tmReachabilityEmptyMachine;

  /// Validation message for TM reachability without a valid initial state.
  ///
  /// In en, this message translates to:
  /// **'The Turing machine must define a valid initial state.'**
  String get tmReachabilityInvalidInitialState;

  /// Validation message when TM reachability receives no inputs.
  ///
  /// In en, this message translates to:
  /// **'At least one input is required for reachability analysis.'**
  String get tmReachabilityInputsRequired;

  /// Validation message for a non-positive TM reachability step limit.
  ///
  /// In en, this message translates to:
  /// **'Step limit must be greater than zero.'**
  String get tmReachabilityStepLimitInvalid;

  /// Validation message for a non-positive TM reachability configuration limit.
  ///
  /// In en, this message translates to:
  /// **'Configuration limit must be greater than zero.'**
  String get tmReachabilityConfigurationLimitInvalid;

  /// Validation message for a non-positive TM reachability timeout.
  ///
  /// In en, this message translates to:
  /// **'Timeout must be greater than zero.'**
  String get tmReachabilityTimeoutInvalid;

  /// Validation message for a non-positive TM reachability batch size.
  ///
  /// In en, this message translates to:
  /// **'Operations per batch must be greater than zero.'**
  String get tmReachabilityOperationsPerBatchInvalid;

  /// Validation message for a non-TM transition during reachability analysis.
  ///
  /// In en, this message translates to:
  /// **'The machine contains a transition that is not a Turing-machine transition.'**
  String get tmReachabilityNonTmTransition;

  /// Validation message for a TM transition endpoint outside the state set.
  ///
  /// In en, this message translates to:
  /// **'Transition {transition} has an endpoint outside the machine state set.'**
  String tmReachabilityTransitionEndpointOutsideSet(String transition);

  /// Validation message for a reachability input symbol outside the TM alphabet.
  ///
  /// In en, this message translates to:
  /// **'Input {input} contains symbol {symbol} outside the machine alphabet.'**
  String tmReachabilityInputSymbolOutsideAlphabet(String input, String symbol);

  /// Analysis status when TM reachability is cancelled.
  ///
  /// In en, this message translates to:
  /// **'Reachability analysis was cancelled.'**
  String get tmReachabilityCancelled;

  /// Analysis status when TM reachability reaches its timeout.
  ///
  /// In en, this message translates to:
  /// **'Reachability analysis timed out.'**
  String get tmReachabilityTimeout;

  /// Analysis status when TM reachability reaches its configuration limit.
  ///
  /// In en, this message translates to:
  /// **'Reachability analysis reached its configuration limit.'**
  String get tmReachabilityConfigurationLimit;

  /// Analysis status when TM reachability reaches its step limit.
  ///
  /// In en, this message translates to:
  /// **'Reachability analysis reached its step limit.'**
  String get tmReachabilityStepLimit;

  /// Analysis status for completed TM reachability analysis.
  ///
  /// In en, this message translates to:
  /// **'Reachability analysis completed.'**
  String get tmReachabilityComplete;

  /// Validation message for a negative TM language-explorer input length.
  ///
  /// In en, this message translates to:
  /// **'Maximum input length must be non-negative.'**
  String get tmLanguageExplorerMaxInputLengthInvalid;

  /// Validation message for a non-positive TM language-explorer candidate cap.
  ///
  /// In en, this message translates to:
  /// **'Candidate cap per length must be greater than zero.'**
  String get tmLanguageExplorerCandidateCapInvalid;

  /// Validation message for a non-positive TM language-explorer step limit.
  ///
  /// In en, this message translates to:
  /// **'Step limit must be greater than zero.'**
  String get tmLanguageExplorerStepLimitInvalid;

  /// Validation message for a non-positive TM language-explorer configuration limit.
  ///
  /// In en, this message translates to:
  /// **'Configuration limit must be greater than zero.'**
  String get tmLanguageExplorerConfigurationLimitInvalid;

  /// Validation message for a non-positive TM language-explorer timeout.
  ///
  /// In en, this message translates to:
  /// **'Timeout must be greater than zero.'**
  String get tmLanguageExplorerTimeoutInvalid;

  /// Validation message for a non-positive TM language-explorer batch size.
  ///
  /// In en, this message translates to:
  /// **'Operations per batch must be greater than zero.'**
  String get tmLanguageExplorerOperationsPerBatchInvalid;

  /// Validation message for NFA-to-DFA conversion with no states.
  ///
  /// In en, this message translates to:
  /// **'The automaton must contain at least one state.'**
  String get nfaToDfaEmptyAutomaton;

  /// Validation message for NFA-to-DFA conversion without an initial state.
  ///
  /// In en, this message translates to:
  /// **'The automaton must have an initial state.'**
  String get nfaToDfaMissingInitialState;

  /// Validation message for an NFA initial state outside its state set.
  ///
  /// In en, this message translates to:
  /// **'The initial state must belong to the automaton state set.'**
  String get nfaToDfaInitialStateOutsideSet;

  /// Validation message for an NFA accepting state outside its state set.
  ///
  /// In en, this message translates to:
  /// **'Every accepting state must belong to the automaton state set.'**
  String get nfaToDfaAcceptingStateOutsideSet;

  /// Analysis message when subset construction reaches its state limit.
  ///
  /// In en, this message translates to:
  /// **'NFA-to-DFA conversion reached the DFA state limit of {limit}.'**
  String nfaToDfaStateLimitExceeded(int limit);

  /// Analysis message for an NFA-to-DFA conversion failure.
  ///
  /// In en, this message translates to:
  /// **'NFA-to-DFA conversion failed: {error}{withSteps, select, true{ (while recording steps)} other{}}.'**
  String nfaToDfaConversionFailed(String error, String withSteps);

  /// Validation message for negative PDA search limits.
  ///
  /// In en, this message translates to:
  /// **'Search limits must not be negative.'**
  String get pdaSimulationSearchLimitsNegative;

  /// Validation message for a negative PDA memory limit.
  ///
  /// In en, this message translates to:
  /// **'The PDA memory limit must not be negative.'**
  String get pdaSimulationMemoryLimitNegative;

  /// Validation message for a non-positive PDA batch size.
  ///
  /// In en, this message translates to:
  /// **'Configurations per batch must be greater than zero.'**
  String get pdaSimulationConfigurationsPerBatchInvalid;

  /// Analysis message for a PDA simulation operation failure.
  ///
  /// In en, this message translates to:
  /// **'PDA {operation} failed: {error}.'**
  String pdaSimulationFailure(String operation, String error);

  /// Analysis message when PDA accepted-string generation fails.
  ///
  /// In en, this message translates to:
  /// **'Finding accepted strings failed: {error}.'**
  String pdaSimulationAcceptedStringsFailure(String error);

  /// Analysis message when PDA rejected-string generation fails.
  ///
  /// In en, this message translates to:
  /// **'Finding rejected strings failed: {error}.'**
  String pdaSimulationRejectedStringsFailure(String error);

  /// Simulation status when PDA execution reaches its timeout.
  ///
  /// In en, this message translates to:
  /// **'PDA simulation timed out.'**
  String get pdaSimulationTimeout;

  /// Simulation status when PDA execution detects a repeated loop.
  ///
  /// In en, this message translates to:
  /// **'PDA simulation detected an infinite loop.'**
  String get pdaSimulationInfiniteLoop;

  /// Simulation status when PDA execution reaches its configuration limit.
  ///
  /// In en, this message translates to:
  /// **'PDA simulation reached its configuration limit.'**
  String get pdaSimulationConfigurationLimit;

  /// Simulation status when PDA search reaches its depth limit.
  ///
  /// In en, this message translates to:
  /// **'PDA simulation reached its search-depth limit.'**
  String get pdaSimulationDepthLimit;

  /// Simulation status when PDA search reaches its memory limit.
  ///
  /// In en, this message translates to:
  /// **'PDA simulation reached its memory limit.'**
  String get pdaSimulationMemoryLimit;

  /// Simulation status for a superseded PDA request.
  ///
  /// In en, this message translates to:
  /// **'The PDA simulation result is stale and was discarded.'**
  String get pdaSimulationStaleRequest;

  /// Simulation status when no accepting PDA configuration exists.
  ///
  /// In en, this message translates to:
  /// **'No accepting PDA configuration was found.'**
  String get pdaSimulationRejectedNoAcceptingConfiguration;

  /// Heading for one PDA transition explanation.
  ///
  /// In en, this message translates to:
  /// **'PDA transition'**
  String get pdaSimulationTransitionTitle;

  /// PDA trace explanation for reading an input symbol.
  ///
  /// In en, this message translates to:
  /// **'Read input symbol {symbol}.'**
  String pdaSimulationReadInput(String symbol);

  /// PDA trace explanation for a stack action.
  ///
  /// In en, this message translates to:
  /// **'Pop {pop} and push {push} on the stack.'**
  String pdaSimulationStackAction(String pop, String push);

  /// PDA trace explanation for a stack-top change.
  ///
  /// In en, this message translates to:
  /// **'The stack top changes from {before} to {after}.'**
  String pdaSimulationStackTopChange(String before, String after);

  /// PDA trace explanation for a matching stack pop.
  ///
  /// In en, this message translates to:
  /// **'The stack pop matches {symbol}.'**
  String pdaSimulationPopMatches(String symbol);

  /// PDA trace explanation for a transition without a pop.
  ///
  /// In en, this message translates to:
  /// **'No stack symbol is popped.'**
  String get pdaSimulationNoPop;

  /// PDA trace explanation for pushing a stack symbol.
  ///
  /// In en, this message translates to:
  /// **'Pushed {symbol} onto the stack.'**
  String pdaSimulationPushed(String symbol);

  /// PDA trace explanation for a transition without a push.
  ///
  /// In en, this message translates to:
  /// **'No stack symbol is pushed.'**
  String get pdaSimulationNoPush;

  /// PDA trace explanation for an epsilon move.
  ///
  /// In en, this message translates to:
  /// **'This is an ε-move.'**
  String get pdaSimulationEpsilonMove;

  /// Validation message for PDA analysis with no states.
  ///
  /// In en, this message translates to:
  /// **'The PDA must contain at least one state.'**
  String get pdaAnalysisEmptyPda;

  /// Validation message for a negative PDA analysis input length.
  ///
  /// In en, this message translates to:
  /// **'Maximum input length must not be negative.'**
  String get pdaAnalysisInvalidMaxInputLength;

  /// Validation message for a non-positive PDA analysis timeout.
  ///
  /// In en, this message translates to:
  /// **'Timeout must be greater than zero.'**
  String get pdaAnalysisInvalidTimeout;

  /// Analysis status when PDA analysis reaches its timeout.
  ///
  /// In en, this message translates to:
  /// **'PDA analysis timed out.'**
  String get pdaAnalysisTimedOut;

  /// Analysis message for a PDA analysis failure.
  ///
  /// In en, this message translates to:
  /// **'PDA analysis failed: {error}.'**
  String pdaAnalysisFailure(String error);

  /// Validation message for CFG-to-PDA conversion with no productions.
  ///
  /// In en, this message translates to:
  /// **'The grammar must contain at least one production.'**
  String get cfgToPdaEmptyGrammar;

  /// Validation message for CFG-to-PDA conversion without a start symbol.
  ///
  /// In en, this message translates to:
  /// **'The grammar must have a start symbol.'**
  String get cfgToPdaMissingStartSymbol;

  /// Validation message naming an undeclared CFG start symbol.
  ///
  /// In en, this message translates to:
  /// **'Start symbol {symbol} is not declared as a non-terminal.'**
  String cfgToPdaUndeclaredStartSymbol(String symbol);

  /// Validation message naming a malformed CFG production.
  ///
  /// In en, this message translates to:
  /// **'Production {production} is malformed.'**
  String cfgToPdaMalformedProduction(String production);

  /// Validation message naming a duplicate CFG production identifier.
  ///
  /// In en, this message translates to:
  /// **'Production ID {production} is duplicated.'**
  String cfgToPdaDuplicateProductionId(String production);

  /// Validation message naming an undeclared symbol in a CFG production.
  ///
  /// In en, this message translates to:
  /// **'Production {production} uses undeclared symbol {symbol}.'**
  String cfgToPdaUndeclaredSymbol(String production, String symbol);

  /// Analysis message for a failed LL CFG-to-PDA analysis.
  ///
  /// In en, this message translates to:
  /// **'LL analysis failed while constructing the PDA.'**
  String get cfgToPdaLlAnalysisFailed;

  /// Analysis message describing an LL conflict during CFG-to-PDA construction.
  ///
  /// In en, this message translates to:
  /// **'LL conflict for {nonterminal} with lookahead {lookahead}: {productions}.'**
  String cfgToPdaLlConflict(
    String nonterminal,
    String lookahead,
    String productions,
  );

  /// Analysis message when LR construction cannot be used for CFG-to-PDA conversion.
  ///
  /// In en, this message translates to:
  /// **'LR construction is unavailable for this grammar.'**
  String get cfgToPdaLrConstructionUnavailable;

  /// Analysis message describing an LR conflict during CFG-to-PDA construction.
  ///
  /// In en, this message translates to:
  /// **'LR conflict in state {state} with lookahead {lookahead}: {productions}.'**
  String cfgToPdaLrConflict(int state, String lookahead, String productions);

  /// Analysis message for invalid CFG-to-PDA output.
  ///
  /// In en, this message translates to:
  /// **'The CFG-to-PDA construction produced an invalid output.'**
  String get cfgToPdaOutputInvalid;

  /// Analysis status when multi-tape TM execution is cancelled.
  ///
  /// In en, this message translates to:
  /// **'Multi-tape execution was cancelled.'**
  String get tmMultiTapeCancelled;

  /// Analysis status when multi-tape TM execution reaches its timeout.
  ///
  /// In en, this message translates to:
  /// **'Multi-tape execution timed out.'**
  String get tmMultiTapeTimeout;

  /// Analysis status when multi-tape execution reaches its configuration limit.
  ///
  /// In en, this message translates to:
  /// **'Multi-tape execution reached its configuration limit.'**
  String get tmMultiTapeConfigurationLimit;

  /// Analysis status for entering a final state during multi-tape execution.
  ///
  /// In en, this message translates to:
  /// **'The multi-tape execution entered a final state under the {policy} policy.'**
  String tmMultiTapeEnteredFinalState(String policy);

  /// Analysis status for a branch entering a final state during multi-tape execution.
  ///
  /// In en, this message translates to:
  /// **'A multi-tape execution branch entered a final state under the {policy} policy.'**
  String tmMultiTapeBranchEnteredFinalState(String policy);

  /// Analysis status for accepted multi-tape execution.
  ///
  /// In en, this message translates to:
  /// **'Multi-tape execution halted with acceptance under the {policy} policy.'**
  String tmMultiTapeHaltedAccepted(String policy);

  /// Analysis status for an accepted multi-tape execution branch.
  ///
  /// In en, this message translates to:
  /// **'A multi-tape execution branch halted with acceptance under the {policy} policy.'**
  String tmMultiTapeBranchHaltedAccepted(String policy);

  /// Validation message for conflicting deterministic multi-tape transitions.
  ///
  /// In en, this message translates to:
  /// **'The multi-tape machine has conflicting deterministic transitions.'**
  String get tmMultiTapeDeterministicConflict;

  /// Analysis status for a detected deterministic multi-tape cycle.
  ///
  /// In en, this message translates to:
  /// **'A deterministic cycle was detected during multi-tape execution.'**
  String get tmMultiTapeDeterministicCycle;

  /// Analysis status when multi-tape execution reaches its step limit.
  ///
  /// In en, this message translates to:
  /// **'Multi-tape execution reached its step limit.'**
  String get tmMultiTapeStepLimit;

  /// Analysis status for rejected multi-tape execution.
  ///
  /// In en, this message translates to:
  /// **'Multi-tape execution halted without acceptance.'**
  String get tmMultiTapeHaltedRejected;

  /// Analysis status when all multi-tape execution branches reject.
  ///
  /// In en, this message translates to:
  /// **'Every multi-tape execution branch was rejected.'**
  String get tmMultiTapeEveryBranchRejected;

  /// Validation message for a building block that reuses the root machine identifier.
  ///
  /// In en, this message translates to:
  /// **'Building block {block} reuses the root machine ID.'**
  String tmBuildingBlockDuplicateMachineId(String block);

  /// Validation message for an empty building-block identifier.
  ///
  /// In en, this message translates to:
  /// **'Building block {block} has an empty name.'**
  String tmBuildingBlockEmptyBlockName(String block);

  /// Validation message for duplicate building-block identifiers.
  ///
  /// In en, this message translates to:
  /// **'Building-block IDs {firstBlock} and {secondBlock} use the same name.'**
  String tmBuildingBlockDuplicateBlockName(
    String firstBlock,
    String secondBlock,
  );

  /// Validation message for a building block without an initial state.
  ///
  /// In en, this message translates to:
  /// **'Building block {block} has no initial state.'**
  String tmBuildingBlockMissingInitialState(String block);

  /// Validation message for a building-block project without a root initial state.
  ///
  /// In en, this message translates to:
  /// **'The root machine has no initial state.'**
  String get tmBuildingBlockMissingRootInitialState;

  /// Validation message for a building block with a different tape count.
  ///
  /// In en, this message translates to:
  /// **'Building block {block} uses {blockTapes} tapes, but the root machine uses {rootTapes}.'**
  String tmBuildingBlockTapeCountMismatch(
    String block,
    int blockTapes,
    int rootTapes,
  );

  /// Validation message for a building block with a different blank symbol.
  ///
  /// In en, this message translates to:
  /// **'Building block {block} uses a different blank symbol from the root machine.'**
  String tmBuildingBlockBlankSymbolMismatch(String block);

  /// Validation message for a building block containing a nested library.
  ///
  /// In en, this message translates to:
  /// **'Building block {block} contains a nested block library.'**
  String tmBuildingBlockNestedLibrary(String block);

  /// Validation message for a recursive building-block dependency cycle.
  ///
  /// In en, this message translates to:
  /// **'The building-block dependency graph is recursive: {cycle}.'**
  String tmBuildingBlockRecursiveDependency(String cycle);

  /// Validation message for a duplicate building-block invocation identifier.
  ///
  /// In en, this message translates to:
  /// **'Invocation ID {invocation} is duplicated.'**
  String tmBuildingBlockDuplicateInvocationId(String invocation);

  /// Validation message for a state invoking multiple building blocks.
  ///
  /// In en, this message translates to:
  /// **'State {state} invokes more than one building block.'**
  String tmBuildingBlockDuplicateInvocationState(String state);

  /// Validation message for an invocation without a graph anchor state.
  ///
  /// In en, this message translates to:
  /// **'Invocation {invocation} has no anchor state.'**
  String tmBuildingBlockMissingAnchorState(String invocation);

  /// Validation message for an invocation referencing a missing block.
  ///
  /// In en, this message translates to:
  /// **'Invocation {invocation} references missing block {block}.'**
  String tmBuildingBlockMissingReference(String invocation, String block);

  /// Validation message for an invocation using an outdated building-block revision.
  ///
  /// In en, this message translates to:
  /// **'Invocation {invocation} expects revision {expected} of block {block}, but found revision {actual}.'**
  String tmBuildingBlockRevisionMismatch(
    String invocation,
    int expected,
    String block,
    int actual,
  );

  /// Validation message for an accepting root building-block invocation.
  ///
  /// In en, this message translates to:
  /// **'Root invocation {invocation} of block {block} cannot be accepting.'**
  String tmBuildingBlockAcceptingRootInvocation(
    String invocation,
    String block,
  );

  /// Validation message for an invalid building-block project.
  ///
  /// In en, this message translates to:
  /// **'The building-block project is invalid.'**
  String get tmBuildingBlockInvalidProject;

  /// Analysis status when building-block execution is cancelled.
  ///
  /// In en, this message translates to:
  /// **'Building-block execution was cancelled.'**
  String get tmBuildingBlockCancelled;

  /// Analysis status when building-block execution reaches its timeout.
  ///
  /// In en, this message translates to:
  /// **'Building-block execution timed out.'**
  String get tmBuildingBlockTimeout;

  /// Analysis status when building-block execution reaches its configuration limit.
  ///
  /// In en, this message translates to:
  /// **'Building-block execution reached its configuration limit.'**
  String get tmBuildingBlockConfigurationLimit;

  /// Analysis status when building-block execution reaches its call-depth limit.
  ///
  /// In en, this message translates to:
  /// **'Building-block execution reached its call-depth limit.'**
  String get tmBuildingBlockCallDepthLimit;

  /// Analysis status when building-block execution reaches its step limit.
  ///
  /// In en, this message translates to:
  /// **'Building-block execution reached its step limit.'**
  String get tmBuildingBlockStepLimit;

  /// Analysis status for entering a final state during building-block execution.
  ///
  /// In en, this message translates to:
  /// **'Execution entered a final state under the {policy} policy.'**
  String tmBuildingBlockEnteredFinalState(String policy);

  /// Analysis status for accepted building-block execution.
  ///
  /// In en, this message translates to:
  /// **'Building-block execution halted with acceptance under the {policy} policy.'**
  String tmBuildingBlockHaltedAccepted(String policy);

  /// Analysis status for rejected building-block execution.
  ///
  /// In en, this message translates to:
  /// **'Building-block execution halted without acceptance.'**
  String get tmBuildingBlockHaltedRejected;

  /// Analysis status when a finite building-block graph rejects.
  ///
  /// In en, this message translates to:
  /// **'The finite building-block graph rejected the input.'**
  String get tmBuildingBlockFiniteGraphRejected;

  /// Analysis status for a repeated building-block execution configuration.
  ///
  /// In en, this message translates to:
  /// **'Building-block execution repeated a configuration.'**
  String get tmBuildingBlockRepeatedConfiguration;

  /// Validation message for an invalid machine passed to TM-to-grammar conversion.
  ///
  /// In en, this message translates to:
  /// **'The Turing machine is invalid for conversion to an unrestricted grammar.'**
  String get tmToGrammarInvalidMachine;

  /// Validation message with a detailed TM-to-grammar machine diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The Turing machine is invalid for conversion: {detail}.'**
  String tmToGrammarInvalidMachineDetail(String detail);

  /// Validation message for TM-to-grammar conversion without an initial state.
  ///
  /// In en, this message translates to:
  /// **'The Turing machine must have an initial state.'**
  String get tmToGrammarMissingInitialState;

  /// Warning when TM-to-grammar conversion finds no accepting state.
  ///
  /// In en, this message translates to:
  /// **'The Turing machine has no accepting state; the converted language is empty.'**
  String get tmToGrammarNoAcceptingState;

  /// Validation message for unsupported multi-tape TM conversion.
  ///
  /// In en, this message translates to:
  /// **'TM-to-grammar conversion does not support {tapes} tapes.'**
  String tmToGrammarMultiTapeUnsupported(int tapes);

  /// Validation message for unsupported multi-tape TM conversion without a tape count.
  ///
  /// In en, this message translates to:
  /// **'TM-to-grammar conversion does not support multi-tape machines.'**
  String get tmToGrammarMultiTapeUnsupportedGeneric;

  /// Validation message for unsupported TM building blocks during conversion.
  ///
  /// In en, this message translates to:
  /// **'TM-to-grammar conversion does not support building blocks: {blocks}.'**
  String tmToGrammarBuildingBlocksUnsupported(String blocks);

  /// Validation message for unsupported TM building blocks without identifiers.
  ///
  /// In en, this message translates to:
  /// **'TM-to-grammar conversion does not support building blocks.'**
  String get tmToGrammarBuildingBlocksUnsupportedGeneric;

  /// Validation message for a blank symbol in the TM input alphabet.
  ///
  /// In en, this message translates to:
  /// **'The blank symbol {symbol} cannot be in the input alphabet.'**
  String tmToGrammarBlankInInputAlphabet(String symbol);

  /// Validation message for a blank symbol in the TM input alphabet without a symbol value.
  ///
  /// In en, this message translates to:
  /// **'The blank symbol cannot be in the input alphabet.'**
  String get tmToGrammarBlankInInputAlphabetGeneric;

  /// Validation message for an input symbol outside the TM tape alphabet.
  ///
  /// In en, this message translates to:
  /// **'Input symbol {symbol} is outside the tape alphabet.'**
  String tmToGrammarInputOutsideTapeAlphabet(String symbol);

  /// Validation message for an input symbol outside the tape alphabet without a symbol value.
  ///
  /// In en, this message translates to:
  /// **'An input symbol is outside the tape alphabet.'**
  String get tmToGrammarInputOutsideTapeAlphabetGeneric;

  /// Analysis message when TM-to-grammar construction reaches its production limit.
  ///
  /// In en, this message translates to:
  /// **'TM-to-grammar construction reached its production limit of {limit}.'**
  String tmToGrammarConstructionLimit(int limit);

  /// Analysis message with a detailed TM-to-grammar construction limit diagnostic.
  ///
  /// In en, this message translates to:
  /// **'TM-to-grammar construction stopped: {detail}.'**
  String tmToGrammarConstructionLimitDetail(String detail);

  /// Analysis message for a TM-to-grammar construction limit without details.
  ///
  /// In en, this message translates to:
  /// **'TM-to-grammar construction reached its limit.'**
  String get tmToGrammarConstructionLimitGeneric;

  /// Analysis message with a detailed invalid TM-to-grammar output diagnostic.
  ///
  /// In en, this message translates to:
  /// **'TM-to-grammar conversion produced invalid output: {detail}.'**
  String tmToGrammarOutputInvalid(String detail);

  /// Analysis message for invalid TM-to-grammar output without details.
  ///
  /// In en, this message translates to:
  /// **'TM-to-grammar conversion produced invalid output.'**
  String get tmToGrammarOutputInvalidGeneric;

  /// Warning naming an unreachable state during TM-to-grammar conversion.
  ///
  /// In en, this message translates to:
  /// **'State {state} is unreachable from the initial state.'**
  String tmToGrammarUnreachableState(String state);

  /// Warning for an unreachable state without an identifier.
  ///
  /// In en, this message translates to:
  /// **'An unreachable state was found.'**
  String get tmToGrammarUnreachableStateGeneric;

  /// Title for the initial partition step of DFA minimization.
  ///
  /// In en, this message translates to:
  /// **'Create the initial partition'**
  String get dfaMinimizationStepInitialPartitionTitle;

  /// Explanation of the initial accepting and non-accepting DFA partition.
  ///
  /// In en, this message translates to:
  /// **'Initial partition: accepting states [{acceptingStates}] and non-accepting states [{nonAcceptingStates}].'**
  String dfaMinimizationStepInitialPartitionExplanation(
    String acceptingStates,
    String nonAcceptingStates,
  );

  /// Title for removing unreachable states during DFA minimization.
  ///
  /// In en, this message translates to:
  /// **'Remove unreachable states'**
  String get dfaMinimizationStepRemoveUnreachableTitle;

  /// Explanation of unreachable-state removal during DFA minimization.
  ///
  /// In en, this message translates to:
  /// **'Removed unreachable states [{unreachableStates}]; {reachableStateCount} reachable states remain.'**
  String dfaMinimizationStepRemoveUnreachableExplanation(
    String unreachableStates,
    int reachableStateCount,
  );

  /// Title for selecting a partition set during DFA minimization.
  ///
  /// In en, this message translates to:
  /// **'Select a partition set'**
  String get dfaMinimizationStepSelectSetTitle;

  /// Explanation of the selected DFA partition set.
  ///
  /// In en, this message translates to:
  /// **'Selected partition set [{states}] for refinement.'**
  String dfaMinimizationStepSelectSetExplanation(String states);

  /// Title for finding DFA predecessors on an input symbol.
  ///
  /// In en, this message translates to:
  /// **'Find predecessors on {symbol}'**
  String dfaMinimizationStepFindPredecessorsTitle(String symbol);

  /// Explanation of predecessor discovery during DFA minimization.
  ///
  /// In en, this message translates to:
  /// **'States [{states}] have predecessors [{predecessors}] on {symbol}{hasPredecessors, select, true{.} other{; no predecessors were found.}}'**
  String dfaMinimizationStepFindPredecessorsExplanation(
    String states,
    String symbol,
    String predecessors,
    String hasPredecessors,
  );

  /// Title for splitting a DFA partition class.
  ///
  /// In en, this message translates to:
  /// **'Split a partition class'**
  String get dfaMinimizationStepSplitClassTitle;

  /// Explanation of a partition-class split during DFA minimization.
  ///
  /// In en, this message translates to:
  /// **'Split [{splitStates}] on {symbol} into intersection [{intersectionStates}] and difference [{differenceStates}] ({oldPartitionSize} classes became {newPartitionSize}).'**
  String dfaMinimizationStepSplitClassExplanation(
    String splitStates,
    String symbol,
    String intersectionStates,
    String differenceStates,
    int oldPartitionSize,
    int newPartitionSize,
  );

  /// Title for a DFA partition class that does not split.
  ///
  /// In en, this message translates to:
  /// **'Keep the partition class for {symbol}'**
  String dfaMinimizationStepNoSplitTitle(String symbol);

  /// Explanation of a partition class that remains stable.
  ///
  /// In en, this message translates to:
  /// **'Class [{states}] remains stable for symbol {symbol}.'**
  String dfaMinimizationStepNoSplitExplanation(String states, String symbol);

  /// Title for a stable DFA partition.
  ///
  /// In en, this message translates to:
  /// **'Partition is stable'**
  String get dfaMinimizationStepPartitionStableTitle;

  /// Explanation of DFA partition stability.
  ///
  /// In en, this message translates to:
  /// **'The partition is stable with {partitionSize} classes.'**
  String dfaMinimizationStepPartitionStableExplanation(int partitionSize);

  /// Title for creating one minimized DFA state.
  ///
  /// In en, this message translates to:
  /// **'Create minimized state {state}'**
  String dfaMinimizationStepCreateMinimizedStateTitle(String state);

  /// Explanation of a minimized state and its formal properties.
  ///
  /// In en, this message translates to:
  /// **'State {state} represents [{equivalenceClass}]; initial: {isInitial, select, true{yes} other{no}}, accepting: {isAccepting, select, true{yes} other{no}}.'**
  String dfaMinimizationStepCreateMinimizedStateExplanation(
    String state,
    String equivalenceClass,
    String isInitial,
    String isAccepting,
  );

  /// Title for creating a minimized DFA transition.
  ///
  /// In en, this message translates to:
  /// **'Create minimized transition on {symbol}'**
  String dfaMinimizationStepCreateMinimizedTransitionTitle(String symbol);

  /// Explanation of a minimized DFA transition.
  ///
  /// In en, this message translates to:
  /// **'Transition from {fromState} to {toState} on {symbol}.'**
  String dfaMinimizationStepCreateMinimizedTransitionExplanation(
    String fromState,
    String toState,
    String symbol,
  );

  /// Title for completing DFA minimization.
  ///
  /// In en, this message translates to:
  /// **'Complete DFA minimization'**
  String get dfaMinimizationStepCompletionTitle;

  /// Summary of completed DFA minimization.
  ///
  /// In en, this message translates to:
  /// **'Minimization complete: {originalStateCount} states became {minimizedStateCount}, with {transitionCount} transitions{hasReduction, select, true{ and a reduction of {reduction} states} other{}}.'**
  String dfaMinimizationStepCompletionExplanation(
    int originalStateCount,
    int minimizedStateCount,
    int transitionCount,
    int reduction,
    String hasReduction,
  );

  /// Structured FSA determinization failure message.
  ///
  /// In en, this message translates to:
  /// **'Determinization failed for {automaton}.'**
  String fsaDeterminizerFailed(String automaton);

  /// Structured input-validation message (FsaEmpty).
  ///
  /// In en, this message translates to:
  /// **'The automaton has no states.'**
  String get validationFsaEmpty;

  /// Structured input-validation message (FsaNoInitial).
  ///
  /// In en, this message translates to:
  /// **'The automaton has no initial state.'**
  String get validationFsaNoInitial;

  /// Structured input-validation message (FsaInvalidInitial).
  ///
  /// In en, this message translates to:
  /// **'Initial state {state} is not in the state set.'**
  String validationFsaInvalidInitial(String state);

  /// Structured input-validation message (FsaEmptyAlphabet).
  ///
  /// In en, this message translates to:
  /// **'The automaton has no alphabet.'**
  String get validationFsaEmptyAlphabet;

  /// Structured input-validation message (FsaInvalidAccepting).
  ///
  /// In en, this message translates to:
  /// **'Accepting state {state} is not in the state set.'**
  String validationFsaInvalidAccepting(String state);

  /// Structured input-validation message (FsaBadFrom).
  ///
  /// In en, this message translates to:
  /// **'Transition source state {state} is unknown.'**
  String validationFsaBadFrom(String state);

  /// Structured input-validation message (FsaBadTo).
  ///
  /// In en, this message translates to:
  /// **'Transition target state {state} is unknown.'**
  String validationFsaBadTo(String state);

  /// Structured input-validation message (FsaBadSymbol).
  ///
  /// In en, this message translates to:
  /// **'Transition symbol {symbol} is outside the alphabet.'**
  String validationFsaBadSymbol(String symbol);

  /// Structured input-validation message (FsaNondeterministic).
  ///
  /// In en, this message translates to:
  /// **'State {state} has {count} transitions on {symbol}.'**
  String validationFsaNondeterministic(String state, int count, String symbol);

  /// Structured input-validation message (PdaEmpty).
  ///
  /// In en, this message translates to:
  /// **'The PDA has no states.'**
  String get validationPdaEmpty;

  /// Structured input-validation message (PdaNoInitial).
  ///
  /// In en, this message translates to:
  /// **'The PDA has no initial state.'**
  String get validationPdaNoInitial;

  /// Structured input-validation message (PdaInvalidInitial).
  ///
  /// In en, this message translates to:
  /// **'Initial state {state} is not in the state set.'**
  String validationPdaInvalidInitial(String state);

  /// Structured input-validation message (PdaNoAccepting).
  ///
  /// In en, this message translates to:
  /// **'The PDA has no accepting states.'**
  String get validationPdaNoAccepting;

  /// Structured input-validation message (PdaEmptyInputAlphabet).
  ///
  /// In en, this message translates to:
  /// **'The PDA has no input alphabet.'**
  String get validationPdaEmptyInputAlphabet;

  /// Structured input-validation message (PdaEmptyStackAlphabet).
  ///
  /// In en, this message translates to:
  /// **'The PDA has no stack alphabet.'**
  String get validationPdaEmptyStackAlphabet;

  /// Structured input-validation message (PdaInvalidInitialStack).
  ///
  /// In en, this message translates to:
  /// **'Initial stack symbol {symbol} is outside the stack alphabet.'**
  String validationPdaInvalidInitialStack(String symbol);

  /// Structured input-validation message (PdaInvalidAccepting).
  ///
  /// In en, this message translates to:
  /// **'Accepting state {state} is not in the state set.'**
  String validationPdaInvalidAccepting(String state);

  /// Structured input-validation message (PdaBadFrom).
  ///
  /// In en, this message translates to:
  /// **'Transition source state {state} is unknown.'**
  String validationPdaBadFrom(String state);

  /// Structured input-validation message (PdaBadTo).
  ///
  /// In en, this message translates to:
  /// **'Transition target state {state} is unknown.'**
  String validationPdaBadTo(String state);

  /// Structured input-validation message (PdaBadInputSymbol).
  ///
  /// In en, this message translates to:
  /// **'Input symbol {symbol} is outside the input alphabet.'**
  String validationPdaBadInputSymbol(String symbol);

  /// Structured input-validation message (PdaBadStackSymbol).
  ///
  /// In en, this message translates to:
  /// **'Stack symbol {symbol} is outside the stack alphabet.'**
  String validationPdaBadStackSymbol(String symbol);

  /// Structured input-validation message (PdaBadPushSymbol).
  ///
  /// In en, this message translates to:
  /// **'Pushed stack symbol {symbol} is outside the stack alphabet.'**
  String validationPdaBadPushSymbol(String symbol);

  /// Title for computing the initial epsilon-closure.
  ///
  /// In en, this message translates to:
  /// **'Compute the initial ε-closure'**
  String get nfaToDfaStepInitialEpsilonClosureTitle;

  /// Explanation of the initial epsilon-closure.
  ///
  /// In en, this message translates to:
  /// **'The ε-closure of {initialState} is {epsilonClosure}{containsAcceptingState, select, true{ and contains an accepting state} other{}}.'**
  String nfaToDfaStepInitialEpsilonClosureExplanation(
    String initialState,
    String epsilonClosure,
    String containsAcceptingState,
  );

  /// Teaching-step title for the initial epsilon-closure.
  ///
  /// In en, this message translates to:
  /// **'Initial ε-closure'**
  String get nfaToDfaStepInitialEpsilonClosureStepTitle;

  /// Bullet describing the initial NFA state.
  ///
  /// In en, this message translates to:
  /// **'Start from state {state}.'**
  String nfaToDfaStepInitialState(String state);

  /// Bullet describing the states reached by epsilon transitions.
  ///
  /// In en, this message translates to:
  /// **'Reach {stateSet} through ε-transitions.'**
  String nfaToDfaStepEpsilonClosureReached(String stateSet);

  /// Bullet marking an accepting initial DFA state.
  ///
  /// In en, this message translates to:
  /// **'The initial DFA state is accepting.'**
  String get nfaToDfaStepInitialStateIsAccepting;

  /// Title for processing an input symbol.
  ///
  /// In en, this message translates to:
  /// **'Process symbol {symbol}'**
  String nfaToDfaStepProcessSymbolTitle(String symbol);

  /// Explanation of symbol processing.
  ///
  /// In en, this message translates to:
  /// **'From {currentStates}, reading {symbol} reaches {reachableStates} before ε-closure.'**
  String nfaToDfaStepProcessSymbolExplanation(
    String currentStates,
    String symbol,
    String reachableStates,
  );

  /// Teaching-step title for processing a symbol.
  ///
  /// In en, this message translates to:
  /// **'Process an input symbol'**
  String get nfaToDfaStepProcessSymbolStepTitle;

  /// Bullet naming the current DFA state set.
  ///
  /// In en, this message translates to:
  /// **'Use DFA state set {stateSet}.'**
  String nfaToDfaStepCurrentDfaStateSet(String stateSet);

  /// Bullet describing symbol-labeled NFA transitions.
  ///
  /// In en, this message translates to:
  /// **'Follow NFA transitions labeled {symbol}.'**
  String nfaToDfaStepCollectSymbolDestinations(String symbol);

  /// Bullet naming reachable states before epsilon-closure.
  ///
  /// In en, this message translates to:
  /// **'Reach NFA states {stateSet}.'**
  String nfaToDfaStepReachableBeforeEpsilonClosure(String stateSet);

  /// Title for closing the reachable NFA states under epsilon.
  ///
  /// In en, this message translates to:
  /// **'Compute ε-closure of reachable states'**
  String get nfaToDfaStepEpsilonClosureOfReachableTitle;

  /// Explanation of the reachable-state epsilon-closure.
  ///
  /// In en, this message translates to:
  /// **'The ε-closure of {reachableStates} is {epsilonClosure}; it {isNewState, select, true{creates a new} other{reuses an existing}} DFA state{containsAcceptingState, select, true{, which is accepting} other{}}.'**
  String nfaToDfaStepEpsilonClosureOfReachableExplanation(
    String reachableStates,
    String epsilonClosure,
    String isNewState,
    String containsAcceptingState,
  );

  /// Teaching-step title for the reachable epsilon-closure.
  ///
  /// In en, this message translates to:
  /// **'Close the reachable states under ε'**
  String get nfaToDfaStepEpsilonClosureOfReachableStepTitle;

  /// Bullet explaining epsilon transitions.
  ///
  /// In en, this message translates to:
  /// **'ε-transitions do not consume input.'**
  String get nfaToDfaStepEpsilonTransitionsDoNotConsumeInput;

  /// Bullet naming the closure reached from states.
  ///
  /// In en, this message translates to:
  /// **'The ε-closure from {reachableStates} is {epsilonClosure}.'**
  String nfaToDfaStepEpsilonClosureReachedFromStates(
    String reachableStates,
    String epsilonClosure,
  );

  /// Bullet marking a newly discovered DFA state set.
  ///
  /// In en, this message translates to:
  /// **'This set becomes a new DFA state.'**
  String get nfaToDfaStepNewDfaStateSet;

  /// Bullet marking a previously discovered DFA state set.
  ///
  /// In en, this message translates to:
  /// **'This set matches an existing DFA state.'**
  String get nfaToDfaStepExistingDfaStateSet;

  /// Bullet marking an accepting DFA state set.
  ///
  /// In en, this message translates to:
  /// **'The DFA state set is accepting.'**
  String get nfaToDfaStepAcceptingDfaStateSet;

  /// Title for creating a DFA state.
  ///
  /// In en, this message translates to:
  /// **'Create DFA state {state}'**
  String nfaToDfaStepCreateDfaStateTitle(String state);

  /// Explanation of a created DFA state.
  ///
  /// In en, this message translates to:
  /// **'DFA state {state} represents {stateSet} and is {isAccepting, select, true{accepting} other{not accepting}}.'**
  String nfaToDfaStepCreateDfaStateExplanation(
    String state,
    String stateSet,
    String isAccepting,
  );

  /// Teaching-step title for creating a DFA state.
  ///
  /// In en, this message translates to:
  /// **'Create a DFA state'**
  String get nfaToDfaStepCreateDfaStateStepTitle;

  /// Bullet explaining the subset construction.
  ///
  /// In en, this message translates to:
  /// **'Each distinct NFA state set becomes one DFA state.'**
  String get nfaToDfaStepSubsetConstructionDistinctStateSets;

  /// Bullet relating a DFA state to an NFA set.
  ///
  /// In en, this message translates to:
  /// **'The DFA state represents NFA set {stateSet}.'**
  String nfaToDfaStepDfaStateRepresentsNfaSet(String stateSet);

  /// Bullet marking an accepting DFA state.
  ///
  /// In en, this message translates to:
  /// **'Mark the DFA state as accepting.'**
  String get nfaToDfaStepAcceptingDfaState;

  /// Bullet marking a non-accepting DFA state.
  ///
  /// In en, this message translates to:
  /// **'The DFA state is not accepting.'**
  String get nfaToDfaStepNonAcceptingDfaState;

  /// Title for creating a DFA transition.
  ///
  /// In en, this message translates to:
  /// **'Create DFA transition on {symbol}'**
  String nfaToDfaStepCreateDfaTransitionTitle(String symbol);

  /// Explanation of a created DFA transition.
  ///
  /// In en, this message translates to:
  /// **'Add {fromState} —{symbol}→ {toState} for {fromStates} to {toStates}.'**
  String nfaToDfaStepCreateDfaTransitionExplanation(
    String fromState,
    String symbol,
    String toState,
    String fromStates,
    String toStates,
  );

  /// Teaching-step title for creating a DFA transition.
  ///
  /// In en, this message translates to:
  /// **'Create a DFA transition'**
  String get nfaToDfaStepCreateDfaTransitionStepTitle;

  /// Bullet describing NFA transition reachability.
  ///
  /// In en, this message translates to:
  /// **'NFA states {fromStates} on {symbol} reach {toStates}.'**
  String nfaToDfaStepNfaTransitionReachability(
    String fromStates,
    String symbol,
    String toStates,
  );

  /// Bullet explaining deterministic transition creation.
  ///
  /// In en, this message translates to:
  /// **'Record one deterministic transition for this state set and symbol.'**
  String get nfaToDfaStepSingleDeterministicTransition;

  /// Title for completing NFA-to-DFA conversion.
  ///
  /// In en, this message translates to:
  /// **'Complete NFA-to-DFA conversion'**
  String get nfaToDfaStepCompletionTitle;

  /// Summary of the completed NFA-to-DFA conversion.
  ///
  /// In en, this message translates to:
  /// **'The DFA has {stateCount} states, {transitionCount} transitions, and {acceptingStateCount} accepting states.'**
  String nfaToDfaStepCompletionExplanation(
    int stateCount,
    int transitionCount,
    int acceptingStateCount,
  );

  /// Teaching-step title for completing conversion.
  ///
  /// In en, this message translates to:
  /// **'Conversion complete'**
  String get nfaToDfaStepCompletionStepTitle;

  /// Bullet reporting the number of DFA states.
  ///
  /// In en, this message translates to:
  /// **'Created {count} DFA states.'**
  String nfaToDfaStepCreatedStateCount(int count);

  /// Bullet reporting the number of DFA transitions.
  ///
  /// In en, this message translates to:
  /// **'Created {count} DFA transitions.'**
  String nfaToDfaStepCreatedTransitionCount(int count);

  /// Bullet reporting the number of accepting DFA states.
  ///
  /// In en, this message translates to:
  /// **'Marked {count} DFA states as accepting.'**
  String nfaToDfaStepMarkedAcceptingStateCount(int count);

  /// Title for initializing a CYK table.
  ///
  /// In en, this message translates to:
  /// **'Initialize the CYK table'**
  String get cykStepInitializeTitle;

  /// Explanation of CYK table initialization.
  ///
  /// In en, this message translates to:
  /// **'Initialize a table for input {input} with {tableSize} tokens.'**
  String cykStepInitializeExplanation(String input, int tableSize);

  /// Teaching-step title for CYK initialization.
  ///
  /// In en, this message translates to:
  /// **'Initialize the CYK table'**
  String get cykStepInitializeStepTitle;

  /// Bullet describing CYK input tokenization.
  ///
  /// In en, this message translates to:
  /// **'Tokenize the input {input} ({tableSize} tokens).'**
  String cykStepInitializeInputBullet(String input, int tableSize);

  /// Bullet describing CYK table creation.
  ///
  /// In en, this message translates to:
  /// **'Create the triangular CYK table.'**
  String get cykStepInitializeTableBullet;

  /// Title for filling a CYK base case.
  ///
  /// In en, this message translates to:
  /// **'Fill the base case for {terminal}'**
  String cykStepFillBaseCaseTitle(String terminal);

  /// Explanation of a CYK base-case cell.
  ///
  /// In en, this message translates to:
  /// **'At input position {position}, terminal {terminal} is derived by {hasVariables, select, true{{variables}} other{no variables}}.'**
  String cykStepFillBaseCaseExplanation(
    int position,
    String terminal,
    String variables,
    String hasVariables,
  );

  /// Teaching-step title for a CYK base case.
  ///
  /// In en, this message translates to:
  /// **'Fill a base-case cell for {terminal}'**
  String cykStepFillBaseCaseStepTitle(String terminal);

  /// Bullet identifying a CYK terminal fragment.
  ///
  /// In en, this message translates to:
  /// **'The input fragment at position {position} is {terminal}.'**
  String cykStepFillBaseCaseFragmentBullet(int position, String terminal);

  /// Bullet describing terminal-production lookup.
  ///
  /// In en, this message translates to:
  /// **'Find productions that derive this terminal.'**
  String get cykStepFillBaseCaseProductionBullet;

  /// Bullet for an empty CYK base case.
  ///
  /// In en, this message translates to:
  /// **'No nonterminal derives terminal {terminal}.'**
  String cykStepFillBaseCaseEmptyBullet(String terminal);

  /// Bullet listing nonterminals added to a base case.
  ///
  /// In en, this message translates to:
  /// **'Add nonterminals {variables} to the cell.'**
  String cykStepFillBaseCaseAddedBullet(String variables);

  /// Title for processing a CYK cell.
  ///
  /// In en, this message translates to:
  /// **'Process cell [{row}][{column}]'**
  String cykStepProcessCellTitle(int row, int column);

  /// Explanation of processing a CYK cell.
  ///
  /// In en, this message translates to:
  /// **'Process substring {substring} at [{row}][{column}] with length {length}.'**
  String cykStepProcessCellExplanation(
    int row,
    int column,
    String substring,
    int length,
  );

  /// Teaching-step title for processing a CYK cell.
  ///
  /// In en, this message translates to:
  /// **'Process CYK cell {substring}'**
  String cykStepProcessCellStepTitle(String substring);

  /// Bullet identifying a CYK cell location.
  ///
  /// In en, this message translates to:
  /// **'Locate substring {length} at table cell [{row}][{column}].'**
  String cykStepProcessCellLocationBullet(int row, int column, int length);

  /// Bullet describing CYK split exploration.
  ///
  /// In en, this message translates to:
  /// **'Try every split point in the substring.'**
  String get cykStepProcessCellSplitBullet;

  /// Title for checking a CYK split.
  ///
  /// In en, this message translates to:
  /// **'Check the split at position {splitPoint}'**
  String cykStepCheckSplitTitle(int splitPoint);

  /// Explanation of a CYK split check.
  ///
  /// In en, this message translates to:
  /// **'Split {substring} into {leftSubstring} and {rightSubstring}; inspect cells [{leftRow}][{leftColumn}] and [{rightRow}][{rightColumn}]. Left: {hasLeftVariables, select, true{{leftVariables}} other{empty}}; right: {hasRightVariables, select, true{{rightVariables}} other{empty}}.'**
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
  );

  /// Teaching-step title for a CYK split.
  ///
  /// In en, this message translates to:
  /// **'Check split {leftSubstring} | {rightSubstring}'**
  String cykStepCheckSplitStepTitle(
    String leftSubstring,
    String rightSubstring,
  );

  /// Bullet for the left CYK split cell.
  ///
  /// In en, this message translates to:
  /// **'Read the left cell [{row}][{column}]: {hasVariables, select, true{{variables}} other{empty}}.'**
  String cykStepCheckSplitLeftBullet(
    int row,
    int column,
    String variables,
    String hasVariables,
  );

  /// Bullet for the right CYK split cell.
  ///
  /// In en, this message translates to:
  /// **'Read the right cell [{row}][{column}]: {hasVariables, select, true{{variables}} other{empty}}.'**
  String cykStepCheckSplitRightBullet(
    int row,
    int column,
    String variables,
    String hasVariables,
  );

  /// Bullet describing CYK production lookup across a split.
  ///
  /// In en, this message translates to:
  /// **'At [{row}][{column}], look for a production combining the two cells.'**
  String cykStepCheckSplitProductionBullet(int row, int column);

  /// Title for applying a CYK binary production.
  ///
  /// In en, this message translates to:
  /// **'Apply {variable} → {leftVariable} {rightVariable}'**
  String cykStepApplyProductionTitle(
    String variable,
    String leftVariable,
    String rightVariable,
  );

  /// Explanation of applying a CYK production.
  ///
  /// In en, this message translates to:
  /// **'At [{row}][{column}], apply {variable} → {leftVariable} {rightVariable} to {substring}.'**
  String cykStepApplyProductionExplanation(
    int row,
    int column,
    String variable,
    String leftVariable,
    String rightVariable,
    String substring,
  );

  /// Teaching-step title for applying a CYK production.
  ///
  /// In en, this message translates to:
  /// **'Apply {variable} → {leftVariable} {rightVariable}'**
  String cykStepApplyProductionStepTitle(
    String variable,
    String leftVariable,
    String rightVariable,
  );

  /// Bullet describing CYK cell combination.
  ///
  /// In en, this message translates to:
  /// **'Combine nonterminals from the left and right cells.'**
  String get cykStepApplyProductionCombineBullet;

  /// Bullet describing a CYK derivation.
  ///
  /// In en, this message translates to:
  /// **'Use {leftVariable} and {rightVariable} to derive {variable} for {substring}.'**
  String cykStepApplyProductionDerivationBullet(
    String leftVariable,
    String rightVariable,
    String variable,
    String substring,
  );

  /// Bullet describing a CYK cell update.
  ///
  /// In en, this message translates to:
  /// **'Add {variable} to cell [{row}][{column}].'**
  String cykStepApplyProductionAddBullet(int row, int column, String variable);

  /// Title for completing a CYK cell.
  ///
  /// In en, this message translates to:
  /// **'Complete cell [{row}][{column}]'**
  String cykStepCompleteCellTitle(int row, int column);

  /// Explanation of a completed CYK cell.
  ///
  /// In en, this message translates to:
  /// **'Cell [{row}][{column}] for {substring} contains {hasNonterminals, select, true{{nonterminals}} other{no nonterminals}}.'**
  String cykStepCompleteCellExplanation(
    int row,
    int column,
    String substring,
    String nonterminals,
    String hasNonterminals,
  );

  /// Teaching-step title for completing a CYK cell.
  ///
  /// In en, this message translates to:
  /// **'Complete cell [{row}][{column}]'**
  String cykStepCompleteCellStepTitle(int row, int column);

  /// Bullet identifying the completed substring.
  ///
  /// In en, this message translates to:
  /// **'The cell covers substring {substring}.'**
  String cykStepCompleteCellSubstringBullet(String substring);

  /// Bullet for an empty completed CYK cell.
  ///
  /// In en, this message translates to:
  /// **'The cell contains no nonterminals.'**
  String get cykStepCompleteCellEmptyBullet;

  /// Bullet listing completed-cell nonterminals.
  ///
  /// In en, this message translates to:
  /// **'The cell contains nonterminals {nonterminals}.'**
  String cykStepCompleteCellNonterminalsBullet(String nonterminals);

  /// Title for checking CYK acceptance.
  ///
  /// In en, this message translates to:
  /// **'Check CYK acceptance'**
  String get cykStepCheckAcceptanceTitle;

  /// Explanation of the CYK acceptance check.
  ///
  /// In en, this message translates to:
  /// **'For input {input}, the final cell has {hasNonterminals, select, true{{nonterminals}} other{no nonterminals}}; start symbol {startSymbol} {accepted, select, true{is present} other{is absent}}.'**
  String cykStepCheckAcceptanceExplanation(
    String input,
    String startSymbol,
    String nonterminals,
    String hasNonterminals,
    String accepted,
  );

  /// Teaching-step title for CYK acceptance.
  ///
  /// In en, this message translates to:
  /// **'Check acceptance'**
  String get cykStepCheckAcceptanceStepTitle;

  /// Bullet describing final-cell inspection.
  ///
  /// In en, this message translates to:
  /// **'Inspect final-cell nonterminals {nonterminals}.'**
  String cykStepCheckAcceptanceFinalCellBullet(String nonterminals);

  /// Bullet for accepted CYK input.
  ///
  /// In en, this message translates to:
  /// **'The start symbol {startSymbol} is in the final cell.'**
  String cykStepCheckAcceptanceAcceptedBullet(String startSymbol);

  /// Bullet for rejected CYK input.
  ///
  /// In en, this message translates to:
  /// **'The start symbol {startSymbol} is not in the final cell.'**
  String cykStepCheckAcceptanceRejectedBullet(String startSymbol);

  /// Title for completing CYK parsing.
  ///
  /// In en, this message translates to:
  /// **'Complete CYK parsing'**
  String get cykStepCompletionTitle;

  /// Summary of completed CYK parsing.
  ///
  /// In en, this message translates to:
  /// **'Parsed {input}: filled {filledCells} of {totalCells} cells; {accepted, select, true{the input is accepted} other{the input is rejected}}.'**
  String cykStepCompletionExplanation(
    String input,
    int totalCells,
    int filledCells,
    String accepted,
  );

  /// Teaching-step title for completed CYK parsing.
  ///
  /// In en, this message translates to:
  /// **'Parsing complete'**
  String get cykStepCompletionStepTitle;

  /// Bullet reporting filled CYK cells.
  ///
  /// In en, this message translates to:
  /// **'Filled {filledCells} of {totalCells} table cells.'**
  String cykStepCompletionFilledCellsBullet(int totalCells, int filledCells);

  /// Bullet for accepted CYK input.
  ///
  /// In en, this message translates to:
  /// **'The input is accepted by the grammar.'**
  String get cykStepCompletionAcceptedBullet;

  /// Bullet for rejected CYK input.
  ///
  /// In en, this message translates to:
  /// **'The input is rejected by the grammar.'**
  String get cykStepCompletionRejectedBullet;

  /// Validation message for non-positive PDA language-analysis limits.
  ///
  /// In en, this message translates to:
  /// **'PDA language-analysis limits must be greater than zero.'**
  String get pdaLanguageEmptinessInvalidLimits;

  /// Message shown when PDA language-emptiness analysis is cancelled.
  ///
  /// In en, this message translates to:
  /// **'PDA language-emptiness analysis was cancelled.'**
  String get pdaLanguageEmptinessCancelled;

  /// Message shown when a computed PDA witness fails replay.
  ///
  /// In en, this message translates to:
  /// **'The CFG witness could not be replayed by the source PDA.'**
  String get pdaLanguageEmptinessWitnessReplayFailed;

  /// Validation message for non-positive CFG shortest-witness limits.
  ///
  /// In en, this message translates to:
  /// **'CFG analysis limits must be greater than zero.'**
  String get pdaLanguageEmptinessCfgInvalidLimits;

  /// Validation message for a CFG with an undeclared start symbol.
  ///
  /// In en, this message translates to:
  /// **'The CFG start symbol must be a declared nonterminal.'**
  String get pdaLanguageEmptinessCfgMissingStartSymbol;

  /// Validation message for overlapping CFG terminal and nonterminal sets.
  ///
  /// In en, this message translates to:
  /// **'CFG terminals and nonterminals must be disjoint.'**
  String get pdaLanguageEmptinessCfgOverlappingSymbolSets;

  /// Validation message for an invalid CFG production left side.
  ///
  /// In en, this message translates to:
  /// **'Production {production} must have one declared nonterminal on its left side.'**
  String pdaLanguageEmptinessCfgInvalidProductionLeft(String production);

  /// Validation message for inconsistent CFG lambda metadata.
  ///
  /// In en, this message translates to:
  /// **'Production {production} has inconsistent lambda metadata.'**
  String pdaLanguageEmptinessCfgInconsistentLambdaMetadata(String production);

  /// Validation message for a production that mixes epsilon with other symbols.
  ///
  /// In en, this message translates to:
  /// **'Production {production} mixes epsilon with other symbols.'**
  String pdaLanguageEmptinessCfgEpsilonMixed(String production);

  /// Validation message for an undeclared CFG production symbol.
  ///
  /// In en, this message translates to:
  /// **'Production {production} uses undeclared symbol {symbol}.'**
  String pdaLanguageEmptinessCfgUndeclaredSymbol(
    String production,
    String symbol,
  );

  /// Message shown when CFG shortest-witness analysis is cancelled.
  ///
  /// In en, this message translates to:
  /// **'CFG shortest-witness analysis was cancelled.'**
  String get pdaLanguageEmptinessCfgCancelled;

  /// Message shown when CFG productivity reaches its update limit.
  ///
  /// In en, this message translates to:
  /// **'CFG productivity update limit exceeded ({limit}).'**
  String pdaLanguageEmptinessCfgProductivityLimit(int limit);

  /// Message shown when CFG derivation reconstruction reaches its step limit.
  ///
  /// In en, this message translates to:
  /// **'CFG derivation step limit exceeded ({limit}).'**
  String pdaLanguageEmptinessCfgDerivationLimit(int limit);

  /// Internal consistency message for a mismatched CFG witness.
  ///
  /// In en, this message translates to:
  /// **'The reconstructed CFG derivation does not match its witness.'**
  String get pdaLanguageEmptinessCfgWitnessMismatch;

  /// Internal consistency message for a missing productive CFG choice.
  ///
  /// In en, this message translates to:
  /// **'No productive choice exists for {symbol} during derivation reconstruction.'**
  String pdaLanguageEmptinessCfgMissingProductiveChoice(String symbol);

  /// Structured input-validation message (TmEmpty).
  ///
  /// In en, this message translates to:
  /// **'The TM has no states.'**
  String get validationTmEmpty;

  /// Structured input-validation message (TmNoInitial).
  ///
  /// In en, this message translates to:
  /// **'The TM has no initial state.'**
  String get validationTmNoInitial;

  /// Structured input-validation message (TmInvalidInitial).
  ///
  /// In en, this message translates to:
  /// **'Initial state {state} is not in the state set.'**
  String validationTmInvalidInitial(String state);

  /// Structured input-validation message (TmNoAccepting).
  ///
  /// In en, this message translates to:
  /// **'The TM has no accepting states.'**
  String get validationTmNoAccepting;

  /// Structured input-validation message (TmEmptyInputAlphabet).
  ///
  /// In en, this message translates to:
  /// **'The TM has no input alphabet.'**
  String get validationTmEmptyInputAlphabet;

  /// Structured input-validation message (TmEmptyTapeAlphabet).
  ///
  /// In en, this message translates to:
  /// **'The TM has no tape alphabet.'**
  String get validationTmEmptyTapeAlphabet;

  /// Structured input-validation message (TmEmptyBlank).
  ///
  /// In en, this message translates to:
  /// **'The blank symbol is empty.'**
  String get validationTmEmptyBlank;

  /// Structured input-validation message (TmBlankNotInTape).
  ///
  /// In en, this message translates to:
  /// **'Blank symbol {symbol} is not in the tape alphabet.'**
  String validationTmBlankNotInTape(String symbol);

  /// Structured input-validation message (TmInputNotInTape).
  ///
  /// In en, this message translates to:
  /// **'Input symbol {symbol} is not in the tape alphabet.'**
  String validationTmInputNotInTape(String symbol);

  /// Structured input-validation message (TmInvalidAccepting).
  ///
  /// In en, this message translates to:
  /// **'Accepting state {state} is not in the state set.'**
  String validationTmInvalidAccepting(String state);

  /// Structured input-validation message (TmBadFrom).
  ///
  /// In en, this message translates to:
  /// **'Transition source state {state} is unknown.'**
  String validationTmBadFrom(String state);

  /// Structured input-validation message (TmBadTo).
  ///
  /// In en, this message translates to:
  /// **'Transition target state {state} is unknown.'**
  String validationTmBadTo(String state);

  /// Structured input-validation message (TmBadReadSymbol).
  ///
  /// In en, this message translates to:
  /// **'Transition reads symbol {symbol}, which is not in the tape alphabet.'**
  String validationTmBadReadSymbol(String symbol);

  /// Structured input-validation message (TmBadWriteSymbol).
  ///
  /// In en, this message translates to:
  /// **'Transition writes symbol {symbol}, which is not in the tape alphabet.'**
  String validationTmBadWriteSymbol(String symbol);

  /// Structured input-validation message (TmBadMove).
  ///
  /// In en, this message translates to:
  /// **'Transition has invalid move direction {direction}.'**
  String validationTmBadMove(String direction);

  /// Structured input-validation message (CfgEmpty).
  ///
  /// In en, this message translates to:
  /// **'The grammar has no productions.'**
  String get validationCfgEmpty;

  /// Structured input-validation message (CfgNoNonterminals).
  ///
  /// In en, this message translates to:
  /// **'The grammar has no nonterminals.'**
  String get validationCfgNoNonterminals;

  /// Structured input-validation message (CfgNoTerminals).
  ///
  /// In en, this message translates to:
  /// **'The grammar has no terminals.'**
  String get validationCfgNoTerminals;

  /// Structured input-validation message (CfgEmptyStart).
  ///
  /// In en, this message translates to:
  /// **'The start symbol is empty.'**
  String get validationCfgEmptyStart;

  /// Structured input-validation message (CfgBadStart).
  ///
  /// In en, this message translates to:
  /// **'Start symbol {symbol} must be a nonterminal.'**
  String validationCfgBadStart(String symbol);

  /// Structured input-validation message (CfgEmptyLeft).
  ///
  /// In en, this message translates to:
  /// **'Production {production} has an empty left side.'**
  String validationCfgEmptyLeft(int production);

  /// Structured input-validation message (CfgBadLeft).
  ///
  /// In en, this message translates to:
  /// **'Production {production} left side {symbol} is not a nonterminal.'**
  String validationCfgBadLeft(int production, String symbol);

  /// Structured input-validation message (CfgEmptyRight).
  ///
  /// In en, this message translates to:
  /// **'Production {production} has an empty right side.'**
  String validationCfgEmptyRight(int production);

  /// Structured input-validation message (CfgBadSymbol).
  ///
  /// In en, this message translates to:
  /// **'Production {production} contains unknown symbol {symbol}.'**
  String validationCfgBadSymbol(int production, String symbol);

  /// Structured input-validation message (InputEmpty).
  ///
  /// In en, this message translates to:
  /// **'The input string is empty.'**
  String get validationInputEmpty;

  /// Structured input-validation message (InputInvalidSymbol).
  ///
  /// In en, this message translates to:
  /// **'Input contains invalid symbol {symbol} at position {position}.'**
  String validationInputInvalidSymbol(String symbol, int position);

  /// Trace message when TM execution enters a reusable building-block machine.
  ///
  /// In en, this message translates to:
  /// **'Enter building-block machine {machine}.'**
  String tmBuildingBlockEnterBlock(String machine);

  /// Trace message when TM building-block execution applies a transition.
  ///
  /// In en, this message translates to:
  /// **'Apply transition {transition}.'**
  String tmBuildingBlockTransition(String transition);

  /// Trace message when TM execution returns from a building block.
  ///
  /// In en, this message translates to:
  /// **'Return from building-block machine {machine}.'**
  String tmBuildingBlockReturnFromBlock(String machine);

  /// Malformed FSA JFLAP document with an invalid XML root.
  ///
  /// In en, this message translates to:
  /// **'JFLAP XML root must be <structure>.'**
  String get codecFsaJflapInvalidRoot;

  /// FSA JFLAP codec rejected another document type.
  ///
  /// In en, this message translates to:
  /// **'JFLAP document type {type} is not an FSA document.'**
  String codecFsaJflapUnsupportedDocumentType(String type);

  /// FSA JFLAP codec rejected building-block content.
  ///
  /// In en, this message translates to:
  /// **'JFLAP building blocks require the dedicated TM codec.'**
  String get codecFsaJflapBuildingBlocksUnsupported;

  /// Malformed FSA JFLAP document without an automaton element.
  ///
  /// In en, this message translates to:
  /// **'JFLAP FSA is missing <automaton>.'**
  String get codecFsaJflapMissingAutomaton;

  /// Malformed FSA JFLAP state without an identifier.
  ///
  /// In en, this message translates to:
  /// **'JFLAP state is missing a non-empty ID.'**
  String get codecFsaJflapMissingStateId;

  /// Malformed FSA JFLAP document with a duplicate state identifier.
  ///
  /// In en, this message translates to:
  /// **'State {state} has a duplicate ID.'**
  String codecFsaJflapDuplicateStateId(String state);

  /// Malformed FSA JFLAP state with an invalid coordinate.
  ///
  /// In en, this message translates to:
  /// **'State {state} has an invalid coordinate.'**
  String codecFsaJflapInvalidStateCoordinate(String state);

  /// Unsupported FSA JFLAP document with multiple initial states.
  ///
  /// In en, this message translates to:
  /// **'The FSA contains multiple initial states.'**
  String get codecFsaJflapMultipleInitialStates;

  /// FSA JFLAP export rejected an invalid document.
  ///
  /// In en, this message translates to:
  /// **'The FSA document is invalid.'**
  String get codecFsaJflapInvalidDocument;

  /// FSA JFLAP export rejected an unsupported schema version.
  ///
  /// In en, this message translates to:
  /// **'FSA schema version {version} is not supported.'**
  String codecFsaJflapUnsupportedSchema(int version);

  /// FSA JFLAP codec called with another formal-system document.
  ///
  /// In en, this message translates to:
  /// **'The JFLAP codec requires an FSA document.'**
  String get codecFsaJflapRequiresFsaDocument;

  /// Informational FSA JFLAP import normalization diagnostic.
  ///
  /// In en, this message translates to:
  /// **'States and transitions were ordered canonically during import.'**
  String get codecFsaJflapCanonicalOrderImport;

  /// Informational FSA JFLAP export normalization diagnostic.
  ///
  /// In en, this message translates to:
  /// **'States and transitions were ordered canonically during export.'**
  String get codecFsaJflapCanonicalOrderExport;

  /// FSA JFLAP export dropped a Turing Lab state type.
  ///
  /// In en, this message translates to:
  /// **'State {state} uses a type that JFLAP FSA cannot store.'**
  String codecFsaJflapStateTypeDropped(String state);

  /// FSA JFLAP export dropped unsupported state properties.
  ///
  /// In en, this message translates to:
  /// **'State {state} has properties that JFLAP FSA cannot store.'**
  String codecFsaJflapStatePropertiesDropped(String state);

  /// FSA JFLAP export dropped a transition control point.
  ///
  /// In en, this message translates to:
  /// **'The control point of transition {transition} was dropped at {controlPoint}.'**
  String codecFsaJflapTransitionControlPointDropped(
    String transition,
    String controlPoint,
  );

  /// FSA JFLAP export dropped an unsupported transition display label.
  ///
  /// In en, this message translates to:
  /// **'The separate display label of transition {transition} was dropped.'**
  String codecFsaJflapTransitionDisplayLabelDropped(String transition);

  /// FSA JFLAP import interpreted an explicit epsilon alias.
  ///
  /// In en, this message translates to:
  /// **'The explicit epsilon alias {symbol} was interpreted as an empty read.'**
  String codecFsaJflapExplicitEpsilonAliasInterpreted(String symbol);

  /// FSA JFLAP export normalized explicit epsilon aliases.
  ///
  /// In en, this message translates to:
  /// **'Explicit epsilon aliases {aliases} were exported as empty reads for transition {transition}.'**
  String codecFsaJflapExplicitEpsilonAliasExportedEmpty(
    String aliases,
    String transition,
  );

  /// FSA JFLAP import expanded a multi-symbol transition.
  ///
  /// In en, this message translates to:
  /// **'Transition {transition} was expanded into {count} single-symbol transitions.'**
  String codecFsaJflapMultiSymbolTransitionExpanded(
    String transition,
    int count,
  );

  /// Informational FSA JFLAP diagnostic for an unknown optional element.
  ///
  /// In en, this message translates to:
  /// **'Unknown optional XML element {extension} was ignored.'**
  String codecFsaJflapUnknownOptionalElement(String extension);

  /// Informational FSA JFLAP diagnostic for an unknown optional attribute.
  ///
  /// In en, this message translates to:
  /// **'Unknown optional XML attribute {extension} was ignored.'**
  String codecFsaJflapUnknownOptionalAttribute(String extension);

  /// Grammar FIRST-set validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'FIRST cannot be computed because production LHS {nonTerminal} is not a declared non-terminal.'**
  String grammarAnalysisFirstProductionLhsUndeclared(String nonTerminal);

  /// Grammar FIRST-set derivation for an empty production.
  ///
  /// In en, this message translates to:
  /// **'FIRST({nonTerminal}) gains epsilon from an empty production.'**
  String grammarAnalysisFirstEpsilonEmptyProduction(String nonTerminal);

  /// Grammar FIRST-set derivation for a nullable production.
  ///
  /// In en, this message translates to:
  /// **'FIRST({nonTerminal}) gains epsilon because {production} contains epsilon.'**
  String grammarAnalysisFirstEpsilonProduction(
    String nonTerminal,
    String production,
  );

  /// Grammar FIRST-set derivation from a terminal production symbol.
  ///
  /// In en, this message translates to:
  /// **'FIRST({nonTerminal}) gains terminal {symbol} from {production}.'**
  String grammarAnalysisFirstTerminalProduction(
    String nonTerminal,
    String symbol,
    String production,
  );

  /// Grammar FIRST-set derivation that absorbs another FIRST set.
  ///
  /// In en, this message translates to:
  /// **'FIRST({nonTerminal}) absorbs FIRST({source}) minus epsilon via {production}.'**
  String grammarAnalysisFirstAbsorbsFirst(
    String nonTerminal,
    String source,
    String production,
  );

  /// Grammar FIRST-set derivation for an all-nullable production.
  ///
  /// In en, this message translates to:
  /// **'FIRST({nonTerminal}) gains epsilon because all symbols in {production} are nullable.'**
  String grammarAnalysisFirstEpsilonNullableProduction(
    String nonTerminal,
    String production,
  );

  /// Grammar FIRST-set analysis summary.
  ///
  /// In en, this message translates to:
  /// **'Computed FIRST sets for {count} non-terminals.'**
  String grammarAnalysisFirstSetsComputed(int count);

  /// Grammar FOLLOW-set validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'FOLLOW cannot be computed because start symbol {symbol} is not a declared non-terminal.'**
  String grammarAnalysisFollowStartSymbolUndeclared(String symbol);

  /// Grammar FOLLOW-set diagnostic for a missing start-symbol entry.
  ///
  /// In en, this message translates to:
  /// **'FOLLOW has no entry for start symbol {symbol}.'**
  String grammarAnalysisFollowStartSymbolMissingEntry(String symbol);

  /// Grammar FOLLOW-set derivation for the start symbol.
  ///
  /// In en, this message translates to:
  /// **'FOLLOW({symbol}) includes the end marker.'**
  String grammarAnalysisFollowStartIncludesEndMarker(String symbol);

  /// Grammar FOLLOW-set validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'FOLLOW cannot be computed because production LHS {nonTerminal} is not a declared non-terminal.'**
  String grammarAnalysisFollowProductionLhsUndeclared(String nonTerminal);

  /// Grammar FOLLOW-set derivation from a production suffix.
  ///
  /// In en, this message translates to:
  /// **'FOLLOW({nonTerminal}) gains {symbols} from the suffix in {production}.'**
  String grammarAnalysisFollowGainsFromSuffix(
    String nonTerminal,
    String symbols,
    String production,
  );

  /// Grammar FOLLOW-set derivation that absorbs another FOLLOW set.
  ///
  /// In en, this message translates to:
  /// **'FOLLOW({nonTerminal}) absorbs FOLLOW({source}) because the suffix in {production} is nullable.'**
  String grammarAnalysisFollowAbsorbsFollow(
    String nonTerminal,
    String source,
    String production,
  );

  /// Grammar FOLLOW-set analysis summary.
  ///
  /// In en, this message translates to:
  /// **'Computed FOLLOW sets for {count} non-terminals.'**
  String grammarAnalysisFollowSetsComputed(int count);

  /// Grammar left-recursion transformation processing order.
  ///
  /// In en, this message translates to:
  /// **'Processing non-terminals in order: {nonTerminals}.'**
  String grammarAnalysisProcessingOrder(String nonTerminals);

  /// Grammar left-recursion substitution note.
  ///
  /// In en, this message translates to:
  /// **'Substitute {production} using {via}.'**
  String grammarAnalysisSubstitutionNote(String production, String via);

  /// Grammar left-recursion substitution derivation.
  ///
  /// In en, this message translates to:
  /// **'Substitution of {production} yields {replacements}.'**
  String grammarAnalysisSubstitutionDerivation(
    String production,
    String replacements,
  );

  /// Grammar left-recursion transformation operation.
  ///
  /// In en, this message translates to:
  /// **'Substitute productions for {nonTerminal} via {via}.'**
  String grammarAnalysisSubstitutionOperation(String nonTerminal, String via);

  /// Grammar left-recursion transformation rationale.
  ///
  /// In en, this message translates to:
  /// **'Replace the leading {via} in {nonTerminal} with its current alternatives.'**
  String grammarAnalysisSubstitutionRationale(String nonTerminal, String via);

  /// Grammar left-recursion rationale for removing vacuous alternatives.
  ///
  /// In en, this message translates to:
  /// **'Remove vacuous {nonTerminal} to {nonTerminal} alternatives because they add no strings.'**
  String grammarAnalysisRemoveVacuousRecursionRationale(String nonTerminal);

  /// Grammar left-recursion derivation for vacuous alternatives.
  ///
  /// In en, this message translates to:
  /// **'Removed vacuous recursive alternatives: {productions}.'**
  String grammarAnalysisVacuousRecursionDerivation(String productions);

  /// Grammar left-recursion rationale for recursive-only productions.
  ///
  /// In en, this message translates to:
  /// **'Remove recursive-only alternatives for {nonTerminal} because they derive no terminal strings.'**
  String grammarAnalysisRecursiveOnlyRationale(String nonTerminal);

  /// Grammar left-recursion derivation for recursive-only productions.
  ///
  /// In en, this message translates to:
  /// **'Removed recursive-only alternatives for {nonTerminal}.'**
  String grammarAnalysisRecursiveOnlyDerivation(String nonTerminal);

  /// Grammar left-recursion note for an introduced helper non-terminal.
  ///
  /// In en, this message translates to:
  /// **'Introduced {introduced} to remove direct recursion from {nonTerminal}.'**
  String grammarAnalysisDirectRecursionIntroduced(
    String introduced,
    String nonTerminal,
  );

  /// Grammar left-recursion transformation rationale.
  ///
  /// In en, this message translates to:
  /// **'Move recursive suffixes of {nonTerminal} to {introduced} and add a terminating epsilon alternative.'**
  String grammarAnalysisMoveRecursiveSuffixesRationale(
    String nonTerminal,
    String introduced,
  );

  /// Grammar left-recursion derivation after rewriting direct recursion.
  ///
  /// In en, this message translates to:
  /// **'Rewrote direct recursion for {nonTerminal} using {introduced}.'**
  String grammarAnalysisDirectRecursionRewritten(
    String nonTerminal,
    String introduced,
  );

  /// Grammar left-recursion transformation operation.
  ///
  /// In en, this message translates to:
  /// **'Remove direct recursion from {nonTerminal}.'**
  String grammarAnalysisDirectRecursionOperation(String nonTerminal);

  /// Grammar left-recursion validation diagnostic when a cycle remains.
  ///
  /// In en, this message translates to:
  /// **'A left-corner cycle remains after transformation.'**
  String get grammarAnalysisLeftCornerCycleRemains;

  /// Grammar left-recursion transformation summary.
  ///
  /// In en, this message translates to:
  /// **'Left recursion was removed.'**
  String get grammarAnalysisLeftRecursionRemoved;

  /// Predictive grammar factoring transformation note.
  ///
  /// In en, this message translates to:
  /// **'Introduced non-terminal {introduced} to factor prefix {prefix} from {nonTerminal} ({productionCount} productions).'**
  String grammarPredictiveFactoringIntroduced(
    String introduced,
    String prefix,
    String nonTerminal,
    int productionCount,
  );

  /// Predictive grammar factoring derivation.
  ///
  /// In en, this message translates to:
  /// **'Factored {productionCount} productions of {nonTerminal} as {nonTerminal} → {prefix}{introduced}.'**
  String grammarPredictiveFactoringDerivation(
    int productionCount,
    String nonTerminal,
    String prefix,
    String introduced,
  );

  /// Predictive grammar factoring suffix derivation.
  ///
  /// In en, this message translates to:
  /// **'The remaining suffix for {introduced} is {suffix}.'**
  String grammarPredictiveFactoringSuffix(String introduced, String suffix);

  /// Predictive grammar factoring result with no required changes.
  ///
  /// In en, this message translates to:
  /// **'No common prefixes requiring factoring were found.'**
  String get grammarPredictiveNoFactoringNeeded;

  /// LL(1) table validation diagnostic for an undeclared production left side.
  ///
  /// In en, this message translates to:
  /// **'The production left side {nonTerminal} is not a declared non-terminal, so the LL(1) table cannot be built.'**
  String grammarPredictiveProductionLhsUndeclared(String nonTerminal);

  /// LL(1) table validation diagnostic for a missing row.
  ///
  /// In en, this message translates to:
  /// **'The LL(1) table has no row for non-terminal {nonTerminal}.'**
  String grammarPredictiveMissingTableRow(String nonTerminal);

  /// LL(1) table validation diagnostic for missing FOLLOW or table data.
  ///
  /// In en, this message translates to:
  /// **'The FOLLOW set or LL(1) table entry is missing for non-terminal {nonTerminal}.'**
  String grammarPredictiveMissingFollowOrTableEntry(String nonTerminal);

  /// LL(1) table derivation for a FIRST placement.
  ///
  /// In en, this message translates to:
  /// **'Placed {production} in LL(1) table[{nonTerminal}, {lookahead}] using FIRST.'**
  String grammarPredictiveTablePlacementFirst(
    String production,
    String nonTerminal,
    String lookahead,
  );

  /// LL(1) table derivation for a FOLLOW placement.
  ///
  /// In en, this message translates to:
  /// **'Placed {production} in LL(1) table[{nonTerminal}, {lookahead}] using FOLLOW.'**
  String grammarPredictiveTablePlacementFollow(
    String production,
    String nonTerminal,
    String lookahead,
  );

  /// LL(1) table construction summary.
  ///
  /// In en, this message translates to:
  /// **'Constructed an LL(1) parse table with {count} non-terminals.'**
  String grammarPredictiveTableConstructed(int count);

  /// LL(1) table result with no conflicts.
  ///
  /// In en, this message translates to:
  /// **'No conflicts were detected in the LL(1) parse table.'**
  String get grammarPredictiveTableNoConflicts;

  /// LL(1) table result with conflicts.
  ///
  /// In en, this message translates to:
  /// **'Detected {count} conflict(s) in the LL(1) parse table.'**
  String grammarPredictiveTableConflictsDetected(int count);

  /// Grammar JFLAP codec rejected another document type.
  ///
  /// In en, this message translates to:
  /// **'JFLAP document type {type} is not a grammar document.'**
  String codecGrammarJflapUnsupportedDocumentType(String type);

  /// Malformed JFLAP grammar without productions.
  ///
  /// In en, this message translates to:
  /// **'The JFLAP grammar contains no productions.'**
  String get codecGrammarJflapEmptyGrammar;

  /// Malformed JFLAP grammar production with a missing side.
  ///
  /// In en, this message translates to:
  /// **'Production {index} is missing a non-empty left or right side.'**
  String codecGrammarJflapMissingProductionSide(int index);

  /// Grammar JFLAP codec could not determine a start symbol.
  ///
  /// In en, this message translates to:
  /// **'The grammar start symbol could not be determined.'**
  String get codecGrammarJflapStartSymbolUndetermined;

  /// JFLAP grammar diagnostic for preserved unknown grammar type.
  ///
  /// In en, this message translates to:
  /// **'Unknown grammar type {type} was preserved for re-export.'**
  String codecGrammarJflapUnknownGrammarTypePreserved(String type);

  /// JFLAP grammar diagnostic for preserved optional XML data.
  ///
  /// In en, this message translates to:
  /// **'Unknown optional XML data {extension} was preserved with provenance.'**
  String codecGrammarJflapUnknownOptionalElement(String extension);

  /// JFLAP grammar import tokenization diagnostic.
  ///
  /// In en, this message translates to:
  /// **'JFLAP grammar text was normalized to token arrays.'**
  String get codecGrammarJflapTokenizationNormalized;

  /// Grammar JFLAP codec called with another formal-system document.
  ///
  /// In en, this message translates to:
  /// **'The Grammar JFLAP codec requires a Grammar document.'**
  String get codecGrammarJflapRequiresGrammarDocument;

  /// Grammar JFLAP codec rejected an unsupported schema version.
  ///
  /// In en, this message translates to:
  /// **'Grammar schema version {version} is not supported.'**
  String codecGrammarJflapUnsupportedSchema(int version);

  /// Grammar JFLAP export rejected an invalid document.
  ///
  /// In en, this message translates to:
  /// **'The Grammar document is invalid.'**
  String get codecGrammarJflapInvalidDocument;

  /// JFLAP grammar export lost multi-character token boundaries.
  ///
  /// In en, this message translates to:
  /// **'Token boundaries {tokens} cannot be preserved in JFLAP grammar XML.'**
  String codecGrammarJflapTokenBoundariesLossy(String tokens);

  /// JFLAP grammar export lost explicit grammar classification.
  ///
  /// In en, this message translates to:
  /// **'Grammar classification {classification} cannot be preserved in JFLAP XML.'**
  String codecGrammarJflapClassificationLossy(String classification);

  /// Malformed L-system JFLAP document with an invalid XML root.
  ///
  /// In en, this message translates to:
  /// **'The L-system JFLAP document must have a <structure> root.'**
  String get codecLSystemJflapInvalidRoot;

  /// L-system JFLAP codec rejected another document type.
  ///
  /// In en, this message translates to:
  /// **'JFLAP document type {type} is not an L-system document.'**
  String codecLSystemJflapUnsupportedDocumentType(String type);

  /// Malformed L-system JFLAP document without an axiom.
  ///
  /// In en, this message translates to:
  /// **'The JFLAP L-system document is missing an axiom.'**
  String get codecLSystemJflapMissingAxiom;

  /// Malformed XML encountered while reading an L-system document.
  ///
  /// In en, this message translates to:
  /// **'The L-system JFLAP XML is malformed.'**
  String get codecLSystemJflapMalformedXml;

  /// L-system JFLAP payload with invalid UTF-8.
  ///
  /// In en, this message translates to:
  /// **'The L-system JFLAP document is not valid UTF-8.'**
  String get codecLSystemJflapInvalidUtf8;

  /// L-system production validation diagnostic for an empty predecessor.
  ///
  /// In en, this message translates to:
  /// **'An L-system production has an empty predecessor.'**
  String get codecLSystemJflapEmptyPredecessor;

  /// L-system production validation diagnostic for an invalid context predecessor.
  ///
  /// In en, this message translates to:
  /// **'The context-sensitive predecessor {production} is invalid.'**
  String codecLSystemJflapInvalidContextPredecessor(String production);

  /// L-system JFLAP parameter validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The L-system parameter {parameter} is invalid.'**
  String codecLSystemJflapInvalidParameter(String parameter);

  /// L-system JFLAP parameter validation diagnostic including the source value.
  ///
  /// In en, this message translates to:
  /// **'The L-system parameter {parameter} has invalid value {value}.'**
  String codecLSystemJflapInvalidParameterValue(String parameter, String value);

  /// L-system JFLAP extension validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The L-system extension {extension} is invalid.'**
  String codecLSystemJflapInvalidExtension(String extension);

  /// L-system JFLAP production metadata validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'L-system production metadata field {field} is invalid.'**
  String codecLSystemJflapInvalidProductionMetadata(String field);

  /// L-system JFLAP command-mapping validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The L-system command mapping is invalid.'**
  String get codecLSystemJflapInvalidCommandMapping;

  /// L-system JFLAP export rejected an invalid document.
  ///
  /// In en, this message translates to:
  /// **'The L-system document is invalid.'**
  String get codecLSystemJflapInvalidDocument;

  /// L-system JFLAP codec called with another formal-system document.
  ///
  /// In en, this message translates to:
  /// **'The JFLAP codec requires an L-system document.'**
  String get codecLSystemJflapRequiresLSystemDocument;

  /// L-system JFLAP codec rejected an unsupported schema version.
  ///
  /// In en, this message translates to:
  /// **'L-system schema version {version} is not supported.'**
  String codecLSystemJflapUnsupportedSchema(int version);

  /// L-system JFLAP decoding failure.
  ///
  /// In en, this message translates to:
  /// **'The L-system JFLAP document could not be decoded.'**
  String get codecLSystemJflapDecodeFailed;

  /// L-system JFLAP encoding failure.
  ///
  /// In en, this message translates to:
  /// **'The L-system could not be encoded as JFLAP XML.'**
  String get codecLSystemJflapEncodeFailed;

  /// L-system JFLAP diagnostic for preserved advanced variants.
  ///
  /// In en, this message translates to:
  /// **'Unsupported L-system variants {variants} were preserved for re-export.'**
  String codecLSystemJflapAdvancedVariantPreserved(String variants);

  /// L-system JFLAP diagnostic for preserved parameters.
  ///
  /// In en, this message translates to:
  /// **'L-system parameters {parameters} were preserved.'**
  String codecLSystemJflapParametersPreserved(String parameters);

  /// L-system JFLAP diagnostic for restored execution extensions.
  ///
  /// In en, this message translates to:
  /// **'L-system execution extensions {features} were restored.'**
  String codecLSystemJflapExecutionExtensionRestored(String features);

  /// L-system JFLAP diagnostic for preserved XML elements.
  ///
  /// In en, this message translates to:
  /// **'Additional L-system XML elements were preserved.'**
  String get codecLSystemJflapElementsPreserved;

  /// L-system JFLAP diagnostic for execution extensions.
  ///
  /// In en, this message translates to:
  /// **'L-system execution extension details {features} are stored in Turing Lab parameters.'**
  String codecLSystemJflapExecutionExtension(String features);

  /// L-system JFLAP diagnostic for advanced variant extensions.
  ///
  /// In en, this message translates to:
  /// **'Advanced L-system variants {variants} are stored in the Turing Lab extension.'**
  String codecLSystemJflapAdvancedVariantExtension(String variants);

  /// Versioned JSON payload with invalid UTF-8.
  ///
  /// In en, this message translates to:
  /// **'The JSON document is not valid UTF-8.'**
  String get codecVersionedJsonInvalidUtf8;

  /// Versioned JSON payload with an invalid root value.
  ///
  /// In en, this message translates to:
  /// **'The JSON document root must be an object.'**
  String get codecVersionedJsonRootMustBeObject;

  /// Versioned JSON syntax diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The JSON document is malformed.'**
  String get codecVersionedJsonMalformedJson;

  /// Versioned JSON codec rejected an unknown document payload.
  ///
  /// In en, this message translates to:
  /// **'The JSON payload is not a recognized Turing Lab document.'**
  String get codecVersionedJsonUnsupportedDocument;

  /// Versioned JSON migration diagnostic for an unversioned payload.
  ///
  /// In en, this message translates to:
  /// **'Legacy JSON was migrated to the current document envelope.'**
  String get codecVersionedJsonLegacyEnvelopeMigrated;

  /// Versioned JSON diagnostic for preserved unknown data.
  ///
  /// In en, this message translates to:
  /// **'Unknown {scope} field {field} was preserved.'**
  String codecVersionedJsonUnknownFieldPreserved(String scope, String field);

  /// Versioned JSON envelope version validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The JSON envelope version must be a positive integer.'**
  String get codecVersionedJsonEnvelopeVersionInvalid;

  /// Versioned JSON codec rejected an unsupported envelope version.
  ///
  /// In en, this message translates to:
  /// **'JSON envelope version {version} is not supported.'**
  String codecVersionedJsonUnsupportedEnvelopeVersion(int version);

  /// Versioned JSON envelope missing document diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The JSON envelope is missing its document object.'**
  String get codecVersionedJsonMissingDocument;

  /// Versioned JSON envelope document identity mismatch.
  ///
  /// In en, this message translates to:
  /// **'The JSON envelope does not describe the expected {system} document.'**
  String codecVersionedJsonDocumentKeyMismatch(String system);

  /// Versioned JSON envelope missing schema diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The JSON envelope is missing its schema object.'**
  String get codecVersionedJsonMissingSchema;

  /// Versioned JSON schema identity validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The JSON envelope schema identity is invalid.'**
  String get codecVersionedJsonSchemaIdentityInvalid;

  /// Versioned JSON codec rejected an unsupported document schema version.
  ///
  /// In en, this message translates to:
  /// **'JSON schema version {version} is not supported.'**
  String codecVersionedJsonUnsupportedSchemaVersion(int version);

  /// Versioned JSON envelope missing payload diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The JSON envelope is missing its payload object.'**
  String get codecVersionedJsonMissingPayload;

  /// Versioned JSON source metadata validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The JSON source metadata must be an object.'**
  String get codecVersionedJsonSourceMetadataInvalid;

  /// Versioned JSON source metadata field validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'JSON source field {field} must be a string.'**
  String codecVersionedJsonSourceFieldInvalid(String field);

  /// Versioned JSON extensions validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The JSON extensions value must be an object.'**
  String get codecVersionedJsonExtensionsInvalid;

  /// Versioned JSON schema migration path diagnostic.
  ///
  /// In en, this message translates to:
  /// **'No JSON migration path exists from schema version {version}.'**
  String codecVersionedJsonMigrationPathMissing(int version);

  /// Versioned JSON migration rejected a payload value.
  ///
  /// In en, this message translates to:
  /// **'The JSON schema migration rejected the payload.'**
  String get codecVersionedJsonMigrationRejected;

  /// Versioned JSON migration invalid-value diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The JSON schema migration received an invalid value.'**
  String get codecVersionedJsonMigrationInvalidValue;

  /// Versioned JSON migration failure diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The JSON schema migration failed.'**
  String get codecVersionedJsonMigrationFailed;

  /// Versioned JSON schema migration progress diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The JSON payload was migrated from schema {from} to schema {to}.'**
  String codecVersionedJsonSchemaMigrated(int from, int to);

  /// Versioned JSON extension-key validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'JSON extension keys must be strings.'**
  String get codecVersionedJsonExtensionKeysInvalid;

  /// Versioned JSON payload type diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The JSON document payload contains an invalid value type.'**
  String get codecVersionedJsonPayloadValueTypeInvalid;

  /// Versioned JSON model decoder value diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The JSON document decoder received an invalid value.'**
  String get codecVersionedJsonDecoderValueTypeInvalid;

  /// Versioned JSON model decoder failure diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The JSON document model could not be decoded.'**
  String get codecVersionedJsonDecoderFailed;

  /// Versioned JSON encoder document identity mismatch.
  ///
  /// In en, this message translates to:
  /// **'This JSON codec cannot encode the {system} document.'**
  String codecVersionedJsonEncodeDocumentMismatch(String system);

  /// Versioned JSON encoder schema validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The JSON document schema version is not supported for export.'**
  String get codecVersionedJsonEncodeSchemaUnsupported;

  /// Versioned JSON encoder value diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The document contains data that cannot be represented as JSON.'**
  String get codecVersionedJsonEncodeValueInvalid;

  /// Versioned JSON model encoder failure diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The JSON document model could not be encoded.'**
  String get codecVersionedJsonEncoderFailed;

  /// Versioned JSON export source metadata normalization diagnostic.
  ///
  /// In en, this message translates to:
  /// **'Source metadata was normalized for the exported JSON document.'**
  String get codecVersionedJsonSourceMetadataNormalized;

  /// Versioned JSON export unknown-field sidecar diagnostic.
  ///
  /// In en, this message translates to:
  /// **'Unknown JSON fields were emitted in the extension sidecar.'**
  String get codecVersionedJsonUnknownFieldsSidecarNormalized;

  /// Versioned JSON envelope serialization failure diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The JSON document envelope could not be serialized.'**
  String get codecVersionedJsonEnvelopeSerializationFailed;

  /// Regex JFLAP codec rejected a non-regex document.
  ///
  /// In en, this message translates to:
  /// **'The JFLAP payload is not a regular-expression document.'**
  String get codecRegexJflapUnsupportedDocument;

  /// Regex JFLAP document validation found multiple expressions.
  ///
  /// In en, this message translates to:
  /// **'The JFLAP document contains multiple regular expressions.'**
  String get codecRegexJflapMultipleExpressions;

  /// Regex JFLAP document validation found duplicate extensions.
  ///
  /// In en, this message translates to:
  /// **'The JFLAP document contains multiple Turing Lab extensions.'**
  String get codecRegexJflapMultipleExtensions;

  /// Regex JFLAP extension validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The Turing Lab regular-expression extension is invalid.'**
  String get codecRegexJflapInvalidExtension;

  /// Regex JFLAP extension disagrees with the canonical source.
  ///
  /// In en, this message translates to:
  /// **'The Turing Lab regular-expression extension does not match the source.'**
  String get codecRegexJflapExtensionMismatch;

  /// Regex JFLAP import normalization diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The regular expression dialect was normalized during import.'**
  String get codecRegexJflapDialectNormalized;

  /// Regex JFLAP codec rejected an unsupported expression feature.
  ///
  /// In en, this message translates to:
  /// **'The regular expression uses an unsupported feature: {feature}.'**
  String codecRegexJflapUnsupportedFeature(String feature);

  /// Regex JFLAP export rejected an invalid document.
  ///
  /// In en, this message translates to:
  /// **'The regular-expression document is invalid.'**
  String get codecRegexJflapInvalidDocument;

  /// Regex JFLAP parsing failed because the document is malformed.
  ///
  /// In en, this message translates to:
  /// **'The regular-expression JFLAP document is malformed.'**
  String get codecRegexJflapMalformedDocument;

  /// Regex JFLAP codec called with another formal-system document.
  ///
  /// In en, this message translates to:
  /// **'The JFLAP codec requires a regular-expression document.'**
  String get codecRegexJflapExpectedRegexDocument;

  /// Regex JFLAP export portability diagnostic.
  ///
  /// In en, this message translates to:
  /// **'Turing Lab regular-expression extension data cannot be represented in JFLAP and was dropped.'**
  String get codecRegexJflapTuringLabExtensionPortability;

  /// Regex JFLAP empty-set interoperability diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The empty-set symbol was normalized for JFLAP interoperability.'**
  String get codecRegexJflapEmptySetInteroperability;

  /// Regex JFLAP parser found unbalanced parentheses.
  ///
  /// In en, this message translates to:
  /// **'JFLAP regular-expression parentheses are unbalanced.'**
  String get codecRegexJflapUnbalancedParentheses;

  /// Regex JFLAP parser found malformed operators.
  ///
  /// In en, this message translates to:
  /// **'JFLAP regular-expression operators are malformed.'**
  String get codecRegexJflapMalformedOperators;

  /// Regex JFLAP parser found a union without an operand.
  ///
  /// In en, this message translates to:
  /// **'JFLAP regular-expression union is missing an operand.'**
  String get codecRegexJflapUnionMissingOperand;

  /// Regex JFLAP parser rejected epsilon on the left side of concatenation.
  ///
  /// In en, this message translates to:
  /// **'JFLAP epsilon cannot be concatenated on its left.'**
  String get codecRegexJflapEpsilonLeftConcatenation;

  /// Regex JFLAP parser rejected epsilon on the right side of concatenation.
  ///
  /// In en, this message translates to:
  /// **'JFLAP epsilon cannot be concatenated on its right.'**
  String get codecRegexJflapEpsilonRightConcatenation;

  /// Regex JFLAP parser found an escape without a symbol.
  ///
  /// In en, this message translates to:
  /// **'JFLAP regular-expression escape must be followed by a symbol.'**
  String get codecRegexJflapEscapeMissingSymbol;

  /// Regex JFLAP parser rejected invalid source text.
  ///
  /// In en, this message translates to:
  /// **'The regular-expression source is invalid.'**
  String get codecRegexJflapInvalidSource;

  /// Regex JSON decoder value-type diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The regular-expression JSON decoder received an unexpected value type.'**
  String get codecRegexJsonUnexpectedDecoderType;

  /// Regex JSON source-of-truth validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The regular-expression JSON source of truth is invalid.'**
  String get codecRegexJsonSourceOfTruthInvalid;

  /// Regex JSON canonical AST consistency diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The regular-expression JSON source does not match its canonical AST.'**
  String get codecRegexJsonCanonicalAstMismatch;

  /// Regex JSON codec called with another formal-system document.
  ///
  /// In en, this message translates to:
  /// **'The JSON codec requires a regular-expression document.'**
  String get codecRegexJsonExpectedRegexDocument;

  /// Regex JSON export rejected an invalid document.
  ///
  /// In en, this message translates to:
  /// **'The regular-expression JSON document is invalid.'**
  String get codecRegexJsonInvalidDocument;

  /// Regex JSON codec rejected an unsupported dialect.
  ///
  /// In en, this message translates to:
  /// **'The regular-expression JSON dialect is not supported.'**
  String get codecRegexJsonUnsupportedDialect;

  /// Regex JSON parser rejected invalid source text.
  ///
  /// In en, this message translates to:
  /// **'The regular-expression JSON source is invalid.'**
  String get codecRegexJsonInvalidSource;

  /// Regex JSON codec received an unexpected validation result.
  ///
  /// In en, this message translates to:
  /// **'The regular-expression JSON validation returned an unexpected outcome.'**
  String get codecRegexJsonUnexpectedValidationOutcome;

  /// PDA JFLAP payload with invalid UTF-8.
  ///
  /// In en, this message translates to:
  /// **'The PDA JFLAP document is not valid UTF-8.'**
  String get codecPdaJflapInvalidUtf8;

  /// Malformed PDA JFLAP XML.
  ///
  /// In en, this message translates to:
  /// **'The PDA JFLAP XML is malformed.'**
  String get codecPdaJflapMalformedXml;

  /// PDA JFLAP document with an invalid XML root.
  ///
  /// In en, this message translates to:
  /// **'The PDA JFLAP XML root must be <structure>.'**
  String get codecPdaJflapInvalidRoot;

  /// PDA JFLAP codec rejected another document type.
  ///
  /// In en, this message translates to:
  /// **'JFLAP document type {type} is not a PDA document.'**
  String codecPdaJflapUnsupportedDocumentType(String type);

  /// Malformed PDA JFLAP document without an automaton.
  ///
  /// In en, this message translates to:
  /// **'The JFLAP PDA document is missing <automaton>.'**
  String get codecPdaJflapMissingAutomaton;

  /// PDA JFLAP state identity validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'A PDA JFLAP state is missing a non-empty ID.'**
  String get codecPdaJflapMissingStateId;

  /// PDA JFLAP duplicate state identity diagnostic.
  ///
  /// In en, this message translates to:
  /// **'PDA state {state} has a duplicate ID.'**
  String codecPdaJflapDuplicateStateId(String state);

  /// PDA JFLAP state coordinate validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'PDA state {state} has an invalid coordinate.'**
  String codecPdaJflapInvalidStateCoordinate(String state);

  /// PDA JFLAP document validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The PDA document is invalid.'**
  String get codecPdaJflapInvalidDocument;

  /// PDA JFLAP transition endpoint validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'A PDA transition references unknown states {from} and {to}.'**
  String codecPdaJflapUnknownTransitionEndpoints(String from, String to);

  /// PDA JFLAP transition identity validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The PDA transition ID is invalid.'**
  String get codecPdaJflapInvalidTransitionId;

  /// PDA JFLAP duplicate transition identity diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The PDA transition ID is duplicated.'**
  String get codecPdaJflapDuplicateTransitionId;

  /// PDA JFLAP acceptance-mode validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The PDA acceptance mode is invalid.'**
  String get codecPdaJflapInvalidAcceptanceMode;

  /// Malformed PDA JFLAP extension.
  ///
  /// In en, this message translates to:
  /// **'The Turing Lab PDA extension is malformed.'**
  String get codecPdaJflapMalformedExtension;

  /// PDA JFLAP import canonical-order diagnostic.
  ///
  /// In en, this message translates to:
  /// **'PDA states and transitions were ordered canonically during import.'**
  String get codecPdaJflapCanonicalOrderImport;

  /// PDA JFLAP stale token-extension diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The PDA token extension was stale and was ignored.'**
  String get codecPdaJflapStaleTokenExtension;

  /// PDA JFLAP epsilon alias normalization diagnostic.
  ///
  /// In en, this message translates to:
  /// **'An explicit epsilon alias was interpreted as an empty input.'**
  String get codecPdaJflapExplicitEpsilonAliasInterpreted;

  /// PDA JFLAP stack-token normalization diagnostic.
  ///
  /// In en, this message translates to:
  /// **'A multi-character pop word was treated as one stack token.'**
  String get codecPdaJflapPopWordTreatedAsAtomicToken;

  /// PDA JFLAP acceptance-mode inference diagnostic.
  ///
  /// In en, this message translates to:
  /// **'JFLAP acceptance mode was assumed to be final-state mode.'**
  String get codecPdaJflapAcceptanceModeAssumedFinalState;

  /// PDA JFLAP codec called with another formal-system document.
  ///
  /// In en, this message translates to:
  /// **'The JFLAP codec requires a PDA document.'**
  String get codecPdaJflapRequiresPdaDocument;

  /// PDA JFLAP codec rejected an unsupported schema version.
  ///
  /// In en, this message translates to:
  /// **'PDA schema version {version} is not supported.'**
  String codecPdaJflapUnsupportedSchema(int version);

  /// PDA JFLAP export portability diagnostic.
  ///
  /// In en, this message translates to:
  /// **'PDA extension data cannot be represented in standard JFLAP and was dropped.'**
  String get codecPdaJflapExtensionPortability;

  /// PDA JFLAP initial-stack-symbol portability diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The PDA initial stack symbol is not portable to standard JFLAP.'**
  String get codecPdaJflapInitialStackSymbolNotPortable;

  /// PDA JFLAP acceptance-mode portability diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The PDA acceptance mode is not portable to standard JFLAP.'**
  String get codecPdaJflapAcceptanceModeNotPortable;

  /// PDA JFLAP pop-token portability diagnostic.
  ///
  /// In en, this message translates to:
  /// **'An atomic PDA pop token is not portable to standard JFLAP.'**
  String get codecPdaJflapAtomicPopTokenNotPortable;

  /// PDA JFLAP push-token portability diagnostic.
  ///
  /// In en, this message translates to:
  /// **'An atomic PDA push token is not portable to standard JFLAP.'**
  String get codecPdaJflapAtomicPushTokenNotPortable;

  /// PDA JFLAP diagnostic for an unknown optional element.
  ///
  /// In en, this message translates to:
  /// **'Unknown optional XML element {extension} was preserved.'**
  String codecPdaJflapUnknownOptionalElement(String extension);

  /// PDA JFLAP diagnostic for an unknown optional attribute.
  ///
  /// In en, this message translates to:
  /// **'Unknown optional XML attribute {extension} was preserved.'**
  String codecPdaJflapUnknownOptionalAttribute(String extension);

  /// PDA JFLAP note-position diagnostic.
  ///
  /// In en, this message translates to:
  /// **'A PDA note has an invalid position.'**
  String get codecPdaJflapInvalidNotePosition;

  /// PDA JFLAP note normalization diagnostic.
  ///
  /// In en, this message translates to:
  /// **'PDA notes were normalized during import.'**
  String get codecPdaJflapNotesNormalized;

  /// PDA JFLAP note presentation portability diagnostic.
  ///
  /// In en, this message translates to:
  /// **'PDA note presentation data was dropped.'**
  String get codecPdaJflapNotePresentationDropped;

  /// PDA JFLAP fallback diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The PDA document contains an unknown diagnostic.'**
  String get codecPdaJflapUnknownDiagnostic;

  /// PDA JSON decoder document-type diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The PDA JSON decoder returned an unexpected document type.'**
  String get codecPdaJsonUnexpectedDocumentType;

  /// PDA JSON document validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The PDA JSON document is invalid.'**
  String get codecPdaJsonInvalidDocument;

  /// TM JFLAP payload with invalid UTF-8.
  ///
  /// In en, this message translates to:
  /// **'The TM JFLAP document is not valid UTF-8.'**
  String get codecTmJflapInvalidUtf8;

  /// Malformed TM JFLAP XML.
  ///
  /// In en, this message translates to:
  /// **'The TM JFLAP XML is malformed.'**
  String get codecTmJflapMalformedXml;

  /// TM JFLAP document with an invalid XML root.
  ///
  /// In en, this message translates to:
  /// **'The TM JFLAP XML root must be <structure>.'**
  String get codecTmJflapInvalidRoot;

  /// TM JFLAP codec rejected another document type.
  ///
  /// In en, this message translates to:
  /// **'JFLAP document type {type} is not a Turing machine document.'**
  String codecTmJflapUnsupportedDocumentType(String type);

  /// TM JFLAP codec rejected an unsupported feature.
  ///
  /// In en, this message translates to:
  /// **'The TM JFLAP document uses an unsupported feature.'**
  String get codecTmJflapUnsupportedFeature;

  /// TM JFLAP tape-count validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The TM tape count is invalid.'**
  String get codecTmJflapInvalidTapeCount;

  /// Malformed TM JFLAP document without an automaton.
  ///
  /// In en, this message translates to:
  /// **'The TM JFLAP document is missing <automaton>.'**
  String get codecTmJflapMissingAutomaton;

  /// Malformed TM JFLAP extension.
  ///
  /// In en, this message translates to:
  /// **'The Turing Lab TM extension is malformed.'**
  String get codecTmJflapMalformedExtension;

  /// TM JFLAP import canonical-order diagnostic.
  ///
  /// In en, this message translates to:
  /// **'TM states and transitions were ordered canonically during import.'**
  String get codecTmJflapCanonicalOrderImport;

  /// TM JFLAP export canonical-order diagnostic.
  ///
  /// In en, this message translates to:
  /// **'TM states and transitions were ordered canonically during export.'**
  String get codecTmJflapCanonicalOrderExport;

  /// TM JFLAP variant validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The TM variant does not match the document.'**
  String get codecTmJflapVariantMismatch;

  /// TM JFLAP tape-count consistency diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The TM tape count does not match the document.'**
  String get codecTmJflapTapeCountMismatch;

  /// TM JFLAP blank-symbol validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The TM blank symbol is invalid.'**
  String get codecTmJflapBlankSymbolInvalid;

  /// TM JFLAP acceptance-policy validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The TM acceptance policy is invalid.'**
  String get codecTmJflapAcceptancePolicyInvalid;

  /// TM JFLAP incomplete extension diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The Turing Lab TM extension is incomplete.'**
  String get codecTmJflapIncompleteExtension;

  /// TM JFLAP extension-schema validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The Turing Lab TM extension schema is invalid.'**
  String get codecTmJflapExtensionSchemaInvalid;

  /// TM JFLAP state identity validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'A TM JFLAP state is missing a non-empty ID.'**
  String get codecTmJflapMissingStateId;

  /// TM JFLAP duplicate state identity diagnostic.
  ///
  /// In en, this message translates to:
  /// **'TM state {state} has a duplicate ID.'**
  String codecTmJflapDuplicateStateId(String state);

  /// TM JFLAP state coordinate validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'TM state {state} has an invalid coordinate.'**
  String codecTmJflapInvalidStateCoordinate(String state);

  /// TM JFLAP state-type validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'TM state {state} has an invalid type.'**
  String codecTmJflapInvalidStateType(String state);

  /// TM JFLAP state-properties validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'TM state {state} has invalid properties.'**
  String codecTmJflapInvalidStateProperties(String state);

  /// TM JFLAP initial-state validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The TM document must contain exactly one initial state.'**
  String get codecTmJflapInvalidInitialStateCount;

  /// TM JFLAP transition endpoint validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'A TM transition references unknown states {from} and {to}.'**
  String codecTmJflapUnknownTransitionEndpoints(String from, String to);

  /// TM JFLAP tape-index validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The TM tape index is invalid.'**
  String get codecTmJflapInvalidTapeIndex;

  /// TM JFLAP duplicate tape-operation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The TM transition contains a duplicate tape operation: {operation}.'**
  String codecTmJflapDuplicateTapeOperation(String operation);

  /// TM JFLAP unsupported read-predicate diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The TM read predicate is not supported by JFLAP.'**
  String get codecTmJflapUnsupportedReadPredicate;

  /// TM JFLAP read-symbol validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The TM read symbol is invalid.'**
  String get codecTmJflapInvalidReadSymbol;

  /// TM JFLAP write-symbol validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The TM write symbol is invalid.'**
  String get codecTmJflapInvalidWriteSymbol;

  /// TM JFLAP movement validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The TM movement must be L, R, or S.'**
  String get codecTmJflapInvalidMove;

  /// TM JFLAP transition-extension validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The Turing Lab TM transition extension is invalid.'**
  String get codecTmJflapInvalidTransitionExtension;

  /// TM JFLAP transition identity validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The TM transition ID is invalid.'**
  String get codecTmJflapInvalidTransitionId;

  /// TM JFLAP duplicate transition identity diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The TM transition ID is duplicated.'**
  String get codecTmJflapDuplicateTransitionId;

  /// TM JFLAP transition-label validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'TM transition {transition} has an invalid label.'**
  String codecTmJflapInvalidTransitionLabel(String transition);

  /// TM JFLAP transition-type validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'TM transition {transition} has an invalid type.'**
  String codecTmJflapInvalidTransitionType(String transition);

  /// TM JFLAP transition control-point validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'A TM transition has an invalid control point.'**
  String get codecTmJflapInvalidControlPoint;

  /// TM JFLAP transition identity reconstruction diagnostic.
  ///
  /// In en, this message translates to:
  /// **'TM transition identities were reconstructed during import.'**
  String get codecTmJflapTransitionIdentitiesReconstructed;

  /// TM JFLAP metadata validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The TM metadata is invalid.'**
  String get codecTmJflapInvalidMetadata;

  /// TM JFLAP document validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The TM document is invalid.'**
  String get codecTmJflapInvalidDocument;

  /// TM JFLAP codec called with another formal-system document.
  ///
  /// In en, this message translates to:
  /// **'The JFLAP codec requires a Turing machine document.'**
  String get codecTmJflapRequiresTmDocument;

  /// TM JFLAP codec rejected an unsupported schema version.
  ///
  /// In en, this message translates to:
  /// **'TM schema version {version} is not supported.'**
  String codecTmJflapUnsupportedSchema(int version);

  /// TM JFLAP unsupported tape-count diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The TM tape count is not supported.'**
  String get codecTmJflapUnsupportedTapeCount;

  /// TM JFLAP unsupported operation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'TM transition {transition} uses unsupported operation {operation} on {symbol}.'**
  String codecTmJflapUnsupportedOperation(
    String transition,
    String operation,
    String symbol,
  );

  /// TM building-block variant validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The building-block TM variant does not match its XML.'**
  String get codecTmJflapBuildingBlockVariantMismatch;

  /// TM building-block recursive-dependency diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The TM building blocks contain a recursive dependency at {block}.'**
  String codecTmJflapRecursiveDependency(String block);

  /// TM building-block missing-definition diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The TM building-block definition {block} is missing.'**
  String codecTmJflapMissingBlockDefinition(String block);

  /// TM building-block ambiguous-definition diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The TM building-block definition {block} is ambiguous.'**
  String codecTmJflapAmbiguousBlockDefinition(String block);

  /// TM building-block acceptance-policy conflict diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The TM root and machine acceptance policies conflict.'**
  String get codecTmJflapAcceptancePolicyConflict;

  /// TM building-block machine-schema validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The building-block machine has an invalid Turing Lab schema.'**
  String get codecTmJflapMachineSchemaInvalid;

  /// TM building-block machine-variant validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The building-block machine has an invalid TM variant.'**
  String get codecTmJflapMachineVariantInvalid;

  /// TM building-block machine tape-count validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The building-block machine has a mismatched tape count.'**
  String get codecTmJflapMachineTapeCountMismatch;

  /// TM building-block machine blank-symbol validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The building-block machine has a mismatched blank symbol.'**
  String get codecTmJflapMachineBlankSymbolMismatch;

  /// TM building-block tag validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The TM block {block} is missing its tag.'**
  String codecTmJflapMissingBlockTag(String block);

  /// TM building-block node identity validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'A TM building-block node ID is invalid.'**
  String get codecTmJflapInvalidNodeId;

  /// TM building-block duplicate node identity diagnostic.
  ///
  /// In en, this message translates to:
  /// **'A TM building-block node ID is duplicated.'**
  String get codecTmJflapDuplicateNodeId;

  /// TM building-block node coordinate validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'TM node {node} has an invalid coordinate.'**
  String codecTmJflapInvalidNodeCoordinate(String node);

  /// TM building-block node state-type validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'TM node {node} has an invalid state type.'**
  String codecTmJflapInvalidNodeStateType(String node);

  /// TM building-block node-properties validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'TM node {node} has invalid properties.'**
  String codecTmJflapInvalidNodeProperties(String node);

  /// TM building-block tag-reference validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The TM building block {block} has no tag reference.'**
  String codecTmJflapMissingBlockTagReference(String block);

  /// TM building-block tape-index validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'A TM tape index is invalid or duplicated.'**
  String get codecTmJflapInvalidOrDuplicateTapeIndex;

  /// TM building-block transition identity conflict diagnostic.
  ///
  /// In en, this message translates to:
  /// **'TM transition identity extensions disagree.'**
  String get codecTmJflapTransitionIdentityConflict;

  /// TM JFLAP building-block import diagnostic.
  ///
  /// In en, this message translates to:
  /// **'TM building blocks were imported.'**
  String get codecTmJflapBuildingBlocksImported;

  /// TM JFLAP shared-tape diagnostic.
  ///
  /// In en, this message translates to:
  /// **'TM building blocks use shared tapes.'**
  String get codecTmJflapSharedTapes;

  /// TM JFLAP building-block extension portability diagnostic.
  ///
  /// In en, this message translates to:
  /// **'An unknown TM building-block extension was dropped.'**
  String get codecTmJflapUnknownBuildingBlockExtensionDropped;

  /// TM JFLAP building-block export diagnostic.
  ///
  /// In en, this message translates to:
  /// **'TM building blocks were exported.'**
  String get codecTmJflapBuildingBlocksExported;

  /// TM JFLAP extension identity diagnostic.
  ///
  /// In en, this message translates to:
  /// **'TM extension identities were normalized.'**
  String get codecTmJflapExtensionIdentities;

  /// TM JFLAP export portability diagnostic.
  ///
  /// In en, this message translates to:
  /// **'TM extension data cannot be represented in standard JFLAP and was dropped.'**
  String get codecTmJflapExtensionPortability;

  /// TM JFLAP diagnostic for an unknown optional element.
  ///
  /// In en, this message translates to:
  /// **'Unknown optional XML element {extension} was preserved.'**
  String codecTmJflapUnknownOptionalElement(String extension);

  /// TM JFLAP diagnostic for an unknown optional attribute.
  ///
  /// In en, this message translates to:
  /// **'Unknown optional XML attribute {extension} was preserved.'**
  String codecTmJflapUnknownOptionalAttribute(String extension);

  /// TM JFLAP note-position diagnostic.
  ///
  /// In en, this message translates to:
  /// **'A TM note has an invalid position.'**
  String get codecTmJflapInvalidNotePosition;

  /// TM JFLAP note normalization diagnostic.
  ///
  /// In en, this message translates to:
  /// **'TM notes were normalized during import.'**
  String get codecTmJflapNotesNormalized;

  /// TM JFLAP note presentation portability diagnostic.
  ///
  /// In en, this message translates to:
  /// **'TM note presentation data was dropped.'**
  String get codecTmJflapNotePresentationDropped;

  /// TM JFLAP fallback diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The TM document contains an unknown diagnostic.'**
  String get codecTmJflapUnknownDiagnostic;

  /// TM JSON decoder document-type diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The TM JSON decoder returned an unexpected document type.'**
  String get codecTmJsonUnexpectedDocumentType;

  /// TM JSON document validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The TM JSON document is invalid.'**
  String get codecTmJsonInvalidDocument;

  /// TM JSON variant validation diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The TM JSON variant does not match the document.'**
  String get codecTmJsonVariantMismatch;

  /// TM JSON variant migration diagnostic.
  ///
  /// In en, this message translates to:
  /// **'The TM variant was inferred from the JSON document.'**
  String get codecTmJsonVariantInferred;

  /// TM JSON operation-vector migration diagnostic.
  ///
  /// In en, this message translates to:
  /// **'TM operation vectors were migrated to the current format.'**
  String get codecTmJsonOperationVectorsMigrated;

  /// TM JSON endpoint identity migration diagnostic.
  ///
  /// In en, this message translates to:
  /// **'TM transition endpoints were migrated to stable IDs.'**
  String get codecTmJsonEndpointsMigratedToIds;
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
    'that was used.',
  );
}
