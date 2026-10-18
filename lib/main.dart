import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_book/screens/profile/profile_screen.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/recipe_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/recipe_detail/recipe_detail_screen.dart';
import 'screens/recipe_form/recipe_form_screen.dart';
import 'screens/favorites/favorites_screen.dart';
import 'screens/available_ingredients/available_ingredients_screen.dart';
import 'screens/settings/settings_screen.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RecipeProvider()),
      ],
      child: MaterialApp(
        title: 'My Recipe Book',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const _AuthGate(),
        onGenerateRoute: _onGenerateRoute,
      ),
    );
  }

  static Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case '/giris':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/kayit-ol':
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case '/favoriler':
        return MaterialPageRoute(builder: (_) => const FavoritesScreen());
      case '/elde-ne-var':
        return MaterialPageRoute(
            builder: (_) => const AvailableIngredientsScreen());
      case '/tarif-ekle':
        return MaterialPageRoute(
            builder: (_) => const RecipeFormScreen());
      case '/profil':
        return MaterialPageRoute(
            builder: (_) => const ProfileScreen());
      case '/ayarlar':
        return MaterialPageRoute(
            builder: (_) => const SettingsScreen());
      case '/tarif':
        final id = settings.arguments as String;
        return MaterialPageRoute(
            builder: (_) => RecipeDetailScreen(recipeId: id));
      case '/tarif-duzenle':
        final id = settings.arguments as String;
        return MaterialPageRoute(
            builder: (_) => RecipeFormScreen(recipeId: id));
      default:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
    }
  }
}

/// Firebase Auth durumuna göre Login veya Ana ekranı gösterir
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return StreamBuilder(
      stream: auth.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
