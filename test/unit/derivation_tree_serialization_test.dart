import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/derivation_tree.dart';
import 'package:turing_lab/core/models/derivation_tree_node.dart';

void main() {
  test('derivation trees keep their normalized JSON shape and round-trip', () {
    const tree = DerivationTree(
      root: DerivationTreeNode(
        symbol: 'S',
        children: [
          DerivationTreeNode(symbol: 'a', lexeme: 'a', start: 0, end: 1),
        ],
      ),
    );

    expect(tree.toJson(), <String, dynamic>{
      'root': <String, dynamic>{
        'symbol': 'S',
        'children': <Map<String, dynamic>>[
          <String, dynamic>{
            'symbol': 'a',
            'children': <dynamic>[],
            'lexeme': 'a',
            'start': 0,
            'end': 1,
          },
        ],
      },
      'isShallow': false,
    });
    expect(DerivationTree.fromJson(tree.toJson()), tree);
  });

  test('derivation nodes still accept legacy explicit null fields', () {
    final node = DerivationTreeNode.fromJson(<String, dynamic>{
      'symbol': 'S',
      'children': <dynamic>[],
      'lexeme': null,
      'start': null,
      'end': null,
    });

    expect(node, const DerivationTreeNode(symbol: 'S'));
  });
}
