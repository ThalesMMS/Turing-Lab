import 'pumping_decomposition.dart';
import 'pumping_lemma_messages.dart';

abstract final class PumpingDecompositionEnumerator {
  static List<RegularPumpingDecomposition> regular({
    required List<String> witness,
    required int pumpingLength,
  }) {
    _validateInputs(witness, pumpingLength);
    final decompositions = <RegularPumpingDecomposition>[];
    final windowEnd = witness.length < pumpingLength
        ? witness.length
        : pumpingLength;
    for (var xEnd = 0; xEnd < windowEnd; xEnd++) {
      for (var yEnd = xEnd + 1; yEnd <= windowEnd; yEnd++) {
        decompositions.add(
          RegularPumpingDecomposition(
            x: witness.sublist(0, xEnd),
            y: witness.sublist(xEnd, yEnd),
            z: witness.sublist(yEnd),
          ),
        );
      }
    }
    return List.unmodifiable(decompositions);
  }

  static List<ContextFreePumpingDecomposition> contextFree({
    required List<String> witness,
    required int pumpingLength,
  }) {
    _validateInputs(witness, pumpingLength);
    final decompositions = <ContextFreePumpingDecomposition>[];
    final length = witness.length;
    for (var uEnd = 0; uEnd <= length; uEnd++) {
      final windowEnd = uEnd + pumpingLength < length
          ? uEnd + pumpingLength
          : length;
      for (var vEnd = uEnd; vEnd <= windowEnd; vEnd++) {
        for (var xEnd = vEnd; xEnd <= windowEnd; xEnd++) {
          for (var yEnd = xEnd; yEnd <= windowEnd; yEnd++) {
            if (vEnd == uEnd && yEnd == xEnd) continue;
            decompositions.add(
              ContextFreePumpingDecomposition(
                u: witness.sublist(0, uEnd),
                v: witness.sublist(uEnd, vEnd),
                x: witness.sublist(vEnd, xEnd),
                y: witness.sublist(xEnd, yEnd),
                z: witness.sublist(yEnd),
              ),
            );
          }
        }
      }
    }
    return List.unmodifiable(decompositions);
  }

  static void _validateInputs(List<String> witness, int pumpingLength) {
    if (pumpingLength < 1) {
      throw PumpingLemmaArgumentError.value(
        pumpingLength,
        'pumpingLength',
        PumpingLemmaMessages.pumpingLengthPositive(),
      );
    }
    if (witness.length < pumpingLength) {
      throw PumpingLemmaArgumentError.message(
        PumpingLemmaMessages.witnessMinimumTokens(pumpingLength),
      );
    }
  }
}
