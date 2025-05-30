import 'package:barber_xe/models/NotificationType_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String? id;
  final String userId;
  final NotificationType type;
  final String title;
  final String description;
  final DateTime createdAt;
  bool isRead;
  final Map<String, dynamic> data;
  final String? actionUrl;

  NotificationModel({
    this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    DateTime? createdAt,
    this.isRead = false,
    this.data = const {},
    this.actionUrl,
  }) : createdAt = createdAt ?? DateTime.now();

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] as String,
      type: NotificationTypeExtension.fromString(data['type'] as String),
      title: data['title'] as String,
      description: data['description'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isRead: data['isRead'] as bool? ?? false,
      data: Map<String, dynamic>.from(data['data'] as Map? ?? {}),
      actionUrl: data['actionUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.name,
      'title': title,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'data': data,
      if (actionUrl != null) 'actionUrl': actionUrl,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? description,
    DateTime? createdAt,
    bool? isRead,
    Map<String, dynamic>? data,
    String? actionUrl,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }
}
