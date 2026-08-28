import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/core/constants/help_catalog.dart';
import 'package:turing_lab/core/constants/help_topic_ids.dart';
import 'package:turing_lab/core/models/help_catalog.dart';
import 'package:turing_lab/l10n/help_catalog_copy.dart';
import 'package:turing_lab/l10n/help_catalog_copy_en.dart';
import 'package:turing_lab/l10n/help_catalog_copy_pt.dart';
import 'package:turing_lab/presentation/widgets/help_search_highlight.dart';

void main() {
  const structuredGroupIds = <String>{
    'fsa.editor.simulation',
    'fsa.editor.algorithms',
    'grammar.editor.parser',
    'grammar.editor.algorithms',
    'pda.editor.simulation',
    'pda.editor.algorithms',
    'tm.editor.simulation',
    'tm.editor.algorithms',
  };

  test('every algorithm, parser, and simulation topic is structured EN/PT', () {
    final topics = kHelpCatalog.nodes
        .whereType<HelpTopicDefinition>()
        .where((topic) {
          final path = kHelpCatalog.pathForTopic(topic.id)!;
          return path.ancestorIds.any(structuredGroupIds.contains);
        })
        .toList(growable: false);

    expect(topics, hasLength(61));
    for (final topic in topics) {
      expect(
        topic.contentKind,
        HelpTopicContentKind.structuredText,
        reason: topic.id,
      );
      for (final copy in [enHelpCatalogCopy, ptHelpCatalogCopy]) {
        final localized = copy[topic.id]!;
        expect(
          localized.blocks.whereType<HelpParagraphBlock>(),
          isNotEmpty,
          reason: topic.id,
        );
        expect(
          localized.blocks.whereType<HelpHeadingBlock>(),
          isNotEmpty,
          reason: topic.id,
        );
        expect(
          localized.blocks.whereType<HelpOrderedStepsBlock>(),
          isNotEmpty,
          reason: topic.id,
        );
        expect(
          localized.blocks.whereType<HelpCalloutBlock>(),
          isNotEmpty,
          reason: topic.id,
        );
        expect(
          localized.blocks.whereType<HelpParagraphBlock>().first.text,
          localized.body,
          reason: topic.id,
        );
      }
    }
  });

  test(
    'parse-table teaching workspace guidance is structured and bilingual',
    () {
      const topicId = HelpTopicIds.grammarEditorParserParseTableTeaching;
      final topic = kHelpCatalog.nodeById(topicId)! as HelpTopicDefinition;

      expect(topic.contentKind, HelpTopicContentKind.structuredText);
      expect(
        topic.relatedTopicIds,
        contains(HelpTopicIds.grammarEditorParserLl1),
      );
      expect(
        topic.relatedTopicIds,
        contains(HelpTopicIds.grammarEditorParserLr),
      );
      expect(
        topic.relatedTopicIds,
        contains(HelpTopicIds.grammarEditorAlgorithmsParseTable),
      );

      for (final copy in [enHelpCatalogCopy, ptHelpCatalogCopy]) {
        final localized = copy[topicId]!;
        expect(localized.blocks.whereType<HelpHeadingBlock>(), hasLength(1));
        expect(
          localized.blocks.whereType<HelpOrderedStepsBlock>().single.steps,
          hasLength(3),
        );
        expect(localized.blocks.whereType<HelpCalloutBlock>(), hasLength(1));
      }

      final english = enHelpCatalogCopy[topicId]!.searchableTextSegments.join(
        '\n',
      );
      final portuguese = ptHelpCatalogCopy[topicId]!.searchableTextSegments
          .join('\n');
      expect(english, contains('Teaching mode'));
      expect(english, contains('generated action'));
      expect(english, contains('read-only reference'));
      expect(english, contains('source grammar invalidates'));
      expect(portuguese, contains('Modo didático'));
      expect(portuguese, contains('ação gerada'));
      expect(portuguese, contains('somente leitura'));
      expect(portuguese, contains('gramática de origem invalida'));
    },
  );

  test('LR(1) teaching workspace guidance is structured and bilingual', () {
    const topicId = HelpTopicIds.grammarEditorParserLr1Teaching;
    final topic = kHelpCatalog.nodeById(topicId)! as HelpTopicDefinition;

    expect(topic.contentKind, HelpTopicContentKind.structuredText);
    expect(topic.relatedTopicIds, contains(HelpTopicIds.grammarEditorParserLr));
    expect(
      topic.relatedTopicIds,
      contains(HelpTopicIds.grammarEditorParserParseTableTeaching),
    );
    expect(
      topic.relatedTopicIds,
      contains(HelpTopicIds.grammarEditorParserResultsAndSteps),
    );
    expect(
      topic.relatedTopicIds,
      contains(HelpTopicIds.troubleshootingSimulationLimits),
    );

    for (final copy in [enHelpCatalogCopy, ptHelpCatalogCopy]) {
      final localized = copy[topicId]!;
      expect(localized.blocks.whereType<HelpHeadingBlock>(), hasLength(1));
      expect(
        localized.blocks.whereType<HelpOrderedStepsBlock>().single.steps,
        hasLength(3),
      );
      expect(localized.blocks.whereType<HelpCalloutBlock>(), hasLength(1));
    }

    final english = enHelpCatalogCopy[topicId]!.searchableTextSegments.join(
      '\n',
    );
    final portuguese = ptHelpCatalogCopy[topicId]!.searchableTextSegments.join(
      '\n',
    );
    expect(english, contains('canonical item sets'));
    expect(english, contains('ACTION / GOTO'));
    expect(english, contains('Shift-reduce execution'));
    expect(english, contains('conflict-free table'));
    expect(english, contains('does not prove language equivalence'));
    expect(portuguese, contains('conjuntos canônicos de itens'));
    expect(portuguese, contains('ACTION / GOTO'));
    expect(portuguese, contains('Execução por deslocamento e redução'));
    expect(portuguese, contains('tabela sem conflitos'));
    expect(portuguese, contains('não prova equivalência de linguagens'));
  });

  test('grammar batch parsing guidance is structured and bilingual', () {
    const topicId = HelpTopicIds.grammarEditorParserMultipleRuns;
    final topic = kHelpCatalog.nodeById(topicId)! as HelpTopicDefinition;

    expect(topic.contentKind, HelpTopicContentKind.structuredText);
    expect(
      topic.relatedTopicIds,
      contains(HelpTopicIds.grammarEditorParserWorkflow),
    );
    expect(
      topic.relatedTopicIds,
      contains(HelpTopicIds.grammarEditorParserResultsAndSteps),
    );
    expect(
      topic.relatedTopicIds,
      contains(HelpTopicIds.gettingStartedMultipleInputBatches),
    );
    expect(
      topic.relatedTopicIds,
      contains(HelpTopicIds.troubleshootingSimulationLimits),
    );

    for (final copy in [enHelpCatalogCopy, ptHelpCatalogCopy]) {
      final localized = copy[topicId]!;
      expect(localized.blocks.whereType<HelpHeadingBlock>(), hasLength(1));
      expect(
        localized.blocks.whereType<HelpOrderedStepsBlock>().single.steps,
        hasLength(3),
      );
      expect(localized.blocks.whereType<HelpCalloutBlock>(), hasLength(1));
    }

    final english = enHelpCatalogCopy[topicId]!.searchableTextSegments.join(
      '\n',
    );
    final portuguese = ptHelpCatalogCopy[topicId]!.searchableTextSegments.join(
      '\n',
    );
    expect(english, contains('multiple inputs'));
    expect(english, contains('Automatic (Earley)'));
    expect(english, contains('Explicit tokens'));
    expect(english, contains('10,000 cases'));
    expect(english, contains('10,000 steps'));
    expect(english, contains('Run batch'));
    expect(english, contains('JSON or CSV'));
    expect(english, contains('language equivalence'));
    expect(portuguese, contains('várias entradas'));
    expect(portuguese, contains('Automatic (Earley)'));
    expect(portuguese, contains('Explicit tokens'));
    expect(portuguese, contains('10.000 casos'));
    expect(portuguese, contains('10.000 passos'));
    expect(portuguese, contains('Run batch'));
    expect(portuguese, contains('JSON ou CSV'));
    expect(portuguese, contains('equivalência de linguagens'));
  });

  test('grammar teaching workspaces have dedicated EN/PT guidance', () {
    const userDerivationId = 'grammar.editor.parser.user-controlled-derivation';
    const dependencyGraphId =
        'grammar.editor.algorithms.variable-dependency-graph';

    expect(
      (kHelpCatalog.nodeById(userDerivationId)! as HelpTopicDefinition)
          .relatedTopicIds,
      contains('grammar.theory.derivations'),
    );
    expect(
      (kHelpCatalog.nodeById(dependencyGraphId)! as HelpTopicDefinition)
          .relatedTopicIds,
      contains('grammar.editor.algorithms.ambiguity'),
    );

    for (final copy in [enHelpCatalogCopy, ptHelpCatalogCopy]) {
      expect(
        copy[userDerivationId]!.blocks
            .whereType<HelpOrderedStepsBlock>()
            .single
            .steps,
        hasLength(3),
      );
    }

    final englishDerivation = enHelpCatalogCopy[userDerivationId]!
        .searchableTextSegments
        .join('\n');
    final portugueseDerivation = ptHelpCatalogCopy[userDerivationId]!
        .searchableTextSegments
        .join('\n');
    final englishGraph = enHelpCatalogCopy[dependencyGraphId]!
        .searchableTextSegments
        .join('\n');
    final portugueseGraph = ptHelpCatalogCopy[dependencyGraphId]!
        .searchableTextSegments
        .join('\n');

    expect(englishDerivation, contains('Start user-controlled derivation'));
    expect(englishDerivation, contains('Request bounded hint'));
    expect(portugueseDerivation, contains('Iniciar derivação controlada'));
    expect(portugueseDerivation, contains('Solicitar dica limitada'));
    expect(englishGraph, contains('Nullable-aware left corner'));
    expect(englishGraph, contains('do not prove ambiguity'));
    expect(portugueseGraph, contains('Canto esquerdo considerando anuláveis'));
    expect(portugueseGraph, contains('não provam ambiguidade'));
  });

  test(
    'TM-to-unrestricted-grammar construction guidance is structured and bilingual',
    () {
      const topicId = HelpTopicIds.unrestrictedGrammarTmToGrammarConstruction;
      final topic = kHelpCatalog.nodeById(topicId)! as HelpTopicDefinition;

      expect(topic.contentKind, HelpTopicContentKind.structuredText);
      expect(topic.relatedTopicIds, contains(HelpTopicIds.tmEditorOverview));
      expect(
        topic.relatedTopicIds,
        contains(HelpTopicIds.tmEditorBuildingBlocks),
      );
      expect(
        topic.relatedTopicIds,
        contains(HelpTopicIds.tmEditorMultiTapeTraceAndMetrics),
      );
      expect(
        topic.relatedTopicIds,
        contains(HelpTopicIds.unrestrictedGrammarEditorOverview),
      );
      expect(
        topic.relatedTopicIds,
        contains(HelpTopicIds.unrestrictedGrammarEditingAndClassification),
      );
      expect(
        topic.relatedTopicIds,
        contains(HelpTopicIds.unrestrictedGrammarExamplesFilesAndLimits),
      );

      for (final copy in [enHelpCatalogCopy, ptHelpCatalogCopy]) {
        final localized = copy[topicId]!;
        expect(localized.blocks.whereType<HelpHeadingBlock>(), hasLength(1));
        expect(
          localized.blocks.whereType<HelpOrderedStepsBlock>().single.steps,
          hasLength(3),
        );
        expect(localized.blocks.whereType<HelpCalloutBlock>(), hasLength(1));
      }

      final english = enHelpCatalogCopy[topicId]!.searchableTextSegments.join(
        '\n',
      );
      final portuguese = ptHelpCatalogCopy[topicId]!.searchableTextSegments
          .join('\n');
      expect(english, contains('single-tape'));
      expect(english, contains('two-way-infinite'));
      expect(english, contains('building-block'));
      expect(english, contains('production provenance'));
      expect(english, contains('formal tape and grammar symbols'));
      expect(english, contains('50,000'));
      expect(english, contains('Copy report'));
      expect(english, contains('Open in unrestricted grammar editor'));
      expect(english, contains('language equivalence'));
      expect(portuguese, contains('fita única'));
      expect(portuguese, contains('infinita nas duas direções'));
      expect(portuguese, contains('blocos de construção'));
      expect(portuguese, contains('proveniência das produções'));
      expect(portuguese, contains('símbolos formais da fita e da gramática'));
      expect(portuguese, contains('50.000'));
      expect(portuguese, contains('Copiar relatório'));
      expect(portuguese, contains('Abrir no editor de gramática irrestrita'));
      expect(portuguese, contains('equivalência de linguagens'));
    },
  );

  test('short topics retain the plain-body compatibility contract', () {
    final english = enHelpCatalogCopy['getting-started.quick-start']!;
    final portuguese = ptHelpCatalogCopy['getting-started.quick-start']!;

    expect(english.body, isNotEmpty);
    expect(portuguese.body, isNotEmpty);
    expect(english.blocks, isEmpty);
    expect(portuguese.blocks, isEmpty);
  });

  test('suggested simulation guidance matches the example-card workflow', () {
    const topicId = 'getting-started.suggested-simulations';
    final topic = kHelpCatalog.nodeById(topicId)! as HelpTopicDefinition;

    expect(topic.contentKind, HelpTopicContentKind.structuredText);
    expect(
      topic.relatedTopicIds,
      contains('getting-started.files-and-examples'),
    );
    expect(topic.relatedTopicIds, contains('getting-started.first-input'));
    for (final copy in [enHelpCatalogCopy, ptHelpCatalogCopy]) {
      final localized = copy[topicId]!;
      expect(localized.body, isNotEmpty);
      expect(localized.blocks.whereType<HelpParagraphBlock>(), isNotEmpty);
      expect(localized.blocks.whereType<HelpHeadingBlock>(), hasLength(1));
      expect(
        localized.blocks.whereType<HelpOrderedStepsBlock>().single.steps,
        hasLength(3),
      );
      expect(localized.blocks.whereType<HelpCalloutBlock>(), hasLength(1));
    }

    final english = enHelpCatalogCopy[topicId]!.searchableTextSegments.join(
      '\n',
    );
    expect(english, contains('Suggested simulations'));
    expect(english, contains('Load example'));
    expect(english, contains('does not fill the input or start the run'));
    expect(english, contains('does not prove every property'));
    expect(english, contains('L-system examples do not show'));

    final portuguese = ptHelpCatalogCopy[topicId]!.searchableTextSegments.join(
      '\n',
    );
    expect(portuguese, contains('Simulações sugeridas'));
    expect(portuguese, contains('Carregar exemplo'));
    expect(portuguese, contains('não preenche o campo nem inicia a execução'));
    expect(portuguese, contains('não prova todas as propriedades'));
    expect(portuguese, contains('Exemplos de sistema L não mostram'));
  });

  test('settings guidance covers persisted presentation preferences', () {
    const topicId = HelpTopicIds.gettingStartedSettings;
    final topic = kHelpCatalog.nodeById(topicId)! as HelpTopicDefinition;

    expect(topic.contentKind, HelpTopicContentKind.structuredText);
    expect(
      topic.relatedTopicIds,
      contains(HelpTopicIds.gettingStartedNavigation),
    );
    expect(
      topic.relatedTopicIds,
      contains(HelpTopicIds.gettingStartedChooseWorkspace),
    );

    for (final copy in [enHelpCatalogCopy, ptHelpCatalogCopy]) {
      final localized = copy[topicId]!;
      expect(localized.body, isNotEmpty);
      expect(localized.blocks.whereType<HelpParagraphBlock>(), isNotEmpty);
      expect(localized.blocks.whereType<HelpHeadingBlock>(), hasLength(1));
      expect(
        localized.blocks.whereType<HelpOrderedStepsBlock>().single.steps,
        hasLength(3),
      );
      expect(localized.blocks.whereType<HelpCalloutBlock>(), hasLength(1));
    }

    final english = enHelpCatalogCopy[topicId]!.searchableTextSegments.join(
      '\n',
    );
    for (final phrase in const [
      'Settings',
      'Theme Mode',
      'System',
      'Light',
      'Dark',
      'App Language',
      'Canvas',
      'Show Grid',
      'Show Coordinates',
      'Grid Size',
      'Node Size',
      'Font Size',
      'Auto Save',
      'Show Tooltips',
      'Save Settings',
      'Reset to Defaults',
      'do not edit formal models',
    ]) {
      expect(english, contains(phrase), reason: phrase);
    }

    final portuguese = ptHelpCatalogCopy[topicId]!.searchableTextSegments.join(
      '\n',
    );
    for (final phrase in const [
      'Configurações',
      'Modo do tema',
      'Sistema',
      'Claro',
      'Escuro',
      'Idioma do aplicativo',
      'Canvas',
      'Mostrar grade',
      'Mostrar coordenadas',
      'Tamanho da grade',
      'Tamanho dos estados',
      'Tamanho da fonte',
      'Salvamento automático',
      'Mostrar dicas',
      'Salvar configurações',
      'Restaurar padrões',
      'não editam modelos formais',
    ]) {
      expect(portuguese, contains(phrase), reason: phrase);
    }
  });

  test(
    'multiple-input batch guidance preserves finite comparison boundaries',
    () {
      const topicId = 'getting-started.multiple-input-batches';
      final topic = kHelpCatalog.nodeById(topicId)! as HelpTopicDefinition;

      expect(topic.contentKind, HelpTopicContentKind.structuredText);
      expect(topic.relatedTopicIds, contains('getting-started.first-input'));
      expect(
        topic.relatedTopicIds,
        contains('troubleshooting.simulation-limits'),
      );
      expect(
        topic.relatedTopicIds,
        contains('transducers.editor.batch-comparison-and-examples'),
      );
      for (final copy in [enHelpCatalogCopy, ptHelpCatalogCopy]) {
        final localized = copy[topicId]!;
        expect(localized.body, isNotEmpty);
        expect(localized.blocks.whereType<HelpParagraphBlock>(), isNotEmpty);
        expect(localized.blocks.whereType<HelpHeadingBlock>(), isNotEmpty);
        expect(localized.blocks.whereType<HelpOrderedStepsBlock>(), isNotEmpty);
        expect(localized.blocks.whereType<HelpCalloutBlock>(), isNotEmpty);
        expect(localized.body, contains('Cancel batch'));
      }

      expect(
        enHelpCatalogCopy[topicId]!.body,
        contains('does not prove general equivalence'),
      );
      expect(
        enHelpCatalogCopy[topicId]!.body,
        contains('does not translate or rewrite'),
      );
      expect(
        ptHelpCatalogCopy[topicId]!.body,
        contains('não prova equivalência geral'),
      );
      expect(
        ptHelpCatalogCopy[topicId]!.body,
        contains('não os traduz nem reescreve'),
      );
    },
  );

  test(
    'document notes guidance is structured and preserves formal content',
    () {
      const topicId = 'getting-started.document-notes';
      final topic = kHelpCatalog.nodeById(topicId)! as HelpTopicDefinition;

      expect(topic.contentKind, HelpTopicContentKind.structuredText);
      expect(
        topic.relatedTopicIds,
        contains('getting-started.files-and-examples'),
      );
      for (final copy in [enHelpCatalogCopy, ptHelpCatalogCopy]) {
        final localized = copy[topicId]!;
        expect(localized.body, isNotEmpty);
        expect(localized.blocks.whereType<HelpParagraphBlock>(), isNotEmpty);
        expect(localized.blocks.whereType<HelpHeadingBlock>(), isNotEmpty);
        expect(localized.blocks.whereType<HelpOrderedStepsBlock>(), isNotEmpty);
        expect(localized.blocks.whereType<HelpCalloutBlock>(), isNotEmpty);
        expect(localized.body, contains('**'));
        expect(localized.body, contains('`'));
        for (final symbol in const ['ε', 'λ', 'q₀', 'A → a']) {
          expect(localized.body, contains(symbol), reason: symbol);
        }
      }

      final english = enHelpCatalogCopy[topicId]!.body;
      expect(english, contains('Document notes'));
      expect(english, contains('Add note'));
      expect(english, contains('Target ID'));
      expect(english, contains('do not change the formal model'));
      expect(english, contains('Include notes in visual exports'));

      final portuguese = ptHelpCatalogCopy[topicId]!.body;
      expect(portuguese, contains('Notas do documento'));
      expect(portuguese, contains('Adicionar nota'));
      expect(portuguese, contains('ID do destino'));
      expect(portuguese, contains('não alteram o modelo formal'));
      expect(portuguese, contains('Incluir notas nas exportações visuais'));
    },
  );

  test(
    'automaton fragment import guidance matches the structural clone boundary',
    () {
      const topicId = 'getting-started.import-automaton-fragments';
      final topic = kHelpCatalog.nodeById(topicId)! as HelpTopicDefinition;

      expect(topic.contentKind, HelpTopicContentKind.structuredText);
      expect(
        topic.relatedTopicIds,
        contains('getting-started.files-and-examples'),
      );
      expect(
        topic.relatedTopicIds,
        contains('troubleshooting.file-import-export'),
      );
      for (final copy in [enHelpCatalogCopy, ptHelpCatalogCopy]) {
        final localized = copy[topicId]!;
        expect(localized.body, isNotEmpty);
        expect(localized.blocks.whereType<HelpParagraphBlock>(), isNotEmpty);
        expect(localized.blocks.whereType<HelpHeadingBlock>(), isNotEmpty);
        expect(localized.blocks.whereType<HelpOrderedStepsBlock>(), isNotEmpty);
        expect(localized.blocks.whereType<HelpCalloutBlock>(), isNotEmpty);
        for (final symbol in const ['ε', 'q₀', 'Z₀', '□']) {
          expect(localized.body, contains(symbol), reason: symbol);
        }
      }

      final english = enHelpCatalogCopy[topicId]!.body;
      for (final label in const [
        'Import automaton',
        'Preview automaton import',
        'Source fidelity',
        'States to import',
        'Insertion anchor',
        'Exact changes',
        'Apply',
        'Cancel',
      ]) {
        expect(english, contains(label), reason: label);
      }
      expect(english, contains('only when both of its endpoint states'));
      expect(english, contains('complete corresponding source set'));
      expect(english, contains('does not establish equivalence'));
      expect(english, contains('does not open or replace a document'));

      final portuguese = ptHelpCatalogCopy[topicId]!.body;
      for (final label in const [
        'Importar autômato',
        'Prévia da importação do autômato',
        'Fidelidade da origem',
        'Estados a importar',
        'Âncora de inserção',
        'Alterações exatas',
        'Aplicar',
        'Cancelar',
      ]) {
        expect(portuguese, contains(label), reason: label);
      }
      expect(portuguese, contains('os dois estados das suas pontas'));
      expect(portuguese, contains('todo o conjunto correspondente da origem'));
      expect(portuguese, contains('não estabelece equivalência'));
      expect(portuguese, contains('não abre nem substitui um documento'));
    },
  );

  test('manual conversion guidance matches the saved session workflow', () {
    const topicId = 'getting-started.manual-conversions';
    final topic = kHelpCatalog.nodeById(topicId)! as HelpTopicDefinition;

    expect(topic.contentKind, HelpTopicContentKind.structuredText);
    expect(
      topic.relatedTopicIds,
      contains('fsa.editor.algorithms.fa-to-regex'),
    );
    expect(
      topic.relatedTopicIds,
      contains('grammar.editor.conversions.right-linear-to-fsa'),
    );
    for (final copy in [enHelpCatalogCopy, ptHelpCatalogCopy]) {
      final localized = copy[topicId]!;
      expect(localized.body, isNotEmpty);
      expect(localized.blocks.whereType<HelpParagraphBlock>(), isNotEmpty);
      expect(localized.blocks.whereType<HelpHeadingBlock>(), isNotEmpty);
      expect(localized.blocks.whereType<HelpOrderedStepsBlock>(), isNotEmpty);
      expect(localized.blocks.whereType<HelpCalloutBlock>(), isNotEmpty);
      for (final label in const [
        'Practice FA to Regex',
        'Practice Regex to FA',
        'Check step',
        'Reveal step',
        'Restart from edited source',
        'Branch from edited source',
        'Construction complete',
        'Open result',
        'Compare',
      ]) {
        expect(localized.body, contains(label), reason: label);
      }
      for (final symbol in const ['ε', 'λ', '∅', 'q₀', 'Z₀', '□']) {
        expect(localized.body, contains(symbol), reason: symbol);
      }
    }

    final english = enHelpCatalogCopy[topicId]!.body;
    expect(english, contains('Close exits'));
    expect(english, contains('Cancel keeps the current destination'));
    expect(english, contains('does not carry accepted actions'));
    expect(
      english,
      contains('Neither label is a general language-equivalence proof'),
    );

    final portuguese = ptHelpCatalogCopy[topicId]!.body;
    expect(portuguese, contains('Close sai'));
    expect(portuguese, contains('Cancelar mantém o destino atual'));
    expect(portuguese, contains('as ações aceitas não são levadas'));
    expect(portuguese, contains('prova equivalência geral de linguagens'));
  });

  test('pumping environment chooser guidance is structured and bilingual', () {
    const topicId = HelpTopicIds.pumpingEditorEnvironmentChoice;
    final topic = kHelpCatalog.nodeById(topicId)! as HelpTopicDefinition;

    expect(topic.contentKind, HelpTopicContentKind.structuredText);
    expect(topic.relatedTopicIds, contains(HelpTopicIds.pumpingEditorOverview));
    expect(topic.relatedTopicIds, contains(HelpTopicIds.pumpingEditorGame));
    expect(
      topic.relatedTopicIds,
      contains(HelpTopicIds.pumpingTheoryStatement),
    );
    expect(
      topic.relatedTopicIds,
      contains(HelpTopicIds.pumpingTheoryQuantifiers),
    );

    for (final copy in [enHelpCatalogCopy, ptHelpCatalogCopy]) {
      final localized = copy[topicId]!;
      expect(localized.body, isNotEmpty);
      expect(localized.blocks.whereType<HelpParagraphBlock>(), isNotEmpty);
      expect(localized.blocks.whereType<HelpHeadingBlock>(), hasLength(1));
      expect(
        localized.blocks.whereType<HelpOrderedStepsBlock>().single.steps,
        hasLength(3),
      );
      expect(localized.blocks.whereType<HelpCalloutBlock>(), hasLength(1));
    }

    final english = enHelpCatalogCopy[topicId]!.searchableTextSegments.join(
      '\n',
    );
    expect(english, contains('Regular pumping'));
    expect(english, contains('Context-free pumping'));
    expect(english, contains('w = uvxyz'));
    expect(english, contains('|vxy| ≤ p'));
    expect(
      english,
      contains('Each environment keeps its own session and progress'),
    );
    expect(
      english,
      contains('decides regularity or non-regularity automatically'),
    );

    final portuguese = ptHelpCatalogCopy[topicId]!.searchableTextSegments.join(
      '\n',
    );
    expect(portuguese, contains('Bombeamento regular'));
    expect(portuguese, contains('Bombeamento livre de contexto'));
    expect(portuguese, contains('w = uvxyz'));
    expect(portuguese, contains('|vxy| ≤ p'));
    expect(
      portuguese,
      contains('Cada ambiente mantém sua própria sessão e progresso'),
    );
    expect(portuguese, contains('decide automaticamente se uma linguagem'));
  });

  test('interoperability review guidance explains fidelity decisions', () {
    const topicId = HelpTopicIds.troubleshootingInteroperabilityReview;
    final topic = kHelpCatalog.nodeById(topicId)! as HelpTopicDefinition;

    expect(topic.contentKind, HelpTopicContentKind.structuredText);
    expect(
      topic.relatedTopicIds,
      contains(HelpTopicIds.troubleshootingFileImportExport),
    );
    expect(
      topic.relatedTopicIds,
      contains(HelpTopicIds.gettingStartedFilesAndExamples),
    );

    for (final copy in [enHelpCatalogCopy, ptHelpCatalogCopy]) {
      final localized = copy[topicId]!;
      expect(localized.body, isNotEmpty);
      expect(localized.blocks.whereType<HelpParagraphBlock>(), isNotEmpty);
      expect(localized.blocks.whereType<HelpHeadingBlock>(), hasLength(1));
      expect(
        localized.blocks.whereType<HelpOrderedStepsBlock>().single.steps,
        hasLength(3),
      );
      expect(localized.blocks.whereType<HelpCalloutBlock>(), hasLength(1));
    }

    final english = enHelpCatalogCopy[topicId]!.searchableTextSegments.join(
      '\n',
    );
    for (final label in const [
      'Review import',
      'Review export',
      'Fidelity',
      'Exact',
      'Normalized',
      'Data loss',
      'Field-level report',
      'Replace document',
      'Cancel',
    ]) {
      expect(english, contains(label), reason: label);
    }
    expect(english, contains('or establish language equivalence'));

    final portuguese = ptHelpCatalogCopy[topicId]!.searchableTextSegments.join(
      '\n',
    );
    for (final label in const [
      'Revisar importação',
      'Revisar exportação',
      'Fidelidade',
      'Exata',
      'Normalizada',
      'Perda de dados',
      'Relatório por campo',
      'Substituir documento',
      'Cancelar',
    ]) {
      expect(portuguese, contains(label), reason: label);
    }
    expect(portuguese, contains('estabelece equivalência de linguagens'));
  });

  test('guided CFG to PDA help preserves construction boundaries', () {
    const topicId = 'grammar.editor.conversions.pda-ll-lr';
    final topic = kHelpCatalog.nodeById(topicId)! as HelpTopicDefinition;

    expect(topic.contentKind, HelpTopicContentKind.structuredText);
    expect(topic.relatedTopicIds, contains('grammar.editor.parser.ll1'));
    expect(topic.relatedTopicIds, contains('grammar.editor.parser.lr'));

    for (final copy in [enHelpCatalogCopy, ptHelpCatalogCopy]) {
      final localized = copy[topicId]!;
      expect(localized.blocks.whereType<HelpHeadingBlock>(), hasLength(1));
      expect(
        localized.blocks.whereType<HelpOrderedStepsBlock>().single.steps,
        hasLength(3),
      );
      expect(localized.blocks.whereType<HelpCalloutBlock>(), hasLength(1));
    }

    final english = enHelpCatalogCopy[topicId]!.searchableTextSegments.join(
      '\n',
    );
    final portuguese = ptHelpCatalogCopy[topicId]!.searchableTextSegments.join(
      '\n',
    );
    expect(english, contains('CFG to PDA (LL) construction'));
    expect(english, contains('cannot prove language equivalence'));
    expect(english, contains('Open in PDA editor'));
    expect(portuguese, contains('Construção GLC para AP (LR)'));
    expect(portuguese, contains('não provam equivalência de linguagens'));
    expect(portuguese, contains('Abrir no editor de AP'));
  });

  test('Mealy and Moore workspace guides are structured and bilingual', () {
    const topicIds = <String>{
      'transducers.mealy.editor.states-and-transitions',
      'transducers.moore.editor.states-and-transitions',
      'transducers.editor.canvas-and-alphabets',
      'transducers.editor.canvas-editing-gestures',
      'transducers.editor.simulation-and-playback',
      'transducers.editor.compact-canvas-playback',
      'transducers.editor.batch-comparison-and-examples',
      'transducers.editor.files-and-export',
    };

    for (final topicId in topicIds) {
      final topic = kHelpCatalog.nodeById(topicId)! as HelpTopicDefinition;
      expect(
        topic.contentKind,
        HelpTopicContentKind.structuredText,
        reason: topicId,
      );
      expect(topic.relatedTopicIds, isNotEmpty, reason: topicId);
      for (final copy in [enHelpCatalogCopy, ptHelpCatalogCopy]) {
        final localized = copy[topicId]!;
        expect(localized.body, isNotEmpty, reason: topicId);
        expect(
          localized.blocks.whereType<HelpParagraphBlock>(),
          isNotEmpty,
          reason: topicId,
        );
        expect(
          localized.blocks.whereType<HelpHeadingBlock>(),
          isNotEmpty,
          reason: topicId,
        );
        expect(
          localized.blocks.whereType<HelpOrderedStepsBlock>(),
          isNotEmpty,
          reason: topicId,
        );
        expect(
          localized.blocks.whereType<HelpCalloutBlock>(),
          isNotEmpty,
          reason: topicId,
        );
      }
    }
  });

  test('transducer gesture guide matches persistent canvas tools', () {
    const topicId = 'transducers.editor.canvas-editing-gestures';
    final topic = kHelpCatalog.nodeById(topicId)! as HelpTopicDefinition;

    expect(topic.contentKind, HelpTopicContentKind.structuredText);
    expect(
      topic.relatedTopicIds,
      contains('transducers.mealy.editor.states-and-transitions'),
    );
    expect(
      topic.relatedTopicIds,
      contains('transducers.moore.editor.states-and-transitions'),
    );

    final english = enHelpCatalogCopy[topicId]!.searchableTextSegments.join(
      '\n',
    );
    for (final label in const [
      'Add state',
      'Add transition',
      'Select',
      'self-loop',
      'long-press',
      'transition label',
    ]) {
      expect(english, contains(label), reason: label);
    }
    expect(english, contains('stay active'));
    expect(english, contains('Panning, pinch zoom, state dragging'));

    final portuguese = ptHelpCatalogCopy[topicId]!.searchableTextSegments.join(
      '\n',
    );
    for (final label in const [
      'Adicionar estado',
      'Adicionar transição',
      'Selecionar',
      'laço',
      'pressão longa',
      'rótulo de transição',
    ]) {
      expect(portuguese, contains(label), reason: label);
    }
    expect(portuguese, contains('permanecem ativos'));
    expect(portuguese, contains('zoom por pinça'));
  });

  test('transducer compact playback guide matches the responsive flow', () {
    const topicId = 'transducers.editor.compact-canvas-playback';
    final topic = kHelpCatalog.nodeById(topicId)! as HelpTopicDefinition;

    expect(topic.contentKind, HelpTopicContentKind.structuredText);
    expect(
      topic.relatedTopicIds,
      contains('transducers.editor.simulation-and-playback'),
    );

    final english = enHelpCatalogCopy[topicId]!.searchableTextSegments.join(
      '\n',
    );
    for (final label in const [
      'View on Canvas',
      'Previous Step',
      'Play',
      'Pause',
      'Next Step',
      'Close',
    ]) {
      expect(english, contains(label), reason: label);
    }
    expect(english, contains('available only in compact layouts'));
    expect(english, contains('target state and transition'));
    expect(english, contains('discards stale playback'));

    final portuguese = ptHelpCatalogCopy[topicId]!.searchableTextSegments.join(
      '\n',
    );
    for (final label in const [
      'Visualizar no Canvas',
      'Passo anterior',
      'Reproduzir',
      'Pausar',
      'Próximo passo',
      'Fechar',
    ]) {
      expect(portuguese, contains(label), reason: label);
    }
    expect(portuguese, contains('somente em layouts compactos'));
    expect(portuguese, contains('estado de destino e a transição'));
    expect(portuguese, contains('descarta a reprodução obsoleta'));
  });

  test('extended workspace guides are structured and bilingual', () {
    const topicIds = <String>{
      'extended-formal-systems.grammar-unrestricted.editing-and-classification',
      'extended-formal-systems.grammar-unrestricted.derivation-and-dependency-graph',
      'extended-formal-systems.grammar-unrestricted.examples-files-and-limits',
      'extended-formal-systems.l-system.definition-and-rules',
      'extended-formal-systems.l-system.generations-and-turtle-view',
      'extended-formal-systems.l-system.examples-files-and-limits',
    };

    for (final topicId in topicIds) {
      final topic = kHelpCatalog.nodeById(topicId)! as HelpTopicDefinition;
      expect(
        topic.contentKind,
        HelpTopicContentKind.structuredText,
        reason: topicId,
      );
      expect(topic.relatedTopicIds, isNotEmpty, reason: topicId);
      for (final copy in [enHelpCatalogCopy, ptHelpCatalogCopy]) {
        final localized = copy[topicId]!;
        expect(localized.body, isNotEmpty, reason: topicId);
        expect(
          localized.blocks.whereType<HelpParagraphBlock>(),
          isNotEmpty,
          reason: topicId,
        );
        expect(
          localized.blocks.whereType<HelpHeadingBlock>(),
          isNotEmpty,
          reason: topicId,
        );
        expect(
          localized.blocks.whereType<HelpOrderedStepsBlock>(),
          isNotEmpty,
          reason: topicId,
        );
        expect(
          localized.blocks.whereType<HelpCalloutBlock>(),
          isNotEmpty,
          reason: topicId,
        );
      }
    }
  });

  test('TM building-block guidance is structured and bilingual', () {
    const topicId = 'tm.editor.building-blocks.library-and-execution';
    final topic = kHelpCatalog.nodeById(topicId)! as HelpTopicDefinition;

    expect(topic.contentKind, HelpTopicContentKind.structuredText);
    expect(topic.relatedTopicIds, contains('tm.editor.simulation.workflow'));
    expect(topic.relatedTopicIds, contains('tm.editor.files-and-examples'));
    for (final copy in [enHelpCatalogCopy, ptHelpCatalogCopy]) {
      final localized = copy[topicId]!;
      expect(localized.body, isNotEmpty);
      expect(localized.blocks.whereType<HelpParagraphBlock>(), isNotEmpty);
      expect(localized.blocks.whereType<HelpHeadingBlock>(), isNotEmpty);
      expect(localized.blocks.whereType<HelpOrderedStepsBlock>(), isNotEmpty);
      expect(localized.blocks.whereType<HelpCalloutBlock>(), isNotEmpty);
    }
  });

  test(
    'TM multi-tape guidance separates trace, configuration, and metrics',
    () {
      const topicId = 'tm.editor.multi-tape.synchronized-trace-and-metrics';
      final topic = kHelpCatalog.nodeById(topicId)! as HelpTopicDefinition;

      expect(topic.contentKind, HelpTopicContentKind.structuredText);
      expect(
        topic.relatedTopicIds,
        contains('tm.editor.tape.head-and-current-cell'),
      );
      expect(
        topic.relatedTopicIds,
        contains('tm.editor.simulation.trace-and-tape'),
      );
      expect(topic.relatedTopicIds, contains('tm.editor.algorithms.space'));
      for (final copy in [enHelpCatalogCopy, ptHelpCatalogCopy]) {
        final localized = copy[topicId]!;
        expect(localized.body, isNotEmpty);
        expect(localized.blocks.whereType<HelpParagraphBlock>(), isNotEmpty);
        expect(localized.blocks.whereType<HelpHeadingBlock>(), isNotEmpty);
        expect(localized.blocks.whereType<HelpOrderedStepsBlock>(), isNotEmpty);
        expect(localized.blocks.whereType<HelpCalloutBlock>(), isNotEmpty);
      }

      expect(enHelpCatalogCopy[topicId]!.body, contains('one atomic step'));
      expect(
        enHelpCatalogCopy[topicId]!.body,
        contains('The selected configuration'),
      );
      expect(
        enHelpCatalogCopy[topicId]!.body,
        contains('maximum simultaneous nonblank total'),
      );
      expect(
        ptHelpCatalogCopy[topicId]!.body,
        contains('um único passo atômico'),
      );
      expect(
        ptHelpCatalogCopy[topicId]!.body,
        contains('A configuração selecionada'),
      );
      expect(
        ptHelpCatalogCopy[topicId]!.body,
        contains('máximo total simultâneo'),
      );
    },
  );

  test('TM building-block library guidance is structured and bilingual', () {
    const topicId = 'tm.editor.building-blocks.manage-library';
    final topic = kHelpCatalog.nodeById(topicId)! as HelpTopicDefinition;

    expect(topic.contentKind, HelpTopicContentKind.structuredText);
    expect(
      topic.relatedTopicIds,
      contains('tm.editor.building-blocks.library-and-execution'),
    );
    for (final copy in [enHelpCatalogCopy, ptHelpCatalogCopy]) {
      final localized = copy[topicId]!;
      expect(localized.blocks.whereType<HelpParagraphBlock>(), isNotEmpty);
      expect(localized.blocks.whereType<HelpHeadingBlock>(), hasLength(1));
      expect(
        localized.blocks.whereType<HelpOrderedStepsBlock>().single.steps,
        hasLength(3),
      );
      expect(localized.blocks.whereType<HelpCalloutBlock>(), hasLength(1));
    }

    final english = enHelpCatalogCopy[topicId]!.searchableTextSegments.join(
      '\n',
    );
    final portuguese = ptHelpCatalogCopy[topicId]!.searchableTextSegments.join(
      '\n',
    );
    expect(english, contains('Create block'));
    expect(english, contains('Detach and delete'));
    expect(portuguese, contains('Criar bloco'));
    expect(portuguese, contains('Desvincular e excluir'));
  });

  test('grammar normalization practice documents its checker boundary', () {
    const topicId = 'grammar.editor.algorithms.normalization-practice';
    final topic = kHelpCatalog.nodeById(topicId)! as HelpTopicDefinition;

    expect(topic.contentKind, HelpTopicContentKind.structuredText);
    expect(topic.relatedTopicIds, contains('grammar.editor.algorithms.cnf'));
    expect(topic.relatedTopicIds, contains('grammar.theory.cnf'));
    expect(
      enHelpCatalogCopy[topicId]!.body,
      contains('a failed check is not a proof of inequivalence'),
    );
    expect(
      ptHelpCatalogCopy[topicId]!.body,
      contains('uma falha na verificação não prova inequivalência'),
    );
  });

  test(
    'language comparison result guide distinguishes verdicts from stops',
    () {
      const topicId = 'fsa.editor.algorithms.language-comparison-results';
      final topic = kHelpCatalog.nodeById(topicId)! as HelpTopicDefinition;

      expect(topic.contentKind, HelpTopicContentKind.structuredText);
      expect(
        topic.relatedTopicIds,
        contains('fsa.editor.algorithms.equivalence'),
      );
      expect(
        topic.relatedTopicIds,
        contains('fsa.editor.algorithms.step-mode'),
      );
      expect(topic.relatedTopicIds, contains('fsa.theory.equivalence'));

      for (final copy in [enHelpCatalogCopy, ptHelpCatalogCopy]) {
        final localized = copy[topicId]!;
        expect(localized.body, isNotEmpty);
        expect(localized.blocks.whereType<HelpParagraphBlock>(), isNotEmpty);
        expect(localized.blocks.whereType<HelpHeadingBlock>(), hasLength(1));
        expect(
          localized.blocks.whereType<HelpOrderedStepsBlock>().single.steps,
          hasLength(4),
        );
        expect(localized.blocks.whereType<HelpCalloutBlock>(), hasLength(1));
        expect(localized.searchableTextSegments.join('\n'), contains('ε'));
      }

      final english = enHelpCatalogCopy[topicId]!.searchableTextSegments.join(
        '\n',
      );
      for (final label in const [
        'Language Comparison',
        'Distinguishing String Found',
        'Current Automaton',
        'Compared Automaton',
        'Product Automaton',
        'Algorithm Steps',
        'Inconclusive within limits',
        'Analysis failed',
      ]) {
        expect(english, contains(label), reason: label);
      }
      expect(english, contains('do not decide equivalence'));
      expect(english, contains('does not change either automaton'));

      final portuguese = ptHelpCatalogCopy[topicId]!.searchableTextSegments
          .join('\n');
      for (final label in const [
        'Comparação de linguagens',
        'Cadeia distintiva encontrada',
        'Autômato atual',
        'Autômato comparado',
        'Autômato produto',
        'Passos do algoritmo',
        'Inconclusivo dentro dos limites',
        'A análise falhou',
      ]) {
        expect(portuguese, contains(label), reason: label);
      }
      expect(portuguese, contains('não decidem a equivalência'));
      expect(portuguese, contains('não altera nenhum dos autômatos'));
    },
  );

  test('FSA guidance and search do not advertise a cancel control', () {
    const fsaSimulationTopicIds = <String>{
      'fsa.editor.simulation.input-and-run',
      'fsa.editor.simulation.results-and-playback',
    };

    for (final (copy, falseInstruction) in [
      (enHelpCatalogCopy, 'use Cancel'),
      (ptHelpCatalogCopy, 'use Cancelar'),
    ]) {
      for (final topicId in fsaSimulationTopicIds) {
        final blockText = copy[topicId]!.blocks
            .expand((block) => block.textSegments)
            .join('\n')
            .toLowerCase();
        expect(
          blockText,
          isNot(contains(falseInstruction.toLowerCase())),
          reason: topicId,
        );
      }

      final searchResult = searchHelpCatalog(
        kHelpCatalog,
        copy,
        falseInstruction,
      );
      expect(
        searchResult.matchingTopicIds.intersection(fsaSimulationTopicIds),
        isEmpty,
        reason: falseInstruction,
      );
    }
  });

  test(
    'structured topics without all required block kinds fail validation',
    () {
      final catalog = HelpCatalog(
        roots: [
          HelpCategoryDefinition(
            id: 'root',
            icon: 'help',
            children: [
              HelpTopicDefinition(
                id: 'root.topic',
                icon: 'help',
                contentKind: HelpTopicContentKind.structuredText,
              ),
            ],
          ),
        ],
      );
      final copy = HelpCatalogCopy({
        'root': HelpNodeCopy(title: 'Root'),
        'root.topic': HelpNodeCopy(
          title: 'Topic',
          body: 'Searchable body.',
          keywords: ['topic'],
          blocks: const [HelpHeadingBlock('Heading only')],
        ),
      });

      expect(
        catalog.validateCopy(copy),
        contains('incomplete structured copy: root.topic'),
      );
      expect(catalog.hasCompleteHelpCopy(copy, 'root.topic'), isFalse);
    },
  );
}
