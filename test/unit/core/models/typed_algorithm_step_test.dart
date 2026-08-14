import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/algorithm_step.dart';
import 'package:turing_lab/core/models/cyk_step.dart';
import 'package:turing_lab/core/models/dfa_minimization_step.dart';
import 'package:turing_lab/core/models/nfa_to_dfa_step.dart';
import 'package:turing_lab/core/models/regex_to_nfa_step.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/typed_algorithm_step.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('TypedAlgorithmStep', () {
    test('wraps a base step and typed payload', () {
      final payload = _nfaToDfaStep();
      final typedStep = TypedAlgorithmStep<NFAToDFAStep>(
        baseStep: payload.baseStep,
        payload: payload,
      );

      expect(typedStep.baseStep, payload.baseStep);
      expect(typedStep.payload, payload);
    });

    test('fromProperties extracts a typed payload', () {
      final payload = _nfaToDfaStep();
      final baseStep = _baseStep().copyWith(
        properties: {kNfaToDfaStepKey: payload},
      );

      final typedStep = TypedAlgorithmStep<NFAToDFAStep>.fromProperties(
        baseStep: baseStep,
        propertyKey: kNfaToDfaStepKey,
      );

      expect(typedStep.baseStep, baseStep);
      expect(typedStep.payload, payload);
    });

    test('fromProperties rejects missing payloads', () {
      final baseStep = _baseStep();

      expect(
        () => TypedAlgorithmStep<NFAToDFAStep>.fromProperties(
          baseStep: baseStep,
          propertyKey: kNfaToDfaStepKey,
        ),
        throwsArgumentError,
      );
    });

    test('delegates base step getters', () {
      final payload = _nfaToDfaStep();
      final typedStep = TypedAlgorithmStep<NFAToDFAStep>(
        baseStep: payload.baseStep,
        payload: payload,
      );

      expect(typedStep.id, payload.baseStep.id);
      expect(typedStep.stepNumber, payload.baseStep.stepNumber);
      expect(typedStep.displayNumber, payload.baseStep.displayNumber);
      expect(typedStep.title, payload.baseStep.title);
      expect(typedStep.explanation, payload.baseStep.explanation);
      expect(typedStep.type, payload.baseStep.type);
    });

    test('copyWith preserves unchanged fields and updates requested fields',
        () {
      final payload = _nfaToDfaStep();
      final replacementPayload = _nfaToDfaStep(id: 'replacement');
      final replacementBase = _baseStep(id: 'replacement-base');
      final typedStep = TypedAlgorithmStep<NFAToDFAStep>(
        baseStep: payload.baseStep,
        payload: payload,
      );

      expect(typedStep.copyWith().baseStep, payload.baseStep);
      expect(typedStep.copyWith().payload, payload);

      final updated = typedStep.copyWith(
        baseStep: replacementBase,
        payload: replacementPayload,
      );

      expect(updated.baseStep, replacementBase);
      expect(updated.payload, replacementPayload);
    });
  });

  group('typed payload utilities', () {
    test('extractPayload returns matching payloads only', () {
      final payload = _nfaToDfaStep();
      final baseStep = _baseStep().copyWith(
        properties: {kNfaToDfaStepKey: payload},
      );

      expect(
        extractPayload<NFAToDFAStep>(baseStep, kNfaToDfaStepKey),
        payload,
      );
      expect(
        extractPayload<DFAMinimizationStep>(baseStep, kNfaToDfaStepKey),
        isNull,
      );
      expect(
        extractPayload<NFAToDFAStep>(baseStep, kDfaMinimizationStepKey),
        isNull,
      );
    });

    test('detectPayloadType recognizes known specialized step payloads', () {
      final cykStep = _baseStep(type: AlgorithmType.cykParsing).copyWith(
        properties: {kCykStepKey: _cykStep()},
      );
      final nfaStep = _baseStep().copyWith(
        properties: {kNfaToDfaStepKey: _nfaToDfaStep()},
      );
      final dfaStep = _baseStep(type: AlgorithmType.dfaMinimization).copyWith(
        properties: {kDfaMinimizationStepKey: _dfaMinimizationStep()},
      );
      final regexStep = _baseStep(type: AlgorithmType.regexToNfa).copyWith(
        properties: {kRegexToNfaStepKey: _regexToNfaStep()},
      );

      expect(detectPayloadType(cykStep), CYKStep);
      expect(detectPayloadType(nfaStep), NFAToDFAStep);
      expect(detectPayloadType(dfaStep), DFAMinimizationStep);
      expect(detectPayloadType(regexStep), RegexToNFAStep);
      expect(detectPayloadType(_baseStep()), isNull);
    });

    test('extractDetectedPayload returns the first recognized payload', () {
      final payload = _regexToNfaStep();
      final baseStep = _baseStep(type: AlgorithmType.regexToNfa).copyWith(
        properties: {kRegexToNfaStepKey: payload},
      );

      expect(extractDetectedPayload(baseStep), payload);
    });
  });
}

AlgorithmStep _baseStep({
  String id = 'step-1',
  AlgorithmType type = AlgorithmType.nfaToDfa,
}) {
  return AlgorithmStep(
    id: id,
    stepNumber: 0,
    title: 'Test step',
    explanation: 'Test explanation',
    type: type,
    timestamp: DateTime(2026, 1, 1),
  );
}

State _state(String id) {
  return State(id: id, label: id, position: Vector2.zero());
}

CYKStep _cykStep() {
  return CYKStep.fillBaseCase(
    id: 'cyk-step',
    stepNumber: 0,
    position: 0,
    terminal: 'a',
    derivingVariables: {'A'},
  );
}

NFAToDFAStep _nfaToDfaStep({String id = 'nfa-step'}) {
  return NFAToDFAStep(
    baseStep: _baseStep(id: id),
    stepType: NFAToDFAStepType.epsilonClosure,
    currentStateSet: {_state('q0')},
    epsilonClosure: {_state('q0'), _state('q1')},
    isAcceptingState: false,
    isNewState: true,
  );
}

DFAMinimizationStep _dfaMinimizationStep() {
  return DFAMinimizationStep(
    baseStep: _baseStep(type: AlgorithmType.dfaMinimization),
    stepType: DFAMinimizationStepType.initialPartition,
    currentPartition: [
      {_state('q0')},
      {_state('q1')},
    ],
  );
}

RegexToNFAStep _regexToNfaStep() {
  return RegexToNFAStep(
    baseStep: _baseStep(type: AlgorithmType.regexToNfa),
    stepType: RegexToNFAStepType.start,
    regexFragment: 'a',
  );
}
