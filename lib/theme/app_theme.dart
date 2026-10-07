import 'package:flutter/material.dart';

class AppTheme {
  static const Color productImageBackground = Color(0xFFF5F5F5);

  static const Color _lightPrimary = Colors.black;
  static const Color _lightText = Color(0xFF111111);
  static const Color _lightSecondaryText = Color(0xFF757575);
  static const Color _lightDivider = Color(0xFFEEEEEE);
  static const Color _lightFieldFill = Color(0xFFF5F5F5);

  static const Color _darkBackground = Color(0xFF0E0E0E);
  static const Color _darkSurface = Color(0xFF1E1E1E);
  static const Color _darkText = Color(0xFFF5F5F5);
  static const Color _darkSecondaryText = Color(0xFF9E9E9E);
  static const Color _darkDivider = Color(0xFF2A2A2A);

  static const BorderRadius _cornerRadius = BorderRadius.all(
    Radius.circular(12),
  );

  static ThemeData get light => _buildTheme(
    brightness: Brightness.light,
    primary: _lightPrimary,
    onPrimary: Colors.white,
    background: Colors.white,
    surface: Colors.white,
    fieldFill: _lightFieldFill,
    text: _lightText,
    secondaryText: _lightSecondaryText,
    divider: _lightDivider,
  );

  static ThemeData get dark => _buildTheme(
    brightness: Brightness.dark,
    primary: Colors.white,
    onPrimary: Colors.black,
    background: _darkBackground,
    surface: _darkSurface,
    fieldFill: _darkSurface,
    text: _darkText,
    secondaryText: _darkSecondaryText,
    divider: _darkDivider,
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color primary,
    required Color onPrimary,
    required Color background,
    required Color surface,
    required Color fieldFill,
    required Color text,
    required Color secondaryText,
    required Color divider,
  }) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: brightness,
        ).copyWith(
          primary: primary,
          onPrimary: onPrimary,
          secondary: secondaryText,
          onSurface: text,
          surface: surface,
          surfaceContainerHighest: surface,
          outline: divider,
          outlineVariant: divider,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      dividerColor: divider,
      shadowColor: Colors.transparent,
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: text),
        bodyMedium: TextStyle(color: text),
        bodySmall: TextStyle(color: secondaryText),
        titleLarge: TextStyle(
          color: text,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: primary,
          disabledForegroundColor: onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 52),
          shape: const RoundedRectangleBorder(borderRadius: _cornerRadius),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: _cornerRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: _cornerRadius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: _cornerRadius,
          borderSide: BorderSide.none,
        ),
      ),
      dividerTheme: DividerThemeData(color: divider, thickness: 1),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: _cornerRadius),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: background,
        elevation: 0,
        selectedItemColor: primary,
        unselectedItemColor: secondaryText,
        type: BottomNavigationBarType.fixed,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primary,
        disabledColor: surface,
        secondarySelectedColor: primary,
        labelStyle: TextStyle(color: text),
        secondaryLabelStyle: TextStyle(color: onPrimary),
        side: BorderSide(color: divider),
        shape: const RoundedRectangleBorder(borderRadius: _cornerRadius),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
    );
  }
}
