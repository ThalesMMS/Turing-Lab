//
//  app_theme.dart
//  Turing Lab
//
//  Declara os temas claro e escuro do aplicativo com paleta Material 3,
//  centralizando cores, estilos de botões, barras e campos para manter
//  aparência consistente entre plataformas e facilitar ajustes de identidade
//  visual futuros.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';

/// Modern app theme for Turing Lab
///
/// Turing Lab intentionally relies on Material 3 and the platform media query for
/// text scaling so iOS Dynamic Type can resize typography across the app.
/// Avoid overriding text scale in the theme unless a widget has a specific
/// accessibility exception.
class AppTheme {
  static const Color primaryColor = Color(0xFF1976D2);
  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color errorColor = Color(0xFFB00020);
  static const Color surfaceColor = Color(0xFFFAFAFA);
  static const Color backgroundColor = Color(0xFFFFFFFF);

  // Audited on 2026-04-22 for Apple accessibility work:
  // - the raw seed color (#1976D2) stays at roughly 4.6:1 against white,
  //   which is AA-compliant but leaves little room for translucency.
  // - small copy therefore stays on explicit onSurfaceVariant text colors
  //   instead of relying on alpha-reduced text over surface tones.
  // - Snack bars and banners should continue using generated on*Container
  //   foregrounds so warning and error messaging keeps Material contrast
  //   guarantees in both light and dark themes.
  static ThemeData _buildTheme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: brightness,
    );
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
    );
    final textTheme = baseTheme.textTheme.copyWith(
      bodySmall: baseTheme.textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      labelSmall: baseTheme.textTheme.labelSmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w500,
      ),
    );

    return baseTheme.copyWith(
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(
          primaryColor.withValues(alpha: 0.5),
        ),
        radius: const Radius.circular(8),
        thickness: WidgetStateProperty.all(8),
        thumbVisibility: WidgetStateProperty.all(true),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  /// Light theme
  static ThemeData get lightTheme => _buildTheme(Brightness.light);

  /// Dark theme
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);
}
