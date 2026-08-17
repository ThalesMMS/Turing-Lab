//
//  workspace_help.dart
//  Turing Lab
//
//  Centralizes contextual help lookup and presentation for automaton
//  workspaces so every responsive surface follows the same behavior.
//
//  Thales Matheus Mendonça Santos - August 2026
//

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations_resolver.dart';
import '../../providers/help_provider.dart';
import '../app_snackbar.dart';
import '../context_aware_help_panel.dart';

Future<void> showWorkspaceHelp({
  required BuildContext context,
  required WidgetRef ref,
  required String contextId,
}) async {
  final content = ref.read(helpProvider.notifier).getHelpByContext(contextId);
  if (content == null) {
    showAppSnackBar(
      context,
      message: appLocalizationsOf(context).workspaceHelpUnavailable,
      tone: AppSnackBarTone.error,
    );
    return;
  }

  await ContextAwareHelpPanel.show(
    context,
    helpContent: content,
    showKeyboardShortcutsAction: true,
  );
}
