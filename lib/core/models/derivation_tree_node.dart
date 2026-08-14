//
//  derivation_tree_node.dart
//  Turing Lab
//
//  Lightweight derivation/parse tree node model used by grammar tooling.
//  Kept serializable/UI-friendly; terminal nodes may optionally carry a lexeme
//  and a span over the original input.
//
//  Added as part of the expanded grammar analysis & transformation toolkit.
//

import 'package:freezed_annotation/freezed_annotation.dart';

part 'derivation_tree_node.freezed.dart';
part 'derivation_tree_node.g.dart';

@freezed
abstract class DerivationTreeNode with _$DerivationTreeNode {
  const DerivationTreeNode._();

  const factory DerivationTreeNode({
    required String symbol,
    @Default(<DerivationTreeNode>[]) List<DerivationTreeNode> children,
    String? lexeme,
    int? start,
    int? end,
  }) = _DerivationTreeNode;

  bool get isLeaf => children.isEmpty;

  factory DerivationTreeNode.fromJson(Map<String, dynamic> json) =>
      _$DerivationTreeNodeFromJson(json);

  String prettyPrint({int indent = 0}) {
    final prefix = ' ' * indent;
    final buf = StringBuffer();
    buf.write(prefix);
    buf.write(symbol);
    if (lexeme != null) {
      buf.write('("$lexeme")');
    }
    if (start != null && end != null) {
      buf.write('[$start,$end)');
    }
    if (children.isEmpty) {
      return buf.toString();
    }
    for (final child in children) {
      buf.write('\n');
      buf.write(child.prettyPrint(indent: indent + 2));
    }
    return buf.toString();
  }
}
