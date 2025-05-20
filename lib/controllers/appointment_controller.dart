import 'package:barber_xe/controllers/barber_controller.dart';
import 'package:barber_xe/controllers/services_controller.dart';
import 'package:barber_xe/exceptions/appointment_exception.dart';
import 'package:barber_xe/models/service_combo.dart';
import 'package:barber_xe/models/service_model.dart';
import 'package:barber_xe/services/appointment_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:barber_xe/models/appointment_model.dart';
import 'package:intl/date_symbol_data_local.dart';

class AppointmentController with ChangeNotifier {
  final AppointmentService _service = AppointmentService();
  final BarberController barberController;
  int _currentPage = 1;
  int _totalPages = 1;
  final int _pageSize = 10;
  bool _hasMorePages = true;
  final int _itemsPerPage = 10;
  DateTimeRange? _dateFilterRange;
  String? _statusFilter;
  bool isLoading = false;
  List<Appointment> allAppointments = [];
  DocumentSnapshot? _lastDoc;

  final ServiceController serviceController;
  

  DateTime? get selectedDate => _selectedDate;
  TimeOfDay? get selectedTime => _selectedTime;
  String? get selectedBarberId => _selectedBarberId;
  String? get selectedBarberName => _selectedBarberName;
  List<String> get selectedServiceIds => _selectedServiceIds;
  List<String> get selectedComboIds => _selectedComboIds;
  String get status => _status;
  List<Appointment> get appointments => _appointments;
  int get currentPage => _currentPage;
  int get itemsPerPage => _itemsPerPage;
  DateTimeRange? get dateFilterRange => _dateFilterRange;
  String? get statusFilter => _statusFilter;
  bool get hasMorePages => _hasMorePages;


  List<Appointment> get paginatedAppointments {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    
    return allAppointments.length > endIndex 
        ? allAppointments.sublist(startIndex, endIndex)
        : allAppointments.sublist(startIndex);
  }
  int get totalPages => (allAppointments.length / _itemsPerPage).ceil();

  // Estado de la cita
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedBarberId;
  String? _selectedBarberName;
  final List<String> _selectedServiceIds = [];
  final List<String> _selectedComboIds = [];
  String _status = 'pending'; // pending, confirmed, cancelled, completed
  List<Appointment> _appointments = [];

  AppointmentController({required this.serviceController,
  required this.barberController}) {
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
    barberController.clearDayCache(date.weekday - 1);
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

  // Método para cambiar página
  void setPage(int page) {
    if (page >= 1 && page <= totalPages) {
      _currentPage = page;
      notifyListeners();
    }
  }

  // Método para aplicar filtros
  void applyFilters({
    DateTimeRange? dateRange,
    String? status,
    String? userId,
    bool forAdmin = false,
  }) {
    _dateFilterRange = dateRange;
    _statusFilter = status;
    _currentPage = 1;
    allAppointments = []; // Limpiar datos antiguos
    notifyListeners();
    
    // Load appointments with the correct context - admin or user specific
    loadAppointments(forAdmin: forAdmin, userId: userId);
  }

  // Método para limpiar filtros
  void clearFilters({String? userId, bool forAdmin = false}) {
    _dateFilterRange = null;
    _statusFilter = null;
    _currentPage = 1;
    loadAppointments(forAdmin: forAdmin, userId: userId);
  }

  void loadAdminData() {
    loadAllAppointments();
    notifyListeners();
  }

  Future<void> loadAppointments({bool forAdmin = false, String? userId}) async {
    isLoading = true;
    _currentPage = 1; // Reset to first page on new data load

    try {
      if (forAdmin) {
        allAppointments = await _service.fetchAllAppointments(
          startDate: _dateFilterRange?.start,
          endDate: _dateFilterRange?.end,
          status: _statusFilter,
        );
      } else if (userId != null) {
        allAppointments = await _service.fetchUserAppointments(
          userId: userId,
          startDate: _dateFilterRange?.start,
          endDate: _dateFilterRange?.end,
          status: _statusFilter,
        );
      }
        
      _hasMorePages = allAppointments.length >= _pageSize;
      _totalPages = (allAppointments.length / _pageSize).ceil();
    } catch (e) {
      allAppointments = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadNextPage() async {
    if (_currentPage < totalPages) {
      _currentPage++;
      notifyListeners();
    }
  }

  void loadPreviousPage() {
    if (_currentPage > 1) {
      _currentPage--;
      notifyListeners();
    }
  }

  List<Appointment> getFilteredAppointments() {
    return allAppointments
        .where((appointment) {
          final matchesStatus = _statusFilter == null || 
              appointment.status == _statusFilter;
          final matchesDateRange = _dateFilterRange == null ||
              (_dateFilterRange!.start.isBefore(appointment.dateTime) &&
                _dateFilterRange!.end.isAfter(appointment.dateTime));
          return matchesStatus && matchesDateRange;
        })
        .toList();
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

  

  Future<void> loadAllAppointments({bool resetPagination = true}) async {
    isLoading = true;
    if (resetPagination) _currentPage = 1;
    
    try {
      allAppointments = await _service.fetchAllAppointments(
        startDate: _dateFilterRange?.start,
        endDate: _dateFilterRange?.end,
        status: _statusFilter,
      );
    } catch (e) {
      debugPrint('Error al cargar todas las citas: $e');
      allAppointments = [];
    } finally {
      isLoading = false;
      notifyListeners();
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

  void scheduleToDateTime(DateTime newDateTime) {
    _selectedDate = newDateTime;
    _selectedTime = TimeOfDay.fromDateTime(newDateTime);
    notifyListeners();
  }

  Future<List<Map<String, DateTime>>> getBusyPeriods(String barberId, DateTime date) async {
    return await _service.getBarberAppointmentsForDay(barberId, date);
  }

  Future<void> updateAppointmentStatus({
    required String appointmentId,
    required String newStatus,
  }) async {
    try {
      await _service.updateStatus(appointmentId, newStatus);
      await loadAllAppointments();
      notifyListeners();
    } catch (e) {
      throw Exception('Error updating status: $e');
    }
  }

  Future<void> deleteAppointment(String appointmentId) async {
    try {
      await _service.deleteAppointment(appointmentId);
      await loadAllAppointments();
      notifyListeners();
    } catch (e) {
      throw Exception('Error deleting appointment: $e');
    }
  }
}