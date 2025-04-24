import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw handleAuthError(e);
    }
  }

  Future<User?> registerWithEmailAndPassword({
  required String email,
  required String password,
}) async {
  try {
    final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    return userCredential.user;
  } on FirebaseAuthException catch (e) {
    print('Error Code: ${e.code}');
    print('Error Message: ${e.message}');
    throw handleAuthError(e);
  }
}

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      debugPrint('Sesión cerrada correctamente en Firebase');
    } catch (e) {
      debugPrint('Error al cerrar sesión: $e');
      throw Exception('No se pudo cerrar la sesión');
    }
  }
  Future<void> updatePassword(String newPassword) async {
    if (_auth.currentUser != null) {
      await _auth.currentUser!.updatePassword(newPassword.trim());
    }
  }

  String handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'El correo ya está registrado. ¿Quieres iniciar sesión?';
      case 'invalid-email':
        return 'Por favor ingresa un correo electrónico válido';
      case 'operation-not-allowed':
        return 'La autenticación por correo no está habilitada. Contacta al soporte.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres';
      default:
        return 'Error durante el registro: ${e.message}';
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    // Implement Google Sign-In logic
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;
    
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );
    
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<User?> get currentUserFuture async {
    try {
      return _auth.currentUser;
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }
}
