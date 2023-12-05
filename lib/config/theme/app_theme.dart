import 'package:flutter/material.dart';

//const Color _customColor = Color.fromARGB(210, 158, 89, 152);
Color _customColor = Colors.purpleAccent.shade200;

List<Color> _colorThemes = [
  _customColor,
  Colors.blue,
  Colors.teal,
  Colors.green,
  Colors.yellow,
  Colors.orange,
  Colors.pink,

];

class AppTheme{

  final int selectedColor;

  AppTheme({ this.selectedColor = 0 })
    : assert(selectedColor >= 0 && selectedColor <= _colorThemes.length - 1,
      'Colors must be between 0 and ${_colorThemes.length}');

  ThemeData getTheme(){
    return ThemeData( useMaterial3: true, colorSchemeSeed: _colorThemes[selectedColor]);
  }
}