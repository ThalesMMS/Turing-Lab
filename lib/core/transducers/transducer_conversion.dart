//
//  transducer_conversion.dart
//  Turing Lab
//
//  Mealy ↔ Moore conversions under the equivalence contract documented in
//  docs/TRANSDUCER_CONVERSIONS.md: equal output words for every input word
//  with the simulators' emission rules (Mealy emits nothing for ε, Moore
//  emits its initial state's output). Each conversion returns a report with
//  didactic steps and states explicitly when the result is exact or differs
//  by the Moore initial output.
//

import 'transducer_analysis.dart';
import 'transducer_ids.dart';
import 'transducer_models.dart';
import 'transducer_symbols.dart';

/// How the converted machine relates to the source.
enum TransducerConversionOutcome {
  /// Same output for every input word, including the empty word.
  exact,

  /// Same output for every input word except that the Moore initial output
  /// is not emitted by the Mealy result; [TransducerConversionReport
  /// .droppedInitialOutput] carries the dropped prefix.
  conventionDifference,
}

enum TransducerConversionStepKind {
  /// A Moore state copy `(state, output)` was created.
  createStateCopy,

  /// A Mealy transition was mapped onto Moore transitions between copies.
  mapTransition,

  /// A Moore transition became a Mealy transition carrying the target output.
  carryTargetOutput,

  /// The Moore initial output could not be expressed and was dropped.
  dropInitialOutput,

  /// A state copy nothing reaches was removed.
  pruneUnreachableCopy,
}

final class TransducerConversionStep {
  const TransducerConversionStep({
    required this.kind,
    required this.subject,
    this.detail,
    this.output,
  });

  final TransducerConversionStepKind kind;

  /// State or transition the step is about (label or id).
  final String subject;

  /// Secondary subject, such as the target state or the transition input.
  final String? detail;

  /// Output word involved, rendered space-separated (`λ` when empty).
  final String? output;
}

sealed class TransducerConversionResult<TTarget extends Object> {
  const TransducerConversionResult();
}

final class TransducerConversionReport<TTarget extends Object>
    extends TransducerConversionResult<TTarget> {
  const TransducerConversionReport({
    required this.machine,
    required this.outcome,
    required this.steps,
    required this.sourceStateCount,
    required this.sourceTransitionCount,
    this.droppedInitialOutput,
  });

  final TTarget machine;
  final TransducerConversionOutcome outcome;
  final List<TransducerConversionStep> steps;
  final int sourceStateCount;
  final int sourceTransitionCount;
  final TransducerOutputWord? droppedInitialOutput;
}

/// The source machine is not deterministic or structurally valid, so no
/// conversion is attempted; [diagnostics] come from [TransducerAnalyzer].
final class TransducerConversionFailure<TTarget extends Object>
    extends TransducerConversionResult<TTarget> {
  const TransducerConversionFailure(this.diagnostics);

  final List<TransducerDiagnostic> diagnostics;
}

String renderOutputWord(TransducerOutputWord word) =>
    word.values.isEmpty ? 'λ' : word.values.join(' ');

abstract final class TransducerConverter {
  /// Builds the Moore machine equivalent to [mealy] for every input word.
  static TransducerConversionResult<MooreMachine> mealyToMoore(
    MealyMachine mealy,
  ) {
    final failure = _reject<MooreMachine>(mealy);
    if (failure != null) return failure;
    final initial = mealy.states.singleWhere((state) => state.isInitial);
    final steps = <TransducerConversionStep>[];

    // Distinct incoming output words per state, in a stable order.
    final incomingOutputs = <TransducerStateId, List<TransducerOutputWord>>{
      for (final state in mealy.states) state.id: [],
    };
    for (final transition in mealy.transitions) {
      final outputs = incomingOutputs[transition.to]!;
      if (!outputs.contains(transition.output)) outputs.add(transition.output);
    }

    // Copies: (state, output). The initial state always gets the λ copy,
    // which is the Moore initial state and emits nothing for ε.
    final copies = <(TransducerStateId, TransducerOutputWord), MooreState>{};
    final byState = {for (final state in mealy.states) state.id: state};
    var copyIndex = 0;
    MooreState ensureCopy(
      TransducerStateId stateId,
      TransducerOutputWord output,
    ) {
      return copies.putIfAbsent((stateId, output), () {
        final source = byState[stateId]!;
        final isInitial =
            stateId == initial.id && output == TransducerOutputWord.empty;
        final ordinal = copyIndex++;
        final label = output.values.isEmpty && !isInitial
            ? '${source.label}/λ'
            : output.values.isEmpty
            ? source.label
            : '${source.label}/${output.values.join(' ')}';
        steps.add(
          TransducerConversionStep(
            kind: TransducerConversionStepKind.createStateCopy,
            subject: source.label,
            detail: label,
            output: renderOutputWord(output),
          ),
        );
        return MooreState(
          id: TransducerStateId('${stateId.value}#$ordinal'),
          label: label,
          position: TransducerPoint(
            source.position.x + ordinal % 3 * 24.0,
            source.position.y + ordinal % 3 * 24.0,
          ),
          isInitial: isInitial,
          output: output,
        );
      });
    }

    ensureCopy(initial.id, TransducerOutputWord.empty);
    for (final state in mealy.states) {
      for (final output in incomingOutputs[state.id]!) {
        ensureCopy(state.id, output);
      }
    }

    // Transitions: every copy of the source state moves to the copy of the
    // target that carries the transition output.
    final transitions = <MooreTransition>[];
    final reachable = <TransducerStateId>{};
    final sourceCopies = <TransducerStateId, List<MooreState>>{};
    for (final entry in copies.entries) {
      sourceCopies.putIfAbsent(entry.key.$1, () => []).add(entry.value);
    }
    var transitionIndex = 0;
    for (final transition in mealy.transitions) {
      final target = ensureCopy(transition.to, transition.output);
      final fromLabel = byState[transition.from]!.label;
      for (final fromCopy in sourceCopies[transition.from] ?? const []) {
        transitions.add(
          MooreTransition(
            id: TransducerTransitionId(
              '${transition.id.value}#${transitionIndex++}',
            ),
            from: fromCopy.id,
            to: target.id,
            input: transition.input,
          ),
        );
      }
      steps.add(
        TransducerConversionStep(
          kind: TransducerConversionStepKind.mapTransition,
          subject:
              '$fromLabel --${transition.input.value}--> '
              '${byState[transition.to]!.label}',
          detail: target.label,
          output: renderOutputWord(transition.output),
        ),
      );
    }

    // Prune copies nothing reaches (besides the initial copy).
    final initialCopy = copies[(initial.id, TransducerOutputWord.empty)]!;
    reachable.add(initialCopy.id);
    var frontier = [initialCopy.id];
    while (frontier.isNotEmpty) {
      final next = <TransducerStateId>[];
      for (final transition in transitions) {
        if (frontier.contains(transition.from) &&
            reachable.add(transition.to)) {
          next.add(transition.to);
        }
      }
      frontier = next;
    }
    final keptStates = <MooreState>[];
    for (final copy in copies.values) {
      if (reachable.contains(copy.id)) {
        keptStates.add(copy);
      } else {
        steps.add(
          TransducerConversionStep(
            kind: TransducerConversionStepKind.pruneUnreachableCopy,
            subject: copy.label,
          ),
        );
      }
    }
    final keptTransitions = transitions
        .where((t) => reachable.contains(t.from) && reachable.contains(t.to))
        .toList(growable: false);

    final machine = MooreMachine(
      id: TransducerMachineId('${mealy.id.value}-moore'),
      name: '${mealy.name} (Moore)',
      revision: const TransducerRevision(0),
      inputAlphabet: mealy.inputAlphabet,
      outputAlphabet: mealy.outputAlphabet,
      states: keptStates,
      transitions: keptTransitions,
    );
    return TransducerConversionReport(
      machine: machine,
      outcome: TransducerConversionOutcome.exact,
      steps: List.unmodifiable(steps),
      sourceStateCount: mealy.states.length,
      sourceTransitionCount: mealy.transitions.length,
    );
  }

  /// Builds the Mealy machine that agrees with [moore] on every input word
  /// after the Moore initial output; exact when that output is empty.
  static TransducerConversionResult<MealyMachine> mooreToMealy(
    MooreMachine moore,
  ) {
    final failure = _reject<MealyMachine>(moore);
    if (failure != null) return failure;
    final initial = moore.states.singleWhere((state) => state.isInitial);
    final byState = {for (final state in moore.states) state.id: state};
    final steps = <TransducerConversionStep>[];
    final states = [
      for (final state in moore.states)
        MealyState(
          id: state.id,
          label: state.label,
          position: state.position,
          isInitial: state.isInitial,
        ),
    ];
    final transitions = [
      for (final transition in moore.transitions)
        MealyTransition(
          id: transition.id,
          from: transition.from,
          to: transition.to,
          input: transition.input,
          output: byState[transition.to]!.output,
        ),
    ];
    for (final transition in moore.transitions) {
      final target = byState[transition.to]!;
      steps.add(
        TransducerConversionStep(
          kind: TransducerConversionStepKind.carryTargetOutput,
          subject:
              '${byState[transition.from]!.label} --'
              '${transition.input.value}--> ${target.label}',
          detail: target.label,
          output: renderOutputWord(target.output),
        ),
      );
    }
    final dropped = initial.output.values.isEmpty ? null : initial.output;
    if (dropped != null) {
      steps.add(
        TransducerConversionStep(
          kind: TransducerConversionStepKind.dropInitialOutput,
          subject: initial.label,
          output: renderOutputWord(dropped),
        ),
      );
    }
    final machine = MealyMachine(
      id: TransducerMachineId('${moore.id.value}-mealy'),
      name: '${moore.name} (Mealy)',
      revision: const TransducerRevision(0),
      inputAlphabet: moore.inputAlphabet,
      outputAlphabet: moore.outputAlphabet,
      states: states,
      transitions: transitions,
    );
    return TransducerConversionReport(
      machine: machine,
      outcome: dropped == null
          ? TransducerConversionOutcome.exact
          : TransducerConversionOutcome.conventionDifference,
      steps: List.unmodifiable(steps),
      sourceStateCount: moore.states.length,
      sourceTransitionCount: moore.transitions.length,
      droppedInitialOutput: dropped,
    );
  }

  static TransducerConversionFailure<T>? _reject<T extends Object>(
    DeterministicFiniteStateTransducer machine,
  ) {
    final report = TransducerAnalyzer.analyze(machine);
    final blocking = report.diagnostics
        .where(
          (diagnostic) =>
              diagnostic.severity == TransducerDiagnosticSeverity.error ||
              diagnostic.code ==
                  TransducerDiagnosticCode.nondeterministicTransition,
        )
        .toList(growable: false);
    if (!report.isStructurallyValid ||
        !report.isDeterministic ||
        blocking.isNotEmpty) {
      return TransducerConversionFailure<T>(
        blocking.isEmpty ? report.diagnostics : blocking,
      );
    }
    return null;
  }
}
