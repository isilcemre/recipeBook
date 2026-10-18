# My Recipe Book — Akıllı Tarif Defteri 🍽️

A personal recipe management app built with Flutter and Firebase, allowing users to register, log in, and manage their own recipes with smart ingredient-based search.

---

## Features

- User registration and login with Firebase Authentication
- Each user can only see and manage their own recipes
- Add recipes with name, category, difficulty, duration, servings, ingredients, instructions, and a photo
- Edit and delete your own recipes (seeded sample recipes are read-only)
- Favorite any recipe and view them in the Favorites tab
- **🧺 What's in the Fridge?** — Select ingredients you have at home and get matching recipes with match percentage
- **🎲 Random Recipe** — Get a random recipe suggestion filtered by category
- Real-time sync with Firestore — changes appear instantly across sessions
- Update username or password from the Settings page
- Delete account along with all associated recipes

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart SDK ^3.12.0) |
| Backend / Auth | Firebase Authentication |
| Database | Cloud Firestore (real-time) |
| Storage | Firebase Storage (recipe images) |
| State Management | Provider ^6.1.2 |
| Navigation | go_router ^14.8.1 |
| Image | image_picker, cached_network_image |
| Fonts | Google Fonts (Fraunces, Inter, IBM Plex Mono) |
| Icons | lucide_icons_flutter |

---

## Project Structure

```
lib/
├── main.dart                             # Entry point
├── firebase_options.dart                 # Firebase config
├── data/
│   ├── ingredients_data.dart             # Categorized ingredient list
│   └── sample_recipes.dart               # Seed recipes for new users
├── models/
│   └── recipe.dart                       # Recipe & RecipeMatch models
├── providers/
│   ├── auth_provider.dart                # Auth state (ChangeNotifier)
│   └── recipe_provider.dart              # Recipe state + filtering logic
├── services/
│   ├── auth_service.dart                 # Firebase Auth operations
│   └── recipe_service.dart               # Firestore CRUD + image upload
├── screens/
│   ├── splash_screen.dart
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── home/
│   │   ├── home_screen.dart              # Recipe grid + search + random pick
│   │   └── widgets/
│   │       ├── hero_banner.dart
│   │       ├── category_filter.dart
│   │       └── recipe_card.dart
│   ├── recipe_detail/
│   │   └── recipe_detail_screen.dart     # Full recipe view
│   ├── recipe_form/
│   │   └── recipe_form_screen.dart       # Add / edit recipe form
│   ├── favorites/
│   │   └── favorites_screen.dart
│   ├── available_ingredients/
│   │   └── available_ingredients_screen.dart  # Ingredient matcher
│   ├── profile/
│   │   └── profile_screen.dart
│   └── settings/
│       └── settings_screen.dart          # Username, password, delete account
├── theme/
│   └── app_theme.dart                    # Colors & Material 3 theme
└── widgets/
    ├── main_scaffold.dart                # Bottom nav bar scaffold
    ├── app_snackbar.dart
    └── confirm_dialog.dart
```

---

## Getting Started

### Prerequisites

- Flutter SDK ^3.12.0
- A Firebase project with **Authentication**, **Firestore**, and **Storage** enabled
- FlutterFire CLI (for `firebase_options.dart` generation)

### Firebase Setup

1. Create a new Firebase project at [console.firebase.google.com](https://console.firebase.google.com).
2. Enable **Email/Password** authentication.
3. Create a **Firestore** database (start in test mode or configure rules).
4. Enable **Firebase Storage**.
5. Run the FlutterFire CLI to generate `firebase_options.dart`:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

### Firestore Rules (recommended)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /recipes/{recipeId} {
      allow read, write: if request.auth != null
        && request.auth.uid == resource.data.userId;
      allow create: if request.auth != null;
    }
  }
}
```

### Running the App

```bash
flutter pub get
flutter run
```

---

## Usage

1. Open the app and tap **Register** to create an account.
2. Log in — the app will automatically seed a set of sample recipes to your account.
3. Browse recipes on the **Home** screen; use the search bar or category filters.
4. Tap **🎲 Şansıma Bırak** on the hero banner to get a random recipe, optionally filtered by category.
5. Add your own recipes via the **＋** button — enter name, category, difficulty, duration, servings, ingredients, instructions, and an optional photo.
6. Tap a recipe card to view full details; edit or delete your own recipes from there.
7. Favorite recipes appear in the **Favorites** tab.
8. Go to **🧺 Buzdolabında Ne Var?**, select ingredients you have, and tap **Tarif Bul** to see matching recipes ranked by match percentage.
9. Manage your account (username, password, delete) from the **Settings** tab.

---

## Recipe Categories

| Category | |
|---|---|
| Ana Yemek | Main Course |
| Çorba | Soup |
| Salata | Salad |
| Tatlı | Dessert |
| Kahvaltı | Breakfast |
| Aperatif | Appetizer |
| İçecek | Beverage |

---

## Screenshots

<img width="250"  alt="Screenshot_1792323858" src="https://github.com/user-attachments/assets/20f5549e-4875-48f6-a5ef-39e0b81ff671" />
<img width="250"  alt="Screenshot_1792324383" src="https://github.com/user-attachments/assets/3ece72aa-5c8e-4acd-89f5-8f662f71cd50" />
<img width="250"  alt="Screenshot_1792324624" src="https://github.com/user-attachments/assets/3d050214-fb16-4159-8829-fc3dcb87ee3b" />
<img width="250"  alt="Screenshot_1792324398" src="https://github.com/user-attachments/assets/66d3c0c5-7ba6-4350-8ab2-6417bcba8085" />
<img width="250"  alt="Screenshot_1792324437" src="https://github.com/user-attachments/assets/7e062d47-b9a0-4caa-a641-826c3c077f7f" />
<img width="250"  alt="Screenshot_1792324499" src="https://github.com/user-attachments/assets/0d84f112-6907-48e9-9c2a-5689634f563d" />
<img width="250"  alt="Screenshot_1792324505" src="https://github.com/user-attachments/assets/ea53885b-22da-4d72-b7ef-fb0e761f6f31" />
<img width="250"  alt="Screenshot_1792324527" src="https://github.com/user-attachments/assets/4f9d3d9b-7429-45d8-8f57-5e57b69f31c4" />
<img width="250"  alt="Screenshot_1792324605" src="https://github.com/user-attachments/assets/699b94ec-89e6-4a43-b4ea-f54524646ca4" />
<img width="250"  alt="Screenshot_1792324527" src="https://github.com/user-attachments/assets/311e91f4-e8a8-4701-b8ee-21a9f007f539" />



