import 'dart:async';
import 'dart:developer' as developer show log;
import 'package:barber_xe/models/NotificationFilter_model.dart';
import 'package:barber_xe/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:barber_xe/models/notification_model.dart';
import 'package:barber_xe/services/notification_service.dart';
import 'package:barber_xe/services/notification_generator_service.dart';
import 'package:barber_xe/services/push_notification_service.dart';
import 'package:barber_xe/exceptions/notification_exceptions.dart';
import 'package:barber_xe/exceptions/notification_error_handler.dart';

class NotificationController with ChangeNotifier {
  final NotificationService _notificationService;
  final NotificationGeneratorService _generatorService;
  final PushNotificationService _pushService;
  final NotificationErrorHandler _errorHandler;
  
  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => List.unmodifiable(_notifications);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  bool _hasError = false;
  bool get hasError => _hasError;

  NotificationFilter _currentFilter = const NotificationFilter();
  NotificationFilter get currentFilter => _currentFilter;

  StreamSubscription<List<NotificationModel>>? _notificationsSubscription;
  StreamSubscription<NotificationModel>? _pushNotificationsSubscription;
  StreamSubscription<NotificationModel>? _fcmTokenSubscription;

  NotificationController({
    NotificationService? notificationService,
    NotificationGeneratorService? generatorService,
    PushNotificationService? pushService,
    NotificationErrorHandler? errorHandler, required AuthService authService,
  }) : 
    _notificationService = notificationService ?? NotificationService(),
    _generatorService = generatorService ?? NotificationGeneratorService(),
    _pushService = pushService ?? PushNotificationService(),
    _errorHandler = errorHandler ?? NotificationErrorHandler();

  Future<void> initialize(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // 1. Inicializar servicios
      await _pushService.initialize();
      
      // 2. Configurar listeners
      _setupNotificationsStream(userId);
      _setupPushNotificationsListener();
      _setupFcmTokenListener();
      
      // 3. Cargar datos iniciales
      await Future.wait([
        _loadNotifications(userId),
        _loadUnreadCount(userId),
      ]);

      _isLoading = false;
      notifyListeners();
    } catch (e, stack) {
      _handleError(e, stack, 'initialize');
    }
  }

  void _setupNotificationsStream(String userId) {
    _notificationsSubscription?.cancel();
    _notificationsSubscription = _notificationService
        .getUserNotificationsStream(userId, filter: _currentFilter)
        .listen(
          (notifications) {
            _notifications = notifications;
            _updateUnreadCount();
            notifyListeners();
          },
          onError: (e) => _handleError(e, StackTrace.current, 'notifications_stream'),
        );
  }

  void _setupPushNotificationsListener() {
    _pushNotificationsSubscription?.cancel();
    _pushNotificationsSubscription = _pushService.notificationStream.listen(
      (notification) {
        _notifications.insert(0, notification);
        _unreadCount++;
        notifyListeners();
      },
      onError: (e) => _handleError(e, StackTrace.current, 'push_notifications_stream'),
    );
  }

  void _setupFcmTokenListener() {
    _fcmTokenSubscription?.cancel();
    _fcmTokenSubscription = _pushService.notificationStream
        .where((notification) => notification.userId.isNotEmpty)
        .listen((notification) {
          // Implementación real para actualizar el token
          _updateFcmTokenInBackend(notification.userId, _pushService.getFcmToken());
        });
  }

  Future<void> _updateFcmTokenInBackend(String userId, Future<String?> fcmTokenFuture) async {
    try {
      final fcmToken = await fcmTokenFuture;
      if (fcmToken != null) {
        // Aquí iría tu lógica para actualizar el token en el backend
        developer.log('Actualizando token FCM para usuario $userId: $fcmToken');
        // Ejemplo:
        // await _apiService.updateUserFcmToken(userId, fcmToken);
      }
    } catch (e, stack) {
      developer.log('Error al actualizar token FCM', error: e, stackTrace: stack);
    }
  }

  Future<void> _loadNotifications(String userId) async {
    try {
      _hasError = false;
      _errorMessage = '';

      _notifications = await _notificationService.getUserNotifications(
        userId,
        filter: _currentFilter,
      );
      _updateUnreadCount();
      notifyListeners();
    } catch (e, stack) {
      _handleError(e, stack, 'load_notifications');
    }
  }

  Future<void> refresh(String userId) async {
    await _loadNotifications(userId);
  }


  Future<void> _loadUnreadCount(String userId) async {
    try {
      _hasError = false;
      _errorMessage = '';
      _unreadCount = await _notificationService.getUnreadCount(userId);
      notifyListeners();
    } catch (e, stack) {
      _handleError(e, stack, 'load_unread_count');
    }
  }

  void _updateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }

  Future<void> applyFilter(String userId, NotificationFilter filter) async {
    try {
      _currentFilter = filter;
      await _loadNotifications(userId);
    } catch (e, stack) {
      _handleError(e, stack, 'apply_filter');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      _updateNotificationStatus(notificationId, true);
    } catch (e, stack) {
      _handleError(e, stack, 'mark_as_read');
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      final unreadIds = _notifications
          .where((n) => !n.isRead)
          .map((n) => n.id!)
          .toList();
      
      if (unreadIds.isNotEmpty) {
        await _notificationService.markMultipleAsRead(unreadIds);
        _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
        _unreadCount = 0;
        notifyListeners();
      }
    } catch (e, stack) {
      _handleError(e, stack, 'mark_all_as_read');
    }
  }

  void _updateNotificationStatus(String notificationId, bool isRead) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: isRead);
      _unreadCount = _notifications.where((n) => !n.isRead).length;
      notifyListeners();
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      _notifications.removeWhere((n) => n.id == notificationId);
      _updateUnreadCount();
      notifyListeners();
    } catch (e, stack) {
      _handleError(e, stack, 'delete_notification');
    }
  }

  Future<void> deleteAllNotifications(String userId) async {
    try {
      final ids = _notifications.map((n) => n.id!).toList();
      if (ids.isNotEmpty) {
        await _notificationService.deleteMultipleNotifications(ids);
        _notifications = [];
        _unreadCount = 0;
        notifyListeners();
      }
    } catch (e, stack) {
      _handleError(e, stack, 'delete_all_notifications');
    }
  }

  Future<void> cleanupOldNotifications(String userId, {int daysOld = 30}) async {
    try {
      await _notificationService.cleanupOldNotifications(userId, daysOld: daysOld);
      await _loadNotifications(userId);
    } catch (e, stack) {
      _handleError(e, stack, 'cleanup_old_notifications');
    }
  }

  Future<void> generateTestNotification(String userId, NotificationFilter newFilter) async {
    try {
      await _generatorService.generatePromotionNotification(
        userId: userId,
        title: 'Notificación de prueba',
        description: 'Esta es una notificación de prueba generada desde la app',
        promotionData: {'test': true},
      );
    } catch (e, stack) {
      _handleError(e, stack, 'generate_test_notification');
    }
  }

  Future<void> scheduleAppointmentReminders({
    required String userId,
    required String appointmentId,
    required DateTime appointmentDateTime,
    required String barberName,
    required String serviceName,
  }) async {
    try {
      await _generatorService.scheduleAppointmentReminders(
        userId: userId,
        appointmentId: appointmentId,
        appointmentDateTime: appointmentDateTime,
        barberName: barberName,
        serviceName: serviceName,
      );
    } catch (e, stack) {
      _handleError(e, stack, 'schedule_appointment_reminders');
    }
  }

  Future<void> cancelAppointmentReminders(String appointmentId) async {
    try {
      await _generatorService.cancelAppointmentReminders(appointmentId);
    } catch (e, stack) {
      _handleError(e, stack, 'cancel_appointment_reminders');
    }
  }

  void _handleError(dynamic error, StackTrace stack, String operation) {
    _errorMessage = error is NotificationException 
        ? error.message 
        : 'Error al $operation: ${error.toString()}';
    
    _isLoading = false;
    _hasError = true;
    notifyListeners();
    
    // Manejar el error con el manejador centralizado
    _errorHandler.handleNotificationError(
      error is NotificationException ? error : GenericNotificationException(error.toString()),
      null,
      operationId: operation,
    );
    
    developer.log(_errorMessage, error: error, stackTrace: stack, name: 'NotificationController');
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    _pushNotificationsSubscription?.cancel();
    _fcmTokenSubscription?.cancel();
    _pushService.dispose();
    super.dispose();
  }
}