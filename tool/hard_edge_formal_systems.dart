import 'dart:io';

import 'hard_edge/catalog.dart';
import 'hard_edge/families/formal_systems_certification.dart';
import 'hard_edge/models.dart';

const _usage = '''
Usage: dart run tool/hard_edge_formal_systems.dart <command> [options]

Commands:
  run       Run the matrix and write stable JSON and Markdown reports.
  repeat    Run the same seed range twice and compare canonical reports.
  summary   Print algorithm, property, and seed coverage as JSON.
  mutate    Run the pure-Dart semantic mutation probes.

Options:
  --seed <uint32>   First seed (default: 339).
  --count <1..64>   Number of seeds (default: 4).
  --case <id>       Select one matrix case.
  --output <path>   Repo-confined report directory
                    (default: build/qa/formal-systems-hard-edge).
''';

Future<void> main(List<String> arguments) async {
  try {
    final parsed = _Arguments.parse(arguments);
    exitCode = await _dispatch(parsed);
  } on FormatException catch (error) {
    stderr.writeln('Usage error: ${error.message}');
    stderr.writeln(_usage);
    exitCode = 64;
  } on RangeError catch (error) {
    stderr.writeln('Usage error: ${error.message}');
    stderr.writeln(_usage);
    exitCode = 64;
  }
}

Future<int> _dispatch(_Arguments parsed) async {
  switch (parsed.command) {
    case 'run':
      final report = await FormalSystemsCertification.run(parsed.options);
      await writeFormalSystemsCertificationReport(report, parsed.output);
      stdout.writeln(canonicalJsonEncode(report.toJson()));
      return report.passed ? 0 : 1;
    case 'repeat':
      final first = await FormalSystemsCertification.run(parsed.options);
      final second = await FormalSystemsCertification.run(parsed.options);
      final stable = canonicalJsonEncode(first.toJson()) ==
          canonicalJsonEncode(second.toJson());
      stdout.writeln(canonicalJsonEncode({
        'remotelyVerified': false,
        'stable': stable,
        'status': stable ? first.status.name : 'failed',
      }));
      return stable && first.passed ? 0 : 1;
    case 'summary':
      final report = await FormalSystemsCertification.run(parsed.options);
      final encoded = report.toJson();
      stdout.writeln(canonicalJsonEncode({
        'coverage': encoded['coverage'],
        'remotelyVerified': false,
        'status': encoded['status'],
      }));
      return report.passed ? 0 : 1;
    case 'mutate':
      final mutations = runFormalSystemsMutationProbes(
        seed: parsed.options.seedStart,
      );
      final survived = mutations.where((mutation) => !mutation.killed).length;
      stdout.writeln(canonicalJsonEncode({
        'killed': mutations.length - survived,
        'mutants': mutations.map((mutation) => mutation.toJson()).toList(),
        'remotelyVerified': false,
        'survived': survived,
      }));
      return survived == 0 ? 0 : 1;
  }
  throw FormatException('Unknown command: ${parsed.command}.');
}

final class _Arguments {
  const _Arguments({
    required this.command,
    required this.options,
    required this.output,
  });

  final String command;
  final FormalSystemsCertificationOptions options;
  final Directory output;

  static _Arguments parse(List<String> arguments) {
    if (arguments.firstOrNull == '--help') {
      stdout.writeln(_usage);
      exit(0);
    }
    if (arguments.isEmpty) {
      throw const FormatException('A command is required.');
    }
    const commands = {'run', 'repeat', 'summary', 'mutate'};
    final command = arguments.first;
    if (!commands.contains(command)) {
      throw FormatException('Unknown command: $command.');
    }
    var seed = 339;
    var count = 4;
    String? caseFilter;
    var output = 'build/qa/formal-systems-hard-edge';
    for (var index = 1; index < arguments.length; index += 2) {
      final option = arguments[index];
      if (index + 1 >= arguments.length || !option.startsWith('--')) {
        throw FormatException('Option $option requires a value.');
      }
      final value = arguments[index + 1];
      switch (option) {
        case '--seed':
          seed = _integer(value, option);
        case '--count':
          count = _integer(value, option);
        case '--case':
          caseFilter = value;
        case '--output':
          output = value;
        default:
          throw FormatException('Unknown option: $option.');
      }
    }
    final options = FormalSystemsCertificationOptions(
      seedStart: seed,
      seedCount: count,
      caseFilter: caseFilter,
    );
    options.validate();
    return _Arguments(
      command: command,
      options: options,
      output: Directory(
        hardEdgePathInside(
          Directory.current.absolute,
          output,
          mustExist: false,
        ).path,
      ).absolute,
    );
  }
}

int _integer(String value, String option) {
  final parsed = int.tryParse(value);
  if (parsed == null) throw FormatException('$option must be an integer.');
  return parsed;
}
