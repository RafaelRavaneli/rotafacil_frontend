import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'legacy_colors.dart';
import 'smooth_page_transitions.dart';

class AppTheme {
  const AppTheme._();

  /// Tema com o visual do Figma, usado em todo o app.
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.green700,
      brightness: Brightness.light,
      primary: AppColors.green700,
      secondary: AppColors.earth,
      onPrimary: AppColors.white,
      onSecondary: AppColors.forest,
      onSurface: AppColors.ink,
      primaryContainer: AppColors.sage,
      onPrimaryContainer: AppColors.forest,
      error: AppColors.red,
      surface: AppColors.paper,
    );

    return ThemeData(
      useMaterial3: true,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: SmoothPageTransitionsBuilder(),
          TargetPlatform.fuchsia: SmoothPageTransitionsBuilder(),
          TargetPlatform.linux: SmoothPageTransitionsBuilder(),
          TargetPlatform.windows: SmoothPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.cream,
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          color: AppColors.green900,
          fontWeight: FontWeight.w700,
          height: 1.05,
          letterSpacing: -1.0,
        ),
        headlineMedium: TextStyle(
          color: AppColors.green900,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: AppColors.ink, height: 1.45),
        bodyMedium: TextStyle(color: AppColors.muted, height: 1.4),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.paper,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.green700, width: 1.4),
        ),
        hintStyle: const TextStyle(color: Color(0xFF929790)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.green700,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.green700,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: AppColors.paper,
        indicatorColor: AppColors.sage,
        indicatorShape: StadiumBorder(),
        height: 72,
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.paper,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.leaf,
          backgroundColor: AppColors.paper,
          minimumSize: const Size(44, 50),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.leaf),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.forest,
        contentTextStyle: TextStyle(color: AppColors.white),
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      dividerColor: AppColors.border,
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.white
              : AppColors.muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.leaf
              : AppColors.sage,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.paper,
        selectedColor: AppColors.leaf,
        side: const BorderSide(color: AppColors.border),
        shape: const StadiumBorder(),
        labelStyle: const TextStyle(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: const TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w600,
        ),
        checkmarkColor: AppColors.white,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.leaf,
      ),
    );
  }

  /// Tema anterior ao redesenho. Usado só pela home do turista, que deve
  /// permanecer como está.
  static ThemeData get legacy {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: LegacyColors.green700,
      brightness: Brightness.light,
      primary: LegacyColors.green700,
      secondary: LegacyColors.earth,
      onPrimary: LegacyColors.white,
      onSecondary: LegacyColors.forest,
      onSurface: LegacyColors.ink,
      primaryContainer: LegacyColors.sage,
      onPrimaryContainer: LegacyColors.forest,
      error: LegacyColors.red,
      surface: LegacyColors.paper,
    );

    return ThemeData(
      useMaterial3: true,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: SmoothPageTransitionsBuilder(),
          TargetPlatform.fuchsia: SmoothPageTransitionsBuilder(),
          TargetPlatform.linux: SmoothPageTransitionsBuilder(),
          TargetPlatform.windows: SmoothPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      colorScheme: colorScheme,
      scaffoldBackgroundColor: LegacyColors.cream,
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          color: LegacyColors.green900,
          fontWeight: FontWeight.w700,
          height: 1.05,
          letterSpacing: -1.0,
        ),
        headlineMedium: TextStyle(
          color: LegacyColors.green900,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          color: LegacyColors.ink,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: LegacyColors.ink,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: LegacyColors.ink, height: 1.45),
        bodyMedium: TextStyle(color: LegacyColors.muted, height: 1.4),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: LegacyColors.cream,
        foregroundColor: LegacyColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LegacyColors.paper,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: LegacyColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: LegacyColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: LegacyColors.green700, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: LegacyColors.green700,
          foregroundColor: LegacyColors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: LegacyColors.green700,
          foregroundColor: LegacyColors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: LegacyColors.paper,
        indicatorColor: LegacyColors.sage,
        height: 76,
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
        ),
      ),
      cardTheme: CardThemeData(
        color: LegacyColors.paper,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: LegacyColors.border),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: LegacyColors.forest,
          minimumSize: const Size(44, 48),
          side: const BorderSide(color: LegacyColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: LegacyColors.forest),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: LegacyColors.forest,
        contentTextStyle: TextStyle(color: LegacyColors.white),
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: LegacyColors.paper,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      dividerColor: LegacyColors.border,
    );
  }
}
