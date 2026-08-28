import 'package:collection/collection.dart';

enum PumpingEvidenceCertainty { boundedEvidence, counterexample }

final class PumpingExponentObservation {
  const PumpingExponentObservation({
    required this.exponent,
    required this.remainsInLanguage,
  }) : assert(exponent >= 0);

  factory PumpingExponentObservation.fromJson(Map<String, Object?> json) =>
      PumpingExponentObservation(
        exponent: json['exponent'] as int,
        remainsInLanguage: json['remainsInLanguage'] as bool,
      );

  final int exponent;
  final bool remainsInLanguage;

  Map<String, Object?> toJson() => {
        'exponent': exponent,
        'remainsInLanguage': remainsInLanguage,
      };

  @override
  bool operator ==(Object other) =>
      other is PumpingExponentObservation &&
      exponent == other.exponent &&
      remainsInLanguage == other.remainsInLanguage;

  @override
  int get hashCode => Object.hash(exponent, remainsInLanguage);
}

final class PumpingLemmaEvidence {
  PumpingLemmaEvidence.bounded({
    required List<PumpingExponentObservation> observations,
  }) : observations = List<PumpingExponentObservation>.unmodifiable(
          observations,
        );

  factory PumpingLemmaEvidence.fromJson(Map<String, Object?> json) =>
      PumpingLemmaEvidence.bounded(
        observations: (json['observations'] as List<Object?>)
            .map(
              (value) => PumpingExponentObservation.fromJson(
                Map<String, Object?>.from(value! as Map),
              ),
            )
            .toList(growable: false),
      );

  static const finiteSampleDisclosureCode =
      'pumping.evidence.finite-sample-not-proof';

  final List<PumpingExponentObservation> observations;

  PumpingEvidenceCertainty get certainty => observations.any(
        (observation) => !observation.remainsInLanguage,
      )
          ? PumpingEvidenceCertainty.counterexample
          : PumpingEvidenceCertainty.boundedEvidence;

  int? get counterexampleExponent {
    for (final observation in observations) {
      if (!observation.remainsInLanguage) {
        return observation.exponent;
      }
    }
    return null;
  }

  bool get provesUniversalClaim => false;

  String get disclosureCode => finiteSampleDisclosureCode;

  Map<String, Object?> toJson() => {
        'certainty': certainty.name,
        'disclosureCode': finiteSampleDisclosureCode,
        'provesUniversalClaim': false,
        'observations': observations
            .map((observation) => observation.toJson())
            .toList(growable: false),
      };

  @override
  bool operator ==(Object other) =>
      other is PumpingLemmaEvidence &&
      const ListEquality<PumpingExponentObservation>().equals(
        observations,
        other.observations,
      );

  @override
  int get hashCode =>
      const ListEquality<PumpingExponentObservation>().hash(observations);
}
