import 'phrase_structure_production.dart';
import 'symbol_sequence.dart';

final class ProductionOccurrence {
  const ProductionOccurrence({
    required this.productionId,
    required this.startIndex,
    required this.occurrenceIndex,
  });

  final String productionId;
  final int startIndex;
  final int occurrenceIndex;
}

final class ProductionApplication {
  const ProductionApplication({
    required this.production,
    required this.occurrence,
    required this.before,
    required this.after,
  });

  final PhraseStructureProduction production;
  final ProductionOccurrence occurrence;
  final GrammarSymbolSequence before;
  final GrammarSymbolSequence after;
}

abstract final class PhraseProductionApplicator {
  static List<ProductionApplication> allApplications(
    GrammarSymbolSequence form,
    Iterable<PhraseStructureProduction> productions,
  ) {
    final ordered = productions.toList()..sort();
    final result = <ProductionApplication>[];
    for (final production in ordered) {
      if (production.left.isEmpty || production.left.length > form.length) {
        continue;
      }
      var occurrenceIndex = 0;
      for (var start = 0;
          start <= form.length - production.left.length;
          start++) {
        if (!form.matchesAt(production.left, start)) continue;
        result.add(ProductionApplication(
          production: production,
          occurrence: ProductionOccurrence(
            productionId: production.id,
            startIndex: start,
            occurrenceIndex: occurrenceIndex++,
          ),
          before: form,
          after: form.replaceRange(
            start,
            start + production.left.length,
            production.right,
          ),
        ));
      }
    }
    return List.unmodifiable(result);
  }
}
