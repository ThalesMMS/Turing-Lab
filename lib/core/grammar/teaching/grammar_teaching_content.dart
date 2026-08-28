import '../../educational_content/educational_content_reference.dart';

/// Versioned educational-copy boundaries for interactive grammar teaching.
abstract final class GrammarTeachingContent {
  static final normalizationLambda = EducationalContentReference(
    id: 'grammar-teaching/normalization/lambda',
    version: 1,
  );
  static final normalizationUnit = EducationalContentReference(
    id: 'grammar-teaching/normalization/unit',
    version: 1,
  );
  static final normalizationUseless = EducationalContentReference(
    id: 'grammar-teaching/normalization/useless',
    version: 1,
  );
  static final normalizationCnf = EducationalContentReference(
    id: 'grammar-teaching/normalization/cnf',
    version: 1,
  );
  static final parseTableLl1 = EducationalContentReference(
    id: 'grammar-teaching/parse-table/ll1',
    version: 1,
    argumentKeys: <String>['row', 'column', 'alternatives'],
  );
  static final parseTableLr1 = EducationalContentReference(
    id: 'grammar-teaching/parse-table/lr1',
    version: 1,
    argumentKeys: <String>['row', 'column', 'alternatives'],
  );
  static final bruteForceSearch = EducationalContentReference(
    id: 'grammar-teaching/brute-force-search',
    version: 1,
    argumentKeys: <String>['limits', 'witness', 'prunedCounts'],
  );
  static final lr1Construction = EducationalContentReference(
    id: 'grammar-teaching/lr1-construction',
    version: 1,
    argumentKeys: <String>['state', 'lookahead', 'actions', 'conflicts'],
  );
  static final userDerivation = EducationalContentReference(
    id: 'grammar-teaching/user-derivation',
    version: 1,
    argumentKeys: <String>['target', 'production', 'occurrence', 'limit'],
  );

  static final shipped = List<EducationalContentReference>.unmodifiable([
    normalizationLambda,
    normalizationUnit,
    normalizationUseless,
    normalizationCnf,
    parseTableLl1,
    parseTableLr1,
    bruteForceSearch,
    lr1Construction,
    userDerivation,
  ]);
}
