import 'package:barber_xe/models/NotificationType_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationFilter {
  final NotificationType? type;
  final bool? isRead;
  final DateTime? fromDate;
  final DateTime? toDate;

  const NotificationFilter({
    this.type,
    this.isRead,
    this.fromDate,
    this.toDate,
  });

  NotificationFilter copyWith({
    NotificationType? type,
    bool? isRead,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return NotificationFilter(
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
    );
  }

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{};
    
    if (type != null) {
      params['type'] = type!.name;
    }
    if (isRead != null) {
      params['isRead'] = isRead;
    }
    if (fromDate != null) {
      params['fromDate'] = Timestamp.fromDate(fromDate!);
    }
    if (toDate != null) {
      params['toDate'] = Timestamp.fromDate(toDate!);
    }
    
    return params;
  }
}