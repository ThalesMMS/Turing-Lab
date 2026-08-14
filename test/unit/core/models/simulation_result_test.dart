//
//  simulation_result_test.dart
//  Turing Lab
//
//  Tests for SimulationResult model, verifying that it correctly stores
//  simulation data, serializes to/from JSON, and includes optional
//  computation tree for NFA simulations.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/nfa_computation_tree.dart';
import 'package:turing_lab/core/models/nfa_path_node.dart';
import 'package:turing_lab/core/models/simulation_result.dart';
import 'package:turing_lab/core/models/simulation_step.dart';

void main() {
  group('SimulationResult', () {
    final testSteps = [
      const SimulationStep(
          currentState: 'q0', remainingInput: 'abc', stepNumber: 0),
      const SimulationStep(
          currentState: 'q1', remainingInput: 'bc', stepNumber: 1),
    ];

    final testTree = NFAComputationTree.accepted(
      root: const NFAPathNode(
        currentState: 'q0',
        remainingInput: 'test',
        stepNumber: 0,
      ),
      inputString: 'test',
      totalSteps: 5,
    );

    group('Factory Constructors', () {
      test('success factory creates result without computation tree', () {
        final result = SimulationResult.success(
          inputString: 'abc',
          steps: testSteps,
          executionTime: const Duration(milliseconds: 100),
        );

        expect(result.accepted, true);
        expect(result.inputString, 'abc');
        expect(result.steps, testSteps);
        expect(result.computationTree, null);
        expect(result.errorMessage, '');
      });

      test('success factory creates result with computation tree', () {
        final result = SimulationResult.success(
          inputString: 'test',
          steps: testSteps,
          executionTime: const Duration(milliseconds: 100),
          computationTree: testTree,
        );

        expect(result.accepted, true);
        expect(result.computationTree, testTree);
      });

      test('failure factory creates result with computation tree', () {
        final result = SimulationResult.failure(
          inputString: 'test',
          steps: testSteps,
          errorMessage: 'Test error',
          executionTime: const Duration(milliseconds: 100),
          computationTree: testTree,
        );

        expect(result.accepted, false);
        expect(result.errorMessage, 'Test error');
        expect(result.computationTree, testTree);
      });

      test('timeout factory creates result with computation tree', () {
        final result = SimulationResult.timeout(
          inputString: 'test',
          steps: testSteps,
          executionTime: const Duration(seconds: 5),
          computationTree: testTree,
        );

        expect(result.accepted, false);
        expect(result.errorMessage.contains('timed out'), true);
        expect(result.computationTree, testTree);
      });

      test('infiniteLoop factory creates result with computation tree', () {
        final result = SimulationResult.infiniteLoop(
          inputString: 'test',
          steps: testSteps,
          executionTime: const Duration(milliseconds: 100),
          computationTree: testTree,
        );

        expect(result.accepted, false);
        expect(result.errorMessage.contains('nfinite loop'), true);
        expect(result.computationTree, testTree);
      });

      test('error factory creates result with computation tree', () {
        final result = SimulationResult.error(
          inputString: 'test',
          errorMessage: 'Test error',
          executionTime: const Duration(milliseconds: 100),
          computationTree: testTree,
        );

        expect(result.accepted, false);
        expect(result.steps.isEmpty, true);
        expect(result.computationTree, testTree);
      });
    });

    group('copyWith', () {
      test('copyWith preserves computation tree when not specified', () {
        final result = SimulationResult.success(
          inputString: 'test',
          steps: testSteps,
          executionTime: const Duration(milliseconds: 100),
          computationTree: testTree,
        );

        final copied = result.copyWith(inputString: 'modified');

        expect(copied.inputString, 'modified');
        expect(copied.computationTree, testTree);
      });

      test('copyWith can update computation tree', () {
        final result = SimulationResult.success(
          inputString: 'test',
          steps: testSteps,
          executionTime: const Duration(milliseconds: 100),
        );

        final copied = result.copyWith(computationTree: testTree);

        expect(copied.computationTree, testTree);
      });
    });

    group('JSON Serialization', () {
      test('toJson includes computation tree when present', () {
        final result = SimulationResult.success(
          inputString: 'test',
          steps: testSteps,
          executionTime: const Duration(milliseconds: 100),
          computationTree: testTree,
        );

        final json = result.toJson();

        expect(json['inputString'], 'test');
        expect(json['accepted'], true);
        expect(json['computationTree'], isNotNull);
        expect(json['computationTree']['inputString'], 'test');
      });

      test('toJson excludes computation tree when null', () {
        final result = SimulationResult.success(
          inputString: 'test',
          steps: testSteps,
          executionTime: const Duration(milliseconds: 100),
        );

        final json = result.toJson();

        expect(json['inputString'], 'test');
        expect(json['accepted'], true);
        expect(json.containsKey('computationTree'), false);
      });

      test('fromJson deserializes computation tree when present', () {
        final json = {
          'inputString': 'test',
          'accepted': true,
          'steps': testSteps.map((s) => s.toJson()).toList(),
          'errorMessage': '',
          'executionTime': 100,
          'computationTree': testTree.toJson(),
        };

        final result = SimulationResult.fromJson(json);

        expect(result.inputString, 'test');
        expect(result.accepted, true);
        expect(result.computationTree, isNotNull);
        expect(result.computationTree!.inputString, 'test');
        expect(result.computationTree!.accepted, true);
      });

      test('fromJson deserializes without computation tree when absent', () {
        final json = {
          'inputString': 'test',
          'accepted': true,
          'steps': testSteps.map((s) => s.toJson()).toList(),
          'errorMessage': '',
          'executionTime': 100,
        };

        final result = SimulationResult.fromJson(json);

        expect(result.inputString, 'test');
        expect(result.accepted, true);
        expect(result.computationTree, null);
      });
    });

    group('Equality', () {
      test('computation tree is included in equality check', () {
        final result1 = SimulationResult.success(
          inputString: 'test',
          steps: testSteps,
          executionTime: const Duration(milliseconds: 100),
          computationTree: testTree,
        );

        final result2 = SimulationResult.success(
          inputString: 'test',
          steps: testSteps,
          executionTime: const Duration(milliseconds: 100),
        );

        // Results with different computation trees should not be equal
        expect(result1 == result2, false);
      });

      test('computation tree is included in hashCode', () {
        final result1 = SimulationResult.success(
          inputString: 'test',
          steps: testSteps,
          executionTime: const Duration(milliseconds: 100),
          computationTree: testTree,
        );

        final result2 = SimulationResult.success(
          inputString: 'test',
          steps: testSteps,
          executionTime: const Duration(milliseconds: 100),
        );

        // Results with different computation trees should have different hash codes
        expect(result1.hashCode != result2.hashCode, true);
      });

      test('identical results are equal', () {
        final result = SimulationResult.success(
          inputString: 'test',
          steps: testSteps,
          executionTime: const Duration(milliseconds: 100),
          computationTree: testTree,
        );

        // A result should equal itself
        expect(result == result, true);
        expect(result.hashCode, result.hashCode);
      });
    });

    group('Backward Compatibility', () {
      test('existing code works without computation tree parameter', () {
        // Verify that existing code that doesn't pass computationTree still works
        final result = SimulationResult.success(
          inputString: 'test',
          steps: testSteps,
          executionTime: const Duration(milliseconds: 100),
        );

        expect(result.accepted, true);
        expect(result.computationTree, null);
        expect(result.stepCount, testSteps.length);
      });

      test('all factory methods accept optional computation tree', () {
        // Success
        final success = SimulationResult.success(
          inputString: 'test',
          steps: testSteps,
          executionTime: const Duration(milliseconds: 100),
        );
        expect(success.computationTree, null);

        // Failure
        final failure = SimulationResult.failure(
          inputString: 'test',
          steps: testSteps,
          errorMessage: 'error',
          executionTime: const Duration(milliseconds: 100),
        );
        expect(failure.computationTree, null);

        // Timeout
        final timeout = SimulationResult.timeout(
          inputString: 'test',
          steps: testSteps,
          executionTime: const Duration(milliseconds: 100),
        );
        expect(timeout.computationTree, null);

        // Infinite loop
        final infiniteLoop = SimulationResult.infiniteLoop(
          inputString: 'test',
          steps: testSteps,
          executionTime: const Duration(milliseconds: 100),
        );
        expect(infiniteLoop.computationTree, null);

        // Error
        final error = SimulationResult.error(
          inputString: 'test',
          errorMessage: 'error',
          executionTime: const Duration(milliseconds: 100),
        );
        expect(error.computationTree, null);
      });
    });
  });
}
