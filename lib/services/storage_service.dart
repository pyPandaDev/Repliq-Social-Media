import 'package:get_storage/get_storage.dart';

class StorageService {
  static final _storage = GetStorage();
  static const _userSessionKey = 'user_session';

  static Map<String, dynamic>? get userSession {
    final data = _storage.read(_userSessionKey);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  static Future<void> saveUserSession(Map<String, dynamic> session) async {
    try {
      await _storage.write(_userSessionKey, session);
    } catch (e) {
      print('Failed to save user session: $e');
      throw Exception('Failed to save user session');
    }
  }

  static Future<void> clearUserSession() async {
    try {
      await _storage.remove(_userSessionKey);
    } catch (e) {
      print('Failed to clear user session: $e');
      throw Exception('Failed to clear user session');
    }
  }

  static Future<void> clearAll() async {
    try {
      await _storage.erase();
    } catch (e) {
      print('Failed to clear storage: $e');
      throw Exception('Failed to clear storage');
    }
  }
}