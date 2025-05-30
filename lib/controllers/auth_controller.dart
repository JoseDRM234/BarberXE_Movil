import 'package:barber_xe/models/user_model.dart';
import 'package:barber_xe/routes/app_routes.dart';
import 'package:barber_xe/routes/route_names.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class AuthController with ChangeNotifier {
  final AuthService _authService;
  final UserService _userService;
  
  bool _isLoading = false;
  String? _errorMessage;
  User? _user;
  UserModel? _currentUser;

  AuthController({
    required AuthService authService,
    required UserService userService,
  })  : _authService = authService,
        _userService = userService {
    // Listen to auth state changes
    _authService.authStateChanges.listen((User? user) async {
      _user = user;
      if (user != null) {
        // Load user data when authenticated
        await _loadCurrentUser(user.uid);
      } else {
        _currentUser = null;
      }
      notifyListeners();
    });
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get user => _user;
  UserModel? get currentUser => _currentUser;

  // Método para cargar datos del usuario actual
  Future<void> _loadCurrentUser(String uid) async {
    try {
      _currentUser = await _userService.getUser(uid);
    } catch (e) {
      debugPrint('Error loading current user: $e');
      _currentUser = null;
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (user == null) throw Exception('No se pudo iniciar sesión');

      // Load user data after successful login
      await _loadCurrentUser(user.uid);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppRouter.navigatorKey.currentState?.pushNamedAndRemoveUntil(
          RouteNames.home,
          (route) => false,
        );
      });

    } catch (e) {
      _errorMessage = e.toString();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (AppRouter.navigatorKey.currentState?.overlay?.context != null) {
          ScaffoldMessenger.of(AppRouter.navigatorKey.currentState!.overlay!.context)
            .showSnackBar(SnackBar(content: Text(_errorMessage!)));
        }
      });
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(
    String email,
    String password,
    String name,
    String apellido,
    String telefono,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (email.isEmpty || password.isEmpty || name.isEmpty || apellido.isEmpty) {
        throw ArgumentError('Nombre, apellido, email y contraseña son obligatorios');
      }

      if (telefono.isNotEmpty && !RegExp(r'^[0-9]+$').hasMatch(telefono)) {
        throw ArgumentError('Ingrese un teléfono válido');
      }

      final user = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (user == null) {
        throw Exception('No se pudo crear el usuario en Firebase Auth');
      }

      final newUser = UserModel(
        uid: user.uid,
        email: email,
        nombre: name,
        apellido: apellido,
        telefono: telefono.isNotEmpty ? telefono : null,
        photoUrl: null,
        role: 'cliente',
        createdAt: DateTime.now(),
        updatedAt: null,
        activo: true,
        clienteId: null,
      );

      await _userService.createUser(newUser);
      await user.updateDisplayName('$name $apellido');
      
      // Set current user after successful registration
      _currentUser = newUser;
      
    } on FirebaseAuthException catch (e) {
      _errorMessage = _authService.handleAuthError(e);
      throw Exception(_errorMessage);
    } on ArgumentError catch (e) {
      _errorMessage = e.message;
      rethrow;
    } catch (e) {
      _errorMessage = 'Error al registrar: ${e.toString()}';
      throw Exception(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Método mejorado para Google Sign-In con opción de seleccionar cuenta
  Future<void> signInWithGoogle({bool forceAccountSelection = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Realizar autenticación con Google
      final result = await _authService.signInWithGoogle(
        forceAccountSelection: forceAccountSelection
      );
      _user = result.user;
      
      if (_user != null) {
        // Guardar/actualizar usuario en Firestore
        final userModel = await _userService.saveUser(_user!);
        _currentUser = userModel;
        
        // Navegar a la pantalla principal
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppRouter.navigatorKey.currentState?.pushNamedAndRemoveUntil(
            RouteNames.home,
            (route) => false,
          );
        });
        
        debugPrint('Google Sign-In exitoso: ${_user!.email}');
      } else {
        throw Exception('No se pudo obtener información del usuario');
      }
      
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error en Google Sign-In: $_errorMessage');
      
      // Mostrar error al usuario
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (AppRouter.navigatorKey.currentState?.overlay?.context != null) {
          ScaffoldMessenger.of(AppRouter.navigatorKey.currentState!.overlay!.context)
            .showSnackBar(
              SnackBar(
                content: Text(_errorMessage!),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
        }
      });
      
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Método para cambiar cuenta de Google
  Future<void> changeGoogleAccount() async {
    await signInWithGoogle(forceAccountSelection: true);
  }

  // Método para actualizar perfil del usuario
  Future<void> updateUserProfile({
    String? nombre,
    String? apellido,
    String? telefono,
    String? photoUrl,
  }) async {
    if (_currentUser == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _userService.updateUserInfo(
        uid: _currentUser!.uid,
        nombre: nombre,
        apellido: apellido,
        telefono: telefono,
        photoUrl: photoUrl,
      );

      // Recargar información del usuario
      await _loadCurrentUser(_currentUser!.uid);
      
    } catch (e) {
      _errorMessage = 'Error actualizando perfil: ${e.toString()}';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Método para limpiar errores
  void resetError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Método para verificar si el usuario está autenticado
  bool get isAuthenticated => _user != null;

  // Método para obtener información básica del usuario
  String get userDisplayName {
    if (_currentUser != null) {
      return _currentUser!.fullName.isNotEmpty 
          ? _currentUser!.fullName 
          : _currentUser!.email;
    }
    return _user?.displayName ?? _user?.email ?? 'Usuario';
  }

  String? get userPhotoUrl => _currentUser?.photoUrl ?? _user?.photoURL;
  String get userEmail => _currentUser?.email ?? _user?.email ?? '';

  // Método para verificar si hay sesión activa de Google
  Future<bool> isGoogleSignedIn() async {
    return await _authService.isGoogleSignedIn();
  }

  // Método mejorado para cerrar sesión
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _authService.signOut(); // Esto ahora cierra tanto Firebase como Google
      _user = null;
      _currentUser = null;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Método específico para forzar selección de cuenta
  Future<void> signInWithGoogleForceSelection() async {
    await signInWithGoogle(forceAccountSelection: true);
  }
}