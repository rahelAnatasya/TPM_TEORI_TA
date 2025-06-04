import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUsername = 'username';
  static const String _keyEmail = 'email';
  static const String _keyTimeZone = 'timezone';

  // Singleton instance
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() {
    return _instance;
  }
  SessionManager._internal();

  // Menyimpan status login dan data user
  Future<void> saveUserSession({
    required bool isLoggedIn,
    String? username,
    String? email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, isLoggedIn);
    if (username != null) await prefs.setString(_keyUsername, username);
    if (email != null) await prefs.setString(_keyEmail, email);
  }

  // Menghapus session user
  Future<void> clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyEmail);
  }

  // Mendapatkan status login
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // Mendapatkan username
  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }

  // Mendapatkan email user
  Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail);
  }

  // Menyimpan pilihan timezone
  Future<void> saveTimeZone(String timeZone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTimeZone, timeZone);
  }

  // Mendapatkan pilihan timezone
  Future<String?> getTimeZone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyTimeZone);
  }
}
