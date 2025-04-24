
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barber_xe/models/service_model.dart';

class ServiceController with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<Service> _services = [];
  List<Service> _combos = [];
  bool _isLoading = true;
  String _searchQuery = '';

  List<Service> get services => _searchQuery.isEmpty 
      ? _services 
      : _services.where((s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

  List<Service> get combos => _searchQuery.isEmpty 
      ? _combos 
      : _combos.where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

  bool get isLoading => _isLoading;

  Future<void> loadServices() async {
    try {
      _isLoading = true;
      notifyListeners();

      final snapshot = await _firestore
          .collection('services')
          .where('isActive', isEqualTo: true)
          .get();

      _services = snapshot.docs.map((doc) => Service.fromFirestore(doc, null)).toList();
      
      // Separar combos y servicios individuales
      _combos = _services.where((s) => s.isCombo).toList();
      _services = _services.where((s) => !s.isCombo).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addService(Service service) async {
    try {
      await _firestore.collection('services').add(service.toFirestore());
      await loadServices();
    } catch (e) {
      throw Exception('Error al agregar servicio: $e');
    }
  }

  Future<void> updateService(Service service) async {
    try {
      await _firestore
          .collection('services')
          .doc(service.id)
          .update(service.toFirestore());
      await loadServices();
    } catch (e) {
      throw Exception('Error al actualizar servicio: $e');
    }
  }

  Future<void> deleteService(String serviceId) async {
    try {
      await _firestore
          .collection('services')
          .doc(serviceId)
          .update({'isActive': false});
      await loadServices();
    } catch (e) {
      throw Exception('Error al eliminar servicio: $e');
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
}