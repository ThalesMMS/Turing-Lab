// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'derivation_tree_node.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DerivationTreeNode {

 String get symbol; List<DerivationTreeNode> get children; String? get lexeme; int? get start; int? get end;
/// Create a copy of DerivationTreeNode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DerivationTreeNodeCopyWith<DerivationTreeNode> get copyWith => _$DerivationTreeNodeCopyWithImpl<DerivationTreeNode>(this as DerivationTreeNode, _$identity);

  /// Serializes this DerivationTreeNode to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DerivationTreeNode&&(identical(other.symbol, symbol) || other.symbol == symbol)&&const DeepCollectionEquality().equals(other.children, children)&&(identical(other.lexeme, lexeme) || other.lexeme == lexeme)&&(identical(other.start, start) || other.start == start)&&(identical(other.end, end) || other.end == end));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,symbol,const DeepCollectionEquality().hash(children),lexeme,start,end);

@override
String toString() {
  return 'DerivationTreeNode(symbol: $symbol, children: $children, lexeme: $lexeme, start: $start, end: $end)';
}


}

/// @nodoc
abstract mixin class $DerivationTreeNodeCopyWith<$Res>  {
  factory $DerivationTreeNodeCopyWith(DerivationTreeNode value, $Res Function(DerivationTreeNode) _then) = _$DerivationTreeNodeCopyWithImpl;
@useResult
$Res call({
 String symbol, List<DerivationTreeNode> children, String? lexeme, int? start, int? end
});




}
/// @nodoc
class _$DerivationTreeNodeCopyWithImpl<$Res>
    implements $DerivationTreeNodeCopyWith<$Res> {
  _$DerivationTreeNodeCopyWithImpl(this._self, this._then);

  final DerivationTreeNode _self;
  final $Res Function(DerivationTreeNode) _then;

/// Create a copy of DerivationTreeNode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? symbol = null,Object? children = null,Object? lexeme = freezed,Object? start = freezed,Object? end = freezed,}) {
  return _then(_self.copyWith(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,children: null == children ? _self.children : children // ignore: cast_nullable_to_non_nullable
as List<DerivationTreeNode>,lexeme: freezed == lexeme ? _self.lexeme : lexeme // ignore: cast_nullable_to_non_nullable
as String?,start: freezed == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as int?,end: freezed == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [DerivationTreeNode].
extension DerivationTreeNodePatterns on DerivationTreeNode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DerivationTreeNode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DerivationTreeNode() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DerivationTreeNode value)  $default,){
final _that = this;
switch (_that) {
case _DerivationTreeNode():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DerivationTreeNode value)?  $default,){
final _that = this;
switch (_that) {
case _DerivationTreeNode() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String symbol,  List<DerivationTreeNode> children,  String? lexeme,  int? start,  int? end)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DerivationTreeNode() when $default != null:
return $default(_that.symbol,_that.children,_that.lexeme,_that.start,_that.end);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String symbol,  List<DerivationTreeNode> children,  String? lexeme,  int? start,  int? end)  $default,) {final _that = this;
switch (_that) {
case _DerivationTreeNode():
return $default(_that.symbol,_that.children,_that.lexeme,_that.start,_that.end);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String symbol,  List<DerivationTreeNode> children,  String? lexeme,  int? start,  int? end)?  $default,) {final _that = this;
switch (_that) {
case _DerivationTreeNode() when $default != null:
return $default(_that.symbol,_that.children,_that.lexeme,_that.start,_that.end);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DerivationTreeNode extends DerivationTreeNode {
  const _DerivationTreeNode({required this.symbol, final  List<DerivationTreeNode> children = const <DerivationTreeNode>[], this.lexeme, this.start, this.end}): _children = children,super._();
  factory _DerivationTreeNode.fromJson(Map<String, dynamic> json) => _$DerivationTreeNodeFromJson(json);

@override final  String symbol;
 final  List<DerivationTreeNode> _children;
@override@JsonKey() List<DerivationTreeNode> get children {
  if (_children is EqualUnmodifiableListView) return _children;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_children);
}

@override final  String? lexeme;
@override final  int? start;
@override final  int? end;

/// Create a copy of DerivationTreeNode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DerivationTreeNodeCopyWith<_DerivationTreeNode> get copyWith => __$DerivationTreeNodeCopyWithImpl<_DerivationTreeNode>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DerivationTreeNodeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DerivationTreeNode&&(identical(other.symbol, symbol) || other.symbol == symbol)&&const DeepCollectionEquality().equals(other._children, _children)&&(identical(other.lexeme, lexeme) || other.lexeme == lexeme)&&(identical(other.start, start) || other.start == start)&&(identical(other.end, end) || other.end == end));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,symbol,const DeepCollectionEquality().hash(_children),lexeme,start,end);

@override
String toString() {
  return 'DerivationTreeNode(symbol: $symbol, children: $children, lexeme: $lexeme, start: $start, end: $end)';
}


}

/// @nodoc
abstract mixin class _$DerivationTreeNodeCopyWith<$Res> implements $DerivationTreeNodeCopyWith<$Res> {
  factory _$DerivationTreeNodeCopyWith(_DerivationTreeNode value, $Res Function(_DerivationTreeNode) _then) = __$DerivationTreeNodeCopyWithImpl;
@override @useResult
$Res call({
 String symbol, List<DerivationTreeNode> children, String? lexeme, int? start, int? end
});




}
/// @nodoc
class __$DerivationTreeNodeCopyWithImpl<$Res>
    implements _$DerivationTreeNodeCopyWith<$Res> {
  __$DerivationTreeNodeCopyWithImpl(this._self, this._then);

  final _DerivationTreeNode _self;
  final $Res Function(_DerivationTreeNode) _then;

/// Create a copy of DerivationTreeNode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? symbol = null,Object? children = null,Object? lexeme = freezed,Object? start = freezed,Object? end = freezed,}) {
  return _then(_DerivationTreeNode(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,children: null == children ? _self._children : children // ignore: cast_nullable_to_non_nullable
as List<DerivationTreeNode>,lexeme: freezed == lexeme ? _self.lexeme : lexeme // ignore: cast_nullable_to_non_nullable
as String?,start: freezed == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as int?,end: freezed == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
