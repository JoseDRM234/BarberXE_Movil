import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barber_xe/models/appointment_model.dart';

class AppointmentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> createAppointment(Appointment appointment) async {
    try {
      final docRef = await _db.collection('appointments').add(appointment.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Error creating appointment: $e');
    }
  }

  Future<List<Appointment>> getUserAppointments(String userId) async {
    try {
      final snapshot = await _db.collection('appointments')
          .where('userId', isEqualTo: userId)
          .orderBy('dateTime', descending: false)
          .get();
      
      return snapshot.docs.map((doc) => Appointment.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Error getting appointments: $e');
    }
  }

  Future<void> cancelAppointment(String appointmentId) async {
    try {
      await _db.collection('appointments').doc(appointmentId).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error cancelling appointment: $e');
    }
  }

  Future<bool> isBarberAvailable({
    required String barberId,
    required DateTime dateTime,
    required int duration,
  }) async {
    try {
      // 1. Verificar horario laboral del barbero
      final barberDoc = await _db.collection('barbers').doc(barberId).get();
      if (!barberDoc.exists) return false;

      final barberData = barberDoc.data()!;
      final dayName = dateTime.weekday.toString(); // Ej: '1' para Lunes
      
      if (!barberData['workingDays'].contains(dayName)) {
        return false;
      }

      // 2. Verificar que esté dentro del horario laboral
      final startTime = barberData['workingHours']['start'];
      final endTime = barberData['workingHours']['end'];
      
      final appointmentEnd = dateTime.add(Duration(minutes: duration));
      
      if (dateTime.isBefore(_parseTime(dateTime, startTime))) {
        return false;
      }
      
      if (appointmentEnd.isAfter(_parseTime(dateTime, endTime))) {
        return false;
      }

      // 3. Verificar colisión con otras citas
      final existingAppointments = await _db.collection('appointments')
          .where('barberId', isEqualTo: barberId)
          .where('dateTime', isGreaterThanOrEqualTo: dateTime.subtract(Duration(minutes: duration)))
          .where('dateTime', isLessThanOrEqualTo: appointmentEnd)
          .where('status', whereIn: ['confirmed', 'pending'])
          .get();

      return existingAppointments.docs.isEmpty;
    } catch (e) {
      throw Exception('Error checking availability: $e');
    }
  }

  DateTime _parseTime(DateTime date, String timeStr) {
    final parts = timeStr.split(':');
    return DateTime(date.year, date.month, date.day, 
                  int.parse(parts[0]), int.parse(parts[1]));
  }
}