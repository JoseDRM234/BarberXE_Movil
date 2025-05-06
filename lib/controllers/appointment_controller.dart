import 'package:barber_xe/models/service_combo.dart';
import 'package:barber_xe/models/service_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barber_xe/models/appointment_model.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

class AppointmentController with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DateTime? get selectedDate => _selectedDate;
  TimeOfDay? get selectedTime => _selectedTime;
  String? get selectedBarberId => _selectedBarberId;
  String? get selectedBarberName => _selectedBarberName;
  List<String> get selectedServiceIds => _selectedServiceIds;
  List<String> get selectedComboIds => _selectedComboIds;
  String get status => _status;
  
  // Estado de la cita
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedBarberId;
  String? _selectedBarberName;
  final List<String> _selectedServiceIds = [];
  final List<String> _selectedComboIds = [];
  String _status = 'pending'; // 'pending', 'confirmed', 'cancelled', 'completed'

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setSelectedTime(TimeOfDay time) {
    _selectedTime = time;
    notifyListeners();
  }

  void setSelectedBarber(String barberId, String barberName) {
    _selectedBarberId = barberId;
    _selectedBarberName = barberName;
    notifyListeners();
  }

  void addService(String serviceId) {
    if (!_selectedServiceIds.contains(serviceId)) {
      _selectedServiceIds.add(serviceId);
      notifyListeners();
    }
  }

  void removeService(String serviceId) {
    _selectedServiceIds.remove(serviceId);
    notifyListeners();
  }

  void addCombo(String comboId) {
    if (!_selectedComboIds.contains(comboId)) {
      _selectedComboIds.add(comboId);
      notifyListeners();
    }
  }

  void removeCombo(String comboId) {
    _selectedComboIds.remove(comboId);
    notifyListeners();
  }

  void clearSelection() {
    _selectedDate = null;
    _selectedTime = null;
    _selectedBarberId = null;
    _selectedServiceIds.clear();
    _selectedComboIds.clear();
    notifyListeners();
  }

  AppointmentController() {
    // Inicializar localización en español
    initializeDateFormatting('es_ES', null);
  }

  Future<String> createAppointment({
    required String userId,
    required String userName,
    required String barberId,
    required String barberName,
    required List<BarberService> services,
    required List<ServiceCombo> combos,
  }) async {
    try {
      if (userId.isEmpty) {
        throw AppointmentException('Usuario no autenticado');
      }

      if (_selectedDate == null || _selectedTime == null) {
        throw AppointmentException('Fecha u hora no seleccionados');
      }

      final totalDuration = calculateTotalDuration(services, combos);
      final totalPrice = calculateTotalPrice(services, combos);

      final appointmentDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final appointment = Appointment(
        userId: userId,
        userName: userName,
        barberId: barberId,
        barberName: barberName,
        serviceIds: _selectedServiceIds,
        serviceNames: services.map((s) => s.name).toList(),
        comboIds: _selectedComboIds,
        comboNames: combos.map((c) => c.name).toList(),
        dateTime: appointmentDateTime,
        duration: totalDuration,
        totalPrice: totalPrice,
        status: _status,
        createdAt: DateTime.now(),
      );

      final docRef = await _db.collection('appointments').add(appointment.toMap());
      return docRef.id;
    } on AppointmentException catch (e) {
      rethrow;
    } catch (e) {
      throw AppointmentException('Error al crear la cita: $e');
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
      throw AppointmentException('Error al obtener las citas: $e');
    }
  }

  Future<void> cancelAppointment(String appointmentId) async {
    try {
      await _db.collection('appointments').doc(appointmentId).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _status = 'cancelled';
      notifyListeners();
    } catch (e) {
      throw AppointmentException('Error al cancelar la cita: $e');
    }
  }

  Future<bool> checkAvailability({
    required String barberId,
    required DateTime dateTime,
    required int duration,
  }) async {
    try {
      final barberDoc = await FirebaseFirestore.instance
          .collection('barbers')
          .doc(barberId)
          .get();

      if (!barberDoc.exists) {
        throw AppointmentException('Barbero no encontrado');
      }

      final barberData = barberDoc.data();
      if (barberData == null) {
        throw AppointmentException('Datos del barbero no disponibles');
      }

      final workingDays = (barberData['workingDays'] as List<dynamic>?)?.cast<int>() ?? [];
      final dayOfWeek = dateTime.weekday;

      if (!workingDays.contains(dayOfWeek)) {
        throw AppointmentException('Barbero no trabaja este día');
      }

      final workingHours = (barberData['workingHours'] as Map<String, dynamic>?) ?? {};
      final startTimeStr = (workingHours['start'] as String?) ?? '09:00';
      final endTimeStr = (workingHours['end'] as String?) ?? '18:00';

      final startTime = _parseTimeString(startTimeStr);
      final endTime = _parseTimeString(endTimeStr);

      // Convertimos TimeOfDay a DateTime para la comparación
      final startDateTime = DateTime(dateTime.year, dateTime.month, dateTime.day, startTime.hour, startTime.minute);
      final endDateTime = DateTime(dateTime.year, dateTime.month, dateTime.day, endTime.hour, endTime.minute);

      final appointmentEnd = dateTime.add(Duration(minutes: duration));
      
      // Comparamos DateTime con DateTime
      if (dateTime.isBefore(startDateTime) || appointmentEnd.isAfter(endDateTime)) {
        throw AppointmentException('La cita está fuera del horario laboral');
      }

      final query = await FirebaseFirestore.instance
          .collection('appointments')
          .where('barberId', isEqualTo: barberId)
          .where('dateTime', isLessThan: appointmentEnd)
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();

      for (final doc in query.docs) {
        final existingAppointment = Appointment.fromFirestore(doc);
        final existingEnd = existingAppointment.dateTime.add(
          Duration(minutes: existingAppointment.duration),
        );
        
        if (dateTime.isBefore(existingEnd) && appointmentEnd.isAfter(existingAppointment.dateTime)) {
          throw AppointmentException('Superposición con otra cita');
        }
      }

      return true;
    } catch (e) {
      throw AppointmentException('Error verificando disponibilidad: $e');
    }
  }

  TimeOfDay _parseTimeString(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } catch (e) {
      throw AppointmentException('Error parseando hora: $e');
    }
  }


  int calculateTotalDuration(
    List<BarberService> services,
    List<ServiceCombo> combos,
  ) {
    int duration = 0;
    
    for (final serviceId in _selectedServiceIds) {
      final service = services.firstWhere(
        (s) => s.id == serviceId,
        orElse: () => BarberService(
          id: '',
          name: '',
          description: '',
          price: 0,
          duration: 0,
        ),
      );
      duration += service.duration;
    }

    for (final comboId in _selectedComboIds) {
      final combo = combos.firstWhere(
        (c) => c.id == comboId,
        orElse: () => ServiceCombo(
          id: '',
          name: '',
          description: '',
          totalPrice: 0,
          discount: 0,
          totalDuration: 0,
          serviceIds: [],
        ),
      );
      duration += combo.totalDuration;
    }

    return duration;
  }

  double calculateTotalPrice(
    List<BarberService> services,
    List<ServiceCombo> combos,
  ) {
    double total = 0;
    
    for (final serviceId in _selectedServiceIds) {
      final service = services.firstWhere(
        (s) => s.id == serviceId,
        orElse: () => BarberService(
          id: '',
          name: '',
          description: '',
          price: 0,
          duration: 0,
        ),
      );
      total += service.price;
    }

    for (final comboId in _selectedComboIds) {
      final combo = combos.firstWhere(
        (c) => c.id == comboId,
        orElse: () => ServiceCombo(
          id: '',
          name: '',
          description: '',
          totalPrice: 0,
          discount: 0,
          totalDuration: 0,
          serviceIds: [],
        ),
      );
      total += combo.totalPrice;
    }

    return total;
  }

  List<String> getSelectedServiceNames(List<BarberService> allServices) {
    return _selectedServiceIds.map((id) {
      final service = allServices.firstWhere(
        (s) => s.id == id,
        orElse: () => BarberService(
          id: '',
          name: 'Servicio no disponible',
          description: '',
          price: 0,
          duration: 0,
        ),
      );
      return service.name;
    }).toList();
  }

  List<String> getSelectedComboNames(List<ServiceCombo> allCombos) {
    return _selectedComboIds.map((id) {
      final combo = allCombos.firstWhere(
        (c) => c.id == id,
        orElse: () => ServiceCombo(
          id: '',
          name: 'Combo no disponible',
          description: '',
          totalPrice: 0,
          discount: 0,
          totalDuration: 0,
          serviceIds: [],
        ),
      );
      return combo.name;
    }).toList();
  }
}

class AppointmentException implements Exception {
  final String message;
  AppointmentException(this.message);
  
  @override
  String toString() => 'AppointmentException: $message';
}
