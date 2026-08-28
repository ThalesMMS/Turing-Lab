import 'dart:convert';
import 'dart:io';

import 'package:turing_lab/core/algorithms/grammar_parser_earley.dart';

import 'hard_edge/catalog.dart';
import 'hard_edge/families/grammar_certification.dart';
import 'hard_edge/models.dart';

const _usage = '''
Usage: dart run tool/hard_edge_grammar_cases.dart <command> [options]

Commands:
  run       Run the grammar certification matrix and write stable reports.
  repeat    Run twice and fail if the stable JSON reports differ.
  summary   Print algorithm/property/seed coverage as JSON.
  mutate    Run the grammar-family mutation probes.
  replay    Replay a counterexample from --artifact <repo-relative path>.
  shrink    Minimize a reproducing --artifact and print the result as JSON.

Options:
  --seed <uint32>       First seed (default: 336).
  --count <1..64>       Number of seeds (default: 4).
  --max-word-length <0..6>  Bounded-oracle word length (default: 3).
  --case <id>           Select one matrix case.
  --output <path>       Repo-confined report directory
                        (default: build/qa/grammar-hard-edge).
  --artifact <path>     Repo-confined replay artifact.
''';

Future<void> main(List<String> arguments) async {
  try {
    final parsed = _Arguments.parse(arguments);
    final exit = await _dispatch(parsed);
    exitCode = exit;
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
      final report = await GrammarFamilyCertification.run(parsed.options);
      await writeGrammarCertificationReport(report, parsed.output);
      stdout.writeln(canonicalJsonEncode(report.toJson()));
      return _statusExitCode(report.status);
    case 'repeat':
      final first = await GrammarFamilyCertification.run(parsed.options);
      final second = await GrammarFamilyCertification.run(parsed.options);
      final stable = canonicalJsonEncode(first.toJson()) ==
          canonicalJsonEncode(second.toJson());
      stdout.writeln(canonicalJsonEncode({
        'remotelyVerified': false,
        'stable': stable,
        'status': stable ? first.status.name : 'failed',
      }));
      return stable ? _statusExitCode(first.status) : 1;
    case 'summary':
      final report = await GrammarFamilyCertification.run(parsed.options);
      final json = report.toJson();
      stdout.writeln(canonicalJsonEncode({
        'coverage': json['coverage'],
        'remotelyVerified': false,
        'status': json['status'],
      }));
      return _statusExitCode(report.status);
    case 'mutate':
      final results = runGrammarMutationProbes(seed: parsed.options.seedStart);
      final survived = results.where((result) => !result.killed).length;
      stdout.writeln(canonicalJsonEncode({
        'killed': results.length - survived,
        'mutants': results.map((result) => result.toJson()).toList(),
        'remotelyVerified': false,
        'survived': survived,
      }));
      return survived == 0 ? 0 : 1;
    case 'replay':
      final counterexample = await _readCounterexample(parsed.artifact!);
      final reproduces = replayGrammarCounterexample(counterexample);
      stdout.writeln(canonicalJsonEncode({
        'artifact': parsed.artifact!.path,
        'remotelyVerified': false,
        'reproduces': reproduces,
        'reproductionCommand':
            'dart run tool/hard_edge_grammar_cases.dart replay --artifact ${parsed.artifactArgument}',
      }));
      return reproduces ? 1 : 0;
    case 'shrink':
      final source = await _readCounterexample(parsed.artifact!);
      final shrunk = shrinkGrammarCounterexample(
        source,
        candidate: (grammar, input) =>
            EarleyRecognizer(grammar).recognizeWithReport(input).accepted,
      );
      stdout.writeln(canonicalJsonEncode(shrunk.toJson()));
      return 0;
  }
  throw FormatException('Unknown command: ${parsed.command}.');
}

int _statusExitCode(GrammarCertificationStatus status) => switch (status) {
      GrammarCertificationStatus.passed => 0,
      GrammarCertificationStatus.failed => 1,
      GrammarCertificationStatus.incomplete => 2,
    };

Future<GrammarCounterexample> _readCounterexample(File artifact) async {
  final decoded = jsonDecode(await artifact.readAsString());
  if (decoded is! Map) {
    throw const FormatException('Counterexample artifact must be an object.');
  }
  return GrammarCounterexample.fromJson(Map<String, Object?>.from(decoded));
}

final class _Arguments {
  const _Arguments({
    required this.command,
    required this.options,
    required this.output,
    required this.artifact,
    required this.artifactArgument,
  });

  final String command;
  final GrammarCertificationOptions options;
  final Directory output;
  final File? artifact;
  final String? artifactArgument;

  static _Arguments parse(List<String> arguments) {
    if (arguments.isEmpty || arguments.first == '--help') {
      if (arguments.firstOrNull == '--help') {
        stdout.writeln(_usage);
        exit(0);
      }
      throw const FormatException('A command is required.');
    }
    const commands = {'run', 'repeat', 'summary', 'mutate', 'replay', 'shrink'};
    final command = arguments.first;
    if (!commands.contains(command)) {
      throw FormatException('Unknown command: $command.');
    }
    var seed = 336;
    var count = 4;
    var maximumWordLength = 3;
    String? caseFilter;
    var outputArgument = 'build/qa/grammar-hard-edge';
    String? artifactArgument;
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
        case '--max-word-length':
          maximumWordLength = _integer(value, option);
        case '--case':
          caseFilter = value;
        case '--output':
          outputArgument = value;
        case '--artifact':
          artifactArgument = value;
        default:
          throw FormatException('Unknown option: $option.');
      }
    }
    if ((command == 'replay' || command == 'shrink') &&
        artifactArgument == null) {
      throw FormatException('$command requires --artifact.');
    }
    if (command != 'replay' &&
        command != 'shrink' &&
        artifactArgument != null) {
      throw const FormatException(
        '--artifact is only valid for replay and shrink.',
      );
    }
    final options = GrammarCertificationOptions(
      seedStart: seed,
      seedCount: count,
      maximumWordLength: maximumWordLength,
      caseFilter: caseFilter,
    );
    options.validate();
    return _Arguments(
      command: command,
      options: options,
      output: Directory(
        _repoConfined(outputArgument, mustExist: false).path,
      ).absolute,
      artifact: artifactArgument == null
          ? null
          : _repoConfined(artifactArgument, mustExist: true).absolute,
      artifactArgument: artifactArgument,
    );
  }
}

int _integer(String value, String option) {
  final parsed = int.tryParse(value);
  if (parsed == null) throw FormatException('$option must be an integer.');
  return parsed;
}

File _repoConfined(String argument, {required bool mustExist}) =>
    hardEdgePathInside(
      Directory.current.absolute,
      argument,
      mustExist: mustExist,
    );

extension on List<String> {
  String? get firstOrNull => isEmpty ? null : first;
}
