import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/core/constants/help_catalog.dart';
import 'package:turing_lab/presentation/widgets/help_icon_mapper.dart';

void main() {
  test('every catalog icon name resolves without a silent Help fallback', () {
    for (final node in kHelpCatalog.nodes) {
      final icon = helpIconData(node.icon);

      if (node.icon == 'help_outline') {
        expect(icon, Icons.help_outline, reason: node.id);
      } else {
        expect(icon, isNot(Icons.help_outline), reason: node.id);
      }
    }
  });

  test('unknown icon names fail explicitly', () {
    expect(
      () => helpIconData('not-a-catalog-icon'),
      throwsA(isA<ArgumentError>()),
    );
  });
}
