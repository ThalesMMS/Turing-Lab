import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../providers/automaton_state_provider.dart';
import '../providers/grammar_provider.dart';
import '../providers/pda_editor_provider.dart';
import '../providers/regex_editor_provider.dart';
import '../providers/tm_editor_provider.dart';

enum ConversionDestination {
  automaton,
  grammar,
  pushdownAutomaton,
  turingMachine,
  regex,
}

Future<bool> confirmConversionDestinationReplacement({
  required BuildContext context,
  required WidgetRef ref,
  required ConversionDestination destination,
}) async {
  if (!_hasLoadedDestination(ref, destination)) {
    return true;
  }

  final l10n = appLocalizationsOf(context);
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.conversionReplaceTitle),
          content: Text(_replacementMessage(l10n, destination)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.conversionReplaceCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.conversionReplaceConfirm),
            ),
          ],
        ),
      ) ??
      false;
}

bool _hasLoadedDestination(
  WidgetRef ref,
  ConversionDestination destination,
) {
  return switch (destination) {
    ConversionDestination.automaton =>
      ref.read(automatonStateProvider).currentAutomaton?.states.isNotEmpty ??
          false,
    ConversionDestination.grammar =>
      ref.read(grammarProvider).productions.isNotEmpty,
    ConversionDestination.pushdownAutomaton =>
      ref.read(pdaEditorProvider).pda?.states.isNotEmpty ?? false,
    ConversionDestination.turingMachine =>
      ref.read(tmEditorProvider).tm?.states.isNotEmpty ?? false,
    ConversionDestination.regex =>
      ref.read(regexEditorProvider).currentRegex.trim().isNotEmpty,
  };
}

String _replacementMessage(
  AppLocalizations l10n,
  ConversionDestination destination,
) {
  return switch (destination) {
    ConversionDestination.automaton => l10n.conversionReplaceAutomatonMessage,
    ConversionDestination.grammar => l10n.conversionReplaceGrammarMessage,
    ConversionDestination.pushdownAutomaton =>
      l10n.conversionReplacePushdownAutomatonMessage,
    ConversionDestination.turingMachine =>
      l10n.conversionReplaceTuringMachineMessage,
    ConversionDestination.regex => l10n.conversionReplaceRegexMessage,
  };
}
