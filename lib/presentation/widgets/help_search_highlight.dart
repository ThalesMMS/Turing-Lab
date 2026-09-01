import 'package:flutter/material.dart';

import '../../core/models/help_catalog.dart';
import '../../l10n/help_catalog_copy.dart';

class HelpSearchResult {
  HelpSearchResult({
    required Set<String> matchingTopicIds,
    required Set<String> visibleNodeIds,
    required Set<String> expandedNodeIds,
  }) : matchingTopicIds = Set.unmodifiable(matchingTopicIds),
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
  final equivalentQueries = _emptyStringSearchAliases(normalizedQuery);
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
    final titleMatches = localized == null
        ? false
        : _matchesAnyQuery(localized.title, equivalentQueries);

    if (node case final HelpTopicDefinition topic) {
      final topicMatches =
          ancestorTitleMatches ||
          titleMatches ||
          (localized?.searchableTextSegments.any(
                (text) => _matchesAnyQuery(text, equivalentQueries),
              ) ??
              false) ||
          (localized?.keywords.any(
                (keyword) => _matchesAnyQuery(keyword, equivalentQueries),
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
      descendantMatches =
          visit(child, ancestorTitleMatches: inheritedMatch) ||
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

const Set<String> _emptyStringQueryAliases = {
  'epsilon',
  'ε',
  'ϵ',
  'lambda',
  'λ',
};

Set<String> _emptyStringSearchAliases(String query) =>
    _emptyStringQueryAliases.contains(query)
    ? _emptyStringQueryAliases
    : {query};

bool _matchesAnyQuery(String text, Set<String> queries) {
  final normalizedText = text.toLowerCase();
  return queries.any(normalizedText.contains);
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
  final equivalentQueries = _emptyStringSearchAliases(normalizedQuery);
  final spans = <TextSpan>[];
  var cursor = 0;
  while (cursor < text.length) {
    String? matchingQuery;
    var matchStart = -1;
    for (final candidate in equivalentQueries) {
      final candidateStart = normalizedText.indexOf(candidate, cursor);
      if (candidateStart < 0) continue;
      if (matchStart < 0 ||
          candidateStart < matchStart ||
          (candidateStart == matchStart &&
              candidate.length > matchingQuery!.length)) {
        matchStart = candidateStart;
        matchingQuery = candidate;
      }
    }
    if (matchingQuery == null) {
      spans.add(TextSpan(text: text.substring(cursor), style: baseStyle));
      break;
    }
    if (matchStart > cursor) {
      spans.add(
        TextSpan(text: text.substring(cursor, matchStart), style: baseStyle),
      );
    }
    final matchEnd = matchStart + matchingQuery.length;
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
