//
//  algorithm_step_test.dart
//  Turing Lab
//
//  Unit tests for educational algorithm-step models,
//  covering the base AlgorithmStep, NFAToDFAStep, DFAMinimizationStep, and
//  FAToRegexStep. Validates constructors, factories, JSON serialization,
//  validation, equality operators, and helper methods.
//
//  Thales Matheus Mendonça Santos - January 2026
//
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/algorithm_step.dart';
import 'package:turing_lab/core/models/nfa_to_dfa_step.dart';
import 'package:turing_lab/core/models/dfa_minimization_step.dart';
import 'package:turing_lab/core/models/fa_to_regex_step.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/transition.dart';
import 'package:vector_math/vector_math_64.dart';

part 'algorithm_step_fa_to_regex_cases.dart';
part 'algorithm_step_type_extension_cases.dart';

void main() {
  group('AlgorithmStep Base Model Tests', () {
    late AlgorithmStep testStep;
    late DateTime testTimestamp;

    setUp(() {
      testTimestamp = DateTime(2026, 1, 21, 10, 30);
      testStep = AlgorithmStep(
        id: 'step-1',
        stepNumber: 0,
        title: 'Test Step',
        explanation: 'This is a test step explanation',
        type: AlgorithmType.nfaToDfa,
        timestamp: testTimestamp,
        properties: {'key': 'value'},
      );
    });

    test('Constructor should create valid step with all properties', () {
      expect(testStep.id, 'step-1');
      expect(testStep.stepNumber, 0);
      expect(testStep.title, 'Test Step');
      expect(testStep.explanation, 'This is a test step explanation');
      expect(testStep.type, AlgorithmType.nfaToDfa);
      expect(testStep.timestamp, testTimestamp);
      expect(testStep.properties, {'key': 'value'});
    });

    test('Constructor should use current timestamp if not provided', () {
      final beforeCreation = DateTime.now();
      final step = AlgorithmStep(
        id: 'step-2',
        stepNumber: 1,
        title: 'Auto-timestamped',
        explanation: 'Step with auto timestamp',
        type: AlgorithmType.dfaMinimization,
      );
      final afterCreation = DateTime.now();

      expect(
        step.timestamp.isAfter(beforeCreation) ||
            step.timestamp.isAtSameMomentAs(beforeCreation),
        true,
      );
      expect(
        step.timestamp.isBefore(afterCreation) ||
            step.timestamp.isAtSameMomentAs(afterCreation),
        true,
      );
    });

    test('Properties should be unmodifiable', () {
      final mutableProps = <String, dynamic>{'key': 'value'};
      final step = AlgorithmStep(
        id: 'step-3',
        stepNumber: 2,
        title: 'Immutable Test',
        explanation: 'Testing immutability',
        type: AlgorithmType.faToRegex,
        properties: mutableProps,
      );

      // Modify original map
      mutableProps['newKey'] = 'newValue';

      // Step properties should not be affected
      expect(step.properties, {'key': 'value'});
      expect(step.properties.containsKey('newKey'), false);
    });

    test('copyWith should create new instance with updated properties', () {
      final copied = testStep.copyWith(title: 'Updated Title', stepNumber: 5);

      expect(copied.id, testStep.id);
      expect(copied.title, 'Updated Title');
      expect(copied.stepNumber, 5);
      expect(copied.explanation, testStep.explanation);
      expect(copied.type, testStep.type);
      expect(copied.timestamp, testStep.timestamp);
    });

    test('copyWith should preserve unchanged properties', () {
      final copied = testStep.copyWith();

      expect(copied.id, testStep.id);
      expect(copied.stepNumber, testStep.stepNumber);
      expect(copied.title, testStep.title);
      expect(copied.explanation, testStep.explanation);
      expect(copied.type, testStep.type);
      expect(copied.timestamp, testStep.timestamp);
      expect(copied.properties, testStep.properties);
    });

    test('toJson should serialize all properties correctly', () {
      final json = testStep.toJson();

      expect(json['id'], 'step-1');
      expect(json['stepNumber'], 0);
      expect(json['title'], 'Test Step');
      expect(json['explanation'], 'This is a test step explanation');
      expect(json['type'], 'nfaToDfa');
      expect(json['timestamp'], testTimestamp.toIso8601String());
      expect(json['properties'], {'key': 'value'});
    });

    test('fromJson should deserialize correctly', () {
      final json = testStep.toJson();
      final deserialized = AlgorithmStep.fromJson(json);

      expect(deserialized.id, testStep.id);
      expect(deserialized.stepNumber, testStep.stepNumber);
      expect(deserialized.title, testStep.title);
      expect(deserialized.explanation, testStep.explanation);
      expect(deserialized.type, testStep.type);
      expect(deserialized.timestamp, testStep.timestamp);
      expect(deserialized.properties, testStep.properties);
    });

    test('fromJson should handle missing properties gracefully', () {
      final json = {
        'id': 'step-min',
        'stepNumber': 0,
        'title': 'Minimal Step',
        'explanation': 'Minimal explanation',
        'type': 'nfaToDfa',
        'timestamp': testTimestamp.toIso8601String(),
      };

      final deserialized = AlgorithmStep.fromJson(json);

      expect(deserialized.properties, isEmpty);
    });

    test('fromJson should use default type for unknown type', () {
      final json = {
        'id': 'step-unknown',
        'stepNumber': 0,
        'title': 'Unknown Type',
        'explanation': 'Unknown type test',
        'type': 'unknownType',
        'timestamp': testTimestamp.toIso8601String(),
      };

      final deserialized = AlgorithmStep.fromJson(json);

      expect(deserialized.type, AlgorithmType.nfaToDfa);
    });

    test('Equality operator should work correctly', () {
      final step1 = AlgorithmStep(
        id: 'step-eq',
        stepNumber: 1,
        title: 'Equality Test',
        explanation: 'Testing equality',
        type: AlgorithmType.nfaToDfa,
        timestamp: testTimestamp,
      );

      final step2 = AlgorithmStep(
        id: 'step-eq',
        stepNumber: 1,
        title: 'Equality Test',
        explanation: 'Testing equality',
        type: AlgorithmType.nfaToDfa,
        timestamp: testTimestamp,
      );

      final step3 = AlgorithmStep(
        id: 'step-diff',
        stepNumber: 1,
        title: 'Equality Test',
        explanation: 'Testing equality',
        type: AlgorithmType.nfaToDfa,
        timestamp: testTimestamp,
      );

      expect(step1 == step2, true);
      expect(step1 == step3, false);
      expect(step1 == step1, true); // Same instance
    });

    test('hashCode should be consistent with equality', () {
      final step1 = AlgorithmStep(
        id: 'step-hash',
        stepNumber: 1,
        title: 'Hash Test',
        explanation: 'Testing hash',
        type: AlgorithmType.nfaToDfa,
        timestamp: testTimestamp,
      );

      final step2 = AlgorithmStep(
        id: 'step-hash',
        stepNumber: 1,
        title: 'Hash Test',
        explanation: 'Testing hash',
        type: AlgorithmType.nfaToDfa,
        timestamp: testTimestamp,
      );

      expect(step1.hashCode, step2.hashCode);
    });

    test('toString should return informative string', () {
      final str = testStep.toString();

      expect(str.contains('step-1'), true);
      expect(str.contains('0'), true);
      expect(str.contains('Test Step'), true);
      expect(str.contains('nfaToDfa'), true);
    });

    test('validate should return empty list for valid step', () {
      final errors = testStep.validate();

      expect(errors, isEmpty);
    });

    test('validate should detect empty id', () {
      final invalidStep = AlgorithmStep(
        id: '',
        stepNumber: 0,
        title: 'Valid Title',
        explanation: 'Valid explanation',
        type: AlgorithmType.nfaToDfa,
      );

      final errors = invalidStep.validate();

      expect(errors.isNotEmpty, true);
      expect(errors.any((e) => e.contains('ID')), true);
    });

    test('validate should detect negative step number', () {
      final invalidStep = AlgorithmStep(
        id: 'step-neg',
        stepNumber: -1,
        title: 'Valid Title',
        explanation: 'Valid explanation',
        type: AlgorithmType.nfaToDfa,
      );

      final errors = invalidStep.validate();

      expect(errors.isNotEmpty, true);
      expect(errors.any((e) => e.contains('number')), true);
    });

    test('validate should detect empty title', () {
      final invalidStep = AlgorithmStep(
        id: 'step-valid',
        stepNumber: 0,
        title: '',
        explanation: 'Valid explanation',
        type: AlgorithmType.nfaToDfa,
      );

      final errors = invalidStep.validate();

      expect(errors.isNotEmpty, true);
      expect(errors.any((e) => e.contains('title')), true);
    });

    test('validate should detect empty explanation', () {
      final invalidStep = AlgorithmStep(
        id: 'step-valid',
        stepNumber: 0,
        title: 'Valid Title',
        explanation: '',
        type: AlgorithmType.nfaToDfa,
      );

      final errors = invalidStep.validate();

      expect(errors.isNotEmpty, true);
      expect(errors.any((e) => e.contains('explanation')), true);
    });

    test('validate should detect multiple errors', () {
      final invalidStep = AlgorithmStep(
        id: '',
        stepNumber: -1,
        title: '',
        explanation: '',
        type: AlgorithmType.nfaToDfa,
      );

      final errors = invalidStep.validate();

      expect(errors.length, 4);
    });

    test('isValid should return true for valid step', () {
      expect(testStep.isValid, true);
    });

    test('isValid should return false for invalid step', () {
      final invalidStep = AlgorithmStep(
        id: '',
        stepNumber: 0,
        title: 'Valid',
        explanation: 'Valid',
        type: AlgorithmType.nfaToDfa,
      );

      expect(invalidStep.isValid, false);
    });

    test('displayNumber should be 1-indexed', () {
      expect(testStep.displayNumber, 1); // stepNumber 0 -> display 1

      final step5 = testStep.copyWith(stepNumber: 5);
      expect(step5.displayNumber, 6); // stepNumber 5 -> display 6
    });
  });

  group('AlgorithmType Extension Tests', () {
    test('displayName should return human-readable names', () {
      expect(AlgorithmType.nfaToDfa.displayName, 'NFA to DFA Conversion');
      expect(AlgorithmType.dfaMinimization.displayName, 'DFA Minimization');
      expect(AlgorithmType.faToRegex.displayName, 'FA to Regex Conversion');
    });

    test('description should return informative descriptions', () {
      expect(AlgorithmType.nfaToDfa.description.isNotEmpty, true);
      expect(AlgorithmType.dfaMinimization.description.isNotEmpty, true);
      expect(AlgorithmType.faToRegex.description.isNotEmpty, true);

      expect(AlgorithmType.nfaToDfa.description.contains('subset'), true);
      expect(
        AlgorithmType.dfaMinimization.description.contains('Hopcroft'),
        true,
      );
      expect(AlgorithmType.faToRegex.description.contains('elimination'), true);
    });
  });

  group('NFAToDFAStep Tests', () {
    late State q0, q1, q2;

    setUp(() {
      q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2(0, 0),
        isInitial: true,
      );
      q1 = State(id: 'q1', label: 'q1', position: Vector2(100, 0));
      q2 = State(
        id: 'q2',
        label: 'q2',
        position: Vector2(200, 0),
        isAccepting: true,
      );
    });

    test('initialEpsilonClosure factory should create correct step', () {
      final step = NFAToDFAStep.initialEpsilonClosure(
        id: 'step-ec-0',
        stepNumber: 0,
        initialState: q0,
        epsilonClosure: {q0, q1},
        containsAcceptingState: false,
      );

      expect(step.stepType, NFAToDFAStepType.epsilonClosure);
      expect(step.currentStateSet, {q0});
      expect(step.epsilonClosure, {q0, q1});
      expect(step.isAcceptingState, false);
      expect(step.isNewState, true);
      expect(step.dfaStateId, 'q0');
      expect(step.title.contains('ε-closure'), true);
    });

    test('initialEpsilonClosure should detect accepting state', () {
      final step = NFAToDFAStep.initialEpsilonClosure(
        id: 'step-ec-1',
        stepNumber: 0,
        initialState: q0,
        epsilonClosure: {q0, q2},
        containsAcceptingState: true,
      );

      expect(step.isAcceptingState, true);
      expect(step.explanation.contains('accepting'), true);
    });

    test('processSymbol factory should create correct step', () {
      final step = NFAToDFAStep.processSymbol(
        id: 'step-ps-0',
        stepNumber: 1,
        currentStateSet: {q0, q1},
        symbol: 'a',
        reachableStates: {q2},
      );

      expect(step.stepType, NFAToDFAStepType.processSymbol);
      expect(step.currentStateSet, {q0, q1});
      expect(step.processedSymbol, 'a');
      expect(step.reachableStates, {q2});
      expect(step.title.contains('a'), true);
    });

    test('epsilonClosureOfReachable factory should create correct step', () {
      final step = NFAToDFAStep.epsilonClosureOfReachable(
        id: 'step-ecr-0',
        stepNumber: 2,
        reachableStates: {q2},
        epsilonClosure: {q2, q1},
        containsAcceptingState: true,
        isNewState: true,
      );

      expect(step.stepType, NFAToDFAStepType.epsilonClosure);
      expect(step.currentStateSet, {q2});
      expect(step.epsilonClosure, {q2, q1});
      expect(step.nextStateSet, {q2, q1});
      expect(step.isAcceptingState, true);
      expect(step.isNewState, true);
      expect(step.explanation.contains('new DFA state'), true);
    });

    test('createDFAState factory should create correct step', () {
      final step = NFAToDFAStep.createDFAState(
        id: 'step-cs-0',
        stepNumber: 3,
        nfaStateSet: {q0, q1},
        dfaStateId: 'q01',
        dfaStateLabel: '{q0,q1}',
        isAccepting: false,
      );

      expect(step.stepType, NFAToDFAStepType.createState);
      expect(step.currentStateSet, {q0, q1});
      expect(step.dfaStateId, 'q01');
      expect(step.dfaStateLabel, '{q0,q1}');
      expect(step.isAcceptingState, false);
      expect(step.isNewState, true);
      expect(step.title.contains('q01'), true);
    });

    test('createDFATransition factory should create correct step', () {
      final step = NFAToDFAStep.createDFATransition(
        id: 'step-ct-0',
        stepNumber: 4,
        fromStateSet: {q0},
        fromDfaStateId: 'q0',
        symbol: 'b',
        toStateSet: {q1, q2},
        toDfaStateId: 'q12',
      );

      expect(step.stepType, NFAToDFAStepType.createTransition);
      expect(step.currentStateSet, {q0});
      expect(step.processedSymbol, 'b');
      expect(step.nextStateSet, {q1, q2});
      expect(step.dfaStateId, 'q0');
      expect(step.title.contains('b'), true);
    });

    test('completion factory should create correct step', () {
      final step = NFAToDFAStep.completion(
        id: 'step-done',
        stepNumber: 10,
        totalStates: 5,
        totalTransitions: 8,
        totalAcceptingStates: 2,
      );

      expect(step.stepType, NFAToDFAStepType.completion);
      expect(step.currentStateSet, isEmpty);
      expect(step.title.contains('complete'), true);
      expect(step.explanation.contains('5 states'), true);
      expect(step.explanation.contains('8 transitions'), true);
      expect(step.explanation.contains('2 accepting'), true);
    });

    test('State sets should be unmodifiable', () {
      final mutableSet = {q0, q1};
      final step = NFAToDFAStep.processSymbol(
        id: 'step-immut',
        stepNumber: 0,
        currentStateSet: mutableSet,
        symbol: 'a',
        reachableStates: {q2},
      );

      mutableSet.add(q2);

      expect(step.currentStateSet, {q0, q1});
      expect(step.currentStateSet.length, 2);
    });

    test('copyWith should work correctly', () {
      final original = NFAToDFAStep.processSymbol(
        id: 'step-copy',
        stepNumber: 0,
        currentStateSet: {q0},
        symbol: 'a',
        reachableStates: {q1},
      );

      final copied = original.copyWith(processedSymbol: 'b', isNewState: true);

      expect(copied.processedSymbol, 'b');
      expect(copied.isNewState, true);
      expect(copied.currentStateSet, original.currentStateSet);
      expect(copied.stepType, original.stepType);
    });

    test('toJson and fromJson should work correctly', () {
      final original = NFAToDFAStep.createDFAState(
        id: 'step-json',
        stepNumber: 5,
        nfaStateSet: {q0, q1},
        dfaStateId: 'q01',
        dfaStateLabel: '{q0,q1}',
        isAccepting: true,
      );

      final json = original.toJson();
      final deserialized = NFAToDFAStep.fromJson(json);

      expect(deserialized.stepType, original.stepType);
      expect(deserialized.stepNumber, original.stepNumber);
      expect(deserialized.dfaStateId, original.dfaStateId);
      expect(deserialized.dfaStateLabel, original.dfaStateLabel);
      expect(deserialized.isAcceptingState, original.isAcceptingState);
      expect(deserialized.isNewState, original.isNewState);
    });

    test('Helper properties should work correctly', () {
      final step = NFAToDFAStep.epsilonClosureOfReachable(
        id: 'step-help',
        stepNumber: 0,
        reachableStates: {q1},
        epsilonClosure: {q0, q1, q2},
        containsAcceptingState: true,
        isNewState: false,
      );

      expect(step.currentStateSetSize, 1);
      expect(step.epsilonClosureSize, 3);
      expect(step.hasEpsilonClosure, true);
      expect(step.processesSymbol, false);
      expect(step.createsNewComponent, false);
    });

    test('createsNewComponent should detect creation steps', () {
      final stateCreation = NFAToDFAStep.createDFAState(
        id: 'step-create-s',
        stepNumber: 0,
        nfaStateSet: {q0},
        dfaStateId: 'q0',
        dfaStateLabel: 'q0',
        isAccepting: false,
      );

      final transitionCreation = NFAToDFAStep.createDFATransition(
        id: 'step-create-t',
        stepNumber: 1,
        fromStateSet: {q0},
        fromDfaStateId: 'q0',
        symbol: 'a',
        toStateSet: {q1},
        toDfaStateId: 'q1',
      );

      expect(stateCreation.createsNewComponent, true);
      expect(transitionCreation.createsNewComponent, true);
    });

    test('stateSetsSummary should provide readable summary', () {
      final step = NFAToDFAStep.epsilonClosureOfReachable(
        id: 'step-summary',
        stepNumber: 0,
        reachableStates: {q1},
        epsilonClosure: {q0, q1},
        containsAcceptingState: false,
        isNewState: true,
      );

      final summary = step.stateSetsSummary;

      expect(summary.contains('Current'), true);
      expect(summary.contains('ε-closure'), true);
      expect(summary.contains('next'), true);
    });
  });

  group('DFAMinimizationStep Tests', () {
    late State q0, q1, q2, q3;
    late List<Set<State>> testPartition;

    setUp(() {
      q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2(0, 0),
        isInitial: true,
      );
      q1 = State(id: 'q1', label: 'q1', position: Vector2(100, 0));
      q2 = State(
        id: 'q2',
        label: 'q2',
        position: Vector2(200, 0),
        isAccepting: true,
      );
      q3 = State(
        id: 'q3',
        label: 'q3',
        position: Vector2(300, 0),
        isAccepting: true,
      );

      testPartition = [
        {q0, q1},
        {q2, q3},
      ];
    });

    test('initialPartition factory should create correct step', () {
      final step = DFAMinimizationStep.initialPartition(
        id: 'step-ip',
        stepNumber: 0,
        acceptingStates: {q2, q3},
        nonAcceptingStates: {q0, q1},
      );

      expect(step.stepType, DFAMinimizationStepType.initialPartition);
      expect(step.currentPartition.length, 2);
      expect(step.partitionSize, 2);
      expect(step.title.contains('initial partition'), true);
    });

    test('removeUnreachable factory should create correct step', () {
      final step = DFAMinimizationStep.removeUnreachable(
        id: 'step-ru',
        stepNumber: 0,
        unreachableStates: {q3},
        reachableStates: {q0, q1, q2},
      );

      expect(step.stepType, DFAMinimizationStepType.removeUnreachable);
      expect(step.explanation.contains('q3'), true);
      expect(step.explanation.contains('3 reachable'), true);
    });

    test('selectProcessingSet factory should create correct step', () {
      final step = DFAMinimizationStep.selectProcessingSet(
        id: 'step-sps',
        stepNumber: 1,
        currentPartition: testPartition,
        processingSet: {q2, q3},
      );

      expect(step.stepType, DFAMinimizationStepType.selectSet);
      expect(step.processingSet, {q2, q3});
      expect(step.currentPartition, testPartition);
      expect(step.title.contains('Select'), true);
    });

    test('findPredecessors factory should create correct step', () {
      final step = DFAMinimizationStep.findPredecessors(
        id: 'step-fp',
        stepNumber: 2,
        currentPartition: testPartition,
        processingSet: {q2, q3},
        symbol: 'a',
        predecessors: {q0, q1},
      );

      expect(step.stepType, DFAMinimizationStepType.findPredecessors);
      expect(step.distinguishingSymbol, 'a');
      expect(step.predecessors, {q0, q1});
      expect(step.title.contains('a'), true);
    });

    test('findPredecessors with no predecessors should explain', () {
      final step = DFAMinimizationStep.findPredecessors(
        id: 'step-fp-empty',
        stepNumber: 2,
        currentPartition: testPartition,
        processingSet: {q2},
        symbol: 'b',
        predecessors: {},
      );

      expect(step.predecessors, isEmpty);
      expect(step.explanation.contains('No predecessors'), true);
    });

    test('splitClass factory should create correct step', () {
      final newPartition = [
        {q0},
        {q1},
        {q2, q3},
      ];

      final step = DFAMinimizationStep.splitClass(
        id: 'step-sc',
        stepNumber: 3,
        currentPartition: testPartition,
        splitSet: {q0, q1},
        intersection: {q0},
        difference: {q1},
        symbol: 'a',
        newPartition: newPartition,
      );

      expect(step.stepType, DFAMinimizationStepType.splitClass);
      expect(step.splitSet, {q0, q1});
      expect(step.splitIntersection, {q0});
      expect(step.splitDifference, {q1});
      expect(step.causedSplit, true);
      expect(step.newPartition, newPartition);
      expect(step.partitionSize, 3);
      expect(step.explanation.contains('2 → 3'), true);
    });

    test('noSplit factory should create correct step', () {
      final step = DFAMinimizationStep.noSplit(
        id: 'step-ns',
        stepNumber: 4,
        currentPartition: testPartition,
        checkedSet: {q2, q3},
        symbol: 'b',
      );

      expect(step.stepType, DFAMinimizationStepType.noSplit);
      expect(step.splitSet, {q2, q3});
      expect(step.causedSplit, false);
      expect(step.title.contains('No split'), true);
    });

    test('partitionStable factory should create correct step', () {
      final step = DFAMinimizationStep.partitionStable(
        id: 'step-stable',
        stepNumber: 5,
        finalPartition: testPartition,
      );

      expect(step.stepType, DFAMinimizationStepType.partitionStable);
      expect(step.currentPartition, testPartition);
      expect(step.explanation.contains('stabilized'), true);
    });

    test('createMinimizedState factory should create correct step', () {
      final step = DFAMinimizationStep.createMinimizedState(
        id: 'step-cms',
        stepNumber: 6,
        stateId: 'q01',
        equivalenceClass: {q0, q1},
        isAccepting: false,
        isInitial: true,
      );

      expect(step.stepType, DFAMinimizationStepType.createState);
      expect(step.equivalenceClassId, 'q01');
      expect(step.equivalenceClassStates, {q0, q1});
      expect(step.explanation.contains('initial state'), true);
      expect(step.explanation.contains('non-accepting'), true);
    });

    test('createMinimizedTransition factory should create correct step', () {
      final step = DFAMinimizationStep.createMinimizedTransition(
        id: 'step-cmt',
        stepNumber: 7,
        fromStateId: 'q01',
        toStateId: 'q23',
        symbol: 'a',
      );

      expect(step.stepType, DFAMinimizationStepType.createTransition);
      expect(step.distinguishingSymbol, 'a');
      expect(step.explanation.contains('q01'), true);
      expect(step.explanation.contains('q23'), true);
    });

    test('completion factory should create correct step', () {
      final step = DFAMinimizationStep.completion(
        id: 'step-done',
        stepNumber: 10,
        originalStates: 4,
        minimizedStates: 2,
        totalTransitions: 4,
      );

      expect(step.stepType, DFAMinimizationStepType.completion);
      expect(step.title.contains('complete'), true);
      expect(step.explanation.contains('4 state'), true);
      expect(step.explanation.contains('2 state'), true);
      expect(step.explanation.contains('Reduced by 2'), true);
    });

    test('completion should detect already minimal DFA', () {
      final step = DFAMinimizationStep.completion(
        id: 'step-minimal',
        stepNumber: 5,
        originalStates: 3,
        minimizedStates: 3,
        totalTransitions: 6,
      );

      expect(step.explanation.contains('already minimal'), true);
    });

    test('Partition should be unmodifiable', () {
      final mutablePartition = [
        {q0, q1},
        {q2, q3},
      ];
      final step = DFAMinimizationStep.selectProcessingSet(
        id: 'step-immut',
        stepNumber: 0,
        currentPartition: mutablePartition,
        processingSet: {q2, q3},
      );

      mutablePartition.add({q0});

      expect(step.currentPartition.length, 2);
    });

    test('toJson and fromJson should work correctly', () {
      final original = DFAMinimizationStep.splitClass(
        id: 'step-json',
        stepNumber: 5,
        currentPartition: testPartition,
        splitSet: {q0, q1},
        intersection: {q0},
        difference: {q1},
        symbol: 'a',
        newPartition: [
          {q0},
          {q1},
          {q2, q3},
        ],
      );

      final json = original.toJson();
      final deserialized = DFAMinimizationStep.fromJson(json);

      expect(deserialized.stepType, original.stepType);
      expect(deserialized.stepNumber, original.stepNumber);
      expect(deserialized.distinguishingSymbol, original.distinguishingSymbol);
      expect(deserialized.causedSplit, original.causedSplit);
      expect(deserialized.partitionSize, original.partitionSize);
    });

    test('Helper properties should work correctly', () {
      final step = DFAMinimizationStep.selectProcessingSet(
        id: 'step-help',
        stepNumber: 0,
        currentPartition: testPartition,
        processingSet: {q2, q3},
      );

      expect(step.processingSetSize, 2);
      expect(step.refinesPartition, false);
      expect(step.createsComponent, false);
    });

    test('refinesPartition should detect refinement steps', () {
      final splitStep = DFAMinimizationStep.splitClass(
        id: 'step-split',
        stepNumber: 0,
        currentPartition: testPartition,
        splitSet: {q0, q1},
        intersection: {q0},
        difference: {q1},
        symbol: 'a',
        newPartition: [
          {q0},
          {q1},
          {q2, q3},
        ],
      );

      final noSplitStep = DFAMinimizationStep.noSplit(
        id: 'step-nosplit',
        stepNumber: 1,
        currentPartition: testPartition,
        checkedSet: {q2, q3},
        symbol: 'b',
      );

      expect(splitStep.refinesPartition, true);
      expect(noSplitStep.refinesPartition, true);
    });

    test('splitRatio should provide correct ratio', () {
      final step = DFAMinimizationStep.splitClass(
        id: 'step-ratio',
        stepNumber: 0,
        currentPartition: testPartition,
        splitSet: {q0, q1, q2},
        intersection: {q0},
        difference: {q1, q2},
        symbol: 'a',
        newPartition: [
          {q0},
          {q1, q2},
          {q3},
        ],
      );

      expect(step.splitRatio, '1:2');
    });

    test('partitionSummary should provide readable summary', () {
      final step = DFAMinimizationStep.selectProcessingSet(
        id: 'step-summary',
        stepNumber: 0,
        currentPartition: testPartition,
        processingSet: {q2, q3},
      );

      final summary = step.partitionSummary;

      expect(summary.contains('Partition'), true);
      expect(summary.contains('2 classes'), true);
      expect(summary.contains('q0'), true);
    });
  });

  _registerFaToRegexStepTests();
  _registerStepTypeExtensionTests();
}
