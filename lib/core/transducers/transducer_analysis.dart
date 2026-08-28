import '../messages/structured_message.dart';
import 'transducer_ids.dart';
import 'transducer_models.dart';
import 'transducer_symbols.dart';

enum TransducerDiagnosticSeverity { warning, error }

enum TransducerDiagnosticCode {
  missingInitialState,
  multipleInitialStates,
  duplicateStateId,
  duplicateTransitionId,
  danglingSourceState,
  danglingTargetState,
  inputSymbolOutsideAlphabet,
  outputSymbolOutsideAlphabet,
  nondeterministicTransition,
  incompleteTransitionFunction,
  emptyIdentifier,
  emptyInputSymbol,
  emptyOutputSymbol,
  negativeRevision,
}

final class TransducerDiagnostic implements Comparable<TransducerDiagnostic> {
  const TransducerDiagnostic({
    required this.code,
    required this.severity,
    required this.subject,
    this.identifier,
    this.symbol,
    this.count,
    this.integer,
    this.outcome,
  });

  final TransducerDiagnosticCode code;
  final TransducerDiagnosticSeverity severity;
  final String subject;
  final String? identifier;
  final String? symbol;
  final int? count;
  final int? integer;
  final String? outcome;

  StructuredMessage get structuredMessage => StructuredMessage(
    namespace: 'transducer.analysis',
    code: switch (code) {
      TransducerDiagnosticCode.missingInitialState => 'missing-initial-state',
      TransducerDiagnosticCode.multipleInitialStates =>
        'multiple-initial-states',
      TransducerDiagnosticCode.duplicateStateId => 'duplicate-state-id',
      TransducerDiagnosticCode.duplicateTransitionId =>
        'duplicate-transition-id',
      TransducerDiagnosticCode.danglingSourceState => 'dangling-source-state',
      TransducerDiagnosticCode.danglingTargetState => 'dangling-target-state',
      TransducerDiagnosticCode.inputSymbolOutsideAlphabet =>
        'input-symbol-outside-alphabet',
      TransducerDiagnosticCode.outputSymbolOutsideAlphabet =>
        'output-symbol-outside-alphabet',
      TransducerDiagnosticCode.nondeterministicTransition =>
        'nondeterministic-transition',
      TransducerDiagnosticCode.incompleteTransitionFunction =>
        'incomplete-transition-function',
      TransducerDiagnosticCode.emptyIdentifier => 'empty-identifier',
      TransducerDiagnosticCode.emptyInputSymbol => 'empty-input-symbol',
      TransducerDiagnosticCode.emptyOutputSymbol => 'empty-output-symbol',
      TransducerDiagnosticCode.negativeRevision => 'negative-revision',
    },
    category: StructuredMessageCategory.analysis,
    severity: switch (severity) {
      TransducerDiagnosticSeverity.warning => StructuredMessageSeverity.warning,
      TransducerDiagnosticSeverity.error => StructuredMessageSeverity.error,
    },
    arguments: !_hasStructuredArguments
        ? const {}
        : switch (code) {
            TransducerDiagnosticCode.missingInitialState => const {},
            TransducerDiagnosticCode.multipleInitialStates => {
              'count': StructuredMessageArgument.count(count!),
            },
            TransducerDiagnosticCode.duplicateStateId => {
              'state': StructuredMessageArgument.identifier(
                identifier!,
                role: 'state',
              ),
            },
            TransducerDiagnosticCode.duplicateTransitionId ||
            TransducerDiagnosticCode.danglingSourceState ||
            TransducerDiagnosticCode.danglingTargetState => {
              'transition': StructuredMessageArgument.identifier(
                identifier!,
                role: 'transition',
              ),
            },
            TransducerDiagnosticCode.inputSymbolOutsideAlphabet => {
              'transition': StructuredMessageArgument.identifier(
                identifier!,
                role: 'transition',
              ),
              'symbol': StructuredMessageArgument.symbol(
                symbol!,
                role: 'input-symbol',
              ),
            },
            TransducerDiagnosticCode.outputSymbolOutsideAlphabet => {
              'subject': StructuredMessageArgument.identifier(
                subject,
                role: 'output-owner',
              ),
              'symbol': StructuredMessageArgument.symbol(
                symbol!,
                role: 'output-symbol',
              ),
            },
            TransducerDiagnosticCode.emptyInputSymbol ||
            TransducerDiagnosticCode.emptyOutputSymbol => {
              'subject': StructuredMessageArgument.literal(
                subject,
                role: 'diagnostic-subject',
              ),
            },
            TransducerDiagnosticCode.nondeterministicTransition ||
            TransducerDiagnosticCode.incompleteTransitionFunction => {
              'state': StructuredMessageArgument.identifier(
                identifier!,
                role: 'state',
              ),
              'symbol': StructuredMessageArgument.symbol(
                symbol!,
                role: 'input-symbol',
              ),
            },
            TransducerDiagnosticCode.emptyIdentifier => {
              'entity': StructuredMessageArgument.outcome(
                outcome!,
                role: 'entity-kind',
              ),
            },
            TransducerDiagnosticCode.negativeRevision => {
              'revision': StructuredMessageArgument.integer(integer!),
            },
          },
  );

  bool get _hasStructuredArguments => switch (code) {
    TransducerDiagnosticCode.missingInitialState ||
    TransducerDiagnosticCode.emptyInputSymbol ||
    TransducerDiagnosticCode.emptyOutputSymbol => true,
    TransducerDiagnosticCode.multipleInitialStates =>
      count != null && count! >= 0,
    TransducerDiagnosticCode.duplicateStateId ||
    TransducerDiagnosticCode.duplicateTransitionId ||
    TransducerDiagnosticCode.danglingSourceState ||
    TransducerDiagnosticCode.danglingTargetState => identifier != null,
    TransducerDiagnosticCode.inputSymbolOutsideAlphabet ||
    TransducerDiagnosticCode.nondeterministicTransition ||
    TransducerDiagnosticCode.incompleteTransitionFunction =>
      identifier != null && symbol != null,
    TransducerDiagnosticCode.outputSymbolOutsideAlphabet => symbol != null,
    TransducerDiagnosticCode.emptyIdentifier => outcome != null,
    TransducerDiagnosticCode.negativeRevision => integer != null,
  };

  @override
  int compareTo(TransducerDiagnostic other) {
    final byCode = code.index.compareTo(other.code.index);
    return byCode != 0 ? byCode : subject.compareTo(other.subject);
  }
}

final class TransducerAnalysisReport {
  TransducerAnalysisReport({
    required Iterable<TransducerDiagnostic> diagnostics,
    required this.isDeterministic,
    required this.isComplete,
  }) : diagnostics = List<TransducerDiagnostic>.unmodifiable(
         diagnostics.toList()..sort(),
       );

  final List<TransducerDiagnostic> diagnostics;
  final bool isDeterministic;
  final bool isComplete;

  bool get isStructurallyValid => diagnostics.every(
    (diagnostic) => diagnostic.severity != TransducerDiagnosticSeverity.error,
  );
}

abstract final class TransducerAnalyzer {
  static TransducerAnalysisReport analyze(
    DeterministicFiniteStateTransducer machine,
  ) {
    final diagnostics = <TransducerDiagnostic>[];
    if (machine.revision.value < 0) {
      diagnostics.add(
        _error(
          TransducerDiagnosticCode.negativeRevision,
          '${machine.revision.value}',
          integer: machine.revision.value,
        ),
      );
    }
    if (machine.id.value.trim().isEmpty) {
      diagnostics.add(
        _error(
          TransducerDiagnosticCode.emptyIdentifier,
          'machine',
          outcome: 'machine',
        ),
      );
    }
    for (final symbol in machine.inputAlphabet) {
      if (symbol.value.isEmpty) {
        diagnostics.add(
          _error(TransducerDiagnosticCode.emptyInputSymbol, 'alphabet'),
        );
      }
    }
    for (final symbol in machine.outputAlphabet) {
      if (symbol.value.isEmpty) {
        diagnostics.add(
          _error(TransducerDiagnosticCode.emptyOutputSymbol, 'alphabet'),
        );
      }
    }

    final initialStates = machine.states
        .where((state) => state.isInitial)
        .toList();
    if (initialStates.isEmpty) {
      diagnostics.add(
        _error(TransducerDiagnosticCode.missingInitialState, 'machine'),
      );
    } else if (initialStates.length > 1) {
      diagnostics.add(
        _error(
          TransducerDiagnosticCode.multipleInitialStates,
          initialStates.map((state) => state.id.value).join(','),
          count: initialStates.length,
        ),
      );
    }

    final stateCounts = <TransducerStateId, int>{};
    for (final state in machine.states) {
      stateCounts.update(state.id, (count) => count + 1, ifAbsent: () => 1);
      if (state.id.value.trim().isEmpty) {
        diagnostics.add(
          _error(
            TransducerDiagnosticCode.emptyIdentifier,
            'state',
            outcome: 'state',
          ),
        );
      }
      if (state case MooreState(:final output)) {
        _checkOutputAlphabet(diagnostics, machine, output, state.id.value);
      }
    }
    for (final entry in stateCounts.entries.where((entry) => entry.value > 1)) {
      diagnostics.add(
        _error(
          TransducerDiagnosticCode.duplicateStateId,
          entry.key.value,
          identifier: entry.key.value,
        ),
      );
    }

    final transitionCounts = <TransducerTransitionId, int>{};
    final transitionIndex = <(TransducerStateId, TransducerInputSymbol), int>{};
    final stateIds = stateCounts.keys.toSet();
    for (final transition in machine.transitions) {
      transitionCounts.update(
        transition.id,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      final lookupKey = (transition.from, transition.input);
      transitionIndex.update(
        lookupKey,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      if (transition.id.value.trim().isEmpty) {
        diagnostics.add(
          _error(
            TransducerDiagnosticCode.emptyIdentifier,
            'transition',
            outcome: 'transition',
          ),
        );
      }
      if (!stateIds.contains(transition.from)) {
        diagnostics.add(
          _error(
            TransducerDiagnosticCode.danglingSourceState,
            transition.id.value,
            identifier: transition.id.value,
          ),
        );
      }
      if (!stateIds.contains(transition.to)) {
        diagnostics.add(
          _error(
            TransducerDiagnosticCode.danglingTargetState,
            transition.id.value,
            identifier: transition.id.value,
          ),
        );
      }
      if (!machine.inputAlphabet.contains(transition.input)) {
        diagnostics.add(
          _error(
            TransducerDiagnosticCode.inputSymbolOutsideAlphabet,
            transition.id.value,
            identifier: transition.id.value,
            symbol: transition.input.value,
          ),
        );
      }
      if (transition.input.value.isEmpty) {
        diagnostics.add(
          _error(
            TransducerDiagnosticCode.emptyInputSymbol,
            transition.id.value,
          ),
        );
      }
      if (transition case MealyTransition(:final output)) {
        _checkOutputAlphabet(diagnostics, machine, output, transition.id.value);
      }
    }
    for (final entry in transitionCounts.entries.where(
      (entry) => entry.value > 1,
    )) {
      diagnostics.add(
        _error(
          TransducerDiagnosticCode.duplicateTransitionId,
          entry.key.value,
          identifier: entry.key.value,
        ),
      );
    }

    var deterministic = true;
    for (final entry in transitionIndex.entries.where(
      (entry) => entry.value > 1,
    )) {
      deterministic = false;
      diagnostics.add(
        _error(
          TransducerDiagnosticCode.nondeterministicTransition,
          [entry.key.$1.value, entry.key.$2.value].join(':'),
          identifier: entry.key.$1.value,
          symbol: entry.key.$2.value,
        ),
      );
    }

    var complete = true;
    for (final stateId in stateIds) {
      for (final symbol in machine.inputAlphabet) {
        if ((transitionIndex[(stateId, symbol)] ?? 0) != 1) {
          complete = false;
          diagnostics.add(
            TransducerDiagnostic(
              code: TransducerDiagnosticCode.incompleteTransitionFunction,
              severity: TransducerDiagnosticSeverity.warning,
              subject: [stateId.value, symbol.value].join(':'),
              identifier: stateId.value,
              symbol: symbol.value,
            ),
          );
        }
      }
    }
    return TransducerAnalysisReport(
      diagnostics: diagnostics,
      isDeterministic: deterministic,
      isComplete: complete,
    );
  }
}

void _checkOutputAlphabet(
  List<TransducerDiagnostic> diagnostics,
  DeterministicFiniteStateTransducer machine,
  TransducerOutputWord output,
  String subject,
) {
  for (final symbol in output.symbols) {
    if (symbol.value.isEmpty) {
      diagnostics.add(
        _error(TransducerDiagnosticCode.emptyOutputSymbol, subject),
      );
    }
    if (!machine.outputAlphabet.contains(symbol)) {
      diagnostics.add(
        _error(
          TransducerDiagnosticCode.outputSymbolOutsideAlphabet,
          subject,
          symbol: symbol.value,
        ),
      );
    }
  }
}

TransducerDiagnostic _error(
  TransducerDiagnosticCode code,
  String subject, {
  String? identifier,
  String? symbol,
  int? count,
  int? integer,
  String? outcome,
}) => TransducerDiagnostic(
  code: code,
  severity: TransducerDiagnosticSeverity.error,
  subject: subject,
  identifier: identifier,
  symbol: symbol,
  count: count,
  integer: integer,
  outcome: outcome,
);

sealed class TransducerLookupOutcome {
  const TransducerLookupOutcome();
}

final class TransducerTransitionFound extends TransducerLookupOutcome {
  const TransducerTransitionFound(this.transition);

  final TransducerTransition transition;
}

final class TransducerTransitionMissing extends TransducerLookupOutcome {
  const TransducerTransitionMissing();
}

final class TransducerTransitionAmbiguous extends TransducerLookupOutcome {
  TransducerTransitionAmbiguous(Iterable<TransducerTransition> transitions)
    : transitions = List<TransducerTransition>.unmodifiable(
        transitions.toList()
          ..sort((left, right) => left.id.compareTo(right.id)),
      );

  final List<TransducerTransition> transitions;
}

final class TransducerTransitionIndex {
  TransducerTransitionIndex(DeterministicFiniteStateTransducer machine)
    : _entries = _build(machine.transitions);

  final Map<
    TransducerStateId,
    Map<TransducerInputSymbol, List<TransducerTransition>>
  >
  _entries;

  TransducerLookupOutcome lookup(
    TransducerStateId state,
    TransducerInputSymbol input,
  ) {
    final matches = _entries[state]?[input] ?? const [];
    return switch (matches.length) {
      0 => const TransducerTransitionMissing(),
      1 => TransducerTransitionFound(matches.single),
      _ => TransducerTransitionAmbiguous(matches),
    };
  }

  static Map<
    TransducerStateId,
    Map<TransducerInputSymbol, List<TransducerTransition>>
  >
  _build(Iterable<TransducerTransition> transitions) {
    final entries =
        <
          TransducerStateId,
          Map<TransducerInputSymbol, List<TransducerTransition>>
        >{};
    for (final transition in transitions) {
      entries
          .putIfAbsent(transition.from, () => {})
          .putIfAbsent(transition.input, () => [])
          .add(transition);
    }
    return entries;
  }
}
