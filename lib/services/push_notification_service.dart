import 'dart:async';
import 'dart:developer' as developer show log;
import 'package:barber_xe/models/NotificationType_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:barber_xe/models/notification_model.dart';
import 'package:barber_xe/exceptions/notification_exceptions.dart';
import 'package:barber_xe/services/notification_service.dart';
import 'package:flutter/material.dart';

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final NotificationService _notificationService = NotificationService();

  StreamController<NotificationModel> _notificationStreamController = StreamController<NotificationModel>.broadcast();
  Stream<NotificationModel> get notificationStream => _notificationStreamController.stream;

  bool _initialized = false;
  String? _currentFcmToken;
  bool _notificationsEnabled = false;

  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // 1. Configurar Firebase Messaging
      await _setupFirebaseMessaging();
      
      // 2. Verificar y solicitar permisos
      await _checkAndRequestPermissions();
      
      // 3. Obtener y manejar el token FCM
      await _setupFcmToken();
      
      // 4. Configurar manejo de mensajes iniciales
      await _handleInitialMessage();
      
      _initialized = true;
      
    } catch (e, stack) {
      developer.log('Error al inicializar PushNotificationService: $e', 
          name: 'PushNotification', error: e, stackTrace: stack);
      throw NotificationConfigurationException('push_notification_init');
    }
  }

  Future<void> _setupFirebaseMessaging() async {
    // Configurar manejadores para diferentes estados de la app
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageOpened);
    
    // Configurar el manejador de fondo
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Configuración adicional para iOS
    await _configureIOSSettings();
  }

  Future<void> _configureIOSSettings() async {
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _checkAndRequestPermissions() async {
    final NotificationSettings settings = await _firebaseMessaging.getNotificationSettings();
    _notificationsEnabled = settings.authorizationStatus == AuthorizationStatus.authorized;
    
    if (!_notificationsEnabled) {
      await _requestPermissions();
    }
  }

  Future<void> _requestPermissions() async {
    final NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    
    _notificationsEnabled = settings.authorizationStatus == AuthorizationStatus.authorized;
    
    if (!_notificationsEnabled) {
      throw NotificationPermissionDeniedException('push_notifications');
    }
  }

  Future<void> _setupFcmToken() async {
    _currentFcmToken = await _firebaseMessaging.getToken();
    
    if (_currentFcmToken == null) {
      throw NotificationConfigurationException('fcm_token');
    }
    
    developer.log('FCM Token obtenido: $_currentFcmToken', name: 'PushNotification');
    
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      developer.log('Nuevo FCM Token: $newToken', name: 'PushNotification');
      _currentFcmToken = newToken;
      // TODO: Actualizar el token en tu backend
    });
  }

  Future<void> _handleInitialMessage() async {
    final RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      await _handleTerminatedMessage(initialMessage);
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      developer.log('Mensaje recibido en primer plano', name: 'PushNotification');
      
      final notification = _parseRemoteMessage(message);
      
      // Enviar notificación al stream
      _notificationStreamController.add(notification);
      
      // Guardar en Firestore
      await _notificationService.createNotification(notification);
      
    } catch (e, stack) {
      developer.log('Error al manejar mensaje en primer plano: $e', 
          name: 'PushNotification', error: e, stackTrace: stack);
      throw NotificationSendFailedException('FOREGROUND_HANDLER', fcmError: e.toString());
    }
  }

  Future<void> _handleBackgroundMessageOpened(RemoteMessage message) async {
    try {
      developer.log('Mensaje recibido con app en segundo plano', name: 'PushNotification');
      
      final notification = _parseRemoteMessage(message);
      _notificationStreamController.add(notification);
      _handleNotificationTap(notification.data['actionUrl']);
      
    } catch (e, stack) {
      developer.log('Error al manejar mensaje en segundo plano: $e', 
          name: 'PushNotification', error: e, stackTrace: stack);
      throw NotificationSendFailedException('BACKGROUND_OPEN_HANDLER', fcmError: e.toString());
    }
  }

  Future<void> _handleTerminatedMessage(RemoteMessage message) async {
    try {
      developer.log('Mensaje recibido con app terminada', name: 'PushNotification');
      
      final notification = _parseRemoteMessage(message);
      _handleNotificationTap(notification.data['actionUrl']);
      
    } catch (e, stack) {
      developer.log('Error al manejar mensaje con app terminada: $e', 
          name: 'PushNotification', error: e, stackTrace: stack);
      throw NotificationSendFailedException('TERMINATED_HANDLER', fcmError: e.toString());
    }
  }

  void _handleNotificationTap(String? actionUrl) {
    if (actionUrl != null) {
      developer.log('Notificación tocada con actionUrl: $actionUrl', name: 'PushNotification');
      // TODO: Implementar lógica de navegación basada en actionUrl
    }
  }

  NotificationModel _parseRemoteMessage(RemoteMessage message) {
    try {
      final data = message.data;
      final notification = message.notification;
      
      developer.log('Parseando mensaje remoto: ${message.messageId}', name: 'PushNotification');
      
      return NotificationModel(
        userId: data['userId'] ?? '',
        type: NotificationTypeExtension.fromString(data['type'] ?? 'PROMOTION'),
        title: notification?.title ?? data['title'] ?? 'Nueva notificación',
        description: notification?.body ?? data['description'] ?? '',
        data: data,
        actionUrl: data['actionUrl'],
        createdAt: DateTime.now(),
      );
    } catch (e, stack) {
      developer.log('Error al parsear mensaje remoto: $e', 
          name: 'PushNotification', error: e, stackTrace: stack);
      throw NotificationValidationException('remote_message', 'Formato de mensaje inválido');
    }
  }

  Future<String?> getFcmToken() async {
    if (!_initialized) await initialize();
    return _currentFcmToken;
  }

  Future<bool> areNotificationsEnabled() async {
    if (!_initialized) await initialize();
    return _notificationsEnabled;
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      if (!_initialized) await initialize();
      await _firebaseMessaging.subscribeToTopic(topic);
      developer.log('Suscrito al topic: $topic', name: 'PushNotification');
    } catch (e, stack) {
      developer.log('Error al suscribirse al topic $topic: $e', 
          name: 'PushNotification', error: e, stackTrace: stack);
      throw NotificationSendFailedException('SUBSCRIBE_ERROR', fcmError: e.toString());
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      if (!_initialized) await initialize();
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      developer.log('Desuscrito del topic: $topic', name: 'PushNotification');
    } catch (e, stack) {
      developer.log('Error al desuscribirse del topic $topic: $e', 
          name: 'PushNotification', error: e, stackTrace: stack);
      throw NotificationSendFailedException('UNSUBSCRIBE_ERROR', fcmError: e.toString());
    }
  }

  void dispose() {
    _notificationStreamController.close();
    developer.log('PushNotificationService disposed', name: 'PushNotification');
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  final PushNotificationService pushService = PushNotificationService();
  final NotificationService notificationService = NotificationService();
  
  try {
    developer.log('Mensaje recibido en segundo plano', name: 'PushNotification');
    
    final notification = pushService._parseRemoteMessage(message);
    await notificationService.createNotification(notification);
    
  } catch (e, stack) {
    developer.log('Error al manejar mensaje en segundo plano: $e', 
        name: 'PushNotification', error: e, stackTrace: stack);
  }
}