//
//  simulation_input_request_binding.dart
//  Turing Lab
//
//  Applies pending SimulationInputRequests to a workspace's input field.
//  An empty field, or one still holding the previously applied suggestion,
//  is filled directly; an edited field asks the user to keep or replace it.
//

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formal_systems/formal_systems.dart';
import '../../../l10n/app_localizations_resolver.dart';
import '../../providers/simulation_input_request_provider.dart';

class SimulationInputRequestBinding {
  SimulationInputRequestBinding({
    required this.workspace,
    required this.controller,
    required this.contextProvider,
    this.formatInput,
    this.onApplied,
  });

  static const Key replaceKey = ValueKey('simulation_input_replace');
  static const Key keepKey = ValueKey('simulation_input_keep');

  final FormalSystemKey workspace;
  final TextEditingController controller;
  final BuildContext? Function() contextProvider;

  /// Converts the catalog suggestion to the field representation; identity by
  /// default.
  final String Function(String input)? formatInput;
  final ValueChanged<String>? onApplied;

  ProviderSubscription<SimulationInputRequest?>? _subscription;
  WidgetRef? _ref;
  String? _lastApplied;
  int? _promptingRequestId;
  DialogRoute<bool>? _dialogRoute;

  /// Starts listening; safe to call from `initState`.
  void attach(WidgetRef ref) {
    _ref = ref;
    _subscription = ref.listenManual<SimulationInputRequest?>(
      simulationInputRequestProvider,
      (_, next) => _handle(next),
    );
    // A request published before this field existed (for example while the
    // simulation sheet was closed) is applied once the first frame is built,
    // because providers must not be modified during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final current = _ref;
      if (current == null) return;
      _handle(current.read(simulationInputRequestProvider));
    });
  }

  void detach() {
    _subscription?.close();
    _subscription = null;
    _ref = null;
    _promptingRequestId = null;
    WidgetsBinding.instance.addPostFrameCallback((_) => _dismissDialog());
  }

  void _dismissDialog() {
    final route = _dialogRoute;
    _dialogRoute = null;
    if (route != null && route.isActive) route.navigator?.removeRoute(route);
  }

  void _handle(SimulationInputRequest? request) {
    if (request == null || request.workspace != workspace) {
      _promptingRequestId = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_promptingRequestId == null) _dismissDialog();
      });
      return;
    }
    if (_promptingRequestId == request.id) return;
    _promptingRequestId = request.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // A newer request published before this frame supersedes the dialog.
      if (_promptingRequestId != request.id) return;
      final ref = _ref;
      if (ref == null ||
          ref.read(simulationInputRequestProvider)?.id != request.id) {
        return;
      }
      _dismissDialog();
      final current = controller.text;
      if (current.isEmpty || current == _lastApplied) {
        _apply(request);
      } else {
        _prompt(request);
      }
    });
  }

  Future<void> _prompt(SimulationInputRequest request) async {
    final context = contextProvider();
    if (context == null || !context.mounted) {
      if (_promptingRequestId == request.id) _promptingRequestId = null;
      return;
    }
    final l10n = appLocalizationsOf(context);
    final route = DialogRoute<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.replaceSimulationInputTitle),
        content: Text(
          l10n.replaceSimulationInputBody(controller.text, request.input),
        ),
        actions: [
          TextButton(
            key: keepKey,
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.keepCurrentInput),
          ),
          FilledButton(
            key: replaceKey,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.replaceInput),
          ),
        ],
      ),
    );
    _dialogRoute = route;
    final replace = await Navigator.of(
      context,
      rootNavigator: true,
    ).push(route);
    if (_promptingRequestId != request.id) return;
    if (identical(_dialogRoute, route)) _dialogRoute = null;
    _promptingRequestId = null;
    final ref = _ref;
    if (ref == null) return;
    // The request may have been replaced while the dialog was open.
    if (ref.read(simulationInputRequestProvider)?.id != request.id) return;
    if (replace == true) {
      _apply(request);
    } else {
      ref.read(simulationInputRequestProvider.notifier).consume(request.id);
    }
  }

  void _apply(SimulationInputRequest request) {
    final value = formatInput?.call(request.input) ?? request.input;
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    _lastApplied = value;
    _ref?.read(simulationInputRequestProvider.notifier).consume(request.id);
    onApplied?.call(value);
  }
}
