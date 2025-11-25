import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import '../constants/sizes.dart';

enum BusinessTheme {
  retail,
  restaurant,
  pharmacy,
  electronics,
  fashion,
  automotive,
}

enum AppThemeMode {
  light,
  dark,
  system,
}

class ThemeManager extends ChangeNotifier {
  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;
  ThemeManager._internal();

  AppThemeMode _themeMode = AppThemeMode.light;
  BusinessTheme _businessTheme = BusinessTheme.retail;
  bool _useSystemTheme = false;

  AppThemeMode get themeMode => _themeMode;
  BusinessTheme get businessTheme => _businessTheme;
  bool get useSystemTheme => _useSystemTheme;
  
  bool get isDarkMode => _themeMode == AppThemeMode.dark;

  void setThemeMode(AppThemeMode mode) {
    _themeMode = mode;
    _updateSystemUI();
    notifyListeners();
  }

  void setBusinessTheme(BusinessTheme theme) {
    _businessTheme = theme;
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = _themeMode == AppThemeMode.light 
        ? AppThemeMode.dark 
        : AppThemeMode.light;
    _updateSystemUI();
    notifyListeners();
  }

  void _updateSystemUI() {
    final brightness = _themeMode == AppThemeMode.dark 
        ? Brightness.dark 
        : Brightness.light;
    
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: brightness,
        statusBarIconBrightness: brightness == Brightness.dark 
            ? Brightness.light 
            : Brightness.dark,
        systemNavigationBarColor: brightness == Brightness.dark 
            ? const Color(0xFF1A1A1A) 
            : Colors.white,
        systemNavigationBarIconBrightness: brightness == Brightness.dark 
            ? Brightness.light 
            : Brightness.dark,
      ),
    );
  }

  // Get current business theme colors
  BusinessThemeColors get currentBusinessColors {
    switch (_businessTheme) {
      case BusinessTheme.retail:
        return BusinessThemeColors.retail;
      case BusinessTheme.restaurant:
        return BusinessThemeColors.restaurant;
      case BusinessTheme.pharmacy:
        return BusinessThemeColors.pharmacy;
      case BusinessTheme.electronics:
        return BusinessThemeColors.electronics;
      case BusinessTheme.fashion:
        return BusinessThemeColors.fashion;
      case BusinessTheme.automotive:
        return BusinessThemeColors.automotive;
    }
  }
}

class BusinessThemeColors {
  final Color primary;
  final Color secondary;
  final Color accent;
  final List<Color> gradient;
  final Color success;
  final Color warning;
  final Color error;
  final String name;
  final IconData icon;

  const BusinessThemeColors({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.gradient,
    required this.success,
    required this.warning,
    required this.error,
    required this.name,
    required this.icon,
  });

  static const BusinessThemeColors retail = BusinessThemeColors(
    primary: Color(0xFF2563EB),
    secondary: Color(0xFF3B82F6),
    accent: Color(0xFF60A5FA),
    gradient: [Color(0xFF2563EB), Color(0xFF3B82F6)],
    success: Color(0xFF22C55E),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    name: 'Retail',
    icon: Icons.store,
  );

  static const BusinessThemeColors restaurant = BusinessThemeColors(
    primary: Color(0xFFDC2626),
    secondary: Color(0xFFEF4444),
    accent: Color(0xFFF87171),
    gradient: [Color(0xFFDC2626), Color(0xFFEF4444)],
    success: Color(0xFF16A34A),
    warning: Color(0xFFEAB308),
    error: Color(0xFFDC2626),
    name: 'Restaurant',
    icon: Icons.restaurant,
  );

  static const BusinessThemeColors pharmacy = BusinessThemeColors(
    primary: Color(0xFF059669),
    secondary: Color(0xFF10B981),
    accent: Color(0xFF34D399),
    gradient: [Color(0xFF059669), Color(0xFF10B981)],
    success: Color(0xFF22C55E),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    name: 'Pharmacy',
    icon: Icons.local_pharmacy,
  );

  static const BusinessThemeColors electronics = BusinessThemeColors(
    primary: Color(0xFF7C3AED),
    secondary: Color(0xFF8B5CF6),
    accent: Color(0xFFA78BFA),
    gradient: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
    success: Color(0xFF22C55E),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    name: 'Electronics',
    icon: Icons.electrical_services,
  );

  static const BusinessThemeColors fashion = BusinessThemeColors(
    primary: Color(0xFFEC4899),
    secondary: Color(0xFFF472B6),
    accent: Color(0xFFF9A8D4),
    gradient: [Color(0xFFEC4899), Color(0xFFF472B6)],
    success: Color(0xFF22C55E),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    name: 'Fashion',
    icon: Icons.checkroom,
  );

  static const BusinessThemeColors automotive = BusinessThemeColors(
    primary: Color(0xFF1F2937),
    secondary: Color(0xFF374151),
    accent: Color(0xFF6B7280),
    gradient: [Color(0xFF1F2937), Color(0xFF374151)],
    success: Color(0xFF22C55E),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    name: 'Automotive',
    icon: Icons.directions_car,
  );
}

class ModernThemeData {
  static ThemeData lightTheme(BusinessThemeColors businessColors) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color scheme
      colorScheme: ColorScheme.light(
        primary: businessColors.primary,
        secondary: businessColors.secondary,
        surface: Colors.white,
        background: const Color(0xFFF8FAFC),
        error: businessColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: const Color(0xFF1E293B),
        onBackground: const Color(0xFF334155),
        onError: Colors.white,
      ),

      // App bar theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: businessColors.primary,
        foregroundColor: Colors.white,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
        ),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
        ),
        color: Colors.white,
        surfaceTintColor: businessColors.primary.withOpacity(0.05),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: businessColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // Text theme
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E293B),
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E293B),
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E293B),
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF334155),
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF334155),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: Color(0xFF475569),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Color(0xFF64748B),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          borderSide: BorderSide(color: businessColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: businessColors.primary,
        unselectedItemColor: const Color(0xFF64748B),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  static ThemeData darkTheme(BusinessThemeColors businessColors) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Color scheme
      colorScheme: ColorScheme.dark(
        primary: businessColors.primary,
        secondary: businessColors.secondary,
        surface: const Color(0xFF1E1E1E),
        background: const Color(0xFF121212),
        error: businessColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: const Color(0xFFE2E8F0),
        onBackground: const Color(0xFFCBD5E1),
        onError: Colors.white,
      ),

      // App bar theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: const Color(0xFFE2E8F0),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light,
        ),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE2E8F0),
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
        ),
        color: const Color(0xFF2D2D2D),
        surfaceTintColor: businessColors.primary.withOpacity(0.1),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: businessColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // Text theme
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Color(0xFFE2E8F0),
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Color(0xFFE2E8F0),
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE2E8F0),
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFFCBD5E1),
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFFCBD5E1),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: Color(0xFF94A3B8),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Color(0xFF64748B),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF374151),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          borderSide: BorderSide(color: businessColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: businessColors.primary,
        unselectedItemColor: const Color(0xFF64748B),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}