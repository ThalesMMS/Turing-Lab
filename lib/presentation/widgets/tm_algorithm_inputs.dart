import 'package:flutter/material.dart';

import '../../core/models/tm_language_explorer_models.dart';
import '../../core/models/tm_space_profile.dart';
import '../../core/models/tm_time_profile.dart';

/// Owns and validates the panel's text input independently from presentation.
class TMAlgorithmInputs {
  TMAlgorithmInputs();

  final terminationInput = TextEditingController();
  final reachabilityInputs = TextEditingController();
  final languageMaxLength = TextEditingController(text: '2');
  final languageCandidateCap = TextEditingController(text: '50');
  final languageMaxSteps = TextEditingController(text: '10000');
  final languageMaxConfigurations = TextEditingController(text: '100000');
  final languageTimeoutMs = TextEditingController(text: '5000');
  final spaceMaxLength = TextEditingController(text: '2');
  final spaceCandidateCap = TextEditingController(text: '20');
  final spaceMaxSteps = TextEditingController(text: '10000');
  final spaceMaxConfigurations = TextEditingController(text: '100000');
  final spaceTimeoutMs = TextEditingController(text: '5000');
  final profileMaxLength = TextEditingController(text: '4');
  final profileCandidateCap = TextEditingController(text: '64');

  List<String> get reachabilityInputScope {
    if (reachabilityInputs.text.trim().isEmpty) return const [''];
    return reachabilityInputs.text
        .split(',')
        .map((input) => input.trim())
        .map((input) => input == 'ε' || input == 'λ' ? '' : input)
        .toSet()
        .toList(growable: false);
  }

  TMLanguageExplorerLimits? get languageLimits {
    final maxLength = int.tryParse(languageMaxLength.text);
    final candidateCap = int.tryParse(languageCandidateCap.text);
    final maxSteps = int.tryParse(languageMaxSteps.text);
    final maxConfigurations = int.tryParse(languageMaxConfigurations.text);
    final timeoutMs = int.tryParse(languageTimeoutMs.text);
    if (!_validLimits(
      maxLength,
      candidateCap,
      maxSteps,
      maxConfigurations,
      timeoutMs,
    )) {
      return null;
    }
    return TMLanguageExplorerLimits(
      maxInputLength: maxLength!,
      maxCandidates: candidateCap!,
      maxStepsPerInput: maxSteps!,
      maxConfigurationsPerInput: maxConfigurations!,
      timeoutPerInput: Duration(milliseconds: timeoutMs!),
    );
  }

  TMSpaceProfileLimits? get spaceLimits {
    final maxLength = int.tryParse(spaceMaxLength.text);
    final candidateCap = int.tryParse(spaceCandidateCap.text);
    final maxSteps = int.tryParse(spaceMaxSteps.text);
    final maxConfigurations = int.tryParse(spaceMaxConfigurations.text);
    final timeoutMs = int.tryParse(spaceTimeoutMs.text);
    if (!_validLimits(
      maxLength,
      candidateCap,
      maxSteps,
      maxConfigurations,
      timeoutMs,
    )) {
      return null;
    }
    return TMSpaceProfileLimits(
      maxInputLength: maxLength!,
      maxCandidatesPerLength: candidateCap!,
      maxStepsPerInput: maxSteps!,
      maxConfigurationsPerInput: maxConfigurations!,
      timeoutPerInput: Duration(milliseconds: timeoutMs!),
    );
  }

  TMTimeProfileBounds? get timeBounds {
    final maxLength = int.tryParse(profileMaxLength.text.trim());
    final candidateCap = int.tryParse(profileCandidateCap.text.trim());
    if (maxLength == null || candidateCap == null) return null;
    return TMTimeProfileBounds(
      maxLength: maxLength,
      maxCandidatesPerLength: candidateCap,
      maxStepsPerCandidate: 50000,
      maxConfigurationsPerCandidate: 100000,
      timeoutPerCandidate: const Duration(seconds: 5),
    );
  }

  bool _validLimits(
    int? maxLength,
    int? candidateCap,
    int? maxSteps,
    int? maxConfigurations,
    int? timeoutMs,
  ) =>
      maxLength != null &&
      maxLength >= 0 &&
      maxLength <= 20 &&
      candidateCap != null &&
      candidateCap > 0 &&
      candidateCap <= 10000 &&
      maxSteps != null &&
      maxSteps > 0 &&
      maxConfigurations != null &&
      maxConfigurations > 0 &&
      timeoutMs != null &&
      timeoutMs > 0;

  void dispose() {
    terminationInput.dispose();
    reachabilityInputs.dispose();
    languageMaxLength.dispose();
    languageCandidateCap.dispose();
    languageMaxSteps.dispose();
    languageMaxConfigurations.dispose();
    languageTimeoutMs.dispose();
    spaceMaxLength.dispose();
    spaceCandidateCap.dispose();
    spaceMaxSteps.dispose();
    spaceMaxConfigurations.dispose();
    spaceTimeoutMs.dispose();
    profileMaxLength.dispose();
    profileCandidateCap.dispose();
  }
}
