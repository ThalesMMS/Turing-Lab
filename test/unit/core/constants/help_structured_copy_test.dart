import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/core/constants/help_catalog.dart';
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
    final topics = kHelpCatalog.nodes.whereType<HelpTopicDefinition>().where(
      (topic) {
        final path = kHelpCatalog.pathForTopic(topic.id)!;
        return path.ancestorIds.any(structuredGroupIds.contains);
      },
    ).toList(growable: false);

    expect(topics, hasLength(54));
    for (final topic in topics) {
      expect(
        topic.contentKind,
        HelpTopicContentKind.structuredText,
        reason: topic.id,
      );
      for (final copy in [enHelpCatalogCopy, ptHelpCatalogCopy]) {
        final localized = copy[topic.id]!;
        expect(localized.blocks.whereType<HelpParagraphBlock>(), isNotEmpty,
            reason: topic.id);
        expect(localized.blocks.whereType<HelpHeadingBlock>(), isNotEmpty,
            reason: topic.id);
        expect(localized.blocks.whereType<HelpOrderedStepsBlock>(), isNotEmpty,
            reason: topic.id);
        expect(localized.blocks.whereType<HelpCalloutBlock>(), isNotEmpty,
            reason: topic.id);
        expect(
          localized.blocks.whereType<HelpParagraphBlock>().first.text,
          localized.body,
          reason: topic.id,
        );
      }
    }
  });

  test('short topics retain the plain-body compatibility contract', () {
    final english = enHelpCatalogCopy['getting-started.quick-start']!;
    final portuguese = ptHelpCatalogCopy['getting-started.quick-start']!;

    expect(english.body, isNotEmpty);
    expect(portuguese.body, isNotEmpty);
    expect(english.blocks, isEmpty);
    expect(portuguese.blocks, isEmpty);
  });

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
        final blockText = copy[topicId]!
            .blocks
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

  test('structured topics without all required block kinds fail validation',
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
  });
}
