import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static const String _lastLoginEmailKey = 'last_login_email';
  
  static SharedPreferencesService? _instance;
  static SharedPreferences? _preferences;
  
  SharedPreferencesService._internal();
  
  static Future<SharedPreferencesService> getInstance() async {
    _instance ??= SharedPreferencesService._internal();
    _preferences ??= await SharedPreferences.getInstance();
    return _instance!;
  }
  
  // Store last login email
  Future<bool> setLastLoginEmail(String email) async {
    return await _preferences!.setString(_lastLoginEmailKey, email);
  }
  
  // Get last login email
  String? getLastLoginEmail() {
    return _preferences!.getString(_lastLoginEmailKey);
  }
  
  // Clear last login email
  Future<bool> clearLastLoginEmail() async {
    return await _preferences!.remove(_lastLoginEmailKey);
  }
}

