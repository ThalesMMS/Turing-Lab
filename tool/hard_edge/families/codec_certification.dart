import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/interoperability/interoperability.dart';

import '../../compatibility_corpus/catalog.dart';
import '../../compatibility_corpus/manifest.dart';
import '../../compatibility_corpus/runner.dart';
import 'codec_family.dart';
import 'codec_matrix.dart';

enum CodecCertificationStatus { passed, failed, inconclusive }

final class CodecCertificationCheck {
  const CodecCertificationCheck({
    required this.codecId,
    required this.property,
    required this.status,
    required this.message,
    required this.fidelityCoverage,
  });

  final String codecId;
  final String property;
  final CodecCertificationStatus status;
  final String message;
  final Set<String> fidelityCoverage;

  String get failureSignature => '$codecId::$property::$message';

  Map<String, Object?> toJson() => {
        'codecId': codecId,
        'fidelityCoverage': fidelityCoverage.toList()..sort(),
        'message': message,
        'property': property,
        'status': status.name,
      };
}

final class CodecCertificationReport {
  CodecCertificationReport({
    required Iterable<CodecCertificationCheck> checks,
    required Iterable<CodecBoundaryEvidence> boundaryEvidence,
    required this.seed,
  })  : checks = List.unmodifiable(checks),
        boundaryEvidence = List.unmodifiable(boundaryEvidence);

  final List<CodecCertificationCheck> checks;
  final List<CodecBoundaryEvidence> boundaryEvidence;
  final int seed;

  bool get passed =>
      checks.every(
        (check) => check.status == CodecCertificationStatus.passed,
      ) &&
      boundaryEvidence.every((evidence) => evidence.passed);

  Map<String, Object?> toJson() => {
        'checks': checks.map((check) => check.toJson()).toList(),
        'boundaryEvidence':
            boundaryEvidence.map((evidence) => evidence.toJson()).toList(),
        'codecCount': codecIds.length,
        'mutationThreshold': codecMutationKillThreshold,
        'passed': passed,
        'remotelyVerified': false,
        'seed': seed,
      };
}

final class CodecBoundaryEvidence {
  const CodecBoundaryEvidence({
    required this.id,
    required this.entryPoints,
    required this.command,
    required this.exitCode,
    required this.output,
    required this.outcome,
  });

  final String id;
  final List<String> entryPoints;
  final String command;
  final int exitCode;
  final String output;
  final CodecBoundaryProcessOutcome outcome;

  bool get passed => outcome == CodecBoundaryProcessOutcome.passed;

  Map<String, Object?> toJson() => {
        'command': command,
        'entryPoints': entryPoints,
        'exitCode': exitCode,
        'id': id,
        'output': output,
        'status': outcome.name,
      };
}

enum CodecBoundaryProcessOutcome { passed, failed, timedOut, cancelled }

final class CodecBoundaryProcessResult {
  const CodecBoundaryProcessResult({
    required this.exitCode,
    required this.output,
    required this.outcome,
  });

  final int exitCode;
  final String output;
  final CodecBoundaryProcessOutcome outcome;
}

final class CodecCertificationRunner {
  CodecCertificationRunner({Directory? repositoryRoot})
      : repositoryRoot = repositoryRoot ?? Directory.current,
        catalog = CompatibilityCodecCatalog.create();

  final Directory repositoryRoot;
  final CompatibilityCodecCatalog catalog;

  late final CompatibilityManifest manifest = CompatibilityManifest.parse(
    File(_path('test/fixtures/compatibility/manifest.v1.json'))
        .readAsStringSync(),
  );

  Future<CodecCertificationReport> run({
    int seed = 340,
    bool includeBoundaryEvidence = true,
  }) async {
    final checks = <CodecCertificationCheck>[];
    for (final descriptor in codecHardEdgeCaseDescriptors) {
      checks.add(
        await runProperty(
          materializeCodecPropertyFixture(
            codecId: descriptor.algorithm,
            property: descriptor.property,
            seed: seed,
            repositoryRoot: repositoryRoot,
          ),
        ),
      );
    }
    return CodecCertificationReport(
      checks: checks,
      boundaryEvidence:
          includeBoundaryEvidence ? await runBoundaryEvidence() : const [],
      seed: seed,
    );
  }

  Future<List<CodecBoundaryEvidence>> runBoundaryEvidence({
    Duration timeoutPerBoundary = const Duration(seconds: 75),
    bool Function()? isCancelled,
  }) async {
    final boundaries = codecBoundaryInventory
        .where(
          (entry) => entry.id != 'typed-codec-registry',
        )
        .toList();
    final evidence = <CodecBoundaryEvidence>[];
    for (final boundary in boundaries) {
      final parts = boundary.evidenceCommand.split(' ');
      if (parts.length < 3 || parts[0] != 'flutter' || parts[1] != 'test') {
        throw StateError(
          'Boundary ${boundary.id} has a non-test evidence command.',
        );
      }
      final executable = Platform.isWindows ? 'cmd.exe' : 'flutter';
      final arguments = Platform.isWindows
          ? ['/d', '/s', '/c', 'flutter', 'test', ...parts.skip(2)]
          : ['test', ...parts.skip(2)];
      CodecBoundaryProcessResult result;
      try {
        result = await runCodecBoundaryProcessForCertification(
          executable: executable,
          arguments: arguments,
          timeout: timeoutPerBoundary,
          isCancelled: isCancelled,
          workingDirectory: repositoryRoot,
        );
      } on ProcessException catch (error) {
        result = CodecBoundaryProcessResult(
          exitCode: 127,
          output: error.toString(),
          outcome: CodecBoundaryProcessOutcome.failed,
        );
      }
      evidence.add(
        CodecBoundaryEvidence(
          id: boundary.id,
          entryPoints: List.unmodifiable(boundary.entryPoints),
          command: boundary.evidenceCommand,
          exitCode: result.exitCode,
          output: result.output,
          outcome: result.outcome,
        ),
      );
      if (result.outcome == CodecBoundaryProcessOutcome.cancelled) break;
    }
    return List.unmodifiable(evidence);
  }

  Future<CodecCertificationCheck> runProperty(
    CodecHardEdgeFixture fixture, {
    String? mutationOperatorId,
  }) async {
    final codec = catalog.codecs[fixture.codecId];
    if (codec == null) {
      return _failed(fixture, 'Codec is absent from the runtime registry.');
    }
    try {
      return switch (fixture.property) {
        'corpus-fidelity' => await _corpusFidelity(fixture, mutationOperatorId),
        'adversarial-security' => _adversarialSecurity(fixture, codec),
        'transport-parity' =>
          _transportParity(fixture, codec, mutationOperatorId),
        'migration-extensions' =>
          _migrationExtensions(fixture, codec, mutationOperatorId),
        _ => _failed(fixture, 'Unknown certification property.'),
      };
    } on Object catch (error) {
      return _failed(fixture, 'Certification threw: $error');
    }
  }

  Future<CodecCertificationCheck> _corpusFidelity(
    CodecHardEdgeFixture fixture,
    String? mutationOperatorId,
  ) async {
    final selected = manifest.cases
        .where((testCase) => testCase.codecId == fixture.codecId)
        .toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    if (selected.isEmpty) {
      return _failed(fixture, 'No compatibility corpus vectors exist.');
    }
    final offset = _fixtureInt(fixture, 'caseOffset') % selected.length;
    final ordered = [
      ...selected.skip(offset),
      ...selected.take(offset),
    ];
    final runner = CompatibilityCorpusRunner(
      repositoryRoot: repositoryRoot,
      catalog: catalog,
      jobs: 1,
    );
    final fidelities = <String>{};
    for (final testCase in ordered) {
      final result = await runner.run(manifest, fixtureId: testCase.id);
      final item = result.cases.single;
      if (item.status != CompatibilityCaseStatus.passed) {
        return _failed(
          fixture,
          '${testCase.id}: ${item.message}',
          fidelityCoverage: fidelities,
        );
      }
      var observedFidelity = item.actualFidelity;
      if (mutationOperatorId == codecEscalateFidelityMutationId) {
        final source = File(_path(testCase.fixture));
        final decoded = _decodeThroughMutationAdapter(
          catalog.codecs[fixture.codecId]!,
          DocumentPayload(
            bytes: source.readAsBytesSync(),
            filename: source.uri.pathSegments.last,
            sourcePath: testCase.fixture,
          ),
          mutationOperatorId,
        );
        if (decoded is CodecSuccess<InteroperableDocument<Object>>) {
          observedFidelity = decoded.fidelity.name;
        }
      }
      final expectedFidelity = testCase.expectation.fidelity?.name;
      if (expectedFidelity != null && observedFidelity != expectedFidelity) {
        return _failed(
          fixture,
          '${testCase.id}: expected fidelity $expectedFidelity, '
          'got $observedFidelity.',
          fidelityCoverage: fidelities,
        );
      }
      if (observedFidelity case final fidelity?) fidelities.add(fidelity);
    }
    return _passed(
      fixture,
      '${selected.length} approved corpus vectors passed.',
      fidelityCoverage: fidelities,
    );
  }

  CodecCertificationCheck _adversarialSecurity(
    CodecHardEdgeFixture fixture,
    DocumentCodecCapability<Object> codec,
  ) {
    final wrongFilename =
        _fixtureString(fixture, 'wrongFilename', fallback: 'wrong.extension');
    final marker =
        _fixtureString(fixture, 'malformedMarker', fallback: 'hard-edge');
    final canonical = _canonicalPayload(
      codec,
      fixture: fixture,
      filename: wrongFilename,
    );
    final canonicalOutcome = codec.decode(canonical);
    if (canonicalOutcome is! CodecSuccess<InteroperableDocument<Object>>) {
      return _failed(
        fixture,
        'A wrong extension over canonical content changed decode semantics.',
      );
    }

    final malformedInputs = <DocumentPayload>[
      DocumentPayload(bytes: Uint8List(0), filename: 'empty.data'),
      DocumentPayload(
        bytes: Uint8List.fromList(
          utf8.encode(_isJson(codec) ? '{"$marker":' : '<$marker'),
        ),
        filename: _isJson(codec) ? 'truncated.json' : 'truncated.jff',
      ),
    ];
    for (final payload in malformedInputs) {
      final outcome = codec.decode(payload);
      if (outcome is CodecSuccess<InteroperableDocument<Object>> ||
          outcome is CodecInternalFailure<InteroperableDocument<Object>>) {
        return _failed(
          fixture,
          'Malformed input produced ${outcome.runtimeType}.',
        );
      }
    }

    if (_isJson(codec)) {
      final depth = codec.descriptor.securityLimits.maximumDepth +
          _fixtureInt(fixture, 'depthExcess', fallback: 1);
      final source = '${'[' * depth}0${']' * depth}';
      final outcome = codec.decode(
        DocumentPayload(
          bytes: Uint8List.fromList(utf8.encode(source)),
          filename: 'deep.json',
        ),
      );
      if (outcome is! CodecResourceLimit<InteroperableDocument<Object>> ||
          outcome.limit != CodecResourceLimitKind.jsonDepth) {
        return _failed(fixture, 'Deep JSON did not report jsonDepth.');
      }
      final entries = codec.descriptor.securityLimits.maximumCollectionEntries;
      final wide = jsonEncode({
        marker: List<int>.filled(
          entries + _fixtureInt(fixture, 'collectionExcess', fallback: 1),
          0,
        ),
      });
      final wideOutcome = codec.decode(
        DocumentPayload(
          bytes: Uint8List.fromList(utf8.encode(wide)),
          filename: 'wide.json',
        ),
      );
      if (wideOutcome is! CodecResourceLimit<InteroperableDocument<Object>> ||
          wideOutcome.limit != CodecResourceLimitKind.collectionEntries) {
        return _failed(
          fixture,
          'Wide JSON did not report collectionEntries.',
        );
      }
    } else {
      final outcome = codec.decode(
        DocumentPayload(
          bytes: Uint8List.fromList(
            utf8.encode(
              '<!DOCTYPE x [<!ENTITY e "$marker">]><x>&e;</x>',
            ),
          ),
          filename: 'xxe.jff',
        ),
      );
      if (outcome is! CodecResourceLimit<InteroperableDocument<Object>> ||
          outcome.limit != CodecResourceLimitKind.xmlDtdOrEntity) {
        return _failed(fixture, 'DTD/entity input was not rejected by policy.');
      }
    }
    return _passed(
      fixture,
      'Malformed, truncated, wrong-extension, and resource attacks were typed.',
    );
  }

  CodecCertificationCheck _transportParity(
    CodecHardEdgeFixture fixture,
    DocumentCodecCapability<Object> codec,
    String? mutationOperatorId,
  ) {
    final payload = _canonicalPayload(codec, fixture: fixture);
    var transportedBytes = Uint8List.fromList(payload.bytes);
    final copyCount = _fixtureInt(fixture, 'copyCount', fallback: 1);
    for (var copy = 0; copy < copyCount; copy++) {
      transportedBytes = Uint8List.fromList(
        base64Decode(base64Encode(transportedBytes)),
      );
    }
    if (mutationOperatorId == codecCorruptTransportCopyMutationId &&
        transportedBytes.isNotEmpty) {
      transportedBytes = Uint8List.sublistView(
        transportedBytes,
        0,
        transportedBytes.length - 1,
      );
    }
    final transported = DocumentPayload(
      bytes: transportedBytes,
      filename: payload.filename,
      mimeType: payload.mimeType,
    );
    final left = codec.decode(payload);
    final right = codec.decode(transported);
    if (left is! CodecSuccess<InteroperableDocument<Object>> ||
        right is! CodecSuccess<InteroperableDocument<Object>> ||
        left.fidelity != right.fidelity ||
        !_sameDocument(left.value, right.value)) {
      return _failed(fixture, 'Base64 transport changed decode semantics.');
    }
    final encodedLeft = codec.encode(left.value);
    final encodedRight = codec.encode(right.value);
    if (encodedLeft is! CodecSuccess<EncodedDocument> ||
        encodedRight is! CodecSuccess<EncodedDocument> ||
        !_sameBytes(encodedLeft.value.bytes, encodedRight.value.bytes)) {
      return _failed(fixture, 'Repeated encoding was not byte deterministic.');
    }
    return _passed(
        fixture, 'Decode and encode matched across transport copies.');
  }

  CodecCertificationCheck _migrationExtensions(
    CodecHardEdgeFixture fixture,
    DocumentCodecCapability<Object> codec,
    String? mutationOperatorId,
  ) {
    if (!_isJson(codec)) {
      return _failed(fixture, 'Migration property requires a JSON codec.');
    }
    final canonical = jsonDecode(
      utf8.decode(_canonicalPayload(codec, fixture: fixture).bytes),
    );
    if (canonical is! Map) {
      return _failed(fixture, 'Canonical JSON root is not an object.');
    }
    final canonicalOutcome = codec.decode(
      _canonicalPayload(codec, fixture: fixture),
    );
    if (canonicalOutcome is! CodecSuccess<InteroperableDocument<Object>>) {
      return _failed(fixture, 'Canonical JSON could not be decoded.');
    }
    final canonicalEncoded = codec.encode(canonicalOutcome.value);
    if (canonicalEncoded is! CodecSuccess<EncodedDocument>) {
      return _failed(fixture, 'Canonical JSON could not be encoded.');
    }
    final encodedRoot = jsonDecode(utf8.decode(canonicalEncoded.value.bytes));
    if (encodedRoot is! Map) {
      return _failed(fixture, 'Encoded canonical JSON root is not an object.');
    }
    final root = Map<String, Object?>.from(canonical);
    final futureRoot =
        jsonDecode(jsonEncode(encodedRoot)) as Map<String, dynamic>;
    final futureDocument = futureRoot['document'];
    final futureSchema =
        futureDocument is Map ? futureDocument['schema'] : futureRoot['schema'];
    if (futureSchema is Map) futureSchema['version'] = 999;
    final futurePayload = DocumentPayload(
      bytes: Uint8List.fromList(utf8.encode(jsonEncode(futureRoot))),
      filename: 'future.json',
    );
    final futureOutcome = _decodeThroughMutationAdapter(
      codec,
      futurePayload,
      mutationOperatorId,
      normalizeFutureSchema:
          mutationOperatorId == codecAcceptFutureSchemaMutationId,
    );
    final futureRejected =
        futureOutcome is CodecUnsupported<InteroperableDocument<Object>>;
    if (!futureRejected) {
      return _failed(fixture, 'Future schema was not reported unsupported.');
    }
    final document = root['document'];
    final rawPayload = document is Map && document['payload'] is Map
        ? Map<String, Object?>.from(document['payload'] as Map)
        : root;
    if (fixture.codecId == 'regex.turing-lab-json.v1') {
      rawPayload['currentRegex'] = rawPayload.remove('source');
      rawPayload.remove('canonicalAst');
      rawPayload.remove('sourceOfTruth');
    }
    final field = _fixtureString(
      fixture,
      'unknownField',
      fallback: 'x-hard-edge-${fixture.seed}',
    );
    rawPayload['x-hard-edge-extension'] = {
      'marker': field,
      'tokens': _fixtureStringList(
        fixture,
        'extensionTokens',
        fallback: const ['multi-token', 'β', '🧪'],
      ),
    };
    final input = DocumentPayload(
      bytes: Uint8List.fromList(utf8.encode(jsonEncode(rawPayload))),
      filename: 'historical.json',
    );
    final outcome = _decodeThroughMutationAdapter(
      codec,
      input,
      mutationOperatorId,
    );
    if (outcome is! CodecSuccess<InteroperableDocument<Object>>) {
      return _failed(
        fixture,
        'Historical/raw JSON shape was not migrated or explicitly accepted.',
      );
    }
    final encoded = codec.encode(outcome.value);
    if (encoded is! CodecSuccess<EncodedDocument>) {
      return _failed(fixture, 'Migrated document could not be re-encoded.');
    }
    final replay = codec.decode(
      DocumentPayload(
          bytes: encoded.value.bytes, filename: encoded.value.filename),
    );
    if (replay is! CodecSuccess<InteroperableDocument<Object>> ||
        !_sameDocument(outcome.value, replay.value)) {
      return _failed(
          fixture, 'Migration was not idempotent after re-encoding.');
    }
    final extensionValues = outcome.value.extensions.values;
    final preserved = extensionValues.values.any(
      (value) => _canonicalValue(value).contains(field),
    );
    if (!preserved) {
      return _failed(
        fixture,
        'Historical shape discarded an unknown extension.',
        fidelityCoverage: {outcome.fidelity.name},
      );
    }
    return _passed(
      fixture,
      'Historical shape migrated and preserved unknown extensions.',
      fidelityCoverage: {outcome.fidelity.name},
    );
  }

  CodecOutcome<InteroperableDocument<Object>> _decodeThroughMutationAdapter(
    DocumentCodecCapability<Object> codec,
    DocumentPayload payload,
    String? mutationOperatorId, {
    bool normalizeFutureSchema = false,
  }) {
    var adaptedPayload = payload;
    if (normalizeFutureSchema) {
      final root = jsonDecode(utf8.decode(payload.bytes));
      if (root is Map) {
        final document = root['document'];
        final schema = document is Map ? document['schema'] : root['schema'];
        if (schema is Map) {
          schema['version'] = codec.descriptor.schemas.maximum;
        }
      }
      adaptedPayload = DocumentPayload(
        bytes: Uint8List.fromList(utf8.encode(jsonEncode(root))),
        filename: payload.filename,
        mimeType: payload.mimeType,
        sourcePath: payload.sourcePath,
      );
    }
    final decoded = codec.decode(adaptedPayload);
    if (decoded is! CodecSuccess<InteroperableDocument<Object>>) {
      return decoded;
    }
    if (mutationOperatorId == codecDropExtensionSidecarMutationId) {
      final value = decoded.value;
      return CodecSuccess(
        value: InteroperableDocument<Object>(
          document: value.document,
          systemKey: value.systemKey,
          schema: value.schema,
          sourceMetadata: value.sourceMetadata,
          extensions: DocumentExtensionBag(),
        ),
        fidelity: decoded.fidelity,
        diagnostics: decoded.diagnostics,
      );
    }
    if (mutationOperatorId == codecEscalateFidelityMutationId) {
      return CodecSuccess(
        value: decoded.value,
        fidelity: DocumentFidelity.exact,
        diagnostics: decoded.diagnostics
            .where(
              (diagnostic) =>
                  diagnostic.disposition ==
                  CodecDiagnosticDisposition.preserved,
            )
            .toList(growable: false),
      );
    }
    return decoded;
  }

  DocumentPayload _canonicalPayload(
    DocumentCodecCapability<Object> codec, {
    CodecHardEdgeFixture? fixture,
    String? filename,
  }) {
    final encoded = fixture?.payload['sourcePayloadBase64'];
    final sourceFilename = fixture?.payload['sourceFilename'];
    if (encoded is String && sourceFilename is String) {
      return DocumentPayload(
        bytes: Uint8List.fromList(base64Decode(encoded)),
        filename: filename ?? sourceFilename,
        sourcePath: 'generated:${fixture!.id}',
      );
    }
    final source = File(_path(codec.descriptor.canonicalFixtures.first));
    return DocumentPayload(
      bytes: source.readAsBytesSync(),
      filename: filename ?? source.uri.pathSegments.last,
      sourcePath: codec.descriptor.canonicalFixtures.first,
    );
  }

  String _path(String relative) =>
      '${repositoryRoot.path}${Platform.pathSeparator}'
      '${relative.replaceAll('/', Platform.pathSeparator)}';
}

Future<CodecBoundaryProcessResult> runCodecBoundaryProcessForCertification({
  required String executable,
  required List<String> arguments,
  required Duration timeout,
  bool Function()? isCancelled,
  Directory? workingDirectory,
}) async {
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory?.path,
    runInShell: false,
  );
  const outputDecoder = Utf8Decoder(allowMalformed: true);
  final stdoutText = process.stdout.transform(outputDecoder).join();
  final stderrText = process.stderr.transform(outputDecoder).join();
  final exitCode = process.exitCode;
  final stopwatch = Stopwatch()..start();
  var outcome = CodecBoundaryProcessOutcome.failed;
  var code = -1;
  while (true) {
    final completed = await Future.any<int?>([
      exitCode.then<int?>((value) => value),
      Future<int?>.delayed(const Duration(milliseconds: 25), () => null),
    ]);
    if (completed != null) {
      code = completed;
      outcome = code == 0
          ? CodecBoundaryProcessOutcome.passed
          : CodecBoundaryProcessOutcome.failed;
      break;
    }
    if (isCancelled?.call() == true) {
      outcome = CodecBoundaryProcessOutcome.cancelled;
      code = -2;
      await _killCodecBoundaryProcessTree(process);
      break;
    }
    if (stopwatch.elapsed >= timeout) {
      outcome = CodecBoundaryProcessOutcome.timedOut;
      code = -1;
      await _killCodecBoundaryProcessTree(process);
      break;
    }
  }
  if (outcome == CodecBoundaryProcessOutcome.timedOut ||
      outcome == CodecBoundaryProcessOutcome.cancelled) {
    await exitCode.timeout(
      const Duration(seconds: 5),
      onTimeout: () => code,
    );
  }
  final output = await Future.wait([stdoutText, stderrText]).timeout(
    const Duration(seconds: 5),
    onTimeout: () => const ['', 'Output streams did not close after cleanup.'],
  );
  final combined = '${output[0]}${output[1]}';
  return CodecBoundaryProcessResult(
    exitCode: code,
    output: combined.length <= 4000
        ? combined
        : combined.substring(combined.length - 4000),
    outcome: outcome,
  );
}

Future<void> _killCodecBoundaryProcessTree(Process process) async {
  if (Platform.isWindows) {
    try {
      final result = await Process.run(
        'taskkill',
        ['/PID', '${process.pid}', '/T', '/F'],
        runInShell: false,
      );
      if (result.exitCode != 0) process.kill();
    } on ProcessException {
      process.kill();
    }
    return;
  }

  final rootPid = process.pid;
  final parentByPid = <int, int>{};
  final descendants = <int>{};
  Process.killPid(rootPid, ProcessSignal.sigstop);
  try {
    for (var attempt = 0; attempt < 4; attempt++) {
      parentByPid.addAll(await _readCodecPosixProcessParents());
      final ordered = CodecBoundaryProcessTree.descendantsDeepestFirst(
        parentByPid,
        rootPid,
      );
      var foundNewDescendant = false;
      for (final pid in ordered) {
        foundNewDescendant = descendants.add(pid) || foundNewDescendant;
        Process.killPid(pid, ProcessSignal.sigstop);
      }
      if (!foundNewDescendant) break;
    }
  } on ProcessException {
    // Supported POSIX hosts provide `ps`; the root is still killed below if
    // process-tree discovery is unavailable.
  } finally {
    final ordered = CodecBoundaryProcessTree.descendantsDeepestFirst(
      parentByPid,
      rootPid,
    );
    for (final pid in ordered) {
      if (descendants.contains(pid)) {
        Process.killPid(pid, ProcessSignal.sigkill);
      }
    }
    process.kill(ProcessSignal.sigkill);
  }
}

Future<Map<int, int>> _readCodecPosixProcessParents() async {
  const arguments = ['-A', '-o', 'pid=,ppid='];
  final result = await Process.run('ps', arguments, runInShell: false);
  if (result.exitCode != 0) {
    throw ProcessException(
      'ps',
      arguments,
      'Could not inspect the boundary process tree.',
      result.exitCode,
    );
  }
  final parentByPid = <int, int>{};
  for (final line in '${result.stdout}'.split(RegExp(r'\r?\n'))) {
    final fields = line.trim().split(RegExp(r'\s+'));
    if (fields.length != 2) continue;
    final pid = int.tryParse(fields[0]);
    final parentPid = int.tryParse(fields[1]);
    if (pid != null && parentPid != null) parentByPid[pid] = parentPid;
  }
  return parentByPid;
}

final class CodecBoundaryProcessTree {
  const CodecBoundaryProcessTree._();

  static List<int> descendantsDeepestFirst(
    Map<int, int> parentByPid,
    int rootPid,
  ) {
    final childrenByPid = <int, List<int>>{};
    for (final MapEntry(key: pid, value: parentPid) in parentByPid.entries) {
      childrenByPid.putIfAbsent(parentPid, () => <int>[]).add(pid);
    }
    for (final children in childrenByPid.values) {
      children.sort();
    }
    final ordered = <int>[];
    final visiting = <int>{rootPid};
    final visited = <int>{};
    void visit(int pid) {
      for (final childPid in childrenByPid[pid] ?? const <int>[]) {
        if (visiting.contains(childPid) || !visited.add(childPid)) continue;
        visiting.add(childPid);
        visit(childPid);
        visiting.remove(childPid);
        ordered.add(childPid);
      }
    }

    visit(rootPid);
    return ordered;
  }
}

bool _isJson(DocumentCodecCapability<Object> codec) =>
    codec.descriptor.formatId == DefaultFormalSystemIds.turingLabJsonFormat;

bool _sameBytes(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

bool _sameDocument(
  InteroperableDocument<Object> left,
  InteroperableDocument<Object> right,
) =>
    left.systemKey == right.systemKey &&
    left.schema == right.schema &&
    _canonicalValue(_documentJson(left.document)) ==
        _canonicalValue(_documentJson(right.document)) &&
    _canonicalValue(left.extensions.values) ==
        _canonicalValue(right.extensions.values);

Object? _documentJson(Object document) {
  try {
    return (document as dynamic).toJson();
  } on NoSuchMethodError {
    return document.toString();
  }
}

String _canonicalValue(Object? value) => jsonEncode(_canonicalize(value));

int _fixtureInt(
  CodecHardEdgeFixture fixture,
  String key, {
  int fallback = 0,
}) =>
    fixture.payload[key] is int ? fixture.payload[key]! as int : fallback;

String _fixtureString(
  CodecHardEdgeFixture fixture,
  String key, {
  required String fallback,
}) =>
    fixture.payload[key] is String ? fixture.payload[key]! as String : fallback;

List<String> _fixtureStringList(
  CodecHardEdgeFixture fixture,
  String key, {
  required List<String> fallback,
}) {
  final value = fixture.payload[key];
  return value is List && value.every((item) => item is String)
      ? value.cast<String>()
      : fallback;
}

Object? _canonicalize(Object? value) {
  if (value is Map) {
    final entries = value.entries.toList()
      ..sort(
          (left, right) => left.key.toString().compareTo(right.key.toString()));
    return <String, Object?>{
      for (final entry in entries)
        entry.key.toString(): _canonicalize(entry.value),
    };
  }
  if (value is Set) {
    final result = value.map(_canonicalize).toList()
      ..sort((left, right) => jsonEncode(left).compareTo(jsonEncode(right)));
    return result;
  }
  if (value is List) return value.map(_canonicalize).toList();
  return value;
}

CodecCertificationCheck _passed(
  CodecHardEdgeFixture fixture,
  String message, {
  Set<String> fidelityCoverage = const {},
}) =>
    CodecCertificationCheck(
      codecId: fixture.codecId,
      property: fixture.property,
      status: CodecCertificationStatus.passed,
      message: message,
      fidelityCoverage: fidelityCoverage,
    );

CodecCertificationCheck _failed(
  CodecHardEdgeFixture fixture,
  String message, {
  Set<String> fidelityCoverage = const {},
}) =>
    CodecCertificationCheck(
      codecId: fixture.codecId,
      property: fixture.property,
      status: CodecCertificationStatus.failed,
      message: message,
      fidelityCoverage: fidelityCoverage,
    );
