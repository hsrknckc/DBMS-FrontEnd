import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final schemaProvider = StateNotifierProvider<SchemaNotifier, Map<String, String>>((ref) {
  return SchemaNotifier();
});

class SchemaNotifier extends StateNotifier<Map<String, String>> {
  SchemaNotifier() : super({}) {
    _loadFromPrefs();
  }

  static const _prefsKey = 'app_schema_types';

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_prefsKey);
      if (jsonStr != null) {
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        final map = decoded.map((key, value) => MapEntry(key, value.toString()));
        state = map;
      }
    } catch (e) {
      state = {};
    }
  }

  Future<void> setCustomType(String dbName, String colName, String key, String type) async {
    final customKey = '${dbName}_${colName}_$key';
    final newState = Map<String, String>.from(state);
    newState[customKey] = type;
    state = newState;
    await _saveToPrefs(newState);
  }

  Future<void> removeCustomType(String dbName, String colName, String key) async {
    final customKey = '${dbName}_${colName}_$key';
    final newState = Map<String, String>.from(state);
    newState.remove(customKey);
    state = newState;
    await _saveToPrefs(newState);
  }

  Future<void> setMultipleCustomTypes(Map<String, String> types) async {
    final newState = Map<String, String>.from(state);
    newState.addAll(types);
    state = newState;
    await _saveToPrefs(newState);
  }

  Future<void> _saveToPrefs(Map<String, String> newState) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(newState);
      await prefs.setString(_prefsKey, jsonStr);
    } catch (_) {}
  }
}
