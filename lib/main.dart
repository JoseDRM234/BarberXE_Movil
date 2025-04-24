import 'package:barber_xe/controllers/home_controller.dart';
import 'package:barber_xe/controllers/services_controller.dart';
import 'package:barber_xe/firebase_options.dart';
import 'package:barber_xe/pages/auth/login_page.dart';
import 'package:barber_xe/pages/home/home_page.dart';
import 'package:barber_xe/routes/app_routes.dart';
import 'package:barber_xe/routes/route_names.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

// Services
import 'services/auth_service.dart';
import 'services/user_service.dart';
import 'services/storage_service.dart';

// Controllers
import 'controllers/profile_controller.dart';
import 'controllers/auth_controller.dart';


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
          ChangeNotifierProvider(create: (_) => ServiceController()),
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
      navigatorKey: AppRouter.navigatorKey,
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: RouteNames.splash,
      home: const AuthChecker(),
    );
  }
}

class AuthChecker extends StatelessWidget {
  const AuthChecker({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        return FutureBuilder<User?>(
          future: authService.currentUserFuture,
          builder: (context, authSnapshot) {
            if (authSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            if (authSnapshot.hasError || authSnapshot.data == null) {
              return const LoginPage();
            }

            return _ProfileLoader(user: authSnapshot.data!);
          },
        );
      },
    );
  }
}

class _ProfileLoader extends StatefulWidget {
  final User user;

  const _ProfileLoader({required this.user});

  @override
  State<_ProfileLoader> createState() => _ProfileLoaderState();
}

class _ProfileLoaderState extends State<_ProfileLoader> {
  late Future<void> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profileController = context.read<ProfileController>();
    await profileController.loadCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return const HomePage();
      },
    );
  }
}

class _AppInitializer extends StatefulWidget {
  final User user;
  final Widget child;

  const _AppInitializer({
    required this.user,
    required this.child,
  });

  @override
  State<_AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<_AppInitializer> {
  late Future<void> _initialization;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _initialization = _initializeApp();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      if (_disposed) return;

      final profileController = Provider.of<ProfileController>(
        AppRouter.navigatorKey.currentContext!,
        listen: false,
      );
      await profileController.loadCurrentUser();
      
      if (_disposed) return;

      final homeController = Provider.of<HomeController>(
        AppRouter.navigatorKey.currentContext!,
        listen: false,
      );
      await homeController.loadServices();
    } catch (e) {
      debugPrint('Error initializing app: $e');
      if (!_disposed && AppRouter.navigatorKey.currentState?.mounted == true) {
        ScaffoldMessenger.of(AppRouter.navigatorKey.currentContext!).showSnackBar(
          SnackBar(content: Text('Error loading data: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(child: Text('Error: ${snapshot.error}')),
            );
          }
          return widget.child;
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}