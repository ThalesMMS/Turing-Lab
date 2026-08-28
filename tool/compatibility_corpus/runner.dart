import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:turing_lab/core/algorithms/automaton_simulator.dart';
import 'package:turing_lab/core/algorithms/regex_to_nfa_converter.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/interoperability/interoperability.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/regex_document.dart';
import 'package:turing_lab/core/transducers/transducers.dart';

import 'catalog.dart';
import 'manifest.dart';

enum CompatibilityCaseStatus { passed, failed, notRun }

enum CompatibilityRunStatus { passed, failed, incomplete }

enum CompatibilityRecognition {
  accepted,
  rejected,
  unknown;

  static CompatibilityRecognition fromResult(bool? value) => switch (value) {
        true => accepted,
        false => rejected,
        null => unknown,
      };
}

final class CompatibilityCaseResult {
  CompatibilityCaseResult({
    required this.testCase,
    required this.status,
    required this.seconds,
    required this.message,
    required this.actualOutcome,
    required this.actualFidelity,
    required Iterable<String> diagnosticCodes,
  }) : diagnosticCodes = List.unmodifiable(diagnosticCodes);

  final CompatibilityCase testCase;
  final CompatibilityCaseStatus status;
  final double seconds;
  final String message;
  final String actualOutcome;
  final String? actualFidelity;
  final List<String> diagnosticCodes;

  Map<String, Object?> toJson() => {
        'id': testCase.id,
        'family': testCase.family,
        'codecId': testCase.codecId,
        'roles': testCase.roles.map((role) => role.name).toList()..sort(),
        'fixture': testCase.fixture,
        'sha256': testCase.sha256,
        'status': status.name,
        'seconds': double.parse(seconds.toStringAsFixed(3)),
        'message': message,
        'expectedOutcome': testCase.expectation.outcome.name,
        'actualOutcome': actualOutcome,
        'expectedFidelity': testCase.expectation.fidelity?.name,
        'actualFidelity': actualFidelity,
        'diagnosticCodes': diagnosticCodes,
        'approvedLosses': [
          for (final entry in testCase.expectation.approvedLosses.entries)
            {'code': entry.key, 'issue': entry.value},
        ],
        'unsupportedCapabilities': testCase.expectation.unsupportedCapabilities,
        'dimensions': {
          for (final entry in testCase.expectation.dimensions.entries)
            entry.key: entry.value.name,
        },
        'oracle': testCase.oracle.toJson(),
        if (testCase.equivalent != null)
          'equivalent': testCase.equivalent!.toJson(),
        'provenance': testCase.provenance.toJson(),
      };
}

final class CompatibilityRunResult {
  CompatibilityRunResult({
    required this.corpusVersion,
    required Iterable<CompatibilityCaseResult> cases,
  }) : cases = List.unmodifiable(cases);

  final String corpusVersion;
  final List<CompatibilityCaseResult> cases;

  CompatibilityRunStatus get status {
    if (cases
        .any((result) => result.status == CompatibilityCaseStatus.failed)) {
      return CompatibilityRunStatus.failed;
    }
    if (cases.any(
      (result) => result.status == CompatibilityCaseStatus.notRun,
    )) {
      return CompatibilityRunStatus.incomplete;
    }
    return CompatibilityRunStatus.passed;
  }

  Map<String, Object?> toJson() => {
        'schemaVersion': 1,
        'corpusVersion': corpusVersion,
        'result': status.name,
        'remotelyVerified': false,
        'cases': cases.map((result) => result.toJson()).toList(),
      };
}

typedef CompatibilityToolProbe = bool Function(String executable);
typedef CompatibilityBeforeCase = Future<void> Function(
  CompatibilityCase testCase,
);

final class CompatibilityCorpusRunner {
  CompatibilityCorpusRunner({
    required this.repositoryRoot,
    required this.catalog,
    this.jobs = 4,
    this.timeout = const Duration(seconds: 10),
    CompatibilityToolProbe? toolProbe,
    CompatibilityBeforeCase? beforeCase,
  })  : toolProbe = toolProbe ?? _defaultToolProbe,
        beforeCase = beforeCase ?? _noOpBeforeCase {
    if (jobs <= 0) throw ArgumentError.value(jobs, 'jobs', 'must be positive');
    if (timeout <= Duration.zero) {
      throw ArgumentError.value(timeout, 'timeout', 'must be positive');
    }
  }

  final Directory repositoryRoot;
  final CompatibilityCodecCatalog catalog;
  final int jobs;
  final Duration timeout;
  final CompatibilityToolProbe toolProbe;
  final CompatibilityBeforeCase beforeCase;

  Future<CompatibilityRunResult> run(
    CompatibilityManifest manifest, {
    String? family,
    String? fixtureId,
  }) async {
    final validationIssues = catalog.validateManifest(manifest);
    if (validationIssues.isNotEmpty) {
      throw FormatException(validationIssues.join('\n'));
    }
    final selected = manifest.cases.where((testCase) {
      return (family == null || testCase.family == family) &&
          (fixtureId == null || testCase.id == fixtureId);
    }).toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    if (selected.isEmpty) {
      throw const FormatException('No compatibility fixtures matched.');
    }

    final results = List<CompatibilityCaseResult?>.filled(
      selected.length,
      null,
    );
    var nextIndex = 0;
    Future<void> worker() async {
      while (true) {
        final index = nextIndex++;
        if (index >= selected.length) return;
        results[index] = await _runWithTimeout(selected[index]);
      }
    }

    await Future.wait([
      for (var index = 0; index < jobs && index < selected.length; index++)
        worker(),
    ]);
    return CompatibilityRunResult(
      corpusVersion: manifest.corpusVersion,
      cases: results.cast<CompatibilityCaseResult>(),
    );
  }

  Future<CompatibilityCaseResult> _runWithTimeout(
    CompatibilityCase testCase,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      return await _runCase(testCase).timeout(timeout);
    } on TimeoutException {
      return CompatibilityCaseResult(
        testCase: testCase,
        status: CompatibilityCaseStatus.failed,
        seconds: stopwatch.elapsedMicroseconds / 1000000,
        message: 'Timed out after ${timeout.inMilliseconds} ms.',
        actualOutcome: 'timeout',
        actualFidelity: null,
        diagnosticCodes: const [],
      );
    } catch (error) {
      return CompatibilityCaseResult(
        testCase: testCase,
        status: CompatibilityCaseStatus.failed,
        seconds: stopwatch.elapsedMicroseconds / 1000000,
        message: error.toString(),
        actualOutcome: 'internalFailure',
        actualFidelity: null,
        diagnosticCodes: const [],
      );
    } finally {
      stopwatch.stop();
    }
  }

  Future<CompatibilityCaseResult> _runCase(
    CompatibilityCase testCase,
  ) async {
    final stopwatch = Stopwatch()..start();
    if (testCase.requiredTool case final tool?) {
      if (!toolProbe(tool)) {
        return CompatibilityCaseResult(
          testCase: testCase,
          status: CompatibilityCaseStatus.notRun,
          seconds: stopwatch.elapsedMicroseconds / 1000000,
          message: 'Required tool $tool is unavailable.',
          actualOutcome: 'notRun',
          actualFidelity: null,
          diagnosticCodes: const [],
        );
      }
    }
    final fixture = File(
      '${repositoryRoot.path}${Platform.pathSeparator}'
      '${testCase.fixture.replaceAll('/', Platform.pathSeparator)}',
    );
    if (!fixture.isSyncFile) {
      return _failure(testCase, stopwatch, 'Fixture does not exist.');
    }
    var bytes = await fixture.readAsBytes();
    final digest = sha256.convert(bytes).toString();
    if (digest != testCase.sha256) {
      return _failure(
        testCase,
        stopwatch,
        'Fixture checksum is stale: expected ${testCase.sha256}, got $digest.',
      );
    }
    await beforeCase(testCase);
    final codec = catalog.codecs[testCase.codecId]!;
    if (testCase.mutation case final mutation?) {
      final mutated = _mutateFixture(mutation, codec, bytes);
      if (mutated case final String error) {
        return _failure(testCase, stopwatch, error);
      }
      bytes = mutated as Uint8List;
    }
    final outcome = codec.decode(
      DocumentPayload(
        bytes: Uint8List.fromList(bytes),
        filename: fixture.uri.pathSegments.last,
        sourcePath: testCase.fixture,
      ),
    );
    return switch (outcome) {
      CodecSuccess<InteroperableDocument<Object>>() =>
        await _success(testCase, stopwatch, codec, outcome),
      CodecMalformed<InteroperableDocument<Object>>() => _typedFailure(
          testCase,
          stopwatch,
          CompatibilityExpectedOutcome.malformed,
          'malformed:${outcome.reason.name}',
          outcome.message,
          outcome.reason.name,
        ),
      CodecUnsupported<InteroperableDocument<Object>>() => _typedFailure(
          testCase,
          stopwatch,
          CompatibilityExpectedOutcome.unsupported,
          'unsupported:${outcome.reason.name}',
          outcome.message,
          outcome.reason.name,
        ),
      CodecResourceLimit<InteroperableDocument<Object>>() => _typedFailure(
          testCase,
          stopwatch,
          CompatibilityExpectedOutcome.resourceLimit,
          'resourceLimit:${outcome.limit.name}',
          'Limit ${outcome.limit.name}: ${outcome.actual}/${outcome.maximum}.',
          outcome.limit.name,
        ),
      CodecAmbiguous<InteroperableDocument<Object>>() => _failure(
          testCase,
          stopwatch,
          'Codec returned an ambiguous outcome.',
          actualOutcome: 'ambiguous',
        ),
      CodecInternalFailure<InteroperableDocument<Object>>() => _failure(
          testCase,
          stopwatch,
          outcome.message,
          actualOutcome: 'internalFailure:${outcome.stage.name}',
        ),
    };
  }

  Object _mutateFixture(
    CompatibilityMutation mutation,
    DocumentCodecCapability<Object> codec,
    List<int> source,
  ) {
    return switch (mutation) {
      CompatibilityMutation.futureSchema => _futureSchema(codec, source),
    };
  }

  Object _futureSchema(
    DocumentCodecCapability<Object> codec,
    List<int> source,
  ) {
    final decoded = codec.decode(
      DocumentPayload(bytes: Uint8List.fromList(source), filename: 'base.json'),
    );
    if (decoded is! CodecSuccess<InteroperableDocument<Object>>) {
      return 'Future-schema mutation could not decode its base fixture.';
    }
    final encoded = codec.encode(decoded.value, filename: 'future.json');
    if (encoded is! CodecSuccess<EncodedDocument>) {
      return 'Future-schema mutation could not canonicalize its base fixture.';
    }
    Object? root;
    try {
      root = jsonDecode(utf8.decode(encoded.value.bytes));
    } catch (_) {
      return 'Future-schema mutation requires JSON output.';
    }
    var changed = 0;
    void mutate(Object? value) {
      if (value is Map) {
        final schema = value['schema'];
        if (schema is Map && schema['version'] is int) {
          schema['version'] = codec.descriptor.schemas.maximum + 1;
          changed++;
        }
        for (final child in value.values) {
          mutate(child);
        }
      } else if (value is List) {
        for (final child in value) {
          mutate(child);
        }
      }
    }

    mutate(root);
    if (changed == 0) return 'Future-schema mutation found no schema version.';
    return Uint8List.fromList(utf8.encode(jsonEncode(root)));
  }

  CompatibilityCaseResult _typedFailure(
    CompatibilityCase testCase,
    Stopwatch stopwatch,
    CompatibilityExpectedOutcome expectedType,
    String actualOutcome,
    String message,
    String detail,
  ) {
    final expectedDetail = testCase.oracle.data['reason'];
    final typeMatches = testCase.expectation.outcome == expectedType;
    final detailMatches = expectedDetail == null || expectedDetail == detail;
    return CompatibilityCaseResult(
      testCase: testCase,
      status: typeMatches && detailMatches
          ? CompatibilityCaseStatus.passed
          : CompatibilityCaseStatus.failed,
      seconds: stopwatch.elapsedMicroseconds / 1000000,
      message: typeMatches && detailMatches
          ? message
          : 'Expected ${testCase.expectation.outcome.name}'
              '${expectedDetail == null ? '' : ':$expectedDetail'}, got '
              '$actualOutcome.',
      actualOutcome: actualOutcome,
      actualFidelity: null,
      diagnosticCodes: const [],
    );
  }

  Future<CompatibilityCaseResult> _success(
    CompatibilityCase testCase,
    Stopwatch stopwatch,
    DocumentCodecCapability<Object> codec,
    CodecSuccess<InteroperableDocument<Object>> decoded,
  ) async {
    if (testCase.expectation.outcome != CompatibilityExpectedOutcome.success) {
      return _failure(
        testCase,
        stopwatch,
        'Expected ${testCase.expectation.outcome.name}, got success.',
        actualOutcome: 'success',
        actualFidelity: decoded.fidelity.name,
      );
    }
    final diagnostics = <CodecDiagnostic>[...decoded.diagnostics];
    final roundTrip = _roundTrip(
      codec,
      decoded.value,
      diagnostics,
      decoded.fidelity,
    );
    final actualFidelity = roundTrip.fidelity;
    if (roundTrip.error != null) {
      return _failure(
        testCase,
        stopwatch,
        roundTrip.error!,
        actualOutcome: 'success',
        actualFidelity: actualFidelity.name,
        diagnosticCodes: _diagnosticCodes(diagnostics),
      );
    }
    if (actualFidelity != testCase.expectation.fidelity) {
      return _failure(
        testCase,
        stopwatch,
        'Fidelity regression: expected '
        '${testCase.expectation.fidelity!.name}, got ${actualFidelity.name}.',
        actualOutcome: 'success',
        actualFidelity: actualFidelity.name,
        diagnosticCodes: _diagnosticCodes(diagnostics),
      );
    }
    final actualCodes = _diagnosticCodes(diagnostics);
    final expectedCodes = testCase.expectation.diagnosticCodes.toList()..sort();
    if (!_sameStrings(actualCodes, expectedCodes)) {
      return _failure(
        testCase,
        stopwatch,
        'Diagnostic regression: expected ${expectedCodes.join(', ')}, got '
        '${actualCodes.join(', ')}.',
        actualOutcome: 'success',
        actualFidelity: actualFidelity.name,
        diagnosticCodes: actualCodes,
      );
    }
    final droppedCodes = diagnostics
        .where(
          (diagnostic) =>
              diagnostic.disposition == CodecDiagnosticDisposition.dropped,
        )
        .map((diagnostic) => diagnostic.code)
        .toSet();
    final unapproved = droppedCodes.difference(
      testCase.expectation.approvedLosses.keys.toSet(),
    );
    final staleApprovals = testCase.expectation.approvedLosses.keys
        .toSet()
        .difference(actualCodes.toSet());
    if (unapproved.isNotEmpty || staleApprovals.isNotEmpty) {
      return _failure(
        testCase,
        stopwatch,
        'Loss approval mismatch: unapproved=${unapproved.join(', ')}, '
        'stale=${staleApprovals.join(', ')}.',
        actualOutcome: 'success',
        actualFidelity: actualFidelity.name,
        diagnosticCodes: actualCodes,
      );
    }
    final oracleError =
        await _runOracle(testCase.oracle, decoded.value.document);
    if (oracleError != null) {
      return _failure(
        testCase,
        stopwatch,
        oracleError,
        actualOutcome: 'success',
        actualFidelity: actualFidelity.name,
        diagnosticCodes: actualCodes,
      );
    }
    final equivalentError = await _validateEquivalent(testCase);
    if (equivalentError != null) {
      return _failure(
        testCase,
        stopwatch,
        equivalentError,
        actualOutcome: 'success',
        actualFidelity: actualFidelity.name,
        diagnosticCodes: actualCodes,
      );
    }
    return CompatibilityCaseResult(
      testCase: testCase,
      status: CompatibilityCaseStatus.passed,
      seconds: stopwatch.elapsedMicroseconds / 1000000,
      message: testCase.equivalent == null
          ? 'Decoded, validated, exported, and reimported.'
          : 'Decoded, round-tripped, and matched the cross-format oracle.',
      actualOutcome: 'success',
      actualFidelity: actualFidelity.name,
      diagnosticCodes: actualCodes,
    );
  }

  Future<String?> _validateEquivalent(CompatibilityCase testCase) async {
    final equivalent = testCase.equivalent;
    if (equivalent == null) return null;
    final fixture = File(
      '${repositoryRoot.path}${Platform.pathSeparator}'
      '${equivalent.fixture.replaceAll('/', Platform.pathSeparator)}',
    );
    if (!fixture.isSyncFile) return 'Equivalent fixture does not exist.';
    final bytes = await fixture.readAsBytes();
    final digest = sha256.convert(bytes).toString();
    if (digest != equivalent.sha256) {
      return 'Equivalent fixture checksum is stale: expected '
          '${equivalent.sha256}, got $digest.';
    }
    final codec = catalog.codecs[equivalent.codecId]!;
    final outcome = codec.decode(
      DocumentPayload(
        bytes: Uint8List.fromList(bytes),
        filename: fixture.uri.pathSegments.last,
        sourcePath: equivalent.fixture,
      ),
    );
    if (outcome is! CodecSuccess<InteroperableDocument<Object>>) {
      return 'Equivalent fixture failed to decode: ${outcome.runtimeType}.';
    }
    final oracleError = await _runOracle(
      testCase.oracle,
      outcome.value.document,
    );
    if (oracleError != null) {
      return 'Cross-format semantic mismatch: $oracleError';
    }
    return null;
  }

  _CompatibilityRoundTripResult _roundTrip(
    DocumentCodecCapability<Object> codec,
    InteroperableDocument<Object> document,
    List<CodecDiagnostic> diagnostics,
    DocumentFidelity initialFidelity,
  ) {
    var fidelity = initialFidelity;
    void includeFidelity(DocumentFidelity candidate) {
      if (candidate.index > fidelity.index) fidelity = candidate;
    }

    if (!codec.descriptor.directions
        .contains(DocumentFormatDirection.exportDocument)) {
      return _CompatibilityRoundTripResult(fidelity: fidelity);
    }
    final first = codec.encode(document);
    if (first is! CodecSuccess<EncodedDocument>) {
      return _CompatibilityRoundTripResult(
        fidelity: fidelity,
        error:
            'Export failed during round-trip: ${_outcomeDescription(first)}.',
      );
    }
    includeFidelity(first.fidelity);
    diagnostics.addAll(first.diagnostics);
    final second = codec.decode(
      DocumentPayload(bytes: first.value.bytes, filename: first.value.filename),
    );
    if (second is! CodecSuccess<InteroperableDocument<Object>>) {
      return _CompatibilityRoundTripResult(
        fidelity: fidelity,
        error: 'Reimport failed during round-trip: '
            '${_outcomeDescription(second)}.',
      );
    }
    includeFidelity(second.fidelity);
    diagnostics.addAll(second.diagnostics);
    final third = codec.encode(second.value);
    if (third is! CodecSuccess<EncodedDocument>) {
      return _CompatibilityRoundTripResult(
        fidelity: fidelity,
        error: 'Second export failed during round-trip: '
            '${_outcomeDescription(third)}.',
      );
    }
    includeFidelity(third.fidelity);
    diagnostics.addAll(third.diagnostics);
    if (!_sameBytes(first.value.bytes, third.value.bytes)) {
      return _CompatibilityRoundTripResult(
        fidelity: fidelity,
        error: 'Normalized export bytes are not deterministic.',
      );
    }
    return _CompatibilityRoundTripResult(fidelity: fidelity);
  }

  Future<String?> _runOracle(
    CompatibilityOracle oracle,
    Object document,
  ) async {
    return switch (oracle.kind) {
      CompatibilityOracleKind.outcome =>
        'Success cases cannot use the outcome oracle.',
      CompatibilityOracleKind.roundTrip => null,
      CompatibilityOracleKind.modelFacts => _modelFacts(oracle.data, document),
      CompatibilityOracleKind.fsaAcceptance =>
        await _fsaAcceptance(oracle.data, document),
      CompatibilityOracleKind.regexAcceptance =>
        await _regexAcceptance(oracle.data, document),
      CompatibilityOracleKind.mealyOutput =>
        _transducerOutput(oracle.data, document, isMoore: false),
      CompatibilityOracleKind.mooreOutput =>
        _transducerOutput(oracle.data, document, isMoore: true),
    };
  }

  String? _modelFacts(Map<String, Object?> data, Object document) {
    final facts = data['facts'];
    if (facts is! Map) return 'modelFacts oracle requires a facts object.';
    Object? json;
    try {
      json = (document as dynamic).toJson();
    } catch (_) {
      return '${document.runtimeType} does not expose canonical JSON facts.';
    }
    for (final entry in facts.entries) {
      if (entry.key is! String) return 'Model fact paths must be strings.';
      final actual = _jsonPointer(json, entry.key as String);
      if (!_jsonEqual(actual, entry.value)) {
        return 'Model fact ${entry.key} expected ${entry.value}, got $actual.';
      }
    }
    return null;
  }

  Future<String?> _fsaAcceptance(
    Map<String, Object?> data,
    Object document,
  ) async {
    if (document is! FSA) return 'fsaAcceptance requires an FSA document.';
    return _acceptanceSamples(data, (input) async {
      final result = await AutomatonSimulator.simulateNFA(document, input);
      return result.data?.isAccepted;
    });
  }

  Future<String?> _regexAcceptance(
    Map<String, Object?> data,
    Object document,
  ) async {
    if (document is! RegexDocument) {
      return 'regexAcceptance requires a Regex document.';
    }
    final conversion = RegexToNFAConverter.convert(
      document.source,
      contextAlphabet: document.alphabet.toSet(),
    );
    if (!conversion.isSuccess) {
      return 'Regex oracle conversion failed: ${conversion.error}.';
    }
    return _acceptanceSamples(data, (input) async {
      final result = await AutomatonSimulator.simulateNFA(
        conversion.data!,
        input,
      );
      return result.data?.isAccepted;
    });
  }

  Future<String?> _acceptanceSamples(
    Map<String, Object?> data,
    Future<bool?> Function(String input) simulate,
  ) async {
    final expectations = <String, CompatibilityRecognition>{};
    for (final entry in const {
      'accepted': CompatibilityRecognition.accepted,
      'rejected': CompatibilityRecognition.rejected,
      'unknown': CompatibilityRecognition.unknown,
    }.entries) {
      final samples = data[entry.key];
      if (samples is! List || samples.any((value) => value is! String)) {
        return 'Acceptance oracle requires a ${entry.key} string array.';
      }
      for (final sample in samples.cast<String>()) {
        if (expectations.containsKey(sample)) {
          return 'Acceptance oracle repeats sample "$sample".';
        }
        expectations[sample] = entry.value;
      }
    }
    for (final entry in expectations.entries) {
      final actual = CompatibilityRecognition.fromResult(
        await simulate(entry.key),
      );
      if (actual != entry.value) {
        return 'Input "${entry.key}" expected ${entry.value.name}, got '
            '${actual.name}.';
      }
    }
    return null;
  }

  String? _transducerOutput(
    Map<String, Object?> data,
    Object document, {
    required bool isMoore,
  }) {
    if ((!isMoore && document is! MealyMachine) ||
        (isMoore && document is! MooreMachine)) {
      return '${isMoore ? 'mooreOutput' : 'mealyOutput'} requires the matching '
          'transducer document.';
    }
    final samples = data['samples'];
    if (samples is! List) return 'Transducer oracle requires samples.';
    for (var index = 0; index < samples.length; index++) {
      final raw = samples[index];
      if (raw is! Map) return 'Transducer sample $index must be an object.';
      final sample = Map<String, Object?>.from(raw);
      final input = sample['input'];
      final output = sample['output'];
      final status = sample['status'] ?? 'success';
      if (input is! String ||
          output is! List ||
          output.any((value) => value is! String) ||
          status is! String) {
        return 'Transducer sample $index is malformed.';
      }
      final outcome = isMoore
          ? DeterministicTransducerSimulator.moore(document as MooreMachine)
              .runRaw(input)
          : DeterministicTransducerSimulator.mealy(document as MealyMachine)
              .runRaw(input);
      final actualStatus = switch (outcome) {
        TransducerSuccess() => 'success',
        TransducerIncomplete() => 'incomplete',
        TransducerBounded() => 'unknown',
        TransducerCancelled() => 'unknown',
        TransducerInvalidInput() => 'invalidInput',
        TransducerInvalidMachine() => 'invalidMachine',
      };
      if (actualStatus != status ||
          !_sameStrings(outcome.output.values, output.cast<String>())) {
        return 'Transducer sample "$input" expected $status/$output, got '
            '$actualStatus/${outcome.output.values}.';
      }
    }
    return null;
  }

  CompatibilityCaseResult _failure(
    CompatibilityCase testCase,
    Stopwatch stopwatch,
    String message, {
    String actualOutcome = 'failure',
    String? actualFidelity,
    Iterable<String> diagnosticCodes = const [],
  }) =>
      CompatibilityCaseResult(
        testCase: testCase,
        status: CompatibilityCaseStatus.failed,
        seconds: stopwatch.elapsedMicroseconds / 1000000,
        message: message,
        actualOutcome: actualOutcome,
        actualFidelity: actualFidelity,
        diagnosticCodes: diagnosticCodes,
      );
}

final class _CompatibilityRoundTripResult {
  const _CompatibilityRoundTripResult({required this.fidelity, this.error});

  final DocumentFidelity fidelity;
  final String? error;
}

Future<void> _noOpBeforeCase(CompatibilityCase _) async {}

bool _defaultToolProbe(String executable) {
  final result = Process.runSync(
    Platform.isWindows ? 'where.exe' : 'which',
    [executable],
    runInShell: false,
  );
  return result.exitCode == 0;
}

List<String> _diagnosticCodes(Iterable<CodecDiagnostic> diagnostics) =>
    diagnostics.map((diagnostic) => diagnostic.code).toSet().toList()..sort();

bool _sameBytes(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

bool _sameStrings(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

Object? _jsonPointer(Object? root, String pointer) {
  if (pointer.isEmpty) return root;
  if (!pointer.startsWith('/')) return null;
  Object? current = root;
  for (final raw in pointer.substring(1).split('/')) {
    final segment = raw.replaceAll('~1', '/').replaceAll('~0', '~');
    if (segment == '#') {
      if (current is List || current is Map) {
        current = (current as dynamic).length;
        continue;
      }
      return null;
    }
    if (current is Map) {
      current = current[segment];
      continue;
    }
    if (current is List) {
      final index = int.tryParse(segment);
      if (index == null || index < 0 || index >= current.length) return null;
      current = current[index];
      continue;
    }
    return null;
  }
  return current;
}

bool _jsonEqual(Object? left, Object? right) =>
    jsonEncode(_canonicalJson(left)) == jsonEncode(_canonicalJson(right));

Object? _canonicalJson(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((key) => key.toString()).toList()..sort();
    return {for (final key in keys) key: _canonicalJson(value[key])};
  }
  if (value is Iterable) return value.map(_canonicalJson).toList();
  return value;
}

String _outcomeDescription(CodecOutcome<Object?> outcome) => switch (outcome) {
      CodecMalformed(:final reason, :final message) =>
        'malformed:${reason.name} ($message)',
      CodecUnsupported(:final reason, :final message) =>
        'unsupported:${reason.name} ($message)',
      CodecResourceLimit(:final limit) => 'resourceLimit:${limit.name}',
      CodecAmbiguous(:final codecIds) =>
        'ambiguous:${codecIds.map((id) => id.value).join(',')}',
      CodecInternalFailure(:final stage, :final message) =>
        'internalFailure:${stage.name} ($message)',
      CodecSuccess() => 'success',
    };

extension on File {
  bool get isSyncFile => existsSync() && FileSystemEntity.isFileSync(path);
}
