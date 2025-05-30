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
  final List<String> favoriteBarbers; // Nuevo campo para favoritos

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
    List<String>? favoriteBarbers, // Nuevo parámetro opcional
  }) : favoriteBarbers = favoriteBarbers ?? [];

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
      updatedAt: data['updatedAt']?.toDate(),
      activo: data['activo'] ?? true,
      clienteId: data['clienteId'],
      favoriteBarbers: List<String>.from(data['favoriteBarbers'] ?? []), // Nuevo
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
      'favoriteBarbers': favoriteBarbers, // Nuevo
    };
  }

  // Métodos para manejar favoritos
  UserModel copyWith({
    String? uid,
    String? email,
    String? nombre,
    String? apellido,
    String? telefono,
    String? photoUrl,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? activo,
    String? clienteId,
    List<String>? favoriteBarbers,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      telefono: telefono ?? this.telefono,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      activo: activo ?? this.activo,
      clienteId: clienteId ?? this.clienteId,
      favoriteBarbers: favoriteBarbers ?? this.favoriteBarbers,
    );
  }
}