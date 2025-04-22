import 'package:barber_xe/controllers/profile_controller.dart';
import 'package:barber_xe/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class AuthController with ChangeNotifier {
  final AuthService _authService;
  final UserService _userService;
  
  bool _isLoading = false;
  String? _errorMessage;
  User? _user;

  AuthController({
    required AuthService authService,
    required UserService userService,
  })  : _authService = authService,
        _userService = userService;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get user => _user;

  Future<void> login(String email, String password, BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (user != null) {
        // Cargar perfil del usuario
        final profileController = Provider.of<ProfileController>(context, listen: false);
        await profileController.loadCurrentUser();
        
        // Navegar según el rol
        if (Navigator.of(context).mounted) {
          if (profileController.currentUser?.isAdmin ?? false) {
            Navigator.of(context).pushReplacementNamed('/admin/home');
          } else {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _authService.signOut();
      _user = null;
    } catch (e) {
      _errorMessage = e.toString();
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
        role: 'cliente', // Valor por defecto para nuevos usuarios
        createdAt: DateTime.now(),
        updatedAt: null,
        activo: true,
        clienteId: null,
      );

      await _userService.createUser(newUser);
      await user.updateDisplayName('$name $apellido');
      
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

  Future<void> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.signInWithGoogle();
      _user = result.user;
      
      if (_user != null) {
        await _userService.saveUser(_user!);
      }
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void resetError() {
    _errorMessage = null;
    notifyListeners();
  }

  
}