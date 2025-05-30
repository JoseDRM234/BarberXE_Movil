import 'package:barber_xe/controllers/services_controller.dart';
import 'package:barber_xe/exceptions/appointment_exception.dart';
import 'package:barber_xe/models/service_combo.dart';
import 'package:barber_xe/models/service_model.dart';
import 'package:barber_xe/services/appointment_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:barber_xe/controllers/appointment_controller.dart';
import 'package:barber_xe/controllers/profile_controller.dart';
import 'package:barber_xe/models/appointment_model.dart';
import 'package:barber_xe/pages/widget/appointment_card.dart';
import 'package:barber_xe/pages/widget/app_helpers.dart'; // Agregado para usar AppHelpers

class AppointmentManageTab extends StatefulWidget {
  const AppointmentManageTab({super.key});

  @override
  State<AppointmentManageTab> createState() => _AppointmentManageTabState();
}

class _AppointmentManageTabState extends State<AppointmentManageTab> {
  bool _isLoading = false;
  final int _itemsPerPage = 10;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    final profileController = context.read<ProfileController>();
    final uid = profileController.currentUser?.uid;
    final isAdmin = profileController.currentUser?.isAdmin ?? false;

    if (uid != null) {
      if (isAdmin) {
        await context.read<AppointmentController>().loadAllAppointments();
      } else {
        await context.read<AppointmentController>().loadUserAppointments(uid, onlyUpcoming: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileController = context.read<ProfileController>();
    final isAdmin = profileController.currentUser?.isAdmin ?? false;
    final appointmentController = context.read<AppointmentController>();

    return Consumer<AppointmentController>(
      builder: (context, controller, _) {
        final now = DateTime.now();
        List<Appointment> allAppointments = isAdmin
            ? controller.allAppointments
            : controller.appointments.where(
                (c) => c.dateTime.isAfter(now) &&
                      (c.status == 'pending' || c.status == 'confirmed'),
              ).toList();

        // Calcular paginación
        final totalPages = (allAppointments.length / _itemsPerPage).ceil();
        final currentPage = controller.currentPage;
        final startIndex = (currentPage - 1) * _itemsPerPage;
        final endIndex = startIndex + _itemsPerPage;
        final paginatedAppointments = allAppointments.sublist(
          startIndex,
          endIndex.clamp(0, allAppointments.length),
        );

        if (allAppointments.isEmpty) {
          return const Center(child: Text('No hay citas para mostrar'));
        }

        return Column(
          children: [
            // Contador de resultados
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${allAppointments.length} citas encontradas',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Página $currentPage/$totalPages',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            // Lista de citas paginadas
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadAppointments,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: paginatedAppointments.length,
                  itemBuilder: (context, index) {
                    final cita = paginatedAppointments[index];
                    return _buildAppointmentCard(context, cita, isAdmin, now);
                  },
                ),
              ),
            ),
            
            // Paginador
            if (totalPages > 1) _buildPaginationControls(totalPages, controller),
          ],
        );
      },
    );
  }

  Widget _buildPaginationControls(int totalPages, AppointmentController controller) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Botón Anterior
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: controller.currentPage > 1
                ? () {
                    controller.setPage(controller.currentPage - 1);
                  }
                : null,
          ),
          
          // Números de página
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(totalPages, (index) {
                  final pageNumber = index + 1;
                  final isCurrentPage = pageNumber == controller.currentPage;
                  
                  return GestureDetector(
                    onTap: () {
                      controller.setPage(pageNumber);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isCurrentPage ? Colors.blue : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCurrentPage ? Colors.blue : Colors.grey[300]!,
                        ),
                      ),
                      child: Text(
                        '$pageNumber',
                        style: TextStyle(
                          color: isCurrentPage ? Colors.white : Colors.black,
                          fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          
          // Botón Siguiente
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: controller.currentPage < totalPages
                ? () {
                    controller.setPage(controller.currentPage + 1);
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(BuildContext context, Appointment cita, bool isAdmin, DateTime now) {
    final canEdit = cita.status != 'completed' && cita.status != 'cancelled' && cita.dateTime.isAfter(now);
    final canCancel = !isAdmin && canEdit && cita.status != 'cancelled';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Parte izquierda: Información de la cita
            Expanded(
              child: AppointmentCard(
                appointment: cita,
                isAdmin: isAdmin,
                onTap: () => _showEditModal(context, cita, isAdmin),
              ),
            ),
            
            // Parte derecha: Botones de acción
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Botón de editar
                  if (canEdit)
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.edit, color: Colors.blue, size: 24),
                      ),
                      onPressed: () => _showEditModal(context, cita, isAdmin),
                    ),
                  
                  // Menú de estados para admin
                  if (isAdmin)
                    PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.more_vert, color: Colors.grey, size: 24),
                      ),
                      onSelected: (value) => _handleStatusChange(context, cita, value),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'pending',
                          child: Row(
                            children: [
                              Icon(Icons.pending, color: Colors.orange, size: 20),
                              const SizedBox(width: 8),
                              const Text('Pendiente'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'confirmed',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.blue, size: 20),
                              const SizedBox(width: 8),
                              const Text('Confirmar'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'completed',
                          child: Row(
                            children: [
                              Icon(Icons.done_all, color: Colors.green, size: 20),
                              const SizedBox(width: 8),
                              const Text('Completar'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'cancelled',
                          child: Row(
                            children: [
                              Icon(Icons.cancel, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              const Text('Cancelar'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  
                  // Botón de cancelar para usuarios no admin
                  if (canCancel)
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.cancel, color: Colors.red, size: 24),
                      ),
                      onPressed: () => _handleCancel(context, cita),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditModal(BuildContext context, Appointment cita, bool isAdmin) {
    final appointmentController = context.read<AppointmentController>();
    final serviceController = context.read<ServiceController>();

    DateTime pickedDate = cita.dateTime;
    TimeOfDay pickedTime = TimeOfDay(hour: cita.dateTime.hour, minute: cita.dateTime.minute);
    List<String> selServices = List.from(cita.serviceIds);
    List<String> selCombos = List.from(cita.comboIds);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Editar Cita',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        if (isAdmin)
                          DropdownButton<String>(
                            value: cita.status,
                            items: Appointment.statusOptions.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(_getStatusText(value)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                _handleStatusChange(context, cita, value);
                                Navigator.pop(context);
                              }
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      title: Text(DateFormat('dd/MM/yyyy').format(pickedDate)),
                      leading: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: pickedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (d != null) setStateModal(() => pickedDate = d);
                      },
                    ),
                    ListTile(
                      title: Text(pickedTime.format(context)),
                      leading: const Icon(Icons.access_time),
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: pickedTime,
                        );
                        if (t != null) setStateModal(() => pickedTime = t);
                      },
                    ),
                    const Divider(),
                    const Text('Servicios', style: TextStyle(fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: serviceController.services.map((s) {
                        final selected = selServices.contains(s.id);
                        return ChoiceChip(
                          label: Text(s.name),
                          selected: selected,
                          onSelected: (_) => setStateModal(() {
                            selected ? selServices.remove(s.id) : selServices.add(s.id);
                          }),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    const Text('Combos', style: TextStyle(fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: serviceController.combos.map((c) {
                        final selected = selCombos.contains(c.id);
                        return ChoiceChip(
                          label: Text(c.name),
                          selected: selected,
                          onSelected: (_) => setStateModal(() {
                            selected ? selCombos.remove(c.id) : selCombos.add(c.id);
                          }),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _updateAppointment(
                          context,
                          cita,
                          pickedDate,
                          pickedTime,
                          selServices,
                          selCombos,
                          appointmentController,
                          serviceController,
                          setStateModal,
                        ),
                        child: _isLoading 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Guardar cambios'),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateAppointment(
    BuildContext context,
    Appointment cita,
    DateTime pickedDate,
    TimeOfDay pickedTime,
    List<String> selServices,
    List<String> selCombos,
    AppointmentController appointmentController,
    ServiceController serviceController,
    StateSetter setStateModal,
  ) async {
    setStateModal(() {
      _isLoading = true;
    });

    try {
      if (pickedDate == null || pickedTime == null) {
        _showErrorMessage('Por favor selecciona fecha y hora');
        return;
      }

      if (selServices.isEmpty && selCombos.isEmpty) {
        _showErrorMessage('Por favor selecciona al menos un servicio o combo');
        return;
      }

      final newDateTime = appointmentController.combineDateAndTime(
        pickedDate,
        pickedTime,
      );

      final selectedServices = _getSelectedServicesFromIds(serviceController, selServices);
      final selectedCombos = _getSelectedCombosFromIds(serviceController, selCombos);

      final totalDuration = AppointmentService.calculateTotalDuration(
        selectedServices, 
        selectedCombos
      );

      // Validar tiempo mínimo (30 minutos)
      if (newDateTime.isBefore(DateTime.now().add(const Duration(minutes: 30)))) {
        _showErrorMessage('No puedes agendar citas con menos de 30 minutos de anticipación');
        return;
      }

      // Actualizar la cita
      appointmentController
        ..setSelectedDate(pickedDate)
        ..setSelectedTime(pickedTime)
        ..clearServices()
        ..addMultipleServices(selServices)
        ..clearCombos()
        ..addMultipleCombos(selCombos);

      await appointmentController.updateAppointment(
        cita: cita,
        services: selectedServices,
        combos: selectedCombos,
      );

      _showSuccessMessage('Cita actualizada exitosamente');
      Navigator.pop(context);
      setState(() {});
    } on AppointmentException catch (e) {
      _showErrorMessage(e.message);
    } catch (e) {
      _showErrorMessage('Error inesperado: ${e.toString()}');
      debugPrint('Error updating appointment: $e');
    } finally {
      setStateModal(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  List<BarberService> _getSelectedServicesFromIds(ServiceController serviceController, List<String> serviceIds) {
    return serviceController.services
        .where((service) => serviceIds.contains(service.id))
        .toList();
  }

  List<ServiceCombo> _getSelectedCombosFromIds(ServiceController serviceController, List<String> comboIds) {
    return serviceController.combos
        .where((combo) => comboIds.contains(combo.id))
        .toList();
  }

  void _handleCancel(BuildContext context, Appointment cita) async {
    final controller = context.read<AppointmentController>();
    final profile = context.read<ProfileController>();
    final now = DateTime.now();
    final diff = cita.dateTime.difference(now);

    if (diff.inHours < 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No puedes cancelar una cita con menos de 3 horas de anticipación'),
      ));
      return;
    }

    try {
      await controller.cancelAppointment(cita.id!);
      await controller.loadUserAppointments(profile.currentUser!.uid, onlyUpcoming: true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cita cancelada')),
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cancelar cita: $e')),
      );
    }
  }

  Future<void> _handleStatusChange(BuildContext context, Appointment cita, String newStatus) async {
    final controller = context.read<AppointmentController>();

    try {
      await controller.adminUpdateAppointmentStatus(
        appointmentId: cita.id!,
        newStatus: newStatus,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Estado actualizado a ${_getStatusText(newStatus)}')),
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar estado: $e')),
      );
    }
  }

  String _getStatusText(String status) {
    return AppHelpers.getStatusText(status); // Usamos el helper para consistencia
  }
}