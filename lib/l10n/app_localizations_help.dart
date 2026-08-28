import 'package:flutter/widgets.dart';

import '../core/constants/help_catalog.dart';
import 'app_localizations.dart';
import 'help_catalog_copy.dart';
import 'help_catalog_copy_en.dart';
import 'help_catalog_copy_pt.dart';
import 'help_localizations_en.dart';
import 'help_localizations_pt.dart';

AppLocalizations jflapLocalizationsOf(BuildContext context) {
  final localizations = Localizations.of<AppLocalizations>(
    context,
    AppLocalizations,
  );
  if (localizations != null) {
    return localizations;
  }

  final locale =
      Localizations.maybeLocaleOf(context) ??
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

  String helpDisclosureSemanticLabel(String title, {required bool expanded}) {
    return expanded
        ? helpDisclosureCollapseSemanticLabel(title)
        : helpDisclosureExpandSemanticLabel(title);
  }

  String get grammarEmptyProductionEditInstruction =>
      _copy('grammarEmptyProductionEditInstruction');
  String workspaceExampleLabel(String id, String fallback) {
    final key = switch (id) {
      'an-bn-cn' => 'unrestrictedGrammarExampleAnBnCn',
      'context-copying' => 'unrestrictedGrammarExampleContextCopying',
      'tm-generated' => 'unrestrictedGrammarExampleTmGenerated',
      'l-system.koch-curve' => 'lSystemExampleKochCurve',
      'l-system.sierpinski-triangle' => 'lSystemExampleSierpinskiTriangle',
      'l-system.dragon-curve' => 'lSystemExampleDragonCurve',
      'l-system.fractal-plant' => 'lSystemExampleFractalPlant',
      'l-system.branching-tree' => 'lSystemExampleBranchingTree',
      'l-system.seeded-context-turtle' => 'lSystemExampleSeededContextTurtle',
      _ => null,
    };
    return key == null ? fallback : _copy(key);
  }

  String get relatedConcepts => _copy('relatedConcepts');
  String get hideExamples => _copy('hideExamples');
  String get viewExamples => _copy('viewExamples');

  String homeNavigationLabel(String id) {
    return switch (id) {
      'fsa' => homeNavigationFsaLabel,
      'grammar' => homeNavigationGrammarLabel,
      'pda' => homeNavigationPdaLabel,
      'tm' => homeNavigationTmLabel,
      'regex' => homeNavigationRegexLabel,
      'pumping' => homeNavigationPumpingLabel,
      'regularPumping' => homeNavigationRegularPumpingLabel,
      'contextFreePumping' => homeNavigationContextFreePumpingLabel,
      'mealy' => homeNavigationMealyLabel,
      'moore' => homeNavigationMooreLabel,
      'unrestrictedGrammar' => homeNavigationUnrestrictedGrammarLabel,
      'lSystem' => homeNavigationLSystemLabel,
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
      'regularPumping' => homeNavigationRegularPumpingDescription,
      'contextFreePumping' => homeNavigationContextFreePumpingDescription,
      'mealy' => homeNavigationMealyDescription,
      'moore' => homeNavigationMooreDescription,
      'unrestrictedGrammar' => homeNavigationUnrestrictedGrammarDescription,
      'lSystem' => homeNavigationLSystemDescription,
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
      // These catalog roots are not generated section keys. Resolve their
      // titles from the locale-aware help copies instead of exposing IDs.
      'transducers' => helpNodeCopy(id)?.title ?? id,
      'extended-formal-systems' => helpNodeCopy(id)?.title ?? id,
      _ => id,
    };
  }

  String helpArticleBody(String id) =>
      _helpArticleBodies[id] ?? enHelpArticleBodies[id] ?? id;

  String helpSearchSuggestion(String id) {
    final suggestions = _isPortuguese
        ? ptHelpSearchSuggestions
        : enHelpSearchSuggestions;
    return suggestions[id] ?? enHelpSearchSuggestions[id] ?? id;
  }

  String helpContentCategory(String category) {
    final categories = _isPortuguese ? ptHelpCategories : enHelpCategories;
    return categories[category] ?? enHelpCategories[category] ?? category;
  }
}
