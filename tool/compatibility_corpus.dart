import 'dart:io';

import 'package:turing_lab/core/interoperability/interoperability.dart';

import 'compatibility_corpus/catalog.dart';
import 'compatibility_corpus/manifest.dart';
import 'compatibility_corpus/report.dart';
import 'compatibility_corpus/runner.dart';

Future<void> main(List<String> arguments) async {
  try {
    final options = _CompatibilityOptions.parse(arguments);
    if (options.help) {
      stdout.write(_help);
      return;
    }
    final root = _findRepositoryRoot(Directory.current);
    if (options.listCodecs) {
      final catalog = CompatibilityCodecCatalog.create();
      for (final id in catalog.codecs.keys.toList()..sort()) {
        final codec = catalog.codecs[id]!;
        final descriptor = codec.descriptor;
        final fixturePath = descriptor.canonicalFixtures.first;
        final fixture = File(_resolve(root, fixturePath));
        final decoded = codec.decode(
          DocumentPayload(
            bytes: fixture.readAsBytesSync(),
            filename: fixture.uri.pathSegments.last,
          ),
        );
        final fidelity = decoded is CodecSuccess<InteroperableDocument<Object>>
            ? decoded.fidelity.name
            : decoded.runtimeType.toString();
        final diagnosticCodes = decoded
                is CodecSuccess<InteroperableDocument<Object>>
            ? (decoded.diagnostics.map((diagnostic) => diagnostic.code).toList()
              ..sort())
            : const <String>[];
        stdout.writeln(
          '$id\t$fixturePath\t$fidelity\t${diagnosticCodes.join(',')}\t'
          '${(descriptor.knownUnsupportedFields.toList()..sort()).join(';')}',
        );
      }
      return;
    }
    final manifestFile = File(_resolve(root, options.manifest));
    final manifest = CompatibilityManifest.parse(
      await manifestFile.readAsString(),
    );
    if (options.list) {
      for (final testCase in manifest.cases.toList()
        ..sort((left, right) => left.id.compareTo(right.id))) {
        stdout.writeln(
          '${testCase.id}\t${testCase.family}\t${testCase.codecId}',
        );
      }
      return;
    }

    final catalog = CompatibilityCodecCatalog.create();
    final runner = CompatibilityCorpusRunner(
      repositoryRoot: root,
      catalog: catalog,
      jobs: options.jobs,
      timeout: Duration(seconds: options.timeoutSeconds),
    );
    final result = await runner.run(
      manifest,
      family: options.family,
      fixtureId: options.fixture,
    );
    final output = Directory(_resolve(root, options.output));
    final publicMatrix = options.updatePublic
        ? File(_resolve(root, 'docs/JFLAP_COMPATIBILITY.md'))
        : null;
    await const CompatibilityReportWriter().write(
      result,
      outputDirectory: output,
      publicMatrix: publicMatrix,
    );

    for (final testCase in result.cases) {
      stdout.writeln(
        'CORPUS_CASE ${testCase.testCase.id}=${testCase.status.name} '
        'outcome=${testCase.actualOutcome} '
        'fidelity=${testCase.actualFidelity ?? '-'}',
      );
    }
    stdout.writeln('CORPUS_RESULT ${result.status.name}');
    stdout.writeln('Reports: ${output.path}');
    stdout.writeln(
      'Local execution only. No result was remotely verified.',
    );
    exitCode = switch (result.status) {
      CompatibilityRunStatus.passed => 0,
      CompatibilityRunStatus.failed => 1,
      CompatibilityRunStatus.incomplete => 2,
    };
  } on FormatException catch (error) {
    stderr
        .writeln('Compatibility corpus configuration error: ${error.message}');
    exitCode = 64;
  } on FileSystemException catch (error) {
    stderr.writeln('Compatibility corpus file error: ${error.message}');
    exitCode = 1;
  }
}

final class _CompatibilityOptions {
  const _CompatibilityOptions({
    required this.manifest,
    required this.output,
    required this.jobs,
    required this.timeoutSeconds,
    required this.family,
    required this.fixture,
    required this.updatePublic,
    required this.list,
    required this.listCodecs,
    required this.help,
  });

  final String manifest;
  final String output;
  final int jobs;
  final int timeoutSeconds;
  final String? family;
  final String? fixture;
  final bool updatePublic;
  final bool list;
  final bool listCodecs;
  final bool help;

  factory _CompatibilityOptions.parse(List<String> arguments) {
    var manifest = 'test/fixtures/compatibility/manifest.v1.json';
    var output = 'build/compatibility';
    var jobs = Platform.numberOfProcessors.clamp(1, 4);
    var timeoutSeconds = 10;
    String? family;
    String? fixture;
    var updatePublic = false;
    var list = false;
    var listCodecs = false;
    var help = false;

    for (var index = 0; index < arguments.length; index++) {
      final argument = arguments[index];
      String value(String name) {
        final equals = argument.indexOf('=');
        if (equals >= 0) return argument.substring(equals + 1);
        if (++index >= arguments.length) {
          throw FormatException('$name requires a value.');
        }
        return arguments[index];
      }

      final name = argument.split('=').first;
      switch (name) {
        case '--manifest':
          manifest = value(name);
        case '--output':
          output = value(name);
        case '--jobs':
          jobs = int.tryParse(value(name)) ?? 0;
        case '--timeout-seconds':
          timeoutSeconds = int.tryParse(value(name)) ?? 0;
        case '--type':
          family = value(name);
        case '--fixture':
          fixture = value(name);
        case '--update-public':
          updatePublic = true;
        case '--list':
          list = true;
        case '--list-codecs':
          listCodecs = true;
        case '--help':
        case '-h':
          help = true;
        default:
          throw FormatException('Unknown option $argument.');
      }
    }
    if (jobs <= 0) throw const FormatException('--jobs must be positive.');
    if (timeoutSeconds <= 0) {
      throw const FormatException('--timeout-seconds must be positive.');
    }
    return _CompatibilityOptions(
      manifest: manifest,
      output: output,
      jobs: jobs,
      timeoutSeconds: timeoutSeconds,
      family: family,
      fixture: fixture,
      updatePublic: updatePublic,
      list: list,
      listCodecs: listCodecs,
      help: help,
    );
  }
}

Directory _findRepositoryRoot(Directory start) {
  var current = start.absolute;
  while (true) {
    if (File('${current.path}${Platform.pathSeparator}pubspec.yaml')
        .existsSync()) {
      return current;
    }
    final parent = current.parent;
    if (parent.path == current.path) {
      throw const FileSystemException('Could not locate pubspec.yaml.');
    }
    current = parent;
  }
}

String _resolve(Directory root, String path) =>
    '${root.path}${Platform.pathSeparator}'
    '${path.replaceAll('/', Platform.pathSeparator)}';

const _help = '''
Turing Lab JFLAP compatibility corpus

Usage:
  dart run tool/compatibility_corpus.dart [options]

Options:
  --manifest PATH          Versioned corpus manifest.
  --output PATH            JSON and Markdown output directory.
  --type FAMILY            Run one document family.
  --fixture ID             Run one fixture id.
  --jobs NUMBER            Bounded worker count (default: up to 4).
  --timeout-seconds NUMBER Per-fixture timeout (default: 10).
  --update-public          Regenerate docs/JFLAP_COMPATIBILITY.md.
  --list                   List discovered fixtures without running them.
  --list-codecs            List every implemented codec and capability gap.
  --help                   Show this help.

Exit codes: 0 passed, 1 failed, 2 incomplete, 64 invalid configuration.
Results are local only and are never remotely verified.
''';
