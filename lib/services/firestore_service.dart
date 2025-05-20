import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barber_xe/models/service_model.dart';
import 'package:barber_xe/models/service_combo.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Services ---
  Future<List<BarberService>> fetchServices() async {
    final snapshot = await _db.collection('services').get(); // Sin filtro
    return snapshot.docs.map((doc) => BarberService.fromFirestore(doc)).toList();
  }

  Future<void> addService(Map<String, dynamic> data) async {
    await _db.collection('services').add(data);
  }

  Future<void> updateService(String id, Map<String, dynamic> data) async {
    await _db.collection('services').doc(id).update(data);
  }

  Future<void> toggleServiceState(String id, bool isActive) async {
    await _db.collection('services').doc(id).update({'isActive': isActive});
  }


  Future<void> deleteService(String id) async {
    await _db.collection('services').doc(id).delete();
  }
  

  

  // --- Combos ---
Future<List<ServiceCombo>> fetchCombos() async {
  final snapshot = await _db.collection('combos').get(); // Sin filtro
  return snapshot.docs.map((doc) => ServiceCombo.fromFirestore(doc)).toList();
}

  Future<void> addCombo(Map<String, dynamic> data) async {
    await _db.collection('combos').add(data);
  }

  Future<void> updateCombo(String id, Map<String, dynamic> data) async {
    await _db.collection('combos').doc(id).update(data);
  }

  Future<void> toggleComboState(String id, bool isActive) async {
    await _db.collection('combos').doc(id).update({'isActive': isActive});
  }

  Future<List<DocumentSnapshot>> getServicesByIds(List<String> ids) async {
    return Future.wait(ids.map((id) => _db.collection('services').doc(id).get()));
  }

  Future<void> deleteCombo(String id) async {
    await _db.collection('combos').doc(id).delete();
  }

  Future<List<BarberService>> getServicesByFilter(Map<String, dynamic> filters) async {
  try {
    CollectionReference servicesRef = _db.collection('services');
    Query query = servicesRef;

    // Aplicar filtros
    filters.forEach((key, value) {
      query = query.where(key, isEqualTo: value);
    });

    final querySnapshot = await query.get();
    return querySnapshot.docs
        .where((doc) => doc.exists)
        .map((doc) => BarberService.fromFirestore(doc))
        .toList();
  } catch (e) {
    debugPrint('Error al obtener los servicios por filtro: $e');
    return [];
  }
}
}
