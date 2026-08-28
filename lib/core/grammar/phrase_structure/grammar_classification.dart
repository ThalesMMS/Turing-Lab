import '../../models/grammar.dart';
import 'grammar_symbol.dart';
import 'phrase_structure_grammar.dart';
import 'phrase_structure_production.dart';
import 'symbol_sequence.dart';

enum PhraseGrammarClassification {
  regular,
  contextFree,
  contextSensitive,
  unrestricted,
  invalid,
}

enum PhraseGrammarRegularOrientation {
  rightLinear,
  leftLinear,
  both,
  mixed,
  notRegular,
}

enum PhraseGrammarNormalForm { strictChomsky, weakChomsky, greibach }

enum PhraseGrammarDiagnosticSeverity { warning, error }

enum PhraseGrammarDiagnosticCode {
  emptyGrammar,
  emptySymbol,
  overlappingSymbolIdentity,
  undeclaredStartSymbol,
  emptyProductionId,
  duplicateProductionId,
  duplicateProduction,
  emptyLeftSide,
  leftSideMissingNonterminal,
  undeclaredProductionSymbol,
  contextFreeLeftSide,
  regularRightSide,
  regularMixedOrientation,
  contextSensitiveContracting,
  contextSensitiveEpsilonRestriction,
  contextSensitiveStartOnRight,
  invalidInputSymbol,
  declaredTypeMismatch,
}

enum PhraseGrammarPredicateCode {
  validPhraseRule,
  contextFreeLeftSide,
  noncontractingRule,
  epsilonRestriction,
  rightLinearRule,
  leftLinearRule,
  strictChomskyRule,
  weakChomskyRule,
  greibachRule,
}

final class PhraseGrammarDiagnostic {
  const PhraseGrammarDiagnostic({
    required this.code,
    required this.severity,
    this.productionId,
    this.symbol,
  });

  final PhraseGrammarDiagnosticCode code;
  final PhraseGrammarDiagnosticSeverity severity;
  final String? productionId;
  final String? symbol;

  Map<String, Object?> toJson() => {
        'code': code.name,
        'severity': severity.name,
        if (productionId != null) 'productionId': productionId,
        if (symbol != null) 'symbol': symbol,
      };
}

final class PhraseGrammarProductionEvidence {
  PhraseGrammarProductionEvidence({
    required this.productionId,
    required Iterable<PhraseGrammarPredicateCode> satisfied,
    required Iterable<PhraseGrammarPredicateCode> violated,
  })  : satisfied = Set.unmodifiable(_sortPredicates(satisfied)),
        violated = Set.unmodifiable(_sortPredicates(violated));

  final String productionId;
  final Set<PhraseGrammarPredicateCode> satisfied;
  final Set<PhraseGrammarPredicateCode> violated;

  bool satisfies(PhraseGrammarPredicateCode predicate) =>
      satisfied.contains(predicate);

  Map<String, Object?> toJson() => {
        'productionId': productionId,
        'satisfied': satisfied.map((item) => item.name).toList(),
        'violated': violated.map((item) => item.name).toList(),
      };
}

final class PhraseGrammarClassificationReport {
  PhraseGrammarClassificationReport({
    required this.classification,
    required Iterable<PhraseGrammarDiagnostic> diagnostics,
    required this.regularOrientation,
    required Iterable<PhraseGrammarNormalForm> normalForms,
    required Iterable<PhraseGrammarProductionEvidence> productionEvidence,
    this.declaredClassification,
  })  : diagnostics = List.unmodifiable(_sortDiagnostics(diagnostics)),
        normalForms = Set.unmodifiable(_sortNormalForms(normalForms)),
        productionEvidence = List.unmodifiable(
          productionEvidence.toList()
            ..sort((left, right) =>
                left.productionId.compareTo(right.productionId)),
        );

  final PhraseGrammarClassification classification;
  final List<PhraseGrammarDiagnostic> diagnostics;
  final PhraseGrammarRegularOrientation regularOrientation;
  final Set<PhraseGrammarNormalForm> normalForms;
  final List<PhraseGrammarProductionEvidence> productionEvidence;
  final PhraseGrammarClassification? declaredClassification;

  bool get isValid => classification != PhraseGrammarClassification.invalid;

  bool get declaredTypeMatches =>
      declaredClassification == null ||
      declaredClassification == classification;

  List<PhraseGrammarDiagnostic> get errors => diagnostics
      .where((item) => item.severity == PhraseGrammarDiagnosticSeverity.error)
      .toList(growable: false);

  Map<String, Object?> toStructuredJson() => {
        'classification': classification.name,
        'regularOrientation': regularOrientation.name,
        'normalForms': normalForms.map((item) => item.name).toList(),
        if (declaredClassification != null)
          'declaredClassification': declaredClassification!.name,
        'declaredTypeMatches': declaredTypeMatches,
        'diagnostics': diagnostics.map((item) => item.toJson()).toList(),
        'productionEvidence':
            productionEvidence.map((item) => item.toJson()).toList(),
      };
}

abstract final class PhraseGrammarClassifier {
  static PhraseGrammarClassificationReport classify(
    PhraseStructureGrammar grammar, {
    PhraseGrammarClassification? declaredClassification,
  }) {
    final diagnostics = <PhraseGrammarDiagnostic>[];
    final allDeclared = <PhraseGrammarSymbol>{
      ...grammar.terminals,
      ...grammar.nonterminals,
    };
    final terminalNames =
        grammar.terminals.map((symbol) => symbol.value).toSet();
    final nonterminalNames =
        grammar.nonterminals.map((symbol) => symbol.value).toSet();
    final productions = grammar.phraseProductions;

    if (productions.isEmpty) {
      diagnostics.add(const PhraseGrammarDiagnostic(
        code: PhraseGrammarDiagnosticCode.emptyGrammar,
        severity: PhraseGrammarDiagnosticSeverity.warning,
      ));
    }
    for (final symbol in allDeclared) {
      if (symbol.value.isEmpty) {
        diagnostics.add(const PhraseGrammarDiagnostic(
          code: PhraseGrammarDiagnosticCode.emptySymbol,
          severity: PhraseGrammarDiagnosticSeverity.error,
        ));
      }
    }
    for (final value in terminalNames.intersection(nonterminalNames)) {
      diagnostics.add(PhraseGrammarDiagnostic(
        code: PhraseGrammarDiagnosticCode.overlappingSymbolIdentity,
        severity: PhraseGrammarDiagnosticSeverity.error,
        symbol: value,
      ));
    }
    if (!grammar.nonterminals.contains(grammar.startSymbol)) {
      diagnostics.add(PhraseGrammarDiagnostic(
        code: PhraseGrammarDiagnosticCode.undeclaredStartSymbol,
        severity: PhraseGrammarDiagnosticSeverity.error,
        symbol: grammar.startSymbol.value,
      ));
    }

    final startOnRight = productions.any(
      (production) => production.right.symbols.contains(grammar.startSymbol),
    );
    final ids = <String>{};
    final shapes = <String>{};
    final evidence = <PhraseGrammarProductionEvidence>[];
    var isContextFree = true;
    var isContextSensitive = true;
    var hasRightOnlyRule = false;
    var hasLeftOnlyRule = false;
    var allRightLinear = true;
    var allLeftLinear = true;

    for (final production in productions) {
      if (production.id.isEmpty) {
        diagnostics.add(const PhraseGrammarDiagnostic(
          code: PhraseGrammarDiagnosticCode.emptyProductionId,
          severity: PhraseGrammarDiagnosticSeverity.error,
        ));
      } else if (!ids.add(production.id)) {
        diagnostics.add(PhraseGrammarDiagnostic(
          code: PhraseGrammarDiagnosticCode.duplicateProductionId,
          severity: PhraseGrammarDiagnosticSeverity.error,
          productionId: production.id,
        ));
      }
      if (!shapes.add(production.structuralKey)) {
        diagnostics.add(PhraseGrammarDiagnostic(
          code: PhraseGrammarDiagnosticCode.duplicateProduction,
          severity: PhraseGrammarDiagnosticSeverity.error,
          productionId: production.id,
        ));
      }

      final leftHasNonterminal =
          production.left.symbols.any((symbol) => symbol.isNonterminal);
      var symbolsDeclared = true;
      if (production.left.isEmpty) {
        diagnostics.add(PhraseGrammarDiagnostic(
          code: PhraseGrammarDiagnosticCode.emptyLeftSide,
          severity: PhraseGrammarDiagnosticSeverity.error,
          productionId: production.id,
        ));
      }
      if (!leftHasNonterminal) {
        diagnostics.add(PhraseGrammarDiagnostic(
          code: PhraseGrammarDiagnosticCode.leftSideMissingNonterminal,
          severity: PhraseGrammarDiagnosticSeverity.error,
          productionId: production.id,
        ));
      }
      for (final symbol in [
        ...production.left.symbols,
        ...production.right.symbols,
      ]) {
        if (!allDeclared.contains(symbol)) {
          symbolsDeclared = false;
          diagnostics.add(PhraseGrammarDiagnostic(
            code: PhraseGrammarDiagnosticCode.undeclaredProductionSymbol,
            severity: PhraseGrammarDiagnosticSeverity.error,
            productionId: production.id,
            symbol: symbol.value,
          ));
        }
      }

      final cfgLeft = production.left.length == 1 &&
          production.left[0] is NonterminalGrammarSymbol;
      if (!cfgLeft) {
        isContextFree = false;
        diagnostics.add(PhraseGrammarDiagnostic(
          code: PhraseGrammarDiagnosticCode.contextFreeLeftSide,
          severity: PhraseGrammarDiagnosticSeverity.warning,
          productionId: production.id,
        ));
      }

      final isStartEpsilon = _isSafeStartEpsilon(
        grammar,
        production,
        startOnRight: startOnRight,
      );
      final noncontracting =
          production.right.length >= production.left.length || isStartEpsilon;
      if (!noncontracting) {
        isContextSensitive = false;
        diagnostics.add(PhraseGrammarDiagnostic(
          code: PhraseGrammarDiagnosticCode.contextSensitiveContracting,
          severity: PhraseGrammarDiagnosticSeverity.warning,
          productionId: production.id,
        ));
      }
      final epsilonAllowed = production.right.isNotEmpty || isStartEpsilon;
      if (!epsilonAllowed) {
        isContextSensitive = false;
        diagnostics.add(PhraseGrammarDiagnostic(
          code: PhraseGrammarDiagnosticCode.contextSensitiveEpsilonRestriction,
          severity: PhraseGrammarDiagnosticSeverity.warning,
          productionId: production.id,
        ));
      }
      final isStartEpsilonIgnoringRightSide = production.right.isEmpty &&
          production.left.length == 1 &&
          production.left[0] == grammar.startSymbol;
      if (isStartEpsilonIgnoringRightSide && startOnRight) {
        isContextSensitive = false;
        diagnostics.add(PhraseGrammarDiagnostic(
          code: PhraseGrammarDiagnosticCode.contextSensitiveStartOnRight,
          severity: PhraseGrammarDiagnosticSeverity.warning,
          productionId: production.id,
        ));
      }

      final linearity = _linearity(
        grammar,
        production,
        startOnRight: startOnRight,
      );
      allRightLinear &= linearity.right;
      allLeftLinear &= linearity.left;
      hasRightOnlyRule |= linearity.right && !linearity.left;
      hasLeftOnlyRule |= linearity.left && !linearity.right;

      final strictChomsky = _isStrictChomskyRule(production);
      final weakChomsky = strictChomsky || isStartEpsilon;
      final greibach = _isGreibachRule(production) || isStartEpsilon;
      evidence.add(_buildEvidence(
        production.id,
        {
          PhraseGrammarPredicateCode.validPhraseRule:
              production.left.isNotEmpty &&
                  leftHasNonterminal &&
                  symbolsDeclared,
          PhraseGrammarPredicateCode.contextFreeLeftSide: cfgLeft,
          PhraseGrammarPredicateCode.noncontractingRule: noncontracting,
          PhraseGrammarPredicateCode.epsilonRestriction: epsilonAllowed,
          PhraseGrammarPredicateCode.rightLinearRule: linearity.right,
          PhraseGrammarPredicateCode.leftLinearRule: linearity.left,
          PhraseGrammarPredicateCode.strictChomskyRule: strictChomsky,
          PhraseGrammarPredicateCode.weakChomskyRule: weakChomsky,
          PhraseGrammarPredicateCode.greibachRule: greibach,
        },
      ));
    }

    final orientation = _orientation(
      isContextFree: isContextFree,
      allRightLinear: allRightLinear,
      allLeftLinear: allLeftLinear,
      hasRightOnlyRule: hasRightOnlyRule,
      hasLeftOnlyRule: hasLeftOnlyRule,
    );
    final isRegular = isContextFree &&
        orientation != PhraseGrammarRegularOrientation.mixed &&
        orientation != PhraseGrammarRegularOrientation.notRegular;
    if (isContextFree && orientation == PhraseGrammarRegularOrientation.mixed) {
      diagnostics.add(const PhraseGrammarDiagnostic(
        code: PhraseGrammarDiagnosticCode.regularMixedOrientation,
        severity: PhraseGrammarDiagnosticSeverity.warning,
      ));
    } else if (isContextFree && !isRegular) {
      diagnostics.add(const PhraseGrammarDiagnostic(
        code: PhraseGrammarDiagnosticCode.regularRightSide,
        severity: PhraseGrammarDiagnosticSeverity.warning,
      ));
    }

    final hasErrors = diagnostics.any(
      (item) => item.severity == PhraseGrammarDiagnosticSeverity.error,
    );
    final classification = hasErrors
        ? PhraseGrammarClassification.invalid
        : isRegular
            ? PhraseGrammarClassification.regular
            : isContextFree
                ? PhraseGrammarClassification.contextFree
                : isContextSensitive
                    ? PhraseGrammarClassification.contextSensitive
                    : PhraseGrammarClassification.unrestricted;
    if (declaredClassification != null &&
        declaredClassification != classification) {
      diagnostics.add(const PhraseGrammarDiagnostic(
        code: PhraseGrammarDiagnosticCode.declaredTypeMismatch,
        severity: PhraseGrammarDiagnosticSeverity.warning,
      ));
    }

    final normalForms = <PhraseGrammarNormalForm>{};
    if (!hasErrors && isContextFree) {
      if (productions.every(_isStrictChomskyRule)) {
        normalForms.add(PhraseGrammarNormalForm.strictChomsky);
      }
      if (productions.every((production) =>
          _isStrictChomskyRule(production) ||
          _isSafeStartEpsilon(
            grammar,
            production,
            startOnRight: startOnRight,
          ))) {
        normalForms.add(PhraseGrammarNormalForm.weakChomsky);
      }
      if (productions.every((production) =>
          _isGreibachRule(production) ||
          _isSafeStartEpsilon(
            grammar,
            production,
            startOnRight: startOnRight,
          ))) {
        normalForms.add(PhraseGrammarNormalForm.greibach);
      }
    }

    return PhraseGrammarClassificationReport(
      classification: classification,
      diagnostics: diagnostics,
      regularOrientation: orientation,
      normalForms: normalForms,
      productionEvidence: evidence,
      declaredClassification: declaredClassification,
    );
  }

  static PhraseGrammarClassificationReport classifyLegacy(Grammar grammar) {
    final terminals = grammar.terminals.map(TerminalGrammarSymbol.new).toSet();
    final nonterminals =
        grammar.nonterminals.map(NonterminalGrammarSymbol.new).toSet();
    PhraseGrammarSymbol symbolFor(String value) =>
        grammar.nonterminals.contains(value)
            ? NonterminalGrammarSymbol(value)
            : TerminalGrammarSymbol(value);
    final productions = grammar.productions.map(
      (production) => PhraseStructureProduction(
        id: production.id,
        left: GrammarSymbolSequence(production.leftSide.map(symbolFor)),
        right: GrammarSymbolSequence(
          production.isLambda
              ? const <PhraseGrammarSymbol>[]
              : production.rightSide
                  .where((value) => !_isLegacyEpsilon(value))
                  .map(symbolFor),
        ),
        order: production.order,
      ),
    );
    return classify(
      UnrestrictedGrammar(
        id: grammar.id,
        name: grammar.name,
        revision: 0,
        terminals: terminals,
        nonterminals: nonterminals,
        startSymbol: NonterminalGrammarSymbol(grammar.startSymbol),
        productions: productions,
      ),
      declaredClassification: _fromLegacyType(grammar.type),
    );
  }

  static bool isStrictChomsky(PhraseStructureGrammar grammar) =>
      classify(grammar).normalForms.contains(
            PhraseGrammarNormalForm.strictChomsky,
          );

  static bool isWeakChomsky(PhraseStructureGrammar grammar) =>
      classify(grammar).normalForms.contains(
            PhraseGrammarNormalForm.weakChomsky,
          );

  static bool isGreibach(PhraseStructureGrammar grammar) =>
      classify(grammar).normalForms.contains(PhraseGrammarNormalForm.greibach);
}

PhraseGrammarProductionEvidence _buildEvidence(
  String productionId,
  Map<PhraseGrammarPredicateCode, bool> results,
) =>
    PhraseGrammarProductionEvidence(
      productionId: productionId,
      satisfied: results.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key),
      violated: results.entries
          .where((entry) => !entry.value)
          .map((entry) => entry.key),
    );

({bool right, bool left}) _linearity(
  PhraseStructureGrammar grammar,
  PhraseStructureProduction production, {
  required bool startOnRight,
}) {
  if (production.left.length != 1 ||
      production.left[0] is! NonterminalGrammarSymbol) {
    return (right: false, left: false);
  }
  if (production.right.isEmpty) {
    final allowed = _isSafeStartEpsilon(
      grammar,
      production,
      startOnRight: startOnRight,
    );
    return (right: allowed, left: allowed);
  }
  final nonterminalIndices = <int>[
    for (var index = 0; index < production.right.length; index++)
      if (production.right[index] is NonterminalGrammarSymbol) index,
  ];
  if (nonterminalIndices.isEmpty) return (right: true, left: true);
  if (nonterminalIndices.length > 1) return (right: false, left: false);
  final index = nonterminalIndices.single;
  return (
    right: index == production.right.length - 1,
    left: index == 0,
  );
}

PhraseGrammarRegularOrientation _orientation({
  required bool isContextFree,
  required bool allRightLinear,
  required bool allLeftLinear,
  required bool hasRightOnlyRule,
  required bool hasLeftOnlyRule,
}) {
  if (!isContextFree) return PhraseGrammarRegularOrientation.notRegular;
  if (hasRightOnlyRule && hasLeftOnlyRule) {
    return PhraseGrammarRegularOrientation.mixed;
  }
  if (allRightLinear && allLeftLinear) {
    return PhraseGrammarRegularOrientation.both;
  }
  if (allRightLinear) return PhraseGrammarRegularOrientation.rightLinear;
  if (allLeftLinear) return PhraseGrammarRegularOrientation.leftLinear;
  return PhraseGrammarRegularOrientation.notRegular;
}

bool _isSafeStartEpsilon(
  PhraseStructureGrammar grammar,
  PhraseStructureProduction production, {
  required bool startOnRight,
}) =>
    production.right.isEmpty &&
    production.left.length == 1 &&
    production.left[0] == grammar.startSymbol &&
    !startOnRight;

bool _isStrictChomskyRule(PhraseStructureProduction production) {
  if (production.left.length != 1 ||
      production.left[0] is! NonterminalGrammarSymbol) {
    return false;
  }
  final right = production.right.symbols;
  return (right.length == 1 && right.single is TerminalGrammarSymbol) ||
      (right.length == 2 &&
          right.every((symbol) => symbol is NonterminalGrammarSymbol));
}

bool _isGreibachRule(PhraseStructureProduction production) {
  if (production.left.length != 1 ||
      production.left[0] is! NonterminalGrammarSymbol ||
      production.right.isEmpty ||
      production.right[0] is! TerminalGrammarSymbol) {
    return false;
  }
  return production.right.symbols
      .skip(1)
      .every((symbol) => symbol is NonterminalGrammarSymbol);
}

PhraseGrammarClassification _fromLegacyType(GrammarType type) => switch (type) {
      GrammarType.regular => PhraseGrammarClassification.regular,
      GrammarType.contextFree => PhraseGrammarClassification.contextFree,
      GrammarType.contextSensitive =>
        PhraseGrammarClassification.contextSensitive,
      GrammarType.unrestricted => PhraseGrammarClassification.unrestricted,
    };

bool _isLegacyEpsilon(String value) =>
    value.isEmpty || value == 'ε' || value == 'λ' || value == 'epsilon';

List<PhraseGrammarPredicateCode> _sortPredicates(
  Iterable<PhraseGrammarPredicateCode> values,
) =>
    values.toList()..sort((left, right) => left.index.compareTo(right.index));

List<PhraseGrammarNormalForm> _sortNormalForms(
  Iterable<PhraseGrammarNormalForm> values,
) =>
    values.toList()..sort((left, right) => left.index.compareTo(right.index));

List<PhraseGrammarDiagnostic> _sortDiagnostics(
  Iterable<PhraseGrammarDiagnostic> diagnostics,
) =>
    diagnostics.toList()
      ..sort((left, right) {
        final byProduction =
            (left.productionId ?? '').compareTo(right.productionId ?? '');
        if (byProduction != 0) return byProduction;
        final byCode = left.code.index.compareTo(right.code.index);
        if (byCode != 0) return byCode;
        final bySymbol = (left.symbol ?? '').compareTo(right.symbol ?? '');
        if (bySymbol != 0) return bySymbol;
        return left.severity.index.compareTo(right.severity.index);
      });
