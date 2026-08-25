import 'package:flutter/material.dart';

import '../../l10n/app_localizations_resolver.dart';

/// Primary action used to retry an operation that previously failed.
///
/// This button centralises error recovery behaviour so all flows share the
/// same semantics, accessibility affordances, and loading feedback.
class RetryButton extends StatelessWidget {
  const RetryButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.label,
    this.icon = Icons.refresh,
  }) : assert(label == null || label != '', 'label must not be empty');

  /// Callback executed when the user taps the button.
  final VoidCallback onPressed;

  /// Whether to show the loading state and disable interaction.
  final bool isLoading;

  /// Whether the button can be interacted with.
  final bool isEnabled;

  /// Text shown next to the icon (or instead of it on smaller screens).
  ///
  /// Defaults to the localized Retry label when omitted.
  final String? label;

  /// Icon presented while the button is idle.
  final IconData icon;

  bool get _canTap => isEnabled && !isLoading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = appLocalizationsOf(context);
    final resolvedLabel = label ?? l10n.retry;

    return Semantics(
      label: resolvedLabel,
      hint: l10n.doubleTapToRetry,
      value: isLoading ? l10n.loading : null,
      button: true,
      enabled: _canTap,
      child: SizedBox(
        height: 44,
        child: FilledButton.icon(
          onPressed: _canTap ? onPressed : null,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return RotationTransition(turns: animation, child: child);
            },
            child: isLoading
                ? SizedBox(
                    key: const ValueKey('retry_button_progress'),
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.onPrimary,
                      ),
                    ),
                  )
                : Icon(
                    icon,
                    key: const ValueKey('retry_button_icon'),
                    size: 20,
                  ),
          ),
          label: Text(isLoading ? l10n.retrying : resolvedLabel),
        ),
      ),
    );
  }
}
