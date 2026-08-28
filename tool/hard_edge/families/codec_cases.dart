import 'dart:convert';
import 'dart:io';

import '../models.dart';
import '../shrinking.dart';
import 'codec_certification.dart';
import 'codec_family.dart';
import 'codec_matrix.dart';
import 'codec_mutations.dart';

Future<void> main(List<String> arguments) async {
  try {
    if (arguments.isEmpty ||
        arguments.first == 'help' ||
        arguments.contains('--help')) {
      stdout.write(_usage);
      return;
    }
    final options = _options(arguments.skip(1).toList());
    switch (arguments.first) {
      case 'run':
        await _run(options);
      case 'replay':
        await _replay(options);
      case 'mutate':
        await _mutate(options);
      case 'shrink':
        await _shrink(options);
      case 'matrix':
        stdout.writeln(
          _pretty({
            'boundaries':
                codecBoundaryInventory.map((entry) => entry.toJson()).toList(),
            'codecIds': codecIds,
            'remotelyVerified': false,
          }),
        );
      default:
        throw FormatException('Unknown codec command ${arguments.first}.');
    }
  } on FormatException catch (error) {
    stderr.writeln('Codec hard-edge error: ${error.message}');
    exitCode = 64;
  } on ArgumentError catch (error) {
    stderr.writeln('Codec hard-edge error: ${error.message ?? error}');
    exitCode = 64;
  }
}

Future<void> _run(Map<String, String> options) async {
  final seed = _seed(options);
  final report = await CodecCertificationRunner().run(seed: seed);
  final output = options['output'];
  if (output != null) {
    final directory = Directory(output);
    await directory.create(recursive: true);
    for (final descriptor in codecHardEdgeCaseDescriptors) {
      final fixture = materializeCodecPropertyFixture(
        codecId: descriptor.algorithm,
        property: descriptor.property,
        seed: seed,
      );
      await _writeJson(
        File(
          '${directory.path}${Platform.pathSeparator}fixtures'
          '${Platform.pathSeparator}${descriptor.algorithm}'
          '--${descriptor.property}.json',
        ),
        fixture.toJson(),
      );
    }
    await _writeJson(
      File('${directory.path}${Platform.pathSeparator}report.json'),
      report.toJson(),
    );
  }
  stdout.writeln(_pretty(report.toJson()));
  if (!report.passed) exitCode = 1;
}

Future<void> _replay(Map<String, String> options) async {
  final fixture = await _readFixture(_required(options, 'fixture'));
  final check = await CodecCertificationRunner().runProperty(fixture);
  stdout.writeln(_pretty(check.toJson()));
  if (check.status != CodecCertificationStatus.passed) exitCode = 1;
}

Future<void> _mutate(Map<String, String> options) async {
  final selected = options['operator'];
  final operators = selected == null
      ? codecMutationOperators.entries
      : [
          MapEntry(
            selected,
            codecMutationOperators[selected] ??
                (throw FormatException(
                  'Unknown codec mutation operator $selected.',
                )),
          ),
        ];
  final evidence = <Map<String, Object?>>[];
  for (final operator in operators) {
    evidence.add(
      (await evaluateCodecProductionMutation(operator.value)).toJson(),
    );
  }
  final killed = evidence.where((item) => item['status'] == 'killed').length;
  stdout.writeln(
    _pretty({
      'killed': killed,
      'mutations': evidence,
      'remotelyVerified': false,
      'survivors': evidence.length - killed,
      'threshold': codecMutationKillThreshold,
    }),
  );
  if (killed != evidence.length ||
      (selected == null && killed < codecMutationKillThreshold)) {
    exitCode = 1;
  }
}

Future<void> _shrink(Map<String, String> options) async {
  final inputFixture = await _readFixture(_required(options, 'fixture'));
  final runner = CodecCertificationRunner();
  final initialCheck = await runner.runProperty(inputFixture);
  if (initialCheck.status != CodecCertificationStatus.failed) {
    throw const FormatException(
      'Codec shrink requires a fixture that currently fails.',
    );
  }
  final expectedSignature = inputFixture.payload['failureSignature'] is String
      ? inputFixture.payload['failureSignature']! as String
      : initialCheck.failureSignature;
  if (expectedSignature != initialCheck.failureSignature) {
    throw const FormatException(
      'Recorded failure signature does not match the replayed failure.',
    );
  }
  final fixture = inputFixture.copyWith(
    payload: {
      ...inputFixture.payload,
      'failureSignature': expectedSignature,
    },
  );
  final source = GeneratedCase<CodecHardEdgeFixture>(
    family: 'codec',
    property: fixture.property,
    generatorVersion: '1',
    seed: fixture.seed,
    caseIndex: 0,
    mode: GenerationMode.boundaryValid,
    budget: const GenerationBudget(
      maxStates: 8,
      maxTransitions: 16,
      maxSymbols: 16,
      maxStackDepth: 80,
    ),
    value: fixture,
    encodeValue: (value) => value.toJson(),
  );
  Future<bool> stillFails(CodecHardEdgeFixture candidate) async {
    final check = await runner.runProperty(candidate);
    return check.status == CodecCertificationStatus.failed &&
        check.failureSignature == expectedSignature;
  }

  final result = await shrinkFailureAsync(
    source: source,
    shrinker: const CodecFixtureShrinker(),
    stillFails: stillFails,
  );
  final output = File(_required(options, 'output'));
  await _writeJson(output, result.minimalValue.toJson());
  stdout.writeln(
    _pretty({
      'acceptedCandidates': result.acceptedCandidates,
      'attempts': result.attempts,
      'fixture': output.path,
    }),
  );
}

Future<CodecHardEdgeFixture> _readFixture(String path) async {
  final decoded = jsonDecode(await File(path).readAsString());
  final payload = decoded is Map && decoded['fixture'] != null
      ? decoded['fixture']
      : decoded;
  return CodecHardEdgeFixture.fromJson(payload);
}

Future<void> _writeJson(File file, Object? value) async {
  await file.parent.create(recursive: true);
  await file.writeAsString('${_pretty(value)}\n');
}

String _pretty(Object? value) => const JsonEncoder.withIndent('  ').convert(
      jsonDecode(canonicalJsonEncode(value)),
    );

Map<String, String> _options(List<String> arguments) {
  final result = <String, String>{};
  for (var index = 0; index < arguments.length; index += 2) {
    final option = arguments[index];
    if (!option.startsWith('--') || index + 1 >= arguments.length) {
      throw FormatException('Expected --option value, received $option.');
    }
    result[option.substring(2)] = arguments[index + 1];
  }
  return result;
}

String _required(Map<String, String> options, String key) {
  final value = options[key];
  if (value == null || value.isEmpty) {
    throw FormatException('--$key is required.');
  }
  return value;
}

int _seed(Map<String, String> options) {
  final value = int.tryParse(options['seed'] ?? '340');
  if (value == null || value < 0 || value > 0xffffffff) {
    throw const FormatException('--seed must be a uint32 integer.');
  }
  return value;
}

const _usage = '''
Local codec hard-edge certification (results are never remotely verified).

  dart run tool/hard_edge/families/codec_cases.dart run [--seed 340] [--output DIR]
  dart run tool/hard_edge/families/codec_cases.dart replay --fixture FILE
  dart run tool/hard_edge/families/codec_cases.dart mutate [--operator ID]
  dart run tool/hard_edge/families/codec_cases.dart shrink --fixture FILE --output FILE
  dart run tool/hard_edge/families/codec_cases.dart matrix
''';
