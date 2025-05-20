import 'package:barber_xe/controllers/appointment_controller.dart';
import 'package:barber_xe/controllers/barber_controller.dart';
import 'package:barber_xe/controllers/services_controller.dart';
import 'package:barber_xe/firebase_options.dart';
import 'package:barber_xe/pages/auth/login_page.dart';
import 'package:barber_xe/pages/home/home_page.dart';
import 'package:barber_xe/services/barber_services.dart';
import 'package:barber_xe/routes/app_routes.dart';
import 'package:barber_xe/routes/route_names.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
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

  Intl.defaultLocale = 'es_ES';
  await initializeDateFormatting('es_ES', null);
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
          Provider(create: (_) => BarberService()),
        ChangeNotifierProvider(create: (_) => BarberController(
          barberService: BarberService(),
        )),
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
          ChangeNotifierProvider(create: (_) => ServiceController()),
          ChangeNotifierProvider(
            create: (context) => AppointmentController(
              serviceController: context.read<ServiceController>(), barberController: context.read<BarberController>(),
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
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'), // Español como idioma principal
      ],
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
    final authService = context.watch<AuthService>();
    final profileController = context.read<ProfileController>();

    return FutureBuilder<User?>(
      future: authService.currentUserFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginPage();
        }

        return FutureBuilder<void>(
          future: profileController.loadCurrentUser(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            
            return const HomePage();
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
    try {
      final profileController = context.read<ProfileController>();
      await profileController.loadCurrentUser();
      
      // Verificar que el usuario se cargó correctamente
      if (profileController.currentUser == null) {
        throw Exception('No se pudo cargar el perfil del usuario');
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      rethrow;
    }
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

      final serviceController = Provider.of<ServiceController>(
        AppRouter.navigatorKey.currentContext!,
        listen: false,
      );
      await serviceController.loadServicesAndCombos();
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