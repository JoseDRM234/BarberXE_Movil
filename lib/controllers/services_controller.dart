import 'package:flutter/material.dart';
import 'package:barber_xe/models/service_model.dart';
import 'package:barber_xe/models/service_combo.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barber_xe/services/firestore_service.dart';

class ServiceController with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<BarberService> _services = [];
  List<ServiceCombo> _combos = [];
  List<BarberService> _allServices = [];
  List<BarberService> _filteredServices = [];

  bool _isLoading = true;
  String _searchQuery = '';
  String? _currentCategory;
  String? _currentSort;

  
  List<ServiceCombo> get combos => _filterItems(_combos);
  List<BarberService> get services => _filteredServices;
  bool get isLoading => _isLoading;

  List<T> _filterItems<T>(List<T> items) {
    if (_searchQuery.isEmpty) return items;
    return items.where((item) {
      final name = (item is BarberService) 
          ? item.name 
          : (item as ServiceCombo).name;
      return name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  List<String> get categories => _allServices
      .map((s) => s.category)
      .toSet()
      .toList();

  void filterByCategory(String? category) {
    _currentCategory = category == 'Todas' ? null : category;
    _applyFilters();
  }

  void setCategoryFilter(String? category) {
    _currentCategory = category;
    _applyFilters();
  }

  void setSorting(String? sortBy) {
    _currentSort = sortBy;
    _applyFilters();
  }

  void _applyFilters() {
    // Aplicar filtro de categoría
    _filteredServices = _services.where((service) {
      if (_currentCategory != null && service.category != _currentCategory) {
        return false;
      }
      return true;
    }).toList();

    // Aplicar ordenamiento
    if (_currentSort != null) {
      switch (_currentSort) {
        case 'price_asc':
          _filteredServices.sort((a, b) => a.price.compareTo(b.price));
          break;
        case 'price_desc':
          _filteredServices.sort((a, b) => b.price.compareTo(a.price));
          break;
        case 'duration_asc':
          _filteredServices.sort((a, b) => a.duration.compareTo(b.duration));
          break;
        case 'duration_desc':
          _filteredServices.sort((a, b) => b.duration.compareTo(a.duration));
          break;
        default:
          // Orden por defecto (tal vez por nombre)
          _filteredServices.sort((a, b) => a.name.compareTo(b.name));
      }
    }

    notifyListeners();
  }

  Future<List<BarberService>> getAvailableServices() async {
    if (_services.isEmpty) {
      await loadServicesAndCombos();
    }
    return _services.where((service) => service.isActive).toList();
  }

  

  Future<void> loadServicesAndCombos() async {
    _isLoading = true;
    
    try {
      
      _services = await _firestoreService.fetchServices();
      _combos = await _firestoreService.fetchCombos();
      _filteredServices = List.from(_services); // Copia inicial
      _applyFilters();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addService(BarberService service) async {
    await _firestoreService.addService(service.toFirestore());
    await loadServicesAndCombos();
  }

  Future<void> updateService(BarberService service) async {
    await _firestoreService.updateService(service.id, service.toFirestore());
    await loadServicesAndCombos();
  }

  Future<void> toggleServiceState(String id, bool isActive) async {
    await _firestoreService.toggleServiceState(id, isActive);
    await loadServicesAndCombos();
  }

  Future<List<BarberService>> getServicesForCombo(ServiceCombo combo) async {
  try {
    // Validamos que haya IDs
    if (combo.serviceIds.isEmpty) return [];

    // Obtener documentos desde Firestore
    final docs = await _firestoreService.getServicesByIds(combo.serviceIds);

    // Convertirlos en objetos BarberService
    return docs
        .where((doc) => doc.exists)
        .map((doc) => BarberService.fromFirestore(doc))
        .toList();
  } catch (e) {
    debugPrint('Error obteniendo servicios del combo: $e');
    return [];
  }
}

Future<List<DocumentSnapshot>> getServicesByFilter(Map<String, dynamic> filters) async {
    CollectionReference servicesRef = _db.collection('services');
    Query query = servicesRef;

    filters.forEach((key, value) {
      query = query.where(key, isEqualTo: value);
    });

    final querySnapshot = await query.get();
    return querySnapshot.docs;
  }

  // En ServiceController
Future<void> addCombo({
  required String name,
  required String description,
  required List<String> serviceIds,
  required double discount,
  String? imageUrl,
}) async {
  try {
      // Obtener servicios actualizados
      final services = await _firestoreService.getServicesByIds(serviceIds);
      
      // Cálculo de precios y duración
      final totalPrice = services.fold<double>(0, (sum, doc) {
        final data = doc.data() as Map<String, dynamic>;
        return sum + (data['price'] as num).toDouble();
      });

      final totalDuration = services.fold<int>(0, (sum, doc) {
        final data = doc.data() as Map<String, dynamic>;
        return sum + (data['duration'] as num).toInt();
      });

      await _firestoreService.addCombo({
        'name': name,
        'description': description,
        'totalPrice': totalPrice - discount,
        'discount': discount,
        'totalDuration': totalDuration,
        'serviceIds': serviceIds,
        'imageUrl': imageUrl,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await loadServicesAndCombos(); // Forzar recarga
    } catch (e) {
      debugPrint('Error adding combo: $e');
      rethrow;
    }
  }

  Future<void> updateCombo(ServiceCombo combo) async {
    await _firestoreService.updateCombo(combo.id, combo.toFirestore());
    await loadServicesAndCombos();
  }

  Future<void> deleteService(String id) async {
    await _firestoreService.deleteService(id);
    await loadServicesAndCombos();
  }

  // Nueva función para eliminar un combo
  Future<void> deleteCombo(String id) async {
    await _firestoreService.deleteCombo(id);
    await loadServicesAndCombos();
  }

  Future<void> toggleComboState(String id, bool isActive) async {
    await _firestoreService.toggleComboState(id, isActive);
    await loadServicesAndCombos();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<List<BarberService>> getServicesByIds(List<String> ids) async {
    try {
      final docs = await _firestoreService.getServicesByIds(ids);
      return docs
          .where((doc) => doc.exists)
          .map((doc) => BarberService.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting services by IDs: $e');
      return [];
    }
  }

  Future<List<BarberService>> getActiveServices() async {
    if (_services.isEmpty) {
      await loadServicesAndCombos();
    }
    return _services.where((s) => s.isActive).toList();
  }
}
