import 'package:flutter/material.dart';
import '../constants/colors.dart';

class AppTheme {
  static ThemeData get lightTheme => _getTheme(Brightness.light);
  static ThemeData get darkTheme => _getTheme(Brightness.dark);

  static ThemeData _getTheme(Brightness brightness, {Color? primaryColor}) {
    final isDark = brightness == Brightness.dark;
    final color = primaryColor ?? AppColors.kPrimary;

    // Common Text Styles
    TextStyle getTextStyle(double size, FontWeight weight, Color color) {
      return TextStyle(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: 0.15,
      );
    }

    final textColor = isDark ? Colors.white : AppColors.kTextPrimary;
    final secondaryTextColor =
        isDark ? Colors.white70 : AppColors.kTextSecondary;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: color,
      secondary: AppColors.kSecondary,
      surface: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      background: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      error: AppColors.kError,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textColor,
      onBackground: textColor,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: color,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          isDark ? const Color(0xFF121212) : AppColors.kBackground,
      
      // Font fallback to handle emoji and special characters
      fontFamily: null, // Use default system fonts with emoji support

      // Typography
      textTheme: TextTheme(
        displayLarge: getTextStyle(34, FontWeight.bold, textColor),
        displayMedium: getTextStyle(28, FontWeight.bold, textColor),
        displaySmall: getTextStyle(24, FontWeight.bold, textColor),
        headlineLarge: getTextStyle(22, FontWeight.w600, textColor),
        headlineMedium: getTextStyle(20, FontWeight.w600, textColor),
        headlineSmall: getTextStyle(18, FontWeight.w600, textColor),
        titleLarge: getTextStyle(16, FontWeight.w600, textColor),
        titleMedium: getTextStyle(15, FontWeight.w500, textColor),
        titleSmall: getTextStyle(14, FontWeight.w500, textColor),
        bodyLarge: getTextStyle(16, FontWeight.normal, secondaryTextColor),
        bodyMedium: getTextStyle(14, FontWeight.normal, secondaryTextColor),
        bodySmall: getTextStyle(12, FontWeight.normal, secondaryTextColor),
        labelLarge: getTextStyle(14, FontWeight.w500, textColor),
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? colorScheme.surface : Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : AppColors.kTextPrimary,
        ),
        titleTextStyle: getTextStyle(
          18,
          FontWeight.w600,
          isDark ? Colors.white : AppColors.kTextPrimary,
        ),
      ),

      // Input Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF2D2D2D) : Colors.grey[100],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white24 : Colors.grey[300]!,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white24 : Colors.grey[300]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        hintStyle: TextStyle(
          color: isDark ? Colors.white38 : Colors.grey[500],
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 0,
        margin: const EdgeInsets.all(0),
        color: isDark ? colorScheme.surface : AppColors.kCardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey[200]!,
            width: 1.2,
          ),
        ),
      ),

      // Dialogs
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? colorScheme.surface : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: getTextStyle(18, FontWeight.bold, textColor),
        contentTextStyle: getTextStyle(14, FontWeight.normal, secondaryTextColor),
      ),

      // FAB
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: color,
        ),
      ),

      // Navigation Bar (Bottom)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? colorScheme.surface : Colors.white,
        indicatorColor: color.withOpacity(0.1),
        iconTheme: WidgetStateProperty.all(
          IconThemeData(
            color: isDark ? Colors.white70 : AppColors.kTextPrimary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.all(
          getTextStyle(12, FontWeight.w500, textColor),
        ),
      ),

      // Checkbox & Switch
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? color : null,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? color : Colors.grey,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? color.withOpacity(0.5)
              : Colors.grey[400],
        ),
      ),

      // Tab Bar
      tabBarTheme: TabBarThemeData(
        labelColor: color,
        unselectedLabelColor: isDark ? Colors.white54 : Colors.grey[600],
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: color, width: 3),
        ),
        labelStyle: getTextStyle(14, FontWeight.w600, color),
        unselectedLabelStyle:
            getTextStyle(14, FontWeight.w500, secondaryTextColor),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: isDark ? Colors.white12 : AppColors.kDivider,
        thickness: 1,
        space: 24,
      ),

      // Icon Theme
      iconTheme: IconThemeData(
        color: isDark ? Colors.white70 : AppColors.kTextPrimary,
      ),
    );
  }
}
