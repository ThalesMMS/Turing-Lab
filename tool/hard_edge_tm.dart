import 'dart:convert';
import 'dart:io';

import 'hard_edge/catalog.dart';
import 'hard_edge/families/tm_certification.dart';

Future<void> main(List<String> arguments) async {
  try {
    final parsed = _Arguments.parse(arguments);
    if (parsed.help) {
      stdout.write(_usage);
      return;
    }
    final repositoryRoot = Directory.current.absolute;
    final runner = TmCertificationRunner(repositoryRoot: repositoryRoot);
    final options = TmCertificationOptions(
      seed: parsed.seed,
      cases: parsed.cases,
      maximumSteps: parsed.maximumSteps,
      maximumConfigurations: parsed.maximumConfigurations,
    );
    final report = parsed.property == null
        ? await runner.run(options)
        : TmCertificationReport(
            options: options,
            checks: [await runner.runProperty(parsed.property!, options)],
          );
    final reportJson = hardEdgePathInside(
      repositoryRoot,
      '${parsed.output}/report.json',
      mustExist: false,
    );
    final reportMarkdown = hardEdgePathInside(
      repositoryRoot,
      '${parsed.output}/report.md',
      mustExist: false,
    );
    await reportJson.parent.create(recursive: true);
    await reportJson.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(report.toJson())}\n',
    );
    await reportMarkdown.writeAsString(report.toMarkdown());
    stdout.writeln(
      'tm hard-edge: ${report.status.name} (${report.checks.length} checks)',
    );
    exitCode = switch (report.status) {
      TmCertificationStatus.passed => 0,
      TmCertificationStatus.failed => 1,
      TmCertificationStatus.incomplete => 2,
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
    required this.maximumSteps,
    required this.maximumConfigurations,
    required this.output,
    required this.property,
    required this.help,
  });

  final int seed;
  final int cases;
  final int maximumSteps;
  final int maximumConfigurations;
  final String output;
  final String? property;
  final bool help;

  factory _Arguments.parse(List<String> arguments) {
    var seed = 338;
    var cases = 12;
    var maximumSteps = 64;
    var maximumConfigurations = 512;
    var output = 'build/hard-edge/tm';
    String? property;
    var help = false;
    for (var index = 0; index < arguments.length; index++) {
      final argument = arguments[index];
      if (argument == '--help' || argument == '-h') {
        help = true;
        continue;
      }
      if (!argument.startsWith('--') || index + 1 == arguments.length) {
        throw FormatException('Invalid option "$argument".');
      }
      final value = arguments[++index];
      switch (argument) {
        case '--seed':
          seed = _integer(value, argument);
        case '--cases':
          cases = _integer(value, argument);
        case '--max-steps':
          maximumSteps = _integer(value, argument);
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
      maximumSteps: maximumSteps,
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

const _usage = '''Usage: dart run tool/hard_edge_tm.dart [options]

Runs only the Turing-machine hard-edge certification family.

Options:
  --seed N                 Stable uint32 seed (default: 338)
  --cases N                Generated cases, 1..128 (default: 12)
  --max-steps N            Oracle step bound (default: 64)
  --max-configurations N   Oracle configuration bound (default: 512)
  --property ID            Run one registrable property
  --output PATH            Report directory (default: build/hard-edge/tm)
  -h, --help               Show this help
''';
