import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:barber_xe/controllers/appointment_controller.dart';
import 'package:barber_xe/controllers/profile_controller.dart';
import 'package:barber_xe/controllers/services_controller.dart';

class AppointmentPage extends StatefulWidget {
  static const String routeName = '/appointments';

  const AppointmentPage({super.key});

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reserva tu Cita'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const _AppointmentContent(),
    );
  }
}

class _AppointmentContent extends StatefulWidget {
  const _AppointmentContent();

  @override
  State<_AppointmentContent> createState() => _AppointmentContentState();
}

class _AppointmentContentState extends State<_AppointmentContent> {
  final List<String> _availableTimes = [
    '9:00 AM', '10:00 AM', '11:00 AM', '12:00 PM', 
    '2:00 PM', '3:00 PM', '4:00 PM', '5:00 PM', '6:00 PM'
  ];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es_ES', null);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return; // Verificar si el widget aún está montado
    
    final controller = context.read<AppointmentController>();
    final serviceController = context.read<ServiceController>();
    
    try {
      await serviceController.loadServicesAndCombos();
      
      if (mounted) { // Verificar nuevamente antes de actualizar
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        controller.setSelectedDate(tomorrow);
        controller.setSelectedTime(const TimeOfDay(hour: 10, minute: 0));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appointmentController = Provider.of<AppointmentController>(context);
    final serviceController = Provider.of<ServiceController>(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          _buildServiceSelectionSection(serviceController, appointmentController),
          _buildComboSelectionSection(serviceController, appointmentController),
          _buildDateTimeSelectionSection(appointmentController),
          _buildBarberSelection(),
          _buildPaymentMethodCard(theme),
          _buildCostSummaryCard(appointmentController, serviceController, theme),
          _buildConfirmButton(appointmentController, theme),
        ],
      ),
    );
  }

  Widget _buildServiceSelectionSection(
      ServiceController serviceController, 
      AppointmentController appointmentController) {
    return ExpansionTile(
      title: const Text('Servicios', style: TextStyle(fontWeight: FontWeight.bold)),
      initiallyExpanded: true,
      children: [
        if (serviceController.services.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No hay servicios disponibles'),
          )
        else
          ...serviceController.services.map((service) => CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(service.name),
            subtitle: Text('\$${service.price.toStringAsFixed(2)} - ${service.duration} min'),
            value: appointmentController.selectedServiceIds.contains(service.id),
            onChanged: (selected) {
              if (selected == true) {
                appointmentController.addService(service.id);
              } else {
                appointmentController.removeService(service.id);
              }
            },
          )),
      ],
    );
  }

  Widget _buildComboSelectionSection(
      ServiceController serviceController, 
      AppointmentController appointmentController) {
    return ExpansionTile(
      title: const Text('Combos', style: TextStyle(fontWeight: FontWeight.bold)),
      children: [
        if (serviceController.combos.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No hay combos disponibles'),
          )
        else
          ...serviceController.combos.map((combo) => CheckboxListTile(
            title: Text(combo.name),
            subtitle: Text('\$${combo.totalPrice.toStringAsFixed(2)} - ${combo.totalDuration} min'),
            value: appointmentController.selectedComboIds.contains(combo.id),
            onChanged: (selected) {
              if (selected == true) {
                appointmentController.addCombo(combo.id);
              } else {
                appointmentController.removeCombo(combo.id);
              }
            },
          )),
      ],
    );
  }

  Widget _buildDateTimeSelectionSection(AppointmentController controller) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Fecha y Hora', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildDateSelector(controller),
            const SizedBox(height: 16),
            if (controller.selectedDate != null) _buildTimeSelector(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector(AppointmentController controller) {
    return InkWell(
      onTap: () => _selectDate(context, controller),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 20),
            const SizedBox(width: 12),
            Text(
              controller.selectedDate != null 
                  ? DateFormat('EEEE, d MMMM y', 'es_ES').format(controller.selectedDate!)
                  : 'Seleccionar fecha',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector(AppointmentController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Horarios disponibles'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableTimes.map((timeStr) {
            final time = _parseTime(timeStr);
            final isSelected = controller.selectedTime != null && 
                controller.selectedTime!.hour == time.hour &&
                controller.selectedTime!.minute == time.minute;
                
            return ChoiceChip(
              label: Text(timeStr),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  controller.setSelectedTime(time);
                }
              },
              selectedColor: Theme.of(context).primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBarberSelection() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('barbers')
          .where('status', isEqualTo: 'active')
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return const Text('Error al cargar barberos');
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('No hay barberos disponibles');
        }

        final barbers = snapshot.data!.docs;

        return Consumer<AppointmentController>(
          builder: (context, controller, _) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Barbero',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButton<String>(
                      value: controller.selectedBarberId,
                      isExpanded: true,
                      underline: const SizedBox(),
                      hint: const Text('Selecciona un barbero'),
                      items: barbers.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return DropdownMenuItem<String>(
                          value: doc.id,
                          child: Text(data['name'] ?? 'Barbero sin nombre'),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          final selectedBarber = barbers.firstWhere(
                            (doc) => doc.id == newValue,
                          );
                          final data = selectedBarber.data() as Map<String, dynamic>;
                          controller.setSelectedBarber(
                            newValue,
                            data['name']?.toString() ?? 'Barbero',
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentMethodCard(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Método de Pago',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                width: 48,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.credit_card, size: 24),
              ),
              title: const Text('Visa **** 1234'),
              subtitle: const Text('Expira 05/26'),
              trailing: TextButton(
                child: const Text('Cambiar'),
                onPressed: () {
                  // Mostrar opciones de pago
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostSummaryCard(
      AppointmentController appointmentController,
      ServiceController serviceController,
      ThemeData theme) {
    final totalPrice = appointmentController.calculateTotalPrice(
      serviceController.services,
      serviceController.combos,
    );
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            if (appointmentController.selectedServiceIds.isNotEmpty) ...[
              const Text('Servicios:', style: TextStyle(fontWeight: FontWeight.w500)),
              ...appointmentController.selectedServiceIds.map((id) {
                final service = serviceController.services.firstWhere((s) => s.id == id);
                return _buildCostRow(service.name, '\$${service.price.toStringAsFixed(2)}');
              }),
              const SizedBox(height: 8),
            ],
            
            if (appointmentController.selectedComboIds.isNotEmpty) ...[
              const Text('Combos:', style: TextStyle(fontWeight: FontWeight.w500)),
              ...appointmentController.selectedComboIds.map((id) {
                final combo = serviceController.combos.firstWhere((c) => c.id == id);
                return _buildCostRow(combo.name, '\$${combo.totalPrice.toStringAsFixed(2)}');
              }),
              const SizedBox(height: 8),
            ],
            
            const Divider(),
            _buildCostRow('Subtotal', '\$${totalPrice.toStringAsFixed(2)}', isTotal: false),
            _buildCostRow('Total', '\$${totalPrice.toStringAsFixed(2)}', isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildCostRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? Theme.of(context).primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(AppointmentController controller, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          onPressed: () => _confirmAppointment(controller),
          child: Text(
            'CONFIRMAR CITA',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, AppointmentController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.black,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textTheme: Theme.of(context).textTheme.apply(
              bodyColor: Colors.black,
              displayColor: Colors.black,
            ),
          ),
          child: Localizations.override(
            context: context,
            locale: const Locale('es', 'ES'),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      controller.setSelectedDate(picked);
    }
  }

  TimeOfDay _parseTime(String timeStr) {
    try {
      final timeRegex = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$', caseSensitive: false);
      final match = timeRegex.firstMatch(timeStr.trim());
      
      if (match == null) throw const FormatException('Formato de hora inválido');

      var hour = int.parse(match.group(1)!);
      final minute = int.parse(match.group(2)!);
      final period = match.group(3)?.toUpperCase();

      if (period == 'PM' && hour != 12) {
        hour += 12;
      } else if (period == 'AM' && hour == 12) {
        hour = 0;
      }

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      debugPrint('Error parsing time ($timeStr): $e');
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  Future<void> _confirmAppointment(AppointmentController controller) async {
    final profileController = Provider.of<ProfileController>(context, listen: false);
    final serviceController = Provider.of<ServiceController>(context, listen: false);
    
    if (profileController.currentUser == null || profileController.currentUser?.uid.isEmpty == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para agendar una cita')),
      );
      return;
    }

    if (controller.selectedDate == null || controller.selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona fecha y hora para tu cita')),
      );
      return;
    }

    if (controller.selectedServiceIds.isEmpty && controller.selectedComboIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un servicio o combo')),
      );
      return;
    }

    if (controller.selectedBarberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un barbero')),
      );
      return;
    }

    try {
      final appointmentDateTime = DateTime(
        controller.selectedDate!.year,
        controller.selectedDate!.month,
        controller.selectedDate!.day,
        controller.selectedTime!.hour,
        controller.selectedTime!.minute,
      );

      final isAvailable = await controller.checkAvailability(
        barberId: controller.selectedBarberId!,
        dateTime: appointmentDateTime,
        duration: controller.calculateTotalDuration(
          serviceController.services,
          serviceController.combos,
        ),
      );

      if (!isAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El horario seleccionado no está disponible')),
        );
        return;
      }

      // Obtener el nombre del barbero seleccionado
      final barberDoc = await FirebaseFirestore.instance
          .collection('barbers')
          .doc(controller.selectedBarberId)
          .get();
      
      final barberName = barberDoc['name']?.toString() ?? 'Barbero';

      await controller.createAppointment(
      userId: profileController.currentUser!.uid,
      userName: profileController.currentUser!.fullName,
      barberId: controller.selectedBarberId ?? '', // ID directo
      barberName: controller.selectedBarberName ?? '', // Puedes obtenerlo de tu UI
      services: serviceController.services
          .where((s) => controller.selectedServiceIds.contains(s.id))
          .toList(),
      combos: serviceController.combos
          .where((c) => controller.selectedComboIds.contains(c.id))
          .toList(),
    );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cita confirmada exitosamente')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al confirmar cita: ${e.toString()}')),
      );
    }
  }
}