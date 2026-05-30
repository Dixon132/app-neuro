import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/user_model.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthState {
  final bool isAuthenticated;
  final UserModel? user;
  final bool isLoading;
  final String? error;

  AuthState({
    this.isAuthenticated = false,
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    UserModel? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService = ApiService();
  final StorageService _storage = StorageService();

  AuthNotifier() : super(AuthState()) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    final isLoggedIn = await _storage.isLoggedIn();
    if (isLoggedIn) {
      final userData = await _storage.getUser();
      if (userData != null) {
        state = state.copyWith(
          isAuthenticated: true,
          user: UserModel.fromJson(userData),
        );
      }
    }
  }

  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiService.login(username, password);
      await _storage.saveToken(response['access_token']);

      final userData = response['user'] ?? {
        'id': 1,
        'email': '$username@example.com',
        'username': username,
        'full_name': username,
        'role': response['role'] ?? 'user',
      };

      final user = UserModel.fromJson(userData);
      await _storage.saveUser(user.toJson());
      state = state.copyWith(
        isAuthenticated: true,
        user: user,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> adminLogin(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiService.adminLogin(username, password);
      await _storage.saveToken(response['access_token']);

      final userData = response['user'];
      final user = UserModel.fromJson(userData);
      await _storage.saveUser(user.toJson());
      state = state.copyWith(
        isAuthenticated: true,
        user: user,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> register(Map<String, dynamic> userData) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiService.register(userData);
      // Register now returns a token + user, same as login
      await _storage.saveToken(response['access_token']);
      final user = UserModel.fromJson(response['user']);
      await _storage.saveUser(user.toJson());
      state = state.copyWith(
        isAuthenticated: true,
        user: user,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> logout() async {
    await _storage.clearAll();
    state = AuthState();
  }
}
