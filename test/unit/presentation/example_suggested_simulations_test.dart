import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/presentation/content/asset_example_content_copy.dart';
import 'package:turing_lab/presentation/content/example_suggested_simulations.dart';
import 'package:turing_lab/presentation/content/tm_block_example_content_copy.dart';
import 'package:turing_lab/presentation/content/unrestricted_grammar_example_content_copy.dart';

void main() {
  test('covers every simulation-capable example and excludes L-Systems', () {
    const transducerIds = {
      'mealy.identity',
      'mealy.parity',
      'mealy.sequence-detector',
      'mealy.partial',
      'asset/moore_parity',
      'asset/moore_vending_control',
      'asset/moore_sequence_detector',
      'asset/moore_partial',
    };
    final expectedIds = {
      ...AssetExampleContentCopies.ids,
      ...UnrestrictedGrammarExampleContentCopies.ids,
      TMBlockExampleContentCopies.id,
      ...transducerIds,
    };

    expect(ExampleSuggestedSimulations.byExampleId.keys.toSet(), expectedIds);
    expect(
      ExampleSuggestedSimulations.byExampleId.keys,
      isNot(contains(startsWith('l-system'))),
    );
    for (final entry in ExampleSuggestedSimulations.byExampleId.entries) {
      expect(entry.value, isNotEmpty, reason: entry.key);
      expect(entry.value.toSet(), hasLength(entry.value.length));
      expect(entry.value.every((suggestion) => suggestion.isNotEmpty), isTrue);
    }
  });

  test('TM a^n b^n includes the required aaabbb suggestion', () {
    expect(
      ExampleSuggestedSimulations.resolve('asset/tm_anbn'),
      contains('aaabbb'),
    );
  });
}
