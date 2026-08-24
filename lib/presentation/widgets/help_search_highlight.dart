import 'package:flutter/material.dart';

import '../../core/models/help_catalog.dart';
import '../../l10n/help_catalog_copy.dart';

class HelpSearchResult {
  HelpSearchResult({
    required Set<String> matchingTopicIds,
    required Set<String> visibleNodeIds,
    required Set<String> expandedNodeIds,
  })  : matchingTopicIds = Set.unmodifiable(matchingTopicIds),
        visibleNodeIds = Set.unmodifiable(visibleNodeIds),
        expandedNodeIds = Set.unmodifiable(expandedNodeIds);

  final Set<String> matchingTopicIds;
  final Set<String> visibleNodeIds;
  final Set<String> expandedNodeIds;
}

HelpSearchResult searchHelpCatalog(
  HelpCatalog catalog,
  HelpCatalogCopy copy,
  String query,
) {
  final normalizedQuery = query.trim().toLowerCase();
  final matchingTopicIds = <String>{};
  final visibleNodeIds = <String>{};
  final expandedNodeIds = <String>{};

  if (normalizedQuery.isEmpty) {
    return HelpSearchResult(
      matchingTopicIds: matchingTopicIds,
      visibleNodeIds: visibleNodeIds,
      expandedNodeIds: expandedNodeIds,
    );
  }

  bool visit(HelpNodeDefinition node, {bool ancestorTitleMatches = false}) {
    final localized = copy[node.id];
    final titleMatches =
        localized?.title.toLowerCase().contains(normalizedQuery) ?? false;

    if (node case final HelpTopicDefinition topic) {
      final topicMatches = ancestorTitleMatches ||
          titleMatches ||
          (localized?.searchableTextSegments.any(
                (text) => text.toLowerCase().contains(normalizedQuery),
              ) ??
              false) ||
          (localized?.keywords.any(
                (keyword) => keyword.toLowerCase().contains(normalizedQuery),
              ) ??
              false);
      if (topicMatches) {
        matchingTopicIds.add(topic.id);
        visibleNodeIds.add(topic.id);
        expandedNodeIds.add(topic.id);
      }
      return topicMatches;
    }

    final group = node as HelpGroupDefinition;
    final inheritedMatch = ancestorTitleMatches || titleMatches;
    var descendantMatches = false;
    for (final child in group.children) {
      descendantMatches = visit(child, ancestorTitleMatches: inheritedMatch) ||
          descendantMatches;
    }
    if (titleMatches || descendantMatches) {
      visibleNodeIds.add(group.id);
      expandedNodeIds.add(group.id);
      return true;
    }
    return false;
  }

  for (final root in catalog.roots) {
    visit(root);
  }

  return HelpSearchResult(
    matchingTopicIds: matchingTopicIds,
    visibleNodeIds: visibleNodeIds,
    expandedNodeIds: expandedNodeIds,
  );
}

List<TextSpan> buildHelpHighlightSpans(
  String text,
  String query,
  TextStyle? baseStyle,
  TextStyle highlightStyle,
) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty || text.isEmpty) {
    return [TextSpan(text: text, style: baseStyle)];
  }

  final normalizedText = text.toLowerCase();
  final spans = <TextSpan>[];
  var cursor = 0;
  while (cursor < text.length) {
    final matchStart = normalizedText.indexOf(normalizedQuery, cursor);
    if (matchStart < 0) {
      spans.add(TextSpan(text: text.substring(cursor), style: baseStyle));
      break;
    }
    if (matchStart > cursor) {
      spans.add(
        TextSpan(text: text.substring(cursor, matchStart), style: baseStyle),
      );
    }
    final matchEnd = matchStart + normalizedQuery.length;
    spans.add(
      TextSpan(
        text: text.substring(matchStart, matchEnd),
        style: baseStyle?.merge(highlightStyle) ?? highlightStyle,
      ),
    );
    cursor = matchEnd;
  }

  return spans.isEmpty ? [TextSpan(text: text, style: baseStyle)] : spans;
}
