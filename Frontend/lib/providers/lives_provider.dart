import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_lives_model.dart';
import '../utils/api_service.dart';
import '../utils/environment_config.dart';
import 'auth_provider.dart';

enum LivesState {
  initial,
  loading,
  loaded,
  consuming,
  consumed,
  blocked,
  error,
}

class LivesProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final AuthProvider _authProvider;
  
  LivesState _livesState = LivesState.initial;
  DailyLivesModel? _dailyLives;
  String? _errorMessage;
  Timer? _refreshTimer;
  
  // Offline handling
  final List<Map<String, dynamic>> _pendingActions = [];
  Timer? _retryTimer;
  bool _isOnline = true;
  
  // Configuration
  static const Duration _refreshInterval = Duration(minutes: 5);
  static const int _maxRetryAttempts = 3;
  static const String _livesKey = 'cached_lives';
  static const String _pendingActionsKey = 'pending_lives_actions';
  
  // Getters
  LivesState get livesState => _livesState;
  DailyLivesModel? get dailyLives => _dailyLives;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _livesState == LivesState.loading;
  bool get isConsuming => _livesState == LivesState.consuming;
  bool get hasLives => _dailyLives?.hasLivesAvailable ?? false;
  int get currentLives => _dailyLives?.currentLives ?? 0;
  bool get isBlocked => _livesState == LivesState.blocked || currentLives <= 0;
  String? get nextReset => _dailyLives?.nextReset;

  int get hoursUntilReset {
    if (_dailyLives?.nextReset == null) return 24;

    try {
      final resetTime = DateTime.parse(_dailyLives!.nextReset!);
      final now = DateTime.now();
      final difference = resetTime.difference(now);

      return difference.inHours.clamp(0, 24);
    } catch (e) {
      return 24;
    }
  }

  LivesProvider(this._authProvider) {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadCachedLives();
    if (_authProvider.isAuthenticated) {
      await fetchLivesStatus();
      _startPeriodicRefresh();
    }
    await _loadPendingActions();
  }

  /// Load cached lives data from SharedPreferences
  Future<void> _loadCachedLives() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedLives = prefs.getString(_livesKey);
      if (cachedLives != null) {
        final livesData = json.decode(cachedLives);
        _dailyLives = DailyLivesModel.fromJson(livesData);
        _livesState = LivesState.loaded;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading cached lives: $e');
      }
    }
  }

  /// Cache lives data to SharedPreferences
  Future<void> _cacheLives() async {
    if (_dailyLives != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_livesKey, json.encode(_dailyLives!.toJson()));
      } catch (e) {
        if (kDebugMode) {
          print('Error caching lives: $e');
        }
      }
    }
  }

  /// Fetch current lives status from API
  Future<void> fetchLivesStatus() async {
    if (!_authProvider.isAuthenticated) return;

    _setState(LivesState.loading);

    try {
      final response = await _apiService.get(
        '${EnvironmentConfig.fullApiUrl}/lives/status',
        token: await _getAuthToken(),
      );

      if (response.success) {
        final responseData = response.data;
        _dailyLives = DailyLivesModel.fromJson(responseData);
        _setState(LivesState.loaded);
        await _cacheLives();
        
        // Process any pending offline actions
        await _processPendingActions();
      } else {
        _handleApiError(response);
      }
    } catch (e) {
      _handleError('Failed to fetch lives status: $e');
    }
  }

  /// Consume a life when user makes an error
  Future<bool> consumeLife() async {
    if (!_authProvider.isAuthenticated) {
      _handleError('User not authenticated');
      return false;
    }

    // Check if user has lives available
    if (currentLives <= 0) {
      _setState(LivesState.blocked);
      return false;
    }

    _setState(LivesState.consuming);

    try {
      // If offline, queue the action
      if (!_isOnline) {
        await _queueOfflineAction('consume_life', {});
        // Optimistically update the UI
        if (_dailyLives != null) {
          _dailyLives = _dailyLives!.copyWith(
            currentLives: _dailyLives!.currentLives - 1,
            hasLivesAvailable: _dailyLives!.currentLives - 1 > 0,
          );
          await _cacheLives();
        }
        _setState(LivesState.consumed);
        return true;
      }

      final response = await _apiService.post(
        '${EnvironmentConfig.fullApiUrl}/lives/consume',
        token: await _getAuthToken(),
      );

      if (response.success) {
        final responseData = response.data;
        final consumeResponse = ConsumeLifeResponse.fromJson(responseData);
        
        // Update the lives model with new data
        if (_dailyLives != null) {
          _dailyLives = _dailyLives!.copyWith(
            currentLives: consumeResponse.currentLives,
            hasLivesAvailable: consumeResponse.hasLivesAvailable,
          );
          await _cacheLives();
        }

        _setState(consumeResponse.hasLivesAvailable 
            ? LivesState.consumed 
            : LivesState.blocked);
        return true;
        
      } else if (response.statusCode == 403) {
        // No lives available
        final errorData = response.data;
        final noLivesError = NoLivesException.fromJson(errorData);
        _handleError(noLivesError.message);
        _setState(LivesState.blocked);
        return false;
        
      } else {
        _handleApiError(response);
        return false;
      }
    } catch (e) {
      // If network error, queue for offline processing
      await _queueOfflineAction('consume_life', {});
      // Optimistically update the UI
      if (_dailyLives != null) {
        _dailyLives = _dailyLives!.copyWith(
          currentLives: _dailyLives!.currentLives - 1,
          hasLivesAvailable: _dailyLives!.currentLives - 1 > 0,
        );
        await _cacheLives();
      }
      _setState(LivesState.consumed);
      return true;
    }
  }

  /// Queue an action for offline processing
  Future<void> _queueOfflineAction(String action, Map<String, dynamic> data) async {
    final actionData = {
      'action': action,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'attempts': 0,
    };
    
    _pendingActions.add(actionData);
    await _savePendingActions();
    
    if (kDebugMode) {
      print('Queued offline action: $action');
    }
  }

  /// Load pending actions from SharedPreferences
  Future<void> _loadPendingActions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingData = prefs.getString(_pendingActionsKey);
      if (pendingData != null) {
        final List<dynamic> actions = json.decode(pendingData);
        _pendingActions.clear();
        _pendingActions.addAll(actions.cast<Map<String, dynamic>>());
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading pending actions: $e');
      }
    }
  }

  /// Save pending actions to SharedPreferences
  Future<void> _savePendingActions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingActionsKey, json.encode(_pendingActions));
    } catch (e) {
      if (kDebugMode) {
        print('Error saving pending actions: $e');
      }
    }
  }

  /// Process pending offline actions
  Future<void> _processPendingActions() async {
    if (_pendingActions.isEmpty) return;

    final actionsToProcess = List<Map<String, dynamic>>.from(_pendingActions);
    
    for (final action in actionsToProcess) {
      final attempts = action['attempts'] as int;
      if (attempts >= _maxRetryAttempts) {
        _pendingActions.remove(action);
        continue;
      }

      try {
        await _processAction(action);
        _pendingActions.remove(action);
        if (kDebugMode) {
          print('Successfully processed offline action: ${action['action']}');
        }
      } catch (e) {
        action['attempts'] = attempts + 1;
        if (kDebugMode) {
          print('Failed to process action ${action['action']}, attempt ${attempts + 1}: $e');
        }
      }
    }

    await _savePendingActions();
  }

  /// Process a single action
  Future<void> _processAction(Map<String, dynamic> action) async {
    switch (action['action']) {
      case 'consume_life':
        // Re-sync with server to get accurate state
        await fetchLivesStatus();
        break;
      default:
        if (kDebugMode) {
          print('Unknown action type: ${action['action']}');
        }
    }
  }

  /// Start periodic refresh of lives status
  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (timer) {
      if (_authProvider.isAuthenticated) {
        fetchLivesStatus();
      } else {
        timer.cancel();
      }
    });
  }

  /// Update network status
  void updateNetworkStatus(bool isOnline) {
    _isOnline = isOnline;
    if (isOnline && _pendingActions.isNotEmpty) {
      _processPendingActions();
    }
  }

  /// Get authentication token
  Future<String?> _getAuthToken() async {
    // This should be implemented based on how auth tokens are stored
    // For now, we'll assume AuthProvider has a method to get the token
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Set state and notify listeners
  void _setState(LivesState newState) {
    if (_livesState != newState) {
      _livesState = newState;
      notifyListeners();
    }
  }

  /// Handle API errors
  void _handleApiError(ApiResponse response) {
    String errorMessage = response.message;
    _handleError(errorMessage);
  }

  /// Handle general errors
  void _handleError(String message) {
    _errorMessage = message;
    _setState(LivesState.error);
    if (kDebugMode) {
      print('LivesProvider Error: $message');
    }
  }

  /// Clear error state
  void clearError() {
    _errorMessage = null;
    if (_livesState == LivesState.error) {
      _setState(_dailyLives != null ? LivesState.loaded : LivesState.initial);
    }
  }

  /// Reset lives (for testing or admin purposes)
  Future<void> resetLives() async {
    await fetchLivesStatus();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _retryTimer?.cancel();
    super.dispose();
  }
}