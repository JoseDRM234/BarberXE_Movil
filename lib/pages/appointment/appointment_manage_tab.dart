import 'package:barber_xe/controllers/services_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:barber_xe/controllers/appointment_controller.dart';
import 'package:barber_xe/controllers/profile_controller.dart';
import 'package:barber_xe/models/appointment_model.dart';

class AppointmentManageTab extends StatefulWidget {
  const AppointmentManageTab({super.key});

  @override
  State<AppointmentManageTab> createState() => _AppointmentManageTabState();
}

class _AppointmentManageTabState extends State<AppointmentManageTab> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uid = context.read<ProfileController>().currentUser?.uid;
    if (uid != null) {
      context.read<AppointmentController>().loadUserAppointments(uid, onlyUpcoming: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppointmentController>(
      builder: (context, controller, _) {
        final now = DateTime.now();
        final upcoming = controller.appointments.where(
          (c) =>
              c.dateTime.isAfter(now) &&
              (c.status == 'pending' || c.status == 'confirmed'),
        ).toList();

        if (upcoming.isEmpty) {
          return const Center(child: Text('No hay citas para modificar o cancelar'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: upcoming.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final cita = upcoming[index];
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                title: Text('Cita con ${cita.barberName}'),
                subtitle: Text(
                  DateFormat('EEEE, d MMM yyyy – HH:mm', 'es_ES')
                      .format(cita.dateTime),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showEditModal(context, cita),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () => _handleCancel(context, cita),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditModal(BuildContext context, Appointment cita) {
    final appointmentController = context.read<AppointmentController>();
    final serviceController = context.read<ServiceController>();

    DateTime pickedDate = cita.dateTime;
    TimeOfDay pickedTime =
        TimeOfDay(hour: cita.dateTime.hour, minute: cita.dateTime.minute);
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
                    const Text('Editar Cita',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    // Fecha
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

                    // Hora
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

                    const Text('Servicios',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: serviceController.services.map((s) {
                        final selected = selServices.contains(s.id);
                        return ChoiceChip(
                          label: Text(s.name),
                          selected: selected,
                          onSelected: (_) => setStateModal(() {
                            selected
                                ? selServices.remove(s.id)
                                : selServices.add(s.id);
                          }),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 12),

                    const Text('Combos',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: serviceController.combos.map((c) {
                        final selected = selCombos.contains(c.id);
                        return ChoiceChip(
                          label: Text(c.name),
                          selected: selected,
                          onSelected: (_) => setStateModal(() {
                            selected
                                ? selCombos.remove(c.id)
                                : selCombos.add(c.id);
                          }),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          appointmentController
                            ..setSelectedDate(pickedDate)
                            ..setSelectedTime(pickedTime)
                            ..clearServices()
                            ..addMultipleServices(selServices)
                            ..clearCombos()
                            ..addMultipleCombos(selCombos);

                          await appointmentController.updateAppointment(
                            cita: cita,
                            services: serviceController.services
                                .where((s) => selServices.contains(s.id))
                                .toList(),
                            combos: serviceController.combos
                                .where((c) => selCombos.contains(c.id))
                                .toList(),
                          );

                          Navigator.pop(context);
                          setState(() {}); // opcional
                        },
                        child: const Text('Guardar cambios'),
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

  void _handleCancel(BuildContext context, Appointment cita) async {
    final controller = context.read<AppointmentController>();
    final profile = context.read<ProfileController>();
    final now = DateTime.now();
    final diff = cita.dateTime.difference(now);

    if (diff.inHours < 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'No puedes cancelar una cita con menos de 3 horas de anticipación'),
      ));
      return;
    }

    try {
      await controller.cancelAppointment(cita.id!);
      await controller.loadUserAppointments(profile.currentUser!.uid,
          onlyUpcoming: true);
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
}