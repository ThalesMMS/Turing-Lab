// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'grammar_transformation_step.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GrammarTransformationStep {

 String get id; String get operation; String get rationale; Grammar get before; Grammar get after; Set<String> get changedSymbols; Set<String> get changedProductionIds;
/// Create a copy of GrammarTransformationStep
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GrammarTransformationStepCopyWith<GrammarTransformationStep> get copyWith => _$GrammarTransformationStepCopyWithImpl<GrammarTransformationStep>(this as GrammarTransformationStep, _$identity);

  /// Serializes this GrammarTransformationStep to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GrammarTransformationStep&&(identical(other.id, id) || other.id == id)&&(identical(other.operation, operation) || other.operation == operation)&&(identical(other.rationale, rationale) || other.rationale == rationale)&&(identical(other.before, before) || other.before == before)&&(identical(other.after, after) || other.after == after)&&const DeepCollectionEquality().equals(other.changedSymbols, changedSymbols)&&const DeepCollectionEquality().equals(other.changedProductionIds, changedProductionIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,operation,rationale,before,after,const DeepCollectionEquality().hash(changedSymbols),const DeepCollectionEquality().hash(changedProductionIds));

@override
String toString() {
  return 'GrammarTransformationStep(id: $id, operation: $operation, rationale: $rationale, before: $before, after: $after, changedSymbols: $changedSymbols, changedProductionIds: $changedProductionIds)';
}


}

/// @nodoc
abstract mixin class $GrammarTransformationStepCopyWith<$Res>  {
  factory $GrammarTransformationStepCopyWith(GrammarTransformationStep value, $Res Function(GrammarTransformationStep) _then) = _$GrammarTransformationStepCopyWithImpl;
@useResult
$Res call({
 String id, String operation, String rationale, Grammar before, Grammar after, Set<String> changedSymbols, Set<String> changedProductionIds
});




}
/// @nodoc
class _$GrammarTransformationStepCopyWithImpl<$Res>
    implements $GrammarTransformationStepCopyWith<$Res> {
  _$GrammarTransformationStepCopyWithImpl(this._self, this._then);

  final GrammarTransformationStep _self;
  final $Res Function(GrammarTransformationStep) _then;

/// Create a copy of GrammarTransformationStep
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? operation = null,Object? rationale = null,Object? before = null,Object? after = null,Object? changedSymbols = null,Object? changedProductionIds = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,operation: null == operation ? _self.operation : operation // ignore: cast_nullable_to_non_nullable
as String,rationale: null == rationale ? _self.rationale : rationale // ignore: cast_nullable_to_non_nullable
as String,before: null == before ? _self.before : before // ignore: cast_nullable_to_non_nullable
as Grammar,after: null == after ? _self.after : after // ignore: cast_nullable_to_non_nullable
as Grammar,changedSymbols: null == changedSymbols ? _self.changedSymbols : changedSymbols // ignore: cast_nullable_to_non_nullable
as Set<String>,changedProductionIds: null == changedProductionIds ? _self.changedProductionIds : changedProductionIds // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [GrammarTransformationStep].
extension GrammarTransformationStepPatterns on GrammarTransformationStep {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GrammarTransformationStep value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GrammarTransformationStep() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GrammarTransformationStep value)  $default,){
final _that = this;
switch (_that) {
case _GrammarTransformationStep():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GrammarTransformationStep value)?  $default,){
final _that = this;
switch (_that) {
case _GrammarTransformationStep() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String operation,  String rationale,  Grammar before,  Grammar after,  Set<String> changedSymbols,  Set<String> changedProductionIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GrammarTransformationStep() when $default != null:
return $default(_that.id,_that.operation,_that.rationale,_that.before,_that.after,_that.changedSymbols,_that.changedProductionIds);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String operation,  String rationale,  Grammar before,  Grammar after,  Set<String> changedSymbols,  Set<String> changedProductionIds)  $default,) {final _that = this;
switch (_that) {
case _GrammarTransformationStep():
return $default(_that.id,_that.operation,_that.rationale,_that.before,_that.after,_that.changedSymbols,_that.changedProductionIds);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String operation,  String rationale,  Grammar before,  Grammar after,  Set<String> changedSymbols,  Set<String> changedProductionIds)?  $default,) {final _that = this;
switch (_that) {
case _GrammarTransformationStep() when $default != null:
return $default(_that.id,_that.operation,_that.rationale,_that.before,_that.after,_that.changedSymbols,_that.changedProductionIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GrammarTransformationStep extends GrammarTransformationStep {
  const _GrammarTransformationStep({required this.id, required this.operation, required this.rationale, required this.before, required this.after, final  Set<String> changedSymbols = const <String>{}, final  Set<String> changedProductionIds = const <String>{}}): _changedSymbols = changedSymbols,_changedProductionIds = changedProductionIds,super._();
  factory _GrammarTransformationStep.fromJson(Map<String, dynamic> json) => _$GrammarTransformationStepFromJson(json);

@override final  String id;
@override final  String operation;
@override final  String rationale;
@override final  Grammar before;
@override final  Grammar after;
 final  Set<String> _changedSymbols;
@override@JsonKey() Set<String> get changedSymbols {
  if (_changedSymbols is EqualUnmodifiableSetView) return _changedSymbols;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_changedSymbols);
}

 final  Set<String> _changedProductionIds;
@override@JsonKey() Set<String> get changedProductionIds {
  if (_changedProductionIds is EqualUnmodifiableSetView) return _changedProductionIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_changedProductionIds);
}


/// Create a copy of GrammarTransformationStep
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GrammarTransformationStepCopyWith<_GrammarTransformationStep> get copyWith => __$GrammarTransformationStepCopyWithImpl<_GrammarTransformationStep>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GrammarTransformationStepToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GrammarTransformationStep&&(identical(other.id, id) || other.id == id)&&(identical(other.operation, operation) || other.operation == operation)&&(identical(other.rationale, rationale) || other.rationale == rationale)&&(identical(other.before, before) || other.before == before)&&(identical(other.after, after) || other.after == after)&&const DeepCollectionEquality().equals(other._changedSymbols, _changedSymbols)&&const DeepCollectionEquality().equals(other._changedProductionIds, _changedProductionIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,operation,rationale,before,after,const DeepCollectionEquality().hash(_changedSymbols),const DeepCollectionEquality().hash(_changedProductionIds));

@override
String toString() {
  return 'GrammarTransformationStep(id: $id, operation: $operation, rationale: $rationale, before: $before, after: $after, changedSymbols: $changedSymbols, changedProductionIds: $changedProductionIds)';
}


}

/// @nodoc
abstract mixin class _$GrammarTransformationStepCopyWith<$Res> implements $GrammarTransformationStepCopyWith<$Res> {
  factory _$GrammarTransformationStepCopyWith(_GrammarTransformationStep value, $Res Function(_GrammarTransformationStep) _then) = __$GrammarTransformationStepCopyWithImpl;
@override @useResult
$Res call({
 String id, String operation, String rationale, Grammar before, Grammar after, Set<String> changedSymbols, Set<String> changedProductionIds
});




}
/// @nodoc
class __$GrammarTransformationStepCopyWithImpl<$Res>
    implements _$GrammarTransformationStepCopyWith<$Res> {
  __$GrammarTransformationStepCopyWithImpl(this._self, this._then);

  final _GrammarTransformationStep _self;
  final $Res Function(_GrammarTransformationStep) _then;

/// Create a copy of GrammarTransformationStep
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? operation = null,Object? rationale = null,Object? before = null,Object? after = null,Object? changedSymbols = null,Object? changedProductionIds = null,}) {
  return _then(_GrammarTransformationStep(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,operation: null == operation ? _self.operation : operation // ignore: cast_nullable_to_non_nullable
as String,rationale: null == rationale ? _self.rationale : rationale // ignore: cast_nullable_to_non_nullable
as String,before: null == before ? _self.before : before // ignore: cast_nullable_to_non_nullable
as Grammar,after: null == after ? _self.after : after // ignore: cast_nullable_to_non_nullable
as Grammar,changedSymbols: null == changedSymbols ? _self._changedSymbols : changedSymbols // ignore: cast_nullable_to_non_nullable
as Set<String>,changedProductionIds: null == changedProductionIds ? _self._changedProductionIds : changedProductionIds // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}


}

// dart format on
