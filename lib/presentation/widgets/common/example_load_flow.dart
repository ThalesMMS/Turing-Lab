//
//  example_load_flow.dart
//  Turing Lab
//
//  The example-loading lifecycle shared by the FSA, PDA, grammar and TM
//  algorithm panels: flag the example as loading, await the repository,
//  report failures and exceptions with the localized messages, apply the
//  payload, confirm with a localized snackbar, and clear the flag afterwards
//  as long as the widget is still mounted. Each panel keeps its own apply step
//  (provider update, analysis reset) and may customize the success message.
//

import 'package:flutter/widgets.dart';

import '../../../core/models/asset_example.dart';
import '../../../core/result.dart';
import '../../../l10n/app_localizations_resolver.dart';
import '../../../l10n/app_localizations_workflows.dart';
import '../app_snackbar.dart';

/// Shows [message] through the workflow localizer with the app snackbar.
void showWorkflowSnackBar(
  BuildContext context,
  String message, {
  AppSnackBarTone tone = AppSnackBarTone.success,
}) {
  showAppSnackBar(
    context,
    message: appLocalizationsOf(context).localizeWorkflowText(message),
    tone: tone,
  );
}

Future<void> loadExampleWithFeedback<T>(
  BuildContext context, {
  required Future<Result<AssetExample<T>>> Function() load,
  required void Function(AssetExample<T> example) apply,
  required void Function(bool loading) setLoading,
  String Function(AssetExample<T> example)? successMessage,
}) async {
  setLoading(true);
  try {
    final result = await load();
    if (!context.mounted) return;
    final l10n = appLocalizationsOf(context);
    if (result.isFailure) {
      showAppSnackBar(
        context,
        message: l10n.failedToLoadExample('${result.error}'),
        tone: AppSnackBarTone.error,
      );
      return;
    }
    final example = result.data!;
    apply(example);
    if (!context.mounted) return;
    showAppSnackBar(
      context,
      message:
          successMessage?.call(example) ?? l10n.exampleLoaded(example.name),
      tone: AppSnackBarTone.success,
    );
  } catch (error) {
    if (!context.mounted) return;
    showAppSnackBar(
      context,
      message: appLocalizationsOf(context).failedToLoadExample('$error'),
      tone: AppSnackBarTone.error,
    );
  } finally {
    if (context.mounted) setLoading(false);
  }
}
