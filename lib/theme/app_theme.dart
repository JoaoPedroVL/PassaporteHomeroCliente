import 'package:flutter/material.dart';

/// Paleta "Passaporte premium": verde profundo, dourado e papel.
abstract final class AppColors {
  static const deepGreen = Color(0xFF0B3B2E);
  static const forest = Color(0xFF14503E);
  static const gold = Color(0xFFC9A227);
  static const goldLight = Color(0xFFE6C766);
  static const parchment = Color(0xFFF5F0E6);
  static const cream = Color(0xFFFBF8F1);
  static const ink = Color(0xFF1C2B27);
  static const muted = Color(0xFF6B7A72);
  static const line = Color(0xFFE3D9C6);
  static const success = Color(0xFF2E7D5B);
  static const danger = Color(0xFFB3261E);
  static const pending = Color(0xFFB07A1F);
}

/// Tema visual da Etapa B.
ThemeData temaPadrao() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.deepGreen,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFDDE9E3),
    onPrimaryContainer: AppColors.deepGreen,
    secondary: AppColors.gold,
    onSecondary: AppColors.ink,
    secondaryContainer: Color(0xFFF3E7C3),
    onSecondaryContainer: Color(0xFF4A3A0A),
    tertiary: AppColors.forest,
    onTertiary: Colors.white,
    error: AppColors.danger,
    onError: Colors.white,
    surface: AppColors.cream,
    onSurface: AppColors.ink,
    surfaceContainerHighest: Color(0xFFEFE8DA),
    onSurfaceVariant: AppColors.muted,
    outline: AppColors.line,
    outlineVariant: Color(0xFFEDE5D5),
    shadow: Color(0x1A000000),
    scrim: Color(0x66000000),
    inverseSurface: AppColors.ink,
    onInverseSurface: AppColors.cream,
    inversePrimary: AppColors.goldLight,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.parchment,
  );

  final textTheme = base.textTheme.copyWith(
    displayLarge: base.textTheme.displayLarge?.copyWith(
      fontFamily: 'CrimsonText',
      fontWeight: FontWeight.w700,
      color: AppColors.deepGreen,
      letterSpacing: -0.5,
    ),
    displayMedium: base.textTheme.displayMedium?.copyWith(
      fontFamily: 'CrimsonText',
      fontWeight: FontWeight.w700,
      color: AppColors.deepGreen,
      letterSpacing: -0.4,
    ),
    displaySmall: base.textTheme.displaySmall?.copyWith(
      fontFamily: 'CrimsonText',
      fontWeight: FontWeight.w700,
      color: AppColors.deepGreen,
    ),
    headlineLarge: base.textTheme.headlineLarge?.copyWith(
      fontFamily: 'CrimsonText',
      fontWeight: FontWeight.w700,
      color: AppColors.deepGreen,
    ),
    headlineMedium: base.textTheme.headlineMedium?.copyWith(
      fontFamily: 'CrimsonText',
      fontWeight: FontWeight.w700,
      color: AppColors.deepGreen,
    ),
    headlineSmall: base.textTheme.headlineSmall?.copyWith(
      fontFamily: 'CrimsonText',
      fontWeight: FontWeight.w700,
      color: AppColors.deepGreen,
    ),
    titleLarge: base.textTheme.titleLarge?.copyWith(
      fontFamily: 'CrimsonText',
      fontWeight: FontWeight.w700,
      color: AppColors.deepGreen,
    ),
    titleMedium: base.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: AppColors.ink,
    ),
    titleSmall: base.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: AppColors.ink,
    ),
    bodyLarge: base.textTheme.bodyLarge?.copyWith(
      color: AppColors.ink,
      height: 1.45,
    ),
    bodyMedium: base.textTheme.bodyMedium?.copyWith(
      color: AppColors.ink,
      height: 1.45,
    ),
    bodySmall: base.textTheme.bodySmall?.copyWith(
      color: AppColors.muted,
      height: 1.4,
    ),
    labelLarge: base.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    ),
  );

  return base.copyWith(
    textTheme: textTheme,
    iconTheme: const IconThemeData(color: AppColors.deepGreen),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.deepGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: AppColors.goldLight),
      actionsIconTheme: IconThemeData(color: AppColors.goldLight),
      titleTextStyle: TextStyle(
        fontFamily: 'CrimsonText',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 0.2,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.deepGreen,
      indicatorColor: AppColors.gold,
      elevation: 0,
      height: 72,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.goldLight : Colors.white70,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? AppColors.deepGreen : Colors.white70,
          size: 24,
        );
      }),
    ),
    cardTheme: CardThemeData(
      color: AppColors.cream,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.line),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.deepGreen,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.deepGreen,
        minimumSize: const Size(0, 48),
        side: const BorderSide(color: AppColors.deepGreen, width: 1.2),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.deepGreen,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: AppColors.cream,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.gold, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.danger, width: 2),
      ),
      labelStyle: const TextStyle(color: AppColors.muted),
      hintStyle: const TextStyle(color: AppColors.muted),
      prefixIconColor: AppColors.muted,
      suffixIconColor: AppColors.muted,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.line,
      thickness: 1,
      space: 1,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.cream,
      selectedColor: AppColors.deepGreen,
      disabledColor: AppColors.line,
      side: const BorderSide(color: AppColors.line),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
      labelStyle: const TextStyle(
        color: AppColors.ink,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      secondaryLabelStyle: const TextStyle(
        color: AppColors.goldLight,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.deepGreen,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.cream,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      titleTextStyle: const TextStyle(
        fontFamily: 'CrimsonText',
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.deepGreen,
      ),
      contentTextStyle: const TextStyle(
        color: AppColors.ink,
        height: 1.45,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.cream,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: AppColors.deepGreen,
      unselectedLabelColor: AppColors.muted,
      indicatorColor: AppColors.gold,
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: AppColors.line,
      labelStyle: TextStyle(fontWeight: FontWeight.w700),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.gold,
      linearTrackColor: AppColors.line,
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.deepGreen,
      textColor: AppColors.ink,
    ),
  );
}
