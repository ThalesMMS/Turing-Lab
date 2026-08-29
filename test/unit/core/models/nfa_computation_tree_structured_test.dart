import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/automaton_simulation_messages.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/models/nfa_computation_tree.dart';
import 'package:turing_lab/core/models/nfa_path_node.dart';
import 'package:turing_lab/l10n/app_localizations_en.dart';
import 'package:turing_lab/l10n/app_localizations_pt.dart';
import 'package:turing_lab/l10n/app_localizations_structured_messages.dart';

void main() {
  const root = NFAPathNode(
    currentState: 'q0',
    remainingInput: 'ab',
    stepNumber: 0,
  );

  test('timeout tree carries a typed locale-neutral outcome', () {
    final tree = NFAComputationTree.timeout(
      root: root,
      inputString: 'ab',
      totalSteps: 12,
    );

    expect(
      tree.structuredMessage?.stableCode,
      'automaton.simulation.computation-tree-timeout',
    );
    expect(
      tree.structuredMessage?.arguments['steps']?.kind,
      StructuredMessageArgumentKind.count,
    );
    expect(tree.structuredMessage?.arguments['steps']?.value, 12);
    expect(NFAComputationTree.fromJson(tree.toJson()), tree);
  });

  test('rejection preserves legacy error and structured payload', () {
    final message = AutomatonSimulationMessages.nfaNotAccepted();
    final tree = NFAComputationTree.rejected(
      root: root,
      inputString: 'ab',
      totalSteps: 2,
      errorMessage: 'Input not accepted - no accepting state reached',
      structuredMessage: message,
    );

    expect(
      tree.errorMessage,
      'Input not accepted - no accepting state reached',
    );
    expect(tree.structuredMessage, message);
    final restored = NFAComputationTree.fromJson(tree.toJson());
    expect(restored.structuredMessage, message);
    expect(restored.errorMessage, tree.errorMessage);
  });

  test('infinite-loop tree exposes its bounded step count', () {
    final tree = NFAComputationTree.infiniteLoop(
      root: root,
      inputString: 'ab',
      totalSteps: 99,
    );

    expect(
      tree.structuredMessage?.stableCode,
      'automaton.simulation.computation-tree-infinite-loop',
    );
    expect(tree.structuredMessage?.arguments['steps']?.value, 99);
    expect(tree.isInfiniteLoop, isTrue);
  });

  test('tree outcomes resolve in both supported locales', () {
    final timeout = AutomatonSimulationMessages.computationTreeTimeout(
      steps: 12,
    );
    final loop = AutomatonSimulationMessages.computationTreeInfiniteLoop(
      steps: 99,
    );
    final en = AppLocalizationsEn();
    final pt = AppLocalizationsPt();

    expect(en.resolveStructuredMessage(timeout), contains('timed out'));
    expect(pt.resolveStructuredMessage(timeout), contains('tempo limite'));
    expect(en.resolveStructuredMessage(loop), contains('infinite loop'));
    expect(pt.resolveStructuredMessage(loop), contains('loop infinito'));
  });

  test('path node copyWith replaces either description representation', () {
    final message = AutomatonSimulationMessages.nfaNotAccepted();
    const legacyNode = NFAPathNode(
      currentState: 'q0',
      remainingInput: 'a',
      stepNumber: 0,
      description: 'Legacy description',
    );
    final structuredNode = legacyNode.copyWith(descriptionMessage: message);

    expect(structuredNode.description, isNull);
    expect(structuredNode.descriptionMessage, message);

    final restoredLegacy = structuredNode.copyWith(
      description: 'Replacement description',
    );
    expect(restoredLegacy.description, 'Replacement description');
    expect(restoredLegacy.descriptionMessage, isNull);

    final unchanged = structuredNode.copyWith();
    expect(unchanged.description, isNull);
    expect(unchanged.descriptionMessage, message);
  });
}
