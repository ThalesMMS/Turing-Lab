import 'package:flutter/widgets.dart';

import '../core/utils/epsilon_utils.dart';

const String kLambdaSymbol = 'λ';
const String kVarepsilonSymbol = 'ϵ';
const Set<String> kSupportedEmptyStringSymbols = {
  kEpsilonSymbol,
  kLambdaSymbol,
};

String normalizeEmptyStringDisplaySymbol(String? value) =>
    value == kLambdaSymbol ? kLambdaSymbol : kEpsilonSymbol;

/// Formats canonical empty-string markers without rewriting lambda user data.
String formatEmptyStringMarkers(String text, String symbol) {
  final resolved = normalizeEmptyStringDisplaySymbol(symbol);
  return text
      .replaceAll(kEpsilonSymbol, resolved)
      .replaceAll(kVarepsilonSymbol, resolved);
}

/// Formats trusted interface copy whose epsilon/lambda terms denote emptiness.
///
/// Do not use this for model labels or user input. Set [preserveComparison]
/// for copy that deliberately explains both conventions.
String formatEmptyStringTerminology(
  String text,
  String symbol, {
  bool preserveComparison = false,
}) {
  if (preserveComparison) {
    return text;
  }

  final resolved = normalizeEmptyStringDisplaySymbol(symbol);
  final formatted = formatEmptyStringMarkers(text, resolved);
  if (resolved == kLambdaSymbol) {
    return formatted
        .replaceAll(RegExp(r'\bEpsilon\b'), 'Lambda')
        .replaceAll(RegExp(r'\bepsilon\b'), 'lambda');
  }
  return formatted
      .replaceAll(kLambdaSymbol, kEpsilonSymbol)
      .replaceAll(RegExp(r'\bLambda\b'), 'Epsilon')
      .replaceAll(RegExp(r'\blambda\b'), 'epsilon');
}

/// Backward-compatible safe marker formatter.
String formatEmptyStringNotation(String text, String symbol) =>
    formatEmptyStringMarkers(text, symbol);

class EmptyStringNotation extends InheritedWidget {
  const EmptyStringNotation({
    super.key,
    required this.symbol,
    required super.child,
  });

  final String symbol;

  static String symbolOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<EmptyStringNotation>()
          ?.symbol ??
      kEpsilonSymbol;

  static String formatMarkers(BuildContext context, String text) =>
      formatEmptyStringMarkers(text, symbolOf(context));

  static String formatTerminology(
    BuildContext context,
    String text, {
    bool preserveComparison = false,
  }) => formatEmptyStringTerminology(
    text,
    symbolOf(context),
    preserveComparison: preserveComparison,
  );

  static String format(BuildContext context, String text) =>
      formatMarkers(context, text);

  @override
  bool updateShouldNotify(EmptyStringNotation oldWidget) =>
      oldWidget.symbol != symbol;
}
