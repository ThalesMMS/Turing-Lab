//
//  suggested_input_dispatcher.dart
//  Turing Lab
//
//  Shared "Use input" flow for example surfaces: make sure the example is the
//  active document (through the workspace's own load flow), publish the
//  SimulationInputRequest, then hand over to the simulation surface.
//

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formal_systems/formal_systems.dart';
import '../../../l10n/app_localizations_resolver.dart';
import '../../providers/simulation_input_request_provider.dart';
import '../../providers/workspace_quick_actions_provider.dart';
import '../app_snackbar.dart';

/// Publishes [input] for [workspace] once [ensureLoaded] confirms the example
/// is the active document.
///
/// When the caller lives in a modal bottom sheet (compact layouts), the sheet
/// is closed and the workspace's simulate action opens the simulation
/// surface; otherwise a confirmation snackbar tells the user where the input
/// went. Returns true when the request was published.
Future<bool> dispatchSuggestedInput(
  BuildContext context,
  WidgetRef ref, {
  required FormalSystemKey workspace,
  required String exampleId,
  required String input,
  required Future<bool> Function() ensureLoaded,
}) async {
  final loaded = await ensureLoaded();
  if (!loaded || !context.mounted) return false;

  ref
      .read(simulationInputRequestProvider.notifier)
      .publish(workspace: workspace, exampleId: exampleId, input: input);

  final route = ModalRoute.of(context);
  final quickActions = ref.read(workspaceQuickActionsProvider(workspace));
  if (route is ModalBottomSheetRoute && quickActions?.onSimulate != null) {
    Navigator.of(context).pop();
    quickActions!.onSimulate!.call();
    return true;
  }
  showAppSnackBar(
    context,
    message: appLocalizationsOf(context).suggestedInputSent(input),
    tone: AppSnackBarTone.info,
  );
  return true;
}
