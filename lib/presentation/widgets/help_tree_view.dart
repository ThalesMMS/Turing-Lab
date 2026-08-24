import 'package:flutter/material.dart';

import '../../core/models/help_catalog.dart';
import '../../l10n/help_catalog_copy.dart';
import '../controllers/help_tree_controller.dart';
import 'help_icon_mapper.dart';
import 'help_search_highlight.dart';

const double helpTreeMaxContentWidth = 880;
const _unavailableHelpEntryKey = ValueKey<String>('help-entry-unavailable');
const _noResultsHelpEntryKey = ValueKey<String>('help-entry-no-results');

ValueKey<String> _helpNodeEntryKey(String nodeId) =>
    ValueKey<String>('help-entry-$nodeId');

typedef HelpTopicContentBuilder = Widget? Function(
  BuildContext context,
  HelpTopicDefinition topic,
);

typedef HelpDisclosureSemanticLabel = String Function(
  String title, {
  required bool expanded,
});

class HelpTreeView extends StatelessWidget {
  const HelpTreeView({
    super.key,
    required this.controller,
    required this.scrollController,
    required this.topicKeys,
    required this.nodeFocusNodes,
    required this.disclosureSemanticLabel,
    required this.relatedTopicsLabel,
    required this.unavailableTitle,
    required this.unavailableDescription,
    required this.noResultsTitle,
    required this.noResultsDescription,
    this.topicContentBuilder,
  });

  final HelpTreeController controller;
  final ScrollController scrollController;
  final Map<String, GlobalKey> topicKeys;
  final Map<String, FocusNode> nodeFocusNodes;
  final HelpDisclosureSemanticLabel disclosureSemanticLabel;
  final String relatedTopicsLabel;
  final String unavailableTitle;
  final String unavailableDescription;
  final String noResultsTitle;
  final String noResultsDescription;
  final HelpTopicContentBuilder? topicContentBuilder;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final entries = <_VisibleHelpNode>[];
        for (final root in controller.catalog.roots) {
          _appendVisibleNode(entries, root, 0);
        }
        final feedbackOffset = controller.topicUnavailable ? 1 : 0;
        final noResultsOffset =
            controller.isSearching && controller.matchingTopicIds.isEmpty
                ? 1
                : 0;
        final entryIndexes = <Key, int>{
          if (feedbackOffset == 1) _unavailableHelpEntryKey: 0,
          if (noResultsOffset == 1) _noResultsHelpEntryKey: feedbackOffset,
          for (var index = 0; index < entries.length; index++)
            _helpNodeEntryKey(entries[index].node.id):
                index + feedbackOffset + noResultsOffset,
        };

        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 32),
          itemCount: entries.length + feedbackOffset + noResultsOffset,
          findChildIndexCallback: (key) => entryIndexes[key],
          itemBuilder: (context, index) {
            if (feedbackOffset == 1 && index == 0) {
              return _UnavailableFeedback(
                key: _unavailableHelpEntryKey,
                title: unavailableTitle,
                description: unavailableDescription,
              );
            }

            if (noResultsOffset == 1 && index == feedbackOffset) {
              return _NoResultsFeedback(
                key: _noResultsHelpEntryKey,
                title: noResultsTitle,
                description: noResultsDescription,
              );
            }

            final entry = entries[index - feedbackOffset - noResultsOffset];
            return Align(
              key: _helpNodeEntryKey(entry.node.id),
              alignment: AlignmentDirectional.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: helpTreeMaxContentWidth,
                ),
                child: _buildEntry(context, entry),
              ),
            );
          },
        );
      },
    );
  }

  void _appendVisibleNode(
    List<_VisibleHelpNode> entries,
    HelpNodeDefinition node,
    int depth,
  ) {
    if (!controller.isNodeVisible(node.id)) return;
    entries.add(_VisibleHelpNode(node: node, depth: depth));
    if (node case final HelpGroupDefinition group
        when controller.expandedIds.contains(group.id)) {
      for (final child in group.children) {
        _appendVisibleNode(entries, child, depth + 1);
      }
    }
  }

  Widget _buildEntry(BuildContext context, _VisibleHelpNode entry) {
    final node = entry.node;
    final copy = controller.copy[node.id];
    if (copy == null) return const SizedBox.shrink();

    final expanded = controller.expandedIds.contains(node.id);
    final topic = node is HelpTopicDefinition ? node : null;
    final row = _HelpNodeRow(
      rowKey: ValueKey('help-node-${node.id}'),
      node: node,
      title: copy.title,
      query: controller.query,
      depth: entry.depth,
      expanded: expanded,
      focusNode: nodeFocusNodes[node.id],
      semanticLabel: disclosureSemanticLabel(
        copy.title,
        expanded: expanded,
      ),
      onTap: () => controller.toggle(node.id),
    );

    final disableExpansionAnimation =
        MediaQuery.disableAnimationsOf(context) || controller.isSearching;
    final topicBody = topic == null || !expanded
        ? const SizedBox.shrink()
        : _HelpTopicBody(
            key: ValueKey('help-body-${topic.id}'),
            topic: topic,
            copy: copy,
            depth: entry.depth,
            catalogCopy: controller.copy,
            relatedTopicsLabel: relatedTopicsLabel,
            onRelatedTopicTap: controller.revealTopic,
            query: controller.query,
            specialContent: topicContentBuilder?.call(context, topic),
          );
    final content = topic == null
        ? row
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              row,
              if (disableExpansionAnimation)
                AnimatedSwitcher(
                  key: ValueKey('help-expansion-${topic.id}'),
                  duration: Duration.zero,
                  child: topicBody,
                )
              else
                AnimatedSize(
                  key: ValueKey('help-expansion-${topic.id}'),
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOutCubic,
                  alignment: AlignmentDirectional.topCenter,
                  child: topicBody,
                ),
            ],
          );

    final topicKey = topicKeys[node.id];
    final keyedContent = topicKey == null
        ? content
        : KeyedSubtree(key: topicKey, child: content);
    return Padding(
      padding: EdgeInsetsDirectional.only(
        top: entry.depth == 0 ? 12 : 0,
        bottom: topic != null && expanded ? 8 : 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          keyedContent,
          Padding(
            padding: EdgeInsetsDirectional.only(
              start: entry.depth * 20.0 + 8,
              end: 4,
            ),
            child: Divider(
              key: ValueKey('help-divider-${node.id}'),
              height: 1,
              thickness: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisibleHelpNode {
  const _VisibleHelpNode({required this.node, required this.depth});

  final HelpNodeDefinition node;
  final int depth;
}

class _HelpNodeRow extends StatelessWidget {
  const _HelpNodeRow({
    required this.rowKey,
    required this.node,
    required this.title,
    required this.semanticLabel,
    required this.query,
    required this.depth,
    required this.expanded,
    required this.onTap,
    this.focusNode,
  });

  final Key rowKey;
  final HelpNodeDefinition node;
  final String title;
  final String semanticLabel;
  final String query;
  final int depth;
  final bool expanded;
  final VoidCallback onTap;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCategory = node is HelpCategoryDefinition;
    final isGroup = node is HelpGroupDefinition;
    final textStyle = switch (node) {
      HelpCategoryDefinition() => theme.textTheme.titleLarge,
      HelpSubsectionDefinition() => theme.textTheme.titleMedium,
      HelpTopicDefinition() => theme.textTheme.titleSmall,
    };
    final resolvedTextStyle = textStyle?.copyWith(
      fontWeight: isGroup ? FontWeight.w600 : FontWeight.w500,
      color: colorScheme.onSurface,
    );
    final highlightStyle = TextStyle(
      backgroundColor: colorScheme.tertiaryContainer,
      color: colorScheme.onTertiaryContainer,
    );

    return Semantics(
      container: true,
      excludeSemantics: true,
      header: true,
      button: true,
      expanded: expanded,
      label: semanticLabel,
      onTap: onTap,
      child: InkWell(
        key: rowKey,
        focusNode: focusNode,
        excludeFromSemantics: true,
        borderRadius: BorderRadius.circular(8),
        focusColor: colorScheme.secondaryContainer,
        hoverColor: colorScheme.surfaceContainerHighest,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start: depth * 20.0 + 8,
              end: 4,
              top: 8,
              bottom: 8,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  helpIconData(node.icon),
                  size: isCategory ? 24 : 20,
                  color: isCategory
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: buildHelpHighlightSpans(
                        title,
                        query,
                        resolvedTextStyle,
                        highlightStyle,
                      ),
                    ),
                    softWrap: true,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox.square(
                  dimension: 48,
                  child: Icon(
                    expanded ? Icons.expand_more : Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HelpTopicBody extends StatelessWidget {
  const _HelpTopicBody({
    super.key,
    required this.topic,
    required this.copy,
    required this.depth,
    required this.catalogCopy,
    required this.relatedTopicsLabel,
    required this.onRelatedTopicTap,
    required this.query,
    this.specialContent,
  });

  final HelpTopicDefinition topic;
  final HelpNodeCopy copy;
  final int depth;
  final HelpCatalogCopy catalogCopy;
  final String relatedTopicsLabel;
  final ValueChanged<String> onRelatedTopicTap;
  final String query;
  final Widget? specialContent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bodyStyle = theme.textTheme.bodyLarge?.copyWith(height: 1.5);
    final highlightStyle = TextStyle(
      backgroundColor: colorScheme.tertiaryContainer,
      color: colorScheme.onTertiaryContainer,
    );

    return Semantics(
      container: true,
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: depth * 20.0 + 40,
          end: 12,
          bottom: 12,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: BorderDirectional(
              start: BorderSide(color: colorScheme.outlineVariant, width: 2),
            ),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 16, end: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (index, block) in _visibleBlocks.indexed)
                  _HelpContentBlockView(
                    topicId: topic.id,
                    index: index,
                    block: block,
                    query: query,
                    bodyStyle: bodyStyle,
                    highlightStyle: highlightStyle,
                  ),
                if (specialContent != null) ...[
                  const SizedBox(height: 20),
                  specialContent!,
                ],
                if (topic.relatedTopicIds.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Semantics(
                    header: true,
                    child: Text(
                      relatedTopicsLabel,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  for (final relatedId in topic.relatedTopicIds)
                    TextButton.icon(
                      key: ValueKey('help-related-$relatedId'),
                      style: TextButton.styleFrom(
                        alignment: AlignmentDirectional.centerStart,
                        minimumSize: const Size(48, 48),
                      ),
                      onPressed: () => onRelatedTopicTap(relatedId),
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: Text(
                        catalogCopy[relatedId]?.title ?? relatedId,
                        softWrap: true,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<HelpContentBlock> get _visibleBlocks {
    if (copy.blocks.isNotEmpty) return copy.blocks;
    return [HelpParagraphBlock(copy.body)];
  }
}

class _HelpContentBlockView extends StatelessWidget {
  const _HelpContentBlockView({
    required this.topicId,
    required this.index,
    required this.block,
    required this.query,
    required this.bodyStyle,
    required this.highlightStyle,
  });

  final String topicId;
  final int index;
  final HelpContentBlock block;
  final String query;
  final TextStyle? bodyStyle;
  final TextStyle highlightStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: switch (block) {
        HelpParagraphBlock(:final text) => SelectableText.rich(
            key: ValueKey('help-block-paragraph-$topicId-$index'),
            TextSpan(
              children: _highlight(text, bodyStyle),
            ),
          ),
        HelpHeadingBlock(:final text) => Semantics(
            key: ValueKey('help-block-heading-$topicId-$index'),
            header: true,
            child: Text.rich(
              TextSpan(
                children: _highlight(
                  text,
                  theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        HelpOrderedStepsBlock(:final steps) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (stepIndex, step) in steps.indexed)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: stepIndex == steps.length - 1 ? 0 : 12,
                  ),
                  child: SelectableText.rich(
                    key: ValueKey(
                      'help-block-step-$topicId-$index-$stepIndex',
                    ),
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${stepIndex + 1}.  ',
                          style: bodyStyle?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                          ),
                        ),
                        ..._highlight(step, bodyStyle),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        HelpCalloutBlock(:final text) => Semantics(
            container: true,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(
                      child: Icon(
                        Icons.info_outline,
                        size: 20,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SelectableText.rich(
                        key: ValueKey(
                          'help-block-callout-$topicId-$index',
                        ),
                        TextSpan(
                          children: _highlight(
                            text,
                            bodyStyle?.copyWith(
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      },
    );
  }

  List<TextSpan> _highlight(String text, TextStyle? style) {
    return buildHelpHighlightSpans(text, query, style, highlightStyle);
  }
}

class _NoResultsFeedback extends StatelessWidget {
  const _NoResultsFeedback({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Align(
      alignment: AlignmentDirectional.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: helpTreeMaxContentWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              Icon(
                Icons.search_off,
                size: 48,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnavailableFeedback extends StatelessWidget {
  const _UnavailableFeedback({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Align(
      alignment: AlignmentDirectional.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: helpTreeMaxContentWidth),
        child: Semantics(
          liveRegion: true,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
