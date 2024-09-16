import 'package:flutter/material.dart';

class OwnThemeFields {
  final Color errorShade;
  final Color textBaloon;
  final Color spanColor;
  final Color textSelectionPopupColor;
  final double searchBarHeight;

  const OwnThemeFields(
      {Color? errorShade,
      Color? textBaloon,
      Color? spanColor,
      Color? textSelectionPopupColor,
      double? searchBarHeight})
      : errorShade = errorShade ?? Colors.red,
        textBaloon = textBaloon ?? Colors.black,
        spanColor = spanColor ?? Colors.black,
        textSelectionPopupColor = textSelectionPopupColor ?? Colors.black,
        searchBarHeight = 80;
}

extension ThemeDataExtensions on ThemeData {
  static final Map<InputDecorationTheme, OwnThemeFields> _own = {};

  void addOwn(OwnThemeFields own) {
    // can't use reference to ThemeData since Theme.of() can create a new localized instance from the original theme. Use internal fields, in this case InputDecoreationTheme reference which is not deep copied but simply a reference is copied
    _own[inputDecorationTheme] = own;
  }

  static OwnThemeFields? empty;

  OwnThemeFields own() {
    var o = _own[inputDecorationTheme];
    if (o == null) {
      empty ??= const OwnThemeFields();
      o = empty;
    }
    return o!;
  }
}

OwnThemeFields ownTheme(BuildContext context) => Theme.of(context).own();

final ThemeData lightTheme = ThemeData.light().copyWith(
    canvasColor: const Color.fromARGB(255, 240, 242, 243),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
            foregroundColor: WidgetStateProperty.all<Color>(Colors.black))),
    inputDecorationTheme: const InputDecorationTheme(
        focusedBorder: InputBorder.none,
        border: InputBorder.none,
        labelStyle: TextStyle(
            fontSize: 18, fontFamily: 'Montserrat', color: Colors.red)),
    // backgroundColor: const Color.fromARGB(255, 240, 242, 243),
    colorScheme: const ColorScheme.light().copyWith(
        surface: const Color.fromARGB(255, 240, 242, 243),
        secondary: Colors.grey.withAlpha(128)),
    textTheme: TextTheme(
      labelLarge: const TextStyle(
          fontSize: 18, fontFamily: 'Montserrat', color: Colors.black),
      headlineSmall: const TextStyle(
        fontSize: 20.0,
        color: Colors.black,
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.bold,
      ),
      // standard TextField()
      titleMedium: const TextStyle(
        fontSize: 20.0,
        fontFamily: 'Montserrat',
        color: Colors.black,
      ),
      titleSmall: TextStyle(
        fontSize: 16.0,
        fontFamily: 'Montserrat',
        fontStyle: FontStyle.italic,
        color: Colors.black.withAlpha(128),
      ),
      // used for dictionary error text in Online dicts
      labelSmall: const TextStyle(
          fontSize: 14.0,
          fontFamily: 'Montserrat',
          fontStyle: FontStyle.italic,
          color: Colors.black),
      // standard Text()
      bodyMedium: const TextStyle(
          fontSize: 20.0, fontFamily: 'Montserrat', color: Colors.black),
      // italic Text()
      bodyLarge: const TextStyle(
          fontSize: 20.0,
          fontFamily: 'Montserrat',
          fontStyle: FontStyle.italic,
          color: Colors.black),
      // Dictionary card, dictionary  name
      bodySmall: const TextStyle(
          fontSize: 17.0, fontFamily: 'Montserrat', color: Colors.black),
    ),
    textSelectionTheme: const TextSelectionThemeData(
        selectionColor: Color.fromARGB(255, 33, 213, 159)),
    dialogTheme: DialogTheme(
      backgroundColor: Colors.grey[100],
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12))),
    ))
  ..addOwn(const OwnThemeFields(
      errorShade: Color.fromARGB(240, 255, 200, 200),
      textBaloon: Color.fromARGB(240, 255, 200, 200),
      textSelectionPopupColor: Color.fromARGB(255, 165, 183, 173)));

final ThemeData darkTheme = ThemeData.dark().copyWith(
    cardColor: const Color.fromARGB(255, 32, 33, 36),
    dialogBackgroundColor: const Color.fromARGB(255, 32, 33, 36),
    canvasColor: const Color.fromARGB(255, 32, 33, 36),
    scaffoldBackgroundColor: const Color.fromARGB(255, 16, 17, 18),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
            foregroundColor: WidgetStateProperty.all<Color>(Colors.white))),
    colorScheme: const ColorScheme.dark().copyWith(
        surface: const Color.fromARGB(255, 32, 35, 36),
        secondary: Colors.green),
    buttonTheme: const ButtonThemeData(
        buttonColor: Colors.white, splashColor: Colors.white),
    textTheme: TextTheme(
      labelLarge: const TextStyle(fontSize: 18, fontFamily: 'Montserrat'),
      headlineSmall: const TextStyle(
          fontSize: 20.0,
          color: Color.fromARGB(255, 240, 240, 240),
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.bold,
          fontFamilyFallback: ['Roboto']),
      titleMedium: const TextStyle(
          fontSize: 20.0,
          fontFamily: 'Montserrat',
          color: Colors.white,
          fontFamilyFallback: ['Roboto']),
      titleSmall: TextStyle(
          fontSize: 16.0,
          fontFamily: 'Montserrat',
          fontStyle: FontStyle.italic,
          color: Colors.white.withAlpha(128),
          fontFamilyFallback: const ['Roboto']),
      // used for dictionary error text in Online dicts
      labelSmall: const TextStyle(
          fontSize: 14.0,
          fontFamily: 'Montserrat',
          fontStyle: FontStyle.italic,
          color: Colors.white,
          fontFamilyFallback: ['Roboto']),
      bodyMedium: const TextStyle(
          fontSize: 20.0,
          fontFamily: 'Montserrat',
          color: Colors.white,
          fontFamilyFallback: ['Roboto']),
      // Dictionary card, dictionary  name
      bodySmall: const TextStyle(
          fontSize: 17.0,
          fontFamily: 'Montserrat',
          color: Colors.white,
          fontFamilyFallback: ['Roboto']),
    ),
    textSelectionTheme: const TextSelectionThemeData(
        selectionColor: Color.fromARGB(255, 14, 88, 66)),
    dialogTheme: const DialogTheme(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12))),
    ))
  ..addOwn(OwnThemeFields(
      spanColor: Colors.grey[400],
      errorShade: const Color.fromARGB(240, 200, 0, 0),
      textBaloon: const Color.fromARGB(255, 200, 80, 80),
      textSelectionPopupColor: const Color(0xFF1C2B3A)));
