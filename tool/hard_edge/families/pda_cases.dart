import 'dart:convert';
import 'dart:io';

import '../models.dart';
import '../shrinking.dart';
import 'pda_executor.dart';
import 'pda_family.dart';

Future<void> main(List<String> arguments) async {
  try {
    if (arguments.isEmpty ||
        arguments.first == 'help' ||
        arguments.contains('--help')) {
      stdout.write(_usage);
      return;
    }
    final command = arguments.first;
    final options = _options(arguments.skip(1).toList());
    switch (command) {
      case 'run':
        await _run(options);
      case 'replay':
        await _replay(options);
      case 'mutate':
        await _mutate(options);
      case 'shrink':
        await _shrink(options);
      default:
        throw FormatException('Unknown PDA command "$command".');
    }
  } on FormatException catch (error) {
    stderr.writeln('PDA hard-edge error: ${error.message}');
    exitCode = 64;
  } on ArgumentError catch (error) {
    stderr.writeln('PDA hard-edge error: ${error.message ?? error}');
    exitCode = 64;
  }
}

Future<void> _run(Map<String, String> options) async {
  final seed = _seed(options);
  final report = await const PdaCertificationRunner().run(seed: seed);
  final output = options['output'];
  if (output != null) {
    final directory = Directory(output);
    await directory.create(recursive: true);
    for (final property in pdaCertificationProperties) {
      await _writeJson(
        File(
          '${directory.path}${Platform.pathSeparator}fixtures'
          '${Platform.pathSeparator}$property.json',
        ),
        materializePdaPropertyFixture(property: property, seed: seed).toJson(),
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
  final check = await _replayCheck(fixture);
  stdout.writeln(_pretty(check));
  if (check['passed'] != true) exitCode = 1;
}

Future<void> _mutate(Map<String, String> options) async {
  final suppliedFixture = options['fixture'] == null
      ? null
      : await _readFixture(options['fixture']!);
  final selected = options['operator'];
  final operators = selected == null
      ? pdaMutationProbeDescriptors.entries
      : [
          MapEntry(
            selected,
            pdaMutationProbeDescriptors[selected] ??
                (throw FormatException(
                  'Unknown PDA mutation operator "$selected".',
                )),
          ),
        ];
  final results = <Map<String, Object?>>[];
  for (final operator in operators) {
    final fixture = suppliedFixture ?? pdaMutationFixture(operator.value);
    final evidence = evaluatePdaProductionMutation(fixture, operator.value);
    results.add({
      'operator': operator.key,
      'originalOracle': evidence.originalOracle.name,
      'canonicalProduction': evidence.canonicalProduction.name,
      'mutantProduction': evidence.mutantProduction.name,
      'status': evidence.killed ? 'killed' : 'survived',
    });
  }
  stdout.writeln(_pretty({'mutations': results, 'remotelyVerified': false}));
  if (results.any((result) => result['status'] != 'killed')) exitCode = 1;
}

Future<void> _shrink(Map<String, String> options) async {
  final fixture = await _readFixture(_required(options, 'fixture'));
  final operatorId = _required(options, 'operator');
  final operator = pdaMutationProbeDescriptors[operatorId];
  if (operator == null) {
    throw FormatException('Unknown PDA mutation operator "$operatorId".');
  }
  final source = GeneratedCase<PdaHardEdgeFixture>(
    family: 'pda',
    property: 'mutation-$operatorId',
    generatorVersion: '1',
    seed: fixture.seed,
    caseIndex: 0,
    mode: GenerationMode.valid,
    budget: const GenerationBudget(
      maxStates: 32,
      maxTransitions: 128,
      maxSymbols: 32,
      maxStackDepth: 64,
    ),
    value: fixture,
    encodeValue: (value) => value.toJson(),
  );
  bool mismatch(PdaHardEdgeFixture candidate) {
    try {
      return evaluatePdaProductionMutation(candidate, operator).killed;
    } on StateError {
      return false;
    }
  }

  final result = shrinkFailure(
    source: source,
    shrinker: pdaFixtureShrinker,
    stillFails: mismatch,
    isValid: (candidate) => candidate.pda.validate().isEmpty,
  );
  final output = File(_required(options, 'output'));
  await _writeJson(output, result.minimalValue.toJson());
  stdout.writeln(
    _pretty({
      'acceptedCandidates': result.acceptedCandidates,
      'attempts': result.attempts,
      'fixture': output.path,
      'operator': operatorId,
    }),
  );
}

Future<Map<String, Object?>> _replayCheck(PdaHardEdgeFixture fixture) async {
  final check = await const PdaCertificationRunner().runProperty(
    property: fixture.property,
    fixture: fixture,
  );
  return {
    'algorithmIds': check.algorithmIds,
    'diagnostic': check.message,
    'fixtureId': fixture.id,
    'passed': check.status == PdaCertificationStatus.passed,
    'property': fixture.property,
    'remotelyVerified': false,
    'status': check.status.name,
  };
}

Future<PdaHardEdgeFixture> _readFixture(String path) async {
  final decoded = jsonDecode(await File(path).readAsString());
  final payload = decoded is Map && decoded['fixture'] != null
      ? decoded['fixture']
      : decoded;
  return PdaHardEdgeFixture.fromJson(payload);
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
      throw FormatException('Expected --option value, received "$option".');
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
  final value = int.tryParse(options['seed'] ?? '337');
  if (value == null || value < 0 || value > 0xffffffff) {
    throw const FormatException('--seed must be a uint32 integer.');
  }
  return value;
}

const _usage = '''
Local PDA hard-edge certification (results are never remotely verified).

  dart run tool/hard_edge/families/pda_cases.dart run [--seed 337] [--output DIR]
  dart run tool/hard_edge/families/pda_cases.dart replay --fixture FILE
  dart run tool/hard_edge/families/pda_cases.dart mutate [--fixture FILE] [--operator ID]
  dart run tool/hard_edge/families/pda_cases.dart shrink --fixture FILE --operator ID --output FILE
''';
