// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'derivation_tree.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DerivationTree _$DerivationTreeFromJson(Map json) => _DerivationTree(
  root: DerivationTreeNode.fromJson(
    Map<String, dynamic>.from(json['root'] as Map),
  ),
  isShallow: json['isShallow'] as bool? ?? false,
);

Map<String, dynamic> _$DerivationTreeToJson(_DerivationTree instance) =>
    <String, dynamic>{
      'root': instance.root.toJson(),
      'isShallow': instance.isShallow,
    };
