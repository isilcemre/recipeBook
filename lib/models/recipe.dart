import 'package:cloud_firestore/cloud_firestore.dart';

const List<String> kCategories = [
  'Ana Yemek',
  'Çorba',
  'Salata',
  'Tatlı',
  'Kahvaltı',
  'Aperatif',
  'İçecek',
];

const List<String> kDifficulties = ['Kolay', 'Orta', 'Zor'];

const String kDefaultImage =
    'https://images.unsplash.com/photo-1495521821757-a1efb6729352?w=600&q=80&auto=format&fit=crop';

class Recipe {
  final String id;
  final String name;
  final String image;
  final String category;
  final int duration;
  final String difficulty;
  final int servings;
  final List<String> ingredients;
  final String instructions;
  final bool favorite;
  final DateTime createdAt;
  final String userId;
  final String authorName;
  final bool isSeeded; // true = uygulama tarafından eklendi, düzenlenemez/silinemez

  const Recipe({
    required this.id,
    required this.name,
    required this.image,
    required this.category,
    required this.duration,
    required this.difficulty,
    required this.servings,
    required this.ingredients,
    required this.instructions,
    required this.favorite,
    required this.createdAt,
    required this.userId,
    this.authorName = '',
    this.isSeeded = false,
  });

  factory Recipe.empty() => Recipe(
        id: '',
        name: '',
        image: '',
        category: kCategories.first,
        duration: 30,
        difficulty: kDifficulties.first,
        servings: 2,
        ingredients: const [],
        instructions: '',
        favorite: false,
        createdAt: DateTime.now(),
        userId: '',
        authorName: '',
      );

  factory Recipe.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Recipe(
      id: doc.id,
      name: data['name'] as String? ?? '',
      image: data['image'] as String? ?? '',
      category: data['category'] as String? ?? kCategories.first,
      duration: (data['duration'] as num?)?.toInt() ?? 30,
      difficulty: data['difficulty'] as String? ?? kDifficulties.first,
      servings: (data['servings'] as num?)?.toInt() ?? 2,
      ingredients: List<String>.from(data['ingredients'] as List? ?? []),
      instructions: data['instructions'] as String? ?? '',
      favorite: data['favorite'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userId: data['userId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? '',
      isSeeded: data['isSeeded'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'image': image,
        'category': category,
        'duration': duration,
        'difficulty': difficulty,
        'servings': servings,
        'ingredients': ingredients,
        'instructions': instructions,
        'favorite': favorite,
        'createdAt': Timestamp.fromDate(createdAt),
        'userId': userId,
        'authorName': authorName,
        'isSeeded': isSeeded,
      };

  Recipe copyWith({
    String? id,
    String? name,
    String? image,
    String? category,
    int? duration,
    String? difficulty,
    int? servings,
    List<String>? ingredients,
    String? instructions,
    bool? favorite,
    DateTime? createdAt,
    String? userId,
    String? authorName,
    bool? isSeeded,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      category: category ?? this.category,
      duration: duration ?? this.duration,
      difficulty: difficulty ?? this.difficulty,
      servings: servings ?? this.servings,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      favorite: favorite ?? this.favorite,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      authorName: authorName ?? this.authorName,
      isSeeded: isSeeded ?? this.isSeeded,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Recipe && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Elindeki malzemelere göre tarif eşleştirme sonucu
class RecipeMatch {
  final Recipe recipe;
  final int matchCount;
  final int missingCount;
  final List<String> missing;
  final int matchPercent;

  const RecipeMatch({
    required this.recipe,
    required this.matchCount,
    required this.missingCount,
    required this.missing,
    required this.matchPercent,
  });
}
