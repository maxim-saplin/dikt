import 'package:flutter/material.dart';

class OwnThemeFields {
  final Color errorShade;
  final Color textBaloon;
  final Color spanColor;
  final Color textSelectionPopupColor;

  const OwnThemeFields(
      {Color? errorShade,
      Color? textBaloon,
      Color? spanColor,
      Color? textSelectionPopupColor})
      : errorShade = errorShade ?? Colors.red,
        textBaloon = textBaloon ?? Colors.black,
        spanColor = spanColor ?? Colors.black,
        textSelectionPopupColor = textSelectionPopupColor ?? Colors.black;
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
    // cardColor: Color.fromARGB(255, 240, 242, 243),
    // dialogBackgroundColor: Color.fromARGB(255, 240, 242, 243),
    backgroundColor: const Color.fromARGB(255, 240, 242, 243),
    canvasColor: const Color.fromARGB(255, 240, 242, 243),
    // scaffoldBackgroundColor: Color.fromARGB(255, 240, 242, 243),
    //visualDensity: VisualDensity(horizontal: -4, vertical: -4),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
            foregroundColor: MaterialStateProperty.all<Color>(Colors.black))),
    inputDecorationTheme: const InputDecorationTheme(
        focusedBorder: InputBorder.none,
        border: InputBorder.none,
        labelStyle: TextStyle(
            fontSize: 18, fontFamily: 'Montserrat', color: Colors.red)),
    colorScheme: const ColorScheme.light()
        .copyWith(secondary: Colors.grey.withAlpha(128)),
    textTheme: TextTheme(
      button: const TextStyle(
          fontSize: 18, fontFamily: 'Montserrat', color: Colors.black),
      headline6: const TextStyle(
        fontSize: 20.0,
        color: Colors.black,
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.bold,
      ),
      // standard TextField()
      subtitle1: const TextStyle(
        fontSize: 20.0,
        fontFamily: 'Montserrat',
        color: Colors.black,
      ),
      subtitle2: TextStyle(
        fontSize: 16.0,
        fontFamily: 'Montserrat',
        fontStyle: FontStyle.italic,
        color: Colors.black.withAlpha(128),
      ),
      // used for dictionary error text in Online dicts
      overline: const TextStyle(
          fontSize: 14.0,
          fontFamily: 'Montserrat',
          fontStyle: FontStyle.italic,
          color: Colors.black),
      // standard Text()
      bodyText2: const TextStyle(
          fontSize: 20.0, fontFamily: 'Montserrat', color: Colors.black),
      // italic Text()
      bodyText1: const TextStyle(
          fontSize: 20.0,
          fontFamily: 'Montserrat',
          fontStyle: FontStyle.italic,
          color: Colors.black),
      // Dictionary card, dictionary  name
      caption: const TextStyle(
          fontSize: 17.0, fontFamily: 'Montserrat', color: Colors.black),
    ))
  ..addOwn(const OwnThemeFields(
      errorShade: Color.fromARGB(240, 255, 200, 200),
      textBaloon: Color.fromARGB(240, 255, 200, 200),
      textSelectionPopupColor: Color.fromARGB(255, 255, 200, 200)));

final ThemeData darkTheme = ThemeData.dark().copyWith(
    cardColor: const Color.fromARGB(255, 32, 33, 36),
    dialogBackgroundColor: const Color.fromARGB(255, 32, 33, 36),
    canvasColor: const Color.fromARGB(255, 32, 33, 36),
    scaffoldBackgroundColor: const Color.fromARGB(255, 16, 17, 18),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
            foregroundColor: MaterialStateProperty.all<Color>(Colors.white))),
    colorScheme: const ColorScheme.dark().copyWith(secondary: Colors.green),
    backgroundColor: const Color.fromARGB(255, 32, 35, 36),
    buttonTheme: const ButtonThemeData(
        buttonColor: Colors.white, splashColor: Colors.white),
    textTheme: TextTheme(
      button: const TextStyle(fontSize: 18, fontFamily: 'Montserrat'),
      headline6: const TextStyle(
          fontSize: 20.0,
          color: Color.fromARGB(255, 240, 240, 240),
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.bold,
          fontFamilyFallback: ['Roboto']),
      subtitle1: const TextStyle(
          fontSize: 20.0,
          fontFamily: 'Montserrat',
          color: Colors.white,
          fontFamilyFallback: ['Roboto']),
      subtitle2: TextStyle(
          fontSize: 16.0,
          fontFamily: 'Montserrat',
          fontStyle: FontStyle.italic,
          color: Colors.white.withAlpha(128),
          fontFamilyFallback: const ['Roboto']),
      // used for dictionary error text in Online dicts
      overline: const TextStyle(
          fontSize: 14.0,
          fontFamily: 'Montserrat',
          fontStyle: FontStyle.italic,
          color: Colors.white,
          fontFamilyFallback: ['Roboto']),
      bodyText2: const TextStyle(
          fontSize: 20.0,
          fontFamily: 'Montserrat',
          color: Colors.white,
          fontFamilyFallback: ['Roboto']),
      // Dictionary card, dictionary  name
      caption: const TextStyle(
          fontSize: 17.0,
          fontFamily: 'Montserrat',
          color: Colors.white,
          fontFamilyFallback: ['Roboto']),
    ))
  ..addOwn(OwnThemeFields(
      spanColor: Colors.grey[400],
      errorShade: const Color.fromARGB(240, 200, 0, 0),
      textBaloon: const Color.fromARGB(255, 200, 80, 80),
      textSelectionPopupColor: const Color.fromARGB(255, 200, 80, 80)));
