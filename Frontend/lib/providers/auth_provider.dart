import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../l10n/app_localizations.dart';
import '../utils/api_service.dart';
import '../utils/environment_config.dart';

enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider with ChangeNotifier {
  static const String _userKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  
  AuthState _authState = AuthState.initial;
  UserModel? _user;
  String? _errorMessage;
  String? _accessToken;
  String? _refreshToken;
  final ApiService _apiService = ApiService();
  
  AuthState get authState => _authState;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  String? get token => _accessToken;
  bool get isAuthenticated => _authState == AuthState.authenticated;
  bool get isLoading => _authState == AuthState.loading;
  
  AuthProvider() {
    _checkAuthStatus();
  }
  
  Future<void> _checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
      
      if (isLoggedIn) {
        final userData = prefs.getString(_userKey);
        if (userData != null) {
          _user = UserModel.fromJson(userData);
          await _loadTokens(); // Load saved tokens
          _authState = AuthState.authenticated;
        } else {
          _authState = AuthState.unauthenticated;
        }
      } else {
        _authState = AuthState.unauthenticated;
      }
      notifyListeners();
    } catch (e) {
      _authState = AuthState.error;
      _errorMessage = 'Error checking authentication status';
      notifyListeners();
    }
  }
  
  Future<void> checkAuthStatus(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
      
      if (isLoggedIn) {
        final userData = prefs.getString(_userKey);
        if (userData != null) {
          _user = UserModel.fromJson(userData);
          _authState = AuthState.authenticated;
        } else {
          _authState = AuthState.unauthenticated;
        }
      } else {
        _authState = AuthState.unauthenticated;
      }
      notifyListeners();
    } catch (e) {
      _authState = AuthState.error;
      if (context.mounted) {
        _errorMessage = AppLocalizations.of(context)!.errorCheckingAuth;
      } else {
        _errorMessage = 'Error checking authentication status';
      }
      notifyListeners();
    }
  }
  
  Future<bool> login(BuildContext context, String email, String password) async {
    _setLoading(true);
    
    try {
      // Basic validation
      if (email.isEmpty || password.isEmpty) {
        final errorMsg = context.mounted 
            ? AppLocalizations.of(context)!.emailPasswordRequired
            : 'Email and password are required';
        throw Exception(errorMsg);
      }
      
      if (!_isValidEmail(email)) {
        final errorMsg = context.mounted 
            ? AppLocalizations.of(context)!.emailInvalid
            : 'Invalid email format';
        throw Exception(errorMsg);
      }
      
      if (password.length < 12) {
        final errorMsg = context.mounted 
            ? AppLocalizations.of(context)!.passwordTooShort
            : 'Password must be at least 12 characters';
        throw Exception(errorMsg);
      }
      
      // Prepare request body according to backend expectations
      final requestBody = {
        'email': email.trim().toLowerCase(),
        'password': password,
      };
      
      // Log configuration for debugging
      if (EnvironmentConfig.isDevelopment) {
        EnvironmentConfig.logConfiguration();
        print('🔄 Making login request to: ${EnvironmentConfig.loginEndpoint}');
        print('📤 Request body: $requestBody');
      }
      
      // Make API call to backend
      final response = await _apiService.post(
        EnvironmentConfig.loginEndpoint,
        body: requestBody,
        withCredentials: true,
      );
      
      if (EnvironmentConfig.isDevelopment) {
        print('📥 Login response: ${response.statusCode} - ${response.message}');
        print('📊 Response data: ${response.data}');
      }
      
      if (response.success) {
        // Parse response data
        final responseData = response.data as Map<String, dynamic>?;
        
        if (responseData != null) {
          // Extract tokens from LoginResponseDto structure
          _accessToken = responseData['accessToken'] as String?;
          // Note: refreshToken comes in HttpOnly cookie, not in response body as per backend security
          
          // Create user from LoginResponseDto fields
          _user = UserModel(
            id: responseData['userId'] ?? '',
            name: responseData['fullName'] ?? email.split('@').first,
            email: responseData['email'] ?? email,
            profileImage: null, // Profile image not included in login response
          );
          
          // Save user data and tokens
          await _saveUserData();
          if (_accessToken != null) {
            await _saveTokens();
          }
          
          _authState = AuthState.authenticated;
          _errorMessage = null;
          notifyListeners();
          
          return true;
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      if (EnvironmentConfig.isDevelopment) {
        print('❌ Login error: $e');
      }
      _authState = AuthState.unauthenticated;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> loginWithGoogle(BuildContext context) async {
    _setLoading(true);
    
    try {
      await Future.delayed(const Duration(seconds: 2));
      
      _user = UserModel(
        id: '2',
        name: 'Ximena',
        email: 'ximena@gmail.com',
        profileImage: null,
      );
      
      await _saveUserData();
      _authState = AuthState.authenticated;
      _errorMessage = null;
      notifyListeners();
      
      return true;
    } catch (e) {
      _authState = AuthState.error;
      if (context.mounted) {
        _errorMessage = AppLocalizations.of(context)!.googleSignInFailed;
      } else {
        _errorMessage = 'Google sign in failed';
      }
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> loginWithApple(BuildContext context) async {
    _setLoading(true);
    
    try {
      await Future.delayed(const Duration(seconds: 2));
      
      _user = UserModel(
        id: '3',
        name: 'Ximena',
        email: 'ximena@icloud.com',
        profileImage: null,
      );
      
      await _saveUserData();
      _authState = AuthState.authenticated;
      _errorMessage = null;
      notifyListeners();
      
      return true;
    } catch (e) {
      _authState = AuthState.error;
      if (context.mounted) {
        _errorMessage = AppLocalizations.of(context)!.appleSignInFailed;
      } else {
        _errorMessage = 'Apple sign in failed';
      }
      notifyListeners();
      return false;
    }
  }
  
  Future<void> logout(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      await prefs.setBool(_isLoggedInKey, false);
      await _clearTokens(); // Clear stored tokens
      
      _user = null;
      _authState = AuthState.unauthenticated;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      if (context.mounted) {
        _errorMessage = AppLocalizations.of(context)!.errorDuringLogout;
      } else {
        _errorMessage = 'Error during logout';
      }
      notifyListeners();
    }
  }
  
  void clearError() {
    _errorMessage = null;
    if (_authState == AuthState.error || _authState == AuthState.loading) {
      _authState = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  // Real API registration method
  Future<bool> register(BuildContext context, String fullName, String email, String password, String confirmPassword) async {
    _setLoading(true);
    
    try {
      // Basic validation
      if (fullName.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
        final errorMsg = context.mounted 
            ? AppLocalizations.of(context)!.emailPasswordRequired
            : 'All fields are required';
        throw Exception(errorMsg);
      }
      
      if (!_isValidEmail(email)) {
        final errorMsg = context.mounted 
            ? AppLocalizations.of(context)!.emailInvalid
            : 'Invalid email format';
        throw Exception(errorMsg);
      }
      
      if (password.length < 12) {
        final errorMsg = context.mounted 
            ? AppLocalizations.of(context)!.passwordTooShort
            : 'Password must be at least 12 characters';
        throw Exception(errorMsg);
      }
      
      if (password != confirmPassword) {
        final errorMsg = context.mounted 
            ? AppLocalizations.of(context)!.passwordTooShort
            : 'Passwords do not match';
        throw Exception(errorMsg);
      }
      
      // Prepare request body according to backend expectations
      final requestBody = {
        'fullName': fullName.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'confirmPassword': confirmPassword,
      };
      
      // Log configuration for debugging
      if (EnvironmentConfig.isDevelopment) {
        EnvironmentConfig.logConfiguration();
      }
      
      // Make API call
      final response = await _apiService.post(
        EnvironmentConfig.registerEndpoint,
        body: requestBody,
        withCredentials: true,
      );
      
      if (response.success) {
        // Parse response data
        final responseData = response.data as Map<String, dynamic>?;
        
        if (responseData != null) {
          // Extract tokens from RegisterResponseDto structure
          _accessToken = responseData['accessToken'] as String?;
          // Note: refreshToken comes in HttpOnly cookie, not in response body as per backend security
          _refreshToken = null; // Set to null since it comes via cookie
          
          // Create user from RegisterResponseDto fields
          _user = UserModel(
            id: responseData['userId'] ?? '',
            name: responseData['fullName'] ?? fullName,
            email: responseData['email'] ?? email,
            profileImage: null, // Profile image not included in registration response
          );
          
          // Save user data and tokens
          await _saveUserData();
          await _saveTokens();
          
          _authState = AuthState.authenticated;
          _errorMessage = null;
          notifyListeners();
          
          return true;
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      _authState = AuthState.unauthenticated;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Mock login method - always successful
  Future<void> mockLogin(BuildContext context) async {
    try {
      _setLoading(true);
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Create mock user
      _user = UserModel(
        id: 'mock_user_123',
        name: 'Usuario Demo',
        email: 'demo@example.com',
      );
      
      _authState = AuthState.authenticated;
      _errorMessage = null;
      
      // Save user data
      await _saveUserData();
      
      notifyListeners();
    } catch (e) {
      _authState = AuthState.error;
      if (context.mounted) {
        _errorMessage = AppLocalizations.of(context)!.errorInMockLogin;
      } else {
        _errorMessage = 'Error in mock login';
      }
      notifyListeners();
    }
  }
  
  void _setLoading(bool loading) {
    if (loading) {
      _authState = AuthState.loading;
      _errorMessage = null;
    } else {
      // Reset to unauthenticated when loading stops (if not authenticated)
      if (_authState == AuthState.loading) {
        _authState = AuthState.unauthenticated;
      }
    }
    notifyListeners();
  }
  
  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }
  
  Future<void> _saveUserData() async {
    if (_user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, _user!.toJson());
      await prefs.setBool(_isLoggedInKey, true);
    }
  }
  
  Future<void> _saveTokens() async {
    final prefs = await SharedPreferences.getInstance();
    if (_accessToken != null) {
      await prefs.setString(_tokenKey, _accessToken!);
    }
    if (_refreshToken != null) {
      await prefs.setString(_refreshTokenKey, _refreshToken!);
    }
  }
  
  Future<void> _loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_tokenKey);
    _refreshToken = prefs.getString(_refreshTokenKey);
  }
  
  Future<void> _clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    _accessToken = null;
    _refreshToken = null;
  }
}