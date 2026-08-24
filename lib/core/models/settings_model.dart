//
//  settings_model.dart
//  Turing Lab
//
//  Lightweight structure representing persisted application preferences,
//  controlling special symbols, interface preferences, and element sizes.
//  Ensures cohesive defaults, allows immutable copies, and facilitates
//  comparisons when updating configuration providers.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_model.freezed.dart';

/// Model representing persisted application settings.
@freezed
abstract class SettingsModel with _$SettingsModel {
  const factory SettingsModel({
    /// Symbol used to represent the empty string.
    @Default('λ') String emptyStringSymbol,

    /// Theme mode preference (system, light, dark).
    @Default('system') String themeMode,

    /// Explicit app locale (en or pt), or null to follow the platform locale.
    String? localeCode,

    /// Whether to display the grid on the canvas.
    @Default(true) bool showGrid,

    /// Whether to display coordinates on the canvas.
    @Default(false) bool showCoordinates,

    /// Whether autosave is enabled.
    @Default(true) bool autoSave,

    /// Whether to display tooltips.
    @Default(true) bool showTooltips,

    /// Size of the grid in logical pixels.
    @Default(20.0) double gridSize,

    /// Size of nodes in logical pixels.
    @Default(30.0) double nodeSize,

    /// Base font size in the interface.
    @Default(14.0) double fontSize,

    /// Animation speed multiplier (1.0 = normal, 0.5 = slow, 2.0 = fast).
    @Default(1.0) double animationSpeed,
  }) = _SettingsModel;
}
