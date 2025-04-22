import 'package:barber_xe/controllers/home_controller.dart';
import 'package:barber_xe/firebase_options.dart';
import 'package:barber_xe/pages/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Services
import 'services/auth_service.dart';
import 'services/user_service.dart';
import 'services/storage_service.dart';

// Controllers
import 'controllers/profile_controller.dart';
import 'controllers/auth_controller.dart';

// Pages
import 'pages/auth/login_page.dart';
import 'pages/auth/register_page.dart';
import 'pages/profile/profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    runApp(
      MultiProvider(
        providers: [
          Provider(create: (_) => AuthService()),
          Provider(create: (_) => UserService()),
          Provider(create: (_) => StorageService()),
          ChangeNotifierProvider(
            create: (context) => ProfileController(
              authService: context.read<AuthService>(),
              userService: context.read<UserService>(),
              storageService: context.read<StorageService>(),
            ),
          ),
          ChangeNotifierProvider(
            create: (context) => AuthController(
              authService: context.read<AuthService>(),
              userService: context.read<UserService>(),
            ),
          ),
          ChangeNotifierProvider(
          create: (context) => HomeController(
            userService: context.read<UserService>(),
          ),
        ),
        ],
      child: const MyApp(),
    ),
    );
  } catch (e) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Error inicializando Firebase: $e')),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BarberXE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.brown,
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.brown[800],
          elevation: 0,
          centerTitle: true,
          titleTextStyle: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.brown[800],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.brown[800],
          ),
        ),
      ),
      home: const AuthChecker(),
      routes: {
        '/home': (context) => const HomePage(),
        //'/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}

class AuthChecker extends StatelessWidget {
  const AuthChecker({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final authController = Provider.of<AuthController>(context, listen: false);

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          if (user == null) {
            return const LoginPage();
          }
          
          return FutureBuilder(
            future: _loadUserAndNavigate(context, authController),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return const HomePage();
              }
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            },
          );
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Future<void> _loadUserAndNavigate(BuildContext context, AuthController authController) async {
    try {
      final profileController = Provider.of<ProfileController>(context, listen: false);
      await profileController.loadCurrentUser();
      
      final homeController = Provider.of<HomeController>(context, listen: false);
      await homeController.loadServices();

      // Verifica si el widget sigue montado
      if (context.mounted) {
        // No necesitas navegar aquí ya que el FutureBuilder ya maneja la navegación
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: ${e.toString()}')),
        );
      }
    }
  }
}