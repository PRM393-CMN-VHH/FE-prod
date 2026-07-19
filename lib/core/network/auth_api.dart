import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prm393/features/auth/models/user.dart';
import 'package:prm393/core/network/api_client_base.dart';

/// Sign up / sign in / session / profile.
mixin AuthApi on ApiClientBase {
  static const String _keyUser = 'api_user';

  UserModel? _currentUser;

  Future<void> requestOtp({required String email}) async {
    try {
      await request(ApiEndpoints.requestOtp, body: {"email": email});
    } catch (e) {
      throw Exception(friendlyRequestError(e));
    }
  }

  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String address,
    required String otp,
  }) async {
    final response = await request(
      ApiEndpoints.signUp,
      query: {'otp': otp},
      body: {
        "fullName": name,
        "phoneNumber": phone,
        "address": address,
        "email": email,
        "password": password,
      },
    );
    final user = UserModel.fromJson(response as Map<String, dynamic>);
    await _saveLocalUser(user);
    return user;
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final response = await request(
      ApiEndpoints.signIn,
      body: {"email": email, "password": password},
    );
    if (response is Map && response.containsKey('user')) {
      final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);
      await _saveLocalUser(user);
      return user;
    }
    throw Exception("Invalid response format from server");
  }

  Future<void> clearLocalSession() async {
    await clearSessionCookie();
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUser);
  }

  Future<void> signOut() async {
    try {
      await request(ApiEndpoints.signOut);
    } catch (_) {
      // Ignore API errors when signing out (e.g. if session is already invalid)
    } finally {
      await clearLocalSession();
    }
  }

  Future<UserModel?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;

    final cookie = await getSessionCookie();
    if (cookie == null) return null;

    try {
      final response = await request(ApiEndpoints.currentUser);
      if (response != null && response is Map<String, dynamic>) {
        final user = UserModel.fromJson(response);
        _currentUser = user;
        await _saveLocalUser(user);
        return user;
      }
    } catch (_) {
      await clearSessionCookie();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUser);
    }
    return null;
  }

  Future<UserModel> getProfile() async {
    dynamic response;
    try {
      response = await request(ApiEndpoints.profile);
    } catch (_) {
      response = await request(ApiEndpoints.currentUser);
    }
    if (response is Map<String, dynamic>) {
      final user = UserModel.fromJson(response);
      await _saveLocalUser(user);
      return user;
    }
    throw Exception("Invalid profile response from server");
  }

  Future<UserModel> updateProfile({
    required String name,
    required String phone,
    required String address,
  }) async {
    final response = await request(
      ApiEndpoints.profileUpdate,
      body: {"fullName": name, "phoneNumber": phone, "address": address},
    );
    if (response is Map<String, dynamic>) {
      final user = UserModel.fromJson(response);
      await _saveLocalUser(user);
      return user;
    }
    throw Exception("Invalid update profile response from server");
  }

  Future<void> _saveLocalUser(UserModel user) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
  }
}
