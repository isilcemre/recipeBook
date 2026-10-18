import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/ingredients_data.dart';
import '../../models/recipe.dart';
import '../../providers/recipe_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/main_scaffold.dart';

class AvailableIngredientsScreen extends StatefulWidget {
  const AvailableIngredientsScreen({super.key});

  @override
  State<AvailableIngredientsScreen> createState() =>
      _AvailableIngredientsScreenState();
}

class _AvailableIngredientsScreenState
    extends State<AvailableIngredientsScreen> {
  final Set<String> _selected = {};
  final _searchCtrl = TextEditingController();
  List<RecipeMatch>? _results;
  String _search = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggle(String ingredient) {
    setState(() {
      if (_selected.contains(ingredient)) {
        _selected.remove(ingredient);
      } else {
        _selected.add(ingredient);
      }
    });
  }

  void _handleSearch() {
    final provider = context.read<RecipeProvider>();
    setState(() {
      _results = provider.findByIngredients(_selected.toList());
    });
  }

  List<String> get _suggestions {
    final q = _search.toLowerCase();
    return kAllIngredients.where((i) => i.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = _search.isNotEmpty;
    final categories = kIngredientCategories.entries.toList();

    return MainScaffold(
      currentIndex: 2,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.paper,
            surfaceTintColor: Colors.transparent,
            title: Text(
              '🧺 Buzdolabında Ne Var?',
              style: GoogleFonts.fraunces(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.brandDark,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Evindeki malzemeleri işaretle, sana en uygun tarifleri bulalım.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: const Color(0xFF6B6355)),
                  ),
                  const SizedBox(height: 16),
                  // Malzeme arama
                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Malzeme ara... (ör: biber)',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: isSearching
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _search = '');
                              },
                            )
                          : null,
                    ),
                    onChanged: (v) => setState(() => _search = v.trim()),
                  ),
                  const SizedBox(height: 12),
                  // Arama önerileri
                  if (isSearching) _buildSuggestions(),
                  // Seçilen malzemeler
                  if (_selected.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${_selected.length} malzeme seçildi',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.brand,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _selected
                          .map(
                            (s) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.brand,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    s,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () => _toggle(s),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
          // Kategori sekmeleri (arama yaparken gizlenir)
          if (!isSearching)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final entry = categories[i];
                    return _CategoryTile(
                      title: entry.key,
                      ingredients: entry.value,
                      selected: _selected,
                      onToggle: _toggle,
                    );
                  },
                  childCount: categories.length,
                ),
              ),
            ),
          // Tarif Bul butonu
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.search_rounded),
                  label: const Text('Tarif Bul'),
                  onPressed: _selected.isEmpty ? null : _handleSearch,
                ),
              ),
            ),
          ),
          // Sonuçlar
          if (_results != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                child: _ResultsList(results: _results!),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    final suggestions = _suggestions;
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
      ),
      child: suggestions.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  '"$_search" ile eşleşen malzeme bulunamadı.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF8A8478),
                    fontSize: 14,
                  ),
                ),
              ),
            )
          : ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: suggestions.length,
              itemBuilder: (context, i) {
                final ingredient = suggestions[i];
                final isSelected = _selected.contains(ingredient);
                return ListTile(
                  dense: true,
                  title: Text(
                    ingredient,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? AppColors.brandDark : AppColors.ink,
                    ),
                  ),
                  trailing: Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.add_circle_outline_rounded,
                    color: AppColors.brand,
                    size: 20,
                  ),
                  onTap: () => _toggle(ingredient),
                );
              },
            ),
    );
  }
}

// ---- Kategori sekmesi ----

class _CategoryTile extends StatelessWidget {
  final String title;
  final List<String> ingredients;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const _CategoryTile({
    required this.title,
    required this.ingredients,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final count = ingredients.where(selected.contains).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.fraunces(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandDark,
                  ),
                ),
              ),
              if (count > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.brand,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ingredients.map((ing) {
                final isSelected = selected.contains(ing);
                return GestureDetector(
                  onTap: () => onToggle(ing),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.brand : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.brand
                            : AppColors.cardBorder,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected
                              ? Icons.check_rounded
                              : Icons.add_rounded,
                          size: 16,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF8A8478),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ing,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Sonuçlar ----

class _ResultsList extends StatelessWidget {
  final List<RecipeMatch> results;

  const _ResultsList({required this.results});

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(
              color: AppColors.cardBorder,
              width: 2,
              style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'Seçtiğin malzemelerle eşleşen bir tarif bulunamadı. Farklı malzemeler deneyebilirsin.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: const Color(0xFF7A7364)),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sonuçlar (${results.length})',
          style: GoogleFonts.fraunces(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.brandDark,
          ),
        ),
        const SizedBox(height: 12),
        ...results.map((m) => _MatchCard(match: m)),
      ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  final RecipeMatch match;

  const _MatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(
        '/tarif',
        arguments: match.recipe.id,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    match.recipe.name,
                    style: GoogleFonts.fraunces(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.brandDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${match.recipe.category} · ${match.recipe.duration} dk',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF6B6355),
                    ),
                  ),
                  if (match.missing.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      'Eksik: ${match.missing.join(', ')}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.paprika,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.mustard,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '%${match.matchPercent}',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF241A00),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}