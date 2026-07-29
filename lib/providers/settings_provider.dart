import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_helper.dart';

class AppSettings {
  final ThemeMode themeMode;
  final String language; // 'en' or 'ph'
  final bool isFirstTime;

  AppSettings({
    required this.themeMode,
    required this.language,
    required this.isFirstTime,
  });

  AppSettings copyWith({ThemeMode? themeMode, String? language, bool? isFirstTime}) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      isFirstTime: isFirstTime ?? this.isFirstTime,
    );
  }
}

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    _loadSettings();
    // Default state (Light mode is now the default per Task 4)
    return AppSettings(themeMode: ThemeMode.light, language: 'en', isFirstTime: true);
  }

  Future<void> _loadSettings() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final data = await db.query('user_settings', limit: 1);

      if (data.isNotEmpty) {
        final row = data.first;
        final themeStr = row['theme_mode'] as String? ?? 'light';
        final langStr = row['language'] as String? ?? 'en';
        final isFirst = (row['is_first_time'] as int? ?? 1) == 1;

        state = AppSettings(
          themeMode: themeStr == 'dark' ? ThemeMode.dark : ThemeMode.light,
          language: langStr,
          isFirstTime: isFirst,
        );
      }
    } catch (_) {}
  }

  Future<void> toggleTheme(bool isDark) async {
    final newMode = isDark ? ThemeMode.dark : ThemeMode.light;
    state = state.copyWith(themeMode: newMode);

    final db = await DatabaseHelper.instance.database;
    await db.update('user_settings', {'theme_mode': isDark ? 'dark' : 'light'}, where: 'id = 1');
  }

  Future<void> setLanguage(String langCode) async {
    state = state.copyWith(language: langCode);
    final db = await DatabaseHelper.instance.database;
    await db.update('user_settings', {'language': langCode}, where: 'id = 1');
  }

  Future<void> completeTutorial() async {
    state = state.copyWith(isFirstTime: false);
    final db = await DatabaseHelper.instance.database;
    await db.update('user_settings', {'is_first_time': 0}, where: 'id = 1');
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(() {
  return SettingsNotifier();
});
