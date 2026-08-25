import 'app_localizations.dart';
import '../presentation/widgets/pumping_lemma_game/pumping_lemma_challenge_model.dart';

/// Localizes the pedagogical pumping-lemma challenge corpus at display time.
extension AppLocalizationsPumpingChallenges on AppLocalizations {
  String localizedPumpingDescription(PumpingLemmaChallenge challenge) {
    return switch (challenge.id) {
      1 => pumpingChallenge1Description,
      2 => pumpingChallenge2Description,
      3 => pumpingChallenge3Description,
      4 => pumpingChallenge4Description,
      5 => pumpingChallenge5Description,
      6 => pumpingChallenge6Description,
      7 => pumpingChallenge7Description,
      8 => pumpingChallenge8Description,
      _ => challenge.description,
    };
  }

  String localizedPumpingExplanation(PumpingLemmaChallenge challenge) {
    return switch (challenge.id) {
      1 => pumpingChallenge1Explanation,
      2 => pumpingChallenge2Explanation,
      3 => pumpingChallenge3Explanation,
      4 => pumpingChallenge4Explanation,
      5 => pumpingChallenge5Explanation,
      6 => pumpingChallenge6Explanation,
      7 => pumpingChallenge7Explanation,
      8 => pumpingChallenge8Explanation,
      _ => challenge.explanation,
    };
  }

  List<String> localizedPumpingProofSteps(PumpingLemmaChallenge challenge) {
    final steps = switch (challenge.id) {
      1 => [
          pumpingChallenge1Proof1,
          pumpingChallenge1Proof2,
          pumpingChallenge1Proof3,
          pumpingChallenge1Proof4,
          pumpingChallenge1Proof5,
        ],
      2 => [
          pumpingChallenge2Proof1,
          pumpingChallenge2Proof2,
          pumpingChallenge2Proof3,
          pumpingChallenge2Proof4,
        ],
      3 => [
          pumpingChallenge3Proof1,
          pumpingChallenge3Proof2,
          pumpingChallenge3Proof3,
          pumpingChallenge3Proof4,
          pumpingChallenge3Proof5,
        ],
      4 => [
          pumpingChallenge4Proof1,
          pumpingChallenge4Proof2,
          pumpingChallenge4Proof3,
          pumpingChallenge4Proof4,
          pumpingChallenge4Proof5,
          pumpingChallenge4Proof6,
        ],
      5 => [
          pumpingChallenge5Proof1,
          pumpingChallenge5Proof2,
          pumpingChallenge5Proof3,
          pumpingChallenge5Proof4,
          pumpingChallenge5Proof5,
        ],
      6 => [
          pumpingChallenge6Proof1,
          pumpingChallenge6Proof2,
          pumpingChallenge6Proof3,
          pumpingChallenge6Proof4,
          pumpingChallenge6Proof5,
        ],
      7 => [
          pumpingChallenge7Proof1,
          pumpingChallenge7Proof2,
          pumpingChallenge7Proof3,
          pumpingChallenge7Proof4,
          pumpingChallenge7Proof5,
        ],
      8 => [
          pumpingChallenge8Proof1,
          pumpingChallenge8Proof2,
          pumpingChallenge8Proof3,
          pumpingChallenge8Proof4,
          pumpingChallenge8Proof5,
        ],
      _ => challenge.detailedExplanation,
    };
    return List<String>.unmodifiable(steps);
  }

  List<String> localizedPumpingHints(PumpingLemmaChallenge challenge) {
    final hint = switch (challenge.id) {
      1 => pumpingChallenge1Hint,
      2 => pumpingChallenge2Hint,
      3 => pumpingChallenge3Hint,
      4 => pumpingChallenge4Hint,
      5 => pumpingChallenge5Hint,
      6 => pumpingChallenge6Hint,
      7 => pumpingChallenge7Hint,
      8 => pumpingChallenge8Hint,
      _ => null,
    };
    if (hint == null) {
      return challenge.hints;
    }
    return List<String>.unmodifiable([hint]);
  }
}
