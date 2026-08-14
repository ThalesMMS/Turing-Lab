//
//  contextual_help_tooltip.dart
//  Turing Lab
//
//  Widget que envolve componentes da interface com tooltips de ajuda contextual,
//  exibindo conteúdo explicativo baseado no HelpContentModel quando o usuário
//  interage com elementos da UI. Respeita a configuração showTooltips do
//  aplicativo e fornece indicadores visuais opcionais de disponibilidade de ajuda.
//
//  Thales Matheus Mendonça Santos - January 2026
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/help_content.dart';
import '../../core/models/help_content_model.dart';
import '../../core/models/settings_model.dart';
import '../../l10n/app_localizations_help.dart';
import '../providers/settings_provider.dart';
import 'help_icon_mapper.dart';

/// Widget that wraps a child component with contextual help tooltip.
///
/// Displays help content from [HelpContentModel] when the user interacts
/// with the wrapped widget. Respects the [SettingsModel.showTooltips]
/// preference and optionally shows a help indicator icon.
class ContextualHelpTooltip extends ConsumerWidget {
  const ContextualHelpTooltip({
    super.key,
    required this.helpContent,
    required this.child,
    this.showHelpIndicator = false,
    this.onHelpPressed,
  });

  /// The help content to display in the tooltip.
  final HelpContentModel helpContent;

  /// The widget to wrap with the help tooltip.
  final Widget child;

  /// Whether to show a visual indicator that help is available.
  final bool showHelpIndicator;

  /// Optional callback when help indicator is pressed.
  /// If null and showHelpIndicator is true, shows a tooltip on tap.
  final VoidCallback? onHelpPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = jflapLocalizationsOf(context);
    final localizedHelpContent = l10n.localizeHelpContent(helpContent);

    // If tooltips are disabled, return the child without wrapping
    if (!settings.showTooltips) {
      return child;
    }

    Widget wrappedChild = Tooltip(
      richMessage: TextSpan(
        children: [
          TextSpan(
            text: '${localizedHelpContent.title}\n',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          TextSpan(
            text: localizedHelpContent.content,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
      preferBelow: false,
      triggerMode: TooltipTriggerMode.tap,
      waitDuration: const Duration(milliseconds: 500),
      showDuration: const Duration(seconds: 4),
      enableTapToDismiss: true,
      constraints: const BoxConstraints(maxWidth: 320),
      child: child,
    );

    // If help indicator is requested, wrap in a stack with help icon
    if (showHelpIndicator) {
      wrappedChild = Stack(
        clipBehavior: Clip.none,
        children: [
          wrappedChild,
          Positioned(
            right: -4,
            top: -4,
            child: Semantics(
              label: l10n.showHelpFor(localizedHelpContent.title),
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onHelpPressed ?? () => _showHelpDialog(context),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      helpIconData(helpContent.icon),
                      size: 12,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return wrappedChild;
  }

  /// Shows a dialog with full help content.
  void _showHelpDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = jflapLocalizationsOf(context);
    final localizedHelpContent = l10n.localizeHelpContent(helpContent);

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                helpIconData(localizedHelpContent.icon),
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(localizedHelpContent.title),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(localizedHelpContent.content),
                if (localizedHelpContent.relatedConcepts.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    '${l10n.relatedConcepts}:',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children:
                        localizedHelpContent.relatedConcepts.map((concept) {
                      return Chip(
                        label: Text(
                          l10n.relatedConceptLabel(
                            concept,
                            kHelpContent[concept],
                          ),
                        ),
                        labelStyle: theme.textTheme.bodySmall,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.close),
            ),
          ],
        );
      },
    );
  }
}
