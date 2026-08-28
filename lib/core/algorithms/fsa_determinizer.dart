//
//  fsa_determinizer.dart
//  Turing Lab
//
//  Shared helper for callers that need deterministic automata before running
//  finite-automata algorithms.
//
import '../models/fsa.dart';
import '../result.dart';
import 'fsa_determinizer_messages.dart';
import 'nfa_to_dfa_converter.dart';

class FSADeterminizer {
  static Result<FSA> determinizeIfNeeded(FSA automaton, String label) {
    if (automaton.isDeterministic) {
      return ResultFactory.success(automaton);
    }

    final conversion = NFAToDFAConverter.convert(automaton);
    if (conversion.isFailure || conversion.data == null) {
      final message = FsaDeterminizerMessages.failed(label);
      return Failure(message.stableCode, structuredMessage: message);
    }

    return ResultFactory.success(conversion.data!);
  }
}
