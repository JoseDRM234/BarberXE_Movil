import 'package:barber_xe/models/profile_data.dart';
import 'package:barber_xe/routes/app_routes.dart';
import 'package:barber_xe/routes/route_names.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/storage_service.dart';

class ProfileController with ChangeNotifier {
  AuthService _authService;
  final UserService _userService;
  final StorageService _storageService;

  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isEditing = false;
  final bool _isDisposed = false;
  
  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isEditing => _isEditing;
  bool get isAdmin => _currentUser?.role == 'admin';
  
  ProfileController({
    required AuthService authService,
    required UserService userService,
    required StorageService storageService,
  })  : _authService = authService,
        _userService = userService,
        _storageService = storageService;

  // Método para actualizar el AuthService
  void updateAuthService(AuthService authService) {
    _authService = authService;
    loadCurrentUser();
  }

  Future<void> loadCurrentUser() async {
  if (_isLoading) return;
  _isLoading = true;   
  notifyListeners();

  try {
      final authService = Provider.of<AuthService>(
        AppRouter.navigatorKey.currentContext!,
        listen: false
      );
      
      if (authService.currentUser == null) {
        _currentUser = null;
        return;
      }

      final userDoc = await _userService.getUser(authService.currentUser!.uid);
      
      if (userDoc == null) {
        final firebaseUser = _authService.currentUser!;
        _currentUser = UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          nombre: firebaseUser.displayName?.split(' ').first ?? '',
          apellido: firebaseUser.displayName?.split(' ').last ?? '',
          role: 'cliente',
          createdAt: DateTime.now(),
          activo: true,
        );
        await _userService.createUser(_currentUser!);
      } else {
        _currentUser = userDoc;
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleEditMode() {
    _isEditing = !_isEditing;
    notifyListeners();
    return Future.value();
  }

  Future<void> updateProfile(ProfileData data) async {
    if (_currentUser == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _userService.updateUser(_currentUser!.uid, {
        'nombre': data.nombre,
        'apellido': data.apellido,
        'telefono': data.telefono,
        if (data.fotoUrl != null) 'fotoUrl': data.fotoUrl,
      });

      if (data.password != null && data.password!.isNotEmpty) {
        await _authService.updatePassword(data.password!);
      }

      await loadCurrentUser();
    } catch (e) {
      print("Error updating profile: $e");
      rethrow;
    } finally {
      _isLoading = false;
      _isEditing = false;
      notifyListeners();
    }
  }

  Future<String?> uploadProfileImage(XFile image) async {
    if (_currentUser == null) return null;

    try {
      if (_currentUser!.photoUrl != null) {
        await _storageService.deleteProfileImage(_currentUser!.photoUrl);
      }

      String? imageUrl = await _storageService.uploadProfileImage(
        _currentUser!.uid,
        image,
      );

      if (imageUrl != null) {
        await _userService.updateUser(_currentUser!.uid, {
          'fotoUrl': imageUrl,
        });
        await loadCurrentUser();
      }

      return imageUrl;
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  Future<void> clearProfile() async {
    _currentUser = null;
    _isLoading = false;
    _isEditing = false;
    notifyListeners();
  }

  Future<void> logout() async {
  _isLoading = true;
  notifyListeners();

  try {
      _currentUser = null;
      _isEditing = false;
      
      await _authService.signOut();
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppRouter.navigatorKey.currentState?.pushNamedAndRemoveUntil(
          RouteNames.login,
          (route) => false,
        );
      });
    } catch (e) {
      debugPrint('Error en logout: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

}