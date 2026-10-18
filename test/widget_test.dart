import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_book/models/recipe.dart';
import 'package:recipe_book/providers/recipe_provider.dart';
import 'package:recipe_book/services/recipe_service.dart';

class FakeRecipeService implements RecipeService {
  @override
  Stream<List<Recipe>> recipesStream() => const Stream.empty();

  @override
  Future<Recipe> addRecipe(Recipe recipe) async => recipe;

  @override
  Future<void> updateRecipe(Recipe recipe) async {}

  @override
  Future<void> deleteRecipe(String id) async {}

  @override
  Future<void> toggleFavorite(String id, bool currentValue) async {}

  @override
  Future<String> uploadImage(File imageFile) async => '';

  @override
  Future<void> seedSampleRecipes() async {}

  @override
  Future<void> deleteAllUserRecipes() async {}

  @override
  List<String> getAllIngredients(List<Recipe> recipes) => [];

  @override
  List<RecipeMatch> findByIngredients(List<Recipe> recipes, List<String> selected) => [];
}

void main() {
  group('Recipe Model and Provider Tests', () {
    test('Recipe empty factory creates default recipe', () {
      final recipe = Recipe.empty();
      expect(recipe.id, '');
      expect(recipe.userId, '');
      expect(recipe.authorName, '');
      expect(recipe.isSeeded, false);
      expect(recipe.favorite, false);
    });

    test('Recipe copyWith correctly updates userId and authorName', () {
      final recipe = Recipe.empty();
      final updated = recipe.copyWith(
        id: 'rec_123',
        name: 'Menemen',
        userId: 'user_456',
        authorName: 'Cemre',
      );

      expect(updated.id, 'rec_123');
      expect(updated.name, 'Menemen');
      expect(updated.userId, 'user_456');
      expect(updated.authorName, 'Cemre');
    });

    test('RecipeProvider ownership check allows only recipe creator', () {
      final fakeService = FakeRecipeService();
      final provider = RecipeProvider(service: fakeService);
      final now = DateTime(2026, 1, 1);

      final userRecipe = Recipe(
        id: 'r1',
        name: 'Tavuk Sote',
        image: '',
        category: 'Ana Yemek',
        duration: 30,
        difficulty: 'Kolay',
        servings: 2,
        ingredients: const ['Tavuk'],
        instructions: 'Pişir',
        favorite: false,
        createdAt: now,
        userId: 'user_123',
        isSeeded: false,
      );

      final seededRecipe = Recipe(
        id: 'r2',
        name: 'Makarna',
        image: '',
        category: 'Ana Yemek',
        duration: 20,
        difficulty: 'Kolay',
        servings: 2,
        ingredients: const ['Makarna'],
        instructions: 'Haşla',
        favorite: false,
        createdAt: now,
        userId: 'user_123',
        isSeeded: true,
      );

      // Kendi tarifini düzenleyebilir/silebilir
      expect(provider.isOwner(userRecipe, 'user_123'), true);

      // Başkasının tarifini düzenleyemez/silemez
      expect(provider.isOwner(userRecipe, 'other_user'), false);

      // Seed / örnek tarifler kendi ID'si olsa bile silinemez/düzenlenemez
      expect(provider.isOwner(seededRecipe, 'user_123'), false);
    });
  });
}
