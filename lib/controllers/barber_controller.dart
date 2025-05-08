// controllers/barber_controller.dart
import 'package:flutter/material.dart';
import 'package:barber_xe/models/barber_model.dart';
import 'package:barber_xe/pages/services/barber_services.dart';

class BarberController with ChangeNotifier {
  final BarberService _barberService;
  List<Barber> _barbers = [];
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
      _errorMessage = '';
    } catch (e) {
      _errorMessage = e.toString();
      _barbers = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addBarber(Barber barber) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _barberService.addBarber(barber);
      await loadBarbers();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateBarber(Barber barber) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _barberService.updateBarber(barber);
      await loadBarbers();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
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

  Future<List<Barber>> getActiveBarbers() async {
    try {
      return await _barberService.getActiveBarbers();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }
}