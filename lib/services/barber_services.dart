// services/barber_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barber_xe/models/barber_model.dart';

class BarberService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Barber>> getBarbers() async {
    try {
      final snapshot = await _db.collection('barbers').get();
      return snapshot.docs.map((doc) => Barber.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Error al obtener barberos: $e');
    }
  }

  Future<String> addBarber(Barber barber) async {
    try {
      final docRef = await _db.collection('barbers').add(barber.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Error al agregar barbero: $e');
    }
  }

  Future<void> updateBarber(Barber barber) async {
    try {
      await _db.collection('barbers').doc(barber.id).update(barber.toFirestore());
    } catch (e) {
      throw Exception('Error al actualizar barbero: $e');
    }
  }

  Future<void> updateStatus(String id, String status) async {
    try {
      await _db.collection('barbers').doc(id).update({'status': status});
    } catch (e) {
      throw Exception('Error al actualizar estado: $e');
    }
  }

  Future<void> deleteBarber(String id) async {
    try {
      await _db.collection('barbers').doc(id).delete();
    } catch (e) {
      throw Exception('Error al eliminar barbero: $e');
    }
  }

  Future<List<Barber>> getActiveBarbers() async {
    try {
      final snapshot = await _db.collection('barbers')
          .where('status', isEqualTo: 'active')
          .get();
      return snapshot.docs.map((doc) => Barber.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Error al obtener barberos activos: $e');
    }
  }

  Future<List<Barber>> getBarbersByWorkingDay(int day) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('barbers')
      .where('status', isEqualTo: 'active')
      .where('workingDays', arrayContains: day)
      .get();

  return snapshot.docs.map((doc) => Barber.fromFirestore(doc)).toList();
}
}