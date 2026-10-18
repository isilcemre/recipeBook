import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:recipe_book/screens/auth/login_screen.dart';
import 'package:recipe_book/screens/home/home_screen.dart';
import 'package:recipe_book/screens/splash_screen.dart';
import '../../providers/auth_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/confirm_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Kullanıcı adı
  final _usernameCtrl = TextEditingController();
  bool _updatingUsername = false;

  // Şifre değiştirme
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _updatingPassword = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _usernameCtrl.text = auth.displayName;
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  // Kullanıcı adı güncelleme
  Future<void> _handleUpdateUsername() async {
    final newName = _usernameCtrl.text.trim();
    if (newName.isEmpty) {
      AppSnackbar.show(context, 'Kullanıcı adı boş olamaz.', isError: true);
      return;
    }

    setState(() => _updatingUsername = true);
    final auth = context.read<AuthProvider>();
    final result = await auth.updateUsername(newName);
    if (!mounted) return;
    setState(() => _updatingUsername = false);

    if (result.success) {
      AppSnackbar.show(context, 'Kullanıcı adı güncellendi! 🎉');
    } else {
      AppSnackbar.show(
        context,
        result.message ?? 'Kullanıcı adı güncellenemedi.',
        isError: true,
      );
    }
  }

  // Şifre güncelleme
  Future<void> _handleUpdatePassword() async {
    final currentPass = _currentPasswordCtrl.text;
    final newPass = _newPasswordCtrl.text;
    final confirmPass = _confirmPasswordCtrl.text;

    if (currentPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      AppSnackbar.show(context, 'Lütfen tüm şifre alanlarını doldurun.', isError: true);
      return;
    }

    if (newPass.length < 6) {
      AppSnackbar.show(context, 'Yeni şifre en az 6 karakter olmalıdır.', isError: true);
      return;
    }

    if (newPass != confirmPass) {
      AppSnackbar.show(context, 'Yeni şifreler eşleşmiyor.', isError: true);
      return;
    }

    if (newPass == currentPass) {
      AppSnackbar.show(context, 'Yeni şifre, eskisi ile aynı olamaz.', isError: true);
      return;
    }

    setState(() => _updatingPassword = true);
    final auth = context.read<AuthProvider>();
    final result = await auth.changePassword(
      currentPassword: currentPass,
      newPassword: newPass,
    );
    if (!mounted) return;
    setState(() => _updatingPassword = false);

    if (result.success) {
      _currentPasswordCtrl.clear();
      _newPasswordCtrl.clear();
      _confirmPasswordCtrl.clear();
      AppSnackbar.show(context, 'Şifreniz başarıyla güncellendi! 🔒');
    } else {
      AppSnackbar.show(
        context,
        result.message ?? 'Şifre güncellenemedi.',
        isError: true,
      );
    }
  }

  // Çıkış yapma
  Future<void> _handleLogout() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Çıkış Yap',
      message: 'Hesabınızdan çıkış yapmak istediğinize emin misiniz?',
      confirmLabel: 'Çıkış Yap',
    );

    if (confirmed && mounted) {
      await context.read<AuthProvider>().logout();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const _AuthGate(),
        ),
        (route) => false,
      );
    }
  }
  // Hesabı sil modalını aç
  void _openDeleteAccountModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _DeleteAccountModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Ayarlar',
          style: GoogleFonts.fraunces(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.brandDark,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── 1. KULLANICI ADI DEĞİŞTİRME ───
            _buildSectionCard(
              title: 'Kullanıcı Adı Değiştir',
              icon: Icons.person_outline_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _usernameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Yeni Kullanıcı Adı',
                      prefixIcon: Icon(Icons.badge_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: _updatingUsername ? null : _handleUpdateUsername,
                    child: _updatingUsername
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Kullanıcı Adını Kaydet'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ─── 2. ŞİFRE DEĞİŞTİRME ───
            _buildSectionCard(
              title: 'Şifre Değiştir',
              icon: Icons.lock_outline_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _currentPasswordCtrl,
                    obscureText: _obscureCurrent,
                    decoration: InputDecoration(
                      labelText: 'Mevcut Şifre',
                      prefixIcon: const Icon(Icons.key_outlined, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureCurrent
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscureCurrent = !_obscureCurrent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _newPasswordCtrl,
                    obscureText: _obscureNew,
                    decoration: InputDecoration(
                      labelText: 'Yeni Şifre (En az 6 karakter)',
                      prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNew
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscureNew = !_obscureNew),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmPasswordCtrl,
                    obscureText: _obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Yeni Şifre Tekrar',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: _updatingPassword ? null : _handleUpdatePassword,
                    child: _updatingPassword
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Şifremi Güncelle'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ─── 3. ÇIKIŞ YAPMA ───
            _buildSectionCard(
              title: 'Oturumu Kapat',
              icon: Icons.logout_rounded,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Çıkış Yap'),
                onPressed: _handleLogout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  side: const BorderSide(color: AppColors.cardBorder, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ─── 4. DANGER ZONE (HESABIMI SİL) ───
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFF2F0),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.paprika.withAlpha(80),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.paprika.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.paprika,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'DANGER ZONE',
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.paprika,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Hesabınızı ve eklediğiniz tüm tarifleri kalıcı olarak siler. Bu işlem geri alınamaz.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF6B433F),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _openDeleteAccountModal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.paprika,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'HESABIMI SİL',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.brandDark),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.fraunces(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ─── HESABIMI SİL MODAL (ÖZEL DOĞRULAMA CÜMLELİ) ──────────────────────────────

class _DeleteAccountModal extends StatefulWidget {
  const _DeleteAccountModal();

  @override
  State<_DeleteAccountModal> createState() => _DeleteAccountModalState();
}

class _DeleteAccountModalState extends State<_DeleteAccountModal> {
  static const List<String> _phrases = [
    'Mutfak kapandı',
    'Doydum',
    'Tabağımı sıyırdım',
    'Şef emekli oldu',
    'Tüp bitti',
    'Muziplik tamamlandı',
  ];

  late final String _requiredPhrase;
  final _inputCtrl = TextEditingController();
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    // Rastgele bir onay cümlesi seç
    _requiredPhrase = _phrases[Random().nextInt(_phrases.length)];
    _inputCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  bool get _isMatch => _inputCtrl.text.trim() == _requiredPhrase.trim();

  Future<void> _handleDeleteAccount() async {
    if (!_isMatch || _isDeleting) return;

    setState(() => _isDeleting = true);

    final auth = context.read<AuthProvider>();
    final recipeProvider = context.read<RecipeProvider>();

    try {
      // 1. Önce kullanıcının Firestore'daki tariflerini temizle
      await recipeProvider.deleteAllUserRecipes();

      // 2. Auth kullanıcısını sil
      final result = await auth.deleteAccount();

      if (!mounted) return;
      setState(() => _isDeleting = false);

      if (result.success) {
        //final navigator = Navigator.of(context);
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const _AuthGate(),
          ),
          (route) => false,
        );
        
        messenger.showSnackBar(
          const SnackBar(content: Text('Hesabınız kalıcı olarak silindi. Afiyet olsun şefim! 👋')),
        );
      } else {
        AppSnackbar.show(
          context,
          result.message ?? 'Hesap silinirken bir hata oluştu.',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        AppSnackbar.show(
          context,
          'Hesap silinirken bir hata oluştu: $e',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.fromLTRB(12, 0, 12, bottomInset + 16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Başlık
            Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Hesabını Silmek Üzeresin',
                    style: GoogleFonts.fraunces(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: AppColors.paprika,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.ink,
                ),
              ],
            ),
            const SizedBox(height: 10),

            Text(
              'Tüm tarif defterin, favorilerin ve kişisel verilerin geri getirilemeyecek şekilde silinecektir.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF6B6355),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // Doğrulama Cümlesi Kutusu
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF2F0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.paprika.withAlpha(60),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ONAYLAMAK İÇİN AŞAĞIDAKİ CÜMLEYİ YAZIN:',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.paprika,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    _requiredPhrase,
                    style: GoogleFonts.fraunces(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Giriş Alanı
            TextField(
              controller: _inputCtrl,
              decoration: InputDecoration(
                hintText: '"$_requiredPhrase"',
                prefixIcon: const Icon(Icons.edit_outlined, size: 20),
                suffixIcon: _isMatch
                    ? const Icon(Icons.check_circle_rounded, color: Colors.green)
                    : null,
              ),
            ),
            const SizedBox(height: 20),

            // Silme Butonu
            ElevatedButton(
              onPressed: (_isMatch && !_isDeleting) ? _handleDeleteAccount : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.paprika,
                disabledBackgroundColor: AppColors.paprika.withAlpha(60),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'HESABIMI KALICI OLARAK SİL',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
            const SizedBox(height: 8),

            // Vazgeç butonu
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Vazgeç',
                style: GoogleFonts.inter(
                  color: const Color(0xFF6B6355),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return StreamBuilder(
      stream: auth.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

