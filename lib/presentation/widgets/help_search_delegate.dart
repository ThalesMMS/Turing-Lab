//
//  help_search_delegate.dart
//  Turing Lab
//
//  Implementa busca global sobre todo o conteúdo de ajuda do aplicativo,
//  permitindo que usuários encontrem rapidamente tooltips, conceitos teóricos,
//  atalhos de teclado e instruções de uso através de palavras-chave. Resultados
//  são agrupados por categoria para facilitar navegação e descoberta.
//
//  Thales Matheus Mendonça Santos - January 2026
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/help_content_model.dart';
import '../../l10n/app_localizations_help.dart';
import '../providers/help_provider.dart';
import 'context_aware_help_panel.dart';
import 'help_icon_mapper.dart';

/// SearchDelegate for global help content search.
///
/// Provides full-text search across all help content including titles,
/// descriptions, keywords, and categories. Results are grouped by category
/// for easier navigation and discovery.
class HelpSearchDelegate extends SearchDelegate<HelpContentModel?> {
  HelpSearchDelegate({
    this.ref,
    String? searchFieldLabel,
  }) : super(
          searchFieldLabel: searchFieldLabel,
          keyboardType: TextInputType.text,
        );

  /// WidgetRef for accessing Riverpod providers.
  /// If null, creates a ProviderScope wrapper.
  final WidgetRef? ref;

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        elevation: 0,
        toolbarHeight: 64,
      ),
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        border: InputBorder.none,
        hintStyle: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    final l10n = jflapLocalizationsOf(context);
    return [
      if (query.isNotEmpty)
        Semantics(
          label: l10n.helpSearchClear,
          button: true,
          excludeSemantics: true,
          child: Tooltip(
            message: l10n.helpSearchClear,
            excludeFromSemantics: true,
            child: IconButton(
              onPressed: () {
                query = '';
                showSuggestions(context);
              },
              icon: const Icon(Icons.clear),
              tooltip: null,
            ),
          ),
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    final l10n = jflapLocalizationsOf(context);
    return Semantics(
      label: l10n.helpSearchClose,
      button: true,
      child: IconButton(
        onPressed: () {
          close(context, null);
        },
        icon: const Icon(Icons.arrow_back),
        tooltip: l10n.helpSearchClose,
      ),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _buildEmptyState(context);
    }
    return _buildSearchResults(context);
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = jflapLocalizationsOf(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.helpSearchTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.helpSearchSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _SuggestionChip(
                  label: l10n.helpSearchSuggestion('canvasTools'),
                  onTap: () => query = 'canvas',
                ),
                _SuggestionChip(
                  label: l10n.helpSearchSuggestion('shortcuts'),
                  onTap: () => query = 'keyboard',
                ),
                _SuggestionChip(
                  label: l10n.helpSearchSuggestion('dfa'),
                  onTap: () => query = 'dfa',
                ),
                _SuggestionChip(
                  label: l10n.helpSearchSuggestion('nfa'),
                  onTap: () => query = 'nfa',
                ),
                _SuggestionChip(
                  label: l10n.helpSearchSuggestion('algorithms'),
                  onTap: () => query = 'algorithm',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    // Wrap in ProviderScope if ref is not available
    if (ref == null) {
      return ProviderScope(
        child: Consumer(
          builder: (context, ref, _) => _SearchResultsList(
            query: query,
            onResultTap: (result) => _showHelpPanel(context, result),
          ),
        ),
      );
    }

    return _SearchResultsList(
      query: query,
      onResultTap: (result) => _showHelpPanel(context, result),
    );
  }

  void _showHelpPanel(BuildContext context, HelpContentModel content) {
    ContextAwareHelpPanel.show(
      context,
      helpContent: content,
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: colorScheme.surfaceContainerHighest,
      side: BorderSide(
        color: colorScheme.outline.withValues(alpha: 0.5),
      ),
    );
  }
}

class _SearchResultsList extends ConsumerWidget {
  const _SearchResultsList({
    required this.query,
    required this.onResultTap,
  });

  final String query;
  final void Function(HelpContentModel) onResultTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = jflapLocalizationsOf(context);
    final helpState = ref.watch(helpProvider);
    final results = _searchLocal(
      helpState.allContent.values.map(l10n.localizeHelpContent),
      query,
    );

    if (results.isEmpty) {
      return _buildNoResults(context);
    }

    // Group results by category
    final groupedResults = <String, List<HelpContentModel>>{};
    for (final result in results) {
      groupedResults.putIfAbsent(result.category, () => []).add(result);
    }

    // Sort categories alphabetically
    final sortedCategories = groupedResults.keys.toList()..sort();

    return ListView.builder(
      itemCount: sortedCategories.length,
      itemBuilder: (context, index) {
        final category = sortedCategories[index];
        final categoryResults = groupedResults[category]!;

        return _CategorySection(
          category: category,
          results: categoryResults,
          onResultTap: onResultTap,
          query: query,
        );
      },
    );
  }

  Widget _buildNoResults(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = jflapLocalizationsOf(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.helpSearchNoResults,
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.helpSearchNoResultsDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<HelpContentModel> _searchLocal(
    Iterable<HelpContentModel> items,
    String query,
  ) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return [];
    }

    final lowerQuery = trimmed.toLowerCase();
    return items.where((help) {
      return help.title.toLowerCase().contains(lowerQuery) ||
          help.content.toLowerCase().contains(lowerQuery) ||
          help.category.toLowerCase().contains(lowerQuery) ||
          help.keywords.any((kw) => kw.toLowerCase().contains(lowerQuery));
    }).toList();
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.category,
    required this.results,
    required this.onResultTap,
    required this.query,
  });

  final String category;
  final List<HelpContentModel> results;
  final void Function(HelpContentModel) onResultTap;
  final String query;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = jflapLocalizationsOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  category.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.helpSearchResultCount(results.length),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        ...results.map(
          (result) => _ResultTile(
            result: result,
            onTap: () => onResultTap(result),
            query: query,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.result,
    required this.onTap,
    required this.query,
  });

  final HelpContentModel result;
  final VoidCallback onTap;
  final String query;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = jflapLocalizationsOf(context);

    return Semantics(
      label: l10n.helpTopicSemanticLabel(result.title),
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  helpIconData(result.icon),
                  size: 24,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getPreview(result.content),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (result.keywords.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: result.keywords.take(3).map((keyword) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color:
                                    colorScheme.outline.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              keyword,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get a preview of the content (first 100 characters).
  String _getPreview(String content) {
    if (content.length <= 100) return content;
    return '${content.substring(0, 100)}...';
  }
}
