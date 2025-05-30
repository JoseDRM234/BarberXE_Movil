import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream de cambios en el estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Usuario actual
  User? get currentUser => _auth.currentUser;

  Future<User?> get currentUserFuture async {
    // Esperar a que Firebase Auth se inicialice completamente
    await _auth.authStateChanges().first;
    return _auth.currentUser;
  }

  // Iniciar sesión con email y contraseña
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(code: e.code, message: e.message);
    }
  }

  // Registrar con email y contraseña
  Future<User?> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(code: e.code, message: e.message);
    }
  }

  // Iniciar sesión con Google
  Future<UserCredential> signInWithGoogle({bool forceAccountSelection = false}) async {
    try {
      // Si se solicita forzar selección de cuenta, cerrar sesión primero
      if (forceAccountSelection) {
        await _googleSignIn.signOut();
        await _auth.signOut();
      }

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // El usuario canceló el sign-in
        throw Exception('Inicio de sesión cancelado por el usuario');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      return userCredential;
      
    } catch (e) {
      debugPrint('Error en Google Sign-In: $e');
      rethrow;
    }
  }

  // Desconectar de Google (importante para permitir selección de cuenta)
  Future<void> signOutFromGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      print('Error al desconectar de Google: $e');
    }
  }

  // Cerrar sesión completamente
  Future<void> signOut() async {
    try {
      // Cerrar sesión de Firebase
      await _auth.signOut();
      
      // Cerrar sesión de Google
      await _googleSignIn.signOut();
    } catch (e) {
      throw Exception('Error al cerrar sesión: $e');
    }
  }

  // Manejar errores de Firebase Auth
  String handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No se encontró una cuenta con este correo electrónico';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este correo electrónico';
      case 'weak-password':
        return 'La contraseña es muy débil';
      case 'invalid-email':
        return 'Correo electrónico inválido';
      case 'too-many-requests':
        return 'Demasiados intentos fallidos. Intenta más tarde';
      case 'network-request-failed':
        return 'Error de conexión. Verifica tu internet';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada';
      case 'operation-not-allowed':
        return 'Operación no permitida';
      default:
        return 'Error de autenticación: ${e.message ?? e.code}';
    }
  }

  // Verificar si el usuario está autenticado
  bool get isSignedIn => _auth.currentUser != null;

  // Obtener el UID del usuario actual
  String? get currentUserUid => _auth.currentUser?.uid;

  // Enviar email de verificación
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // Enviar email para restablecer contraseña
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(code: e.code, message: e.message);
    }
  }

  // Recargar datos del usuario actual
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  // Actualizar email del usuario
  Future<void> updateEmail(String email) async {
    try {
      await _auth.currentUser?.updateEmail(email);
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(code: e.code, message: e.message);
    }
  }

  // Actualizar contraseña del usuario
  Future<void> updatePassword(String password) async {
    try {
      await _auth.currentUser?.updatePassword(password);
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(code: e.code, message: e.message);
    }
  }

  // Re-autenticar usuario (necesario para operaciones sensibles)
  Future<void> reauthenticateWithEmail(String email, String password) async {
    try {
      final credential = EmailAuthProvider.credential(email: email, password: password);
      await _auth.currentUser?.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(code: e.code, message: e.message);
    }
  }

  // Eliminar cuenta del usuario
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(code: e.code, message: e.message);
    }
  }

  Future<bool> isGoogleSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }
}