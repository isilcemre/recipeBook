import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/recipe_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/main_scaffold.dart';
import '../home/widgets/recipe_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  static const _removeDuration = Duration(milliseconds: 320);

  /// Çıkış animasyonu oynayan kartlar
  final Set<String> _removing = {};

  /// Animasyon bittikten sonra listeden gizlenen kartlar
  /// (provider güncellemesi gecikse bile kart geri gelmesin)
  final Set<String> _hidden = {};

  Future<void> _removeFromFavorites(String id, bool currentFavorite) async {
    if (_removing.contains(id) || _hidden.contains(id)) return;

    // 1. Çıkış animasyonunu başlat
    setState(() => _removing.add(id));
    await Future.delayed(_removeDuration);
    if (!mounted) return;

    // 2. Kartı listeden çıkar
    setState(() => _hidden.add(id));

    // 3. Provider'ı güncelle
    try {
      await context.read<RecipeProvider>().toggleFavorite(id, currentFavorite);
      if (!mounted) return;
      final stillFavorite = context
          .read<RecipeProvider>()
          .favoriteRecipes
          .any((r) => r.id == id);
      setState(() {
        _removing.remove(id);
        if (!stillFavorite) _hidden.remove(id);
      });
      AppSnackbar.show(context, 'Favorilerden kaldırıldı 💔');
    } catch (e) {
      if (!mounted) return;
      // Hata olursa kartı geri getir
      setState(() {
        _removing.remove(id);
        _hidden.remove(id);
      });
      AppSnackbar.show(
        context,
        'Favori güncellenirken hata oluştu.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecipeProvider>();
    final favorites = provider.favoriteRecipes
        .where((r) => !_hidden.contains(r.id))
        .toList();

    return MainScaffold(
      currentIndex: 1,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.paper,
            surfaceTintColor: Colors.transparent,
            title: Text(
              'Favorilerim',
              style: GoogleFonts.fraunces(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.brandDark,
              ),
            ),
          ),
          if (favorites.isEmpty)
            const SliverFillRemaining(
              child: _EmptyFavorites(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final recipe = favorites[i];
                    final isRemoving = _removing.contains(recipe.id);

                    return AnimatedOpacity(
                      key: ValueKey(recipe.id),
                      opacity: isRemoving ? 0.0 : 1.0,
                      duration: _removeDuration,
                      curve: Curves.easeOut,
                      child: AnimatedScale(
                        scale: isRemoving ? 0.6 : 1.0,
                        duration: _removeDuration,
                        curve: Curves.easeInBack,
                        child: IgnorePointer(
                          ignoring: isRemoving,
                          child: RecipeCard(
                            recipe: recipe,
                            onTap: () => Navigator.of(context).pushNamed(
                              '/tarif',
                              arguments: recipe.id,
                            ),
                            onFavorite: () => _removeFromFavorites(
                                recipe.id, recipe.favorite),
                            onDelete: () async {
                              final confirmed = await ConfirmDialog.show(
                                context,
                                message:
                                    '"${recipe.name}" tarifini silmek istediğine emin misin?',
                              );
                              if (confirmed && context.mounted) {
                                await context
                                    .read<RecipeProvider>()
                                    .deleteRecipe(recipe.id);
                                if (context.mounted) {
                                  AppSnackbar.show(
                                      context, 'Tarif silindi 🗑️');
                                }
                              }
                            },
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: favorites.length,
                  findChildIndexCallback: (key) {
                    if (key is ValueKey) {
                      final index =
                          favorites.indexWhere((r) => r.id == key.value);
                      return index == -1 ? null : index;
                    }
                    return null;
                  },
                ),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.favorite_outline_rounded,
              size: 64,
              color: AppColors.sage,
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz favori yok',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Beğendiğin tariflerin üzerindeki ❤️ butonuna basarak favorilerine ekleyebilirsin.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: const Color(0xFF7A7364)),
            ),
          ],
        ),
      ),
    );
  }
}