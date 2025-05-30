import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');

  // Método existente para obtener usuario
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error obteniendo usuario: $e');
      return null;
    }
  }

  // Método existente para crear usuario
  Future<void> createUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.uid).set(user.toMap());
    } catch (e) {
      debugPrint('Error creando usuario: $e');
      throw Exception('No se pudo crear el usuario en la base de datos');
    }
  }

  // Método mejorado para manejar usuarios de Google Sign-In
  Future<UserModel> saveUser(User firebaseUser) async {
    try {
      // Verificar si el usuario ya existe
      final existingUser = await getUser(firebaseUser.uid);
      
      if (existingUser != null) {
        // Si existe, actualizamos la información básica
        final updatedUser = existingUser.copyWith(
          email: firebaseUser.email ?? existingUser.email,
          photoUrl: firebaseUser.photoURL ?? existingUser.photoUrl,
          updatedAt: DateTime.now(),
        );
        
        await updateUser(updatedUser);
        debugPrint('Usuario existente actualizado: ${firebaseUser.email}');
        return updatedUser;
      } else {
        // Si no existe, creamos un nuevo usuario
        final newUser = _createUserFromFirebaseUser(firebaseUser);
        await createUser(newUser);
        debugPrint('Nuevo usuario creado: ${firebaseUser.email}');
        return newUser;
      }
    } catch (e) {
      debugPrint('Error guardando usuario: $e');
      throw Exception('No se pudo guardar la información del usuario');
    }
  }

  // Método privado para crear UserModel desde Firebase User
  UserModel _createUserFromFirebaseUser(User firebaseUser) {
    // Extraer nombre y apellido del displayName
    String? nombre;
    String? apellido;
    
    if (firebaseUser.displayName != null && firebaseUser.displayName!.isNotEmpty) {
      final nameParts = firebaseUser.displayName!.trim().split(' ');
      nombre = nameParts.first;
      if (nameParts.length > 1) {
        apellido = nameParts.sublist(1).join(' ');
      }
    }

    return UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      nombre: nombre,
      apellido: apellido,
      telefono: firebaseUser.phoneNumber,
      photoUrl: firebaseUser.photoURL,
      role: 'cliente', // Rol por defecto
      createdAt: DateTime.now(),
      updatedAt: null,
      activo: true,
      clienteId: null,
      favoriteBarbers: [], // Lista vacía por defecto
    );
  }

  // Método para actualizar usuario
  Future<void> updateUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.uid).update(user.toMap());
    } catch (e) {
      debugPrint('Error actualizando usuario: $e');
      throw Exception('No se pudo actualizar el usuario');
    }
  }

  // Método para actualizar información específica del usuario
  Future<void> updateUserInfo({
    required String uid,
    String? nombre,
    String? apellido,
    String? telefono,
    String? photoUrl,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': DateTime.now(),
      };

      if (nombre != null) updateData['nombre'] = nombre;
      if (apellido != null) updateData['apellido'] = apellido;
      if (telefono != null) updateData['telefono'] = telefono;
      if (photoUrl != null) updateData['photoUrl'] = photoUrl;

      await _usersCollection.doc(uid).update(updateData);
    } catch (e) {
      debugPrint('Error actualizando información del usuario: $e');
      throw Exception('No se pudo actualizar la información del usuario');
    }
  }

  // Método para verificar si un usuario existe
  Future<bool> userExists(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error verificando existencia del usuario: $e');
      return false;
    }
  }

  // Método para obtener usuarios por rol
  Future<List<UserModel>> getUsersByRole(String role) async {
    try {
      final querySnapshot = await _usersCollection
          .where('role', isEqualTo: role)
          .where('activo', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error obteniendo usuarios por rol: $e');
      return [];
    }
  }

  // Método para desactivar usuario (en lugar de eliminar)
  Future<void> deactivateUser(String uid) async {
    try {
      await _usersCollection.doc(uid).update({
        'activo': false,
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      debugPrint('Error desactivando usuario: $e');
      throw Exception('No se pudo desactivar el usuario');
    }
  }
}