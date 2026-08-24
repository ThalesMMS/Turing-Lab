import 'package:flutter/foundation.dart';

import '../../core/constants/help_topic_ids.dart';
import '../../core/models/help_catalog.dart';
import '../../l10n/help_catalog_copy.dart';
import '../widgets/help_search_highlight.dart';

class HelpTreeController extends ChangeNotifier {
  HelpTreeController({
    required this.catalog,
    required HelpCatalogCopy copy,
    String? initialTopicId,
  }) : _copy = copy {
    if (initialTopicId == null) {
      _expandedIds.add(HelpTopicIds.gettingStarted);
    } else {
      _revealTopic(initialTopicId, notify: false);
    }
  }

  final HelpCatalog catalog;
  HelpCatalogCopy _copy;

  final Set<String> _expandedIds = <String>{};
  Set<String>? _preSearchExpandedIds;
  HelpSearchResult? _searchResult;
  String _query = '';
  String? _pendingRevealTopicId;

  bool topicUnavailable = false;

  Set<String> get expandedIds => Set.unmodifiable(_expandedIds);
  HelpCatalogCopy get copy => _copy;
  String get query => _query;
  bool get isSearching => _searchResult != null;
  HelpSearchResult? get searchResult => _searchResult;
  Set<String> get matchingTopicIds =>
      _searchResult?.matchingTopicIds ?? const <String>{};

  bool isNodeVisible(String id) {
    return !isSearching || _searchResult!.visibleNodeIds.contains(id);
  }

  void toggle(String id) {
    if (_searchResult?.expandedNodeIds.contains(id) ?? false) return;

    if (!_expandedIds.remove(id)) {
      _expandedIds.add(id);
    }
    notifyListeners();
  }

  void revealTopic(String topicId) {
    if (isSearching && !_searchResult!.visibleNodeIds.contains(topicId)) {
      _clearQuery(notify: false);
    }
    _revealTopic(topicId, notify: true);
  }

  void setQuery(String query) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      clearQuery();
      return;
    }

    if (!isSearching) {
      _preSearchExpandedIds = Set.of(_expandedIds);
    }
    _query = trimmedQuery;
    _searchResult = searchHelpCatalog(catalog, copy, trimmedQuery);
    _expandedIds
      ..clear()
      ..addAll(_searchResult!.expandedNodeIds);
    topicUnavailable = false;
    notifyListeners();
  }

  void updateCopy(HelpCatalogCopy copy) {
    if (identical(_copy, copy)) return;

    _copy = copy;
    if (isSearching) {
      _searchResult = searchHelpCatalog(catalog, _copy, _query);
      _expandedIds
        ..clear()
        ..addAll(_searchResult!.expandedNodeIds);
    }
    notifyListeners();
  }

  void clearQuery() {
    _clearQuery(notify: true);
  }

  String? consumePendingReveal() {
    final topicId = _pendingRevealTopicId;
    _pendingRevealTopicId = null;
    return topicId;
  }

  void _clearQuery({required bool notify}) {
    if (!isSearching && _query.isEmpty && _preSearchExpandedIds == null) {
      return;
    }

    final previousExpansions = _preSearchExpandedIds;
    _query = '';
    _searchResult = null;
    _preSearchExpandedIds = null;
    if (previousExpansions != null) {
      _expandedIds
        ..clear()
        ..addAll(previousExpansions);
    }
    if (notify) notifyListeners();
  }

  void _revealTopic(String topicId, {required bool notify}) {
    final path = catalog.pathForTopic(topicId);
    if (path == null) {
      topicUnavailable = true;
      if (notify) notifyListeners();
      return;
    }

    _expandedIds
      ..addAll(path.ancestorIds)
      ..add(topicId);
    _pendingRevealTopicId = topicId;
    topicUnavailable = false;
    if (notify) notifyListeners();
  }
}
