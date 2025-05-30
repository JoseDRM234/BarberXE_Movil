// controllers/barber_controller.dart
import 'package:barber_xe/services/storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:barber_xe/models/barber_model.dart';
import 'package:barber_xe/services/barber_services.dart';

class BarberController with ChangeNotifier {
  final BarberService _barberService;
  List<Barber> _barbers = [];
  final Map<int, List<Barber>> _barbersByDayCache = {};
  bool _isLoading = false;
  String _errorMessage = '';

  BarberController({required BarberService barberService}) 
      : _barberService = barberService;

  List<Barber> get barbers => _barbers;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> loadBarbers() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _barbers = await _barberService.getBarbers();
      _barbers = _barbers;
      _errorMessage = '';
    } catch (e) {
      _errorMessage = e.toString();
      _barbers = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Barber>> getBarbersByDay(int day) async {
    // Verificar caché primero
    if (_barbersByDayCache.containsKey(day)) {
      return _barbersByDayCache[day]!;
    }
    
    try {
      final barbers = await _barberService.getBarbersByWorkingDay(day);
      _barbersByDayCache[day] = barbers; // Almacenar en caché
      return barbers;
    } catch (e) {
      _errorMessage = e.toString();
      return [];
    }
  }

  void clearDayCache(int day) {
    _barbersByDayCache.remove(day);
  }

  Future<bool> addBarber(Barber barber, {dynamic imageFile}) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (imageFile != null) {
        final imageUrl = await uploadBarberImage(imageFile);
        barber = barber.copyWith(photoUrl: imageUrl);
      }
      await _barberService.addBarber(barber);
      await loadBarbers();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateBarber(Barber barber, {dynamic imageFile}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Subir nueva imagen si existe
      if (imageFile != null) {
        final imageUrl = await uploadBarberImage(imageFile);
        barber = barber.copyWith(photoUrl: imageUrl);
      }
      await _barberService.updateBarber(barber);
      await loadBarbers();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

   // Método actualizado para agregar/actualizar calificación por usuario
  Future<bool> addRating(String barberId, double rating) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final barberIndex = _barbers.indexWhere((b) => b.id == barberId);
      if (barberIndex == -1) {
        throw Exception('Barbero no encontrado');
      }

      final currentBarber = _barbers[barberIndex];
      final updatedBarber = currentBarber.addOrUpdateUserRating(user.uid, rating);

      // Actualizar en Firestore
      await FirebaseFirestore.instance
          .collection('barbers')
          .doc(barberId)
          .update({
        'userRatings': updatedBarber.userRatings,
        'rating': updatedBarber.rating,
        'totalRatings': updatedBarber.totalRatings,
      });

      // Actualizar localmente
      _barbers[barberIndex] = updatedBarber;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
  // Verificar si el usuario actual ya ha calificado a un barbero
  bool hasCurrentUserRated(String barberId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final barber = _barbers.firstWhere(
      (b) => b.id == barberId,
      orElse: () => throw Exception('Barbero no encontrado'),
    );

    return barber.hasUserRated(user.uid);
  }

  // Obtener la calificación del usuario actual para un barbero
  double? getCurrentUserRating(String barberId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final barber = _barbers.firstWhere((b) => b.id == barberId);
      return barber.getUserRating(user.uid);
    } catch (e) {
      return null;
    }
  }

  // Nuevo método para cambiar estado sin recargar todo
  Future<bool> toggleBarberStatus(String barberId) async {
    try {
      // Buscar el barbero en la lista local
      final barberIndex = _barbers.indexWhere((b) => b.id == barberId);
      if (barberIndex == -1) {
        throw Exception('Barbero no encontrado');
      }

      final currentBarber = _barbers[barberIndex];
      final updatedBarber = currentBarber.toggleStatus();

      // Actualizar en Firestore
      await FirebaseFirestore.instance
          .collection('barbers')
          .doc(barberId)
          .update({'status': updatedBarber.status});

      // Actualizar localmente sin recargar
      _barbers[barberIndex] = updatedBarber;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<String?> uploadBarberImage(dynamic imageFile) async {
    try {
      final storage = StorageService();
      return await storage.uploadBarberImage(imageFile);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> updateBarberStatus(String id, String status) async {
    try {
      await _barberService.updateStatus(id, status);
      await loadBarbers();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> deleteBarber(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _barberService.deleteBarber(id);
      await loadBarbers();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<Barber> getBarberDetails(String barberId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('barbers')
          .doc(barberId)
          .get();
      
      if (!doc.exists) throw Exception('Barbero no encontrado');
      
      return Barber.fromFirestore(doc);
    } catch (e) {
      throw Exception('Error obteniendo detalles del barbero: ${e.toString()}');
    }
  }

  Future<List<Barber>> getActiveBarbers() async {
    try {
      return await _barberService.getActiveBarbers();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  Barber getBarberById(String id) {
    return _barbers.firstWhere(
      (b) => b.id == id,
      orElse: () => throw Exception('Barbero no encontrado')
    );
  }
}