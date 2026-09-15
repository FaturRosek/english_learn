import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/user_model.dart';

enum AuthStatus { unknown, authenticated, unauthenticated, onboarding }

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  String? _error;
  bool _loading = false;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get error => _error;
  bool get loading => _loading;

  Future<void> checkAuthStatus() async {
    final hasToken = await _api.hasToken();
    if (hasToken) {
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> register({
    required String email,
    required String fullName,
    required String password,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.post(ApiConstants.register, data: {
        'email': email,
        'fullName': fullName,
        'password': password,
      });

      final auth = AuthResponse.fromJson(response.data);
      _user = auth.user;
      await _api.saveTokens(auth.accessToken, auth.refreshToken);
      _status = AuthStatus.onboarding;
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _loading = false;
      _error = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.post(ApiConstants.login, data: {
        'email': email,
        'password': password,
      });

      final auth = AuthResponse.fromJson(response.data);
      _user = auth.user;
      await _api.saveTokens(auth.accessToken, auth.refreshToken);

      _status = auth.user.onboardingCompleted
          ? AuthStatus.authenticated
          : AuthStatus.onboarding;

      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _loading = false;
      _error = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _api.post(ApiConstants.logout);
    } catch (_) {}
    await _api.clearTokens();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void onboardingComplete() {
    if (_user != null) {
      _user = UserModel(
        id: _user!.id,
        email: _user!.email,
        fullName: _user!.fullName,
        avatarUrl: _user!.avatarUrl,
        onboardingCompleted: true,
      );
    }
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  String _parseError(dynamic e) {
    if (e.toString().contains('409')) return 'Email already registered';
    if (e.toString().contains('401')) return 'Invalid email or password';
    if (e.toString().contains('SocketException')) return 'No internet connection';
    return 'Something went wrong. Please try again.';
  }
}
