import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'mock_mode.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  Future<UserModel> login(String email, String password) async {
    if (kMockMode) {
      if (email.contains('@')) {
        final mockUser = UserModel(
          id: 'mock-user-001',
          name: 'Test User',
          email: email,
          role: null,
          points: 90,
          acceptedGuidelines: false,
          isOnline: false,
          licenseVerified: false,
        );
        _mockUser = mockUser;
        await saveToken('mock-token-123');
        return mockUser;
      } else {
        throw ApiException('Invalid email format');
      }
    }

    try {
      final response = await _apiService.post('/auth/login', {
        'email': email,
        'password': password,
      }).timeout(const Duration(seconds: 10));
      
      final data = response;
      await saveToken(data['token']);
      return UserModel.fromJson(data['user']);
    } on TimeoutException catch (_) {
      throw ApiException('Login timed out. Please try again.');
    } catch (e) {
      if (e.toString().contains('timeout')) {
        throw ApiException('Login timed out. Please try again.');
      }
      rethrow;
    }
  }

  Future<UserModel> register(String name, String email, String password) async {
    if (kMockMode) {
      final mockUser = UserModel(
        id: 'mock-user-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: email,
        role: null,
        points: 0,
        acceptedGuidelines: false,
      );
      _mockUser = mockUser;
      await saveToken('mock-token-${mockUser.id}');
      return mockUser;
    }

    try {
      final response = await _apiService.post('/auth/register', {
        'name': name,
        'email': email,
        'password': password,
      }).timeout(const Duration(seconds: 10));

      final data = response;
      await saveToken(data['token']);
      return UserModel.fromJson(data['user']);
    } on TimeoutException catch (_) {
      throw ApiException('Registration timed out. Please try again.');
    } catch (e) {
      if (e.toString().contains('timeout')) {
        throw ApiException('Registration timed out. Please try again.');
      }
      rethrow;
    }
  }

  static UserModel? _mockUser;

  Future<UserModel> getCurrentUser() async {
    if (kMockMode) {
      return _mockUser ?? UserModel(
        id: 'mock-user-001',
        name: 'Test User',
        email: 'test@college.edu',
        role: null,
        points: 90,
        acceptedGuidelines: false,
      );
    }
    
    final response = await _apiService.get('/auth/me');
    return UserModel.fromJson(response);
  }

  Future<void> logout() async {
    if (kMockMode) {
      _mockUser = null;
    }
    if (!kMockMode) {
      try {
        await _apiService.post('/auth/logout', {});
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  bool validateCollegeEmail(String email) {
    return email.contains('@') && (email.endsWith('.edu') || email.contains('college'));
  }
}
