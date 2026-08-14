//
//  fsa_determinizer.dart
//  Turing Lab
//
//  Shared helper for callers that need deterministic automata before running
//  finite-automata algorithms.
//
import '../models/fsa.dart';
import '../result.dart';
import 'nfa_to_dfa_converter.dart';

class FSADeterminizer {
  static Result<FSA> determinizeIfNeeded(FSA automaton, String label) {
    if (automaton.isDeterministic) {
      return ResultFactory.success(automaton);
    }

    final conversion = NFAToDFAConverter.convert(automaton);
    if (conversion.isFailure || conversion.data == null) {
      return ResultFactory.failure(
        'Failed to determinize automaton $label: '
        '${conversion.error ?? 'unknown conversion failure'}',
      );
    }

    return ResultFactory.success(conversion.data!);
  }
}
