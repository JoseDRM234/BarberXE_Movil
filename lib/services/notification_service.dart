import 'dart:async';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barber_xe/models/NotificationType_model.dart';
import 'package:barber_xe/models/NotificationFilter_model.dart';
import '../models/notification_model.dart';
import '../exceptions/notification_exceptions.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'notifications';
  final Map<String, StreamController<List<NotificationModel>>> _streamControllers = {};
  final Map<String, List<NotificationModel>> _cache = {};
  static const int maxNotificationsPerUser = 100;
  static const int defaultPageSize = 20;

  CollectionReference get _collection => _firestore.collection(_collectionName);

  // ========== OPERACIONES CRUD ==========

  Future<NotificationModel> createNotification(NotificationModel notification) async {
    try {
      _validateNotificationData(notification);
      await _checkUserNotificationLimit(notification.userId);
      
      final docRef = await _collection.add(notification.toFirestore());
      final createdNotification = notification.copyWith(id: docRef.id);
      
      developer.log('Notificación creada: ${docRef.id}');
      return createdNotification;
      
    } on FirebaseException catch (e) {
      throw _handleFirebaseException(e, 'crear notificación');
    } on NotificationException {
      rethrow;
    } catch (e) {
      throw GenericNotificationException('Error inesperado al crear notificación: ${e.toString()}');
    }
  }

  Future<NotificationModel> getNotificationById(String notificationId) async {
    try {
      final doc = await _collection.doc(notificationId).get();
      
      if (!doc.exists) {
        throw NotificationNotFoundException(notificationId);
      }
      
      return NotificationModel.fromFirestore(doc);
      
    } on FirebaseException catch (e) {
      throw _handleFirebaseException(e, 'obtener notificación');
    }
  }

  Future<List<NotificationModel>> getUserNotifications(
    String userId, {
    NotificationFilter? filter,
    int limit = defaultPageSize,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _collection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true);

      if (filter != null) query = _applyFiltersToQuery(query, filter);
      if (startAfter != null) query = query.startAfterDocument(startAfter);
      
      final querySnapshot = await query.limit(limit).get();
      final notifications = querySnapshot.docs.map(NotificationModel.fromFirestore).toList();

      _updateCache(userId, notifications);
      return notifications;
      
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable' && _cache.containsKey(userId)) {
        developer.log('Usando cache para usuario $userId');
        return _cache[userId]!;
      }
      throw _handleFirebaseException(e, 'obtener notificaciones');
    }
  }

  Future<NotificationModel> updateNotification(NotificationModel notification) async {
    try {
      _validateNotificationData(notification);
      await _collection.doc(notification.id).update(notification.toFirestore());
      return notification;
      
    } on FirebaseException catch (e) {
      throw _handleFirebaseException(e, 'actualizar notificación');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _collection.doc(notificationId).update({'isRead': true});
    } on FirebaseException catch (e) {
      throw _handleFirebaseException(e, 'marcar como leída');
    }
  }

  Future<void> markMultipleAsRead(List<String> notificationIds) async {
    try {
      final batch = _firestore.batch();
      for (final id in notificationIds) {
        batch.update(_collection.doc(id), {'isRead': true});
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw _handleFirebaseException(e, 'marcar múltiples como leídas');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _collection.doc(notificationId).delete();
    } on FirebaseException catch (e) {
      throw _handleFirebaseException(e, 'eliminar notificación');
    }
  }

  Future<void> deleteMultipleNotifications(List<String> notificationIds) async {
    try {
      final batch = _firestore.batch();
      for (final id in notificationIds) {
        batch.delete(_collection.doc(id));
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw _handleFirebaseException(e, 'eliminar múltiples notificaciones');
    }
  }

  // ========== STREAMS EN TIEMPO REAL ==========

  Stream<List<NotificationModel>> getUserNotificationsStream(
    String userId, {
    NotificationFilter? filter,
    int limit = defaultPageSize,
  }) {
    final streamKey = '${userId}_${filter.hashCode}_$limit';
    
    if (_streamControllers.containsKey(streamKey)) {
      return _streamControllers[streamKey]!.stream;
    }
    
    final controller = StreamController<List<NotificationModel>>.broadcast();
    _streamControllers[streamKey] = controller;
    
    Query query = _collection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    
    if (filter != null) query = _applyFiltersToQuery(query, filter);
    
    final subscription = query.snapshots().listen(
      (snapshot) {
        try {
          final notifications = snapshot.docs.map(NotificationModel.fromFirestore).toList();
          _updateCache(userId, notifications);
          if (!controller.isClosed) controller.add(notifications);
        } catch (e) {
          if (!controller.isClosed) controller.addError(_convertToNotificationException(e));
        }
      },
      onError: (e) {
        if (!controller.isClosed) controller.addError(_convertToNotificationException(e));
      }
    );
    
    controller.onCancel = () {
      subscription.cancel();
      _streamControllers.remove(streamKey);
      controller.close();
    };
    
    return controller.stream;
  }

  // ========== CONSULTAS ESPECIALIZADAS ==========

  Future<int> getUnreadCount(String userId) async {
    try {
      final countSnapshot = await _collection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();
      return countSnapshot.count ?? 0;
    } on FirebaseException catch (e) {
      throw _handleFirebaseException(e, 'obtener conteo no leídas');
    }
  }

  Future<List<NotificationModel>> getNotificationsByType(
    String userId,
    NotificationType type, {
    int limit = defaultPageSize,
  }) async {
    try {
      final querySnapshot = await _collection
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: type.name)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map(NotificationModel.fromFirestore).toList();
    } on FirebaseException catch (e) {
      throw _handleFirebaseException(e, 'obtener notificaciones por tipo');
    }
  }

  Future<int> cleanupOldNotifications(String userId, {int daysOld = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      final querySnapshot = await _collection
          .where('userId', isEqualTo: userId)
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      if (querySnapshot.docs.isEmpty) return 0;

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      return querySnapshot.docs.length;
    } on FirebaseException catch (e) {
      throw _handleFirebaseException(e, 'limpiar notificaciones antiguas');
    }
  }

  // ========== MÉTODOS AUXILIARES ==========

  Query _applyFiltersToQuery(Query query, NotificationFilter filter) {
    if (filter.type != null) query = query.where('type', isEqualTo: filter.type!.name);
    if (filter.isRead != null) query = query.where('isRead', isEqualTo: filter.isRead);
    if (filter.fromDate != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(filter.fromDate!));
    }
    if (filter.toDate != null) {
      query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(filter.toDate!));
    }
    return query;
  }

  void _validateNotificationData(NotificationModel notification) {
    final errors = <String>[];
    if (notification.userId.isEmpty) errors.add('userId vacío');
    if (notification.title.isEmpty) errors.add('título vacío');
    if (notification.description.isEmpty) errors.add('descripción vacía');
    if (notification.createdAt.isAfter(DateTime.now().add(Duration(minutes: 5)))) {
      errors.add('fecha futura inválida');
    }
    
    if (errors.isNotEmpty) {
      throw NotificationValidationException('datos_notificación', errors.join(', '));
    }
  }

  Future<void> _checkUserNotificationLimit(String userId) async {
    try {
      final countSnapshot = await _collection
          .where('userId', isEqualTo: userId)
          .count()
          .get();
      
      if ((countSnapshot.count ?? 0) >= maxNotificationsPerUser) {
        throw NotificationLimitExceededException(countSnapshot.count!, maxNotificationsPerUser);
      }
    } on FirebaseException catch (e) {
      developer.log('Advertencia: No se pudo verificar límite: ${e.code}');
    }
  }

  void _updateCache(String userId, List<NotificationModel> notifications) {
    _cache[userId] = notifications;
    if (_cache.length > 5) _cache.remove(_cache.keys.first);
  }

  NotificationException _handleFirebaseException(FirebaseException e, String operation) {
    developer.log('Error de Firebase al $operation: ${e.code}');
    
    switch (e.code) {
      case 'permission-denied':
        return NotificationPermissionDeniedException('firestore');
      case 'not-found':
        return NotificationNotFoundException('');
      case 'resource-exhausted':
        return NotificationLimitExceededException(0, maxNotificationsPerUser);
      case 'unavailable':
        return NotificationNetworkException(statusCode: 503, originalError: e.message);
      default:
        return NotificationNetworkException(statusCode: e.hashCode, originalError: e.message);
    }
  }

  NotificationException _convertToNotificationException(dynamic error) {
    if (error is FirebaseException) return _handleFirebaseException(error, 'stream');
    if (error is NotificationException) return error;
    return GenericNotificationException(error.toString());
  }

  // ========== GESTIÓN DE CACHE Y STREAMS ==========

  List<NotificationModel>? getCachedNotifications(String userId) => _cache[userId];
  void clearUserCache(String userId) => _cache.remove(userId);
  void clearAllCache() => _cache.clear();

  void closeStream(String userId, {NotificationFilter? filter, int limit = defaultPageSize}) {
    final streamKey = '${userId}_${filter.hashCode}_$limit';
    final controller = _streamControllers[streamKey];
    if (controller != null && !controller.isClosed) {
      controller.close();
      _streamControllers.remove(streamKey);
    }
  }

  void closeAllStreams() {
    _streamControllers.values.where((c) => !c.isClosed).forEach((c) => c.close());
    _streamControllers.clear();
  }

  void dispose() {
    closeAllStreams();
    clearAllCache();
  }

  
}