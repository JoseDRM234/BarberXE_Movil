import 'package:barber_xe/models/cash_register_model.dart';
import 'package:barber_xe/services/appointment_service.dart';
import 'package:flutter/material.dart';

class CashRegisterController with ChangeNotifier {
  final AppointmentService appointmentService;
  CashRegister _cashRegister = CashRegister(
    totalIncome: 0,
    pendingAmount: 0,
    cancelledAmount: 0,
    completedAppointments: [],
    pendingAppointments: [],
    cancelledAppointments: [],
  );
  
  bool _isLoading = false;
  DateTimeRange? _dateRange;

  CashRegisterController({
    required this.appointmentService,
  });

  // Getters
  CashRegister get cashRegister => _cashRegister;
  bool get isLoading => _isLoading;
  DateTimeRange? get dateRange => _dateRange;

  Future<void> loadCashRegister({DateTimeRange? dateRange}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Usar el rango de fechas proporcionado o establecer uno por defecto (últimos 7 días)
      _dateRange = dateRange ?? DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now(),
      );

      // Obtener las citas filtradas por el rango de fechas
      final appointments = await appointmentService.getAppointmentsForCashRegister(
        startDate: _dateRange!.start,
        endDate: _dateRange!.end,
      );

      // Procesar las citas para crear el estado de caja
      _cashRegister = CashRegister.fromAppointments(appointments);
    } catch (e) {
      // Manejar el error adecuadamente según tu aplicación
      debugPrint('Error loading cash register: $e');
      // Opcional: puedes reiniciar el estado a vacío en caso de error
      _cashRegister = CashRegister(
        totalIncome: 0,
        pendingAmount: 0,
        cancelledAmount: 0,
        completedAppointments: [],
        pendingAppointments: [],
        cancelledAppointments: [],
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reload() async {
    await loadCashRegister(dateRange: _dateRange);
  }
}