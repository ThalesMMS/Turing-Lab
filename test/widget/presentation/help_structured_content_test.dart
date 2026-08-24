import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/core/models/help_catalog.dart';
import 'package:turing_lab/l10n/help_catalog_copy.dart';
import 'package:turing_lab/presentation/controllers/help_tree_controller.dart';
import 'package:turing_lab/presentation/widgets/help_tree_view.dart';

void main() {
  testWidgets('renders and highlights typed structured help blocks', (
    tester,
  ) async {
    final catalog = HelpCatalog(
      roots: [
        HelpCategoryDefinition(
          id: 'root',
          icon: 'help_outline',
          children: [
            HelpTopicDefinition(
              id: 'root.topic',
              icon: 'play_arrow',
              contentKind: HelpTopicContentKind.structuredText,
            ),
          ],
        ),
      ],
    );
    final copy = HelpCatalogCopy({
      'root': HelpNodeCopy(title: 'Root'),
      'root.topic': HelpNodeCopy(
        title: 'Structured topic',
        body: 'The original body remains available and searchable.',
        keywords: ['structured'],
        blocks: [
          const HelpHeadingBlock('Operate the parser'),
          HelpOrderedStepsBlock([
            'Choose a strategy.',
            'Inspect the unique ordered needle.',
          ]),
          const HelpCalloutBlock('Resolve the unique callout warning first.'),
        ],
      ),
    });
    final controller = HelpTreeController(
      catalog: catalog,
      copy: copy,
      initialTopicId: 'root.topic',
    );
    final scrollController = ScrollController();
    final focusNodes = {
      for (final node in catalog.nodes) node.id: FocusNode(),
    };
    addTearDown(controller.dispose);
    addTearDown(scrollController.dispose);
    addTearDown(() {
      for (final node in focusNodes.values) {
        node.dispose();
      }
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HelpTreeView(
            controller: controller,
            scrollController: scrollController,
            topicKeys: {'root.topic': GlobalKey()},
            nodeFocusNodes: focusNodes,
            disclosureSemanticLabel: (title, {required expanded}) => title,
            relatedTopicsLabel: 'Related topics',
            unavailableTitle: 'Unavailable',
            unavailableDescription: 'Unavailable topic.',
            noResultsTitle: 'No results',
            noResultsDescription: 'Nothing matched.',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final paragraph = find.byKey(
      const ValueKey('help-block-paragraph-root.topic-0'),
    );
    final heading = find.byKey(
      const ValueKey('help-block-heading-root.topic-1'),
    );
    final firstStep = find.byKey(
      const ValueKey('help-block-step-root.topic-2-0'),
    );
    final secondStep = find.byKey(
      const ValueKey('help-block-step-root.topic-2-1'),
    );
    final callout = find.byKey(
      const ValueKey('help-block-callout-root.topic-3'),
    );
    expect(paragraph, findsOneWidget);
    expect(heading, findsOneWidget);
    expect(tester.getSemantics(heading).flagsCollection.isHeader, isTrue);
    expect(firstStep, findsOneWidget);
    expect(secondStep, findsOneWidget);
    expect(find.textContaining('1.  Choose a strategy.'), findsOneWidget);
    expect(callout, findsOneWidget);

    controller.setQuery('unique ordered needle');
    await tester.pump();

    expect(controller.matchingTopicIds, {'root.topic'});
    final selectable = tester.widget<SelectableText>(secondStep);
    final highlighted = selectable.textSpan!.children!.cast<TextSpan>().where(
          (span) => span.text?.toLowerCase() == 'unique ordered needle',
        );
    expect(highlighted, hasLength(1));
    expect(highlighted.single.style?.backgroundColor, isNotNull);
  });
}
