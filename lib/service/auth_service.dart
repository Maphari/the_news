import 'dart:developer';

// ignore: depend_on_referenced_packages
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:io';

import 'package:the_news/config/env_config.dart';
import 'package:the_news/model/auth_results_model.dart';
import 'package:the_news/model/auth_userdata_model.dart';

//? baseurl for the server
final EnvConfig _config = EnvConfig();
String? get backendUrl => _config.get('API_BASE_URL');

class AuthService {
  //? Secure storage for tokens
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  //? Keys for storage
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  //? Initialization state
  Future<void>? _initialization;

  //? Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  //? Initialization
  Future<void> _ensureInitialized() {
    return _initialization ??=
        GoogleSignInPlatform.instance.init(const InitParameters())
          ..catchError((dynamic _) {
            _initialization = null;
          });
  }

  //? SAVE AUTH DATA (used by all login methods)
  Future<void> saveAuthData({
    required String token,
    required Map<String, dynamic> userData,
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userKey, value: jsonEncode(userData));
  }

  //? Validate token with backend (optional but recommended)
  Future<bool> validateToken() async {
    try {
      final token = await getToken();

      if (token == null || token.isEmpty) {
        return false;
      }

      //? Make a request to your backend to verify the token
      final response = await http.get(
        Uri.parse('$backendUrl/auth/validate-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        //? Token is invalid, clear storage
        await clearSecureStorage();
        return false;
      }
    } catch (e) {
      log('Error validating token: $e');
      return false;
    }
  }

  //? sign in with google
  Future<AuthResultsModel> signInWithGoogle() async {
    try {
      await _ensureInitialized();

      //? Attempt authentication
      final AuthenticationResults result = await GoogleSignInPlatform.instance
          .authenticate(const AuthenticateParameters());

      final user = result.user;

      //? Get authentication tokens
      final ClientAuthorizationTokenData? tokens = await GoogleSignInPlatform
          .instance
          .clientAuthorizationTokensForScopes(
            ClientAuthorizationTokensForScopesParameters(
              request: AuthorizationRequestDetails(
                scopes: const ['email', 'profile'],
                userId: user.id,
                email: user.email,
                promptIfUnauthorized: false, //* Avoid double prompt
              ),
            ),
          );

      if (tokens == null || tokens.accessToken.isEmpty) {
        return AuthResultsModel(
          success: false,
          error: 'Failed to get authentication tokens',
        );
      }

      //? Send token to your backend
      final response = await http.post(
        Uri.parse('$backendUrl/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'accessToken': tokens.accessToken,
          'provider': 'Google',
          'email': user.email,
          'name': user.displayName,
          'photoUrl': user.photoUrl,
          'userId': user.id,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        //? save data to secure storage
        await saveAuthData(token: data['token'], userData: data['user']);

        return AuthResultsModel(
          success: true,
          token: data['token'],
          user: AuthUserdataModel.fromJson(data['user']),
        );
      } else {
        return AuthResultsModel(
          success: false,
          error: 'Backend authentication failed: ${response.body}',
        );
      }
    } on GoogleSignInException catch (e) {
      return AuthResultsModel(
        success: false,
        error: e.code == GoogleSignInExceptionCode.canceled
            ? 'Sign in cancelled'
            : 'GoogleSignInException ${e.code}: ${e.description}',
      );
    } catch (error) {
      log('❌ Sign in error: $error');
      return AuthResultsModel(success: false, error: error.toString());
    }
  }

  //? Sign in with apple
  Future<AuthResultsModel> signInWithApple() async {
    try {
      //? Check if Apple Sign In is available
      if (!Platform.isIOS && !Platform.isMacOS) {
        return AuthResultsModel(
          success: false,
          error: 'Apple Sign In only available on iOS/macOS',
        );
      }

      //? Trigger Apple Sign In flow
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      if (credential.identityToken == null) {
        return AuthResultsModel(
          success: false,
          error: 'Failed to get identity token',
        );
      }

      //? Send to your backend
      final response = await http.post(
        Uri.parse('$backendUrl/auth/apple'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identityToken': credential.identityToken,
          'authorizationCode': credential.authorizationCode,
          'givenName': credential.givenName,
          'familyName': credential.familyName,
          'email': credential.email,
          'provider': 'Apple',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        //? Use unified save method
        await saveAuthData(token: data['token'], userData: data['user']);

        return AuthResultsModel(
          success: true,
          token: data['token'],
          user: AuthUserdataModel.fromJson(data['user']),
        );
      } else {
        return AuthResultsModel(
          success: false,
          error: 'Backend authentication failed: ${response.body}',
        );
      }
    } catch (error) {
      return AuthResultsModel(success: false, error: error.toString());
    }
  }

  //? TOKEN MANAGEMENT
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final userJson = await _storage.read(key: _userKey);
    if (userJson != null) {
      return jsonDecode(userJson) as Map<String, dynamic>;
    }
    return null;
  }

  Future<bool> isAuthenticated({bool validateWithBackend = false}) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      return false;
    }

    // Optionally validate with backend
    if (validateWithBackend) {
      return await validateToken();
    }

    return true;
  }

  //? Refresh user data from backend
  Future<Map<String, dynamic>?> refreshUserData() async {
    try {
      final response = await authenticatedRequest(
        endpoint: '/auth/me',
        method: 'GET',
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        await _storage.write(key: _userKey, value: jsonEncode(userData));
        return userData;
      }

      return null;
    } catch (e) {
      log('Error refreshing user data: $e');
      return null;
    }
  }

  Future<void> clearSecureStorage() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }

  //? SIGN OUT (works for all auth methods)
  Future<void> signOut() async {
    try {
      await _ensureInitialized();

      //? Sign out from Google
      await GoogleSignInPlatform.instance.disconnect(const DisconnectParams());

      //? Clear stored data
      await clearSecureStorage();
    } catch (error) {
      //? Still clear local data even if Google sign out fails
      await clearSecureStorage();
    }
  }

  //? AUTHENTICATED REQUESTS (works for all auth methods)
  Future<http.Response> authenticatedRequest({
    required String endpoint,
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final token = await getToken();

    if (token == null) {
      throw Exception('Not authenticated');
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final uri = Uri.parse('$backendUrl$endpoint');

    switch (method.toUpperCase()) {
      case 'GET':
        return await http.get(uri, headers: headers);
      case 'POST':
        return await http.post(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'PUT':
        return await http.put(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'DELETE':
        return await http.delete(uri, headers: headers);
      default:
        throw Exception('Unsupported HTTP method: $method');
    }
  }
}
