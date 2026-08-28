import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/core/constants/help_topic_ids.dart';
import 'package:turing_lab/core/models/help_content_block.dart';
import 'package:turing_lab/l10n/help_catalog_copy_en.dart';
import 'package:turing_lab/l10n/help_catalog_copy_pt.dart';

void main() {
  test('English regex test-string copy names NFA simulation', () {
    final body = enHelpCatalogCopy[HelpTopicIds.regexEditorTestStrings]!.body;

    expect(body, contains('NFA simulation'));
    expect(body, isNot(contains('AFN simulation')));
  });

  test(
    'parser availability copy uses user-facing language in both locales',
    () {
      for (final id in [
        HelpTopicIds.grammarEditorParserLl1,
        HelpTopicIds.grammarEditorParserLr,
      ]) {
        expect(
          enHelpCatalogCopy[id]!.body,
          isNot(contains('GrammarParser.')),
          reason: id,
        );
        expect(
          ptHelpCatalogCopy[id]!.body,
          isNot(contains('GrammarParser.')),
          reason: id,
        );
      }
    },
  );

  test('developer topic names the developer and public repository', () {
    final english =
        enHelpCatalogCopy[HelpTopicIds.aboutDeveloperAndProject]!.body;
    final portuguese =
        ptHelpCatalogCopy[HelpTopicIds.aboutDeveloperAndProject]!.body;

    const repository = 'https://github.com/ThalesMMS/Turing-Lab';
    const developer = 'Thales Matheus Mendonça Santos';

    expect(english, contains(developer));
    expect(english, contains(repository));
    expect(portuguese, contains(developer));
    expect(portuguese, contains(repository));
    expect(english, isNot(contains('Open Licenses')));
    expect(portuguese, isNot(contains('Abra Licenças')));
  });

  test('left-recursion help covers direct and indirect cycles', () {
    final english =
        enHelpCatalogCopy[HelpTopicIds
            .grammarEditorAlgorithmsRemoveLeftRecursion]!;
    final portuguese =
        ptHelpCatalogCopy[HelpTopicIds
            .grammarEditorAlgorithmsRemoveLeftRecursion]!;

    expect(english.title, contains('direct and indirect'));
    expect(english.body, contains('ordered substitution'));
    expect(portuguese.title, contains('direta e indireta'));
    expect(portuguese.body, contains('substituições estáveis'));
  });

  test('manual conversion help names the combined algorithms surface', () {
    final english =
        enHelpCatalogCopy[HelpTopicIds.gettingStartedManualConversions]!;
    final portuguese =
        ptHelpCatalogCopy[HelpTopicIds.gettingStartedManualConversions]!;

    expect(
      english.blocks.whereType<HelpOrderedStepsBlock>().single.steps.first,
      startsWith('Open Algorithms & Examples'),
    );
    expect(
      portuguese.blocks.whereType<HelpOrderedStepsBlock>().single.steps.first,
      startsWith('Abra Algoritmos e Exemplos'),
    );
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
