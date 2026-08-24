import 'package:flutter/widgets.dart';

import '../core/constants/help_catalog.dart';
import 'app_localizations.dart';
import 'help_catalog_copy.dart';
import 'help_catalog_copy_en.dart';
import 'help_catalog_copy_pt.dart';
import 'help_localizations_en.dart';
import 'help_localizations_pt.dart';

AppLocalizations jflapLocalizationsOf(BuildContext context) {
  final localizations =
      Localizations.of<AppLocalizations>(context, AppLocalizations);
  if (localizations != null) {
    return localizations;
  }

  final locale = Localizations.maybeLocaleOf(context) ??
      WidgetsBinding.instance.platformDispatcher.locale;
  try {
    return lookupAppLocalizations(locale);
  } on FlutterError {
    return lookupAppLocalizations(const Locale('en'));
  }
}

extension AppHelpLocalizations on AppLocalizations {
  bool get _isPortuguese => localeName.startsWith('pt');

  HelpCatalogCopy get helpCatalogCopy => selectHelpCatalogCopy(
        localeName: localeName,
        english: enHelpCatalogCopy,
        portuguese: ptHelpCatalogCopy,
      );

  HelpNodeCopy? helpNodeCopy(String id) => helpCatalogCopy[id];

  bool hasCompleteHelpCopy(String id) {
    return kHelpCatalog.hasCompleteHelpCopy(helpCatalogCopy, id);
  }

  Map<String, String> get _uiCopy =>
      _isPortuguese ? ptHelpUiCopy : enHelpUiCopy;

  Map<String, String> get _helpArticleBodies =>
      _isPortuguese ? ptHelpArticleBodies : enHelpArticleBodies;

  String _copy(String key) => _uiCopy[key] ?? enHelpUiCopy[key] ?? key;

  String get homeHelpTooltip => _copy('homeHelpTooltip');
  String get homeSettingsTooltip => _copy('homeSettingsTooltip');
  String get helpPageTitle => _copy('helpPageTitle');
  String get helpSearchTooltip => _copy('helpSearchTooltip');
  String get helpQuickStartTitle => _copy('helpQuickStartTitle');
  String get helpQuickStartBody => _copy('helpQuickStartBody');
  String get helpGotIt => _copy('helpGotIt');
  String get helpSearchFieldLabel => _copy('helpSearchFieldLabel');
  String get helpSearchClear => _copy('helpSearchClear');
  String get helpSearchClose => _copy('helpSearchClose');
  String get helpSearchTitle => _copy('helpSearchTitle');
  String get helpSearchSubtitle => _copy('helpSearchSubtitle');
  String get helpSearchNoResults => _copy('helpSearchNoResults');
  String get helpSearchNoResultsDescription =>
      _copy('helpSearchNoResultsDescription');
  String helpDisclosureSemanticLabel(String title, {required bool expanded}) {
    final action = _copy(
      expanded ? 'helpDisclosureCollapse' : 'helpDisclosureExpand',
    );
    return '$action $title';
  }

  String get helpRelatedTopics => _copy('helpRelatedTopics');
  String get helpTopicUnavailable => _copy('helpTopicUnavailable');
  String get helpTopicUnavailableDescription =>
      _copy('helpTopicUnavailableDescription');
  String get contextualHelpPanelLabel => _copy('contextualHelpPanelLabel');
  String get closeHelpPanel => _copy('closeHelpPanel');
  String get close => _copy('close');
  String get viewAllRelatedHelp => _copy('viewAllRelatedHelp');
  String get moreHelp => _copy('moreHelp');
  String get helpCenter => _copy('helpCenter');
  String get workspaceSimulateTooltip => _copy('workspaceSimulateTooltip');
  String get workspaceAlgorithmsTooltip => _copy('workspaceAlgorithmsTooltip');
  String get workspaceParserTooltip => _copy('workspaceParserTooltip');
  String get workspaceEditTooltip => _copy('workspaceEditTooltip');
  String get grammarEmptyProductionEditInstruction =>
      _copy('grammarEmptyProductionEditInstruction');
  String get workspaceMetricsTooltip => _copy('workspaceMetricsTooltip');
  String get relatedConcepts => _copy('relatedConcepts');
  String get hideExamples => _copy('hideExamples');
  String get viewExamples => _copy('viewExamples');
  String get keyboardShortcutsDialogLabel =>
      _copy('keyboardShortcutsDialogLabel');
  String get keyboardShortcutsTitle => _copy('keyboardShortcutsTitle');
  String get keyboardShortcutsCanvasOperations =>
      _copy('keyboardShortcutsCanvasOperations');
  String get keyboardShortcutsSimulationControls =>
      _copy('keyboardShortcutsSimulationControls');
  String get keyboardShortcutsDialogShortcuts =>
      _copy('keyboardShortcutsDialogShortcuts');
  String get closeShortcutsDialog => _copy('closeShortcutsDialog');
  String get shortcutAlternativeSeparator =>
      _copy('shortcutAlternativeSeparator');
  String get aboutDeveloperLabel => _copy('aboutDeveloperLabel');
  String get aboutProjectRepositoryLabel =>
      _copy('aboutProjectRepositoryLabel');
  String get aboutProjectOpenError => _copy('aboutProjectOpenError');
  String get aboutOpenSourceLicenses => _copy('aboutOpenSourceLicenses');
  String get aboutLicensesIntro => _copy('aboutLicensesIntro');
  String get aboutTuringLabLicenseSummary =>
      _copy('aboutTuringLabLicenseSummary');
  String get aboutJflapLicenseSummary => _copy('aboutJflapLicenseSummary');
  String get aboutGraphViewLicenseSummary =>
      _copy('aboutGraphViewLicenseSummary');
  String get aboutAppleNoticesSummary => _copy('aboutAppleNoticesSummary');
  String get aboutAppleNoticesTitle => _copy('aboutAppleNoticesTitle');
  String get aboutPackageLicenses => _copy('aboutPackageLicenses');
  String get aboutPackageLicensesDescription =>
      _copy('aboutPackageLicensesDescription');
  String get aboutAcknowledgments => _copy('aboutAcknowledgments');
  String get aboutJflapCreator => _copy('aboutJflapCreator');
  String get aboutJflapTeam => _copy('aboutJflapTeam');
  String get aboutOriginalProject => _copy('aboutOriginalProject');
  String get aboutOriginalProjectTitle => _copy('aboutOriginalProjectTitle');
  String get aboutGraphViewFork => _copy('aboutGraphViewFork');
  String get aboutGraphViewForkTitle => _copy('aboutGraphViewForkTitle');
  String get aboutDistribution => _copy('aboutDistribution');
  String get aboutDistributionDescription =>
      _copy('aboutDistributionDescription');
  String get aboutLicenseExpandPrompt => _copy('aboutLicenseExpandPrompt');
  String get aboutLicenseLoading => _copy('aboutLicenseLoading');
  String aboutLicenseLoadFailed(Object error) =>
      '${_copy('aboutLicenseLoadFailed')}: $error';

  String homeNavigationLabel(String id) {
    return switch (id) {
      'fsa' => homeNavigationFsaLabel,
      'grammar' => homeNavigationGrammarLabel,
      'pda' => homeNavigationPdaLabel,
      'tm' => homeNavigationTmLabel,
      'regex' => homeNavigationRegexLabel,
      'pumping' => homeNavigationPumpingLabel,
      _ => id,
    };
  }

  String homeNavigationDescription(String id) {
    return switch (id) {
      'fsa' => homeNavigationFsaDescription,
      'grammar' => homeNavigationGrammarDescription,
      'pda' => homeNavigationPdaDescription,
      'tm' => homeNavigationTmDescription,
      'regex' => homeNavigationRegexDescription,
      'pumping' => homeNavigationPumpingDescription,
      _ => id,
    };
  }

  String helpSectionTitle(String id) {
    return switch (id) {
      'gettingStarted' => helpSectionGettingStarted,
      'fsa' => helpSectionFsa,
      'grammar' => helpSectionGrammar,
      'pda' => helpSectionPda,
      'tm' => helpSectionTm,
      'regex' => helpSectionRegex,
      'pumping' => helpSectionPumping,
      'fileOperations' => helpSectionFileOperations,
      'troubleshooting' => helpSectionTroubleshooting,
      'about' => helpSectionAbout,
      _ => id,
    };
  }

  String helpArticleBody(String id) =>
      _helpArticleBodies[id] ?? enHelpArticleBodies[id] ?? id;

  String helpSearchSuggestion(String id) {
    final suggestions =
        _isPortuguese ? ptHelpSearchSuggestions : enHelpSearchSuggestions;
    return suggestions[id] ?? enHelpSearchSuggestions[id] ?? id;
  }

  String helpSearchResultCount(int count) {
    if (_isPortuguese) {
      return count == 1 ? '1 resultado' : '$count resultados';
    }
    return count == 1 ? '1 result' : '$count results';
  }

  String helpTopicSemanticLabel(String title) {
    return _isPortuguese ? 'Tópico de ajuda: $title' : 'Help topic: $title';
  }

  String showHelpFor(String title) {
    return _isPortuguese
        ? 'Mostrar ajuda sobre $title'
        : 'Show help for $title';
  }

  String navigateTo(String label) {
    return _isPortuguese ? 'Navegar para $label' : 'Navigate to $label';
  }

  String unableToLoadHelp(String category) {
    if (_isPortuguese) {
      return 'Não foi possível carregar a ajuda para "$category".';
    }
    return 'Unable to load help for "$category".';
  }

  String noHelpItemsFound(String category) {
    if (_isPortuguese) {
      return 'Nenhum item de ajuda encontrado para "$category".';
    }
    return 'No help items found for "$category".';
  }

  String helpContentCategory(String category) {
    final categories = _isPortuguese ? ptHelpCategories : enHelpCategories;
    return categories[category] ?? enHelpCategories[category] ?? category;
  }
}
