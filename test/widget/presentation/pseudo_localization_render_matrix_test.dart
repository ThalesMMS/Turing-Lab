import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../tool/localization/pseudo_localization_catalog.dart';

void main() {
  testWidgets(
    'full pseudo catalog renders a narrow high-scale control matrix in order',
    (tester) async {
      tester.view
        ..physicalSize = const Size(320, 700)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();

      final source =
          jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
              as Map<String, Object?>;
      final pseudo = PseudoLocalizationCatalog.transform(source);
      const messageKeys = <String>[
        'grammarAnalysisTitle',
        'inputString',
        'conversionReplaceTitle',
        'automatonLayoutButtonSemantics',
        'parseString',
        'clear',
        'close',
      ];
      final messages = <String, String>{
        for (final key in messageKeys) key: pseudo[key]! as String,
      };

      for (final key in messageKeys) {
        expect(messages[key], startsWith('⟦'));
        expect(messages[key], endsWith('⟧'));
        expect(
          messages[key]!.length,
          greaterThan((source[key]! as String).length),
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 700),
                textScaler: TextScaler.linear(2),
              ),
              child: SingleChildScrollView(
                key: const ValueKey('pseudo-scroll'),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      messages['grammarAnalysisTitle']!,
                      key: const ValueKey('pseudo-title'),
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      key: const ValueKey('pseudo-input'),
                      decoration: InputDecoration(
                        labelText: messages['inputString'],
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      key: const ValueKey('pseudo-list-tile'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(messages['conversionReplaceTitle']!),
                      subtitle: Text(
                        messages['automatonLayoutButtonSemantics']!,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const ValueKey('pseudo-primary-action'),
                      onPressed: () {},
                      child: Text(messages['parseString']!),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      key: const ValueKey('pseudo-secondary-action'),
                      onPressed: () {},
                      child: Text(messages['clear']!),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      key: const ValueKey('pseudo-last-action'),
                      onPressed: () {},
                      child: Text(messages['close']!),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final key in messageKeys) {
        expect(
          find.bySemanticsLabel(RegExp(RegExp.escape(messages[key]!))),
          findsWidgets,
        );
      }

      const orderedKeys = <ValueKey<String>>[
        ValueKey('pseudo-title'),
        ValueKey('pseudo-input'),
        ValueKey('pseudo-list-tile'),
        ValueKey('pseudo-primary-action'),
        ValueKey('pseudo-secondary-action'),
        ValueKey('pseudo-last-action'),
      ];
      final topPositions = <double>[];
      for (final key in orderedKeys) {
        final finder = find.byKey(key);
        expect(finder, findsOneWidget);
        final rect = tester.getRect(finder);
        expect(rect.width, lessThanOrEqualTo(288));
        topPositions.add(rect.top);
      }
      expect(topPositions, orderedEquals(topPositions.toList()..sort()));
      final lastAction = find.byKey(const ValueKey('pseudo-last-action'));
      await tester.ensureVisible(lastAction);
      await tester.pump();
      expect(lastAction.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );
}
