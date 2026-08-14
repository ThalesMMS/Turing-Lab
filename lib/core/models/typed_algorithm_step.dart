//
//  typed_algorithm_step.dart
//  Turing Lab
//
//  Lightweight typed payload wrapper for algorithm step UI adapters.
//

import 'algorithm_step.dart';
import 'cyk_step.dart';
import 'dfa_minimization_step.dart';
import 'nfa_to_dfa_step.dart';
import 'regex_to_nfa_step.dart';

const String kCykStepKey = 'cykStep';
const String kNfaToDfaStepKey = 'nfaToDfaStep';
const String kDfaMinimizationStepKey = 'dfaMinimizationStep';
const String kRegexToNfaStepKey = 'regexToNfaStep';

class TypedAlgorithmStep<T> {
  final AlgorithmStep baseStep;
  final T payload;

  const TypedAlgorithmStep({required this.baseStep, required this.payload});

  factory TypedAlgorithmStep.fromProperties({
    required AlgorithmStep baseStep,
    required String propertyKey,
  }) {
    final payload = extractPayload<T>(baseStep, propertyKey);
    if (payload == null) {
      throw ArgumentError.value(
        propertyKey,
        'propertyKey',
        'No payload of type $T found on algorithm step ${baseStep.id}',
      );
    }

    return TypedAlgorithmStep(baseStep: baseStep, payload: payload);
  }

  String get id => baseStep.id;
  int get stepNumber => baseStep.stepNumber;
  int get displayNumber => baseStep.displayNumber;
  String get title => baseStep.title;
  String get explanation => baseStep.explanation;
  AlgorithmType get type => baseStep.type;

  TypedAlgorithmStep<T> copyWith({AlgorithmStep? baseStep, T? payload}) {
    return TypedAlgorithmStep<T>(
      baseStep: baseStep ?? this.baseStep,
      payload: payload ?? this.payload,
    );
  }
}

T? extractPayload<T>(AlgorithmStep step, String propertyKey) {
  final payload = step.properties[propertyKey];
  return payload is T ? payload : null;
}

Type? detectPayloadType(AlgorithmStep step) {
  final payload = extractDetectedPayload(step);
  return payload?.runtimeType;
}

Object? extractDetectedPayload(AlgorithmStep step) {
  return extractPayload<CYKStep>(step, kCykStepKey) ??
      extractPayload<NFAToDFAStep>(step, kNfaToDfaStepKey) ??
      extractPayload<DFAMinimizationStep>(step, kDfaMinimizationStepKey) ??
      extractPayload<RegexToNFAStep>(step, kRegexToNfaStepKey);
}
