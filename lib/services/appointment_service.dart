import 'package:barber_xe/models/service_combo.dart';
import 'package:barber_xe/models/service_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barber_xe/models/appointment_model.dart';
import 'package:flutter/material.dart';

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

  Future<List<Appointment>> fetchUserAppointments({
    required String userId,
    bool onlyUpcoming = false,
  }) async {
    try {
      Query query = _db.collection('appointments')
        .where('userId', isEqualTo: userId)
        .orderBy('dateTime', descending: true); // Orden descendente por fecha

      if (onlyUpcoming) {
        query = query.where(
          'dateTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()),
        );
      }

      final snapshot = await query.get();
      return snapshot.docs.map((d) => Appointment.fromFirestore(d)).toList();
    } catch (e) {
      debugPrint('Error fetching appointments: $e');
      throw Exception('Error al cargar citas');
    }
  }

  Future<void> update({
    required String appointmentId,
    required String userId,
    required String userName,
    required String barberId,
    required String barberName,
    required DateTime dateTime,
    required List<BarberService> services,
    required List<ServiceCombo> combos,
  }) async {
    // Calcular duración total
    final totalDuration = services.fold<int>(
      0, (sum, s) => sum + s.duration
    ) + combos.fold<int>(
      0, (sum, c) => sum + c.totalDuration
    );
    // Calcular precio total
    final totalPrice = services.fold<double>(
      0, (sum, s) => sum + s.price
    ) + combos.fold<double>(
      0, (sum, c) => sum + c.totalPrice
    );

    await _db.collection('appointments').doc(appointmentId).update({
      'userId':      userId,
      'userName':    userName,
      'barberId':    barberId,
      'barberName':  barberName,
      'serviceIds':  services.map((s) => s.id).toList(),
      'serviceNames':services.map((s) => s.name).toList(),
      'comboIds':    combos.map((c) => c.id).toList(),
      'comboNames':  combos.map((c) => c.name).toList(),
      'dateTime':    Timestamp.fromDate(dateTime),
      'duration':    totalDuration,
      'totalPrice':  totalPrice,
      'updatedAt':   FieldValue.serverTimestamp(),
    });
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
    debugPrint('Checking availability for barber $barberId at ${dateTime.toString()} for $duration minutes');

    final barberDoc = await _db.collection('barbers').doc(barberId).get();
    if (!barberDoc.exists) {
      return false;
    }

    final barberData = barberDoc.data()!;



    if (!barberData.containsKey('workingHours') ||
        !barberData['workingHours'].containsKey('start') ||
        !barberData['workingHours'].containsKey('end')) {
      return false;
    }

    final startTime = _parseTime(dateTime, barberData['workingHours']['start']);
    final endTime = _parseTime(dateTime, barberData['workingHours']['end']);

    final workStart = DateTime(dateTime.year, dateTime.month, dateTime.day, startTime.hour, startTime.minute);
    final workEnd = DateTime(dateTime.year, dateTime.month, dateTime.day, endTime.hour, endTime.minute);


    final appointmentEnd = dateTime.add(Duration(minutes: duration));
    if (dateTime.isBefore(workStart) || appointmentEnd.isAfter(workEnd)) {
      return false;
    }

    final startOfDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query = _db
        .collection('appointments')
        .where('barberId', isEqualTo: barberId)
        .where('status', whereIn: ['pending', 'confirmed'])
        .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('dateTime', isLessThan: Timestamp.fromDate(endOfDay));

    final snapshot = await query.get();

    for (final doc in snapshot.docs) {
      final existingAppointment = Appointment.fromFirestore(doc);
      final existingStart = existingAppointment.dateTime;
      final existingEnd = existingAppointment.dateTime.add(Duration(minutes: existingAppointment.duration));


      if ((dateTime.isBefore(existingEnd) && appointmentEnd.isAfter(existingStart))) {
        return false;
      }
    }
    return true;
  } catch (e) {
    debugPrint('Error checking availability: $e');
    return false;
  }
}


  // Ahora la función _parseTime acepta ambos parámetros, la fecha y la hora
  DateTime _parseTime(DateTime date, String timeStr) {
    final parts = timeStr.split(':');
    return DateTime(date.year, date.month, date.day, 
                  int.parse(parts[0]), int.parse(parts[1]));
  }

  static int calculateTotalDuration(List<BarberService> services, List<ServiceCombo> combos) {
    return services.fold(0, (sum, s) => sum + s.duration) +
          combos.fold(0, (sum, c) => sum + c.totalDuration);
  }

  static double calculateTotalPrice(List<BarberService> services, List<ServiceCombo> combos) {
    return services.fold(0.0, (sum, s) => sum + s.price) +
            combos.fold(0.0, (sum, c) => sum + c.totalPrice);
  }
  
}
