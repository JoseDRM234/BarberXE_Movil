import 'package:barber_xe/models/barber_model.dart';
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
    bool onlyUpcoming = false,  // Agrega este parámetro
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    Query query = FirebaseFirestore.instance
        .collection('appointments')
        .where('userId', isEqualTo: userId)
        .orderBy('dateTime', descending: true);

    if (onlyUpcoming) {
      query = query.where('dateTime', isGreaterThanOrEqualTo: DateTime.now());
    }

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    if (startDate != null && endDate != null) {
      query = query
          .where('dateTime', isGreaterThanOrEqualTo: startDate)
          .where('dateTime', isLessThanOrEqualTo: endDate);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Appointment.fromFirestore(doc)).toList();
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
      final barberDoc = await FirebaseFirestore.instance
          .collection('barbers')
          .doc(barberId)
          .get();
          
      if (!barberDoc.exists) return false;

      final barber = Barber.fromFirestore(barberDoc);
      final weekday = dateTime.weekday - 1;

      // 1. Verificar día de trabajo
      if (!barber.workingDays.contains(weekday)) {
        return false;
      }

      // 2. Verificar horario laboral
      final startParts = barber.workingHours['start']!.split(':');
      final endParts = barber.workingHours['end']!.split(':');
      
      final workStart = DateTime(
        dateTime.year,
        dateTime.month,
        dateTime.day,
        int.parse(startParts[0]),
        int.parse(startParts[1]),
      );
      
      final workEnd = DateTime(
        dateTime.year,
        dateTime.month,
        dateTime.day,
        int.parse(endParts[0]),
        int.parse(endParts[1]),
      );

      final appointmentEnd = dateTime.add(Duration(minutes: duration));
      
      if (dateTime.isBefore(workStart) || appointmentEnd.isAfter(workEnd)) {
        return false;
      }

      // 3. Verificar colisiones con otras citas
      final overlappingAppointments = await FirebaseFirestore.instance
          .collection('appointments')
          .where('barberId', isEqualTo: barberId)
          .where('dateTime', isLessThan: Timestamp.fromDate(appointmentEnd))
          .where('dateTime', isGreaterThan: Timestamp.fromDate(
            dateTime.subtract(Duration(minutes: duration))
          ))
          .get();

      return overlappingAppointments.docs.isEmpty;
    } catch (e) {
      debugPrint('Error checking availability: $e');
      return false;
    }
  }

  static int calculateTotalDuration(List<BarberService> services, List<ServiceCombo> combos) {
    return services.fold(0, (sum, s) => sum + s.duration) +
          combos.fold(0, (sum, c) => sum + c.totalDuration);
  }

  static double calculateTotalPrice(List<BarberService> services, List<ServiceCombo> combos) {
    return services.fold(0.0, (sum, s) => sum + s.price) +
            combos.fold(0.0, (sum, c) => sum + c.totalPrice);
  }

  Future<DateTime?> findAvailableTimeInDay({
    required Barber barber,
    required DateTime date,
    required int duration,
  }) async {
    try {
      final startTime = TimeOfDay.fromDateTime(DateTime.parse("2023-01-01 ${barber.workingHours['start']}"));
      final endTime = TimeOfDay.fromDateTime(DateTime.parse("2023-01-01 ${barber.workingHours['end']}"));
      
      DateTime currentTime = DateTime(
        date.year,
        date.month,
        date.day,
        startTime.hour,
        startTime.minute,
      );
      
      final endWorkDay = DateTime(
        date.year,
        date.month,
        date.day,
        endTime.hour,
        endTime.minute,
      );

      while (currentTime.add(Duration(minutes: duration)).isBefore(endWorkDay)) {
        final isAvailable = await isBarberAvailable(
          barberId: barber.id,
          dateTime: currentTime,
          duration: duration,
        );
        
        if (isAvailable) return currentTime;
        
        currentTime = currentTime.add(const Duration(minutes: 30));
      }
      
      return null;
    } catch (e) {
      throw Exception('Error buscando horario disponible: ${e.toString()}');
    }
  }

  Future<List<Map<String, DateTime>>> getBarberAppointmentsForDay(String barberId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _db.collection('appointments')
        .where('barberId', isEqualTo: barberId)
        .where('dateTime', isGreaterThanOrEqualTo: startOfDay)
        .where('dateTime', isLessThan: endOfDay)
        .get();

    return snapshot.docs.map((doc) {
      final appointment = Appointment.fromFirestore(doc);
      return {
        'start': appointment.dateTime,
        'end': appointment.dateTime.add(Duration(minutes: appointment.duration))
      };
    }).toList();
  }

  Future<List<Appointment>> fetchAllAppointments({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    Query query = FirebaseFirestore.instance
        .collection('appointments')
        .orderBy('dateTime', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    if (startDate != null && endDate != null) {
      query = query
          .where('dateTime', isGreaterThanOrEqualTo: startDate)
          .where('dateTime', isLessThanOrEqualTo: endDate);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Appointment.fromFirestore(doc)).toList();
  }

  Future<void> updateStatus(String appointmentId, String newStatus) async {
    await _db.collection('appointments').doc(appointmentId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteAppointment(String appointmentId) async {
    await _db.collection('appointments').doc(appointmentId).delete();
  }
}