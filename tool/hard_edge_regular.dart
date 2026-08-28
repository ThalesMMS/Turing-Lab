import 'dart:convert';
import 'dart:io';

import 'hard_edge/catalog.dart';
import 'hard_edge/families/regular_certification.dart';
import 'hard_edge/families/regular_oracles.dart';

Future<void> main(List<String> arguments) async {
  try {
    final parsed = _Arguments.parse(arguments);
    if (parsed.help) {
      stdout.write(_usage);
      return;
    }
    final repositoryRoot = Directory.current.absolute;
    final runner = RegularCertificationRunner(repositoryRoot: repositoryRoot);
    final options = RegularCertificationOptions(
      seed: parsed.seed,
      cases: parsed.cases,
      oracleBudget: RegularOracleBudget(
        maximumWordLength: parsed.maximumWordLength,
        maximumWords: parsed.maximumWords,
        maximumConfigurations: parsed.maximumConfigurations,
      ),
    );
    final report = parsed.property == null
        ? await runner.run(options)
        : RegularCertificationReport(
            options: options,
            checks: [await runner.runProperty(parsed.property!, options)],
          );
    final jsonReport = hardEdgePathInside(
      repositoryRoot,
      '${parsed.output}/report.json',
      mustExist: false,
    );
    final markdownReport = hardEdgePathInside(
      repositoryRoot,
      '${parsed.output}/report.md',
      mustExist: false,
    );
    await jsonReport.parent.create(recursive: true);
    await jsonReport.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(report.toJson())}\n',
    );
    await markdownReport.writeAsString(report.toMarkdown());
    stdout.writeln(
      'regular hard-edge: ${report.status.name} '
      '(${report.checks.length} checks)',
    );
    exitCode = switch (report.status) {
      RegularCertificationStatus.passed => 0,
      RegularCertificationStatus.failed => 1,
      RegularCertificationStatus.incomplete => 2,
    };
  } on FormatException catch (error) {
    stderr.writeln('Usage error: ${error.message}');
    stderr.write(_usage);
    exitCode = 64;
  } on ArgumentError catch (error) {
    stderr.writeln('Usage error: ${error.message}');
    stderr.write(_usage);
    exitCode = 64;
  }
}

final class _Arguments {
  const _Arguments({
    required this.seed,
    required this.cases,
    required this.maximumWordLength,
    required this.maximumWords,
    required this.maximumConfigurations,
    required this.output,
    required this.property,
    required this.help,
  });

  final int seed;
  final int cases;
  final int maximumWordLength;
  final int maximumWords;
  final int maximumConfigurations;
  final String output;
  final String? property;
  final bool help;

  factory _Arguments.parse(List<String> arguments) {
    var seed = 335;
    var cases = 12;
    var maximumWordLength = 5;
    var maximumWords = 4096;
    var maximumConfigurations = 100000;
    var output = 'build/hard-edge/regular';
    String? property;
    var help = false;
    for (var index = 0; index < arguments.length; index++) {
      final argument = arguments[index];
      if (argument == '--help' || argument == '-h') {
        help = true;
        continue;
      }
      if (!argument.startsWith('--')) {
        throw FormatException('Unexpected argument "$argument".');
      }
      if (index + 1 == arguments.length) {
        throw FormatException('$argument requires a value.');
      }
      final value = arguments[++index];
      switch (argument) {
        case '--seed':
          seed = _integer(value, argument);
        case '--cases':
          cases = _integer(value, argument);
        case '--max-word-length':
          maximumWordLength = _integer(value, argument);
        case '--max-words':
          maximumWords = _integer(value, argument);
        case '--max-configurations':
          maximumConfigurations = _integer(value, argument);
        case '--output':
          output = value;
        case '--property':
          property = value;
        default:
          throw FormatException('Unknown option "$argument".');
      }
    }
    if (output.trim().isEmpty) {
      throw const FormatException('--output must not be empty.');
    }
    return _Arguments(
      seed: seed,
      cases: cases,
      maximumWordLength: maximumWordLength,
      maximumWords: maximumWords,
      maximumConfigurations: maximumConfigurations,
      output: output,
      property: property,
      help: help,
    );
  }
}

int _integer(String value, String option) {
  final parsed = int.tryParse(value);
  if (parsed == null) throw FormatException('$option must be an integer.');
  return parsed;
}

const _usage = '''Usage: dart run tool/hard_edge_regular.dart [options]

Runs only the regular-language hard-edge certification family.

Options:
  --seed N                 Stable uint32 seed (default: 335)
  --cases N                Generated cases, 1..256 (default: 12)
  --max-word-length N      Exhaustive oracle word bound (default: 5)
  --max-words N            Exhaustive oracle cardinality bound (default: 4096)
  --max-configurations N   Per-word configuration bound (default: 100000)
  --property ID            Run one registrable property
  --output PATH            Report directory (default: build/hard-edge/regular)
  -h, --help               Show this help
''';
