import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/exercise_provider.dart';
import 'providers/piece_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'theme/app_colors.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final themeNotifier = ThemeNotifier();
  await themeNotifier.load();

  runApp(RepertoireApp(themeNotifier: themeNotifier));
}

class RepertoireApp extends StatelessWidget {
  final ThemeNotifier themeNotifier;
  const RepertoireApp({super.key, required this.themeNotifier});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeNotifier),
        ChangeNotifierProvider(create: (_) => PieceProvider()),
        ChangeNotifierProvider(create: (_) => ExerciseProvider()),
      ],
      child: Consumer<ThemeNotifier>(
        builder: (context, theme, _) {
          final isDark = theme.isDark;
          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarColor: isDark
                ? AppColors.dark.background
                : AppColors.light.background,
            systemNavigationBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
          ));
          return MaterialApp(
            title: 'Repertoire',
            debugShowCheckedModeBanner: false,
            themeMode: theme.mode,
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    const colors = AppColors.dark;
    const colorScheme = ColorScheme.dark(
      primary: kGoldColor,
      onPrimary: Color(0xFF1A1200),
      secondary: kGoldColor,
      onSecondary: Color(0xFF1A1200),
      surface: Color(0xFF1E2128),
      onSurface: Color(0xFFE8EAF0),
      error: Colors.redAccent,
      onError: Colors.white,
      outline: Color(0xFF2D3340),
    );
    return _buildThemeData(colorScheme, colors);
  }

  ThemeData _buildLightTheme() {
    const colors = AppColors.light;
    const colorScheme = ColorScheme.light(
      primary: kGoldColor,
      onPrimary: Color(0xFF1A1200),
      secondary: kGoldColor,
      onSecondary: Color(0xFF1A1200),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF1A1D2E),
      error: Colors.red,
      onError: Colors.white,
      outline: Color(0xFFE5E7EB),
    );
    return _buildThemeData(colorScheme, colors);
  }

  ThemeData _buildThemeData(ColorScheme colorScheme, AppColors colors) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      fontFamily: 'Roboto',
      extensions: [colors],

      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: colors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),

      cardTheme: CardThemeData(
        color: colors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: colors.divider),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kGoldColor,
          foregroundColor: const Color(0xFF1A1200),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: kGoldColor),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kGoldColor, width: 1.5),
        ),
        labelStyle: TextStyle(color: colors.textSecondary),
        hintStyle: TextStyle(color: colors.textSecondary.withOpacity(0.5)),
      ),

      dividerTheme: DividerThemeData(
        color: colors.divider,
        space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.card,
        contentTextStyle: TextStyle(color: colors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: colors.card,
        titleTextStyle: TextStyle(
          color: colors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(color: colors.textSecondary, fontSize: 14),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: colors.card,
        selectedColor: kGoldColor.withOpacity(0.15),
        labelStyle: TextStyle(color: colors.textSecondary, fontSize: 12),
        side: BorderSide(color: colors.divider),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: kGoldColor,
        foregroundColor: Color(0xFF1A1200),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: kGoldColor,
        linearTrackColor: colors.divider,
      ),

      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(colors.card),
        ),
      ),
    );
  }
}
