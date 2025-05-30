import 'dart:async';
import 'dart:developer' as developer;
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'notification_exceptions.dart';

/// Manejador centralizado de errores para el sistema de notificaciones
/// Proporciona recuperación automática, logging y comunicación con el usuario
class NotificationErrorHandler {
  static final NotificationErrorHandler _instance = NotificationErrorHandler._internal();
  factory NotificationErrorHandler() => _instance;
  NotificationErrorHandler._internal();

  /// Mapa de reintentos por tipo de error
  final Map<String, int> _retryCount = {};

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  /// Configuración de reintentos
  static const int maxRetries = 3;
  static const Duration baseRetryDelay = Duration(seconds: 1);

  /// Maneja una excepción específica de notificaciones
  Future<bool> handleNotificationError(
    NotificationException error,
    BuildContext? context, {
    String? operationId,
    VoidCallback? onRetry,
    Function(String, MessageType)? onShowMessage,
  }) async {
    // Registrar el error para debugging y analytics
    _logError(error, operationId);

    // Determinar estrategia según el tipo de error
    switch (error.runtimeType) {
      case NotificationNetworkException:
        return await _handleNetworkError(
          error as NotificationNetworkException,
          context,
          operationId: operationId,
          onRetry: onRetry,
          onShowMessage: onShowMessage,
        );

      case NotificationPermissionDeniedException:
        return await _handlePermissionError(
          error as NotificationPermissionDeniedException,
          context,
          onShowMessage: onShowMessage,
        );

      case NotificationNotFoundException:
        return await _handleNotFoundError(
          error as NotificationNotFoundException,
          context,
          onShowMessage: onShowMessage,
        );

      case NotificationSendFailedException:
        return await _handleSendError(
          error as NotificationSendFailedException,
          context,
          operationId: operationId,
          onRetry: onRetry,
          onShowMessage: onShowMessage,
        );

      case NotificationValidationException:
        return await _handleValidationError(
          error as NotificationValidationException,
          context,
          onShowMessage: onShowMessage,
        );

      case NotificationLimitExceededException:
        return await _handleLimitError(
          error as NotificationLimitExceededException,
          context,
          onShowMessage: onShowMessage,
        );

      case NotificationScheduleException:
        return await _handleScheduleError(
          error as NotificationScheduleException,
          context,
          onShowMessage: onShowMessage,
        );

      default:
        return await _handleGenericError(
          error,
          context,
          onShowMessage: onShowMessage,
        );
    }
  }

  /// Maneja errores de red con reintento automático
  Future<bool> _handleNetworkError(
    NotificationNetworkException error,
    BuildContext? context, {
    String? operationId,
    VoidCallback? onRetry,
    Function(String, MessageType)? onShowMessage,
  }) async {
    final retryKey = operationId ?? 'network_${DateTime.now().millisecondsSinceEpoch}';
    final retryCount = _retryCount[retryKey] ?? 0;

    if (retryCount < maxRetries) {
      _retryCount[retryKey] = retryCount + 1;
      final message = 'Error de conexión. Reintentando... (${retryCount + 1}/$maxRetries)';
      _showUserMessage(context, message, MessageType.info, onShowMessage);

      final delay = Duration(seconds: baseRetryDelay.inSeconds * (retryCount + 1));
      await Future.delayed(delay);
      onRetry?.call();
      return true;
    } else {
      _retryCount.remove(retryKey);
      final message = 'No se pudo conectar al servidor. Verifica tu conexión.';
      _showUserMessage(context, message, MessageType.error, onShowMessage);
      return false;
    }
  }

  /// Maneja errores de permisos denegados
  Future<bool> _handlePermissionError(
    NotificationPermissionDeniedException error,
    BuildContext? context, {
    Function(String, MessageType)? onShowMessage,
  }) async {
    final message = 'Permisos de notificación deshabilitados.';
    
    if (context != null && context.mounted) {
      return await _showPermissionDialog(context, onShowMessage);
    } else {
      _showUserMessage(context, message, MessageType.warning, onShowMessage);
      return false;
    }
  }

  Future<bool> _showPermissionDialog(
    BuildContext context,
    Function(String, MessageType)? onShowMessage,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permisos Requeridos'),
        content: const Text('Para recibir notificaciones, necesitamos permisos. ¿Deseas habilitarlos ahora?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Más tarde'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Habilitar'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final settings = await _firebaseMessaging.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );

        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          _showUserMessage(
            context, 
            'Permisos habilitados correctamente', 
            MessageType.success, 
            onShowMessage
          );
          return true;
        } else {
          _showUserMessage(
            context,
            'Permisos no concedidos. Puedes habilitarlos en la configuración del dispositivo.',
            MessageType.warning,
            onShowMessage,
          );
        }
      } catch (e) {
        _showUserMessage(
          context,
          'Error al solicitar permisos: ${e.toString()}',
          MessageType.error,
          onShowMessage,
        );
        _logError(GenericNotificationException('Error en permisos: ${e.toString()}'), null);
      }
    }
    
    return false;
  }

  /// Maneja errores cuando no se encuentra una notificación
  Future<bool> _handleNotFoundError(
    NotificationNotFoundException error,
    BuildContext? context, {
    Function(String, MessageType)? onShowMessage,
  }) async {
    final message = 'La notificación ya no está disponible. La lista se actualizará automáticamente.';
    _showUserMessage(context, message, MessageType.info, onShowMessage);
    return false; // No reintentar
  }

  /// Maneja errores de envío de notificaciones push
  Future<bool> _handleSendError(
    NotificationSendFailedException error,
    BuildContext? context, {
    String? operationId,
    VoidCallback? onRetry,
    Function(String, MessageType)? onShowMessage,
  }) async {
    // Algunos códigos de error de FCM son recuperables
    final recoverableErrors = ['UNAVAILABLE', 'INTERNAL', 'TIMEOUT'];
    final isRecoverable = recoverableErrors.contains(error.errorCode);

    if (isRecoverable) {
      return await _handleNetworkError(
        NotificationNetworkException(originalError: error.errorCode),
        context,
        operationId: operationId,
        onRetry: onRetry,
        onShowMessage: onShowMessage,
      );
    } else {
      final message = 'No se pudo enviar la notificación. La información se guardó localmente.';
      _showUserMessage(context, message, MessageType.warning, onShowMessage);
      return false;
    }
  }

  /// Maneja errores de validación
  Future<bool> _handleValidationError(
    NotificationValidationException error,
    BuildContext? context, {
    Function(String, MessageType)? onShowMessage,
  }) async {
    final message = 'Los datos proporcionados no son válidos: ${error.field}';
    _showUserMessage(context, message, MessageType.error, onShowMessage);
    return false; // Errores de validación no se reintentan
  }

  /// Maneja errores de límite excedido
  Future<bool> _handleLimitError(
    NotificationLimitExceededException error,
    BuildContext? context, {
    Function(String, MessageType)? onShowMessage,
  }) async {
    final message = 'Has alcanzado el límite de notificaciones (${error.maxLimit}). Elimina algunas para continuar.';
    _showUserMessage(context, message, MessageType.warning, onShowMessage);
    return false;
  }

  /// Maneja errores de programación
  Future<bool> _handleScheduleError(
    NotificationScheduleException error,
    BuildContext? context, {
    Function(String, MessageType)? onShowMessage,
  }) async {
    final message = 'No se pudo programar la notificación. Se enviará inmediatamente.';
    _showUserMessage(context, message, MessageType.warning, onShowMessage);
    return false; // Usar fallback en lugar de reintentar
  }

  /// Maneja errores genéricos
  Future<bool> _handleGenericError(
    NotificationException error,
    BuildContext? context, {
    Function(String, MessageType)? onShowMessage,
  }) async {
    final message = 'Ocurrió un error inesperado. Por favor, intenta nuevamente.';
    _showUserMessage(context, message, MessageType.error, onShowMessage);
    return false;
  }

  /// Muestra un mensaje al usuario usando diferentes métodos
  void _showUserMessage(
    BuildContext? context,
    String message,
    MessageType type,
    Function(String, MessageType)? onShowMessage,
  ) {
    if (onShowMessage != null) {
      onShowMessage(message, type);
      return;
    }

    if (context != null && context.mounted) {
      _showSnackBar(context, message, type);
      return;
    }

    developer.log(message, name: 'NotificationErrorHandler');
  }

  /// Muestra un SnackBar con el mensaje
  void _showSnackBar(BuildContext context, String message, MessageType type) {
    final backgroundColor = switch (type) {
      MessageType.success => Colors.green,
      MessageType.warning => Colors.orange,
      MessageType.error => Colors.red,
      MessageType.info => Colors.blue,
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: type == MessageType.error
            ? SnackBarAction(
                label: 'Reintentar',
                onPressed: () {/* Lógica de reintento */},
              )
            : null,
      ),
    );
  }



  /// Registra el error para debugging y analytics
  void _logError(NotificationException error, String? operationId) {
    developer.log(
      'NotificationError: ${error.runtimeType}',
      error: error.message,
      stackTrace: StackTrace.current,
    );

    FirebaseCrashlytics.instance.recordError(
      error,
      StackTrace.current,
      reason: 'Notification Error',
      information: [
        'Type: ${error.runtimeType}',
        'Message: ${error.message}',
        'Operation ID: $operationId',
      ],
    );

    //Registra el error como evento en Firebase Analytics
    FirebaseAnalytics.instance.logEvent(
      name: 'notification_error',
      parameters: {
        'error_type': error.runtimeType.toString(),
        'message': error.message,
        'operation_id': operationId ?? 'unknown',
      },
    );
  }


  /// Registra el error como evento en Firebase Analytics
  void _logAnalyticsEvent(NotificationException error, String? operationId) {
    final parameters = {
      'error_type': error.runtimeType.toString(),
      'error_message': error.message,
      'operation_id': operationId ?? 'unknown',
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    if (error.context != null) {
      parameters['error_context'] = error.context!;
    }

    FirebaseAnalytics.instance.logEvent(
      name: 'notification_error',
      parameters: parameters,
    );
  }

  /// Muestra un mensaje al usuario usando diferentes métodos
  
}

/// Tipos de mensajes para el usuario
enum MessageType {
  success,
  warning,
  error,
  info,
}