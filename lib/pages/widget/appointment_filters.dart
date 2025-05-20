import 'package:barber_xe/controllers/profile_controller.dart';
import 'package:barber_xe/pages/widget/app_helpers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:barber_xe/controllers/appointment_controller.dart';
import 'package:barber_xe/models/appointment_model.dart';

class AppointmentFilters extends StatelessWidget {
  const AppointmentFilters({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<AppointmentController>();
    final profileController = context.read<ProfileController>();

    return IconButton(
      icon: const Icon(Icons.filter_list),
      onPressed: () => showFiltersDialog(context, controller, profileController),
    );
  }

  void showFiltersDialog(BuildContext context, AppointmentController controller, ProfileController profileController) {
    DateTimeRange? selectedRange = controller.dateFilterRange;
    String? selectedStatus = controller.statusFilter;
    final isAdmin = profileController.isAdmin;
    final userId = profileController.currentUser?.uid;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Filtrar Citas'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.date_range),
                    title: const Text('Rango de Fechas'),
                    subtitle: Text(
                      selectedRange != null
                          ? '${DateFormat('dd/MM/yyyy').format(selectedRange!.start)} - ${DateFormat('dd/MM/yyyy').format(selectedRange!.end)}'
                          : 'Seleccionar fechas',
                    ),
                    onTap: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        initialDateRange: selectedRange,
                      );
                      if (picked != null) setState(() => selectedRange = picked);
                    },
                  ),
                  DropdownButtonFormField<String?>(
                    value: selectedStatus,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Todos los estados'),
                      ),
                      ...Appointment.statusOptions.map((status) => 
                        DropdownMenuItem(
                          value: status,
                          child: Text(AppHelpers.getStatusText(status)),
                        ),
                      )
                    ],
                    onChanged: (value) => setState(() => selectedStatus = value),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Clear filters with appropriate user context
                  controller.clearFilters(
                    forAdmin: isAdmin,
                    userId: isAdmin ? null : userId,
                  );
                  Navigator.pop(context);
                },
                child: const Text('Limpiar'),
              ),
              TextButton(
                onPressed: () {
                  // Apply filters with appropriate user context
                  controller.applyFilters(
                    dateRange: selectedRange,
                    status: selectedStatus,
                    forAdmin: isAdmin,
                    userId: isAdmin ? null : userId,
                  );
                  Navigator.pop(context);
                },
                child: const Text('Aplicar'),
              ),
            ],
          );
        },
      ),
    );
  }
}