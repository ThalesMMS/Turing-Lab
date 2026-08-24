//
//  regex_to_nfa_converter.dart
//  Turing Lab
//
//  Converts regular expressions into nondeterministic finite automata
//  using Thompson constructions, validation, and unique identifier
//  generation. Exposes utilities to analyze the expression, create states
//  and transitions, and report detailed errors when the input is invalid.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';
import '../models/algorithm_step.dart';
import '../models/fsa.dart';
import '../models/fsa_transition.dart';
import '../models/regex_to_nfa_step.dart';
import '../models/state.dart';
import '../models/transition.dart';
import '../result.dart';
import 'fsa_concatenator.dart';
import 'fsa_kleene_star.dart';
import 'state_renamer.dart';

part 'regex_to_nfa_converter_parser.dart';
part 'regex_to_nfa_converter_construction.dart';
part 'regex_to_nfa_converter_builders.dart';
part 'regex_to_nfa_converter_models.dart';

/// Converts Regular Expressions to Non-deterministic Finite Automata (NFA)
class RegexToNFAConverter {
  static int _idSeq = 0;
  static String _newStateId(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${_idSeq++}';
  static String _newTransId(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${_idSeq++}';

  /// Parses [regex] with the same syntax contract used by conversion.
  static RegexValidationResult validate(String regex) {
    return _validateRegexSyntax(regex);
  }

  /// Converts a regular expression to an equivalent NFA
  static Result<FSA> convert(String regex, {Set<String>? contextAlphabet}) {
    try {
      // Validate input
      final validationResult = _validateRegex(regex);
      if (!validationResult.isSuccess) {
        return ResultFactory.failure(validationResult.error!);
      }
      final alphabetValidation = _validateContextAlphabet(
        regex,
        contextAlphabet,
      );
      if (!alphabetValidation.isSuccess) {
        return ResultFactory.failure(alphabetValidation.error!);
      }

      // Parse the regular expression
      final parsedRegex = _parseRegex(regex);
      if (parsedRegex == null) {
        return ResultFactory.failure('Invalid regular expression syntax');
      }

      // Convert to NFA using Thompson's construction
      var nfa = _thompsonConstruction(
        parsedRegex,
        contextAlphabet: contextAlphabet,
      );

      // Rename labels to q0, q1, q2... and apply circular layout
      nfa = StateRenamer.renameAndLayout(nfa);

      return ResultFactory.success(nfa);
    } catch (e) {
      return ResultFactory.failure('Error converting regex to NFA: $e');
    }
  }

  /// Converts a regular expression to NFA with step-by-step information
  static Result<RegexToNFAConversionResult> convertWithSteps(
    String regex, {
    Set<String>? contextAlphabet,
  }) {
    try {
      final stopwatch = Stopwatch()..start();
      final steps = <RegexToNFAStep>[];
      int stepCounter = 1;

      // Validate input
      final validationResult = _validateRegex(regex);
      if (!validationResult.isSuccess) {
        return ResultFactory.failure(validationResult.error!);
      }
      final alphabetValidation = _validateContextAlphabet(
        regex,
        contextAlphabet,
      );
      if (!alphabetValidation.isSuccess) {
        return ResultFactory.failure(alphabetValidation.error!);
      }

      // Parse the regular expression
      final parsedRegex = _parseRegex(regex);
      if (parsedRegex == null) {
        return ResultFactory.failure('Invalid regular expression syntax');
      }

      // Add start step
      steps.add(
        RegexToNFAStep.start(
          id: 'step_$stepCounter',
          stepNumber: stepCounter++,
          regex: regex,
        ),
      );

      // Convert to NFA using Thompson's construction with step capture
      var nfa = _thompsonConstructionWithSteps(
        parsedRegex,
        steps,
        stepCounter,
        contextAlphabet: contextAlphabet,
      );
      stepCounter += steps.length - 1;

      // Rename labels to q0, q1, q2... and apply circular layout
      nfa = StateRenamer.renameAndLayout(nfa);

      // Add completion step
      final finalStates = nfa.states.toList();
      final finalTransitions = nfa.fsaTransitions.toList();
      steps.add(
        RegexToNFAStep.complete(
          id: 'step_$stepCounter',
          stepNumber: stepCounter,
          finalStartState: nfa.initialState!,
          finalAcceptState: nfa.acceptingStates.first,
          totalStates: finalStates.length,
          totalTransitions: finalTransitions.length,
        ),
      );

      stopwatch.stop();

      final result = RegexToNFAConversionResult(
        regex: regex,
        resultNFA: nfa,
        steps: steps,
        executionTime: stopwatch.elapsed,
      );

      return ResultFactory.success(result);
    } catch (e) {
      return ResultFactory.failure(
        'Error converting regex to NFA with steps: $e',
      );
    }
  }
}

String _newStateId(String prefix) => RegexToNFAConverter._newStateId(prefix);

String _newTransId(String prefix) => RegexToNFAConverter._newTransId(prefix);
