import 'package:barber_xe/models/barber_model.dart';
import 'package:barber_xe/models/service_combo.dart';
import 'package:barber_xe/models/service_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barber_xe/models/appointment_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  Future<void> updateStatus(String appointmentId, String newStatus, {String? changedBy}) async {
    // VALIDACIÓN ADICIONAL: Solo permitir transiciones válidas
    final validTransitions = {
      'pending': ['confirmed', 'cancelled'],
      'confirmed': ['completed', 'cancelled'],
      'completed': [],
      'cancelled': [],
    };

    final doc = await _db.collection('appointments').doc(appointmentId).get();
    if (!doc.exists) return;

    final currentStatus = doc.get('status') as String?;
    
    if (currentStatus != null && 
        !validTransitions[currentStatus]!.contains(newStatus)) {
      throw Exception('Transición de estado no permitida');
    }

    await doc.reference.update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
      'changedBy': changedBy,
    });
  }
  Future<void> deleteAppointment(String appointmentId) async {
    await _db.collection('appointments').doc(appointmentId).delete();
  }

    /// Obtiene todas las citas en un rango de fechas para el reporte de caja
  Future<List<Appointment>> getAppointmentsForCashRegister({
    required DateTime startDate,
    required DateTime endDate,
    String? barberId,
  }) async {
    Query query = _db.collection('appointments')
        .where('dateTime', isGreaterThanOrEqualTo: startDate)
        .where('dateTime', isLessThanOrEqualTo: endDate)
        .orderBy('dateTime', descending: true);

    if (barberId != null) {
      query = query.where('barberId', isEqualTo: barberId);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Appointment.fromFirestore(doc)).toList();
  }

  /// Calcula los totales de ingresos por estado de citas
  Future<Map<String, dynamic>> calculateCashRegisterTotals({
    required DateTime startDate,
    required DateTime endDate,
    String? barberId,
  }) async {
    final appointments = await getAppointmentsForCashRegister(
      startDate: startDate,
      endDate: endDate,
      barberId: barberId,
    );

    // Calcular totales por estado
    final completed = appointments.where((a) => a.status == 'completed');
    final pending = appointments.where((a) => a.status == 'pending');
    final cancelled = appointments.where((a) => a.status == 'cancelled');

    final completedTotal = completed.fold(0.0, (sum, a) => sum + a.totalPrice);
    final pendingTotal = pending.fold(0.0, (sum, a) => sum + a.totalPrice);
    final cancelledTotal = cancelled.fold(0.0, (sum, a) => sum + a.totalPrice);

    return {
      'completed': {
        'count': completed.length,
        'total': completedTotal,
        'appointments': completed.toList(),
      },
      'pending': {
        'count': pending.length,
        'total': pendingTotal,
        'appointments': pending.toList(),
      },
      'cancelled': {
        'count': cancelled.length,
        'total': cancelledTotal,
        'appointments': cancelled.toList(),
      },
      'totalIncome': completedTotal,
      'pendingAmount': pendingTotal,
      'cancelledAmount': cancelledTotal,
    };
  }

  /// Obtiene las citas completadas para un día específico
  Future<List<Appointment>> getCompletedAppointmentsForDay(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _db.collection('appointments')
        .where('status', isEqualTo: 'completed')
        .where('dateTime', isGreaterThanOrEqualTo: startOfDay)
        .where('dateTime', isLessThan: endOfDay)
        .get();

    return snapshot.docs.map((doc) => Appointment.fromFirestore(doc)).toList();
  }

  /// Genera un resumen diario de ingresos (sin método de pago)
  Future<Map<String, dynamic>> generateDailySummary(DateTime date) async {
    final appointments = await getCompletedAppointmentsForDay(date);
    
    if (appointments.isEmpty) {
      return {
        'date': date,
        'totalIncome': 0.0,
        'appointmentCount': 0,
        'averageTicket': 0.0,
      };
    }

    // Calcular total de ingresos
    final totalIncome = appointments.fold(0.0, (sum, a) => sum + a.totalPrice);
    
    // Calcular ticket promedio
    final averageTicket = totalIncome / appointments.length;

    return {
      'date': date,
      'totalIncome': totalIncome,
      'appointmentCount': appointments.length,
      'averageTicket': averageTicket,
    };
  }


    Future<bool> isBarberAvailableForUpdate({
      required String barberId,
      required DateTime dateTime,
      required int duration,
      required String excludeAppointmentId,
    }) async {
      try {
        // 1. Verificar existencia del barbero
        final barberDoc = await _db.collection('barbers').doc(barberId).get();
        if (!barberDoc.exists) {
          debugPrint('Barbero no encontrado: $barberId');
          return false;
        }

        // 2. Convertir a objeto Barber
        final barber = Barber.fromFirestore(barberDoc);
        final weekday = dateTime.weekday - 1;

        // 3. Verificar día de trabajo
        if (!barber.workingDays.contains(weekday)) {
          debugPrint('El barbero no trabaja este día (${dateTime.weekday})');
          return false;
        }

        // 4. Parsear horario laboral
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

        // 5. Calcular fin de la cita
        final appointmentEnd = dateTime.add(Duration(minutes: duration));
        
        // 6. Verificar horario laboral
        if (dateTime.isBefore(workStart)) {
          debugPrint('La cita comienza antes de la hora de inicio ($workStart)');
          return false;
        }
        
        if (appointmentEnd.isAfter(workEnd)) {
          debugPrint('La cita termina después de la hora de cierre ($workEnd)');
          return false;
        }

        // 7. Obtener todas las citas del día (solo activas)
        final startOfDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        
        final dayAppointments = await _db.collection('appointments')
            .where('barberId', isEqualTo: barberId)
            .where('dateTime', isGreaterThanOrEqualTo: startOfDay)
            .where('dateTime', isLessThan: endOfDay)
            .where('status', whereIn: ['pending', 'confirmed'])
            .get();

        // 8. Verificar solapamientos con otras citas
        for (final doc in dayAppointments.docs) {
          // Excluir la cita actual que estamos modificando
          if (doc.id == excludeAppointmentId) continue;
          
          final appointment = Appointment.fromFirestore(doc);
          final existingStart = appointment.dateTime;
          final existingEnd = existingStart.add(Duration(minutes: appointment.duration));
          
          // Comprobar todos los tipos de solapamiento posible
          final overlapCondition1 = dateTime.isBefore(existingEnd) && appointmentEnd.isAfter(existingStart);
          final overlapCondition2 = dateTime.isAtSameMomentAs(existingStart) || appointmentEnd.isAtSameMomentAs(existingEnd);
          final overlapCondition3 = dateTime.isBefore(existingStart) && appointmentEnd.isAfter(existingEnd);
          
          if (overlapCondition1 || overlapCondition2 || overlapCondition3) {
            debugPrint('Conflicto con cita existente: ${appointment.id} '
                      '(${DateFormat.Hm().format(existingStart)} - ${DateFormat.Hm().format(existingEnd)})');
            return false;
          }
        }

        // 9. Todas las validaciones pasaron
        return true;
        
      } catch (e) {
        debugPrint('Error en verificación de disponibilidad: $e');
        return false;
      }
    }
}