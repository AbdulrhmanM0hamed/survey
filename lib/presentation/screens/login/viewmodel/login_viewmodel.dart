import 'package:flutter/foundation.dart';
import 'package:survey/data/repositories/auth_repository.dart';

enum LoginState { initial, loading, success, error }

class LoginViewModel extends ChangeNotifier {
  final AuthRepository repository;

  LoginViewModel({required this.repository});

  LoginState _state = LoginState.initial;
  LoginState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _userName;
  String? get userName => _userName;

  bool _obscurePassword = true;
  bool get obscurePassword => _obscurePassword;

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _setState(LoginState.loading);
    _errorMessage = null;

    final result = await repository.login(username, password);

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        _setState(LoginState.error);
        return false;
      },
      (user) {
        _userName = user.fullName;
        _setState(LoginState.success);
        return true;
      },
    );
  }

  Future<void> logout() async {
    await repository.logout();
    _userName = null;
    _setState(LoginState.initial);
  }

  bool isLoggedIn() {
    return repository.isLoggedIn();
  }

  String? getStoredUserName() {
    return repository.getUserName();
  }

  void _setState(LoginState newState) {
    _state = newState;
    notifyListeners();
  }
}
