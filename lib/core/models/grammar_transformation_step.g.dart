// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grammar_transformation_step.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GrammarTransformationStep _$GrammarTransformationStepFromJson(Map json) =>
    _GrammarTransformationStep(
      id: json['id'] as String,
      operation: json['operation'] as String,
      rationale: json['rationale'] as String,
      before: Grammar.fromJson(
        Map<String, dynamic>.from(json['before'] as Map),
      ),
      after: Grammar.fromJson(Map<String, dynamic>.from(json['after'] as Map)),
      changedSymbols:
          (json['changedSymbols'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          const <String>{},
      changedProductionIds:
          (json['changedProductionIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          const <String>{},
    );

Map<String, dynamic> _$GrammarTransformationStepToJson(
  _GrammarTransformationStep instance,
) => <String, dynamic>{
  'id': instance.id,
  'operation': instance.operation,
  'rationale': instance.rationale,
  'before': instance.before.toJson(),
  'after': instance.after.toJson(),
  'changedSymbols': instance.changedSymbols.toList(),
  'changedProductionIds': instance.changedProductionIds.toList(),
};
