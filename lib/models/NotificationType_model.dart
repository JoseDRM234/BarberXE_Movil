

enum NotificationType {
  REMINDER_24H,
  REMINDER_1H,
  APPOINTMENT_CHANGE,
  PROMOTION,
  FAVORITE_BARBER_AVAILABLE
}

extension NotificationTypeExtension on NotificationType {
  String get name {
    switch (this) {
      case NotificationType.REMINDER_24H:
        return 'REMINDER_24H';
      case NotificationType.REMINDER_1H:
        return 'REMINDER_1H';
      case NotificationType.APPOINTMENT_CHANGE:
        return 'APPOINTMENT_CHANGE';
      case NotificationType.PROMOTION:
        return 'PROMOTION';
      case NotificationType.FAVORITE_BARBER_AVAILABLE:
        return 'FAVORITE_BARBER_AVAILABLE';
    }
  }

  static NotificationType fromString(String value) {
    switch (value) {
      case 'REMINDER_24H':
        return NotificationType.REMINDER_24H;
      case 'REMINDER_1H':
        return NotificationType.REMINDER_1H;
      case 'APPOINTMENT_CHANGE':
        return NotificationType.APPOINTMENT_CHANGE;
      case 'PROMOTION':
        return NotificationType.PROMOTION;
      case 'FAVORITE_BARBER_AVAILABLE':
        return NotificationType.FAVORITE_BARBER_AVAILABLE;
      default:
        throw ArgumentError('Invalid NotificationType: $value');
    }
  }
}