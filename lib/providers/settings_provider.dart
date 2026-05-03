import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';

class SettingsProvider extends ChangeNotifier {
  static const _key = 'app_settings';
  AppSettings _settings = const AppSettings();

  AppSettings get settings => _settings;

  SettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_key);
      if (json != null) {
        _settings = AppSettings.fromJson(jsonDecode(json) as Map<String, dynamic>);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[SettingsProvider] Load error: $e');
    }
  }

  Future<void> update(AppSettings newSettings) async {
    _settings = newSettings;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(_settings.toJson()));
    } catch (e) {
      debugPrint('[SettingsProvider] Save error: $e');
    }
  }
}
