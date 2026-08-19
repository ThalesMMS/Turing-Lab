//
//  context_aware_help_panel.dart
//  Turing Lab
//
//  Painel expansível de ajuda contextual que exibe explicações detalhadas de
//  conceitos teóricos, operações de autômatos e funcionalidades do aplicativo.
//  Adapta-se ao contexto atual (e.g., mostra explicação de transições epsilon
//  quando editando NFA) e permite navegação entre conceitos relacionados.
//
//  Thales Matheus Mendonça Santos - January 2026
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/help_content.dart';
import '../../core/models/help_content_model.dart';
import '../../l10n/app_localizations_help.dart';
import '../pages/help_category_page.dart';
import '../pages/help_page.dart';
import '../providers/help_provider.dart';
import 'app_snackbar.dart';
import 'help_icon_mapper.dart';
import 'keyboard_shortcuts_dialog.dart';

/// Displays context-aware help content in an expandable panel dialog.
///
/// Shows theory explanations, usage instructions, and related concepts.
/// Adapts content based on the current application context (e.g., DFA vs NFA
/// concepts, epsilon transitions, stack operations).
class ContextAwareHelpPanel extends ConsumerWidget {
  const ContextAwareHelpPanel({
    super.key,
    required this.helpContent,
    this.examples,
    this.showExamplesInitially = false,
    this.showKeyboardShortcutsAction = false,
    this.showHelpCenterAction = false,
    this.onClose,
    this.onNavigateToRelated,
  });

  /// The help content to display in the panel.
  final HelpContentModel helpContent;

  /// Optional examples or additional notes to show in expandable section.
  final String? examples;

  /// Whether the examples section starts expanded.
  final bool showExamplesInitially;

  /// Whether to expose the keyboard-shortcuts dialog from this panel.
  final bool showKeyboardShortcutsAction;

  /// Whether to expose a shortcut to the full help center from this panel.
  final bool showHelpCenterAction;

  /// Invoked when the panel is closed.
  final VoidCallback? onClose;

  /// Invoked when navigating to a related concept.
  /// If null, uses the HelpProvider to fetch and display related content.
  final void Function(String conceptId)? onNavigateToRelated;

  bool get _hasExamples => examples != null && examples!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = jflapLocalizationsOf(context);
    final localizedHelpContent = l10n.localizeHelpContent(helpContent);

    return Semantics(
      namesRoute: true,
      label: l10n.contextualHelpPanelLabel,
      child: AlertDialog(
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        title: _PanelTitle(
          helpContent: localizedHelpContent,
          colorScheme: colorScheme,
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CategoryChip(
                  category: localizedHelpContent.category,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 16),
                Text(
                  localizedHelpContent.content,
                  style: theme.textTheme.bodyMedium,
                ),
                if (localizedHelpContent.relatedConcepts.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _RelatedConceptsSection(
                    relatedConcepts: localizedHelpContent.relatedConcepts,
                    theme: theme,
                    colorScheme: colorScheme,
                    onNavigateToRelated: onNavigateToRelated,
                  ),
                ],
                if (_hasExamples) ...[
                  const SizedBox(height: 16),
                  _ExamplesSection(
                    examples: examples!,
                    initiallyExpanded: showExamplesInitially,
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        actions: [
          if (showHelpCenterAction)
            TextButton.icon(
              onPressed: () async {
                final navigator = Navigator.of(context, rootNavigator: true);
                navigator.pop();
                await navigator.push(
                  MaterialPageRoute(builder: (context) => const HelpPage()),
                );
              },
              icon: const Icon(Icons.menu_book_outlined),
              label: Text(l10n.helpCenter),
            ),
          if (showKeyboardShortcutsAction)
            TextButton.icon(
              onPressed: () async {
                final navigator = Navigator.of(
                  context,
                  rootNavigator: true,
                );
                final rootContext = navigator.context;
                navigator.pop();
                if (rootContext.mounted) {
                  await KeyboardShortcutsDialog.show(rootContext);
                }
              },
              icon: const Icon(Icons.keyboard),
              label: Text(l10n.keyboardShortcutsTitle),
            ),
          Semantics(
            label: l10n.closeHelpPanel,
            button: true,
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onClose?.call();
              },
              child: Text(l10n.close),
            ),
          ),
          if (localizedHelpContent.keywords.isNotEmpty)
            Semantics(
              label: l10n.viewAllRelatedHelp,
              button: true,
              child: TextButton.icon(
                onPressed: () async {
                  final navigator = Navigator.of(context, rootNavigator: true);
                  final rootContext = navigator.context;
                  navigator.pop();
                  // Navigate to help page with this category
                  await _showCategoryHelp(
                    rootContext,
                    ref,
                    helpContent.category,
                  );
                },
                icon: const Icon(Icons.help_outline),
                label: Text(l10n.moreHelp),
              ),
            ),
        ],
      ),
    );
  }

  /// Shows the help page filtered by category.
  Future<void> _showCategoryHelp(
    BuildContext context,
    WidgetRef ref,
    String category,
  ) async {
    final helpNotifier = ref.read(helpProvider.notifier);
    final l10n = jflapLocalizationsOf(context);
    final categoryLabel = l10n.helpContentCategory(category);

    List<HelpContentModel> results = [];
    try {
      results = helpNotifier
          .getHelpByCategory(category)
          .map(l10n.localizeHelpContent)
          .toList();
    } catch (error) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          message: l10n.unableToLoadHelp(categoryLabel),
          tone: AppSnackBarTone.error,
        );
      }
      return;
    }

    if (!context.mounted) return;

    if (results.isEmpty) {
      showAppSnackBar(
        context,
        message: l10n.noHelpItemsFound(categoryLabel),
        tone: AppSnackBarTone.info,
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HelpCategoryPage(
          category: categoryLabel,
          results: results,
        ),
      ),
    );
  }

  /// Shows the panel as a dialog.
  static Future<void> show(
    BuildContext context, {
    required HelpContentModel helpContent,
    String? examples,
    bool showExamplesInitially = false,
    bool showKeyboardShortcutsAction = false,
    bool showHelpCenterAction = false,
    VoidCallback? onClose,
    void Function(String conceptId)? onNavigateToRelated,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => ContextAwareHelpPanel(
        helpContent: helpContent,
        examples: examples,
        showExamplesInitially: showExamplesInitially,
        showKeyboardShortcutsAction: showKeyboardShortcutsAction,
        showHelpCenterAction: showHelpCenterAction,
        onClose: onClose,
        onNavigateToRelated: onNavigateToRelated,
      ),
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({
    required this.helpContent,
    required this.colorScheme,
  });

  final HelpContentModel helpContent;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          helpIconData(helpContent.icon),
          size: 48,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            helpContent.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.colorScheme,
  });

  final String category;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.label_outline,
            size: 16,
            color: colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 6),
          Text(
            category.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
          ),
        ],
      ),
    );
  }
}

class _RelatedConceptsSection extends ConsumerWidget {
  const _RelatedConceptsSection({
    required this.relatedConcepts,
    required this.theme,
    required this.colorScheme,
    this.onNavigateToRelated,
  });

  final List<String> relatedConcepts;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final void Function(String conceptId)? onNavigateToRelated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.link,
              size: 16,
              color: colorScheme.secondary,
            ),
            const SizedBox(width: 6),
            Text(
              jflapLocalizationsOf(context).relatedConcepts,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: relatedConcepts.map((conceptId) {
            return _RelatedConceptChip(
              conceptId: conceptId,
              colorScheme: colorScheme,
              onTap: () {
                if (onNavigateToRelated != null) {
                  onNavigateToRelated!(conceptId);
                } else {
                  _navigateToRelatedConcept(context, ref, conceptId);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Navigate to related concept by showing a new help panel.
  void _navigateToRelatedConcept(
    BuildContext context,
    WidgetRef ref,
    String conceptId,
  ) {
    final helpNotifier = ref.read(helpProvider.notifier);
    final relatedContent = helpNotifier.getHelpByContext(conceptId);

    if (relatedContent != null) {
      final navigator = Navigator.of(context, rootNavigator: true);
      navigator.pop(); // Close current panel
      ContextAwareHelpPanel.show(
        navigator.context,
        helpContent: relatedContent,
      );
    }
  }
}

class _RelatedConceptChip extends StatelessWidget {
  const _RelatedConceptChip({
    required this.conceptId,
    required this.colorScheme,
    required this.onTap,
  });

  final String conceptId;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final helpContent = kHelpContent[conceptId];
    final label = jflapLocalizationsOf(context).relatedConceptLabel(
      conceptId,
      helpContent,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.secondary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: colorScheme.onSecondaryContainer,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExamplesSection extends StatefulWidget {
  const _ExamplesSection({
    required this.examples,
    required this.initiallyExpanded,
  });

  final String examples;
  final bool initiallyExpanded;

  @override
  State<_ExamplesSection> createState() => _ExamplesSectionState();
}

class _ExamplesSectionState extends State<_ExamplesSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(covariant _ExamplesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initiallyExpanded != widget.initiallyExpanded) {
      _expanded = widget.initiallyExpanded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderColor = colorScheme.outlineVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => setState(() => _expanded = !_expanded),
          icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
          label: Text(
            _expanded ? 'Hide examples' : 'View examples',
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
              color: colorScheme.surfaceContainerHighest,
            ),
            child: SingleChildScrollView(
              child: Text(
                widget.examples,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}
