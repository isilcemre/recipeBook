import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? get currentUser => _authService.currentUser;

  Stream<User?> get authStateChanges => _authService.authStateChanges;

  bool get isLoggedIn => currentUser != null;

  String get userId => currentUser?.uid ?? '';

  String get userEmail => currentUser?.email ?? '';

  String get displayName =>
      currentUser?.displayName ?? currentUser?.email?.split('@').first ?? '';

  Future<AuthResult> register(String username, String password) async {
    final result = await _authService.register(
      username: username,
      password: password,
    );
    notifyListeners();
    return result;
  }

  Future<AuthResult> login(String username, String password) async {
    final result = await _authService.login(
      username: username,
      password: password,
    );
    notifyListeners();
    return result;
  }

  Future<void> logout() async {
    await _authService.logout();
    notifyListeners();
  }

  Future<AuthResult> updateUsername(String newUsername) async {
    final result = await _authService.updateUsername(newUsername);
    notifyListeners();
    return result;
  }

  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return await _authService.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  Future<AuthResult> deleteAccount() async {
    final result = await _authService.deleteAccount();
    notifyListeners();
    return result;
  }
}
