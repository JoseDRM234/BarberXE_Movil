import 'package:barber_xe/models/appointment_model.dart';

class CashRegister {
  final double totalIncome;
  final double pendingAmount;
  final double cancelledAmount;
  final List<Appointment> completedAppointments;
  final List<Appointment> pendingAppointments;
  final List<Appointment> cancelledAppointments;

  CashRegister({
    required this.totalIncome,
    required this.pendingAmount,
    required this.cancelledAmount,
    required this.completedAppointments,
    required this.pendingAppointments,
    required this.cancelledAppointments,
  });

  factory CashRegister.fromAppointments(List<Appointment> appointments) {
    final completed = appointments.where((a) => a.status == 'completed').toList();
    final pending = appointments.where((a) => a.status == 'pending').toList();
    final cancelled = appointments.where((a) => a.status == 'cancelled').toList();

    final totalIncome = completed.fold(0.0, (sum, a) => sum + a.totalPrice);
    final pendingAmount = pending.fold(0.0, (sum, a) => sum + a.totalPrice);
    final cancelledAmount = cancelled.fold(0.0, (sum, a) => sum + a.totalPrice);

    return CashRegister(
      totalIncome: totalIncome,
      pendingAmount: pendingAmount,
      cancelledAmount: cancelledAmount,
      completedAppointments: completed,
      pendingAppointments: pending,
      cancelledAppointments: cancelled,
    );
  }

    double get estimatedTotal {
    if (completedAppointments.isEmpty) return 0.0;
    return totalIncome + pendingAmount;
  }

  bool get showEstimatedTotal => completedAppointments.isNotEmpty;
}