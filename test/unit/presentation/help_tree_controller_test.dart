import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/constants/help_catalog.dart';
import 'package:turing_lab/core/constants/help_topic_ids.dart';
import 'package:turing_lab/core/models/help_catalog.dart';
import 'package:turing_lab/l10n/help_catalog_copy.dart';
import 'package:turing_lab/l10n/help_catalog_copy_en.dart';
import 'package:turing_lab/presentation/controllers/help_tree_controller.dart';
import 'package:turing_lab/presentation/widgets/help_search_highlight.dart';

final _searchCatalog = HelpCatalog(
  roots: [
    HelpCategoryDefinition(
      id: 'automata',
      icon: 'automata',
      children: [
        HelpSubsectionDefinition(
          id: 'automata.editor',
          icon: 'edit',
          children: [
            HelpTopicDefinition(id: 'topic.title', icon: 'topic'),
            HelpTopicDefinition(id: 'topic.body', icon: 'topic'),
            HelpTopicDefinition(id: 'topic.keyword', icon: 'topic'),
            HelpTopicDefinition(id: 'topic.literal', icon: 'topic'),
          ],
        ),
      ],
    ),
    HelpCategoryDefinition(
      id: 'grammar',
      icon: 'grammar',
      children: [HelpTopicDefinition(id: 'topic.unrelated', icon: 'topic')],
    ),
  ],
);

final _searchCopy = HelpCatalogCopy({
  'automata': HelpNodeCopy(title: 'Automata'),
  'automata.editor': HelpNodeCopy(title: 'Editor and canvas'),
  'topic.title': HelpNodeCopy(
    title: 'Alpha topic',
    body: 'Ordinary body.',
    keywords: ['ordinary'],
  ),
  'topic.body': HelpNodeCopy(
    title: 'Body topic',
    body: 'The needle appears in this body.',
    keywords: ['ordinary'],
  ),
  'topic.keyword': HelpNodeCopy(
    title: 'Keyword topic',
    body: 'Ordinary body.',
    keywords: ['secret keyword'],
  ),
  'topic.literal': HelpNodeCopy(
    title: 'Optional operator',
    body: 'Type a? after an operand.',
    keywords: ['question mark'],
  ),
  'grammar': HelpNodeCopy(title: 'Grammar'),
  'topic.unrelated': HelpNodeCopy(
    title: 'Unrelated topic',
    body: 'Different content.',
    keywords: ['different'],
  ),
});

void main() {
  group('HelpTreeController', () {
    test('toggle keeps several branches expanded', () {
      final controller = HelpTreeController(
        catalog: kHelpCatalog,
        copy: enHelpCatalogCopy,
      );

      controller.toggle('fsa');
      controller.toggle('grammar');
      controller.toggle('fsa.editor');

      expect(
        controller.expandedIds,
        containsAll(['fsa', 'grammar', 'fsa.editor']),
      );
    });

    test('toggle closes only the selected branch', () {
      final controller = HelpTreeController(
        catalog: kHelpCatalog,
        copy: enHelpCatalogCopy,
      );
      controller.toggle('fsa');
      controller.toggle('grammar');

      controller.toggle('fsa');

      expect(controller.expandedIds, isNot(contains('fsa')));
      expect(controller.expandedIds, contains('grammar'));
    });

    test('initial topic expands all ancestors and the topic', () {
      final controller = HelpTreeController(
        catalog: kHelpCatalog,
        copy: enHelpCatalogCopy,
        initialTopicId: HelpTopicIds.pdaEditorSimulation,
      );

      expect(
        controller.expandedIds,
        containsAll([
          'pda',
          'pda.editor',
          'pda.editor.simulation',
          HelpTopicIds.pdaEditorSimulation,
        ]),
      );
      expect(
        controller.consumePendingReveal(),
        HelpTopicIds.pdaEditorSimulation,
      );
      expect(controller.consumePendingReveal(), isNull);
    });

    test('general help expands only Getting started', () {
      final controller = HelpTreeController(
        catalog: kHelpCatalog,
        copy: enHelpCatalogCopy,
      );

      expect(controller.expandedIds, {'getting-started'});
      expect(controller.topicUnavailable, isFalse);
      expect(controller.consumePendingReveal(), isNull);
    });

    test('expanded IDs cannot be mutated by callers', () {
      final controller = HelpTreeController(
        catalog: kHelpCatalog,
        copy: enHelpCatalogCopy,
      );

      expect(() => controller.expandedIds.add('fsa'), throwsUnsupportedError);
      expect(controller.expandedIds, {'getting-started'});
    });

    test('invalid initial topic opens at the top and reports unavailable', () {
      final controller = HelpTreeController(
        catalog: kHelpCatalog,
        copy: enHelpCatalogCopy,
        initialTopicId: 'missing.topic',
      );

      expect(controller.expandedIds, isEmpty);
      expect(controller.topicUnavailable, isTrue);
      expect(controller.consumePendingReveal(), isNull);
    });

    test('reveal opens the target path without closing other branches', () {
      final controller = HelpTreeController(
        catalog: kHelpCatalog,
        copy: enHelpCatalogCopy,
      );
      controller.toggle('grammar');
      controller.toggle(HelpTopicIds.gettingStartedQuickStart);

      controller.revealTopic(HelpTopicIds.pdaEditorSimulation);

      expect(
        controller.expandedIds,
        containsAll([
          'grammar',
          HelpTopicIds.gettingStartedQuickStart,
          'pda',
          'pda.editor',
          'pda.editor.simulation',
          HelpTopicIds.pdaEditorSimulation,
        ]),
      );
    });

    test('title match retains the topic and expands its ancestor path', () {
      final result = searchHelpCatalog(
        _searchCatalog,
        _searchCopy,
        'ALPHA TOPIC',
      );

      expect(result.matchingTopicIds, {'topic.title'});
      expect(result.visibleNodeIds, {
        'automata',
        'automata.editor',
        'topic.title',
      });
      expect(result.expandedNodeIds, {
        'automata',
        'automata.editor',
        'topic.title',
      });
    });

    test('body match finds only the topic containing the literal text', () {
      final result = searchHelpCatalog(
        _searchCatalog,
        _searchCopy,
        'needle appears',
      );

      expect(result.matchingTopicIds, {'topic.body'});
    });

    test('keyword match finds only the topic carrying that keyword', () {
      final result = searchHelpCatalog(
        _searchCatalog,
        _searchCopy,
        'SECRET KEYWORD',
      );

      expect(result.matchingTopicIds, {'topic.keyword'});
    });

    test('group title match retains all topics below that group', () {
      final result = searchHelpCatalog(_searchCatalog, _searchCopy, 'automata');

      expect(result.matchingTopicIds, {
        'topic.title',
        'topic.body',
        'topic.keyword',
        'topic.literal',
      });
      expect(result.visibleNodeIds, isNot(contains('grammar')));
      expect(result.visibleNodeIds, isNot(contains('topic.unrelated')));
    });

    test('regex metacharacters stay literal', () {
      final result = searchHelpCatalog(_searchCatalog, _searchCopy, 'a?');

      expect(result.matchingTopicIds, {'topic.literal'});
    });

    test('query with no matches returns empty projection sets', () {
      final result = searchHelpCatalog(
        _searchCatalog,
        _searchCopy,
        'missing phrase',
      );

      expect(result.matchingTopicIds, isEmpty);
      expect(result.visibleNodeIds, isEmpty);
      expect(result.expandedNodeIds, isEmpty);
    });

    test('epsilon and lambda names and glyphs return equivalent topics', () {
      final results = [
        for (final query in ['epsilon', 'ε', 'ϵ', 'lambda', 'λ'])
          searchHelpCatalog(kHelpCatalog, enHelpCatalogCopy, query),
      ];

      for (final result in results.skip(1)) {
        expect(result.matchingTopicIds, results.first.matchingTopicIds);
      }
      expect(
        results.first.matchingTopicIds,
        contains(HelpTopicIds.fsaTheoryEpsilon),
      );
    });

    test('epsilon aliases highlight the formatted lambda copy', () {
      final spans = buildHelpHighlightSpans(
        'Use λ and lambda closure.',
        'epsilon',
        const TextStyle(),
        const TextStyle(backgroundColor: Colors.yellow),
      );
      final highlighted = spans.where(
        (span) => span.style?.backgroundColor == Colors.yellow,
      );

      expect(highlighted.map((span) => span.text), ['λ', 'lambda']);
    });

    test('clearing search restores prior expansions', () {
      final controller = HelpTreeController(
        catalog: _searchCatalog,
        copy: _searchCopy,
      );
      // The fixture starts expanded; collapse it before taking the snapshot.
      controller.toggle('getting-started');
      controller.toggle('automata');
      controller.toggle('grammar');

      controller.setQuery('needle');
      expect(controller.expandedIds, {
        'automata',
        'automata.editor',
        'topic.body',
      });

      controller.clearQuery();
      expect(controller.expandedIds, {'automata', 'grammar'});
    });

    test('updating an active query does not overwrite expansion snapshot', () {
      final controller = HelpTreeController(
        catalog: _searchCatalog,
        copy: _searchCopy,
      );
      // The fixture starts expanded; collapse it before taking the snapshot.
      controller.toggle('getting-started');
      controller.toggle('automata');
      controller.toggle('grammar');

      controller.setQuery('needle');
      controller.setQuery('secret keyword');
      controller.clearQuery();

      expect(controller.expandedIds, {'automata', 'grammar'});
    });

    test('search-required ancestor and topic cannot be collapsed', () {
      final controller = HelpTreeController(
        catalog: _searchCatalog,
        copy: _searchCopy,
      );
      controller.setQuery('needle');

      controller.toggle('automata.editor');
      controller.toggle('topic.body');

      expect(controller.expandedIds, {
        'automata',
        'automata.editor',
        'topic.body',
      });
    });

    test('an empty query is not a search', () {
      final controller = HelpTreeController(
        catalog: _searchCatalog,
        copy: _searchCopy,
      );

      controller.setQuery('   ');

      expect(controller.isSearching, isFalse);
      expect(controller.query, isEmpty);
      expect(controller.expandedIds, {'getting-started'});
    });
  });
}
