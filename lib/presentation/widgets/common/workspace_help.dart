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
import 'help_navigation.dart';

Future<void> showWorkspaceHelp({
  required BuildContext context,
  String? topicId,
}) {
  return openHelp(context, topicId: topicId);
}
