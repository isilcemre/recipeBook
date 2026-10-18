import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/recipe.dart';
import '../../providers/auth_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/confirm_dialog.dart';

class RecipeDetailScreen extends StatelessWidget {
  final String recipeId;

  const RecipeDetailScreen({super.key, required this.recipeId});

  Future<void> _toggleFavorite(BuildContext context, Recipe recipe) async {
    // Basmadan önceki duruma göre mesajı belirle
    final wasFavorite = recipe.favorite;

    try {
      await context
          .read<RecipeProvider>()
          .toggleFavorite(recipe.id, wasFavorite);
      if (context.mounted) {
        AppSnackbar.show(
          context,
          wasFavorite ? 'Favorilerden kaldırıldı 💔' : 'Favorilere eklendi ❤️',
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.show(
          context,
          'Favori güncellenirken hata oluştu.',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<RecipeProvider>();
    final recipe = provider.getById(recipeId);

    if (recipe == null) {
      return Scaffold(
        backgroundColor: AppColors.paper,
        appBar: AppBar(title: const Text('Tarif Bulunamadı')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off_rounded,
                  size: 64, color: AppColors.sage),
              const SizedBox(height: 16),
              Text(
                'Bu tarif bulunamadı\nveya silinmiş olabilir.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Geri Dön'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, recipe, provider),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category and ownership badges
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.sage,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          recipe.category.toUpperCase(),
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.brandDark,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      if (provider.isOwner(recipe, auth.userId))
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.mustard.withAlpha(90),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person_rounded,
                                  size: 12, color: Color(0xFF5E4500)),
                              const SizedBox(width: 4),
                              Text(
                                'SENİN TARİFİN',
                                style: GoogleFonts.ibmPlexMono(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF5E4500),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (recipe.isSeeded)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6E2D8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'ŞEFİN SEÇİMİ',
                            style: GoogleFonts.ibmPlexMono(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6B6355),
                            ),
                          ),
                        )
                      else if (recipe.authorName.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            border: Border.all(
                                color: AppColors.cardBorder, width: 1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'YAZAR: ${recipe.authorName.toUpperCase()}',
                            style: GoogleFonts.ibmPlexMono(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Title + favorite
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          recipe.name,
                          style: GoogleFonts.fraunces(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _toggleFavorite(context, recipe),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 4, 0, 8),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            transitionBuilder: (child, animation) =>
                                ScaleTransition(
                              scale: animation,
                              child: child,
                            ),
                            child: Icon(
                              recipe.favorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_outline_rounded,
                              key: ValueKey(recipe.favorite),
                              size: 28,
                              color: recipe.favorite
                                  ? AppColors.paprika
                                  : AppColors.ink,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Meta row
                  _MetaRow(recipe: recipe),
                  const SizedBox(height: 28),
                  // Ingredients
                  Text(
                    'Malzemeler',
                    style: GoogleFonts.fraunces(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.brandDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...recipe.ingredients.map(
                    (ing) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(top: 7, right: 10),
                            decoration: const BoxDecoration(
                              color: AppColors.brand,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              ing,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Instructions
                  Text(
                    'Hazırlanışı',
                    style: GoogleFonts.fraunces(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.brandDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    recipe.instructions,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      height: 1.7,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Düzenle/Sil — sadece kullanıcının kendi eklediği tariflerde
                  if (provider.isOwner(recipe, auth.userId))
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Düzenle'),
                            onPressed: () => Navigator.of(context).pushNamed(
                              '/tarif-duzenle',
                              arguments: recipe.id,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 18),
                            label: const Text('Sil'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.paprika,
                              side: const BorderSide(
                                  color: AppColors.paprika, width: 1.5),
                            ),
                            onPressed: () async {
                              final confirmed = await ConfirmDialog.show(
                                context,
                                message:
                                    '"${recipe.name}" tarifini silmek istediğine emin misin?',
                              );
                              if (confirmed && context.mounted) {
                                await provider.deleteRecipe(recipe.id);
                                if (context.mounted) {
                                  AppSnackbar.show(context, 'Tarif silindi 🗑️');
                                  Navigator.of(context).pop();
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    )
                  else if (!recipe.isSeeded)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: AppColors.cardBorder, width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 20, color: Color(0xFF8A8478)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Bu tarif ${recipe.authorName.isNotEmpty ? recipe.authorName : "başka bir kullanıcı"} tarafından eklendi. Yalnızca kendi tariflerinizi düzenleyebilir veya silebilirsiniz.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF6B6355),
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
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(
      BuildContext context, Recipe recipe, RecipeProvider provider) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: AppColors.paper,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(220),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_rounded, size: 20),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: recipe.image.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: recipe.image,
                fit: BoxFit.cover,
                // ignore: unnecessary_underscores
                placeholder: (_, __) =>
                    Container(color: AppColors.sage),
                // ignore: unnecessary_underscores
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.sage,
                  child: const Icon(
                    Icons.restaurant_outlined,
                    size: 80,
                    color: AppColors.brand,
                  ),
                ),
              )
            : Container(
                color: AppColors.sage,
                child: const Icon(
                  Icons.restaurant_outlined,
                  size: 80,
                  color: AppColors.brand,
                ),
              ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final Recipe recipe;

  const _MetaRow({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
      ),
      child: Row(
        children: [
          _MetaItem(label: 'Süre', value: '${recipe.duration} dk'),
          _divider(),
          _MetaItem(label: 'Zorluk', value: recipe.difficulty),
          _divider(),
          _MetaItem(
              label: 'Porsiyon', value: '${recipe.servings} kişilik'),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 32,
        color: AppColors.cardBorder,
        margin: const EdgeInsets.symmetric(horizontal: 16),
      );
}

class _MetaItem extends StatelessWidget {
  final String label;
  final String value;

  const _MetaItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8A8478),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}