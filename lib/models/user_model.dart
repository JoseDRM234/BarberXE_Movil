import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String? nombre;
  final String? apellido;
  final String? telefono;
  final String? photoUrl;
  final String role;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool activo;
  final String? clienteId;

  UserModel({
    required this.uid,
    required this.email,
    this.nombre,
    this.apellido,
    this.telefono,
    this.photoUrl,
    required this.role,
    required this.createdAt,
    this.updatedAt,
    this.activo = true,
    this.clienteId,
  });

  String get fullName => '$nombre $apellido'.trim();
  bool get isAdmin => role == 'admin';

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      nombre: data['nombre'],
      apellido: data['apellido'],
      telefono: data['telefono'],
      photoUrl: data['photoUrl'],
      role: data['role'] ?? 'cliente',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt']?.toDate(), // Manejo seguro con ?.
      activo: data['activo'] ?? true,
      clienteId: data['clienteId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'nombre': nombre,
      'apellido': apellido,
      'telefono': telefono,
      'photoUrl': photoUrl,
      'role': role,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'activo': activo,
      'clienteId': clienteId,
    };
  }
}