import 'dart:convert';
import 'dart:io';

import 'hard_edge/repository_algorithm_inventory.dart';

const _fixture =
    'test/fixtures/hard_edge/repository_algorithm_inventory.v1.json';

Future<void> main(List<String> arguments) async {
  if (arguments.length != 1 ||
      !const {'--check', '--write', '--print'}.contains(arguments.single)) {
    stderr.writeln(
      'Usage: dart run tool/build_repository_algorithm_inventory.dart '
      '<--check|--write|--print>',
    );
    exitCode = 64;
    return;
  }
  final root = Directory.current.absolute;
  final inventory = RepositoryAlgorithmInventory.discover(root);
  final validationIssues = inventory.validate(root);
  if (validationIssues.isNotEmpty) {
    for (final issue in validationIssues) {
      stderr.writeln('inventory: $issue');
    }
    exitCode = 1;
    return;
  }
  final encoded = '${canonicalInventoryJson(inventory.toJson())}\n';
  switch (arguments.single) {
    case '--write':
      final file = File(_path(root, _fixture));
      await file.parent.create(recursive: true);
      await file.writeAsString(encoded);
      stdout.writeln('Wrote ${inventory.entries.length} inventory entries.');
    case '--print':
      stdout.write(encoded);
    case '--check':
      final file = File(_path(root, _fixture));
      if (!file.existsSync()) {
        stderr.writeln('inventory: $_fixture is missing.');
        exitCode = 1;
        return;
      }
      final expected = jsonDecode(await file.readAsString());
      final actual = jsonDecode(encoded);
      if (jsonEncode(expected) != jsonEncode(actual)) {
        stderr.writeln(
          'inventory: $_fixture is stale; regenerate it with --write.',
        );
        exitCode = 1;
        return;
      }
      stdout.writeln(
        'Inventory is current: ${inventory.entries.length} entries, '
        '${inventory.exclusions.length} classified support files.',
      );
  }
}

String _path(Directory root, String relative) =>
    '${root.path}${Platform.pathSeparator}'
    '${relative.replaceAll('/', Platform.pathSeparator)}';
