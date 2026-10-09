import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';
import '../../services/mock_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  final SocketService _socketService;

  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _errorMessage;
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _isTestMode = false;

  UserProvider(this._socketService, {bool isTestMode = false}) {
    _isTestMode = isTestMode;
    if (!_isTestMode) {
      loadUser();
    }
  }

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  String? get errorMessage => _errorMessage;

  String? get userName => _currentUser?.name;
  String? get collegeName => _currentUser?.collegeName;
  String? get serviceArea => _currentUser?.serviceArea;
  String? get prn => _currentUser?.prn;
  String? get vehicleType => _currentUser?.vehicleType;
  String? get vehicleNumber => _currentUser?.vehicleNumber;
  String? get course => _currentUser?.course;
  String? get yearOfStudy => _currentUser?.yearOfStudy;
  String? get avatarUrl => _currentUser?.avatarUrl;
  String? get licensePhoto => _currentUser?.licensePhoto;
  String? get rcPhoto => _currentUser?.rcPhoto;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get locationEnabled => _locationEnabled;

  bool get isRider => _currentUser?.role == 'rider';
  bool get isPassenger => _currentUser?.role == 'passenger';
  bool get hasSelectedRole => _currentUser?.role != null;

  void updateAvatar(String url) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(avatarUrl: url);
      notifyListeners();
    }
  }

  void clearAvatar() {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(clearAvatar: true);
      notifyListeners();
    }
  }

  void setNotificationsEnabled(bool value) {
    _notificationsEnabled = value;
    notifyListeners();
  }

  void setLocationEnabled(bool value) {
    _locationEnabled = value;
    notifyListeners();
  }

  Future<void> setRole(dynamic role) async {
    final roleStr = role.toString().split('.').last;
    await updateRole(roleStr);
  }

  void setUserProfile({
    String? name,
    String? phoneNumber,
    String? collegeName,
    String? prn,
    String? course,
    String? yearOfStudy,
    String? vehicleType,
    String? vehicleNumber,
    String? drivingLicense,
    String? serviceArea,
  }) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        name: name ?? _currentUser!.name,
        phoneNumber: phoneNumber,
        collegeName: collegeName,
        prn: prn,
        course: course,
        yearOfStudy: yearOfStudy,
        vehicleType: vehicleType,
        vehicleNumber: vehicleNumber,
        drivingLicense: drivingLicense,
        serviceArea: serviceArea,
      );
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    if (kMockMode) {
      // Mock login returns instantly with a mock user
      _currentUser = UserModel(
        id: 'mock-user-123',
        name: 'Mock User',
        email: email,
        role: null,
        acceptedGuidelines: false,
        points: 100,
      );
      notifyListeners();
      return;
    }

    _setLoading(true);
    _errorMessage = null;
    try {
      _currentUser = await _authService
          .login(email, password)
          .timeout(const Duration(seconds: 10));
      await _saveUserToPrefs(_currentUser!);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _currentUser = await _authService.register(name, email, password);
      await _saveUserToPrefs(_currentUser!);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshPoints() async {
    await loadUser();
  }

  Future<void> loadUser() async {
    if (_isTestMode) return;
    try {
      if (_currentUser == null) {
        _isInitializing = true;
      }
      _isLoading = true;
      notifyListeners();
      
      final prefs = await SharedPreferences.getInstance();
      if (_isTestMode) return;
      final token = prefs.getString('jwt_token');
      
      if (token == null) {
        if (_isTestMode) return;
        _currentUser = null;
        _isInitializing = false;
        notifyListeners();
        return;
      }
      
      // Connect socket if token exists
      _socketService.connect(token);
      
      // Try to load from cache first
      await _loadUserFromPrefs();
      if (_isTestMode) return;
      if (_currentUser != null) {
        notifyListeners();
      }
      
      // Try fresh from API
      if (!kMockMode && !_isTestMode) {
        try {
          final user = await _authService.getCurrentUser();
          if (_isTestMode) return;
          _currentUser = user;
          await _saveUserToPrefs(user);
          notifyListeners();
        } on ApiException catch (e) {
          // Only log out if it's a definitive unauthorized error
          if (e.message.toLowerCase().contains('unauthorized') || 
              e.message.toLowerCase().contains('invalid token') ||
              e.message.toLowerCase().contains('expired')) {
            debugPrint('[UserProvider] Auth failure - logging out: ${e.message}');
            await logout();
          } else {
            debugPrint('[UserProvider] API refresh failed (retaining session): $e');
          }
        } catch (e) {
          debugPrint('[UserProvider] Non-API refresh error (retaining session): $e');
        }
      }
    } finally {
      if (!_isTestMode) {
        _isInitializing = false;
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _saveUserToPrefs(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', user.id);
      await prefs.setString('user_name', user.name);
      await prefs.setString('user_email', user.email);
      await prefs.setString('user_role', user.role ?? '');
      await prefs.setBool('accepted_guidelines', user.acceptedGuidelines);
      await prefs.setInt('user_points', user.points);
      await prefs.setBool('is_online', user.isOnline);
      await prefs.setString('verification_status', user.verificationStatus ?? 'unverified');
      await prefs.setString('verification_note', user.verificationNote ?? '');
      debugPrint('[UserProvider] Saved user to SharedPreferences');
    } catch (e) {
      debugPrint('[UserProvider] Error saving user to prefs: $e');
    }
  }

  Future<void> _loadUserFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString('user_id');
      if (id != null) {
        _currentUser = UserModel(
          id: id,
          name: prefs.getString('user_name') ?? '',
          email: prefs.getString('user_email') ?? '',
          role: prefs.getString('user_role') == '' ? null : prefs.getString('user_role'),
          acceptedGuidelines: prefs.getBool('accepted_guidelines') ?? false,
          points: prefs.getInt('user_points') ?? 0,
          isOnline: prefs.getBool('is_online') ?? false,
          verificationStatus: prefs.getString('verification_status') ?? 'unverified',
          verificationNote: prefs.getString('verification_note') ?? '',
        );
        debugPrint('[UserProvider] Loaded user from SharedPreferences: ${_currentUser?.name}');
      }
    } catch (e) {
      debugPrint('[UserProvider] Error loading user from prefs: $e');
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.logout();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _currentUser = null;
    } catch (e) {
      debugPrint('[UserProvider] Error during logout: $e');
      // Still clear local state even if API logout fails
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateRole(String role) async {
    _currentUser = _currentUser?.copyWith(role: role);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', role);
    } catch (e) {
      debugPrint('[UserProvider] Error saving role to prefs: $e');
    }
    
    if (!kMockMode && !_isTestMode) {
      _apiService.patch('/users/role', {'role': role}).then((response) {
        if (response is Map<String, dynamic>) {
          _currentUser = UserModel.fromJson(response);
          notifyListeners();
        }
      }).catchError((e) {
        debugPrint('[UserProvider] Error patching role to server: $e');
      });
    }
  }

  Future<void> switchRole() async {
    if (_currentUser == null) return;
    final newRole = isRider ? 'passenger' : 'rider';
    await updateRole(newRole);
  }

  Future<void> clearRole() async {
    _currentUser = _currentUser?.copyWith(role: '');
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', '');
    } catch (e) {
      debugPrint('[UserProvider] Error saving cleared role to prefs: $e');
    }
    
    if (!kMockMode && !_isTestMode) {
      _apiService.patch('/users/role', {'role': ''}).catchError((e) {
        debugPrint('[UserProvider] Error patching cleared role to server: $e');
      });
    }
  }

  void addPoints(int points) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        points: _currentUser!.points + points,
      );
      notifyListeners();
    }
  }

  Future<void> acceptGuidelines() async {
    _setLoading(true);
    try {
      if (kMockMode) {
        _currentUser = _currentUser?.copyWith(acceptedGuidelines: true);
      } else {
        final response = await _apiService.patch('/users/guidelines', {});
        _currentUser = UserModel.fromJson(response);
      }

      if (_currentUser != null) {
        await _saveUserToPrefs(_currentUser!);
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> toggleOnline(bool isOnline) async {
    _setLoading(true);
    try {
      if (kMockMode) {
        _currentUser = _currentUser?.copyWith(isOnline: isOnline);
      } else {
        final response = await _apiService.patch('/users/online', {'is_online': isOnline});
        _currentUser = UserModel.fromJson(response);
      }
      if (_currentUser != null) {
        await _saveUserToPrefs(_currentUser!);
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    Future.microtask(() => notifyListeners());
  }


  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void setUserForTesting(UserModel user) {
    _isTestMode = true;
    _currentUser = user;
    _isInitializing = false;
    notifyListeners();
  }
}
