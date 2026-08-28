import 'dart:io';

Future<void> main(List<String> arguments) async {
  if (arguments.contains('--help') || arguments.contains('-h')) {
    stdout.write(_usage);
    return;
  }
  final forwarded = <String>[
    'run',
    'tool/hard_edge_cases.dart',
    'run',
    '--family',
    'graph',
    '--output',
    'build/hard-edge/graph',
    '--timeout-seconds',
    '60',
    ...arguments,
  ];
  final process = await Process.start(
    Platform.resolvedExecutable,
    forwarded,
    mode: ProcessStartMode.inheritStdio,
  );
  exitCode = await process.exitCode;
}

const _usage = '''Usage: dart run tool/hard_edge_graph.dart [options]

Runs the graph mapping, layout, viewport, and canvas-history hard-edge family.
Reports are written under build/hard-edge/graph by default.

Options are forwarded to `hard_edge_cases.dart run`; useful options include:
  --property ID          Run one property
  --seed N               Materialize one deterministic seed
  --jobs N               Parallel catalog jobs, 1..4
  --timeout-seconds N    Per-case timeout (default here: 60)
  --output PATH          Override the report directory
  -h, --help             Show this help
''';
