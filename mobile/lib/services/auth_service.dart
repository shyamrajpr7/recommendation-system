import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';

const _tokenKey = 'auth_token';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class AuthService {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  AuthService(this._dio, this._storage);

  Future<bool> get isLoggedIn async {
    final token = await _storage.read(key: _tokenKey);
    return token != null;
  }

  Future<void> login(String email, String password) async {
    try {
      final res = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      final token = res.data['access_token'] as String;
      await _storage.write(key: _tokenKey, value: token);
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'Login failed';
      throw AuthException(msg.toString());
    }
  }

  Future<void> signup(String name, String email, String password) async {
    try {
      final res = await _dio.post('/auth/signup', data: {
        'name': name,
        'email': email,
        'password': password,
      });
      final token = res.data['access_token'] as String;
      await _storage.write(key: _tokenKey, value: token);
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'Signup failed';
      throw AuthException(msg.toString());
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(dioProvider), ref.watch(secureStorageProvider));
});
