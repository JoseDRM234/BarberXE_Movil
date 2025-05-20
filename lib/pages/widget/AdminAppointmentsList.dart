
import 'package:barber_xe/controllers/appointment_controller.dart';
import 'package:barber_xe/models/appointment_model.dart';
import 'package:barber_xe/pages/widget/app_helpers.dart';
import 'package:barber_xe/pages/widget/appointment_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AdminAppointmentsList extends StatefulWidget {
  const AdminAppointmentsList({super.key});

  @override
  State<AdminAppointmentsList> createState() => _AdminAppointmentsListState();
}

class _AdminAppointmentsListState extends State<AdminAppointmentsList> {
  late final AppointmentController _controller;

  @override
  void initState() {
    super.initState();
    _controller = context.read<AppointmentController>();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _controller.loadAllAppointments();
    if (_controller.allAppointments.isEmpty) {
      await _controller.loadAllAppointments();
    }
  }

  @override
Widget build(BuildContext context) {
  return Consumer<AppointmentController>(
    builder: (context, controller, _) {
      if (controller.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      
      if (controller.allAppointments.isEmpty) {
        return const Center(child: Text('No se encontraron citas'));
      }

      return Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => controller.loadAllAppointments(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.paginatedAppointments.length + 1,
                itemBuilder: (context, index) {
                  if (index < controller.paginatedAppointments.length) {
                    final cita = controller.paginatedAppointments[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppointmentCard(
                        appointment: cita,
                        isAdmin: true,
                        onTap: () => _showAppointmentDetails(cita),
                        onLongPress: () => _showAdminOptions(cita),
                      ),
                    );
                  }
                  return controller.isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : const SizedBox();
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

  Widget _buildStatsHeader(AppointmentController controller) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total', controller.allAppointments.length),
              _buildStatItem('Pendientes',
                  controller.allAppointments.where((a) => a.status == 'pending').length),
              _buildStatItem('Confirmadas',
                  controller.allAppointments.where((a) => a.status == 'confirmed').length),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildAppointmentsList(AppointmentController controller) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: () => controller.loadAllAppointments(),
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: controller.paginatedAppointments.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final appointment = controller.paginatedAppointments[index];
          return _buildAppointmentTile(appointment);
        },
      ),
    );
  }

  Widget _buildAppointmentTile(Appointment appointment) {
    return AppointmentCard(
      appointment: appointment,
      isAdmin: true,
      onTap: () => _showAppointmentDetails(appointment),
      onLongPress: () => _showAdminOptions(appointment),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      backgroundColor: Colors.white,
      title: Text(
        'Detalles de la Cita',
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailItem('Cliente', appointment.userName),
            _buildDetailItem('Barbero', appointment.barberName),
            _buildDetailItem(
              'Fecha',
              DateFormat('EEEE, d MMMM y - HH:mm', 'es_ES').format(appointment.dateTime),
            ),
            _buildDetailItem('Duración', '${appointment.duration} minutos'),
            _buildDetailItem('Estado', AppHelpers.getStatusText(appointment.status)),

            if (appointment.serviceNames.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSectionTitle('Servicios'),
              ...appointment.serviceNames.map(_buildListItem),
            ],

            if (appointment.comboNames.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSectionTitle('Combos'),
              ...appointment.comboNames.map(_buildListItem),
            ],

            const SizedBox(height: 20),
            _buildDetailItem(
              'Total',
              '\$${priceFormatter.format(appointment.totalPrice)}',
              isBold: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cerrar',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}

Widget _buildDetailItem(String label, String value, {bool isBold = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    ),
  );
}

Widget _buildSectionTitle(String title) {
  return Text(
    title,
    style: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    ),
  );
}

Widget _buildListItem(String text) {
  return Padding(
    padding: const EdgeInsets.only(top: 4, left: 12),
    child: Text(
      '– $text',
      style: GoogleFonts.poppins(fontSize: 13.5),
    ),
  );
}

  void _showAdminOptions(Appointment appointment) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar Estado'),
              onTap: () {
                Navigator.pop(context);
                _showStatusEditDialog(appointment);
              },
            ),
            if (appointment.status != 'completed' && appointment.status != 'cancelled')
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Eliminar Cita'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteAppointment(appointment);
                },
              ),
            ListTile(
              leading: const Icon(Icons.content_copy),
              title: const Text('Copiar ID de Cita'),
              onTap: () {
                Navigator.pop(context);
                _copyToClipboard(appointment.id!);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusEditDialog(Appointment appointment) {
    String selectedStatus = appointment.status; // Inicializar con el estado actual

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Cambiar Estado'),
            content: DropdownButtonFormField<String>(
              value: selectedStatus,
              items: Appointment.statusOptions.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(AppHelpers.getStatusText(status)),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    selectedStatus = newValue; // Actualizar el estado local
                  });
                }
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  if (selectedStatus != appointment.status) {
                    try {
                      await _controller.updateAppointmentStatus(
                        appointmentId: appointment.id!,
                        newStatus: selectedStatus,
                      );
                      if (mounted) Navigator.pop(context);
                    } catch (e) {
                      if (mounted) _showErrorSnackbar('Error: $e');
                    }
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteAppointment(Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text('¿Estás seguro de eliminar esta cita permanentemente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _controller.deleteAppointment(appointment.id!);
                _showSuccessSnackbar('Cita eliminada exitosamente');
              } catch (e) {
                _showErrorSnackbar('Error al eliminar cita: $e');
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID copiado al portapapeles')),
      );
    }
  }


  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}