import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:recipe_book/screens/home/widgets/category_filter.dart';
import '../../models/recipe.dart';
import '../../providers/auth_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/main_scaffold.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _copyUserId(BuildContext context, String userId) {
    if (userId.isEmpty) return;
    Clipboard.setData(ClipboardData(text: userId));
    AppSnackbar.show(context, 'Kullanıcı ID panoya kopyalandı 📋');
  }

  Future<void> _handleDelete(BuildContext context, Recipe recipe) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Tarifi Sil',
      message: '"${recipe.name}" tarifini silmek istediğinize emin misiniz?',
      confirmLabel: 'Sil',
    );
    if (!confirmed || !context.mounted) return;

    try {
      await context.read<RecipeProvider>().deleteRecipe(recipe.id);
      if (context.mounted) {
        AppSnackbar.show(context, 'Tarif silindi 🗑️');
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.show(context, 'Tarif silinirken hata oluştu.', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final recipeProvider = context.watch<RecipeProvider>();

    // Kullanıcının tüm tarifleri (filtrelenmemiş)
    final allMyRecipes = recipeProvider.getUserRecipes(auth.userId);

    // Seçili kategoriye göre filtrelenmiş liste.
    // NOT: "Tümü" yerine provider'ındaki "hepsi" değerini kullan.
    final selectedCategory = recipeProvider.selectedCategory;
    final myRecipes = (selectedCategory == 'Tümü')
        ? allMyRecipes
        : allMyRecipes.where((r) => r.category == selectedCategory).toList();

    final favoriteCount = recipeProvider.favoriteRecipes.length;

    return MainScaffold(
      currentIndex: 4,
      child: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.paper,
            surfaceTintColor: Colors.transparent,
            title: Text(
              'Profilim',
              style: GoogleFonts.fraunces(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.brandDark,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: AppColors.brandDark),
                tooltip: 'Ayarlar',
                onPressed: () => Navigator.of(context).pushNamed('/ayarlar'),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // 1. Profil Kimlik Kartı (Avatar, Kullanıcı Adı, ID & Kopyalama)
                  _buildUserCard(context, auth),

                  const SizedBox(height: 16),

                  // 2. İstatistik Kartları (toplam sayılar, filtreden etkilenmez)
                  _buildStatsRow(allMyRecipes.length, favoriteCount),

                  const SizedBox(height: 24),

                  // 3. "Tariflerim" Başlığı & Yeni Tarif Ekle Butonu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Tariflerim',
                            style: GoogleFonts.fraunces(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.brandDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.sage,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${allMyRecipes.length}',
                              style: GoogleFonts.ibmPlexMono(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.brandDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Yeni Ekle'),
                        onPressed: () {
                          Navigator.of(context).pushNamed('/tarif-ekle');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 16),
                CategoryFilter(
                  selected: recipeProvider.selectedCategory,
                  onSelect: recipeProvider.setCategory,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // 4. Kullanıcının Kendi Tarifleri Listesi
          if (allMyRecipes.isEmpty)
            // Kullanıcının hiç tarifi yok
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildEmptyState(context),
              ),
            )
          else if (myRecipes.isEmpty)
            // Tarifleri var ama seçili kategoride yok
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                child: _buildEmptyFilterState(),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final recipe = myRecipes[index];
                    return _MyRecipeListItem(
                      recipe: recipe,
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          '/tarif',
                          arguments: recipe.id,
                        );
                      },
                      onEdit: () {
                        Navigator.of(context).pushNamed(
                          '/tarif-duzenle',
                          arguments: recipe.id,
                        );
                      },
                      onDelete: () => _handleDelete(context, recipe),
                    );
                  },
                  childCount: myRecipes.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Kullanıcı Kimlik Kartı ───────────────────────────────────────────────

  Widget _buildUserCard(BuildContext context, AuthProvider auth) {
    final initial = auth.displayName.isNotEmpty
        ? auth.displayName[0].toUpperCase()
        : 'U';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandDark.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.mustard, AppColors.brand],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.mustard.withAlpha(100),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: GoogleFonts.fraunces(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF241A00),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // İsim & Hesap
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            auth.displayName,
                            style: GoogleFonts.fraunces(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.brandDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.sage,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Şef',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.brandDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      auth.userEmail.isNotEmpty
                          ? auth.userEmail
                          : 'Kayıtlı Kullanıcı',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF7A7364),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 12),

          // Benzersiz Kullanıcı ID Satırı
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.sage.withAlpha(90),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.fingerprint_rounded,
                  size: 18,
                  color: AppColors.brandDark,
                ),
                const SizedBox(width: 8),
                Text(
                  'ID: ',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandDark,
                  ),
                ),
                Expanded(
                  child: Text(
                    auth.userId.isNotEmpty ? auth.userId : 'Oturum Açılmamış',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 11,
                      color: AppColors.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (auth.userId.isNotEmpty)
                  GestureDetector(
                    onTap: () => _copyUserId(context, auth.userId),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border:
                            Border.all(color: AppColors.cardBorder, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.copy_rounded,
                              size: 13, color: AppColors.brandDark),
                          const SizedBox(width: 4),
                          Text(
                            'Kopyala',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.brandDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── İstatistik Satırı ───────────────────────────────────────────────────

  Widget _buildStatsRow(int myRecipeCount, int favoriteCount) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.menu_book_rounded,
            title: 'Tariflerim',
            value: '$myRecipeCount',
            color: AppColors.brand,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.favorite_rounded,
            title: 'Favorilerim',
            value: '$favoriteCount',
            color: AppColors.paprika,
          ),
        ),
      ],
    );
  }

  // ─── Boş Durum (Kullanıcının Henüz Tarifi Yoksa) ─────────────────────────

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      margin: const EdgeInsets.only(top: 8, bottom: 40),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.sage.withAlpha(120),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restaurant_menu_rounded,
              size: 32,
              color: AppColors.brand,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz Tarif Eklemedin',
            style: GoogleFonts.fraunces(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.brandDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kendine ait özel lezzetleri ekle, istediğin an güncelle veya sil. Tariflerin güvenle profilinde saklansın.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.5,
              color: const Color(0xFF7A7364),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('İlk Tarifini Ekle'),
            onPressed: () {
              Navigator.of(context).pushNamed('/tarif-ekle');
            },
          ),
        ],
      ),
    );
  }

  // ─── Boş Durum (Seçili Kategoride Tarif Yoksa) ───────────────────────────

  Widget _buildEmptyFilterState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
      ),
      child: Column(
        children: [
          Icon(
            Icons.filter_list_off_rounded,
            size: 32,
            color: AppColors.brand.withAlpha(180),
          ),
          const SizedBox(height: 12),
          Text(
            'Bu kategoride tarifin yok',
            style: GoogleFonts.fraunces(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.brandDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Başka bir kategori seçmeyi dene.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF7A7364),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── İstatistik Kartı Widget'ı ──────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(24),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF7A7364),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tarif Liste Öğesi (Profil İçin Düzenle & Sil Butonlu) ───────────────────

class _MyRecipeListItem extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MyRecipeListItem({
    required this.recipe,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Resim
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 70,
                  height: 70,
                  child: recipe.image.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: recipe.image,
                          fit: BoxFit.cover,
                          // ignore: unnecessary_underscores
                          placeholder: (_, __) => Container(
                            color: AppColors.sage,
                            child: const Icon(
                              Icons.restaurant_outlined,
                              size: 24,
                              color: AppColors.brand,
                            ),
                          ),
                          // ignore: unnecessary_underscores
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.sage,
                            child: const Icon(
                              Icons.restaurant_outlined,
                              size: 24,
                              color: AppColors.brand,
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.sage,
                          child: const Icon(
                            Icons.restaurant_outlined,
                            size: 24,
                            color: AppColors.brand,
                          ),
                        ),
                ),
              ),

              const SizedBox(width: 14),

              // Bilgiler
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.sage,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        recipe.category.toUpperCase(),
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brandDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recipe.name,
                      style: GoogleFonts.fraunces(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_outlined,
                          size: 13,
                          color: Color(0xFF7A7364),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.duration} dk',
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 11,
                            color: const Color(0xFF7A7364),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.signal_cellular_alt_outlined,
                          size: 13,
                          color: Color(0xFF7A7364),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          recipe.difficulty,
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 11,
                            color: const Color(0xFF7A7364),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Düzenle & Sil Aksiyonları
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    tooltip: 'Düzenle',
                    color: AppColors.brand,
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    tooltip: 'Sil',
                    color: AppColors.paprika,
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}