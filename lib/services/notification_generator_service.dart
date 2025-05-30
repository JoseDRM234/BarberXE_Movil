import 'dart:async';
import 'dart:developer' as developer;
import 'package:barber_xe/models/NotificationType_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';
import '../exceptions/notification_exceptions.dart';
import 'notification_service.dart';

class NotificationGeneratorService {
  static final NotificationGeneratorService _instance = NotificationGeneratorService._internal();
  factory NotificationGeneratorService() => _instance;
  NotificationGeneratorService._internal();

  final NotificationService _notificationService = NotificationService();
  final Map<String, Timer> _scheduledTasks = {};
  static const Duration reminder24Hours = Duration(hours: 24);
  static const Duration reminder1Hour = Duration(hours: 1);
  static const Duration minimumReminderTime = Duration(hours: 2);

  // ========== GENERACIÓN DE RECORDATORIOS ==========

  Future<List<String>> scheduleAppointmentReminders({
    required String userId,
    required String appointmentId,
    required DateTime appointmentDateTime,
    required String barberName,
    required String serviceName,
  }) async {
    try {
      _validateAppointmentTime(appointmentDateTime);
      
      final scheduledIds = <String>[];
      final now = DateTime.now();

      // Recordatorio 24 horas antes
      final reminder24Time = appointmentDateTime.subtract(reminder24Hours);
      if (reminder24Time.isAfter(now)) {
        final notification = _createReminderNotification(
          userId: userId,
          type: NotificationType.REMINDER_24H,
          title: 'Recordatorio: Cita mañana',
          description: 'Tienes una cita con $barberName mañana a las ${_formatTime(appointmentDateTime)} para $serviceName',
          appointmentId: appointmentId,
          appointmentDateTime: appointmentDateTime,
          barberName: barberName,
          serviceName: serviceName,
        );

        await _scheduleNotification(
          notification: notification,
          scheduleTime: reminder24Time,
          taskKey: '${appointmentId}_24h'
        );
        scheduledIds.add('${appointmentId}_24h');
      }

      // Recordatorio 1 hora antes
      final reminder1Time = appointmentDateTime.subtract(reminder1Hour);
      if (reminder1Time.isAfter(now.add(minimumReminderTime))) {
        final notification = _createReminderNotification(
          userId: userId,
          type: NotificationType.REMINDER_1H,
          title: 'Recordatorio: Cita en 1 hora',
          description: 'Tu cita con $barberName es en 1 hora (${_formatTime(appointmentDateTime)}) para $serviceName',
          appointmentId: appointmentId,
          appointmentDateTime: appointmentDateTime,
          barberName: barberName,
          serviceName: serviceName,
        );

        await _scheduleNotification(
          notification: notification,
          scheduleTime: reminder1Time,
          taskKey: '${appointmentId}_1h'
        );
        scheduledIds.add('${appointmentId}_1h');
      }

      return scheduledIds;
      
    } on NotificationException {
      rethrow;
    } catch (e) {
      throw NotificationScheduleException(
        appointmentDateTime, 
        'Error al programar recordatorios: ${e.toString()}'
      );
    }
  }

  Future<void> cancelAppointmentReminders(String appointmentId) async {
    final taskKeys = ['${appointmentId}_24h', '${appointmentId}_1h'];
    for (final key in taskKeys) {
      _cancelScheduledTask(key);
    }
  }

  /// Genera notificación cuando un barbero favorito tiene disponibilidad
Future<NotificationModel> generateFavoriteBarberAvailableNotification({
  required String userId,
  required String barberId,
  required String barberName,
  required List<DateTime> availableSlots,
  String? customMessage,
}) async {
  try {
    // Validación de datos básicos
    if (userId.isEmpty) {
      throw NotificationValidationException('userId', 'No puede estar vacío');
    }
    if (barberId.isEmpty) {
      throw NotificationValidationException('barberId', 'No puede estar vacío');
    }
    if (availableSlots.isEmpty) {
      throw NotificationValidationException('availableSlots', 'Debe tener al menos un horario');
    }

    // Preparar descripción con los primeros 3 horarios
    final slotsDescription = availableSlots
        .take(3)
        .map((slot) => _formatTime(slot))
        .join(', ');

    final moreSlotsText = availableSlots.length > 3 
        ? ' y ${availableSlots.length - 3} horarios más' 
        : '';

    // Crear modelo de notificación
    final notification = NotificationModel(
      userId: userId,
      type: NotificationType.FAVORITE_BARBER_AVAILABLE,
      title: customMessage ?? '¡$barberName está disponible!',
      description: 'Horarios disponibles: $slotsDescription$moreSlotsText',
      data: {
        'barberId': barberId,
        'barberName': barberName,
        'availableSlots': availableSlots.map((s) => s.toIso8601String()).toList(),
        'totalSlots': availableSlots.length,
        'generatedAt': DateTime.now().toIso8601String(),
      },
    );

    // Registrar en Firestore
    final createdNotification = await _notificationService.createNotification(notification);

    developer.log(
      'Notificación de barbero disponible creada para usuario $userId',
      name: 'NotificationGeneratorService',
    );

    return createdNotification;

  } on NotificationException {
    rethrow;
  } on FirebaseException catch (e) {
    throw NotificationSendFailedException(
      'BARBER_AVAILABLE_ERROR',
      fcmError: e.message,
      userId: userId,
    );
  } catch (e) {
    throw NotificationSendFailedException(
      'UNKNOWN_ERROR',
      fcmError: e.toString(),
      userId: userId,
    );
  }
}

  // ========== NOTIFICACIONES DE CAMBIO ==========

  Future<NotificationModel> generateAppointmentChangeNotification({
    required String userId,
    required String appointmentId,
    required DateTime oldDateTime,
    required DateTime newDateTime,
    required String barberName,
    required String serviceName,
    required String changeReason,
  }) async {
    try {
      _validateAppointmentTime(newDateTime);
      
      final notification = NotificationModel(
        userId: userId,
        type: NotificationType.APPOINTMENT_CHANGE,
        title: 'Cambio en tu cita',
        description: _generateChangeDescription(oldDateTime, newDateTime, barberName, changeReason),
        data: {
          'appointmentId': appointmentId,
          'oldDateTime': oldDateTime.toIso8601String(),
          'newDateTime': newDateTime.toIso8601String(),
          'barberName': barberName,
          'serviceName': serviceName,
          'changeReason': changeReason,
        },
      );

      await cancelAppointmentReminders(appointmentId);
      await scheduleAppointmentReminders(
        userId: userId,
        appointmentId: appointmentId,
        appointmentDateTime: newDateTime,
        barberName: barberName,
        serviceName: serviceName,
      );

      return await _notificationService.createNotification(notification);
      
    } on NotificationException {
      rethrow;
    } catch (e) {
      throw NotificationSendFailedException(
        'APPOINTMENT_CHANGE_ERROR',
        fcmError: e.toString(),
      );
    }
  }

  // ========== NOTIFICACIONES DE PROMOCIONES ==========

  Future<NotificationModel> generatePromotionNotification({
    required String userId,
    required String title,
    required String description,
    required Map<String, dynamic> promotionData,
    String? actionUrl,
  }) async {
    try {
      final notification = NotificationModel(
        userId: userId,
        type: NotificationType.PROMOTION,
        title: title,
        description: description,
        actionUrl: actionUrl,
        data: promotionData,
      );

      return await _notificationService.createNotification(notification);
      
    } on NotificationException {
      rethrow;
    } catch (e) {
      throw NotificationSendFailedException(
        'PROMOTION_ERROR',
        fcmError: e.toString(),
      );
    }
  }

  Future<List<NotificationModel>> generateBulkPromotionNotifications({
    required List<String> userIds,
    required String title,
    required String description,
    required Map<String, dynamic> promotionData,
    String? actionUrl,
  }) async {
    final results = <NotificationModel>[];
    final errors = <String>[];

    for (final userId in userIds) {
      try {
        final notification = await generatePromotionNotification(
          userId: userId,
          title: title,
          description: description,
          promotionData: promotionData,
          actionUrl: actionUrl,
        );
        results.add(notification);
      } catch (e) {
        errors.add('Usuario $userId: ${e.toString()}');
      }
    }

    if (errors.isNotEmpty) {
      throw NotificationSendFailedException(
        'BULK_PROMOTION_ERROR',
        fcmError: 'Errores en ${errors.length}/${userIds.length} usuarios: ${errors.join('; ')}',
      );
    }

    return results;
  }

  // ========== MÉTODOS AUXILIARES PRIVADOS ==========

  NotificationModel _createReminderNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String description,
    required String appointmentId,
    required DateTime appointmentDateTime,
    required String barberName,
    required String serviceName,
  }) {
    return NotificationModel(
      userId: userId,
      type: type,
      title: title,
      description: description,
      data: {
        'appointmentId': appointmentId,
        'appointmentDateTime': appointmentDateTime.toIso8601String(),
        'barberName': barberName,
        'serviceName': serviceName,
        'reminderType': type.name,
      },
    );
  }

  Future<void> _scheduleNotification({
    required NotificationModel notification,
    required DateTime scheduleTime,
    required String taskKey,
  }) async {
    try {
      _validateScheduleTime(scheduleTime);
      
      _cancelScheduledTask(taskKey);

      final delay = scheduleTime.difference(DateTime.now());
      _scheduledTasks[taskKey] = Timer(delay, () async {
        try {
          await _notificationService.createNotification(notification);
          _scheduledTasks.remove(taskKey);
        } catch (e) {
          developer.log('Error al enviar notificación programada: $e');
          _scheduledTasks.remove(taskKey);
        }
      });
      
    } on NotificationException {
      rethrow;
    } catch (e) {
      throw NotificationScheduleException(
        scheduleTime,
        'Error al programar notificación: ${e.toString()}'
      );
    }
  }

  void _cancelScheduledTask(String taskKey) {
    _scheduledTasks[taskKey]?.cancel();
    _scheduledTasks.remove(taskKey);
  }

  void _validateAppointmentTime(DateTime dateTime) {
    if (dateTime.isBefore(DateTime.now())) {
      throw NotificationValidationException(
        'appointmentDateTime', 
        'La fecha/hora no puede estar en el pasado'
      );
    }
  }

  void _validateScheduleTime(DateTime scheduleTime) {
    if (scheduleTime.isBefore(DateTime.now())) {
      throw NotificationScheduleException(
        scheduleTime,
        'El tiempo programado es en el pasado'
      );
    }
  }

  String _generateChangeDescription(
    DateTime oldDateTime,
    DateTime newDateTime,
    String barberName,
    String changeReason,
  ) {
    final oldStr = '${_formatDate(oldDateTime)} a las ${_formatTime(oldDateTime)}';
    final newStr = '${_formatDate(newDateTime)} a las ${_formatTime(newDateTime)}';
    
    return 'Tu cita con $barberName ha cambiado de $oldStr a $newStr. '
            'Motivo: ${changeReason.isNotEmpty ? changeReason : "no especificado"}';
  }

  String _formatDate(DateTime date) {
    if (_isToday(date)) return 'Hoy';
    if (_isTomorrow(date)) return 'Mañana';
    return '${_getWeekdayName(date.weekday)} ${date.day}/${date.month}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
            date.month == now.month && 
            date.day == now.day;
  }

  bool _isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(Duration(days: 1));
    return date.year == tomorrow.year && 
            date.month == tomorrow.month && 
            date.day == tomorrow.day;
  }

  String _getWeekdayName(int weekday) {
    const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return days[weekday - 1];
  }

  // ========== GESTIÓN DE TAREAS PROGRAMADAS ==========

  Map<String, DateTime> getActiveScheduledTasks() {
    final activeTasks = <String, DateTime>{};
    final now = DateTime.now();
    
    _scheduledTasks.forEach((key, timer) {
      if (timer.isActive) {
        activeTasks[key] = now.add(Duration(milliseconds: timer.tick ?? 0));
      }
    });
    
    return activeTasks;
  }

  void cancelAllTasks() {
    _scheduledTasks.values.forEach((timer) => timer.cancel());
    _scheduledTasks.clear();
  }

  void dispose() {
    cancelAllTasks();
  }
}