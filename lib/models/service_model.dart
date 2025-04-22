import 'package:cloud_firestore/cloud_firestore.dart';

class Service {
  final String id;
  final String name;
  final String description;
  final double price;
  final bool isCombo;
  final List<String>? includedServices; // Para combos
  final int duration; // Duración en minutos
  final String category; // Ej: 'hair', 'beard', 'combo'
  final String? imageUrl; // URL de la imagen
  final bool isActive; // Si está disponible
  final DateTime createdAt;
  final double? discount; // Descuento si aplica (para combos)
  final List<String> tags; // Para filtrado y búsqueda

  Service({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.isCombo = false,
    this.includedServices,
    this.duration = 30, // Valor por defecto 30 mins
    this.category = 'hair', // Categoría por defecto
    this.imageUrl,
    this.isActive = true, // Por defecto activo
    DateTime? createdAt,
    this.discount,
    this.tags = const [], // Lista vacía por defecto
  }) : createdAt = createdAt ?? DateTime.now();

  // Método para crear un objeto Service desde Firestore
  factory Service.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot,
      SnapshotOptions? options,
      ) {
    final data = snapshot.data()!;
    return Service(
      id: snapshot.id,
      name: data['name'] ?? 'Sin nombre',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      isCombo: data['isCombo'] ?? false,
      includedServices: data['includedServices'] != null
          ? List<String>.from(data['includedServices'])
          : null,
      duration: data['duration'] ?? 30,
      category: data['category'] ?? 'hair',
      imageUrl: data['imageUrl'],
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      discount: data['discount']?.toDouble(),
      tags: data['tags'] != null ? List<String>.from(data['tags']) : [],
    );
  }

  // Método para convertir a Map (para Firestore)
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'isCombo': isCombo,
      if (includedServices != null) 'includedServices': includedServices,
      'duration': duration,
      'category': category,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      if (discount != null) 'discount': discount,
      'tags': tags,
    };
  }

  // Copia el objeto permitiendo modificar algunos atributos
  Service copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    bool? isCombo,
    List<String>? includedServices,
    int? duration,
    String? category,
    String? imageUrl,
    bool? isActive,
    DateTime? createdAt,
    double? discount,
    List<String>? tags,
  }) {
    return Service(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      isCombo: isCombo ?? this.isCombo,
      includedServices: includedServices ?? this.includedServices,
      duration: duration ?? this.duration,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      discount: discount ?? this.discount,
      tags: tags ?? this.tags,
    );
  }
}