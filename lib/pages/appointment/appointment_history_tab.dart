import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:barber_xe/models/appointment_model.dart';
import 'package:barber_xe/controllers/appointment_controller.dart';
import 'package:barber_xe/controllers/profile_controller.dart';
import 'package:barber_xe/pages/widget/app_helpers.dart';
import 'package:barber_xe/pages/widget/appointment_card.dart';

class AppointmentHistoryTab extends StatefulWidget {
  const AppointmentHistoryTab({super.key});

  @override
  State<AppointmentHistoryTab> createState() => _AppointmentHistoryTabState();
}

class _AppointmentHistoryTabState extends State<AppointmentHistoryTab> {

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final uid = context.read<ProfileController>().currentUser?.uid;
    if (uid != null) {
      await context.read<AppointmentController>().loadAppointments(
        userId: uid,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppointmentController>(
      builder: (context, controller, _) {
        if (controller.isLoading && controller.currentPage == 1) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.allAppointments.isEmpty) {
          return const Center(child: Text('No tienes citas'));
        }

        return Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadInitialData,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.paginatedAppointments.length, // Solo los items reales
                  itemBuilder: (context, index) {
                    final cita = controller.paginatedAppointments[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppointmentCard(
                        appointment: cita,
                        onTap: () => _showAppointmentDetails(cita),
                      ),
                    );
                  },
                ),
              ),
            ),
            _buildPaginationControls(controller),
          ],
        );
      },
    );
  }

  Widget _buildPaginationControls(AppointmentController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: controller.currentPage > 1
                ? () => controller.setPage(controller.currentPage - 1)
                : null,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Página ${controller.currentPage} de ${controller.totalPages}',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: controller.currentPage < controller.totalPages
                ? () => controller.setPage(controller.currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }

  void _showAppointmentDetails(Appointment appointment) {
    final priceFormatter = NumberFormat("#,###", "es_ES");
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles de la Cita'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem('Barbero:', appointment.barberName),
              _buildDetailItem('Fecha:', 
                DateFormat('EEEE, d MMMM y - HH:mm', 'es_ES').format(appointment.dateTime)),
              _buildDetailItem('Duración:', '${appointment.duration} minutos'),
              _buildDetailItem(
                'Estado:', 
                AppHelpers.getStatusText(appointment.status)
              ),
              const SizedBox(height: 12),
              const Text('Servicios:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...appointment.serviceNames.map((s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('- $s'),
              )),
              if (appointment.comboNames.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Combos:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...appointment.comboNames.map((c) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('- $c'),
                )),
              ],
              const SizedBox(height: 16),
              _buildDetailItem(
                'Total:', 
                '\$${priceFormatter.format(appointment.totalPrice)}'
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(child: Text(value)),
        ],
      ),
    );
  }
}