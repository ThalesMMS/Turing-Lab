// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'derivation_tree.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DerivationTree {

 DerivationTreeNode get root; bool get isShallow;
/// Create a copy of DerivationTree
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DerivationTreeCopyWith<DerivationTree> get copyWith => _$DerivationTreeCopyWithImpl<DerivationTree>(this as DerivationTree, _$identity);

  /// Serializes this DerivationTree to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DerivationTree&&(identical(other.root, root) || other.root == root)&&(identical(other.isShallow, isShallow) || other.isShallow == isShallow));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,root,isShallow);

@override
String toString() {
  return 'DerivationTree(root: $root, isShallow: $isShallow)';
}


}

/// @nodoc
abstract mixin class $DerivationTreeCopyWith<$Res>  {
  factory $DerivationTreeCopyWith(DerivationTree value, $Res Function(DerivationTree) _then) = _$DerivationTreeCopyWithImpl;
@useResult
$Res call({
 DerivationTreeNode root, bool isShallow
});


$DerivationTreeNodeCopyWith<$Res> get root;

}
/// @nodoc
class _$DerivationTreeCopyWithImpl<$Res>
    implements $DerivationTreeCopyWith<$Res> {
  _$DerivationTreeCopyWithImpl(this._self, this._then);

  final DerivationTree _self;
  final $Res Function(DerivationTree) _then;

/// Create a copy of DerivationTree
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? root = null,Object? isShallow = null,}) {
  return _then(_self.copyWith(
root: null == root ? _self.root : root // ignore: cast_nullable_to_non_nullable
as DerivationTreeNode,isShallow: null == isShallow ? _self.isShallow : isShallow // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of DerivationTree
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DerivationTreeNodeCopyWith<$Res> get root {

  return $DerivationTreeNodeCopyWith<$Res>(_self.root, (value) {
    return _then(_self.copyWith(root: value));
  });
}
}


/// Adds pattern-matching-related methods to [DerivationTree].
extension DerivationTreePatterns on DerivationTree {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DerivationTree value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DerivationTree() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DerivationTree value)  $default,){
final _that = this;
switch (_that) {
case _DerivationTree():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DerivationTree value)?  $default,){
final _that = this;
switch (_that) {
case _DerivationTree() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DerivationTreeNode root,  bool isShallow)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DerivationTree() when $default != null:
return $default(_that.root,_that.isShallow);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DerivationTreeNode root,  bool isShallow)  $default,) {final _that = this;
switch (_that) {
case _DerivationTree():
return $default(_that.root,_that.isShallow);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DerivationTreeNode root,  bool isShallow)?  $default,) {final _that = this;
switch (_that) {
case _DerivationTree() when $default != null:
return $default(_that.root,_that.isShallow);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DerivationTree extends DerivationTree {
  const _DerivationTree({required this.root, this.isShallow = false}): super._();
  factory _DerivationTree.fromJson(Map<String, dynamic> json) => _$DerivationTreeFromJson(json);

@override final  DerivationTreeNode root;
@override@JsonKey() final  bool isShallow;

/// Create a copy of DerivationTree
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DerivationTreeCopyWith<_DerivationTree> get copyWith => __$DerivationTreeCopyWithImpl<_DerivationTree>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DerivationTreeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DerivationTree&&(identical(other.root, root) || other.root == root)&&(identical(other.isShallow, isShallow) || other.isShallow == isShallow));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,root,isShallow);

@override
String toString() {
  return 'DerivationTree(root: $root, isShallow: $isShallow)';
}


}

/// @nodoc
abstract mixin class _$DerivationTreeCopyWith<$Res> implements $DerivationTreeCopyWith<$Res> {
  factory _$DerivationTreeCopyWith(_DerivationTree value, $Res Function(_DerivationTree) _then) = __$DerivationTreeCopyWithImpl;
@override @useResult
$Res call({
 DerivationTreeNode root, bool isShallow
});


@override $DerivationTreeNodeCopyWith<$Res> get root;

}
/// @nodoc
class __$DerivationTreeCopyWithImpl<$Res>
    implements _$DerivationTreeCopyWith<$Res> {
  __$DerivationTreeCopyWithImpl(this._self, this._then);

  final _DerivationTree _self;
  final $Res Function(_DerivationTree) _then;

/// Create a copy of DerivationTree
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? root = null,Object? isShallow = null,}) {
  return _then(_DerivationTree(
root: null == root ? _self.root : root // ignore: cast_nullable_to_non_nullable
as DerivationTreeNode,isShallow: null == isShallow ? _self.isShallow : isShallow // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of DerivationTree
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DerivationTreeNodeCopyWith<$Res> get root {

  return $DerivationTreeNodeCopyWith<$Res>(_self.root, (value) {
    return _then(_self.copyWith(root: value));
  });
}
}

// dart format on
