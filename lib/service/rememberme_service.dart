import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RememberMeService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  
  //? Storage keys
  static const String _rememberMeKey = 'remember_me';
  static const String _savedEmailKey = 'saved_email';
  static const String _savedPasswordKey = 'saved_password';
  
  //? Singleton pattern
  static final RememberMeService _instance = RememberMeService._internal();
  factory RememberMeService() => _instance;
  RememberMeService._internal();
  
  //? Save remember me preference and credentials
  Future<void> saveRememberMe({
    required bool rememberMe,
    String? email,
    String? password,
  }) async {
    //? Always clear previous credentials first
    await clearCredentials();
    
    //? Save remember me preference
    await _storage.write(
      key: _rememberMeKey,
      value: rememberMe.toString(),
    );
    
    if (rememberMe && email != null && password != null) {
      //? Save new credentials securely
      await _storage.write(key: _savedEmailKey, value: email);
      await _storage.write(key: _savedPasswordKey, value: password);
    }
  }
  
  //? Get remember me preference
  Future<bool> getRememberMe() async {
    final value = await _storage.read(key: _rememberMeKey);
    return value == 'true';
  }
  
  //? Get saved credentials
  Future<Map<String, String?>> getSavedCredentials() async {
    final rememberMe = await getRememberMe();
    
    if (!rememberMe) {
      return {'email': null, 'password': null};
    }
    
    final email = await _storage.read(key: _savedEmailKey);
    final password = await _storage.read(key: _savedPasswordKey);
    
    return {
      'email': email,
      'password': password,
    };
  }
  
  //? Clear saved credentials
  Future<void> clearCredentials() async {
    await _storage.delete(key: _savedEmailKey);
    await _storage.delete(key: _savedPasswordKey);
  }
  
  //? Clear all remember me data
  Future<void> clearAll() async {
    await _storage.delete(key: _rememberMeKey);
    await clearCredentials();
  }
}