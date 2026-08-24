import 'package:flutter/material.dart';

import 'common/help_navigation.dart';

/// Standard icon-only action for contextual Help destinations.
class HelpActionButton extends StatelessWidget {
  HelpActionButton({
    super.key,
    required String topicId,
    required this.tooltip,
    this.iconSize,
    this.filled = false,
  }) : topicId = validateHelpTopicId(topicId);

  final String topicId;
  final String tooltip;
  final double? iconSize;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    void openTopic() => openHelp(context, topicId: topicId);

    final button = filled
        ? IconButton.filled(
            tooltip: tooltip,
            constraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 48,
            ),
            iconSize: iconSize,
            icon: const Icon(Icons.help_outline),
            onPressed: openTopic,
          )
        : IconButton(
            tooltip: tooltip,
            constraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 48,
            ),
            iconSize: iconSize,
            icon: const Icon(Icons.help_outline),
            onPressed: openTopic,
          );

    return Semantics(
      label: tooltip,
      button: true,
      onTap: openTopic,
      child: ExcludeSemantics(child: button),
    );
  }
}
