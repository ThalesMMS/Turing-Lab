import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/core/constants/help_catalog.dart';
import 'package:turing_lab/core/constants/help_topic_ids.dart';
import 'package:turing_lab/core/models/help_catalog.dart';
import 'package:turing_lab/l10n/app_localizations_en.dart';
import 'package:turing_lab/l10n/app_localizations_help.dart';
import 'package:turing_lab/l10n/app_localizations_pt.dart';
import 'package:turing_lab/l10n/help_catalog_copy.dart';
import 'package:turing_lab/l10n/help_catalog_copy_en.dart';
import 'package:turing_lab/l10n/help_catalog_copy_pt.dart';

final fixture = HelpCatalog(
  roots: [
    HelpCategoryDefinition(
      id: 'fsa',
      icon: 'account_tree',
      children: [
        HelpSubsectionDefinition(
          id: 'fsa.editor',
          icon: 'edit',
          children: [
            HelpSubsectionDefinition(
              id: 'fsa.editor.algorithms',
              icon: 'auto_awesome',
              children: [
                HelpTopicDefinition(
                  id: 'fsa.editor.algorithms.minimize',
                  icon: 'compress',
                  relatedTopicIds: ['fsa.theory.dfa'],
                ),
              ],
            ),
          ],
        ),
        HelpSubsectionDefinition(
          id: 'fsa.theory',
          icon: 'school',
          children: [
            HelpTopicDefinition(id: 'fsa.theory.dfa', icon: 'account_tree'),
          ],
        ),
      ],
    ),
  ],
);

final duplicateFixture = HelpCatalog(
  roots: [
    HelpCategoryDefinition(
      id: 'fsa',
      icon: 'account_tree',
      children: [
        HelpSubsectionDefinition(
          id: 'fsa.editor',
          icon: 'edit',
          children: [HelpTopicDefinition(id: 'shared.topic', icon: 'help')],
        ),
        HelpSubsectionDefinition(
          id: 'fsa.theory',
          icon: 'school',
          children: [HelpTopicDefinition(id: 'shared.topic', icon: 'help')],
        ),
      ],
    ),
  ],
);

final danglingFixture = HelpCatalog(
  roots: [
    HelpCategoryDefinition(
      id: 'fsa',
      icon: 'account_tree',
      children: [
        HelpTopicDefinition(
          id: 'fsa.editor.overview',
          icon: 'help',
          relatedTopicIds: ['unregistered.topic'],
        ),
      ],
    ),
  ],
);

List<String> topicIdsUnder(HelpCatalog catalog, String ancestorId) {
  return catalog.nodes
      .whereType<HelpTopicDefinition>()
      .map((topic) => topic.id)
      .where((id) => id.startsWith('$ancestorId.'))
      .toList(growable: false);
}

void main() {
  test('pathForTopic returns every ancestor in display order', () {
    final path = fixture.pathForTopic('fsa.editor.algorithms.minimize');

    expect(path!.ancestorIds, ['fsa', 'fsa.editor', 'fsa.editor.algorithms']);
    expect(path.topic.id, 'fsa.editor.algorithms.minimize');
  });

  test('pathForTopic returns null for a missing topic', () {
    expect(fixture.pathForTopic('fsa.missing'), isNull);
  });

  test('validateStructure reports duplicate and dangling IDs', () {
    expect(fixture.validateStructure(), isEmpty);
    expect(
      duplicateFixture.validateStructure(),
      contains('duplicate node id: shared.topic'),
    );
    expect(
      danglingFixture.validateStructure(),
      contains(
        'topic fsa.editor.overview references missing related topic: '
        'unregistered.topic',
      ),
    );
  });

  test('nodeById and topicIds preserve source order', () {
    expect(fixture.nodeById('fsa.theory.dfa'), isA<HelpTopicDefinition>());
    expect(fixture.topicIds, [
      'fsa.editor.algorithms.minimize',
      'fsa.theory.dfa',
    ]);
  });

  test('defensively freezes caller collections and keeps index stable', () {
    final topicChildren = <HelpNodeDefinition>[
      HelpTopicDefinition(id: 'mutable.topic', icon: 'help'),
    ];
    final roots = <HelpCategoryDefinition>[
      HelpCategoryDefinition(
        id: 'mutable',
        icon: 'help',
        children: [
          HelpSubsectionDefinition(
            id: 'mutable.section',
            icon: 'help',
            children: topicChildren,
          ),
        ],
      ),
    ];
    final catalog = HelpCatalog(roots: roots);

    expect(catalog.nodeById('mutable.topic')?.id, 'mutable.topic');
    roots.clear();
    topicChildren.clear();
    expect(catalog.nodeById('mutable.topic')?.id, 'mutable.topic');
    expect(catalog.topicIds, ['mutable.topic']);
    expect(() => catalog.roots.clear(), throwsUnsupportedError);
    expect(
      () => (catalog.roots.single.children.single as HelpGroupDefinition)
          .children
          .clear(),
      throwsUnsupportedError,
    );
  });

  test('localized copy defensively freezes entries, keywords, and blocks', () {
    final keywords = <String>['parser'];
    final steps = <String>['Choose a strategy.'];
    final blocks = <HelpContentBlock>[
      const HelpHeadingBlock('How to use it'),
      HelpOrderedStepsBlock(steps),
      const HelpCalloutBlock('Resolve validation errors first.'),
    ];
    final entries = <String, HelpNodeCopy>{
      'topic': HelpNodeCopy(
        title: 'Parser',
        body: 'The original searchable summary.',
        keywords: keywords,
        blocks: blocks,
      ),
    };
    final copy = HelpCatalogCopy(entries);

    entries.clear();
    keywords.clear();
    steps.clear();
    blocks.clear();

    final topic = copy['topic']!;
    expect(copy.entries.keys, ['topic']);
    expect(topic.keywords, ['parser']);
    expect(
      topic.blocks.whereType<HelpParagraphBlock>().single.text,
      'The original searchable summary.',
    );
    expect(
      topic.blocks.whereType<HelpHeadingBlock>().single.text,
      'How to use it',
    );
    expect(topic.blocks.whereType<HelpOrderedStepsBlock>().single.steps, [
      'Choose a strategy.',
    ]);
    expect(
      topic.blocks.whereType<HelpCalloutBlock>().single.text,
      'Resolve validation errors first.',
    );
    expect(() => copy.entries.clear(), throwsUnsupportedError);
    expect(() => topic.keywords.clear(), throwsUnsupportedError);
    expect(() => topic.blocks.clear(), throwsUnsupportedError);
    expect(
      () =>
          topic.blocks.whereType<HelpOrderedStepsBlock>().single.steps.clear(),
      throwsUnsupportedError,
    );
  });

  test('validateStructure reports categories nested below a category', () {
    final catalog = HelpCatalog(
      roots: [
        HelpCategoryDefinition(
          id: 'root',
          icon: 'help',
          children: [
            HelpSubsectionDefinition(
              id: 'root.section',
              icon: 'help',
              children: [
                HelpCategoryDefinition(
                  id: 'root.invalid-category',
                  icon: 'help',
                  children: [],
                ),
              ],
            ),
          ],
        ),
      ],
    );

    expect(catalog.validateStructure(), contains(contains('category')));
  });

  test('catalog preserves the exact approved node order', () {
    expect(kHelpCatalog.nodes.map((node) => node.id), [
      'getting-started',
      'getting-started.quick-start',
      'getting-started.navigation',
      'getting-started.choose-workspace',
      'getting-started.settings',
      'getting-started.files-and-examples',
      'getting-started.suggested-simulations',
      'getting-started.import-automaton-fragments',
      'getting-started.manual-conversions',
      'getting-started.document-notes',
      'getting-started.first-input',
      'getting-started.multiple-input-batches',
      'getting-started.find-help',
      'fsa',
      'fsa.editor',
      'fsa.editor.overview',
      'fsa.editor.editing',
      'fsa.editor.selection',
      'fsa.editor.states',
      'fsa.editor.transitions',
      'fsa.editor.determinism',
      'fsa.editor.history-and-clear',
      'fsa.editor.viewport',
      'fsa.editor.viewport.zoom',
      'fsa.editor.viewport.fit-and-reset',
      'fsa.editor.viewport.auto-layout',
      'fsa.editor.simulation',
      'fsa.editor.simulation.input-and-run',
      'fsa.editor.simulation.results-and-playback',
      'fsa.editor.algorithms',
      'fsa.editor.algorithms.overview',
      'fsa.editor.algorithms.regex-to-nfa',
      'fsa.editor.algorithms.nfa-to-dfa',
      'fsa.editor.algorithms.remove-lambda',
      'fsa.editor.algorithms.minimize-dfa',
      'fsa.editor.algorithms.complete-dfa',
      'fsa.editor.algorithms.complement-dfa',
      'fsa.editor.algorithms.union',
      'fsa.editor.algorithms.intersection',
      'fsa.editor.algorithms.difference',
      'fsa.editor.algorithms.prefix-closure',
      'fsa.editor.algorithms.suffix-closure',
      'fsa.editor.algorithms.fa-to-regex',
      'fsa.editor.algorithms.fsa-to-grammar',
      'fsa.editor.algorithms.equivalence',
      'fsa.editor.algorithms.language-comparison-results',
      'fsa.editor.algorithms.step-mode',
      'fsa.editor.files-and-examples',
      'fsa.theory',
      'fsa.theory.dfa',
      'fsa.theory.nfa',
      'fsa.theory.states',
      'fsa.theory.transitions',
      'fsa.theory.alphabet-and-acceptance',
      'fsa.theory.epsilon',
      'fsa.theory.epsilon-closure',
      'fsa.theory.equivalence',
      'fsa.theory.closure-operations',
      'grammar',
      'grammar.editor',
      'grammar.editor.overview',
      'grammar.editor.productions',
      'grammar.editor.productions.symbols',
      'grammar.editor.productions.rows-and-alternatives',
      'grammar.editor.productions.lambda',
      'grammar.editor.productions.validation',
      'grammar.editor.parser',
      'grammar.editor.parser.workflow',
      'grammar.editor.parser.user-controlled-derivation',
      'grammar.editor.parser.automatic-earley',
      'grammar.editor.parser.brute-force',
      'grammar.editor.parser.cyk',
      'grammar.editor.parser.ll1',
      'grammar.editor.parser.lr',
      'grammar.editor.parser.lr1-teaching',
      'grammar.editor.parser.parse-table-teaching',
      'grammar.editor.parser.results-and-steps',
      'grammar.editor.parser.multiple-runs',
      'grammar.editor.algorithms',
      'grammar.editor.algorithms.overview',
      'grammar.editor.algorithms.cnf',
      'grammar.editor.algorithms.normalization-practice',
      'grammar.editor.algorithms.gnf',
      'grammar.editor.algorithms.remove-left-recursion',
      'grammar.editor.algorithms.left-factor',
      'grammar.editor.algorithms.first',
      'grammar.editor.algorithms.follow',
      'grammar.editor.algorithms.parse-table',
      'grammar.editor.algorithms.ambiguity',
      'grammar.editor.algorithms.variable-dependency-graph',
      'grammar.editor.conversions',
      'grammar.editor.conversions.right-linear-to-fsa',
      'grammar.editor.conversions.pda-general',
      'grammar.editor.conversions.pda-standard',
      'grammar.editor.conversions.pda-greibach',
      'grammar.editor.conversions.pda-ll-lr',
      'grammar.editor.files-and-examples',
      'grammar.theory',
      'grammar.theory.cfg',
      'grammar.theory.productions',
      'grammar.theory.derivations',
      'grammar.theory.parse-trees',
      'grammar.theory.ambiguity',
      'grammar.theory.left-recursion-and-factoring',
      'grammar.theory.first-and-follow',
      'grammar.theory.predictive-parsing',
      'grammar.theory.cnf',
      'grammar.theory.gnf',
      'grammar.theory.grammar-fsa-pda',
      'pda',
      'pda.editor',
      'pda.editor.overview',
      'pda.editor.editing',
      'pda.editor.selection-and-states',
      'pda.editor.transitions',
      'pda.editor.lambda-switches',
      'pda.editor.history-and-clear',
      'pda.editor.viewport',
      'pda.editor.viewport.zoom',
      'pda.editor.viewport.fit-and-reset',
      'pda.editor.viewport.auto-layout',
      'pda.editor.stack',
      'pda.editor.stack.inspector',
      'pda.editor.stack.initial-symbol-and-alphabet',
      'pda.editor.stack.operation-preview',
      'pda.editor.simulation',
      'pda.editor.simulation.workflow',
      'pda.editor.simulation.trace-and-stack',
      'pda.editor.simulation.results-and-canvas',
      'pda.editor.algorithms',
      'pda.editor.algorithms.overview',
      'pda.editor.algorithms.to-cfg',
      'pda.editor.algorithms.minimize',
      'pda.editor.algorithms.determinism',
      'pda.editor.algorithms.reachable-states',
      'pda.editor.algorithms.language',
      'pda.editor.algorithms.stack-operations',
      'pda.editor.files-and-examples',
      'pda.theory',
      'pda.theory.pda',
      'pda.theory.stack',
      'pda.theory.transitions',
      'pda.theory.acceptance',
      'pda.theory.nondeterminism',
      'pda.theory.context-free-languages',
      'pda.theory.pda-and-cfg',
      'tm',
      'tm.editor',
      'tm.editor.overview',
      'tm.editor.editing',
      'tm.editor.selection-and-states',
      'tm.editor.transitions',
      'tm.editor.read-write-and-direction',
      'tm.editor.history-and-clear',
      'tm.editor.viewport',
      'tm.editor.viewport.zoom',
      'tm.editor.viewport.fit-and-reset',
      'tm.editor.viewport.auto-layout',
      'tm.editor.tape',
      'tm.editor.tape.inspector',
      'tm.editor.tape.blank-and-alphabet',
      'tm.editor.tape.head-and-current-cell',
      'tm.editor.multi-tape.synchronized-trace-and-metrics',
      'tm.editor.simulation',
      'tm.editor.simulation.workflow',
      'tm.editor.simulation.trace-and-tape',
      'tm.editor.simulation.results-and-canvas',
      'tm.editor.algorithms',
      'tm.editor.algorithms.overview',
      'tm.editor.algorithms.decidability',
      'tm.editor.algorithms.reachable-states',
      'tm.editor.algorithms.language',
      'tm.editor.algorithms.tape-operations',
      'tm.editor.algorithms.time',
      'tm.editor.algorithms.space',
      'tm.editor.building-blocks',
      'tm.editor.building-blocks.library-and-execution',
      'tm.editor.building-blocks.manage-library',
      'tm.editor.files-and-examples',
      'tm.theory',
      'tm.theory.tm',
      'tm.theory.tape-and-head',
      'tm.theory.configurations',
      'tm.theory.halting-and-acceptance',
      'tm.theory.decidable-languages',
      'tm.theory.recursively-enumerable',
      'tm.theory.time-and-space',
      'regex',
      'regex.editor',
      'regex.editor.overview',
      'regex.editor.input-and-validation',
      'regex.editor.alphabet',
      'regex.editor.test-strings',
      'regex.editor.conversions',
      'regex.editor.conversions.overview',
      'regex.editor.conversions.to-nfa',
      'regex.editor.conversions.to-dfa',
      'regex.editor.conversions.fa-to-regex',
      'regex.editor.simplification',
      'regex.editor.complexity',
      'regex.editor.sample-strings',
      'regex.editor.equivalence',
      'regex.editor.embedded-fsa-panels',
      'regex.theory',
      'regex.theory.regex',
      'regex.theory.literals-and-grouping',
      'regex.theory.concatenation-and-union',
      'regex.theory.kleene-star-and-plus',
      'regex.theory.optional',
      'regex.theory.precedence',
      'regex.theory.lambda',
      'regex.theory.regular-languages',
      'regex.theory.equivalence-with-fsa',
      'pumping',
      'pumping.editor',
      'pumping.editor.environment-choice',
      'pumping.editor.overview',
      'pumping.editor.game',
      'pumping.editor.difficulty-and-challenges',
      'pumping.editor.regularity-choice',
      'pumping.editor.witness-and-decomposition',
      'pumping.editor.pumping-choice-and-submit',
      'pumping.editor.feedback-retry-and-practice',
      'pumping.editor.progress',
      'pumping.editor.responsive-layout',
      'pumping.theory',
      'pumping.theory.statement',
      'pumping.theory.quantifiers',
      'pumping.theory.proof-strategy',
      'pumping.theory.choose-witness',
      'pumping.theory.all-decompositions',
      'pumping.theory.contradiction',
      'pumping.theory.limitations',
      'pumping.theory.regular-example',
      'pumping.theory.nonregular-anbn',
      'pumping.theory.nonregular-ww',
      'transducers',
      'transducers.mealy.editor.overview',
      'transducers.mealy.editor.states-and-transitions',
      'transducers.moore.editor.overview',
      'transducers.moore.editor.states-and-transitions',
      'transducers.editor.canvas-and-alphabets',
      'transducers.editor.canvas-editing-gestures',
      'transducers.editor.simulation-and-playback',
      'transducers.editor.compact-canvas-playback',
      'transducers.editor.batch-comparison-and-examples',
      'transducers.editor.files-and-export',
      'extended-formal-systems',
      'extended-formal-systems.grammar-unrestricted',
      'extended-formal-systems.grammar-unrestricted.editing-and-classification',
      'extended-formal-systems.grammar-unrestricted.derivation-and-dependency-graph',
      'extended-formal-systems.grammar-unrestricted.examples-files-and-limits',
      'extended-formal-systems.grammar-unrestricted.tm-to-grammar-construction',
      'extended-formal-systems.l-system',
      'extended-formal-systems.l-system.definition-and-rules',
      'extended-formal-systems.l-system.generations-and-turtle-view',
      'extended-formal-systems.l-system.examples-files-and-limits',
      'shortcuts',
      'shortcuts.canvas',
      'shortcuts.simulation',
      'shortcuts.dialogs-and-forms',
      'shortcuts.focus-navigation',
      'shortcuts.platform-modifiers',
      'shortcuts.cancel-and-close',
      'troubleshooting',
      'troubleshooting.invalid-automata',
      'troubleshooting.grammar-input',
      'troubleshooting.regex-input',
      'troubleshooting.simulation-limits',
      'troubleshooting.parser-strategies',
      'troubleshooting.file-import-export',
      'troubleshooting.interoperability-review',
      'troubleshooting.missing-state-markers',
      'troubleshooting.nondeterminism',
      'troubleshooting.lost-canvas-view',
      'about',
      'about.developer-and-project',
      'about.licenses',
      'about.acknowledgments',
      'about.distribution',
    ]);
  });

  test('catalog exposes the approved top-level order', () {
    expect(kHelpCatalog.roots.map((node) => node.id), [
      'getting-started',
      'fsa',
      'grammar',
      'pda',
      'tm',
      'regex',
      'pumping',
      'transducers',
      'extended-formal-systems',
      'shortcuts',
      'troubleshooting',
      'about',
    ]);
  });

  test('global categories expose the complete approved topic inventory', () {
    expect(topicIdsUnder(kHelpCatalog, 'transducers'), [
      'transducers.mealy.editor.overview',
      'transducers.mealy.editor.states-and-transitions',
      'transducers.moore.editor.overview',
      'transducers.moore.editor.states-and-transitions',
      'transducers.editor.canvas-and-alphabets',
      'transducers.editor.canvas-editing-gestures',
      'transducers.editor.simulation-and-playback',
      'transducers.editor.compact-canvas-playback',
      'transducers.editor.batch-comparison-and-examples',
      'transducers.editor.files-and-export',
    ]);
    expect(topicIdsUnder(kHelpCatalog, 'extended-formal-systems'), [
      'extended-formal-systems.grammar-unrestricted',
      'extended-formal-systems.grammar-unrestricted.editing-and-classification',
      'extended-formal-systems.grammar-unrestricted.derivation-and-dependency-graph',
      'extended-formal-systems.grammar-unrestricted.examples-files-and-limits',
      'extended-formal-systems.grammar-unrestricted.tm-to-grammar-construction',
      'extended-formal-systems.l-system',
      'extended-formal-systems.l-system.definition-and-rules',
      'extended-formal-systems.l-system.generations-and-turtle-view',
      'extended-formal-systems.l-system.examples-files-and-limits',
    ]);
    expect(topicIdsUnder(kHelpCatalog, 'shortcuts'), [
      'shortcuts.canvas',
      'shortcuts.simulation',
      'shortcuts.dialogs-and-forms',
      'shortcuts.focus-navigation',
      'shortcuts.platform-modifiers',
      'shortcuts.cancel-and-close',
    ]);
    expect(topicIdsUnder(kHelpCatalog, 'troubleshooting'), [
      'troubleshooting.invalid-automata',
      'troubleshooting.grammar-input',
      'troubleshooting.regex-input',
      'troubleshooting.simulation-limits',
      'troubleshooting.parser-strategies',
      'troubleshooting.file-import-export',
      'troubleshooting.interoperability-review',
      'troubleshooting.missing-state-markers',
      'troubleshooting.nondeterminism',
      'troubleshooting.lost-canvas-view',
    ]);
    expect(topicIdsUnder(kHelpCatalog, 'about'), [
      'about.developer-and-project',
      'about.licenses',
      'about.acknowledgments',
      'about.distribution',
    ]);
  });

  test('about licenses uses the rich licenses content kind', () {
    final licenses = kHelpCatalog.nodeById('about.licenses');

    expect(licenses, isA<HelpTopicDefinition>());
    expect(
      (licenses! as HelpTopicDefinition).contentKind,
      HelpTopicContentKind.aboutAndLicenses,
    );
  });

  test('grammar keeps editor before theory and has every parser topic', () {
    final grammar = kHelpCatalog.nodeById('grammar')! as HelpCategoryDefinition;

    expect(grammar.children.map((node) => node.id), [
      'grammar.editor',
      'grammar.theory',
    ]);
    expect(
      topicIdsUnder(kHelpCatalog, 'grammar.editor.parser'),
      containsAll({
        'grammar.editor.parser.workflow',
        'grammar.editor.parser.user-controlled-derivation',
        'grammar.editor.parser.automatic-earley',
        'grammar.editor.parser.brute-force',
        'grammar.editor.parser.cyk',
        'grammar.editor.parser.ll1',
        'grammar.editor.parser.lr',
        'grammar.editor.parser.lr1-teaching',
        'grammar.editor.parser.parse-table-teaching',
        'grammar.editor.parser.results-and-steps',
        'grammar.editor.parser.multiple-runs',
      }),
    );
  });

  test('grammar copy names every parser, algorithm, and conversion', () {
    final englishBodies = enHelpCatalogCopy.entries.entries
        .where((entry) => entry.key.startsWith('grammar.'))
        .map((entry) => entry.value.body)
        .join('\n');
    final portugueseBodies = ptHelpCatalogCopy.entries.entries
        .where((entry) => entry.key.startsWith('grammar.'))
        .map((entry) => entry.value.body)
        .join('\n');

    const parserNames = [
      'Automatic (Earley)',
      'Brute force',
      'CYK (Cocke-Younger-Kasami)',
      'LL(1)',
      'LR',
    ];
    const englishAlgorithmNames = [
      'Convert to CNF',
      'Convert to GNF',
      'Remove Left Recursion',
      'Left Factor',
      'Find First Sets',
      'Find Follow Sets',
      'Build Parse Table',
      'Check Ambiguity',
      'Convert Right-Linear Grammar to FSA',
      'Convert Grammar to PDA (General)',
      'Convert Grammar to PDA (Standard)',
      'Convert Grammar to PDA (Greibach)',
    ];
    const portugueseAlgorithmNames = [
      'Converter para FNC',
      'Converter para FNG',
      'Remover recursão à esquerda',
      'Fatorar à esquerda',
      'Calcular conjuntos FIRST',
      'Calcular conjuntos FOLLOW',
      'Construir tabela de análise',
      'Verificar ambiguidade',
      'Convert Right-Linear Grammar to FSA',
      'Convert Grammar to PDA (General)',
      'Convert Grammar to PDA (Standard)',
      'Convert Grammar to PDA (Greibach)',
    ];

    for (final name in parserNames) {
      expect(englishBodies, contains(name), reason: 'English: $name');
      expect(portugueseBodies, contains(name), reason: 'Portuguese: $name');
    }
    for (final name in englishAlgorithmNames) {
      expect(englishBodies, contains(name), reason: 'English: $name');
    }
    for (final name in portugueseAlgorithmNames) {
      expect(portugueseBodies, contains(name), reason: 'Portuguese: $name');
    }
  });

  test('pda keeps editor before theory and exposes every analysis control', () {
    final pda = kHelpCatalog.nodeById('pda')! as HelpCategoryDefinition;

    expect(pda.children.map((node) => node.id), ['pda.editor', 'pda.theory']);
    expect(
      topicIdsUnder(kHelpCatalog, 'pda.editor.algorithms'),
      containsAll({
        'pda.editor.algorithms.to-cfg',
        'pda.editor.algorithms.minimize',
        'pda.editor.algorithms.determinism',
        'pda.editor.algorithms.reachable-states',
        'pda.editor.algorithms.language',
        'pda.editor.algorithms.stack-operations',
      }),
    );
  });

  test('pda copy documents transition and live simulation fields', () {
    final englishBodies = enHelpCatalogCopy.entries.entries
        .where((entry) => entry.key.startsWith('pda.'))
        .map((entry) => entry.value.body.toLowerCase())
        .join('\n');
    final portugueseBodies = ptHelpCatalogCopy.entries.entries
        .where((entry) => entry.key.startsWith('pda.'))
        .map((entry) => entry.value.body.toLowerCase())
        .join('\n');

    for (final term in const [
      'input symbol',
      'pop symbol',
      'push symbol',
      'initial stack symbol',
      'current stack',
      'remaining input',
    ]) {
      expect(englishBodies, contains(term), reason: 'English: $term');
    }
    for (final term in const [
      'símbolo de entrada',
      'símbolo de pop',
      'símbolo de push',
      'símbolo inicial da pilha',
      'pilha atual',
      'entrada restante',
    ]) {
      expect(portugueseBodies, contains(term), reason: 'Portuguese: $term');
    }
  });

  test('pda copy names all six visible analysis controls', () {
    final englishBodies = enHelpCatalogCopy.entries.entries
        .where((entry) => entry.key.startsWith('pda.editor.algorithms.'))
        .map((entry) => entry.value.body)
        .join('\n');
    final portugueseBodies = ptHelpCatalogCopy.entries.entries
        .where((entry) => entry.key.startsWith('pda.editor.algorithms.'))
        .map((entry) => entry.value.body)
        .join('\n');

    for (final label in const [
      'Convert to CFG',
      'Simplify PDA',
      'Check Determinism',
      'Find Reachable States',
      'Language Analysis',
      'Stack Operations',
    ]) {
      expect(englishBodies, contains(label), reason: 'English: $label');
    }
    for (final label in const [
      'Converter para GLC',
      'Simplificar AP',
      'Verificar determinismo',
      'Encontrar estados alcançáveis',
      'Análise da linguagem',
      'Operações da pilha',
    ]) {
      expect(portugueseBodies, contains(label), reason: 'Portuguese: $label');
    }
  });

  test('pda simplification controls and warnings are localized', () {
    final english = AppLocalizationsEn();
    final portuguese = AppLocalizationsPt('pt_BR');

    expect(english.pdaSimplificationButtonTitle, 'Simplify PDA');
    expect(portuguese.pdaSimplificationButtonTitle, 'Simplificar AP');
    expect(
      english.pdaSimplificationSkippedSemantic,
      contains('uncertain states were retained'),
    );
    expect(
      portuguese.pdaSimplificationSkippedSemantic,
      contains('estados incertos foram mantidos'),
    );
    expect(
      portuguese.pdaSimplificationActiveAcceptance(
        portuguese.pdaAcceptanceBoth,
      ),
      'Aceitação ativa: estado final e pilha vazia',
    );
  });

  test('pda copy records unavailable and platform-limited controls', () {
    final englishViewport =
        enHelpCatalogCopy[HelpTopicIds.pdaEditorViewportAutoLayout]!.body;
    final portugueseViewport =
        ptHelpCatalogCopy[HelpTopicIds.pdaEditorViewportAutoLayout]!.body;
    final englishFiles =
        enHelpCatalogCopy[HelpTopicIds.pdaEditorFilesAndExamples]!.body;
    final portugueseFiles =
        ptHelpCatalogCopy[HelpTopicIds.pdaEditorFilesAndExamples]!.body;
    final englishPlayback =
        enHelpCatalogCopy[HelpTopicIds.pdaEditorSimulationResultsAndCanvas]!
            .body;
    final portuguesePlayback =
        ptHelpCatalogCopy[HelpTopicIds.pdaEditorSimulationResultsAndCanvas]!
            .body;

    expect(englishViewport, contains('does not expose Auto Layout'));
    expect(portugueseViewport, contains('não expõe Auto Layout'));
    expect(
      englishFiles,
      contains('does not offer PDA JFLAP or JSON import or save actions'),
    );
    expect(
      portugueseFiles,
      contains('não oferece ações de importar ou salvar AP em JFLAP ou JSON'),
    );
    expect(
      englishPlayback,
      contains('narrow iOS layout below 1024 logical pixels'),
    );
    expect(
      portuguesePlayback,
      contains('layout estreito no iOS com menos de 1.024 pixels lógicos'),
    );
  });

  test('workspace help lists all five examples behind Algorithms', () {
    final topics = <String, List<String>>{
      HelpTopicIds.fsaEditorFilesAndExamples: const [
        'AFD - Termina com A',
        'AFD - Binário divisível por 3',
        'AFD - Paridade AB',
        'AFD - Contém AB',
        'AFNε - A ou AB',
      ],
      HelpTopicIds.grammarEditorFilesAndExamples: const [
        'GLC - Palíndromo',
        'GLC - Parênteses balanceados',
        'GLC - a^n b^n',
        'GLC - Zeros em quantidade par',
        'GLC - Expressões aritméticas',
      ],
      HelpTopicIds.pdaEditorFilesAndExamples: const [
        'APD - Parênteses Balanceados',
        'APD - a^n b^n',
        'APD - Palíndromo',
        'APD - a^n b^2n',
        'APD - w#reverse(w)',
      ],
      HelpTopicIds.regexEditorOverview: const [
        'Regex - Repetição de A',
        'Regex - Termina com AB',
        'Regex - Binário iniciado por 0',
        'Regex - Pares AB ou BA',
        'Regex - Blocos de A e B',
      ],
    };

    for (final entry in topics.entries) {
      final english = enHelpCatalogCopy[entry.key]!.body;
      final portuguese = ptHelpCatalogCopy[entry.key]!.body;
      expect(english, contains('Algorithms'), reason: entry.key);
      expect(portuguese, contains('Algoritmos'), reason: entry.key);
      for (final example in entry.value) {
        expect(english, contains(example), reason: 'English: $example');
        expect(portuguese, contains(example), reason: 'Portuguese: $example');
      }
    }
  });

  test('pda history copy separates graph, playback, and stack effects', () {
    final english =
        enHelpCatalogCopy[HelpTopicIds.pdaEditorHistoryAndClear]!.body;
    final portuguese =
        ptHelpCatalogCopy[HelpTopicIds.pdaEditorHistoryAndClear]!.body;

    expect(
      english,
      contains('Undo and Redo restore the PDA graph and refresh validation.'),
    );
    expect(
      english,
      contains('A model edit during canvas playback stops that playback.'),
    );
    expect(
      english,
      contains('The displayed stack is not part of Undo or Redo history'),
    );
    expect(
      english,
      contains('can remain as the previous snapshot after playback stops'),
    );
    expect(
      english,
      contains(
        'Only Clear canvas explicitly stops playback and clears the displayed stack together with the graph.',
      ),
    );

    expect(
      portuguese,
      contains(
        'Desfazer e Refazer restauram o grafo da AP e atualizam a validação.',
      ),
    );
    expect(
      portuguese,
      contains(
        'Uma edição do modelo durante a reprodução no canvas encerra essa reprodução.',
      ),
    );
    expect(
      portuguese,
      contains(
        'A pilha exibida não faz parte do histórico de Desfazer ou Refazer',
      ),
    );
    expect(
      portuguese,
      contains(
        'pode permanecer como o instantâneo anterior após o fim da reprodução',
      ),
    );
    expect(
      portuguese,
      contains(
        'Somente Limpar canvas encerra explicitamente a reprodução e limpa a pilha exibida junto com o grafo.',
      ),
    );
  });

  test('tm keeps editor before theory and exposes every analysis control', () {
    final tm = kHelpCatalog.nodeById('tm')! as HelpCategoryDefinition;

    expect(tm.children.map((node) => node.id), ['tm.editor', 'tm.theory']);
    expect(
      topicIdsUnder(kHelpCatalog, 'tm.editor.algorithms'),
      containsAll({
        'tm.editor.algorithms.decidability',
        'tm.editor.algorithms.reachable-states',
        'tm.editor.algorithms.language',
        'tm.editor.algorithms.tape-operations',
        'tm.editor.algorithms.time',
        'tm.editor.algorithms.space',
      }),
    );
  });

  test('tm copy documents transition, tape, and complexity vocabulary', () {
    final englishBodies = enHelpCatalogCopy.entries.entries
        .where((entry) => entry.key.startsWith('tm.'))
        .map((entry) => entry.value.body.toLowerCase())
        .join('\n');
    final portugueseBodies = ptHelpCatalogCopy.entries.entries
        .where((entry) => entry.key.startsWith('tm.'))
        .map((entry) => entry.value.body.toLowerCase())
        .join('\n');

    for (final term in const [
      'read symbol',
      'write symbol',
      'head movement',
      'tape',
      'blank symbol',
      'time',
      'space',
    ]) {
      expect(englishBodies, contains(term), reason: 'English: $term');
    }
    for (final term in const [
      'símbolo lido',
      'símbolo escrito',
      'movimento do cabeçote',
      'fita',
      'símbolo branco',
      'tempo',
      'espaço',
    ]) {
      expect(portugueseBodies, contains(term), reason: 'Portuguese: $term');
    }
  });

  test('tm copy names all six visible analysis controls', () {
    final englishBodies = enHelpCatalogCopy.entries.entries
        .where((entry) => entry.key.startsWith('tm.editor.algorithms.'))
        .map((entry) => entry.value.body)
        .join('\n');
    final portugueseBodies = ptHelpCatalogCopy.entries.entries
        .where((entry) => entry.key.startsWith('tm.editor.algorithms.'))
        .map((entry) => entry.value.body)
        .join('\n');

    for (final label in const [
      'Termination and Cycles',
      'Reachability',
      'Language Explorer',
      'Tape Trace',
      'Time Profile',
      'Space Profile',
    ]) {
      expect(englishBodies, contains(label), reason: 'English: $label');
    }
    for (final label in const [
      'Término e ciclos',
      'Alcançabilidade',
      'Explorador de linguagem',
      'Traço da fita',
      'Perfil de tempo',
      'Perfil de espaço',
    ]) {
      expect(portugueseBodies, contains(label), reason: 'Portuguese: $label');
    }
  });

  test('tm copy records multi-tape, analysis, and platform boundaries', () {
    final englishTape =
        enHelpCatalogCopy['tm.editor.tape.blank-and-alphabet']!.body;
    final portugueseTape =
        ptHelpCatalogCopy['tm.editor.tape.blank-and-alphabet']!.body;
    final englishDecidability =
        enHelpCatalogCopy['tm.editor.algorithms.decidability']!.body;
    final portugueseDecidability =
        ptHelpCatalogCopy['tm.editor.algorithms.decidability']!.body;
    final englishFiles =
        enHelpCatalogCopy['tm.editor.files-and-examples']!.body;
    final portugueseFiles =
        ptHelpCatalogCopy['tm.editor.files-and-examples']!.body;
    final englishPlayback =
        enHelpCatalogCopy['tm.editor.simulation.results-and-canvas']!.body;
    final portuguesePlayback =
        ptHelpCatalogCopy['tm.editor.simulation.results-and-canvas']!.body;

    expect(englishTape, contains('tape-count controls'));
    expect(englishTape, contains('one explicit operation per tape'));
    expect(portugueseTape, contains('controles da quantidade de fitas'));
    expect(portugueseTape, contains('uma operação explícita por fita'));
    expect(
      englishDecidability,
      contains('makes no claim about termination on every input'),
    );
    expect(
      portugueseDecidability,
      contains('não faz afirmação sobre término em todas as entradas'),
    );
    expect(
      englishFiles,
      contains('import and export JFLAP XML and Turing Lab JSON'),
    );
    expect(
      portugueseFiles,
      contains('importar e exportar XML do JFLAP e JSON do Turing Lab'),
    );
    expect(
      englishPlayback,
      contains('narrow iOS layout below 1024 logical pixels'),
    );
    expect(
      portuguesePlayback,
      contains('layout estreito no iOS com menos de 1.024 pixels lógicos'),
    );
  });

  test('tm building-block library guidance is structured and bilingual', () {
    const topicId = 'tm.editor.building-blocks.manage-library';
    final topic = kHelpCatalog.nodeById(topicId)! as HelpTopicDefinition;

    expect(
      topic.relatedTopicIds,
      contains('tm.editor.building-blocks.library-and-execution'),
    );
    expect(topic.relatedTopicIds, contains('tm.editor.overview'));
    expect(topic.relatedTopicIds, contains('tm.editor.files-and-examples'));
  });

  test('tm copy records execution bounds and every bundled example', () {
    final englishSimulation =
        enHelpCatalogCopy['tm.editor.simulation.workflow']!.body;
    final portugueseSimulation =
        ptHelpCatalogCopy['tm.editor.simulation.workflow']!.body;
    final englishFiles =
        enHelpCatalogCopy['tm.editor.files-and-examples']!.body;
    final portugueseFiles =
        ptHelpCatalogCopy['tm.editor.files-and-examples']!.body;

    expect(englishSimulation, contains('10,000 deterministic steps'));
    expect(
      englishSimulation,
      contains('100,000 nondeterministic configurations'),
    );
    expect(portugueseSimulation, contains('10.000 passos determinísticos'));
    expect(
      portugueseSimulation,
      contains('100.000 configurações não determinísticas'),
    );

    for (final example in const [
      'MT - a^n b^n',
      'MT - Binário para unário',
      'MT - Cópia de string',
      'MT - Incremento binário',
      'MT - Verificador de palíndromo',
    ]) {
      expect(englishFiles, contains(example), reason: 'English: $example');
      expect(
        portugueseFiles,
        contains(example),
        reason: 'Portuguese: $example',
      );
    }
  });

  test('every tm node is searchable by both acronyms in both locales', () {
    final tmNodeIds = kHelpCatalog.nodes
        .map((node) => node.id)
        .where((id) => id == 'tm' || id.startsWith('tm.'));

    for (final nodeId in tmNodeIds) {
      expect(
        enHelpCatalogCopy[nodeId]!.keywords,
        containsAll(const ['TM', 'MT']),
        reason: 'English keywords: $nodeId',
      );
      expect(
        ptHelpCatalogCopy[nodeId]!.keywords,
        containsAll(const ['TM', 'MT']),
        reason: 'Portuguese keywords: $nodeId',
      );
    }
  });

  test('tm tape analysis documents branch and multi-tape metrics', () {
    final english =
        enHelpCatalogCopy['tm.editor.algorithms.tape-operations']!.body;
    final portuguese =
        ptHelpCatalogCopy['tm.editor.algorithms.tape-operations']!.body;

    expect(english, contains('measures one real branch'));
    expect(english, contains('Defined but unexecuted transitions'));
    expect(english, contains('per-tape metrics'));
    expect(portuguese, contains('mede um ramo real'));
    expect(portuguese, contains('Transições definidas mas não executadas'));
    expect(portuguese, contains('métricas por fita'));
  });

  test(
    'regex and pumping keep editor before theory with approved inventories',
    () {
      final regex = kHelpCatalog.nodeById('regex')! as HelpCategoryDefinition;
      final pumping =
          kHelpCatalog.nodeById('pumping')! as HelpCategoryDefinition;

      expect(regex.children.map((node) => node.id), [
        'regex.editor',
        'regex.theory',
      ]);
      expect(pumping.children.map((node) => node.id), [
        'pumping.editor',
        'pumping.theory',
      ]);
      expect(topicIdsUnder(kHelpCatalog, 'regex'), [
        'regex.editor.overview',
        'regex.editor.input-and-validation',
        'regex.editor.alphabet',
        'regex.editor.test-strings',
        'regex.editor.conversions.overview',
        'regex.editor.conversions.to-nfa',
        'regex.editor.conversions.to-dfa',
        'regex.editor.conversions.fa-to-regex',
        'regex.editor.simplification',
        'regex.editor.complexity',
        'regex.editor.sample-strings',
        'regex.editor.equivalence',
        'regex.editor.embedded-fsa-panels',
        'regex.theory.regex',
        'regex.theory.literals-and-grouping',
        'regex.theory.concatenation-and-union',
        'regex.theory.kleene-star-and-plus',
        'regex.theory.optional',
        'regex.theory.precedence',
        'regex.theory.lambda',
        'regex.theory.regular-languages',
        'regex.theory.equivalence-with-fsa',
      ]);
      expect(topicIdsUnder(kHelpCatalog, 'pumping'), [
        'pumping.editor.environment-choice',
        'pumping.editor.overview',
        'pumping.editor.game',
        'pumping.editor.difficulty-and-challenges',
        'pumping.editor.regularity-choice',
        'pumping.editor.witness-and-decomposition',
        'pumping.editor.pumping-choice-and-submit',
        'pumping.editor.feedback-retry-and-practice',
        'pumping.editor.progress',
        'pumping.editor.responsive-layout',
        'pumping.theory.statement',
        'pumping.theory.quantifiers',
        'pumping.theory.proof-strategy',
        'pumping.theory.choose-witness',
        'pumping.theory.all-decompositions',
        'pumping.theory.contradiction',
        'pumping.theory.limitations',
        'pumping.theory.regular-example',
        'pumping.theory.nonregular-anbn',
        'pumping.theory.nonregular-ww',
      ]);
    },
  );

  test('regex theory copy names every supported operator in both locales', () {
    final english = enHelpCatalogCopy.entries.entries
        .where((entry) => entry.key.startsWith('regex.theory.'))
        .map((entry) => entry.value.body)
        .join('\n');
    final portuguese = ptHelpCatalogCopy.entries.entries
        .where((entry) => entry.key.startsWith('regex.theory.'))
        .map((entry) => entry.value.body)
        .join('\n');

    for (final label in const [
      'literal',
      'grouping ( )',
      'concatenation',
      'union |',
      'Kleene star *',
      'plus +',
      'optional ?',
      'wildcard .',
      'character class [ ]',
      r'shortcuts \d, \D, \s, \S, \w, and \W',
      'epsilon ε',
    ]) {
      expect(english, contains(label), reason: 'English: $label');
    }
    for (final label in const [
      'literal',
      'agrupamento ( )',
      'concatenação',
      'união |',
      'estrela de Kleene *',
      'mais +',
      'opcional ?',
      'curinga .',
      'classe de caracteres [ ]',
      r'atalhos \d, \D, \s, \S, \w e \W',
      'epsilon ε',
    ]) {
      expect(portuguese, contains(label), reason: 'Portuguese: $label');
    }
  });

  test('pumping progress copy names all four visible metrics', () {
    final english = enHelpCatalogCopy['pumping.editor.progress']!.body
        .toLowerCase();
    final portuguese = ptHelpCatalogCopy['pumping.editor.progress']!.body
        .toLowerCase();

    for (final label in const ['accuracy', 'correct', 'attempts', 'score']) {
      expect(english, contains(label), reason: 'English: $label');
    }
    for (final label in const [
      'precisão',
      'corretas',
      'tentativas',
      'pontuação',
    ]) {
      expect(portuguese, contains(label), reason: 'Portuguese: $label');
    }
    final portugueseVisibleLabels =
        ptHelpCatalogCopy['pumping.editor.progress']!.body;
    for (final label in const ['Accuracy', 'Correct', 'Attempts', 'Score']) {
      expect(
        portugueseVisibleLabels,
        contains(label),
        reason: 'Visible Portuguese UI label: $label',
      );
    }
  });

  test('pumping theory preserves quantifiers and the one-way limitation', () {
    final english = enHelpCatalogCopy['pumping.theory.quantifiers']!.body;
    final portuguese = ptHelpCatalogCopy['pumping.theory.quantifiers']!.body;
    final englishLimit = enHelpCatalogCopy['pumping.theory.limitations']!.body;
    final portugueseLimit =
        ptHelpCatalogCopy['pumping.theory.limitations']!.body;

    expect(
      english,
      contains(
        'For every regular language L, there exists p ≥ 1 such that for every s ∈ L with |s| ≥ p, there exists a decomposition s = xyz such that |xy| ≤ p, |y| > 0, and for every k ≥ 0, xyᵏz ∈ L.',
      ),
    );
    expect(
      portuguese,
      contains(
        'Para toda linguagem regular L, existe p ≥ 1 tal que, para toda s ∈ L com |s| ≥ p, existe uma decomposição s = xyz tal que |xy| ≤ p, |y| > 0 e, para todo k ≥ 0, xyᵏz ∈ L.',
      ),
    );
    expect(
      englishLimit,
      contains('proves non-regularity; it does not prove regularity'),
    );
    expect(
      portugueseLimit,
      contains('prova não regularidade; ele não prova regularidade'),
    );
  });

  test('production catalog has a valid recursive structure', () {
    expect(kHelpCatalog.validateStructure(), isEmpty);
  });

  test('every related topic resolves to a catalog topic', () {
    final topicIds = kHelpCatalog.topicIds.toSet();

    for (final topic in kHelpCatalog.nodes.whereType<HelpTopicDefinition>()) {
      for (final relatedTopicId in topic.relatedTopicIds) {
        expect(
          topicIds,
          contains(relatedTopicId),
          reason: '${topic.id} -> $relatedTopicId',
        );
      }
    }
  });

  test('every stable routing destination appears in the catalog', () {
    const routingDestinations = [
      HelpTopicIds.gettingStartedQuickStart,
      HelpTopicIds.fsaEditorOverview,
      HelpTopicIds.fsaTheoryDfa,
      HelpTopicIds.fsaTheoryNfa,
      HelpTopicIds.fsaTheoryEpsilon,
      HelpTopicIds.pdaEditorOverview,
      HelpTopicIds.pdaEditorSimulation,
      HelpTopicIds.pdaTheoryPda,
      HelpTopicIds.tmEditorOverview,
      HelpTopicIds.tmTheoryTm,
      HelpTopicIds.grammarEditorOverview,
      HelpTopicIds.grammarEditorAlgorithms,
      HelpTopicIds.grammarTheoryCfg,
      HelpTopicIds.regexEditorInput,
      HelpTopicIds.regexEditorConversions,
      HelpTopicIds.pumpingEditorGame,
      HelpTopicIds.shortcutsCanvas,
    ];

    expect(kHelpCatalog.topicIds, containsAll(routingDestinations));
  });

  test('every topic has complete English and Portuguese copy', () {
    expect(kHelpCatalog.validateCopy(enHelpCatalogCopy), isEmpty);
    expect(kHelpCatalog.validateCopy(ptHelpCatalogCopy), isEmpty);
  });

  test('English and Portuguese contain every current node', () {
    for (final node in kHelpCatalog.nodes) {
      expect(enHelpCatalogCopy.contains(node.id), isTrue, reason: node.id);
      expect(ptHelpCatalogCopy.contains(node.id), isTrue, reason: node.id);
      expect(enHelpCatalogCopy[node.id]!.title.trim(), isNotEmpty);
      expect(ptHelpCatalogCopy[node.id]!.title.trim(), isNotEmpty);
      if (node is HelpTopicDefinition) {
        expect(enHelpCatalogCopy[node.id]!.body.trim(), isNotEmpty);
        expect(ptHelpCatalogCopy[node.id]!.body.trim(), isNotEmpty);
        expect(enHelpCatalogCopy[node.id]!.keywords, isNotEmpty);
        expect(ptHelpCatalogCopy[node.id]!.keywords, isNotEmpty);
      }
    }
  });

  test('validateCopy reports missing, orphaned, and incomplete entries', () {
    final copy = HelpCatalogCopy({
      'getting-started': HelpNodeCopy(title: 'Getting started'),
      'getting-started.quick-start': HelpNodeCopy(
        title: 'Quick start',
        body: 'Complete topic body.',
      ),
      'orphan': HelpNodeCopy(title: 'Orphan', body: 'Unused copy'),
    });

    final messages = kHelpCatalog.validateCopy(copy);

    expect(messages, contains(contains('missing')));
    expect(messages, contains(contains('orphan')));
    expect(messages, contains(contains('incomplete')));
  });

  test('copy completeness rejects whitespace-only keywords consistently', () {
    final catalog = HelpCatalog(
      roots: [
        HelpCategoryDefinition(
          id: 'root',
          icon: 'help',
          children: [HelpTopicDefinition(id: 'root.topic', icon: 'help')],
        ),
      ],
    );
    final copy = HelpCatalogCopy({
      'root': HelpNodeCopy(title: 'Root'),
      'root.topic': HelpNodeCopy(
        title: 'Topic',
        body: 'Complete body.',
        keywords: ['  ', '\n'],
      ),
    });

    expect(
      catalog.validateCopy(copy),
      contains('incomplete localized entry: root.topic'),
    );
    expect(catalog.hasCompleteHelpCopy(copy, 'root.topic'), isFalse);
  });

  test('catalog copy lookup follows locale without cross-locale fallback', () {
    final englishFixture = HelpCatalogCopy({
      'english-only': HelpNodeCopy(
        title: 'English only',
        body: 'Only the English fixture contains this topic.',
      ),
    });
    final portugueseFixture = HelpCatalogCopy({
      'portuguese-only': HelpNodeCopy(
        title: 'Somente português',
        body: 'Somente o mapa em português contém este tópico.',
      ),
    });
    final selectedPortuguese = selectHelpCatalogCopy(
      localeName: 'pt_BR',
      english: englishFixture,
      portuguese: portugueseFixture,
    );
    final selectedEnglish = selectHelpCatalogCopy(
      localeName: 'es',
      english: englishFixture,
      portuguese: portugueseFixture,
    );
    final english = AppLocalizationsEn();
    final portuguese = AppLocalizationsPt('pt_BR');

    expect(selectedPortuguese, same(portugueseFixture));
    expect(selectedPortuguese['english-only'], isNull);
    expect(selectedEnglish, same(englishFixture));
    expect(selectedEnglish['portuguese-only'], isNull);
    expect(english.helpCatalogCopy, same(enHelpCatalogCopy));
    expect(portuguese.helpCatalogCopy, same(ptHelpCatalogCopy));
    expect(english.hasCompleteHelpCopy('missing'), isFalse);
    expect(
      portuguese.helpNodeCopy('getting-started')!.title,
      'Primeiros passos',
    );
  });

  test('history copy documents every accepted Apple modifier variant', () {
    final english =
        enHelpCatalogCopy[HelpTopicIds.fsaEditorHistoryAndClear]!.body;
    final portuguese =
        ptHelpCatalogCopy[HelpTopicIds.fsaEditorHistoryAndClear]!.body;

    expect(english, contains('Apple platforms with a physical keyboard'));
    expect(english, contains('Cmd+Z'));
    expect(english, contains('Cmd+Y'));
    expect(english, contains('Cmd+Shift+Z'));
    expect(portuguese, contains('plataformas Apple com teclado físico'));
    expect(portuguese, contains('Cmd+Z'));
    expect(portuguese, contains('Cmd+Y'));
    expect(portuguese, contains('Cmd+Shift+Z'));
  });

  test('closure copy separates the mathematical and command requirements', () {
    final english =
        enHelpCatalogCopy[HelpTopicIds.fsaTheoryClosureOperations]!.body;
    final portuguese =
        ptHelpCatalogCopy[HelpTopicIds.fsaTheoryClosureOperations]!.body;
    final normalizedEnglish = english.toLowerCase();
    final normalizedPortuguese = portuguese.toLowerCase();

    expect(
      normalizedEnglish,
      contains('mathematical complement assumes a total'),
    );
    expect(
      normalizedEnglish,
      contains('completes missing transitions internally'),
    );
    expect(normalizedEnglish, contains('deterministic'));
    expect(english, contains('ε transitions'));
    expect(
      normalizedPortuguese,
      contains('complemento matemático pressupõe uma função'),
    );
    expect(
      normalizedPortuguese,
      contains('completa internamente as transições ausentes'),
    );
    expect(normalizedPortuguese, contains('determinística'));
    expect(portuguese, contains('transições ε'));
  });

  test('active automata, grammar, and PDA help presents canonical epsilon', () {
    const topicIds = [
      HelpTopicIds.fsaEditorTransitions,
      HelpTopicIds.fsaEditorAlgorithmsOverview,
      HelpTopicIds.fsaEditorAlgorithmsRemoveLambda,
      HelpTopicIds.fsaTheoryEpsilon,
      HelpTopicIds.fsaTheoryEpsilonClosure,
      HelpTopicIds.grammarEditorProductionLambda,
      HelpTopicIds.pdaEditorTransitions,
      HelpTopicIds.pdaEditorLambdaSwitches,
    ];

    for (final topicId in topicIds) {
      for (final copy in [
        enHelpCatalogCopy[topicId]!,
        ptHelpCatalogCopy[topicId]!,
      ]) {
        final visibleCopy = '${copy.title}\n${copy.body}';
        expect(
          visibleCopy.toLowerCase(),
          anyOf(contains('ε'), contains('epsilon')),
          reason: topicId,
        );
        expect(visibleCopy, isNot(contains('λ')), reason: topicId);
        expect(
          visibleCopy.toLowerCase(),
          isNot(contains('lambda')),
          reason: topicId,
        );
      }
    }
  });

  test('grammar conversion copy distinguishes disablement from runtime errors', () {
    const topicIds = [
      HelpTopicIds.grammarEditorConversionsRightLinearToFsa,
      HelpTopicIds.grammarEditorConversionsPdaGeneral,
      HelpTopicIds.grammarEditorConversionsPdaStandard,
      HelpTopicIds.grammarEditorConversionsPdaGreibach,
    ];

    for (final topicId in topicIds) {
      final english = enHelpCatalogCopy[topicId]!.body;
      final portuguese = ptHelpCatalogCopy[topicId]!.body;

      expect(
        english,
        contains(
          'No productions or any conversion already running disables this control.',
        ),
        reason: 'English disablement: $topicId',
      );
      expect(
        english,
        contains(
          'An invalid start symbol or another conversion failure does not disable a non-empty grammar in advance; it returns an error after activation.',
        ),
        reason: 'English runtime failure: $topicId',
      );
      expect(
        portuguese,
        contains(
          'A ausência de produções ou qualquer conversão já em andamento desativa este controle.',
        ),
        reason: 'Portuguese disablement: $topicId',
      );
      expect(
        portuguese,
        contains(
          'Um símbolo inicial inválido ou outra falha de conversão não desativa previamente uma gramática não vazia; a falha retorna como erro após o acionamento.',
        ),
        reason: 'Portuguese runtime failure: $topicId',
      );
    }
  });

  test('grammar file copy matches platform labels and recovery actions', () {
    final english =
        enHelpCatalogCopy[HelpTopicIds.grammarEditorFilesAndExamples]!.body;
    final portuguese =
        ptHelpCatalogCopy[HelpTopicIds.grammarEditorFilesAndExamples]!.body;

    expect(
      english,
      contains(
        'Load JFLAP is available on every platform when the panel is mounted.',
      ),
    );
    expect(
      english,
      contains(
        'Save as JFLAP and Export SVG on native platforms to Download JFLAP and Download SVG on the web',
      ),
    );
    expect(
      english,
      contains(
        'Retry with Cancel in the dialog or Retry with Dismiss in the banner; there is no Report action.',
      ),
    );
    expect(english, isNot(contains('retry/report actions')));

    expect(
      portuguese,
      contains(
        'Load JFLAP fica disponível em todas as plataformas quando o painel está montado.',
      ),
    );
    expect(
      portuguese,
      contains(
        'Save as JFLAP e Export SVG nas plataformas nativas para Download JFLAP e Download SVG na Web',
      ),
    );
    expect(
      portuguese,
      contains(
        'Retry com Cancel no diálogo ou Retry com Dismiss no banner; não existe ação Report.',
      ),
    );
    expect(portuguese, isNot(contains('repetir ou relatar')));
  });

  test('shortcut copy records real scope and platform modifiers', () {
    final english = [
      enHelpCatalogCopy['shortcuts.canvas']!.body,
      enHelpCatalogCopy['shortcuts.platform-modifiers']!.body,
    ].join('\n');
    final portuguese = [
      ptHelpCatalogCopy['shortcuts.canvas']!.body,
      ptHelpCatalogCopy['shortcuts.platform-modifiers']!.body,
    ].join('\n');

    for (final shortcut in const [
      'A',
      'T',
      'V',
      'Delete',
      'Backspace',
      'Ctrl+Z',
      'Cmd+Z',
      'Ctrl+Y',
      'Cmd+Y',
      'Ctrl+Shift+Z',
      'Cmd+Shift+Z',
    ]) {
      expect(english, contains(shortcut), reason: 'English: $shortcut');
      expect(portuguese, contains(shortcut), reason: 'Portuguese: $shortcut');
    }
    expect(english, contains('physical keyboard'));
    expect(english, contains('text field'));
    expect(portuguese, contains('teclado físico'));
    expect(portuguese, contains('campo de texto'));
  });

  test('quick start topic preserves the former dialog guidance', () {
    final english =
        enHelpCatalogCopy[HelpTopicIds.gettingStartedQuickStart]!.body;
    final portuguese =
        ptHelpCatalogCopy[HelpTopicIds.gettingStartedQuickStart]!.body;

    for (final guidance in const [
      'navigation tabs or section chips',
      'open a supported file',
      'Double-tap',
      'Pinch to zoom',
      'algorithms to transform structures',
      'Quick Start icon',
    ]) {
      expect(english, contains(guidance), reason: 'English: $guidance');
    }
    for (final guidance in const [
      'abas de navegação ou chips de seção',
      'abra um arquivo compatível',
      'Toque duas vezes',
      'Faça pinça',
      'algoritmos para transformar estruturas',
      'ícone de guia rápido',
    ]) {
      expect(portuguese, contains(guidance), reason: 'Portuguese: $guidance');
    }
  });

  test('getting-started guidance names every registered workspace family', () {
    final englishNavigation =
        enHelpCatalogCopy[HelpTopicIds.gettingStartedNavigation]!;
    final englishChoice =
        enHelpCatalogCopy[HelpTopicIds.gettingStartedChooseWorkspace]!;
    final portugueseNavigation =
        ptHelpCatalogCopy[HelpTopicIds.gettingStartedNavigation]!;
    final portugueseChoice =
        ptHelpCatalogCopy[HelpTopicIds.gettingStartedChooseWorkspace]!;

    for (final name in const [
      'Mealy',
      'Moore',
      'Unrestricted grammar',
      'L-system',
    ]) {
      expect(englishNavigation.body, contains(name), reason: name);
      expect(englishChoice.body, contains(name), reason: name);
      expect(
        englishNavigation.keywords.join('\n').toLowerCase(),
        contains(name.toLowerCase()),
        reason: name,
      );
      expect(
        englishChoice.keywords.join('\n').toLowerCase(),
        contains(name.toLowerCase()),
        reason: name,
      );
    }
    for (final name in const [
      'Mealy',
      'Moore',
      'Gramática irrestrita',
      'Sistema L',
    ]) {
      expect(portugueseNavigation.body, contains(name), reason: name);
      expect(portugueseChoice.body, contains(name), reason: name);
      expect(
        portugueseNavigation.keywords.join('\n').toLowerCase(),
        contains(name.toLowerCase()),
        reason: name,
      );
      expect(
        portugueseChoice.keywords.join('\n').toLowerCase(),
        contains(name.toLowerCase()),
        reason: name,
      );
    }
  });

  test('navigation localization resolves the new workspace identifiers', () {
    final english = AppLocalizationsEn();
    final portuguese = AppLocalizationsPt('pt_BR');

    for (final (id, label, description) in const [
      ('mealy', 'Mealy', 'Edit and simulate Mealy transducers.'),
      ('moore', 'Moore', 'Edit and simulate Moore transducers.'),
      (
        'unrestrictedGrammar',
        'Unrestricted grammar',
        'Classify phrase-structure grammars and explore bounded derivations.',
      ),
      (
        'lSystem',
        'L-system',
        'Expand parallel rewrite systems and render turtle graphics.',
      ),
    ]) {
      expect(english.homeNavigationLabel(id), label, reason: id);
      expect(english.homeNavigationDescription(id), description, reason: id);
    }

    for (final (id, label, description) in const [
      ('mealy', 'Mealy', 'Edite e simule transdutores Mealy.'),
      ('moore', 'Moore', 'Edite e simule transdutores Moore.'),
      (
        'unrestrictedGrammar',
        'Gramática irrestrita',
        'Classifique gramáticas de estrutura de frase e explore derivações limitadas.',
      ),
      (
        'lSystem',
        'Sistema L',
        'Expanda sistemas de reescrita paralela e renderize gráficos de tartaruga.',
      ),
    ]) {
      expect(portuguese.homeNavigationLabel(id), label, reason: id);
      expect(portuguese.homeNavigationDescription(id), description, reason: id);
    }

    expect(english.helpSectionTitle('transducers'), 'Transducers');
    expect(
      english.helpSectionTitle('extended-formal-systems'),
      'Extended formal systems',
    );
    expect(portuguese.helpSectionTitle('transducers'), 'Transdutores');
    expect(
      portuguese.helpSectionTitle('extended-formal-systems'),
      'Sistemas formais estendidos',
    );
  });

  test('troubleshooting copy gives localized recovery actions', () {
    final english = enHelpCatalogCopy.entries.entries
        .where((entry) => entry.key.startsWith('troubleshooting.'))
        .map((entry) => entry.value.body)
        .join('\n');
    final portuguese = ptHelpCatalogCopy.entries.entries
        .where((entry) => entry.key.startsWith('troubleshooting.'))
        .map((entry) => entry.value.body)
        .join('\n');

    for (final fact in const [
      'initial state',
      'accepting state',
      'Automatic (Earley)',
      'Brute force',
      '5-second',
      'very large automata',
      'dense transition graphs',
      'Fit to content',
      'Reset view',
    ]) {
      expect(english, contains(fact), reason: 'English: $fact');
    }
    for (final fact in const [
      'estado inicial',
      'estado de aceitação',
      'Automatic (Earley)',
      'Brute force',
      '5 segundos',
      'autômatos muito grandes',
      'grafos com muitas transições',
      'Ajustar ao conteúdo',
      'Redefinir visualização',
    ]) {
      expect(portuguese, contains(fact), reason: 'Portuguese: $fact');
    }

    final englishFiles =
        enHelpCatalogCopy[HelpTopicIds.troubleshootingFileImportExport]!.body;
    final portugueseFiles =
        ptHelpCatalogCopy[HelpTopicIds.troubleshootingFileImportExport]!.body;
    expect(englishFiles, contains('supported file that is not corrupted'));
    expect(englishFiles, isNot(contains('unmodified supported file')));
    expect(
      portugueseFiles,
      contains('arquivo compatível que não esteja corrompido'),
    );
    expect(portugueseFiles, isNot(contains('arquivo compatível não alterado')));
  });

  test(
    'about copy preserves project, license, credit, and distribution facts',
    () {
      final english = enHelpCatalogCopy.entries.entries
          .where((entry) => entry.key.startsWith('about.'))
          .map((entry) => entry.value.body)
          .join('\n');
      final portuguese = ptHelpCatalogCopy.entries.entries
          .where((entry) => entry.key.startsWith('about.'))
          .map((entry) => entry.value.body)
          .join('\n');

      for (final fact in const [
        'Thales Matheus Mendonça Santos',
        'https://github.com/ThalesMMS/Turing-Lab',
        'Apache License 2.0',
        'JFLAP 7.1 License',
        'GraphView',
        'Susan H. Rodger',
        'Duke University',
        'http://www.jflap.org',
        'free, non-monetized educational app',
      ]) {
        expect(english, contains(fact), reason: 'English: $fact');
      }
      for (final fact in const [
        'Thales Matheus Mendonça Santos',
        'https://github.com/ThalesMMS/Turing-Lab',
        'Apache License 2.0',
        'Licença do JFLAP 7.1',
        'GraphView',
        'Susan H. Rodger',
        'Duke University',
        'http://www.jflap.org',
        'aplicativo educacional gratuito e não monetizado',
      ]) {
        expect(portuguese, contains(fact), reason: 'Portuguese: $fact');
      }
    },
  );
}
