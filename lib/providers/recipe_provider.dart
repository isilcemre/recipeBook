import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';

class RecipeProvider extends ChangeNotifier {
  final RecipeService _service;

  RecipeProvider({RecipeService? service}) : _service = service ?? RecipeService();

  List<Recipe> _recipes = [];
  String _searchTerm = '';
  String _selectedCategory = 'Tümü';
  // ignore: prefer_final_fields
  bool _isLoading = false;

  List<Recipe> get recipes => _recipes;
  String get searchTerm => _searchTerm;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;

  /// Filtrelenmiş tarif listesi
  List<Recipe> get filteredRecipes {
    return _recipes.where((r) {
      final matchesSearch = _searchTerm.isEmpty ||
          r.name.toLowerCase().contains(_searchTerm.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'Tümü' || r.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  /// Favori tarifler
  List<Recipe> get favoriteRecipes =>
      _recipes.where((r) => r.favorite).toList();

  /// Belirli bir kullanıcının eklediği tarifler
  List<Recipe> getUserRecipes(String userId) {
    if (userId.isEmpty) return [];
    return _recipes.where((r) => r.userId == userId && !r.isSeeded).toList();
  }

  /// Tarifin oturumdaki kullanıcıya ait olup olmadığı (düzenleme/silme yetkisi)
  bool isOwner(Recipe recipe, String currentUserId) {
    return currentUserId.isNotEmpty &&
        recipe.userId == currentUserId &&
        !recipe.isSeeded;
  }

  /// Tüm benzersiz malzemeler (alfabetik)
  List<String> get allIngredients {
    final set = <String>{};
    for (final r in _recipes) {
      set.addAll(r.ingredients);
    }
    final list = set.toList()..sort((a, b) => a.compareTo(b));
    return list;
  }

  /// Firestore stream'ini dinle
  Stream<List<Recipe>> get recipesStream => _service.recipesStream();

  void updateRecipes(List<Recipe> recipes) {
    _recipes = recipes;
    notifyListeners();
  }

  void setSearchTerm(String term) {
    _searchTerm = term;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Recipe? getById(String id) {
    try {
      return _recipes.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  // Mevcut tariflerden benzersiz kategorileri döner
  List<String> getCategories() {
    return _recipes.map((r) => r.category).toSet().toList()..sort();
  }

  // Kategoriye göre rastgele tarif (category null ise tümünden)
  Recipe? getRandomRecipe({String? category}) {
    final list = category == null
        ? _recipes
        : _recipes.where((r) => r.category == category).toList();
    if (list.isEmpty) return null;
    return list[Random().nextInt(list.length)];
  }

  Future<void> addRecipe(Recipe recipe) async {
    await _service.addRecipe(recipe);
  }

  Future<void> updateRecipe(Recipe recipe) async {
    await _service.updateRecipe(recipe);
  }

  Future<void> deleteRecipe(String id) async {
    await _service.deleteRecipe(id);
  }

  Future<void> toggleFavorite(String id, bool current) async {
    final index = _recipes.indexWhere((r) => r.id == id);
    if (index == -1) {
      await _service.toggleFavorite(id, current);
      return;
    }

    // Önce yerelde güncelle, ekran hemen değişsin
    final oldRecipe = _recipes[index];
    _recipes[index] = oldRecipe.copyWith(favorite: !current);
    notifyListeners();

    try {
      await _service.toggleFavorite(id, current);
    } catch (e) {
      // Hata olursa geri al
      final i = _recipes.indexWhere((r) => r.id == id);
      if (i != -1) {
        _recipes[i] = oldRecipe;
        notifyListeners();
      }
      rethrow;
    }
  }

  Future<String?> uploadImage(File file) async {
    try {
      return await _service.uploadImage(file);
    } catch (_) {
      return null;
    }
  }

  /// İlk kayıt sonrası örnek tarifleri Firestore'a ekler (varsa es geçer)
  Future<void> seedSampleRecipes() async {
    await _service.seedSampleRecipes();
  }

  List<RecipeMatch> findByIngredients(List<String> selected) {
    return _service.findByIngredients(_recipes, selected);
  }

  Future<void> deleteAllUserRecipes() async {
    await _service.deleteAllUserRecipes();
    _recipes.clear();
    notifyListeners();
  }
}
