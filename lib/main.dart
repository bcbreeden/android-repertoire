import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/piece_provider.dart';
import 'screens/home_screen.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: kBackgroundColor,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const RepertoireApp());
}

class RepertoireApp extends StatelessWidget {
  const RepertoireApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PieceProvider(),
      child: MaterialApp(
        title: 'Repertoire',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: const HomeScreen(),
      ),
    );
  }

  ThemeData _buildTheme() {
    const colorScheme = ColorScheme.dark(
      primary: kGoldColor,
      onPrimary: Color(0xFF1A1200),
      secondary: kGoldColor,
      onSecondary: Color(0xFF1A1200),
      surface: kSurfaceColor,
      onSurface: kTextPrimary,
      error: Colors.redAccent,
      onError: Colors.white,
      outline: kDividerColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: kBackgroundColor,
      fontFamily: 'Roboto',

      appBarTheme: const AppBarTheme(
        backgroundColor: kBackgroundColor,
        foregroundColor: kTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: kTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: kTextPrimary),
      ),

      cardTheme: const CardThemeData(
        color: kCardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: kDividerColor),
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
        fillColor: kCardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kDividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kDividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kGoldColor, width: 1.5),
        ),
        labelStyle: const TextStyle(color: kTextSecondary),
        hintStyle: TextStyle(color: kTextSecondary.withOpacity(0.5)),
      ),

      dividerTheme: const DividerThemeData(
        color: kDividerColor,
        space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: kCardColor,
        contentTextStyle: const TextStyle(color: kTextPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      dialogTheme: const DialogThemeData(
        backgroundColor: kCardColor,
        titleTextStyle: TextStyle(
          color: kTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(color: kTextSecondary, fontSize: 14),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: kCardColor,
        selectedColor: kGoldColor.withOpacity(0.15),
        labelStyle: const TextStyle(color: kTextSecondary, fontSize: 12),
        side: const BorderSide(color: kDividerColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: kGoldColor,
        foregroundColor: Color(0xFF1A1200),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: kGoldColor,
        linearTrackColor: kDividerColor,
      ),

      dropdownMenuTheme: const DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(kCardColor),
        ),
      ),
    );
  }
}
