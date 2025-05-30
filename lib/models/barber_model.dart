import 'package:cloud_firestore/cloud_firestore.dart';

class Barber {
  final String id;
  final String name;
  final String? photoUrl;
  final String status;
  final List<int> workingDays;
  final Map<String, String> workingHours;
  final double rating;
  final List<double> ratings;
  final Map<String, double> userRatings;
  final int totalRatings;
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
    this.ratings = const [],
    this.userRatings = const {},
    this.totalRatings = 0,
    this.shortDescription = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Barber.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Obtener userRatings de Firestore
    final userRatingsData = data['userRatings'] as Map<String, dynamic>? ?? {};
    final userRatingsMap = Map<String, double>.from(
      userRatingsData.map((key, value) => MapEntry(key, (value as num).toDouble()))
    );
    
    // Crear lista de ratings desde userRatings
    final ratingsList = userRatingsMap.values.toList();
    
    // Calcular promedio
    double averageRating = 0.0;
    if (ratingsList.isNotEmpty) {
      averageRating = ratingsList.reduce((a, b) => a + b) / ratingsList.length;
    }

    return Barber(
      id: doc.id,
      name: data['name'] as String? ?? 'Sin nombre',
      photoUrl: data['photoUrl'],
      status: data['status'] as String? ?? 'active',
      workingDays: List<int>.from(data['workingDays'] ?? []),
      workingHours: Map<String, String>.from(data['workingHours'] ?? 
          {'start': '09:00', 'end': '18:00'}),
      rating: averageRating,
      ratings: ratingsList,
      userRatings: userRatingsMap,
      totalRatings: ratingsList.length,
      shortDescription: data['shortDescription'] ?? '',
      createdAt: _parseTimestamp(data['createdAt']),
    );
  }

  get averageRating => null;

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is DateTime) return timestamp;
    return DateTime.now();
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'photoUrl': photoUrl,
      'status': status,
      'workingDays': workingDays,
      'workingHours': workingHours,
      'rating': rating,
      'ratings': ratings,
      'userRatings': userRatings,
      'totalRatings': totalRatings,
      'shortDescription': shortDescription,
      'createdAt': createdAt,
    };
  }

  // Método para agregar/actualizar calificación de un usuario específico
  Barber addOrUpdateUserRating(String userId, double newRating) {
    final newUserRatings = Map<String, double>.from(userRatings);
    newUserRatings[userId] = newRating;

    final allRatings = newUserRatings.values.toList();
    final updatedAverage = allRatings.isEmpty
        ? 0.0
        : allRatings.reduce((a, b) => a + b) / allRatings.length;

    return copyWith(
      userRatings: newUserRatings,
      rating: double.parse(updatedAverage.toStringAsFixed(1)),
      totalRatings: newUserRatings.length,
    );
  }

  // Verificar si un usuario ya ha calificado
  bool hasUserRated(String userId) => userRatings.containsKey(userId);

  // Obtener la calificación de un usuario específico
  double? getUserRating(String userId) => userRatings[userId];

  // Método para alternar estado
  Barber toggleStatus() {
    return copyWith(
      status: status == 'active' ? 'inactive' : 'active',
    );
  }

  Barber copyWith({
    String? name,
    String? photoUrl,
    String? status,
    List<int>? workingDays,
    Map<String, String>? workingHours,
    double? rating,
    List<double>? ratings,
    Map<String, double>? userRatings,
    int? totalRatings,
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
      ratings: ratings ?? this.ratings,
      userRatings: userRatings ?? this.userRatings,
      totalRatings: totalRatings ?? this.totalRatings,
      shortDescription: shortDescription ?? this.shortDescription,
      createdAt: createdAt,
    );
  }
}
