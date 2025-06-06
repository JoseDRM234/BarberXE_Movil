import 'package:cloud_firestore/cloud_firestore.dart';

class BarberService {
  final String id;
  final String name;
  final String description;
  final double price;
  final int duration;
  final String category;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;
  final List<String> tags;

  BarberService({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.duration,
    this.category = 'hair',
    this.imageUrl,
    this.isActive = true,
    DateTime? createdAt,
    this.tags = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  factory BarberService.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BarberService(
      id: doc.id,
      name: data['name'],
      description: data['description'],
      price: (data['price'] as num).toDouble(),
      duration: data['duration'],
      category: data['category'] ?? 'hair',
      imageUrl: data['imageUrl'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'duration': duration,
      'category': category,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': createdAt,
      'tags': tags,
    };
  }

  BarberService copyWith({
    String? name,
    String? description,
    double? price,
    int? duration,
    String? category,
    String? imageUrl,
    bool? isActive,
    List<String>? tags,
  }) {
    return BarberService(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      duration: duration ?? this.duration,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      tags: tags ?? this.tags,
    );
  }
}
