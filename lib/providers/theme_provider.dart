import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _primaryColorKey = 'primary_color';
  static const String _useDynamicColorsKey = 'use_dynamic_colors';
  static const String _fontSizeKey = 'font_size';
  
  late SharedPreferences _prefs;
  ThemeMode _themeMode = ThemeMode.system;
  Color _primaryColor = Colors.blue;
  bool _useDynamicColors = true;
  double _fontSize = 1.0;
  bool _isDarkMode = false;

  static const Map<String, Color> colorPalette = {
    'Gün Batımı': Color(0xFFFF7B54),
    'Okyanus': Color(0xFF6C9BCF),
    'Orman': Color(0xFF539165),
    'Lavanta': Color(0xFF9376E0),
    'Mercan': Color(0xFFFF8787),
    'Gökyüzü': Color(0xFF85CDFD),
    'Safran': Color(0xFFFFB84C),
    'Nane': Color(0xFF98D8AA),
  };

  ThemeProvider() {
    _loadPreferences();
  }

  // Getter methods
  ThemeMode get themeMode => _themeMode;
  Color get primaryColor => _primaryColor;
  bool get useDynamicColors => _useDynamicColors;
  double get fontSize => _fontSize;
  bool get isDarkMode => _isDarkMode;
  
  ThemeData get themeData => isDarkMode ? getThemeData(true) : getThemeData(false);

  // Initialize preferences
  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Load theme mode
    final themeModeString = _prefs.getString(_themeKey) ?? 'system';
    _themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.toString() == 'ThemeMode.$themeModeString',
      orElse: () => ThemeMode.system,
    );

    // Load dark mode preference
    _isDarkMode = _prefs.getBool('isDarkMode') ?? false;

    // Load primary color
    final colorValue = _prefs.getInt(_primaryColorKey) ?? Colors.blue.value;
    _primaryColor = Color(colorValue);

    // Load dynamic colors preference
    _useDynamicColors = _prefs.getBool(_useDynamicColorsKey) ?? true;

    // Load font size
    _fontSize = _prefs.getDouble(_fontSizeKey) ?? 1.0;

    notifyListeners();
  }

  // Update theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      await _prefs.setString(_themeKey, mode.toString().split('.').last);
      notifyListeners();
    }
  }

  // Toggle dark mode
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    _themeMode = _isDarkMode ? ThemeMode.dark : ThemeMode.light;
    await _prefs.setBool('isDarkMode', _isDarkMode);
    await _prefs.setString(_themeKey, _themeMode.toString().split('.').last);
    notifyListeners();
  }

  // Update primary color
  Future<void> setPrimaryColor(Color color) async {
    if (_primaryColor != color) {
      _primaryColor = color;
      await _prefs.setInt(_primaryColorKey, color.value);
      notifyListeners();
    }
  }

  // Toggle dynamic colors
  Future<void> toggleDynamicColors() async {
    _useDynamicColors = !_useDynamicColors;
    await _prefs.setBool(_useDynamicColorsKey, _useDynamicColors);
    notifyListeners();
  }

  // Update font size
  Future<void> setFontSize(double scale) async {
    if (_fontSize != scale) {
      _fontSize = scale.clamp(0.8, 1.4); // Limit scale between 80% and 140%
      await _prefs.setDouble(_fontSizeKey, _fontSize);
      notifyListeners();
    }
  }

  // Get theme data based on current settings
  ThemeData getThemeData(bool isDark) {
    final base = isDark ? ThemeData.dark() : ThemeData.light();
    
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: isDark ? Brightness.dark : Brightness.light,
    ).copyWith(
      primary: _primaryColor,
      secondary: _primaryColor.withOpacity(0.8),
      tertiary: _primaryColor.withOpacity(0.6),
    );

    return base.copyWith(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: base.textTheme.apply(fontSizeFactor: _fontSize),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: isDark ? Colors.grey[900] : colorScheme.primary,
        foregroundColor: isDark ? colorScheme.onSurface : Colors.white,
      ),
      scaffoldBackgroundColor: isDark 
          ? colorScheme.background 
          : Color.lerp(colorScheme.primary, Colors.white, 0.9),
    );
  }

  // Reset all theme settings to defaults
  Future<void> resetToDefaults() async {
    await _prefs.remove(_themeKey);
    await _prefs.remove(_primaryColorKey);
    await _prefs.remove(_useDynamicColorsKey);
    await _prefs.remove(_fontSizeKey);
    await _prefs.remove('isDarkMode');
    
    _themeMode = ThemeMode.system;
    _primaryColor = Colors.blue;
    _useDynamicColors = true;
    _fontSize = 1.0;
    _isDarkMode = false;
    
    notifyListeners();
  }
}
