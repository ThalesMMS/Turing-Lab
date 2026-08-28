import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/data/codecs/default_document_interoperability_registry.dart';
import 'package:turing_lab/data/formal_systems/default_formal_system_registry.dart';

void main() {
  test('parity matrix covers every registered formal-system capability', () {
    final registry = DefaultDocumentInteroperabilityRegistry.withBuiltInCodecs(
      DefaultFormalSystemRegistry.registry,
    );
    final registered = <String>{};
    for (final module in registry.modules) {
      final descriptor = module.descriptor;
      final key = descriptor.key.value;
      registered.add('workspace:$key');
      for (final capability in FormalSystemCapability.values) {
        if (descriptor.capabilities.supports(capability)) {
          registered.add('capability:$key:${capability.name}');
        }
      }
      for (final format in descriptor.formats) {
        for (final direction in DocumentFormatDirection.values) {
          if (format.supports(direction)) {
            registered.add(
              'format:$key:${format.formatId.value}:${direction.name}',
            );
          }
        }
      }
      for (final conversion in descriptor.conversions) {
        if (conversion.availability.isEnabled) {
          registered.add('conversion:${conversion.id.value}');
        }
      }
      for (final codec in module.codecs) {
        registered.add('codec:${codec.descriptor.codecId.value}');
      }
      if (module.examples != null) registered.add('adapter:$key:examples');
      if (module.session != null) registered.add('adapter:$key:session');
    }

    final covered = <String>{};
    final directory = Directory('docs/jflap-parity');
    for (final file in directory
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'))) {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map || decoded['rows'] is! List) continue;
      for (final row in decoded['rows'] as List) {
        if (row is! Map || row['registryCapabilities'] is! List) continue;
        covered.addAll(
          (row['registryCapabilities'] as List).whereType<String>(),
        );
      }
    }

    final missing = registered.difference(covered).toList()..sort();
    final stale = covered.difference(registered).toList()..sort();

    expect(
      missing,
      isEmpty,
      reason: 'Every live registry capability needs a parity matrix row. '
          'Missing:\n${missing.join('\n')}',
    );
    expect(
      stale,
      isEmpty,
      reason: 'Parity matrix registry capability IDs must remain live. '
          'Stale:\n${stale.join('\n')}',
    );
  });
}
