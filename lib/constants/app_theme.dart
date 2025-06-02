import 'package:flutter/material.dart';

/// Theme constants and color schemes for the Sudoku game
class AppTheme {
  // Primary colors
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color primaryDark = Color(0xFF1976D2);
  static const Color accent = Color(0xFF03DAC6);
  
  // Game board colors
  static const Color boardBackground = Color(0xFFF5F5F5);
  static const Color cellBackground = Colors.white;
  static const Color cellBorder = Color(0xFFE0E0E0);
  static const Color thickBorder = Color(0xFF424242);
  
  // Cell states
  static const Color selectedCell = Color(0xFFE3F2FD);
  static const Color highlightedCell = Color(0xFFF3E5F5);
  static const Color errorCell = Color(0xFFFFEBEE);
  static const Color correctCell = Color(0xFFE8F5E8);
  
  // Text colors
  static const Color clueText = Color(0xFF212121);
  static const Color userText = Color(0xFF1976D2);
  static const Color noteText = Color(0xFF757575);
  static const Color errorText = Color(0xFFD32F2F);
  
  // Dark theme colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkBoardBackground = Color(0xFF2C2C2C);
  static const Color darkCellBackground = Color(0xFF383838);
  
  // Button colors
  static const Color primaryButton = primaryColor;
  static const Color secondaryButton = Color(0xFF6C757D);
  static const Color successButton = Color(0xFF28A745);
  static const Color warningButton = Color(0xFFFFC107);
  static const Color dangerButton = Color(0xFFDC3545);
  
  // Spacing and sizing
  static const double smallPadding = 8.0;
  static const double mediumPadding = 16.0;
  static const double largePadding = 24.0;
  
  static const double smallRadius = 4.0;
  static const double mediumRadius = 8.0;
  static const double largeRadius = 16.0;
  
  static const double cellSize = 40.0;
  static const double boardPadding = 16.0;
  static const double borderWidth = 1.0;
  static const double thickBorderWidth = 2.0;
  
  // Text styles
  static const TextStyle cellTextStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );
  
  static const TextStyle noteTextStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
  );
  
  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );
  
  static const TextStyle titleTextStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );
  
  static const TextStyle subtitleTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );
  
  // Light theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: mediumPadding,
            vertical: smallPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(mediumRadius),
          ),
        ),
      ),      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(mediumRadius),
        ),
      ),
    );
  }
  
  // Dark theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: darkSurface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: mediumPadding,
            vertical: smallPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(mediumRadius),
          ),
        ),
      ),      cardTheme: CardThemeData(
        elevation: 2,
        color: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(mediumRadius),
        ),
      ),
    );
  }
}
