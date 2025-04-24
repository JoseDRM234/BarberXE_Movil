import 'package:barber_xe/models/service_model.dart';
import 'package:barber_xe/pages/auth/login_page.dart';
import 'package:barber_xe/pages/auth/register_page.dart';
import 'package:barber_xe/pages/home/home_page.dart';
import 'package:barber_xe/pages/profile/profile_page.dart';
import 'package:barber_xe/pages/services/service_page.dart';
import 'package:barber_xe/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class AppRouter {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String service = '/service';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final authService = Provider.of<AuthService>(navigatorKey.currentContext!, listen: false);

    // Rutas públicas
    if (settings.name == login || settings.name == register) {
      return _buildRoute(settings);
    }

    // Verificar autenticación para rutas protegidas
    if (authService.currentUser == null) {
      return MaterialPageRoute(
        builder: (_) => const LoginPage(),
        settings: const RouteSettings(name: login),
      );
    }

    return _buildRoute(settings);
  }

  static MaterialPageRoute _buildRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterPage());
      case home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfilePage());
      case service:
        final service = settings.arguments as BarberService?;
        return MaterialPageRoute(
          builder: (_) => ServicePage(service: service),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),  // Paréntesis de cierre añadido aquí
        );
    }
  }

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static void showErrorSnackBar(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentState?.overlay?.context;
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    });
  }

  static BuildContext? get safeContext {
    try {
      final context = navigatorKey.currentState?.overlay?.context;
      return context?.mounted == true ? context : null;
    } catch (e) {
      return null;
    }
  }
}