import 'package:chatbot/app_libs.dart';
import 'package:flutter/material.dart';

class AppTheme with ChangeNotifier {
  static bool _isDark = false;

   ThemeMode currentTheme() {
    return _isDark ? ThemeMode.dark : ThemeMode.light;
  }

  void switchingTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}
