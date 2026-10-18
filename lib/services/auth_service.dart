import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Kullanıcı adını geçerli bir email prefix'ine çevirir.
  /// Örn: "Ahmet Yılmaz" → "ahmetyilmaz"
  ///      "user@gmail.com" → "usergmailcom"
  String _sanitizeUsername(String username) {
    return username
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '') // sadece harf ve rakam
        .replaceAll(RegExp(r'\s+'), '');       // boşlukları kaldır
  }

  String _toEmail(String username) {
    final sanitized = _sanitizeUsername(username);
    if (sanitized.isEmpty) return '';
    return '$sanitized@recipebook.app';
  }

  /// Kayıt ol
  Future<AuthResult> register({
    required String username,
    required String password,
  }) async {
    final trimmed = username.trim();
    if (trimmed.isEmpty || password.isEmpty) {
      return AuthResult.failure('Kullanıcı adı ve şifre zorunludur.');
    }

    final email = _toEmail(trimmed);
    if (email.isEmpty) {
      return AuthResult.failure(
          'Kullanıcı adı geçersiz. Lütfen harf veya rakam kullanın.');
    }

    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Orijinal kullanıcı adını displayName olarak sakla
      await _auth.currentUser?.updateDisplayName(trimmed);
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseError(e.code));
    } catch (e) {
      return AuthResult.failure('Bir hata oluştu. Lütfen tekrar deneyin.');
    }
  }

  /// Giriş yap
  Future<AuthResult> login({
    required String username,
    required String password,
  }) async {
    final trimmed = username.trim();
    if (trimmed.isEmpty || password.isEmpty) {
      return AuthResult.failure('Kullanıcı adı ve şifre zorunludur.');
    }

    final email = _toEmail(trimmed);
    if (email.isEmpty) {
      return AuthResult.failure(
          'Kullanıcı adı geçersiz. Lütfen harf veya rakam kullanın.');
    }

    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseError(e.code));
    } catch (e) {
      return AuthResult.failure('Bir hata oluştu. Lütfen tekrar deneyin.');
    }
  }

  /// Çıkış yap
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Kullanıcı adını güncelle
  Future<AuthResult> updateUsername(String newUsername) async {
    final trimmed = newUsername.trim();
    if (trimmed.isEmpty) {
      return AuthResult.failure('Kullanıcı adı boş olamaz.');
    }
    try {
      await _auth.currentUser?.updateDisplayName(trimmed);
      await _auth.currentUser?.reload();
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseError(e.code));
    } catch (e) {
      return AuthResult.failure('Kullanıcı adı güncellenirken bir hata oluştu.');
    }
  }

  /// Şifre değiştir
  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      return AuthResult.failure('Oturum açık değil.');
    }
    if (newPassword.length < 6) {
      return AuthResult.failure('Yeni şifre en az 6 karakter olmalıdır.');
    }
    try {
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseError(e.code));
    } catch (e) {
      return AuthResult.failure('Şifre değiştirilirken bir hata oluştu.');
    }
  }

  /// Hesabı sil
  Future<AuthResult> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      return AuthResult.failure('Oturum açık değil.');
    }
    try {
      await user.delete();
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return AuthResult.failure(
            'Güvenlik gerekçesiyle hesabı silmeden önce lütfen çıkış yapıp tekrar giriş yapın.');
      }
      return AuthResult.failure(_mapFirebaseError(e.code));
    } catch (e) {
      return AuthResult.failure('Hesap silinirken bir hata oluştu.');
    }
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Bu kullanıcı adı zaten alınmış.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Kullanıcı adı veya şifre hatalı.';
      case 'weak-password':
        return 'Şifre en az 6 karakter olmalıdır.';
      case 'too-many-requests':
        return 'Çok fazla deneme. Lütfen biraz bekleyin.';
      case 'invalid-email':
        return 'Geçersiz kullanıcı adı formatı.';
      case 'network-request-failed':
        return 'İnternet bağlantısı yok. Lütfen tekrar deneyin.';
      case 'operation-not-allowed':
        return 'E-posta/şifre girişi henüz etkinleştirilmemiş.';
      default:
        return 'Bir hata oluştu ($code). Lütfen tekrar deneyin.';
    }
  }
}

class AuthResult {
  final bool success;
  final String? message;

  const AuthResult._({required this.success, this.message});

  factory AuthResult.success() => const AuthResult._(success: true);
  factory AuthResult.failure(String message) =>
      AuthResult._(success: false, message: message);
}
