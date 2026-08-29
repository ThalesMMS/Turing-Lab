// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'grammar_gnf_transformation_report.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GrammarGnfTransformationReport {

 Grammar get grammar; List<GrammarTransformationStep> get steps; List<GrammarGnfStructuredTransformationStep> get structuredSteps; List<GrammarDiagnostic> get diagnostics;
/// Create a copy of GrammarGnfTransformationReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GrammarGnfTransformationReportCopyWith<GrammarGnfTransformationReport> get copyWith => _$GrammarGnfTransformationReportCopyWithImpl<GrammarGnfTransformationReport>(this as GrammarGnfTransformationReport, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GrammarGnfTransformationReport&&(identical(other.grammar, grammar) || other.grammar == grammar)&&const DeepCollectionEquality().equals(other.steps, steps)&&const DeepCollectionEquality().equals(other.structuredSteps, structuredSteps)&&const DeepCollectionEquality().equals(other.diagnostics, diagnostics));
}


@override
int get hashCode => Object.hash(runtimeType,grammar,const DeepCollectionEquality().hash(steps),const DeepCollectionEquality().hash(structuredSteps),const DeepCollectionEquality().hash(diagnostics));

@override
String toString() {
  return 'GrammarGnfTransformationReport(grammar: $grammar, steps: $steps, structuredSteps: $structuredSteps, diagnostics: $diagnostics)';
}


}

/// @nodoc
abstract mixin class $GrammarGnfTransformationReportCopyWith<$Res>  {
  factory $GrammarGnfTransformationReportCopyWith(GrammarGnfTransformationReport value, $Res Function(GrammarGnfTransformationReport) _then) = _$GrammarGnfTransformationReportCopyWithImpl;
@useResult
$Res call({
 Grammar grammar, List<GrammarTransformationStep> steps, List<GrammarGnfStructuredTransformationStep> structuredSteps, List<GrammarDiagnostic> diagnostics
});




}
/// @nodoc
class _$GrammarGnfTransformationReportCopyWithImpl<$Res>
    implements $GrammarGnfTransformationReportCopyWith<$Res> {
  _$GrammarGnfTransformationReportCopyWithImpl(this._self, this._then);

  final GrammarGnfTransformationReport _self;
  final $Res Function(GrammarGnfTransformationReport) _then;

/// Create a copy of GrammarGnfTransformationReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? grammar = null,Object? steps = null,Object? structuredSteps = null,Object? diagnostics = null,}) {
  return _then(_self.copyWith(
grammar: null == grammar ? _self.grammar : grammar // ignore: cast_nullable_to_non_nullable
as Grammar,steps: null == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as List<GrammarTransformationStep>,structuredSteps: null == structuredSteps ? _self.structuredSteps : structuredSteps // ignore: cast_nullable_to_non_nullable
as List<GrammarGnfStructuredTransformationStep>,diagnostics: null == diagnostics ? _self.diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<GrammarDiagnostic>,
  ));
}

}


/// Adds pattern-matching-related methods to [GrammarGnfTransformationReport].
extension GrammarGnfTransformationReportPatterns on GrammarGnfTransformationReport {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GrammarGnfTransformationReport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GrammarGnfTransformationReport() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GrammarGnfTransformationReport value)  $default,){
final _that = this;
switch (_that) {
case _GrammarGnfTransformationReport():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GrammarGnfTransformationReport value)?  $default,){
final _that = this;
switch (_that) {
case _GrammarGnfTransformationReport() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Grammar grammar,  List<GrammarTransformationStep> steps,  List<GrammarGnfStructuredTransformationStep> structuredSteps,  List<GrammarDiagnostic> diagnostics)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GrammarGnfTransformationReport() when $default != null:
return $default(_that.grammar,_that.steps,_that.structuredSteps,_that.diagnostics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Grammar grammar,  List<GrammarTransformationStep> steps,  List<GrammarGnfStructuredTransformationStep> structuredSteps,  List<GrammarDiagnostic> diagnostics)  $default,) {final _that = this;
switch (_that) {
case _GrammarGnfTransformationReport():
return $default(_that.grammar,_that.steps,_that.structuredSteps,_that.diagnostics);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Grammar grammar,  List<GrammarTransformationStep> steps,  List<GrammarGnfStructuredTransformationStep> structuredSteps,  List<GrammarDiagnostic> diagnostics)?  $default,) {final _that = this;
switch (_that) {
case _GrammarGnfTransformationReport() when $default != null:
return $default(_that.grammar,_that.steps,_that.structuredSteps,_that.diagnostics);case _:
  return null;

}
}

}

/// @nodoc


class _GrammarGnfTransformationReport implements GrammarGnfTransformationReport {
  const _GrammarGnfTransformationReport({required this.grammar, required final  List<GrammarTransformationStep> steps, final  List<GrammarGnfStructuredTransformationStep> structuredSteps = const <GrammarGnfStructuredTransformationStep>[], required final  List<GrammarDiagnostic> diagnostics}): _steps = steps,_structuredSteps = structuredSteps,_diagnostics = diagnostics;


@override final  Grammar grammar;
 final  List<GrammarTransformationStep> _steps;
@override List<GrammarTransformationStep> get steps {
  if (_steps is EqualUnmodifiableListView) return _steps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_steps);
}

 final  List<GrammarGnfStructuredTransformationStep> _structuredSteps;
@override@JsonKey() List<GrammarGnfStructuredTransformationStep> get structuredSteps {
  if (_structuredSteps is EqualUnmodifiableListView) return _structuredSteps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_structuredSteps);
}

 final  List<GrammarDiagnostic> _diagnostics;
@override List<GrammarDiagnostic> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}


/// Create a copy of GrammarGnfTransformationReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GrammarGnfTransformationReportCopyWith<_GrammarGnfTransformationReport> get copyWith => __$GrammarGnfTransformationReportCopyWithImpl<_GrammarGnfTransformationReport>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GrammarGnfTransformationReport&&(identical(other.grammar, grammar) || other.grammar == grammar)&&const DeepCollectionEquality().equals(other._steps, _steps)&&const DeepCollectionEquality().equals(other._structuredSteps, _structuredSteps)&&const DeepCollectionEquality().equals(other._diagnostics, _diagnostics));
}


@override
int get hashCode => Object.hash(runtimeType,grammar,const DeepCollectionEquality().hash(_steps),const DeepCollectionEquality().hash(_structuredSteps),const DeepCollectionEquality().hash(_diagnostics));

@override
String toString() {
  return 'GrammarGnfTransformationReport(grammar: $grammar, steps: $steps, structuredSteps: $structuredSteps, diagnostics: $diagnostics)';
}


}

/// @nodoc
abstract mixin class _$GrammarGnfTransformationReportCopyWith<$Res> implements $GrammarGnfTransformationReportCopyWith<$Res> {
  factory _$GrammarGnfTransformationReportCopyWith(_GrammarGnfTransformationReport value, $Res Function(_GrammarGnfTransformationReport) _then) = __$GrammarGnfTransformationReportCopyWithImpl;
@override @useResult
$Res call({
 Grammar grammar, List<GrammarTransformationStep> steps, List<GrammarGnfStructuredTransformationStep> structuredSteps, List<GrammarDiagnostic> diagnostics
});




}
/// @nodoc
class __$GrammarGnfTransformationReportCopyWithImpl<$Res>
    implements _$GrammarGnfTransformationReportCopyWith<$Res> {
  __$GrammarGnfTransformationReportCopyWithImpl(this._self, this._then);

  final _GrammarGnfTransformationReport _self;
  final $Res Function(_GrammarGnfTransformationReport) _then;

/// Create a copy of GrammarGnfTransformationReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? grammar = null,Object? steps = null,Object? structuredSteps = null,Object? diagnostics = null,}) {
  return _then(_GrammarGnfTransformationReport(
grammar: null == grammar ? _self.grammar : grammar // ignore: cast_nullable_to_non_nullable
as Grammar,steps: null == steps ? _self._steps : steps // ignore: cast_nullable_to_non_nullable
as List<GrammarTransformationStep>,structuredSteps: null == structuredSteps ? _self._structuredSteps : structuredSteps // ignore: cast_nullable_to_non_nullable
as List<GrammarGnfStructuredTransformationStep>,diagnostics: null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<GrammarDiagnostic>,
  ));
}


}

// dart format on
