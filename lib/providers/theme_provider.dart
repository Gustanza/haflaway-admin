import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/styles.dart';
import '../utils/dimensions.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.light;

  bool get isDarkMode => themeMode == ThemeMode.dark;

  void toggleTheme(bool isOn) {
    themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

class MyThemes {
  static final darkTheme = ThemeData(
    useMaterial3: true,
    // fontFamily: 'Poppins',
    // colorSchemeSeed: primaryColor,
    appBarTheme: const AppBarTheme(
      elevation: psm,

      // centerTitle: true,
      titleTextStyle: TextStyle(fontSize: fsm + 4),
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),
    textButtonTheme: const TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(secondaryColor),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),
    colorScheme: const ColorScheme.dark(),
  );

  static final lightTheme = ThemeData(
    useMaterial3: true,
    // fontFamily: 'Poppins',
    colorSchemeSeed: primaryColor,
    appBarTheme: const AppBarTheme(
      elevation: psm,
      // centerTitle: true,
      titleTextStyle: TextStyle(fontSize: fsm + 4),
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),
    textButtonTheme: const TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(secondaryColor),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),
    scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
  );
}
