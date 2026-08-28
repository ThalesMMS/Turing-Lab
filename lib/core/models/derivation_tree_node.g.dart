// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'derivation_tree_node.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DerivationTreeNode _$DerivationTreeNodeFromJson(Map json) =>
    _DerivationTreeNode(
      symbol: json['symbol'] as String,
      children:
          (json['children'] as List<dynamic>?)
              ?.map(
                (e) => DerivationTreeNode.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList() ??
          const <DerivationTreeNode>[],
      lexeme: json['lexeme'] as String?,
      start: (json['start'] as num?)?.toInt(),
      end: (json['end'] as num?)?.toInt(),
    );

Map<String, dynamic> _$DerivationTreeNodeToJson(_DerivationTreeNode instance) =>
    <String, dynamic>{
      'symbol': instance.symbol,
      'children': instance.children.map((e) => e.toJson()).toList(),
      'lexeme': ?instance.lexeme,
      'start': ?instance.start,
      'end': ?instance.end,
    };
