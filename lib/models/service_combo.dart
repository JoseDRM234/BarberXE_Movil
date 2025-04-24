import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceCombo {
  final String id;
  final String name;
  final String description;
  final double totalPrice;
  final double discount;
  final int totalDuration;
  final List<String> serviceIds;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;

  ServiceCombo({
    required this.id,
    required this.name,
    required this.description,
    required this.totalPrice,
    required this.discount,
    required this.totalDuration,
    required this.serviceIds,
    this.imageUrl,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ServiceCombo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceCombo(
      id: doc.id,
      name: data['name'],
      description: data['description'],
      totalPrice: (data['totalPrice'] as num).toDouble(),
      discount: (data['discount'] as num).toDouble(),
      totalDuration: data['totalDuration'],
      serviceIds: List<String>.from(data['serviceIds']),
      imageUrl: data['imageUrl'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'totalPrice': totalPrice,
      'discount': discount,
      'totalDuration': totalDuration,
      'serviceIds': serviceIds,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }

  ServiceCombo copyWith({
    String? name,
    String? description,
    double? totalPrice,
    double? discount,
    int? totalDuration,
    List<String>? serviceIds,
    String? imageUrl,
    bool? isActive,
  }) {
    return ServiceCombo(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      totalPrice: totalPrice ?? this.totalPrice,
      discount: discount ?? this.discount,
      totalDuration: totalDuration ?? this.totalDuration,
      serviceIds: serviceIds ?? this.serviceIds,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}
