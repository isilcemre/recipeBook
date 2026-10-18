import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/recipe.dart';
import '../data/sample_recipes.dart';

class RecipeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? '';

  CollectionReference<Map<String, dynamic>> get _recipes =>
      _db.collection('recipes');

  /// Kullanıcının henüz veritabanında olmayan örnek tariflerini Firestore'a ekler.
  Future<void> seedSampleRecipes() async {
    if (_uid.isEmpty) return;

    // Kullanıcının mevcut tariflerinin isimlerini al
    final existing = await _recipes
        .where('userId', isEqualTo: _uid)
        .get();
    final existingNames = existing.docs
        .map((doc) => (doc.data()['name'] as String? ?? '').trim().toLowerCase())
        .toSet();

    final samples = buildSampleRecipes(_uid);
    final batch = _db.batch();
    int newCount = 0;

    for (final recipe in samples) {
      if (!existingNames.contains(recipe.name.trim().toLowerCase())) {
        final ref = _recipes.doc();
        batch.set(
          ref,
          recipe.copyWith(authorName: 'Şefin Tarifi').toFirestore(),
        );
        newCount++;
      }
    }

    if (newCount > 0) {
      await batch.commit();
    }
  }

  /// Kullanıcının tariflerini gerçek zamanlı akış olarak döner
  Stream<List<Recipe>> recipesStream() {
    return _recipes
        .where('userId', isEqualTo: _uid)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(Recipe.fromFirestore).toList();
      // Firestore'da composite index gerekmemesi için sıralamayı Dart'ta yapıyoruz
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Tarif ekle (oturumdaki kullanıcının ID ve kullanıcı adını atar)
  Future<Recipe> addRecipe(Recipe recipe) async {
    final user = _auth.currentUser;
    final uid = user?.uid ?? '';
    final author = user?.displayName ?? user?.email?.split('@').first ?? 'Kullanıcı';

    final data = recipe.copyWith(
      userId: uid,
      authorName: recipe.authorName.isNotEmpty ? recipe.authorName : author,
      createdAt: DateTime.now(),
      isSeeded: false,
    );
    final ref = await _recipes.add(data.toFirestore());
    return data.copyWith(id: ref.id);
  }

  /// Tarif güncelle (sadece kendi tarifini güncelleyebilir)
  Future<void> updateRecipe(Recipe recipe) async {
    if (recipe.isSeeded) {
      throw Exception('Örnek tarifler düzenlenemez.');
    }
    if (recipe.userId.isNotEmpty && recipe.userId != _uid) {
      throw Exception('Yalnızca kendi eklediğiniz tarifleri düzenleyebilirsiniz.');
    }
    await _recipes.doc(recipe.id).update(recipe.toFirestore());
  }

  /// Tarif sil (sadece kendi tarifini silebilir)
  Future<void> deleteRecipe(String id) async {
    final doc = await _recipes.doc(id).get();
    if (!doc.exists) return;

    final data = doc.data();
    if (data != null) {
      final docUserId = data['userId'] as String? ?? '';
      final isSeeded = data['isSeeded'] as bool? ?? false;

      if (isSeeded) {
        throw Exception('Örnek tarifler silinemez.');
      }
      if (docUserId.isNotEmpty && docUserId != _uid) {
        throw Exception('Yalnızca kendi eklediğiniz tarifleri silebilirsiniz.');
      }
    }

    await _recipes.doc(id).delete();
  }

  /// Favori durumunu değiştir
  Future<void> toggleFavorite(String id, bool currentValue) async {
    await _recipes.doc(id).update({'favorite': !currentValue});
  }

  /// Resim yükle ve URL döndür
  Future<String> uploadImage(File imageFile) async {
    final fileName = '${_uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('recipe_images/$fileName');
    await ref.putFile(imageFile);
    return ref.getDownloadURL();
  }

  /// Tüm malzemeleri listele (eşsiz, sıralı)
  List<String> getAllIngredients(List<Recipe> recipes) {
    final set = <String>{};
    for (final r in recipes) {
      set.addAll(r.ingredients);
    }
    final list = set.toList();
    list.sort((a, b) => a.compareTo(b));
    return list;
  }

  /// Seçili malzemelere göre eşleşen tarifleri sırala
  List<RecipeMatch> findByIngredients(
    List<Recipe> recipes,
    List<String> selected,
  ) {
    if (selected.isEmpty) return [];
    final selectedLower = selected.map((s) => s.toLowerCase()).toList();

    final matches = <RecipeMatch>[];
    for (final recipe in recipes) {
      final recipeIngLower =
          recipe.ingredients.map((i) => i.toLowerCase()).toList();
      final matchCount =
          recipeIngLower.where(selectedLower.contains).length;
      if (matchCount == 0) continue;
      final missing = recipe.ingredients
          .where((i) => !selectedLower.contains(i.toLowerCase()))
          .toList();
      final matchPercent =
          (matchCount / recipe.ingredients.length * 100).round();
      matches.add(RecipeMatch(
        recipe: recipe,
        matchCount: matchCount,
        missingCount: missing.length,
        missing: missing,
        matchPercent: matchPercent,
      ));
    }

    matches.sort((a, b) {
      final pctCmp = b.matchPercent.compareTo(a.matchPercent);
      if (pctCmp != 0) return pctCmp;
      return b.matchCount.compareTo(a.matchCount);
    });

    return matches;
  }

  /// Kullanıcının tüm tariflerini veritabanından sil (hesap silindiğinde)
  Future<void> deleteAllUserRecipes() async {
    if (_uid.isEmpty) return;
    final docs = await _recipes.where('userId', isEqualTo: _uid).get();
    final batch = _db.batch();
    for (final doc in docs.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
