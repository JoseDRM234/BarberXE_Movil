import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _users => _firestore.collection('users');

  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _users.doc(uid).get();
      if (!doc.exists) return null;
      
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return null;

      // Manejo seguro de campos requeridos
      return UserModel(
        uid: doc.id,
        email: data['email'] ?? '',
        nombre: data['nombre'],
        apellido: data['apellido'],
        telefono: data['telefono'],
        photoUrl: data['photoUrl'],
        role: data['role'] ?? 'cliente', // Valor por defecto
        createdAt: data['createdAt'] != null 
            ? (data['createdAt'] as Timestamp).toDate() 
            : DateTime.now(), // Valor por defecto
        updatedAt: data['updatedAt'] != null 
            ? (data['updatedAt'] as Timestamp).toDate() 
            : null,
        activo: data['activo'] ?? true, // Valor por defecto
        clienteId: data['clienteId'],
      );
    } catch (e) {
      debugPrint('Error getting user: $e');
      return null;
    }
  }

  Future<void> createUser(UserModel user) async {
  try {
    await _users.doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  } catch (e) {
    print('Error creating user: $e');
    throw Exception('No se pudo crear el usuario en Firestore');
  }
}

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
  try {
    // Elimina campos nulos para no sobrescribir datos existentes con null
    data.removeWhere((key, value) => value == null);
    await _users.doc(uid).update(data);
  } catch (e) {
    print('Error updating user: $e');
    throw Exception('No se pudo actualizar el usuario');
  }
}

  Future<bool> isEmailRegistered(String email) async {
    QuerySnapshot query = await _users.where('email', isEqualTo: email).get();
    return query.docs.isNotEmpty;
  }

  Stream<List<UserModel>> getClients() {
    return _users
        .where('role', isEqualTo: 'cliente')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .toList());
  }

  Future<void> saveUser(User user) async {
    // Implement user saving logic (e.g., to Firestore)
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }
}