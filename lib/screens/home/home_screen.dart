import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/recipe.dart';
import '../../providers/auth_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/main_scaffold.dart';
import 'widgets/hero_banner.dart';
import 'widgets/category_filter.dart';
import 'widgets/recipe_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();
  StreamSubscription? _recipeSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startListening();
    });
  }

  void _startListening() {
    if (!mounted) return;
    final provider = context.read<RecipeProvider>();

    // Eksik örnek tarifler varsa Firestore'a ekle
    provider.seedSampleRecipes().catchError((_) {});

    _recipeSub = provider.recipesStream.listen(
      (recipes) {
        if (!mounted) return;
        provider.updateRecipes(recipes);
      },
      onError: (e) {
        if (mounted) {
          AppSnackbar.show(
            context,
            'Tarifler yüklenirken hata oluştu. İnternet bağlantınızı kontrol edin.',
            isError: true,
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _recipeSub?.cancel();
    super.dispose();
  }

  Future<void> _handleDelete(BuildContext ctx, String id, String name) async {
    final confirmed = await ConfirmDialog.show(
      ctx,
      message: '"$name" tarifini silmek istediğine emin misin?',
    );
    if (!confirmed || !ctx.mounted) return;
    await ctx.read<RecipeProvider>().deleteRecipe(id);
    if (ctx.mounted) AppSnackbar.show(ctx, 'Tarif silindi 🗑️');
  }

  void _showRandomRecipeModal() {
    final provider = context.read<RecipeProvider>();
    final categories = provider.getCategories();
    if (categories.isEmpty) return;

    showDialog<String>(
      context: context,
      builder: (_) => _CategoryPickerDialog(categories: categories),
    ).then((selected) {
      if (selected == null || !mounted) return;

      final selectedCategory =
          selected == _CategoryPickerDialog.allKey ? null : selected;

      final recipe = provider.getRandomRecipe(category: selectedCategory);

      if (recipe == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bu kategoride tarif bulunamadı.')),
        );
        return;
    }

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _RandomRecipeModal(
          recipe: recipe,
          category: selectedCategory, // yeni
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final recipeProvider = context.watch<RecipeProvider>();
    final recipes = recipeProvider.filteredRecipes;

    return MainScaffold(
      currentIndex: 0,
      child: CustomScrollView(
        slivers: [
          // AppBar
          SliverAppBar(
            floating: true,
            snap: true,
            pinned: false,
            backgroundColor: AppColors.paper,
            surfaceTintColor: Colors.transparent,
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.mustard,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    size: 18,
                    color: Color(0xFF241A00),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'My Recipe Book',
                  style: GoogleFonts.fraunces(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandDark,
                  ),
                ),
              ],
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.sage,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${auth.displayName} Chef',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.brandDark,
                  ),
                ),
              ),
              
              const SizedBox(width: 12)

            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: SearchBar(
                  controller: _searchCtrl,
                  hintText: 'Tarif ara...',
                  leading: const Icon(Icons.search_rounded, size: 20),
                  trailing: _searchCtrl.text.isNotEmpty
                      ? [
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              recipeProvider.setSearchTerm('');
                            },
                          ),
                        ]
                      : null,
                  onChanged: recipeProvider.setSearchTerm,
                  backgroundColor:
                      const WidgetStatePropertyAll(AppColors.white),
                  elevation: const WidgetStatePropertyAll(0),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(
                          color: AppColors.cardBorder, width: 1.5),
                    ),
                  ),
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            ),
          ),

          // Hero banner + category filter
          SliverToBoxAdapter(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: HeroBanner(
                    recipeCount: recipeProvider.recipes.length,
                    onRandomPick: _showRandomRecipeModal,
                  ),
                ),
                const SizedBox(height: 16),
                CategoryFilter(
                  selected: recipeProvider.selectedCategory,
                  onSelect: recipeProvider.setCategory,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Recipe grid or empty state
          if (recipes.isEmpty)
            const SliverFillRemaining(
              child: _EmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final recipe = recipes[i];
                    return RecipeCard(
                      recipe: recipe,
                      onTap: () => Navigator.of(context).pushNamed(
                        '/tarif',
                        arguments: recipe.id,
                      ),
                      onFavorite: () async {
                        await recipeProvider.toggleFavorite(
                            recipe.id, recipe.favorite);
                      },
                      onDelete: () =>
                          _handleDelete(context, recipe.id, recipe.name),
                    );
                  },
                  childCount: recipes.length,
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

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.cardBorder,
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.restaurant_outlined,
                size: 40,
                color: AppColors.sage,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Hiç tarif yok',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Aradığın kriterlere uyan bir tarif bulunamadı. Belki yeni bir tarif eklemenin zamanı gelmiştir!',
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

// ─── Şansıma Bırak Modal ─────────────────────────────────────────────────────

class _RandomRecipeModal extends StatefulWidget {
  final Recipe recipe;
  final String? category;

  const _RandomRecipeModal({required this.recipe, this.category});

  @override
  State<_RandomRecipeModal> createState() => _RandomRecipeModalState();
}

class _RandomRecipeModalState extends State<_RandomRecipeModal> {
  late Recipe _current;

  @override
  void initState() {
    super.initState();
    _current = widget.recipe;
  }

  void _reroll() {
  final provider = context.read<RecipeProvider>();

  Recipe? next;
  // Aynı tarif tekrar gelmesin diye birkaç kez dene
  for (var i = 0; i < 5; i++) {
    next = provider.getRandomRecipe(category: widget.category);
    if (next == null || next.id != _current.id) break;
  }

  if (next != null) {
    setState(() => _current = next!);
  }
}

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 16),

          // Tarif resmi
          if (_current.image.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: _current.image,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  // ignore: unnecessary_underscores
                  placeholder: (_, __) =>
                      Container(height: 200, color: AppColors.sage),
                  // ignore: unnecessary_underscores
                  errorWidget: (_, __, ___) => Container(
                    height: 200,
                    color: AppColors.sage,
                    child: const Icon(Icons.restaurant_outlined,
                        size: 60, color: AppColors.brand),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Tarif bilgisi
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kategori badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.sage,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _current.category.toUpperCase(),
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: AppColors.brandDark,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // İsim
                Text(
                  _current.name,
                  style: GoogleFonts.fraunces(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandDark,
                  ),
                ),
                const SizedBox(height: 12),
                // Meta
                Row(
                  children: [
                    _ModalMeta(
                      icon: Icons.schedule_outlined,
                      label: '${_current.duration} dk',
                    ),
                    const SizedBox(width: 20),
                    _ModalMeta(
                      icon: Icons.signal_cellular_alt_outlined,
                      label: _current.difficulty,
                    ),
                    const SizedBox(width: 20),
                    _ModalMeta(
                      icon: Icons.people_outline_rounded,
                      label: '${_current.servings} kişilik',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Butonlar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Row(
              children: [
                OutlinedButton.icon(
                  icon: const Text('🎲', style: TextStyle(fontSize: 15)),
                  label: const Text('Tekrar Dene'),
                  onPressed: _reroll,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon:
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('Tarife Git'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context)
                          .pushNamed('/tarif', arguments: _current.id);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _CategoryPickerDialog extends StatelessWidget {
  static const allKey = '__all__';
  final List<String> categories;

  const _CategoryPickerDialog({required this.categories});

  @override
  Widget build(BuildContext context) {
    const bgColor = Colors.white;
    const titleColor = Color(0xFF1F1F1F);
    const subtitleColor = Color(0xFF6B6B6B);
    //final accent = Theme.of(context).colorScheme.primary;

    return Dialog(
      backgroundColor: bgColor,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Kategori seç',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: subtitleColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Seçtiğin kategoriden rastgele bir tarif getireceğim.',
              style: TextStyle(fontSize: 14, color: subtitleColor),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 2,
                  children: [
                    ActionChip(
                      avatar: Icon(Icons.shuffle, size: 18, color: titleColor),
                      label: Text(
                        'Hepsi',
                        style: TextStyle(
                          color: titleColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      // ignore: deprecated_member_use
                      backgroundColor: const Color(0xFFF1F1F1),
                      side: BorderSide.none,
                      onPressed: () => Navigator.pop(context, allKey),
                    ),
                    for (final c in categories)
                      ActionChip(
                        label: Text(
                          c,
                          style: const TextStyle(
                            color: titleColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        backgroundColor: const Color(0xFFF1F1F1),
                        side: BorderSide.none,
                        onPressed: () => Navigator.pop(context, c),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModalMeta extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ModalMeta({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF6B6355)),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.ibmPlexMono(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B6355),
          ),
        ),
      ],
    );
  }
}
