import 'package:flutter/material.dart';

import '../../core/constants/monospace_typography.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../content/example_suggested_simulations.dart';

final class ExampleSuggestedSimulationsText extends StatelessWidget {
  const ExampleSuggestedSimulationsText({
    super.key,
    required this.suggestions,
    this.counterexamples = const [],
    this.onUseInput,
    this.exampleId,
  });

  final List<String> suggestions;

  /// Commented boundary inputs and counterexamples with their expected
  /// outcome; rendered after the accepted suggestions.
  final List<ExampleSuggestedSimulation> counterexamples;

  /// When provided, each suggestion becomes a "Use input" action that hands
  /// the untouched word to the workspace's simulation field.
  final ValueChanged<String>? onUseInput;

  /// Scopes the chip keys so equal words on different examples stay unique.
  final String? exampleId;

  static Key useInputKey(String input, [String? exampleId]) => ValueKey(
    exampleId == null
        ? 'use-suggested-input-$input'
        : 'use-suggested-input-$exampleId-$input',
  );

  /// Empty inputs are displayed as ε so the chip stays visible and tappable.
  static String displayInput(String input) => input.isEmpty ? 'ε' : input;

  static String semanticLabel(
    BuildContext context,
    List<String> suggestions, {
    List<ExampleSuggestedSimulation> counterexamples = const [],
  }) {
    final l10n = appLocalizationsOf(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    return [
      l10n.exampleSuggestedSimulationSemantics(
        suggestions.length,
        suggestions.join(', '),
      ),
      for (final entry in counterexamples)
        l10n.exampleCounterexampleSemantics(
          displayInput(entry.input),
          expectationLabel(l10n, entry.expectation),
          entry.rationaleFor(languageCode),
        ),
    ].join(' ');
  }

  static String expectationLabel(
    AppLocalizations l10n,
    ExampleSimulationExpectation expectation,
  ) => switch (expectation) {
    ExampleSimulationExpectation.accepted => l10n.exampleExpectationAccepted,
    ExampleSimulationExpectation.rejected => l10n.exampleExpectationRejected,
    ExampleSimulationExpectation.invalidSymbol =>
      l10n.exampleExpectationInvalidSymbol,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final onUseInput = this.onUseInput;
    final monospace = textTheme.bodySmall?.copyWith(
      fontFamilyFallback: kMonospaceFontFamilyFallback,
      fontWeight: FontWeight.w600,
    );

    Widget inputWidget(String input) {
      if (onUseInput == null) {
        return Text(displayInput(input), style: monospace);
      }
      return Tooltip(
        message: l10n.useSuggestedInput,
        child: ActionChip(
          key: useInputKey(input, exampleId),
          avatar: const Icon(Icons.input, size: 16),
          label: Text(displayInput(input), style: monospace),
          visualDensity: VisualDensity.compact,
          onPressed: () => onUseInput(input),
        ),
      );
    }

    final Widget suggestionsWidget;
    if (onUseInput == null) {
      suggestionsWidget = Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text:
                  '${l10n.exampleSuggestedSimulationLabel(suggestions.length)}: ',
              style: textTheme.bodySmall,
            ),
            TextSpan(text: suggestions.join(', '), style: monospace),
          ],
        ),
      );
    } else {
      suggestionsWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${l10n.exampleSuggestedSimulationLabel(suggestions.length)}:',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final suggestion in suggestions) inputWidget(suggestion),
            ],
          ),
        ],
      );
    }

    if (counterexamples.isEmpty) {
      return Semantics(
        label: semanticLabel(context, suggestions),
        // Static text is summarized; actionable chips keep their tap actions.
        excludeSemantics: onUseInput == null,
        child: suggestionsWidget,
      );
    }

    final languageCode = Localizations.localeOf(context).languageCode;
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      label: semanticLabel(
        context,
        suggestions,
        counterexamples: counterexamples,
      ),
      excludeSemantics: onUseInput == null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          suggestionsWidget,
          const SizedBox(height: 8),
          Text(
            '${l10n.exampleCounterexampleLabel(counterexamples.length)}:',
            style: textTheme.bodySmall,
          ),
          for (final entry in counterexamples)
            Padding(
              key: ValueKey('example-counterexample-${entry.input}'),
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      inputWidget(entry.input),
                      Text(
                        expectationLabel(l10n, entry.expectation),
                        style: textTheme.labelSmall?.copyWith(
                          color: switch (entry.expectation) {
                            ExampleSimulationExpectation.accepted =>
                              colorScheme.primary,
                            ExampleSimulationExpectation.rejected =>
                              colorScheme.error,
                            ExampleSimulationExpectation.invalidSymbol =>
                              colorScheme.tertiary,
                          },
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    entry.rationaleFor(languageCode),
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
