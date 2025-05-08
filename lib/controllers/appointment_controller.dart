import 'package:barber_xe/controllers/services_controller.dart';
import 'package:barber_xe/exceptions/appointment_exception.dart';
import 'package:barber_xe/models/service_combo.dart';
import 'package:barber_xe/models/service_model.dart';
import 'package:barber_xe/services/appointment_service.dart';
import 'package:flutter/material.dart';
import 'package:barber_xe/models/appointment_model.dart';
import 'package:intl/date_symbol_data_local.dart';

class AppointmentController with ChangeNotifier {
  final AppointmentService _service = AppointmentService();
  bool isLoading = false;

  final ServiceController serviceController;
  

  DateTime? get selectedDate => _selectedDate;
  TimeOfDay? get selectedTime => _selectedTime;
  String? get selectedBarberId => _selectedBarberId;
  String? get selectedBarberName => _selectedBarberName;
  List<String> get selectedServiceIds => _selectedServiceIds;
  List<String> get selectedComboIds => _selectedComboIds;
  String get status => _status;
  List<Appointment> get appointments => _appointments;

  // Estado de la cita
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedBarberId;
  String? _selectedBarberName;
  final List<String> _selectedServiceIds = [];
  final List<String> _selectedComboIds = [];
  String _status = 'pending'; // pending, confirmed, cancelled, completed
  List<Appointment> _appointments = [];

  AppointmentController({required this.serviceController}) {
    initializeDateFormatting('es_ES', null);
  }

  double calculateTotalPrice() {
    double total = 0.0;
    
    // Sumar servicios seleccionados
    for (var serviceId in _selectedServiceIds) {
      final service = serviceController.services.firstWhere(
        (s) => s.id == serviceId,
        orElse: () => BarberService(
          id: '', 
          name: '', 
          price: 0.0, 
          duration: 0, 
          description: '', 
          imageUrl: ''
        ),
      );
      total += service.price;
    }
    
    // Sumar combos seleccionados (incluyendo el descuento)
    for (var comboId in _selectedComboIds) {
      final combo = serviceController.combos.firstWhere(
        (c) => c.id == comboId,
        orElse: () => ServiceCombo(
          id: '', 
          name: '',
          description: '',
          totalPrice: 0.0, 
          discount: 0.0, // Nuevo parámetro requerido
          totalDuration: 0, 
          serviceIds: [], 
          imageUrl: '',
          isActive: true,
        ),
      );
      // Aplicar descuento al precio del combo
      total += combo.totalPrice - (combo.totalPrice * combo.discount / 100);
    }
    
    return total;
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
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

  void addService(String id) {
    if (!_selectedServiceIds.contains(id)) {
      _selectedServiceIds.add(id);
      notifyListeners();
    }
  }

  void removeService(String id) {
    _selectedServiceIds.remove(id);
    notifyListeners();
  }

  void addCombo(String id) {
    if (!_selectedComboIds.contains(id)) {
      _selectedComboIds.add(id);
      notifyListeners();
    }
  }

  void removeCombo(String id) {
    _selectedComboIds.remove(id);
    notifyListeners();
  }

  void addMultipleServices(List<String> ids) {
    _selectedServiceIds.clear();
    _selectedServiceIds.addAll(ids);
    notifyListeners();
  }

  void addMultipleCombos(List<String> ids) {
    _selectedComboIds.clear();
    _selectedComboIds.addAll(ids);
    notifyListeners();
  }

  void clearServices() {
    _selectedServiceIds.clear();
    notifyListeners();
  }

  void clearCombos() {
    _selectedComboIds.clear();
    notifyListeners();
  }

  void clearSelection() {
    _selectedDate = null;
    _selectedTime = null;
    _selectedBarberId = null;
    _selectedBarberName = null;
    _selectedServiceIds.clear();
    _selectedComboIds.clear();
    _status = 'pending';
    notifyListeners();
  }

  Future<void> loadUserAppointments(String userId, {bool onlyUpcoming = false}) async {
  isLoading = true;

  try {
    _appointments = await _service.fetchUserAppointments(
      userId: userId,
      onlyUpcoming: onlyUpcoming,
    );
  } catch (e) {
    debugPrint('Error al cargar citas: $e');
    _appointments = []; // Asegúrate de limpiar si hay error
  } finally {
    isLoading = false;
    notifyListeners(); // Notifica para que la UI actualice con los datos cargados
  }
}

  Future<String> createAppointment({
    required String userId,
    required String userName,
    required String barberId,
    required String barberName,
    required List<BarberService> services,
    required List<ServiceCombo> combos,
  }) async {
    if (_selectedDate == null || _selectedTime == null) {
      throw AppointmentException('Selecciona fecha y hora');
    }

    final dateTime = DateTime(
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
      dateTime: dateTime,
      duration: AppointmentService.calculateTotalDuration(services, combos),
      totalPrice: calculateTotalPrice(),
      status: _status,
      createdAt: DateTime.now(),
    );

    return await _service.createAppointment(appointment);
  }

  Future<void> updateAppointment({
    required Appointment cita,
    required List<BarberService> services,
    required List<ServiceCombo> combos,
  }) async {
    if (_selectedDate == null || _selectedTime == null) {
      throw AppointmentException('Selecciona fecha y hora');
    }

    final newDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    await _service.update(
      appointmentId: cita.id!,
      userId: cita.userId,
      userName: cita.userName,
      barberId: cita.barberId,
      barberName: cita.barberName,
      dateTime: newDateTime,
      services: services,
      combos: combos,
    );

    await loadUserAppointments(cita.userId, onlyUpcoming: true);
  }

  Future<void> cancelAppointment(String appointmentId) async {
    await _service.cancelAppointment(appointmentId);
    _status = 'cancelled';
    notifyListeners();
  }

  Future<bool> checkAvailability({
    required String barberId,
    required DateTime dateTime,
    required int duration,
  }) async {
    return await _service.isBarberAvailable(
      barberId: barberId,
      dateTime: dateTime,
      duration: duration,
    );
  }

  DateTime combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }
}