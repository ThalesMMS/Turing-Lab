//
//  help_provider.dart
//  Turing Lab
//
//  Expõe um StateNotifier responsável por gerenciar o estado de ajuda contextual
//  da aplicação, fornecendo métodos de busca e filtragem sobre o conteúdo de
//  ajuda definido em kHelpContent. Permite consultas por ID, categoria, ou
//  palavras-chave, suportando navegação eficiente e descoberta de conceitos
//  relacionados durante o uso do aplicativo.
//
//  Thales Matheus Mendonça Santos - January 2026
//
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/help_content.dart';
import '../../core/models/help_content_model.dart';

/// State class that holds help content and search/filter state.
@immutable
class HelpState {
  final Map<String, HelpContentModel> allContent;
  final List<HelpContentModel> searchResults;
  final String? currentQuery;
  final String? currentCategory;

  const HelpState({
    required this.allContent,
    this.searchResults = const [],
    this.currentQuery,
    this.currentCategory,
  });

  HelpState copyWith({
    Map<String, HelpContentModel>? allContent,
    List<HelpContentModel>? searchResults,
    String? currentQuery,
    String? currentCategory,
  }) {
    return HelpState(
      allContent: allContent ?? this.allContent,
      searchResults: searchResults ?? this.searchResults,
      currentQuery: currentQuery ?? this.currentQuery,
      currentCategory: currentCategory ?? this.currentCategory,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is HelpState &&
        other.allContent == allContent &&
        _listEquals(other.searchResults, searchResults) &&
        other.currentQuery == currentQuery &&
        other.currentCategory == currentCategory;
  }

  @override
  int get hashCode => Object.hash(
        allContent,
        Object.hashAll(searchResults),
        currentQuery,
        currentCategory,
      );

  bool _listEquals(List<HelpContentModel> a, List<HelpContentModel> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Provider that exposes help content and search/filter functionality.
final helpProvider = StateNotifierProvider<HelpNotifier, HelpState>(
  (ref) {
    return HelpNotifier();
  },
);

/// State notifier responsible for managing help content and search/filter operations.
class HelpNotifier extends StateNotifier<HelpState> {
  HelpNotifier()
      : super(const HelpState(
          allContent: kHelpContent,
        ));

  bool _disposed = false;

  /// Search help content by query string.
  /// Searches across title, content, keywords, and category.
  /// Returns a list of matching HelpContentModel items.
  List<HelpContentModel> searchHelpContent(String query) {
    if (_disposed) return [];
    if (query.isEmpty) {
      state = state.copyWith(
        searchResults: [],
        currentQuery: null,
      );
      return [];
    }

    final lowerQuery = query.toLowerCase();
    final results = state.allContent.values.where((help) {
      return help.title.toLowerCase().contains(lowerQuery) ||
          help.content.toLowerCase().contains(lowerQuery) ||
          help.category.toLowerCase().contains(lowerQuery) ||
          help.keywords.any((kw) => kw.toLowerCase().contains(lowerQuery));
    }).toList();

    state = state.copyWith(
      searchResults: results,
      currentQuery: query,
    );

    return results;
  }

  /// Get help content by context ID.
  /// Returns the HelpContentModel for the given ID, or null if not found.
  HelpContentModel? getHelpByContext(String contextId) {
    if (_disposed) return null;
    return state.allContent[contextId];
  }

  /// Get help content filtered by category.
  /// Returns a list of all HelpContentModel items in the specified category.
  List<HelpContentModel> getHelpByCategory(String category) {
    if (_disposed) return [];
    final results = state.allContent.values
        .where((help) => help.category == category)
        .toList();

    state = state.copyWith(
      searchResults: results,
      currentCategory: category,
      currentQuery: null,
    );

    return results;
  }

  /// Get all available categories.
  List<String> getAllCategories() {
    if (_disposed) return [];
    return state.allContent.values.map((help) => help.category).toSet().toList()
      ..sort();
  }

  /// Clear current search/filter state.
  void clearSearch() {
    if (_disposed) return;
    state = state.copyWith(
      searchResults: [],
      currentQuery: null,
      currentCategory: null,
    );
  }

  /// Get related help content for a given help item.
  /// Returns a list of HelpContentModel items referenced in relatedConcepts.
  List<HelpContentModel> getRelatedContent(String helpId) {
    if (_disposed) return [];
    final helpItem = state.allContent[helpId];
    if (helpItem == null) return [];

    return helpItem.relatedConcepts
        .map((id) => state.allContent[id])
        .whereType<HelpContentModel>()
        .toList();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
