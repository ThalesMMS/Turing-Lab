import 'dart:io';

import 'hard_edge/catalog.dart';
import 'hard_edge/certification.dart';
import 'hard_edge/certification_report.dart';
import 'hard_edge/families/registry.dart';
import 'hard_edge/report.dart';
import 'hard_edge/runner.dart';

Future<void> main(List<String> arguments) async {
  final _CommandOptions options;
  try {
    options = _CommandOptions.parse(arguments);
  } on FormatException catch (error) {
    stderr.writeln('Hard-edge command error: ${error.message}');
    exitCode = 64;
    return;
  }
  if (options.help) {
    stdout.write(_help);
    return;
  }

  try {
    final root = _findRepositoryRoot(Directory.current);
    final propertyExecutor = hardEdgePropertyExecutorRegistry(root);
    final mutationExecutor = hardEdgeMutationExecutorRegistry();
    final shrinkAdapters = hardEdgeShrinkAdapterRegistry();
    final output =
        Directory(_inside(root, options.output, mustExist: false).path);
    Future<HardEdgeCatalog> loadCatalog() => HardEdgeCatalog.load(
          repositoryRoot: root,
          manifestFile: _inside(root, options.manifest, mustExist: true),
        );
    switch (options.command) {
      case 'certify':
        final catalog = await loadCatalog();
        final policy = await HardEdgeCertificationPolicy.load(
          _inside(root, options.policy, mustExist: true),
        );
        final environment = await collectHardEdgeEnvironment(root);
        final result = await HardEdgeCertificationRunner(
          catalog: catalog,
          propertyExecutor: propertyExecutor,
          mutationExecutor: mutationExecutor,
          policy: policy,
          environment: environment,
        ).run(
          HardEdgeCertificationOptions(
            family: options.family,
            property: options.property,
            seedStart: options.seedStart,
            seedCount: options.seedCount,
            repeats: options.repeats,
            jobs: options.jobs,
            caseTimeout: Duration(seconds: options.timeoutSeconds),
            maximumCases: options.maximumCases,
            mutationOnly: options.mutationOnly,
            regressionOnly: options.regressionOnly,
            command: _certificationCommand(arguments),
          ),
        );
        await const HardEdgeCertificationReportWriter().write(
          result,
          outputDirectory: output,
        );
        for (final phase in result.phases) {
          stdout.writeln(
            'CERTIFICATION_PHASE ${phase.name}='
            '${hardEdgeCertificationStatusName(phase.status)}',
          );
        }
        stdout.writeln(
          'CERTIFICATION_RESULT '
          '${hardEdgeCertificationStatusName(result.status)}',
        );
        stdout.writeln('Reports: ${output.path}');
        if (result.hasMissingRequiredPrerequisite) {
          exitCode = 127;
        } else {
          exitCode = switch (result.status) {
            HardEdgeCertificationStatus.passed => 0,
            HardEdgeCertificationStatus.failed => 1,
            HardEdgeCertificationStatus.skipped ||
            HardEdgeCertificationStatus.notRun =>
              2,
          };
        }
      case 'run':
      case 'repeat':
        final catalog = await loadCatalog();
        final runOptions = HardEdgeRunOptions(
          family: options.family,
          property: options.property,
          seedStart: options.seedStart,
          seedCount: options.seedCount,
          repeats: options.repeats,
          jobs: options.jobs,
          caseTimeout: Duration(seconds: options.timeoutSeconds),
          maximumCases: options.maximumCases,
          regressionOnly: options.regressionOnly,
        );
        final result = await HardEdgeRunner(
          catalog: catalog,
          executor: propertyExecutor,
        ).run(runOptions);
        await const HardEdgeReportWriter().writeRun(
          result,
          outputDirectory: output,
          catalog: catalog,
        );
        for (final resultCase in result.cases) {
          stdout.writeln(
            'PROPERTY_CASE ${resultCase.testCase.id}='
            '${resultCase.status.name} outcome='
            '${resultCase.outcome?.name ?? 'runnerError'} '
            'seed=${resultCase.testCase.seed}',
          );
        }
        stdout.writeln('PROPERTY_RESULT ${result.status.name}');
        stdout.writeln('Reports: ${output.path}');
        _setResultExitCode(result.status);
      case 'replay':
        final failure = _inside(root, options.fixture!, mustExist: true);
        final result = await replayFailureArtifact(
          failureFile: failure,
          executor: propertyExecutor,
          timeout: Duration(seconds: options.timeoutSeconds),
        );
        stdout.writeln(
          'PROPERTY_CASE ${result.testCase.id}=${result.status.name} '
          'outcome=${result.outcome?.name ?? 'runnerError'} '
          'seed=${result.testCase.seed}',
        );
        stdout.writeln(
          'PROPERTY_RESULT ${switch (result.status) {
            HardEdgeCaseStatus.passed => 'passed',
            HardEdgeCaseStatus.failed => 'failed',
            HardEdgeCaseStatus.incomplete => 'incomplete',
          }}',
        );
        exitCode = switch (result.status) {
          HardEdgeCaseStatus.passed => 0,
          HardEdgeCaseStatus.failed => 1,
          HardEdgeCaseStatus.incomplete => 2,
        };
      case 'shrink':
        final failure = _inside(root, options.failure!, mustExist: true);
        final artifact = await readFailureArtifact(failure);
        final shrinkAdapter =
            shrinkAdapters.forFamily(artifact.testCase.family);
        final shrinkOutput = options.shrinkOutput ??
            'build/hard-edge/minimized/${failure.uri.pathSegments.last}';
        final minimized = await shrinkFailureArtifact(
          repositoryRoot: root,
          failureFile: failure,
          outputPath: shrinkOutput,
          executor: propertyExecutor,
          shrinker: shrinkAdapter?.shrinker,
          isValid: shrinkAdapter?.isValid,
          isApplicable: shrinkAdapter?.isApplicable,
        );
        stdout.writeln('SHRINK_RESULT passed fixture=${minimized.path}');
      case 'promote':
        final catalog = await loadCatalog();
        final failure = _inside(root, options.failure!, mustExist: true);
        final promoted = await promoteFailureArtifact(
          catalog: catalog,
          failureFile: failure,
          regressionIssue: options.issue!,
          executor: propertyExecutor,
        );
        stdout.writeln(
          'PROMOTE_RESULT passed case=${promoted.id} '
          'fixture=${promoted.fixture}',
        );
      case 'summary':
        final report = _inside(
          root,
          options.report ?? 'build/hard-edge/hard-edge-report.json',
          mustExist: true,
        );
        final summaryOutput = _inside(
          root,
          options.summaryOutput ?? 'build/hard-edge/hard-edge-summary.md',
          mustExist: false,
        );
        await const HardEdgeReportWriter().renderSummaryFromJson(
          reportFile: report,
          outputFile: summaryOutput,
        );
        stdout.writeln('SUMMARY_RESULT passed output=${summaryOutput.path}');
      case 'mutate':
        final catalog = await loadCatalog();
        final result = await HardEdgeMutationRunner(
          catalog: catalog,
          executor: mutationExecutor,
        ).run(
          family: options.family,
          property: options.property,
        );
        await const HardEdgeReportWriter().writeMutation(
          result,
          outputDirectory: output,
        );
        for (final mutation in result.mutations) {
          stdout.writeln(
            'MUTATION_CASE ${mutation.mutation.id}=${mutation.status.name}',
          );
        }
        stdout.writeln('MUTATION_RESULT ${result.status.name}');
        _setResultExitCode(result.status);
      default:
        throw StateError('Unhandled command ${options.command}.');
    }
    stdout.writeln(
      'Local execution only. No result was remotely verified.',
    );
  } on HardEdgeConfigurationException catch (error) {
    stderr.writeln('Hard-edge command error: ${error.message}');
    exitCode = 64;
  } on HardEdgeMissingToolException catch (error) {
    stderr.writeln('Hard-edge prerequisite error: $error');
    stdout.writeln('PROPERTY_RESULT failed reason=missing_${error.tool}');
    exitCode = 127;
  } on FormatException catch (error) {
    stderr.writeln('Hard-edge catalog or fixture error: ${error.message}');
    exitCode = 1;
  } on FileSystemException catch (error) {
    stderr.writeln('Hard-edge file error: ${error.message}');
    exitCode = 1;
  }
}

void _setResultExitCode(HardEdgeRunStatus status) {
  exitCode = switch (status) {
    HardEdgeRunStatus.passed => 0,
    HardEdgeRunStatus.failed => 1,
    HardEdgeRunStatus.incomplete => 2,
  };
}

final class _CommandOptions {
  const _CommandOptions({
    required this.command,
    required this.manifest,
    required this.output,
    required this.policy,
    required this.family,
    required this.property,
    required this.seedStart,
    required this.seedCount,
    required this.repeats,
    required this.jobs,
    required this.timeoutSeconds,
    required this.maximumCases,
    required this.fixture,
    required this.failure,
    required this.shrinkOutput,
    required this.issue,
    required this.report,
    required this.summaryOutput,
    required this.mutationOnly,
    required this.regressionOnly,
    required this.help,
  });

  static const commands = {
    'run',
    'certify',
    'repeat',
    'replay',
    'shrink',
    'promote',
    'summary',
    'mutate',
  };

  final String command;
  final String manifest;
  final String output;
  final String policy;
  final String? family;
  final String? property;
  final int? seedStart;
  final int? seedCount;
  final int repeats;
  final int jobs;
  final int timeoutSeconds;
  final int maximumCases;
  final String? fixture;
  final String? failure;
  final String? shrinkOutput;
  final int? issue;
  final String? report;
  final String? summaryOutput;
  final bool mutationOnly;
  final bool regressionOnly;
  final bool help;

  factory _CommandOptions.parse(List<String> arguments) {
    if (arguments.isEmpty ||
        arguments.first == '--help' ||
        arguments.first == '-h') {
      return const _CommandOptions(
        command: 'run',
        manifest: 'test/fixtures/hard_edge/manifest.v1.json',
        output: 'build/hard-edge',
        policy: 'test/fixtures/hard_edge/certification_policy.v1.json',
        family: null,
        property: null,
        seedStart: null,
        seedCount: null,
        repeats: 1,
        jobs: 1,
        timeoutSeconds: 5,
        maximumCases: 10000,
        fixture: null,
        failure: null,
        shrinkOutput: null,
        issue: null,
        report: null,
        summaryOutput: null,
        mutationOnly: false,
        regressionOnly: false,
        help: true,
      );
    }
    final command = arguments.first;
    if (!commands.contains(command)) {
      throw FormatException('Unknown command "$command".');
    }
    var manifest = 'test/fixtures/hard_edge/manifest.v1.json';
    var output = 'build/hard-edge';
    var policy = 'test/fixtures/hard_edge/certification_policy.v1.json';
    String? family;
    String? property;
    int? seedStart;
    int? seedCount;
    var repeats = command == 'repeat' ? 3 : 1;
    var jobs = 1;
    var timeoutSeconds = 5;
    var timeoutWasSet = false;
    var maximumCases = 10000;
    String? fixture;
    String? failure;
    String? shrinkOutput;
    int? issue;
    String? report;
    String? summaryOutput;
    var profile = '';
    var mutationOnly = false;
    var regressionOnly = false;
    var full = false;

    for (var index = 1; index < arguments.length; index++) {
      final argument = arguments[index];
      if (!argument.startsWith('--')) {
        throw FormatException('Unexpected argument "$argument".');
      }
      final equals = argument.indexOf('=');
      final name = equals < 0 ? argument : argument.substring(0, equals);
      String value() {
        if (equals >= 0) return argument.substring(equals + 1);
        index++;
        if (index >= arguments.length) {
          throw FormatException('$name requires a value.');
        }
        return arguments[index];
      }

      switch (name) {
        case '--full':
          if (equals >= 0) {
            throw const FormatException('--full does not take a value.');
          }
          full = true;
        case '--mutation-only':
          if (equals >= 0) {
            throw const FormatException(
              '--mutation-only does not take a value.',
            );
          }
          mutationOnly = true;
        case '--regression-only':
          if (equals >= 0) {
            throw const FormatException(
              '--regression-only does not take a value.',
            );
          }
          regressionOnly = true;
        case '--manifest':
          manifest = value();
        case '--policy':
          policy = value();
        case '--output':
          output = value();
        case '--family':
          family = value();
        case '--property':
          property = value();
        case '--seed':
          seedStart = _parseInt(value(), name);
          seedCount = 1;
        case '--seed-start':
          seedStart = _parseInt(value(), name);
        case '--seed-count':
          seedCount = _parseInt(value(), name);
        case '--repeat':
          repeats = _parseInt(value(), name);
        case '--jobs':
          jobs = _parseInt(value(), name);
        case '--timeout-seconds':
          timeoutSeconds = _parseInt(value(), name);
          timeoutWasSet = true;
        case '--max-cases':
          maximumCases = _parseInt(value(), name);
        case '--fixture':
          fixture = value();
        case '--failure':
          failure = value();
        case '--shrink-output':
          shrinkOutput = value();
        case '--issue':
          issue = _parseInt(value(), name);
        case '--report':
          report = value();
        case '--summary-output':
          summaryOutput = value();
        case '--profile':
          profile = value();
        default:
          throw FormatException('Unknown option "$name".');
      }
    }
    if (profile.isNotEmpty && profile != 'qa') {
      throw FormatException('Unknown profile "$profile".');
    }
    if (profile == 'qa' && !timeoutWasSet) {
      timeoutSeconds = 60;
    }
    if (manifest.trim().isEmpty) {
      throw const FormatException('--manifest must not be empty.');
    }
    if (output.trim().isEmpty) {
      throw const FormatException('--output must not be empty.');
    }
    if (policy.trim().isEmpty) {
      throw const FormatException('--policy must not be empty.');
    }
    if (family?.trim().isEmpty == true) {
      throw const FormatException('--family must not be empty.');
    }
    if (property?.trim().isEmpty == true) {
      throw const FormatException('--property must not be empty.');
    }
    if (seedStart != null && (seedStart < 0 || seedStart > 0xffffffff)) {
      throw const FormatException('--seed must be a 32-bit unsigned integer.');
    }
    if (seedCount != null && (seedCount <= 0 || seedCount > 10000)) {
      throw const FormatException('--seed-count must be between 1 and 10000.');
    }
    if (seedCount != null && seedStart == null) {
      throw const FormatException('--seed-count requires --seed-start.');
    }
    if (seedStart != null &&
        seedCount != null &&
        seedStart + seedCount - 1 > 0xffffffff) {
      throw const FormatException('Seed range exceeds uint32.');
    }
    if (repeats <= 0 || repeats > 20) {
      throw const FormatException('--repeat must be between 1 and 20.');
    }
    if (jobs <= 0 || jobs > 4) {
      throw const FormatException('--jobs must be between 1 and 4.');
    }
    if (timeoutSeconds <= 0 || timeoutSeconds > 60) {
      throw const FormatException(
          '--timeout-seconds must be between 1 and 60.');
    }
    if (maximumCases <= 0 || maximumCases > 10000) {
      throw const FormatException('--max-cases must be between 1 and 10000.');
    }
    if (seedCount != null && seedCount > maximumCases) {
      throw const FormatException(
        '--seed-count cannot exceed --max-cases.',
      );
    }
    if (mutationOnly && regressionOnly ||
        full && (mutationOnly || regressionOnly)) {
      throw const FormatException(
        '--full, --mutation-only, and --regression-only are mutually '
        'exclusive.',
      );
    }
    if (command != 'certify' && (full || mutationOnly)) {
      throw const FormatException(
        '--full and --mutation-only require the certify command.',
      );
    }
    switch (command) {
      case 'replay':
        if (fixture == null) {
          throw const FormatException('replay requires --fixture.');
        }
      case 'shrink':
        if (failure == null) {
          throw const FormatException('shrink requires --failure.');
        }
      case 'promote':
        if (failure == null || issue == null || issue <= 0) {
          throw const FormatException(
            'promote requires --failure and a positive --issue.',
          );
        }
    }
    return _CommandOptions(
      command: command,
      manifest: manifest,
      output: output,
      policy: policy,
      family: family,
      property: property,
      seedStart: seedStart,
      seedCount: seedCount,
      repeats: repeats,
      jobs: jobs,
      timeoutSeconds: timeoutSeconds,
      maximumCases: maximumCases,
      fixture: fixture,
      failure: failure,
      shrinkOutput: shrinkOutput,
      issue: issue,
      report: report,
      summaryOutput: summaryOutput,
      mutationOnly: mutationOnly,
      regressionOnly: regressionOnly,
      help: false,
    );
  }
}

int _parseInt(String value, String option) {
  final parsed = int.tryParse(value);
  if (parsed == null) throw FormatException('$option requires an integer.');
  return parsed;
}

String _certificationCommand(List<String> arguments) => [
      'dart',
      'run',
      'tool/hard_edge_cases.dart',
      ...arguments,
    ].map(_displayArgument).join(' ');

String _displayArgument(String value) {
  if (RegExp(r'^[a-zA-Z0-9_./:=+-]+$').hasMatch(value)) return value;
  return '"${value.replaceAll('"', r'\"')}"';
}

Directory _findRepositoryRoot(Directory start) {
  var current = start.absolute;
  while (true) {
    if (File('${current.path}${Platform.pathSeparator}pubspec.yaml')
        .existsSync()) {
      return current;
    }
    if (current.parent.path == current.path) {
      throw const FileSystemException('Could not locate pubspec.yaml.');
    }
    current = current.parent;
  }
}

File _inside(Directory root, String path, {required bool mustExist}) =>
    hardEdgePathInside(root, path, mustExist: mustExist);

const _help = '''
Turing Lab hard-edge property runner

Usage:
  dart run tool/hard_edge_cases.dart COMMAND [options]

Commands:
  certify   Run properties and mutations and write JSON, Markdown, and HTML.
  run       Run catalog properties once.
  repeat    Repeat selected seeds to check flakiness.
  replay    Replay a standalone failure fixture.
  shrink    Minimize a standalone failure fixture.
  promote   Add a reviewed minimized fixture to the regression catalog.
  summary   Render a short Markdown summary from a JSON report.
  mutate    Run registered mutation probes.

Selection:
  --family ID --property ID --seed N
  --seed-start N --seed-count N
  --full | --mutation-only | --regression-only

Limits:
  --repeat N             1..20
  --jobs N               1..4
  --timeout-seconds N    1..60
  --max-cases N          1..10000

Common:
  --manifest PATH
  --policy PATH
  --output PATH
  --profile qa

Summary defaults to build/hard-edge/hard-edge-report.json. Use --report and
--summary-output to override its input and Markdown destination.

Exit codes: 0 passed, 1 failed, 2 incomplete, 64 invalid arguments,
127 required local tool unavailable. Results are local only.
''';
