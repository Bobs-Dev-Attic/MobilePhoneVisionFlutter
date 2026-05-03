import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/app_settings.dart';

class SettingsProvider extends ChangeNotifier {
  static const _key = 'app_settings';
  static const _openaiApiKey = 'openai_api_key';
  static const _anthropicApiKey = 'anthropic_api_key';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
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
        _settings = _settings.copyWith(
          openaiApiKey: await _secureStorage.read(key: _openaiApiKey) ?? '',
          anthropicApiKey: await _secureStorage.read(key: _anthropicApiKey) ?? '',
        );
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
      await prefs.setString(_key, jsonEncode(_settings.copyWith(openaiApiKey: '', anthropicApiKey: '').toJson()));
      await _secureStorage.write(key: _openaiApiKey, value: _settings.openaiApiKey);
      await _secureStorage.write(key: _anthropicApiKey, value: _settings.anthropicApiKey);
    } catch (e) {
      debugPrint('[SettingsProvider] Save error: $e');
    }
  }
}
