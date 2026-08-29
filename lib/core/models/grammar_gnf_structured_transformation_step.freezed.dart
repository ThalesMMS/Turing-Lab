// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'grammar_gnf_structured_transformation_step.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GrammarGnfStructuredTransformationStep {

 GrammarTransformationStep get legacyStep; StructuredMessage get operationMessage; StructuredMessage get rationaleMessage;
/// Create a copy of GrammarGnfStructuredTransformationStep
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GrammarGnfStructuredTransformationStepCopyWith<GrammarGnfStructuredTransformationStep> get copyWith => _$GrammarGnfStructuredTransformationStepCopyWithImpl<GrammarGnfStructuredTransformationStep>(this as GrammarGnfStructuredTransformationStep, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GrammarGnfStructuredTransformationStep&&(identical(other.legacyStep, legacyStep) || other.legacyStep == legacyStep)&&(identical(other.operationMessage, operationMessage) || other.operationMessage == operationMessage)&&(identical(other.rationaleMessage, rationaleMessage) || other.rationaleMessage == rationaleMessage));
}


@override
int get hashCode => Object.hash(runtimeType,legacyStep,operationMessage,rationaleMessage);

@override
String toString() {
  return 'GrammarGnfStructuredTransformationStep(legacyStep: $legacyStep, operationMessage: $operationMessage, rationaleMessage: $rationaleMessage)';
}


}

/// @nodoc
abstract mixin class $GrammarGnfStructuredTransformationStepCopyWith<$Res>  {
  factory $GrammarGnfStructuredTransformationStepCopyWith(GrammarGnfStructuredTransformationStep value, $Res Function(GrammarGnfStructuredTransformationStep) _then) = _$GrammarGnfStructuredTransformationStepCopyWithImpl;
@useResult
$Res call({
 GrammarTransformationStep legacyStep, StructuredMessage operationMessage, StructuredMessage rationaleMessage
});


$GrammarTransformationStepCopyWith<$Res> get legacyStep;

}
/// @nodoc
class _$GrammarGnfStructuredTransformationStepCopyWithImpl<$Res>
    implements $GrammarGnfStructuredTransformationStepCopyWith<$Res> {
  _$GrammarGnfStructuredTransformationStepCopyWithImpl(this._self, this._then);

  final GrammarGnfStructuredTransformationStep _self;
  final $Res Function(GrammarGnfStructuredTransformationStep) _then;

/// Create a copy of GrammarGnfStructuredTransformationStep
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? legacyStep = null,Object? operationMessage = null,Object? rationaleMessage = null,}) {
  return _then(_self.copyWith(
legacyStep: null == legacyStep ? _self.legacyStep : legacyStep // ignore: cast_nullable_to_non_nullable
as GrammarTransformationStep,operationMessage: null == operationMessage ? _self.operationMessage : operationMessage // ignore: cast_nullable_to_non_nullable
as StructuredMessage,rationaleMessage: null == rationaleMessage ? _self.rationaleMessage : rationaleMessage // ignore: cast_nullable_to_non_nullable
as StructuredMessage,
  ));
}
/// Create a copy of GrammarGnfStructuredTransformationStep
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GrammarTransformationStepCopyWith<$Res> get legacyStep {

  return $GrammarTransformationStepCopyWith<$Res>(_self.legacyStep, (value) {
    return _then(_self.copyWith(legacyStep: value));
  });
}
}


/// Adds pattern-matching-related methods to [GrammarGnfStructuredTransformationStep].
extension GrammarGnfStructuredTransformationStepPatterns on GrammarGnfStructuredTransformationStep {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GrammarGnfStructuredTransformationStep value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GrammarGnfStructuredTransformationStep() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GrammarGnfStructuredTransformationStep value)  $default,){
final _that = this;
switch (_that) {
case _GrammarGnfStructuredTransformationStep():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GrammarGnfStructuredTransformationStep value)?  $default,){
final _that = this;
switch (_that) {
case _GrammarGnfStructuredTransformationStep() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GrammarTransformationStep legacyStep,  StructuredMessage operationMessage,  StructuredMessage rationaleMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GrammarGnfStructuredTransformationStep() when $default != null:
return $default(_that.legacyStep,_that.operationMessage,_that.rationaleMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GrammarTransformationStep legacyStep,  StructuredMessage operationMessage,  StructuredMessage rationaleMessage)  $default,) {final _that = this;
switch (_that) {
case _GrammarGnfStructuredTransformationStep():
return $default(_that.legacyStep,_that.operationMessage,_that.rationaleMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GrammarTransformationStep legacyStep,  StructuredMessage operationMessage,  StructuredMessage rationaleMessage)?  $default,) {final _that = this;
switch (_that) {
case _GrammarGnfStructuredTransformationStep() when $default != null:
return $default(_that.legacyStep,_that.operationMessage,_that.rationaleMessage);case _:
  return null;

}
}

}

/// @nodoc


class _GrammarGnfStructuredTransformationStep extends GrammarGnfStructuredTransformationStep {
  const _GrammarGnfStructuredTransformationStep({required this.legacyStep, required this.operationMessage, required this.rationaleMessage}): super._();


@override final  GrammarTransformationStep legacyStep;
@override final  StructuredMessage operationMessage;
@override final  StructuredMessage rationaleMessage;

/// Create a copy of GrammarGnfStructuredTransformationStep
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GrammarGnfStructuredTransformationStepCopyWith<_GrammarGnfStructuredTransformationStep> get copyWith => __$GrammarGnfStructuredTransformationStepCopyWithImpl<_GrammarGnfStructuredTransformationStep>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GrammarGnfStructuredTransformationStep&&(identical(other.legacyStep, legacyStep) || other.legacyStep == legacyStep)&&(identical(other.operationMessage, operationMessage) || other.operationMessage == operationMessage)&&(identical(other.rationaleMessage, rationaleMessage) || other.rationaleMessage == rationaleMessage));
}


@override
int get hashCode => Object.hash(runtimeType,legacyStep,operationMessage,rationaleMessage);

@override
String toString() {
  return 'GrammarGnfStructuredTransformationStep(legacyStep: $legacyStep, operationMessage: $operationMessage, rationaleMessage: $rationaleMessage)';
}


}

/// @nodoc
abstract mixin class _$GrammarGnfStructuredTransformationStepCopyWith<$Res> implements $GrammarGnfStructuredTransformationStepCopyWith<$Res> {
  factory _$GrammarGnfStructuredTransformationStepCopyWith(_GrammarGnfStructuredTransformationStep value, $Res Function(_GrammarGnfStructuredTransformationStep) _then) = __$GrammarGnfStructuredTransformationStepCopyWithImpl;
@override @useResult
$Res call({
 GrammarTransformationStep legacyStep, StructuredMessage operationMessage, StructuredMessage rationaleMessage
});


@override $GrammarTransformationStepCopyWith<$Res> get legacyStep;

}
/// @nodoc
class __$GrammarGnfStructuredTransformationStepCopyWithImpl<$Res>
    implements _$GrammarGnfStructuredTransformationStepCopyWith<$Res> {
  __$GrammarGnfStructuredTransformationStepCopyWithImpl(this._self, this._then);

  final _GrammarGnfStructuredTransformationStep _self;
  final $Res Function(_GrammarGnfStructuredTransformationStep) _then;

/// Create a copy of GrammarGnfStructuredTransformationStep
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? legacyStep = null,Object? operationMessage = null,Object? rationaleMessage = null,}) {
  return _then(_GrammarGnfStructuredTransformationStep(
legacyStep: null == legacyStep ? _self.legacyStep : legacyStep // ignore: cast_nullable_to_non_nullable
as GrammarTransformationStep,operationMessage: null == operationMessage ? _self.operationMessage : operationMessage // ignore: cast_nullable_to_non_nullable
as StructuredMessage,rationaleMessage: null == rationaleMessage ? _self.rationaleMessage : rationaleMessage // ignore: cast_nullable_to_non_nullable
as StructuredMessage,
  ));
}

/// Create a copy of GrammarGnfStructuredTransformationStep
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GrammarTransformationStepCopyWith<$Res> get legacyStep {

  return $GrammarTransformationStepCopyWith<$Res>(_self.legacyStep, (value) {
    return _then(_self.copyWith(legacyStep: value));
  });
}
}

// dart format on
