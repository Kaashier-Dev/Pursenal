import 'package:flutter/material.dart';
import 'package:pursenal/app/extensions/color.dart';
import 'package:pursenal/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  final lightTextColor = Colors.grey.shade700;
  final lightCardColor = Colors.grey.shade100;
  final lightScaffoldBGColor = Colors.white;
  final lightMainTitleColor = Colors.grey.shade900;
  final lightPageTitleColor = Colors.blueGrey.shade700;

  final darkTextColor = Colors.grey.shade100;
  final darkCardColor = Colors.grey.shade800;
  final darkScaffoldBGColor = Colors.grey.shade900;
  final darkMainTitleColor = Colors.blue.shade400;
  final darkPageTitleColor = Colors.blueAccent.shade100;

  MaterialColor _primaryColor = Colors.blue;
  MaterialColor get primaryColor => _primaryColor;

  Color primary50 = Colors.blue.shade50;
  Color primary200 = Colors.blue.shade200;
  Color primary400 = Colors.blue.shade400;
  Color primary500 = Colors.blue.shade500;
  Color primary600 = Colors.blue.shade600;
  Color primary700 =
      Colors.blueAccent.shade700; // also used as the primary color
  Color primary800 = Colors.blue.shade800;
  Color primary900 = Colors.blue.shade900;
  Color primary100 = Colors.blueAccent.shade100;

// Grey Colors
  final Color grey100 = Colors.grey.shade100;
  final Color grey200 = Colors.grey.shade200;
  final Color grey300 = Colors.grey.shade300;
  final Color grey500 = Colors.grey;
  final Color grey700 = Colors.grey.shade700;
  final Color grey800 = Colors.grey.shade800;
  final Color grey900 = Colors.grey.shade900;

// BlueGrey Colors
  final Color blueGrey50 = Colors.blueGrey.shade50;
  final Color blueGrey100 = Colors.blueGrey.shade100;
  final Color blueGrey200 = Colors.blueGrey.shade200;
  final Color blueGrey400 = Colors.blueGrey.shade400;
  final Color blueGrey500 = Colors.blueGrey.shade500;
  final Color blueGrey700 = Colors.blueGrey.shade700;
  final Color blueGrey800 = Colors.blueGrey.shade800;
  final Color blueGrey900 = Colors.blueGrey.shade900;

// Other common colors
  final Color white = Colors.white;
  final Color transparent = Colors.transparent;

  final elevatedBtnRadius = 8.0;
  final cardRadius = 14.0;

  // Preferences instance
  SharedPreferences? _prefs;

  Future<void> init() async {
    try {
      notifyListeners();

      _prefs = await SharedPreferences.getInstance();
      _primaryColor =
          (await getPrimaryColor())?.hexToMaterialColor() ?? Colors.blue;
      await _getFont();
      setColors();
      notifyListeners();
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');

      notifyListeners();
    }
  }

  setColors() {
    primary700 = _primaryColor[700] ?? Colors.blue.shade700;
    primary50 = _primaryColor[50] ?? Colors.blue.shade50;
    primary200 = _primaryColor[200] ?? Colors.blue.shade200;
    primary400 = _primaryColor[400] ?? Colors.blue.shade400;
    primary500 = _primaryColor[500] ?? Colors.blue.shade500;
    primary600 = _primaryColor[600] ?? Colors.blue.shade600;
    primary700 = _primaryColor[700] ??
        Colors.blueAccent.shade700; // also used as the primary color
    primary800 = _primaryColor[800] ?? Colors.blue.shade800;
    primary900 = _primaryColor[900] ?? Colors.blue.shade900;
    primary100 = _primaryColor[100] ?? Colors.blueAccent.shade100;
    notifyListeners();
  }

  String _selectedFont = 'Ubuntu'; // Default font

  String get selectedFont => _selectedFont;

  set primaryColor(MaterialColor value) {
    try {
      _primaryColor = value;
      setPrimaryColor(value.toHex());
      setColors();
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
    }
    notifyListeners();
  }

  Future<String?> getPrimaryColor() async {
    try {
      return _prefs?.getString('primaryColor');
    } catch (e) {
      AppLogger.instance.error("Error selecting primary color ${e.toString()}");
      return null;
    }
  }

  Future<void> setPrimaryColor(String color) async {
    try {
      _prefs?.setString('primaryColor', color);
    } catch (e) {
      AppLogger.instance.error("Error setting primary color ${e.toString()}");
    }
  }

  Future<void> _getFont() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _selectedFont = prefs.getString('selectedFont') ?? 'OpenSans';
    notifyListeners();
  }

  Future<void> setFont(String font) async {
    _selectedFont = font;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedFont', font);
    notifyListeners();
  }

  ThemeData getLightTheme() {
    final ThemeData lightTheme = ThemeData(
      // General colors
      primaryColor: primary700,
      scaffoldBackgroundColor: white,
      cardColor: grey100,
      dividerColor: transparent,
      fontFamily: _selectedFont,
      cardTheme: CardThemeData(
        color: grey100,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(cardRadius)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        textColor: grey700,
        shape: Border(
          bottom: BorderSide(color: grey500, width: 0.40),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
            shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)))),
      ),
      // AppBar Theme
      appBarTheme: AppBarTheme(
        iconTheme: IconThemeData(color: grey900),
        titleTextStyle: TextStyle(
          color: grey900,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      chipTheme: ChipThemeData(
        selectedColor: primary700,
        backgroundColor: blueGrey400,
        side: BorderSide.none,
        labelStyle: TextStyle(color: white),
        checkmarkColor: white,
      ),
      // Button Theme
      buttonTheme: ButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: primary50,
      ),
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(200, 50),
          backgroundColor: primary700,
          foregroundColor: white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(elevatedBtnRadius),
          ),
        ),
      ),
      // Icon Theme
      iconTheme: IconThemeData(size: 26, color: grey900),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: grey100.withValues(alpha: .7),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary700),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primary600),
          borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primary800, width: 2),
          borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
          inputDecorationTheme: InputDecorationTheme(
        fillColor: grey100.withValues(alpha: .7),
        filled: true,
      )),
      disabledColor: blueGrey200,
      // Color Scheme
      colorScheme: ColorScheme.light(
        primary: primary700,
        secondary: blueGrey200,
        surface: white,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: white,
        shape: const RoundedRectangleBorder(),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        expansionAnimationStyle: const AnimationStyle(
          curve: Curves.easeInOut,
          duration: Duration(milliseconds: 350),
          reverseCurve: Curves.easeInOut,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(grey700),
          textStyle: WidgetStatePropertyAll(
            TextStyle(color: grey700, fontWeight: FontWeight.bold),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: primary900,
          fontSize: 34,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: blueGrey700,
          fontSize: 30,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: TextStyle(
          color: grey900,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: blueGrey700,
        ),
        bodyMedium: TextStyle(
          color: blueGrey700,
        ),
        displayLarge: TextStyle(color: blueGrey700),
        displayMedium: TextStyle(color: blueGrey700),
        titleMedium: TextStyle(
          color: blueGrey800,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: primary900,
          fontSize: 30,
          fontWeight: FontWeight.bold,
        ),
        titleSmall: TextStyle(color: blueGrey500),
        bodySmall: TextStyle(color: blueGrey400),
        labelLarge: TextStyle(color: blueGrey800),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
          foregroundColor: white,
          iconSize: 32,
          sizeConstraints: const BoxConstraints(minHeight: 72, minWidth: 72)),
    );
    return lightTheme;
  }

  ThemeData getDarkTheme() {
    final ThemeData darkTheme2 = ThemeData(
      // General colors
      primaryColor: primary700,
      scaffoldBackgroundColor: grey900,
      cardColor: grey800,
      dividerColor: transparent,
      fontFamily: _selectedFont,
      cardTheme: CardThemeData(
        color: grey800,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(cardRadius)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        textColor: grey100,
        shape: Border(
          bottom: BorderSide(color: grey500, width: 0.40),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
            shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)))),
      ),
      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: transparent,
        iconTheme: IconThemeData(color: grey100),
        titleTextStyle: TextStyle(
          color: grey100,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      // Button Theme
      buttonTheme: ButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 2,
        backgroundColor: primary900,
      ),
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          iconColor: white,
          minimumSize: const Size(200, 50),
          backgroundColor: primary700,
          foregroundColor: white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(elevatedBtnRadius),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        selectedColor: primary700,
        backgroundColor: transparent,
        labelStyle: TextStyle(color: white),
        checkmarkColor: white,
        side: BorderSide.none,
      ),
      // Icon Theme
      iconTheme: IconThemeData(
        color: primary200,
        size: 24,
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: grey800.withValues(alpha: .7),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary700),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primary800),
          borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        ),
        labelStyle: TextStyle(color: white),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primary500, width: 2),
          borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
          inputDecorationTheme: InputDecorationTheme(
        fillColor: grey800.withValues(alpha: .7),
        filled: true,
      )),
      // Color Scheme
      colorScheme: ColorScheme.dark(
        primary: primary700,
        secondary: blueGrey500,
        surface: grey800,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: grey900,
        shape: const RoundedRectangleBorder(),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        expansionAnimationStyle: const AnimationStyle(
          curve: Curves.easeInOut,
          duration: Duration(milliseconds: 350),
          reverseCurve: Curves.easeInOut,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(grey100),
          textStyle: WidgetStatePropertyAll(
            TextStyle(color: grey100, fontWeight: FontWeight.bold),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
          foregroundColor: white,
          iconSize: 32,
          sizeConstraints: const BoxConstraints(minHeight: 72, minWidth: 72)),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: blueGrey100,
          fontSize: 34,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: grey100,
          fontSize: 30,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: TextStyle(
          color: blueGrey200,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: grey100,
        ),
        bodyMedium: TextStyle(
          color: blueGrey100,
        ),
        displayLarge: TextStyle(color: blueGrey200),
        displayMedium: TextStyle(color: blueGrey100),
        titleMedium: TextStyle(
          color: grey100,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: white,
          fontSize: 30,
          fontWeight: FontWeight.bold,
        ),
        titleSmall: TextStyle(color: blueGrey100),
        bodySmall: TextStyle(color: grey100),
        labelLarge: TextStyle(color: grey200),
      ),
    );
    return darkTheme2;
  }
}
