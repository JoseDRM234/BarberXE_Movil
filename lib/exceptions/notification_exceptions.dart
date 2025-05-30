
// Excepción base para todas las excepciones de notificaciones
abstract class NotificationException implements Exception {
  final String message;
  final DateTime timestamp;
  final String? context;

  NotificationException(
    this.message, {
    this.context,
  }) : timestamp = DateTime.now();

  @override
  String toString() => 'NotificationException: $message';
}

class GenericNotificationException extends NotificationException {
  GenericNotificationException(String message, {String? context})
      : super(message, context: context);
}

// Se lanza cuando no se encuentra una notificación específica
class NotificationNotFoundException extends NotificationException {
  final String notificationId;

  NotificationNotFoundException(this.notificationId)
      : super(
          'Notificación con ID $notificationId no encontrada',
          context: 'notification_id: $notificationId',
        );

  @override
  String toString() => 'NotificationNotFoundException: Notificación $notificationId no encontrada';
}

//Se lanza cuando se niegan los permisos de notificación
class NotificationPermissionDeniedException extends NotificationException {
  final String permissionType;

  NotificationPermissionDeniedException(this.permissionType)
      : super(
          'Permisos de notificación denegados: $permissionType',
          context: 'permission_type: $permissionType',
        );

  @override
  String toString() => 'NotificationPermissionDeniedException: Permisos $permissionType denegados';
}

// Se lanza cuando falla el envío de una notificación push
class NotificationSendFailedException extends NotificationException {
  final String errorCode;
  final String? fcmError;

  NotificationSendFailedException(
    this.errorCode, {
    this.fcmError,
    String? userId,
  }) : super(
          'Error al enviar notificación push: $errorCode',
          context: 'error_code: $errorCode, fcm_error: ${fcmError ?? 'N/A'}, user_id: ${userId ?? 'N/A'}',
        );

  @override
  String toString() => 'NotificationSendFailedException: Error $errorCode - ${fcmError ?? 'Error desconocido'}';
}

// Se lanza cuando hay errores de red o conectividad
class NotificationNetworkException extends NotificationException {
  final int? statusCode;
  final String? originalError;

  NotificationNetworkException({
    this.statusCode,
    this.originalError,
  }) : super(
          'Error de conexión al procesar notificaciones',
          context: 'status_code: ${statusCode ?? 'N/A'}, original_error: ${originalError ?? 'N/A'}',
        );

  @override
  String toString() => 'NotificationNetworkException: Error de red (${statusCode ?? 'Sin código'})';
}

// Se lanza cuando hay errores de validación de datos
class NotificationValidationException extends NotificationException {
  final String field;
  final dynamic value;

  NotificationValidationException(this.field, this.value)
      : super(
          'Error de validación en campo $field',
          context: 'field: $field, value: $value',
        );

  @override
  String toString() => 'NotificationValidationException: Campo $field inválido (valor: $value)';
}

// Se lanza cuando se alcanza el límite de notificaciones
class NotificationLimitExceededException extends NotificationException {
  final int currentCount;
  final int maxLimit;

  NotificationLimitExceededException(this.currentCount, this.maxLimit)
      : super(
          'Límite de notificaciones excedido: $currentCount/$maxLimit',
          context: 'current: $currentCount, limit: $maxLimit',
        );

  @override
  String toString() => 'NotificationLimitExceededException: Límite excedido ($currentCount/$maxLimit)';
}

// Se lanza cuando hay errores al programar notificaciones futuras
class NotificationScheduleException extends NotificationException {
  final DateTime scheduledTime;
  final String reason;

  NotificationScheduleException(this.scheduledTime, this.reason)
      : super(
          'Error al programar notificación para $scheduledTime: $reason',
          context: 'scheduled_time: $scheduledTime, reason: $reason',
        );

  @override
  String toString() => 'NotificationScheduleException: No se pudo programar para $scheduledTime ($reason)';
}

// Se lanza cuando hay errores de configuración del sistema
class NotificationConfigurationException extends NotificationException {
  final String configKey;

  NotificationConfigurationException(this.configKey)
      : super(
          'Error de configuración: $configKey',
          context: 'config_key: $configKey',
        );

  @override
  String toString() => 'NotificationConfigurationException: Configuración $configKey inválida';
}