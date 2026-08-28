//
//  pda_simulation_semantic_variant.dart
//  Turing Lab
//
//  Defines the canonical PDA search behavior and the deliberately incorrect
//  semantic variants used by the hard-edge mutation campaign.
//

/// Selects the low-level semantics used by the PDA configuration search.
///
/// Application code should use [canonical]. The other values inject one
/// deliberate defect at a time so certification can prove that its fixtures
/// detect the corresponding production regression.
enum PDASimulationSemanticVariant {
  canonical,
  ignorePush,
  reversePushOrder,
  omitStackFromConfiguration,
  acceptBeforeInputConsumed,
}
