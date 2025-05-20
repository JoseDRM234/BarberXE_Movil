// models/barber_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Barber {
  final String id;
  final String name;
  final String? photoUrl;
  final String status;
  final List<int> workingDays; // [0,1,2,3,4,5,6] donde 0=Lunes, 6=Domingo
  final Map<String, String> workingHours; // {'start': '09:00', 'end': '18:00'}
  final double rating;
  final String shortDescription;
  final DateTime createdAt;

  Barber({
    required this.id,
    required this.name,
    this.photoUrl,
    required this.status,
    this.workingDays = const [],
    this.workingHours = const {'start': '09:00', 'end': '18:00'},
    this.rating = 0.0,
    this.shortDescription = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Barber.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Barber(
      id: doc.id,
      name: data['name'] as String? ?? 'Sin nombre', // Valor por defecto
      photoUrl: data['photoUrl'],
      status: data['status'] as String? ?? 'active', // Valor por defecto
      workingDays: List<int>.from(data['workingDays'] ?? []),
      workingHours: Map<String, String>.from(data['workingHours'] ?? 
          {'start': '09:00', 'end': '18:00'}),
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      shortDescription: data['shortDescription'] ?? '',
      createdAt: _parseTimestamp(data['createdAt']), // Función de parseo segura
    );
  }

   static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is DateTime) return timestamp;
    return DateTime.now(); // Valor por defecto si no se puede parsear
  }


  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'photoUrl': photoUrl,
      'status': status,
      'workingDays': workingDays,
      'workingHours': workingHours,
      'rating': rating,
      'shortDescription': shortDescription,
      'createdAt': createdAt,
    };
  }

  Barber copyWith({
    String? name,
    String? photoUrl,
    String? status,
    List<int>? workingDays,
    Map<String, String>? workingHours,
    double? rating,
    String? shortDescription,
  }) {
    return Barber(
      id: id,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      workingDays: workingDays ?? this.workingDays,
      workingHours: workingHours ?? this.workingHours,
      rating: rating ?? this.rating,
      shortDescription: shortDescription ?? this.shortDescription,
      createdAt: createdAt,
    );
  }
}