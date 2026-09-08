import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class Storage {
  static const key = 'ironclock_data_v1';

  /// A workout in progress, saved separately from [key] so it can be
  /// restored (or cleared, once finished/abandoned) independently of the
  /// rest of the app's data.
  static const sessionKey = 'ironclock_session_v1';

  static Future<AppData> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null) return AppData();
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return AppData.fromJson(decoded);
    } catch (e) {
      return AppData();
    }
  }

  static Future<void> save(AppData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(data.toJson()));
    } catch (e) {
      // ignore save failures; data stays in memory for this session
    }
  }

  static Future<Map<String, dynamic>?> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(sessionKey);
      if (raw == null) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Saves the in-progress workout, or clears it when [session] is null
  /// (the workout finished or was abandoned).
  static Future<void> saveSession(Map<String, dynamic>? session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (session == null) {
        await prefs.remove(sessionKey);
      } else {
        await prefs.setString(sessionKey, jsonEncode(session));
      }
    } catch (e) {
      // ignore save failures; session stays in memory for this run
    }
  }
}
