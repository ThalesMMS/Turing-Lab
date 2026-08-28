import '../educational_content/educational_content_reference.dart';

/// Versioned educational-copy boundaries for manual conversion requirements.
abstract final class ManualConversionContent {
  static final legacy = EducationalContentReference(
    id: 'manual-conversion/legacy-requirement',
    version: 1,
  );

  static final faToRegexNormalize = EducationalContentReference(
    id: 'manual-conversion/fa-to-regex/normalize',
    version: 1,
    argumentKeys: <String>[
      'initialStateId',
      'acceptingStateIds',
      'startStateId',
      'finalStateId',
    ],
  );
  static final faToRegexSelectState = EducationalContentReference(
    id: 'manual-conversion/fa-to-regex/select-state',
    version: 1,
    argumentKeys: <String>['stateId', 'startStateId', 'finalStateId'],
  );
  static final faToRegexPairExpression = EducationalContentReference(
    id: 'manual-conversion/fa-to-regex/pair-expression',
    version: 1,
    argumentKeys: <String>[
      'stateId',
      'fromStateId',
      'toStateId',
      'directExpression',
      'incomingExpression',
      'loopExpression',
      'outgoingExpression',
      'expectedExpression',
    ],
  );
  static final faToRegexCommitElimination = EducationalContentReference(
    id: 'manual-conversion/fa-to-regex/commit-elimination',
    version: 1,
    argumentKeys: <String>['stateId', 'pairCount'],
  );
  static final faToRegexComplete = EducationalContentReference(
    id: 'manual-conversion/fa-to-regex/complete',
    version: 1,
    argumentKeys: <String>['regex'],
  );

  static final regexToFaSymbol = EducationalContentReference(
    id: 'manual-conversion/regex-to-fa/symbol',
    version: 1,
    argumentKeys: <String>['nodeId', 'sourceReference', 'childIds'],
  );
  static final regexToFaDot = EducationalContentReference(
    id: 'manual-conversion/regex-to-fa/dot',
    version: 1,
    argumentKeys: <String>['nodeId', 'sourceReference', 'childIds'],
  );
  static final regexToFaEpsilon = EducationalContentReference(
    id: 'manual-conversion/regex-to-fa/epsilon',
    version: 1,
    argumentKeys: <String>['nodeId', 'sourceReference', 'childIds'],
  );
  static final regexToFaEmptyLanguage = EducationalContentReference(
    id: 'manual-conversion/regex-to-fa/empty-language',
    version: 1,
    argumentKeys: <String>['nodeId', 'sourceReference', 'childIds'],
  );
  static final regexToFaCharacterSet = EducationalContentReference(
    id: 'manual-conversion/regex-to-fa/character-set',
    version: 1,
    argumentKeys: <String>['nodeId', 'sourceReference', 'childIds'],
  );
  static final regexToFaShortcut = EducationalContentReference(
    id: 'manual-conversion/regex-to-fa/shortcut',
    version: 1,
    argumentKeys: <String>['nodeId', 'sourceReference', 'childIds'],
  );
  static final regexToFaUnion = EducationalContentReference(
    id: 'manual-conversion/regex-to-fa/union',
    version: 1,
    argumentKeys: <String>['nodeId', 'sourceReference', 'childIds'],
  );
  static final regexToFaConcatenation = EducationalContentReference(
    id: 'manual-conversion/regex-to-fa/concatenation',
    version: 1,
    argumentKeys: <String>['nodeId', 'sourceReference', 'childIds'],
  );
  static final regexToFaKleeneStar = EducationalContentReference(
    id: 'manual-conversion/regex-to-fa/kleene-star',
    version: 1,
    argumentKeys: <String>['nodeId', 'sourceReference', 'childIds'],
  );
  static final regexToFaPlus = EducationalContentReference(
    id: 'manual-conversion/regex-to-fa/plus',
    version: 1,
    argumentKeys: <String>['nodeId', 'sourceReference', 'childIds'],
  );
  static final regexToFaOptional = EducationalContentReference(
    id: 'manual-conversion/regex-to-fa/optional',
    version: 1,
    argumentKeys: <String>['nodeId', 'sourceReference', 'childIds'],
  );

  static final faGrammarMapState = EducationalContentReference(
    id: 'manual-conversion/fa-to-grammar/map-state-to-nonterminal',
    version: 1,
    argumentKeys: <String>['stateId', 'nonterminal'],
  );
  static final faGrammarAddProduction = EducationalContentReference(
    id: 'manual-conversion/fa-to-grammar/add-transition-production',
    version: 1,
    argumentKeys: <String>['sourceTransitionIds', 'production'],
  );
  static final faGrammarAddEpsilon = EducationalContentReference(
    id: 'manual-conversion/fa-to-grammar/add-accepting-epsilon',
    version: 1,
    argumentKeys: <String>['stateId', 'production'],
  );
  static final grammarFaMapNonterminal = EducationalContentReference(
    id: 'manual-conversion/grammar-to-fa/map-nonterminal-to-state',
    version: 1,
    argumentKeys: <String>['nonterminal', 'stateId'],
  );
  static final grammarFaAddTransition = EducationalContentReference(
    id: 'manual-conversion/grammar-to-fa/add-production-transition',
    version: 1,
    argumentKeys: <String>['sourceProductionIds', 'transition'],
  );
  static final grammarFaMarkAccepting = EducationalContentReference(
    id: 'manual-conversion/grammar-to-fa/mark-epsilon-accepting',
    version: 1,
    argumentKeys: <String>['sourceProductionIds', 'stateId'],
  );

  static final shipped = List<EducationalContentReference>.unmodifiable([
    faToRegexNormalize,
    faToRegexSelectState,
    faToRegexPairExpression,
    faToRegexCommitElimination,
    faToRegexComplete,
    regexToFaSymbol,
    regexToFaDot,
    regexToFaEpsilon,
    regexToFaEmptyLanguage,
    regexToFaCharacterSet,
    regexToFaShortcut,
    regexToFaUnion,
    regexToFaConcatenation,
    regexToFaKleeneStar,
    regexToFaPlus,
    regexToFaOptional,
    faGrammarMapState,
    faGrammarAddProduction,
    faGrammarAddEpsilon,
    grammarFaMapNonterminal,
    grammarFaAddTransition,
    grammarFaMarkAccepting,
  ]);

  static EducationalContentReference? referenceFor(String id) {
    for (final reference in <EducationalContentReference>[legacy, ...shipped]) {
      if (reference.id == id) return reference;
    }
    return null;
  }
}
