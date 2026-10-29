import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cambridge Educational Series color palette extracted from logo:
///   Primary   – Deep Purple   #6A0DAD  (shield purple)
///   Secondary – Lime Green    #76B900  (shield green)
///   Accent    – Gold          #C9A44A  (gear/atom gold)
class AppColors {
  // Primary – Purple
  static const Color primary = Color(0xFF6A0DAD);
  static const Color primaryDark = Color(0xFF4A0080);
  static const Color primaryLight = Color(0xFF9C4DCA);
  static const Color primarySurface = Color(0xFFF3E8FF);

  // Secondary – Lime Green
  static const Color secondary = Color(0xFF76B900);
  static const Color secondaryDark = Color(0xFF518000);
  static const Color secondaryLight = Color(0xFF8DC63F);
  static const Color secondarySurface = Color(0xFFF0F9E0);

  // Accent – Gold
  static const Color accent = Color(0xFFC9A44A);

  // Light-mode neutrals (static – use context.appColors for dark-aware)
  static const Color background = Color(0xFFF8F7FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3EEF8);
  static const Color border = Color(0xFFE0D5F0);
  static const Color textPrimary = Color(0xFF1A0033);
  static const Color textSecondary = Color(0xFF6B5A82);
  static const Color textHint = Color(0xFF9E8FB2);

  // Status
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFB00020);
  static const Color warning = Color(0xFFE65100);
  static const Color info = Color(0xFF0277BD);
}

/// Dark-mode-aware color palette — reads from [Theme.of(context)].
/// Use via `context.appColors.background`, etc.
class AppColorSet {
  final ColorScheme _cs;
  final bool _isDark;
  const AppColorSet(this._cs, this._isDark);

  Color get primary => _cs.primary;
  Color get primarySurface => _isDark
      ? _cs.primaryContainer
      : AppColors.primarySurface;
  Color get secondary => _cs.secondary;
  Color get accent => AppColors.accent;

  Color get background => _isDark
      ? const Color(0xFF110920)
      : AppColors.background;
  Color get surface => _cs.surface;
  Color get surfaceVariant => _cs.surfaceContainerHighest;
  Color get border => _cs.outline;
  Color get textPrimary => _cs.onSurface;
  Color get textSecondary => _cs.onSurfaceVariant;
  Color get textHint => _isDark
      ? const Color(0xFF7A6890)
      : AppColors.textHint;

  Color get success => AppColors.success;
  Color get error => _cs.error;
  Color get warning => AppColors.warning;
  Color get info => AppColors.info;
}

extension AppTheme on BuildContext {
  AppColorSet get appColors {
    final cs = Theme.of(this).colorScheme;
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return AppColorSet(cs, isDark);
  }

  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

class ThemeState {
  final ThemeMode mode;
  final Color primaryColor;
  final Color secondaryColor;

  ThemeState({
    required this.mode,
    required this.primaryColor,
    required this.secondaryColor,
  });

  ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.primary,
          onPrimary: Colors.white,
          primaryContainer: AppColors.primarySurface,
          onPrimaryContainer: AppColors.primaryDark,
          secondary: AppColors.secondary,
          onSecondary: Colors.white,
          secondaryContainer: AppColors.secondarySurface,
          onSecondaryContainer: AppColors.secondaryDark,
          tertiary: AppColors.accent,
          onTertiary: Colors.white,
          tertiaryContainer: Color(0xFFFFF8E1),
          onTertiaryContainer: Color(0xFF7A5500),
          error: AppColors.error,
          onError: Colors.white,
          errorContainer: Color(0xFFFFDAD6),
          onErrorContainer: Color(0xFF410002),
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          surfaceContainerHighest: AppColors.surfaceVariant,
          onSurfaceVariant: AppColors.textSecondary,
          outline: AppColors.border,
          outlineVariant: Color(0xFFEDE5F5),
          scrim: Colors.black54,
          inverseSurface: AppColors.textPrimary,
          onInverseSurface: Colors.white,
          inversePrimary: AppColors.primaryLight,
          shadow: AppColors.primary,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 1,
          shadowColor: AppColors.border,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          iconTheme: IconThemeData(color: AppColors.textPrimary),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border, width: 1),
          ),
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          hintStyle:
              const TextStyle(color: AppColors.textHint, fontSize: 14),
          labelStyle:
              const TextStyle(color: AppColors.textSecondary),
          prefixIconColor: AppColors.textSecondary,
          suffixIconColor: AppColors.textSecondary,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.surfaceVariant,
          selectedColor: AppColors.primary,
          labelStyle: const TextStyle(fontSize: 13),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primarySurface,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.primary);
            }
            return const IconThemeData(color: AppColors.textSecondary);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600);
            }
            return const TextStyle(
                color: AppColors.textSecondary, fontSize: 12);
          }),
          elevation: 0,
          shadowColor: AppColors.border,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.border,
          thickness: 1,
        ),
        listTileTheme: const ListTileThemeData(
          iconColor: AppColors.primary,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.primary;
            return null;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primarySurface;
            }
            return null;
          }),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.primary,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.textPrimary,
          contentTextStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ),
        dialogTheme: DialogThemeData(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: AppColors.surface,
        ),
      );

  ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: AppColors.primaryLight,
          onPrimary: Colors.white,
          primaryContainer: AppColors.primaryDark,
          onPrimaryContainer: AppColors.primaryLight,
          secondary: AppColors.secondaryLight,
          onSecondary: Colors.black,
          secondaryContainer: AppColors.secondaryDark,
          onSecondaryContainer: AppColors.secondaryLight,
          tertiary: AppColors.accent,
          onTertiary: Colors.black,
          tertiaryContainer: Color(0xFF4A3000),
          onTertiaryContainer: Color(0xFFFFD080),
          error: Color(0xFFFFB4AB),
          onError: Color(0xFF690005),
          errorContainer: Color(0xFF93000A),
          onErrorContainer: Color(0xFFFFDAD6),
          surface: Color(0xFF1A1025),
          onSurface: Color(0xFFF0E8FF),
          surfaceContainerHighest: Color(0xFF2D1F42),
          onSurfaceVariant: Color(0xFFCDB9E5),
          outline: Color(0xFF5A4570),
          outlineVariant: Color(0xFF3D2D55),
          scrim: Colors.black87,
          inverseSurface: Color(0xFFF0E8FF),
          onInverseSurface: Color(0xFF1A1025),
          inversePrimary: AppColors.primary,
          shadow: Colors.black,
        ),
        scaffoldBackgroundColor: const Color(0xFF110920),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1025),
          foregroundColor: Color(0xFFF0E8FF),
          elevation: 0,
          scrolledUnderElevation: 1,
          shadowColor: Color(0xFF5A4570),
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFFF0E8FF),
          ),
          iconTheme: IconThemeData(color: Color(0xFFF0E8FF)),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: const Color(0xFF1A1025),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF5A4570), width: 1),
          ),
          margin: EdgeInsets.zero,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF1A1025),
          indicatorColor: AppColors.primaryDark,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.primaryLight);
            }
            return const IconThemeData(color: Color(0xFFCDB9E5));
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                  color: AppColors.primaryLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w600);
            }
            return const TextStyle(
                color: Color(0xFFCDB9E5), fontSize: 12);
          }),
          elevation: 0,
          shadowColor: const Color(0xFF5A4570),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFF2D1F42),
          selectedColor: AppColors.primaryDark,
          labelStyle: const TextStyle(fontSize: 13, color: Color(0xFFF0E8FF)),
          side: const BorderSide(color: Color(0xFF5A4570)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF1A1025),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF1A1025),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF2D1F42),
          contentTextStyle: const TextStyle(color: Color(0xFFF0E8FF)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFF5A4570),
          thickness: 1,
        ),
        listTileTheme: const ListTileThemeData(
          iconColor: AppColors.primaryLight,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2D1F42),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF5A4570)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF5A4570)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.primaryLight, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFFB4AB)),
          ),
          hintStyle: const TextStyle(
              color: Color(0xFF7A6890), fontSize: 14),
          labelStyle: const TextStyle(color: Color(0xFFCDB9E5)),
          prefixIconColor: const Color(0xFFCDB9E5),
          suffixIconColor: const Color(0xFFCDB9E5),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.primaryLight,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primaryLight;
            }
            return null;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primaryDark;
            }
            return null;
          }),
        ),
      );

  ThemeState copyWith({
    ThemeMode? mode,
    Color? primaryColor,
    Color? secondaryColor,
  }) {
    return ThemeState(
      mode: mode ?? this.mode,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
    );
  }
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier()
      : super(
          ThemeState(
            mode: ThemeMode.light,
            primaryColor: AppColors.primary,
            secondaryColor: AppColors.secondary,
          ),
        );

  void toggleThemeMode(ThemeMode mode) {
    state = state.copyWith(mode: mode);
  }

  void updatePrimaryColor(Color color) {
    state = state.copyWith(primaryColor: color);
  }

  void updateSecondaryColor(Color color) {
    state = state.copyWith(secondaryColor: color);
  }
}

final themeNotifierProvider =
    StateNotifierProvider<ThemeNotifier, ThemeState>((ref) => ThemeNotifier());