import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:barber_xe/controllers/appointment_controller.dart';
import 'package:barber_xe/controllers/profile_controller.dart';

class AppointmentHistoryTab extends StatefulWidget {
  const AppointmentHistoryTab({super.key});

  @override
  State<AppointmentHistoryTab> createState() => _AppointmentHistoryTabState();
}

class _AppointmentHistoryTabState extends State<AppointmentHistoryTab> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uid = context.read<ProfileController>().currentUser?.uid;
    if (uid != null) {
      context.read<AppointmentController>().loadUserAppointments(uid, onlyUpcoming: false);
    }
  }
  

  @override
  Widget build(BuildContext context) {
    return Consumer<AppointmentController>(
      builder: (context, controller, _) {
        final now = DateTime.now();

        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final pastAppointments = controller.appointments
            .where((cita) => cita.dateTime.isBefore(now))
            .toList();

        if (pastAppointments.isEmpty) {
          return const Center(child: Text('No tienes citas anteriores'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: pastAppointments.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final cita = pastAppointments[index];
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                title: Text('Cita con ${cita.barberName}'),
                subtitle: Text(
                  DateFormat('EEEE, d MMM yyyy – HH:mm', 'es_ES').format(cita.dateTime),
                ),
              ),
            );
          },
        );
      },
    );
  }

}