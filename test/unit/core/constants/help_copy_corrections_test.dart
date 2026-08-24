import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/core/constants/help_topic_ids.dart';
import 'package:turing_lab/l10n/help_catalog_copy_en.dart';
import 'package:turing_lab/l10n/help_catalog_copy_pt.dart';

void main() {
  test('English regex test-string copy names NFA simulation', () {
    final body = enHelpCatalogCopy[HelpTopicIds.regexEditorTestStrings]!.body;

    expect(body, contains('NFA simulation'));
    expect(body, isNot(contains('AFN simulation')));
  });

  test('parser availability copy uses user-facing language in both locales',
      () {
    for (final id in [
      HelpTopicIds.grammarEditorParserLl1,
      HelpTopicIds.grammarEditorParserLr,
    ]) {
      expect(enHelpCatalogCopy[id]!.body, isNot(contains('GrammarParser.')),
          reason: id);
      expect(ptHelpCatalogCopy[id]!.body, isNot(contains('GrammarParser.')),
          reason: id);
    }
  });

  test('developer topic directs the repository action to Licenses', () {
    final english =
        enHelpCatalogCopy[HelpTopicIds.aboutDeveloperAndProject]!.body;
    final portuguese =
        ptHelpCatalogCopy[HelpTopicIds.aboutDeveloperAndProject]!.body;

    expect(english, contains('Open Licenses'));
    expect(english, contains('Project repository'));
    expect(portuguese, contains('Abra Licenças'));
    expect(portuguese, contains('Repositório do projeto'));
  });

  test('left-recursion help covers direct and indirect cycles', () {
    final english = enHelpCatalogCopy[
        HelpTopicIds.grammarEditorAlgorithmsRemoveLeftRecursion]!;
    final portuguese = ptHelpCatalogCopy[
        HelpTopicIds.grammarEditorAlgorithmsRemoveLeftRecursion]!;

    expect(english.title, contains('direct and indirect'));
    expect(english.body, contains('ordered substitution'));
    expect(portuguese.title, contains('direta e indireta'));
    expect(portuguese.body, contains('substituições estáveis'));
  });

  test('time-profile help separates DTM time from NTM exploration', () {
    final english =
        enHelpCatalogCopy[HelpTopicIds.tmEditorAlgorithmsTime]!.body;
    final portuguese =
        ptHelpCatalogCopy[HelpTopicIds.tmEditorAlgorithmsTime]!.body;

    expect(english, contains('maximum transition steps'));
    expect(english, contains('exploration depth'));
    expect(english, contains('never deterministic time complexity'));
    expect(english, contains('do not infer a Big-O class'));
    expect(portuguese, contains('máximo de passos'));
    expect(portuguese, contains('profundidade de exploração'));
    expect(portuguese, contains('nunca como complexidade temporal'));
    expect(portuguese, contains('não inferem uma classe Big-O'));
  });
}
