//
//  contextual_help_tooltip.dart
//  Turing Lab
//
//  Keeps short control labels aligned with the global tooltip preference.
//  Detailed explanatory content belongs exclusively on HelpPage.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';

/// Wraps an ordinary control label in a settings-aware tooltip.
class ContextualHelpTooltip extends ConsumerWidget {
  const ContextualHelpTooltip({
    super.key,
    required this.message,
    required this.child,
  });

  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(settingsProvider).showTooltips) {
      return child;
    }

    return Tooltip(message: message, child: child);
  }
}
