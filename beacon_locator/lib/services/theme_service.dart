import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  ThemeService._();

  static const _themeKey = 'theme_mode';

  static Future<bool> isDarkTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey) != 'light';
  }

  static Future<void> setDarkTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _themeKey,
      isDark ? 'dark' : 'light',
    );
  }
}