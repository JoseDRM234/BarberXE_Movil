import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String? id;
  final String userId;
  final String userName;
  final String barberId;
  final String barberName;
  final List<String> serviceIds;
  final List<String> serviceNames;
  final List<String> comboIds; 
  final List<String> comboNames; 
  final DateTime dateTime;
  final int duration;
  final double totalPrice;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Appointment({
    this.id,
    required this.userId,
    required this.userName,
    required this.barberId,
    required this.barberName,
    required this.serviceIds,
    required this.serviceNames,
    required this.comboIds,
    required this.comboNames,
    required this.dateTime,
    required this.duration,
    required this.totalPrice,
    this.status = 'pending',
    required this.createdAt,
    this.updatedAt,
  });

    Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'barberId': barberId,
      'barberName': barberName,
      'serviceIds': serviceIds,
      'serviceNames': serviceNames,
      'comboIds': comboIds,
      'comboNames': comboNames,
      'dateTime': Timestamp.fromDate(dateTime),
      'duration': duration,
      'totalPrice': totalPrice,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory Appointment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Appointment(
      id: doc.id,
      userId: data['userId'],
      userName: data['userName'] ?? '', // Valor por defecto si no existe
      barberId: data['barberId'],
      barberName: data['barberName'],
      serviceIds: List<String>.from(data['serviceIds']),
      serviceNames: List<String>.from(data['serviceNames']),
      comboIds: List<String>.from(data['comboIds'] ?? []), // Manejo seguro
      comboNames: List<String>.from(data['comboNames'] ?? []), // Manejo seguro
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      duration: (data['duration'] as num).toInt(),
      totalPrice: (data['totalPrice'] as num).toDouble(),
      status: data['status'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt']?.toDate(),
    );
  }
}