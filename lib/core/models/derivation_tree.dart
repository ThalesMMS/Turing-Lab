//
//  derivation_tree.dart
//  Turing Lab
//
//  Lightweight derivation/parse tree wrapper.
//

import 'package:freezed_annotation/freezed_annotation.dart';

import 'derivation_tree_node.dart';

part 'derivation_tree.freezed.dart';
part 'derivation_tree.g.dart';

@freezed
abstract class DerivationTree with _$DerivationTree {
  const DerivationTree._();

  const factory DerivationTree({
    required DerivationTreeNode root,
    @Default(false) bool isShallow,
  }) = _DerivationTree;

  factory DerivationTree.fromJson(Map<String, dynamic> json) =>
      _$DerivationTreeFromJson(json);

  String prettyPrint() => root.prettyPrint();
}
