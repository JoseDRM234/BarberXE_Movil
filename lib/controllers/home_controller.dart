import 'package:barber_xe/models/service_model.dart';
import 'package:barber_xe/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeController with ChangeNotifier {
  final UserService _userService;
  List<Service> _services = [];
  List<Service> _combos = [];
  bool _isLoading = true;
  String _searchQuery = '';

  HomeController({required UserService userService}) : _userService = userService;

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

    final snapshot = await FirebaseFirestore.instance
        .collection('services')
        .where('isActive', isEqualTo: true) // Solo servicios activos
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

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
}