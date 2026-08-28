// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SettingsModel {

/// Theme mode preference (system, light, dark).
 String get themeMode;/// Explicit app language (en or pt), or null to use automatic resolution.
///
/// These language-only values are kept for persisted-data compatibility.
 String? get localeCode;/// Whether to display the grid on the canvas.
 bool get showGrid;/// Whether to display coordinates on the canvas.
 bool get showCoordinates;/// Whether autosave is enabled.
 bool get autoSave;/// Whether to display tooltips.
 bool get showTooltips;/// Size of the grid in logical pixels.
 double get gridSize;/// Size of nodes in logical pixels.
 double get nodeSize;/// Base font size in the interface.
 double get fontSize;/// Animation speed multiplier (1.0 = normal, 0.5 = slow, 2.0 = fast).
 double get animationSpeed;
/// Create a copy of SettingsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsModelCopyWith<SettingsModel> get copyWith => _$SettingsModelCopyWithImpl<SettingsModel>(this as SettingsModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsModel&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.localeCode, localeCode) || other.localeCode == localeCode)&&(identical(other.showGrid, showGrid) || other.showGrid == showGrid)&&(identical(other.showCoordinates, showCoordinates) || other.showCoordinates == showCoordinates)&&(identical(other.autoSave, autoSave) || other.autoSave == autoSave)&&(identical(other.showTooltips, showTooltips) || other.showTooltips == showTooltips)&&(identical(other.gridSize, gridSize) || other.gridSize == gridSize)&&(identical(other.nodeSize, nodeSize) || other.nodeSize == nodeSize)&&(identical(other.fontSize, fontSize) || other.fontSize == fontSize)&&(identical(other.animationSpeed, animationSpeed) || other.animationSpeed == animationSpeed));
}


@override
int get hashCode => Object.hash(runtimeType,themeMode,localeCode,showGrid,showCoordinates,autoSave,showTooltips,gridSize,nodeSize,fontSize,animationSpeed);

@override
String toString() {
  return 'SettingsModel(themeMode: $themeMode, localeCode: $localeCode, showGrid: $showGrid, showCoordinates: $showCoordinates, autoSave: $autoSave, showTooltips: $showTooltips, gridSize: $gridSize, nodeSize: $nodeSize, fontSize: $fontSize, animationSpeed: $animationSpeed)';
}


}

/// @nodoc
abstract mixin class $SettingsModelCopyWith<$Res>  {
  factory $SettingsModelCopyWith(SettingsModel value, $Res Function(SettingsModel) _then) = _$SettingsModelCopyWithImpl;
@useResult
$Res call({
 String themeMode, String? localeCode, bool showGrid, bool showCoordinates, bool autoSave, bool showTooltips, double gridSize, double nodeSize, double fontSize, double animationSpeed
});




}
/// @nodoc
class _$SettingsModelCopyWithImpl<$Res>
    implements $SettingsModelCopyWith<$Res> {
  _$SettingsModelCopyWithImpl(this._self, this._then);

  final SettingsModel _self;
  final $Res Function(SettingsModel) _then;

/// Create a copy of SettingsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? themeMode = null,Object? localeCode = freezed,Object? showGrid = null,Object? showCoordinates = null,Object? autoSave = null,Object? showTooltips = null,Object? gridSize = null,Object? nodeSize = null,Object? fontSize = null,Object? animationSpeed = null,}) {
  return _then(_self.copyWith(
themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as String,localeCode: freezed == localeCode ? _self.localeCode : localeCode // ignore: cast_nullable_to_non_nullable
as String?,showGrid: null == showGrid ? _self.showGrid : showGrid // ignore: cast_nullable_to_non_nullable
as bool,showCoordinates: null == showCoordinates ? _self.showCoordinates : showCoordinates // ignore: cast_nullable_to_non_nullable
as bool,autoSave: null == autoSave ? _self.autoSave : autoSave // ignore: cast_nullable_to_non_nullable
as bool,showTooltips: null == showTooltips ? _self.showTooltips : showTooltips // ignore: cast_nullable_to_non_nullable
as bool,gridSize: null == gridSize ? _self.gridSize : gridSize // ignore: cast_nullable_to_non_nullable
as double,nodeSize: null == nodeSize ? _self.nodeSize : nodeSize // ignore: cast_nullable_to_non_nullable
as double,fontSize: null == fontSize ? _self.fontSize : fontSize // ignore: cast_nullable_to_non_nullable
as double,animationSpeed: null == animationSpeed ? _self.animationSpeed : animationSpeed // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [SettingsModel].
extension SettingsModelPatterns on SettingsModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SettingsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SettingsModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SettingsModel value)  $default,){
final _that = this;
switch (_that) {
case _SettingsModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SettingsModel value)?  $default,){
final _that = this;
switch (_that) {
case _SettingsModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String themeMode,  String? localeCode,  bool showGrid,  bool showCoordinates,  bool autoSave,  bool showTooltips,  double gridSize,  double nodeSize,  double fontSize,  double animationSpeed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SettingsModel() when $default != null:
return $default(_that.themeMode,_that.localeCode,_that.showGrid,_that.showCoordinates,_that.autoSave,_that.showTooltips,_that.gridSize,_that.nodeSize,_that.fontSize,_that.animationSpeed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String themeMode,  String? localeCode,  bool showGrid,  bool showCoordinates,  bool autoSave,  bool showTooltips,  double gridSize,  double nodeSize,  double fontSize,  double animationSpeed)  $default,) {final _that = this;
switch (_that) {
case _SettingsModel():
return $default(_that.themeMode,_that.localeCode,_that.showGrid,_that.showCoordinates,_that.autoSave,_that.showTooltips,_that.gridSize,_that.nodeSize,_that.fontSize,_that.animationSpeed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String themeMode,  String? localeCode,  bool showGrid,  bool showCoordinates,  bool autoSave,  bool showTooltips,  double gridSize,  double nodeSize,  double fontSize,  double animationSpeed)?  $default,) {final _that = this;
switch (_that) {
case _SettingsModel() when $default != null:
return $default(_that.themeMode,_that.localeCode,_that.showGrid,_that.showCoordinates,_that.autoSave,_that.showTooltips,_that.gridSize,_that.nodeSize,_that.fontSize,_that.animationSpeed);case _:
  return null;

}
}

}

/// @nodoc


class _SettingsModel implements SettingsModel {
  const _SettingsModel({this.themeMode = 'light', this.localeCode, this.showGrid = true, this.showCoordinates = false, this.autoSave = true, this.showTooltips = true, this.gridSize = 20.0, this.nodeSize = 30.0, this.fontSize = 14.0, this.animationSpeed = 1.0});


/// Theme mode preference (system, light, dark).
@override@JsonKey() final  String themeMode;
/// Explicit app language (en or pt), or null to use automatic resolution.
///
/// These language-only values are kept for persisted-data compatibility.
@override final  String? localeCode;
/// Whether to display the grid on the canvas.
@override@JsonKey() final  bool showGrid;
/// Whether to display coordinates on the canvas.
@override@JsonKey() final  bool showCoordinates;
/// Whether autosave is enabled.
@override@JsonKey() final  bool autoSave;
/// Whether to display tooltips.
@override@JsonKey() final  bool showTooltips;
/// Size of the grid in logical pixels.
@override@JsonKey() final  double gridSize;
/// Size of nodes in logical pixels.
@override@JsonKey() final  double nodeSize;
/// Base font size in the interface.
@override@JsonKey() final  double fontSize;
/// Animation speed multiplier (1.0 = normal, 0.5 = slow, 2.0 = fast).
@override@JsonKey() final  double animationSpeed;

/// Create a copy of SettingsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SettingsModelCopyWith<_SettingsModel> get copyWith => __$SettingsModelCopyWithImpl<_SettingsModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SettingsModel&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.localeCode, localeCode) || other.localeCode == localeCode)&&(identical(other.showGrid, showGrid) || other.showGrid == showGrid)&&(identical(other.showCoordinates, showCoordinates) || other.showCoordinates == showCoordinates)&&(identical(other.autoSave, autoSave) || other.autoSave == autoSave)&&(identical(other.showTooltips, showTooltips) || other.showTooltips == showTooltips)&&(identical(other.gridSize, gridSize) || other.gridSize == gridSize)&&(identical(other.nodeSize, nodeSize) || other.nodeSize == nodeSize)&&(identical(other.fontSize, fontSize) || other.fontSize == fontSize)&&(identical(other.animationSpeed, animationSpeed) || other.animationSpeed == animationSpeed));
}


@override
int get hashCode => Object.hash(runtimeType,themeMode,localeCode,showGrid,showCoordinates,autoSave,showTooltips,gridSize,nodeSize,fontSize,animationSpeed);

@override
String toString() {
  return 'SettingsModel(themeMode: $themeMode, localeCode: $localeCode, showGrid: $showGrid, showCoordinates: $showCoordinates, autoSave: $autoSave, showTooltips: $showTooltips, gridSize: $gridSize, nodeSize: $nodeSize, fontSize: $fontSize, animationSpeed: $animationSpeed)';
}


}

/// @nodoc
abstract mixin class _$SettingsModelCopyWith<$Res> implements $SettingsModelCopyWith<$Res> {
  factory _$SettingsModelCopyWith(_SettingsModel value, $Res Function(_SettingsModel) _then) = __$SettingsModelCopyWithImpl;
@override @useResult
$Res call({
 String themeMode, String? localeCode, bool showGrid, bool showCoordinates, bool autoSave, bool showTooltips, double gridSize, double nodeSize, double fontSize, double animationSpeed
});




}
/// @nodoc
class __$SettingsModelCopyWithImpl<$Res>
    implements _$SettingsModelCopyWith<$Res> {
  __$SettingsModelCopyWithImpl(this._self, this._then);

  final _SettingsModel _self;
  final $Res Function(_SettingsModel) _then;

/// Create a copy of SettingsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? themeMode = null,Object? localeCode = freezed,Object? showGrid = null,Object? showCoordinates = null,Object? autoSave = null,Object? showTooltips = null,Object? gridSize = null,Object? nodeSize = null,Object? fontSize = null,Object? animationSpeed = null,}) {
  return _then(_SettingsModel(
themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as String,localeCode: freezed == localeCode ? _self.localeCode : localeCode // ignore: cast_nullable_to_non_nullable
as String?,showGrid: null == showGrid ? _self.showGrid : showGrid // ignore: cast_nullable_to_non_nullable
as bool,showCoordinates: null == showCoordinates ? _self.showCoordinates : showCoordinates // ignore: cast_nullable_to_non_nullable
as bool,autoSave: null == autoSave ? _self.autoSave : autoSave // ignore: cast_nullable_to_non_nullable
as bool,showTooltips: null == showTooltips ? _self.showTooltips : showTooltips // ignore: cast_nullable_to_non_nullable
as bool,gridSize: null == gridSize ? _self.gridSize : gridSize // ignore: cast_nullable_to_non_nullable
as double,nodeSize: null == nodeSize ? _self.nodeSize : nodeSize // ignore: cast_nullable_to_non_nullable
as double,fontSize: null == fontSize ? _self.fontSize : fontSize // ignore: cast_nullable_to_non_nullable
as double,animationSpeed: null == animationSpeed ? _self.animationSpeed : animationSpeed // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
