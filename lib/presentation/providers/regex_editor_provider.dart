import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/messages/structured_message.dart';
import '../../core/algorithms/automaton_simulator.dart';
import '../../core/algorithms/dfa_completer.dart';
import '../../core/algorithms/equivalence_checker.dart';
import '../../core/algorithms/nfa_to_dfa_converter.dart';
import '../../core/algorithms/regex_analyzer.dart';
import '../../core/algorithms/regex_simplifier.dart';
import '../../core/algorithms/regex_to_nfa_converter.dart';
import '../../core/models/fsa.dart';
import '../../core/models/regex_document.dart';
import '../../core/models/regex_analysis.dart';

class RegexEditorOperationResult<T> {
  const RegexEditorOperationResult._({
    required this.isSuccess,
    this.data,
    this.error,
    this.structuredError,
  });

  final bool isSuccess;
  final T? data;
  final String? error;
  final StructuredMessage? structuredError;

  bool get isFailure => !isSuccess;

  factory RegexEditorOperationResult.success([T? data]) {
    return RegexEditorOperationResult._(isSuccess: true, data: data);
  }

  factory RegexEditorOperationResult.failure([String? error]) =>
      RegexEditorOperationResult._(isSuccess: false, error: error);

  factory RegexEditorOperationResult.failureWithStructured(
    String? error,
    StructuredMessage structuredError,
  ) => RegexEditorOperationResult._(
    isSuccess: false,
    error: error,
    structuredError: structuredError,
  );
}

class RegexEditorState {
  static const defaultAlphabet =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 .,!?_-';

  const RegexEditorState({
    this.documentId = 'regex-workspace',
    this.documentName = 'Regular expression',
    this.documentGeneration = 0,
    this.currentRegex = '',
    this.testString = '',
    this.isValid = false,
    this.matches = false,
    this.hasTested = false,
    this.errorMessage = '',
    this.validationDiagnostic,
    this.alphabet = defaultAlphabet,
    this.equivalenceResult,
    this.equivalenceMessage = '',
    this.simplifyOutput = true,
    this.simplificationResult,
    this.showSimplificationSteps = false,
    this.selectedStepIndex = 0,
    this.regexAnalysis,
    this.showAnalysisDetails = false,
    this.sampleStrings,
    this.showSampleStringsDetails = false,
  });

  static const _unset = Object();

  final String documentId;
  final String documentName;
  final int documentGeneration;
  final String currentRegex;
  final String testString;
  final bool isValid;
  final bool matches;
  final bool hasTested;
  final String errorMessage;
  final RegexValidationDiagnostic? validationDiagnostic;
  final String alphabet;
  final bool? equivalenceResult;
  final String equivalenceMessage;
  final bool simplifyOutput;
  final RegexSimplificationResult? simplificationResult;
  final bool showSimplificationSteps;
  final int selectedStepIndex;
  final RegexAnalysis? regexAnalysis;
  final bool showAnalysisDetails;
  final RegexSampleStrings? sampleStrings;
  final bool showSampleStringsDetails;

  bool get canRunRegexOperation =>
      isValid && currentRegex.isNotEmpty && alphabet.isNotEmpty;
  Set<String> get resolvedAlphabet =>
      alphabet.runes.map(String.fromCharCode).toSet();

  RegexEditorState copyWith({
    String? documentId,
    String? documentName,
    int? documentGeneration,
    String? currentRegex,
    String? testString,
    bool? isValid,
    bool? matches,
    bool? hasTested,
    String? errorMessage,
    Object? validationDiagnostic = _unset,
    String? alphabet,
    Object? equivalenceResult = _unset,
    String? equivalenceMessage,
    bool? simplifyOutput,
    Object? simplificationResult = _unset,
    bool? showSimplificationSteps,
    int? selectedStepIndex,
    Object? regexAnalysis = _unset,
    bool? showAnalysisDetails,
    Object? sampleStrings = _unset,
    bool? showSampleStringsDetails,
  }) {
    return RegexEditorState(
      documentId: documentId ?? this.documentId,
      documentName: documentName ?? this.documentName,
      documentGeneration: documentGeneration ?? this.documentGeneration,
      currentRegex: currentRegex ?? this.currentRegex,
      testString: testString ?? this.testString,
      isValid: isValid ?? this.isValid,
      matches: matches ?? this.matches,
      hasTested: hasTested ?? this.hasTested,
      errorMessage: errorMessage ?? this.errorMessage,
      validationDiagnostic: validationDiagnostic == _unset
          ? this.validationDiagnostic
          : validationDiagnostic as RegexValidationDiagnostic?,
      alphabet: alphabet ?? this.alphabet,
      equivalenceResult: equivalenceResult == _unset
          ? this.equivalenceResult
          : equivalenceResult as bool?,
      equivalenceMessage: equivalenceMessage ?? this.equivalenceMessage,
      simplifyOutput: simplifyOutput ?? this.simplifyOutput,
      simplificationResult: simplificationResult == _unset
          ? this.simplificationResult
          : simplificationResult as RegexSimplificationResult?,
      showSimplificationSteps:
          showSimplificationSteps ?? this.showSimplificationSteps,
      selectedStepIndex: selectedStepIndex ?? this.selectedStepIndex,
      regexAnalysis: regexAnalysis == _unset
          ? this.regexAnalysis
          : regexAnalysis as RegexAnalysis?,
      showAnalysisDetails: showAnalysisDetails ?? this.showAnalysisDetails,
      sampleStrings: sampleStrings == _unset
          ? this.sampleStrings
          : sampleStrings as RegexSampleStrings?,
      showSampleStringsDetails:
          showSampleStringsDetails ?? this.showSampleStringsDetails,
    );
  }
}

class RegexEditorNotifier extends StateNotifier<RegexEditorState> {
  RegexEditorNotifier() : super(const RegexEditorState());

  int _testStringMatchVersion = 0;

  void setSimplifyOutput(bool value) {
    state = state.copyWith(simplifyOutput: value);
  }

  void setAlphabet(String value) {
    if (value == state.alphabet) return;
    _testStringMatchVersion++;
    state = state.copyWith(
      alphabet: value,
      documentGeneration: state.documentGeneration + 1,
      matches: false,
      hasTested: false,
      errorMessage: '',
      equivalenceResult: null,
      equivalenceMessage: '',
      simplificationResult: null,
      showSimplificationSteps: false,
      selectedStepIndex: 0,
      regexAnalysis: null,
      showAnalysisDetails: false,
      sampleStrings: null,
      showSampleStringsDetails: false,
    );
  }

  void restorePersistedInput({
    required String currentRegex,
    required String testString,
    required bool simplifyOutput,
    String alphabet = RegexEditorState.defaultAlphabet,
    String documentId = 'regex-workspace',
    String documentName = 'Regular expression',
  }) {
    _testStringMatchVersion++;
    state = RegexEditorState(
      documentId: documentId,
      documentName: documentName,
      testString: testString,
      simplifyOutput: simplifyOutput,
      alphabet: alphabet,
    );

    if (currentRegex.isNotEmpty) {
      validateRegex(currentRegex);
      state = state.copyWith(testString: testString);
    }
  }

  void clearInputs() {
    _testStringMatchVersion++;
    state = RegexEditorState(
      documentId: state.documentId,
      documentName: state.documentName,
      documentGeneration: state.documentGeneration + 1,
      simplifyOutput: state.simplifyOutput,
      alphabet: state.alphabet,
    );
  }

  void validateRegex(String regex) {
    _testStringMatchVersion++;
    final sourceChanged = regex != state.currentRegex;
    final nextState = state.copyWith(
      currentRegex: regex,
      documentGeneration: sourceChanged
          ? state.documentGeneration + 1
          : state.documentGeneration,
      errorMessage: '',
      validationDiagnostic: null,
      hasTested: false,
      matches: sourceChanged ? false : state.matches,
      equivalenceResult: sourceChanged ? null : state.equivalenceResult,
      equivalenceMessage: sourceChanged ? '' : state.equivalenceMessage,
      simplificationResult: sourceChanged ? null : state.simplificationResult,
      showSimplificationSteps: sourceChanged
          ? false
          : state.showSimplificationSteps,
      selectedStepIndex: sourceChanged ? 0 : state.selectedStepIndex,
      regexAnalysis: sourceChanged ? null : state.regexAnalysis,
      showAnalysisDetails: sourceChanged ? false : state.showAnalysisDetails,
      sampleStrings: sourceChanged ? null : state.sampleStrings,
      showSampleStringsDetails: sourceChanged
          ? false
          : state.showSampleStringsDetails,
    );

    if (regex.isEmpty) {
      state = nextState.copyWith(
        isValid: false,
        validationDiagnostic: RegexToNFAConverter.validate(regex).diagnostic,
      );
      return;
    }

    final validation = RegexToNFAConverter.validate(regex);
    final diagnostic = validation.diagnostic;
    state = nextState.copyWith(
      isValid: validation.isValid,
      errorMessage: diagnostic?.displayMessage ?? '',
      validationDiagnostic: diagnostic,
    );
  }

  RegexDocument buildDocument() => RegexDocument(
    id: state.documentId,
    name: state.documentName,
    source: state.currentRegex,
    alphabet: state.alphabet.runes.map(String.fromCharCode),
  );

  void replaceDocument(RegexDocument document) {
    _testStringMatchVersion++;
    state = RegexEditorState(
      documentId: document.id,
      documentName: document.name,
      documentGeneration: state.documentGeneration + 1,
      currentRegex: document.source,
      alphabet: document.alphabet.join(),
      simplifyOutput: state.simplifyOutput,
    );
    if (document.source.isNotEmpty) validateRegex(document.source);
  }

  void restoreDocumentCheckpoint(RegexEditorState checkpoint) {
    _testStringMatchVersion++;
    state = checkpoint;
  }

  Future<void> testStringMatch(String input) async {
    final requestVersion = ++_testStringMatchVersion;
    final canRunRegexOperation = state.canRunRegexOperation;

    if (!canRunRegexOperation) {
      state = state.copyWith(testString: input);
      return;
    }

    state = state.copyWith(
      testString: input,
      matches: false,
      errorMessage: '',
      hasTested: false,
    );

    try {
      final conversionResult = RegexToNFAConverter.convert(
        state.currentRegex,
        contextAlphabet: state.resolvedAlphabet,
      );
      if (!conversionResult.isSuccess || conversionResult.data == null) {
        if (!_isLatestTestStringRequest(requestVersion)) {
          return;
        }
        state = state.copyWith(
          matches: false,
          hasTested: true,
          errorMessage:
              conversionResult.error ?? 'Unable to convert regex to NFA',
        );
        return;
      }

      final simulationResult = await AutomatonSimulator.simulateNFA(
        conversionResult.data!,
        input,
      );

      if (!_isLatestTestStringRequest(requestVersion)) {
        return;
      }

      if (simulationResult.isSuccess && simulationResult.data != null) {
        final result = simulationResult.data!;
        state = state.copyWith(
          matches: result.isAccepted,
          hasTested: true,
          errorMessage: !result.isAccepted && result.errorMessage.isNotEmpty
              ? result.errorMessage
              : state.errorMessage,
        );
      } else {
        state = state.copyWith(
          matches: false,
          hasTested: true,
          errorMessage:
              simulationResult.error ?? 'Failed to simulate automaton',
        );
      }
    } catch (error) {
      if (!_isLatestTestStringRequest(requestVersion)) {
        return;
      }
      state = state.copyWith(
        matches: false,
        hasTested: true,
        errorMessage: 'Error testing string: $error',
      );
    }
  }

  bool _isLatestTestStringRequest(int requestVersion) {
    return requestVersion == _testStringMatchVersion;
  }

  RegexEditorOperationResult<FSA> convertToNfa() {
    if (!state.canRunRegexOperation) {
      return RegexEditorOperationResult<FSA>.failure();
    }

    final result = RegexToNFAConverter.convert(
      state.currentRegex,
      contextAlphabet: state.resolvedAlphabet,
    );
    if (!result.isSuccess || result.data == null) {
      return RegexEditorOperationResult<FSA>.failure(result.error);
    }

    return RegexEditorOperationResult<FSA>.success(result.data!);
  }

  RegexEditorOperationResult<FSA> convertToDfa() {
    if (!state.canRunRegexOperation) {
      return RegexEditorOperationResult<FSA>.failure();
    }

    return _regexToDfa(
      state.currentRegex,
      contextAlphabet: state.resolvedAlphabet,
    );
  }

  void compareRegexEquivalence(String primaryInput, String secondaryInput) {
    final primary = primaryInput.trim();
    final secondary = secondaryInput.trim();

    state = state.copyWith(equivalenceResult: null, equivalenceMessage: '');

    if (primary.isEmpty || secondary.isEmpty) {
      state = state.copyWith(
        equivalenceResult: false,
        equivalenceMessage: 'Enter both regular expressions to compare.',
      );
      return;
    }

    try {
      final firstDfaResult = _regexToDfa(
        primary,
        contextAlphabet: state.resolvedAlphabet,
        nfaFailureMessage: 'Unable to convert first regex to NFA',
        dfaFailureMessage: 'Unable to convert first regex to DFA',
      );
      if (firstDfaResult.isFailure || firstDfaResult.data == null) {
        state = state.copyWith(
          equivalenceResult: false,
          equivalenceMessage:
              firstDfaResult.error ?? 'Unable to convert first regex to DFA',
        );
        return;
      }

      final secondDfaResult = _regexToDfa(
        secondary,
        contextAlphabet: state.resolvedAlphabet,
        nfaFailureMessage: 'Unable to convert second regex to NFA',
        dfaFailureMessage: 'Unable to convert second regex to DFA',
      );
      if (secondDfaResult.isFailure || secondDfaResult.data == null) {
        state = state.copyWith(
          equivalenceResult: false,
          equivalenceMessage:
              secondDfaResult.error ?? 'Unable to convert second regex to DFA',
        );
        return;
      }

      final equivalent = EquivalenceChecker.areEquivalent(
        firstDfaResult.data!,
        secondDfaResult.data!,
      );

      state = state.copyWith(
        equivalenceResult: equivalent,
        equivalenceMessage: equivalent
            ? 'The regular expressions are equivalent.'
            : 'The regular expressions are not equivalent.',
      );
    } catch (error) {
      state = state.copyWith(
        equivalenceResult: false,
        equivalenceMessage: 'Error comparing regular expressions: $error',
      );
    }
  }

  RegexEditorOperationResult<FSA> _regexToDfa(
    String regex, {
    required Set<String> contextAlphabet,
    String nfaFailureMessage = 'Unable to convert regex to NFA',
    String dfaFailureMessage = 'Unable to convert regex to DFA',
  }) {
    final regexToNfaResult = RegexToNFAConverter.convert(
      regex,
      contextAlphabet: contextAlphabet,
    );
    if (!regexToNfaResult.isSuccess || regexToNfaResult.data == null) {
      return RegexEditorOperationResult<FSA>.failure(
        regexToNfaResult.error ?? nfaFailureMessage,
      );
    }

    final nfaToDfaResult = NFAToDFAConverter.convert(regexToNfaResult.data!);
    if (!nfaToDfaResult.isSuccess || nfaToDfaResult.data == null) {
      return RegexEditorOperationResult<FSA>.failure(
        nfaToDfaResult.error ?? dfaFailureMessage,
      );
    }

    return RegexEditorOperationResult<FSA>.success(
      DFACompleter.complete(nfaToDfaResult.data!),
    );
  }

  RegexEditorOperationResult<void> runSimplificationWithSteps() {
    if (!state.canRunRegexOperation) {
      return RegexEditorOperationResult<void>.failure();
    }

    final result = RegexSimplifier.simplifyWithSteps(state.currentRegex);
    if (!result.isSuccess || result.data == null) {
      final structuredError = result.structuredError;
      return structuredError == null
          ? RegexEditorOperationResult<void>.failure(result.error)
          : RegexEditorOperationResult<void>.failureWithStructured(
              result.error,
              structuredError,
            );
    }

    state = state.copyWith(
      simplificationResult: result.data,
      showSimplificationSteps: true,
      selectedStepIndex: 0,
    );
    return RegexEditorOperationResult<void>.success();
  }

  void clearSimplification() {
    state = state.copyWith(
      simplificationResult: null,
      showSimplificationSteps: false,
      selectedStepIndex: 0,
    );
  }

  void toggleSimplificationSteps() {
    state = state.copyWith(
      showSimplificationSteps: !state.showSimplificationSteps,
    );
  }

  void setSelectedStepIndex(int index) {
    final steps = state.simplificationResult?.steps ?? const [];
    if (index < 0 || index >= steps.length) {
      return;
    }
    state = state.copyWith(selectedStepIndex: index);
  }

  RegexEditorOperationResult<void> runComplexityAnalysis() {
    if (!state.canRunRegexOperation) {
      return RegexEditorOperationResult<void>.failure();
    }

    final result = RegexAnalyzer.analyze(
      state.currentRegex,
      contextAlphabet: state.resolvedAlphabet,
    );
    if (!result.isSuccess || result.data == null) {
      return RegexEditorOperationResult<void>.failure(result.error);
    }

    state = state.copyWith(
      regexAnalysis: result.data,
      showAnalysisDetails: true,
    );
    return RegexEditorOperationResult<void>.success();
  }

  void clearComplexityAnalysis() {
    state = state.copyWith(regexAnalysis: null, showAnalysisDetails: false);
  }

  void toggleAnalysisDetails() {
    state = state.copyWith(showAnalysisDetails: !state.showAnalysisDetails);
  }

  RegexEditorOperationResult<void> runSampleGeneration({int maxSamples = 10}) {
    if (!state.canRunRegexOperation) {
      return RegexEditorOperationResult<void>.failure();
    }

    final result = RegexAnalyzer.generateSampleStrings(
      state.currentRegex,
      maxSamples: maxSamples,
      maxLength: 30,
      contextAlphabet: state.resolvedAlphabet,
    );
    if (!result.isSuccess || result.data == null) {
      return RegexEditorOperationResult<void>.failure(result.error);
    }

    state = state.copyWith(
      sampleStrings: result.data,
      showSampleStringsDetails: true,
    );
    return RegexEditorOperationResult<void>.success();
  }

  void clearSampleStrings() {
    state = state.copyWith(
      sampleStrings: null,
      showSampleStringsDetails: false,
    );
  }

  void toggleSampleStringsDetails() {
    state = state.copyWith(
      showSampleStringsDetails: !state.showSampleStringsDetails,
    );
  }
}

final regexEditorProvider =
    StateNotifierProvider<RegexEditorNotifier, RegexEditorState>(
      (ref) => RegexEditorNotifier(),
    );
