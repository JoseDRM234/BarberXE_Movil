import 'package:barber_xe/pages/services/all_combos_page.dart';
import 'package:barber_xe/pages/services/all_services_page.dart';
import 'package:barber_xe/pages/widget/selectable_item_card.dart';
import 'package:barber_xe/services/appointment_service.dart';
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
    return const _AppointmentContent();
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

  void _navigateToAllServices(BuildContext context, AppointmentController controller) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AllServicesPage(selectedIds: controller.selectedServiceIds),
      ),
    );
  }

  void _navigateToAllCombos(BuildContext context, AppointmentController controller) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AllCombosPage(selectedIds: controller.selectedComboIds),
      ),
    );
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
    final totalPrice = appointmentController.calculateTotalPrice();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildServiceSelectionSection(serviceController, appointmentController),
            const SizedBox(height: 16),
            _buildComboSelectionSection(serviceController, appointmentController),
            const SizedBox(height: 16),
            _buildDateTimeSelectionSection(appointmentController),
            const SizedBox(height: 16),
            _buildBarberSelection(),
            const SizedBox(height: 16),
            _buildPaymentMethodCard(theme),
            const SizedBox(height: 16),
            _buildCostSummaryCard(appointmentController, serviceController, theme,totalPrice,),
            const SizedBox(height: 16),
            _buildConfirmButton(appointmentController, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceSelectionSection(
  ServiceController serviceController,
  AppointmentController appointmentController) {
  
  final displayedServices = serviceController.services.take(5).toList();
  final hasMoreServices = serviceController.services.length > 5;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Servicios Disponibles',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (hasMoreServices)
              TextButton(
                onPressed: () => _navigateToAllServices(context, appointmentController),
                child: const Text('Ver más'),
              ),
          ],
        ),
      ),
      SizedBox(
        height: 170,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: displayedServices.length,
          itemBuilder: (context, index) {
            final service = displayedServices[index];
            return SelectableItemCard(
              title: service.name,
              price: service.price,
              duration: service.duration,
              imageUrl: service.imageUrl,
              isSelected: appointmentController.selectedServiceIds.contains(service.id),
              onTap: () => _toggleServiceSelection(appointmentController, service.id),
            );
          },
        ),
      ),
    ],
  );
}


  Widget _buildComboSelectionSection(
    ServiceController serviceController,
    AppointmentController appointmentController) {
    
    final displayedCombos = serviceController.combos.take(5).toList();
    final hasMoreCombos = serviceController.combos.length > 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Combos Especiales',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (hasMoreCombos)
                TextButton(
                  onPressed: () => _navigateToAllCombos(context, appointmentController),
                  child: const Text('Ver más'),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: displayedCombos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final combo = displayedCombos[index];
              return SelectableItemCard(
                isCombo: true,
                title: combo.name,
                price: combo.totalPrice,
                duration: combo.totalDuration,
                imageUrl: combo.imageUrl,
                description: combo.description,
                isSelected: appointmentController.selectedComboIds.contains(combo.id),
                onTap: () => _toggleComboSelection(appointmentController, combo.id),
              );
            },
          ),
        ),
      ],
    );
  }

// Funciones auxiliares
void _toggleServiceSelection(AppointmentController controller, String serviceId) {
  if (controller.selectedServiceIds.contains(serviceId)) {
    controller.removeService(serviceId);
  } else {
    controller.addService(serviceId);
  }
}

void _toggleComboSelection(AppointmentController controller, String comboId) {
  if (controller.selectedComboIds.contains(comboId)) {
    controller.removeCombo(comboId);
  } else {
    controller.addCombo(comboId);
  }
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
        const Text('Seleccionar hora'),
        const SizedBox(height: 8),
        ListTile(
          title: Text(
            controller.selectedTime != null
                ? controller.selectedTime!.format(context)
                : 'Seleccionar hora',
          ),
          leading: const Icon(Icons.access_time),
          onTap: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: controller.selectedTime ?? const TimeOfDay(hour: 10, minute: 0),
              builder: (BuildContext context, Widget? child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Colors.black,
                      onPrimary: Colors.white,
                      onSurface: Colors.black,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            
            if (time != null && mounted) {
              controller.setSelectedTime(time);
              
              // Validate the combined date and time isn't in the past
              if (controller.selectedDate != null) {
                final selectedDateTime = DateTime(
                  controller.selectedDate!.year,
                  controller.selectedDate!.month,
                  controller.selectedDate!.day,
                  time.hour,
                  time.minute,
                );
                
                if (selectedDateTime.isBefore(DateTime.now())) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No puedes agendar citas en el pasado')),
                  );
                }
              }
            }
          },
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
    ThemeData theme,
    double totalPrice,
  ) {
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
  }

  Future<void> _confirmAppointment(AppointmentController controller) async {
    final profileController = Provider.of<ProfileController>(context, listen: false);
    final serviceController = Provider.of<ServiceController>(context, listen: false);
    
    // Validaciones básicas
    if (profileController.currentUser == null) {
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
      // Crear DateTime de la cita - Ensuring proper time construction
      final appointmentDateTime = DateTime(
        controller.selectedDate!.year,
        controller.selectedDate!.month,
        controller.selectedDate!.day,
        controller.selectedTime!.hour,
        controller.selectedTime!.minute,
      );

      // Debug log to check the constructed date and time
      debugPrint('Creating appointment for: ${appointmentDateTime.toString()}');

      // Verificar que no sea en el pasado
      if (appointmentDateTime.isBefore(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No puedes agendar citas en el pasado')),
        );
        return;
      }

      // Get selected services and combos
      final selectedServices = serviceController.services
          .where((s) => controller.selectedServiceIds.contains(s.id))
          .toList();
      
      final selectedCombos = serviceController.combos
          .where((c) => controller.selectedComboIds.contains(c.id))
          .toList();

      // Calcular duración
      final duration = AppointmentService.calculateTotalDuration(
        selectedServices,
        selectedCombos,
      );

      debugPrint('Checking availability for barber: ${controller.selectedBarberId}');
      debugPrint('At time: ${appointmentDateTime.toString()}');
      debugPrint('With duration: $duration minutes');

      // Verificar disponibilidad
      final isAvailable = await controller.checkAvailability(
        barberId: controller.selectedBarberId!,
        dateTime: appointmentDateTime,
        duration: duration,
      );

      if (!isAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El horario seleccionado no está disponible')),
        );
        return;
      }

      // Obtener nombre del barbero
      final barberDoc = await FirebaseFirestore.instance
          .collection('barbers')
          .doc(controller.selectedBarberId)
          .get();
      
      final barberName = barberDoc.exists 
          ? barberDoc['name']?.toString() ?? 'Barbero'
          : 'Barbero';

      debugPrint('Creating appointment with barber: $barberName');

      // Crear la cita
      final appointmentId = await controller.createAppointment(
        userId: profileController.currentUser!.uid,
        userName: profileController.currentUser!.fullName,
        barberId: controller.selectedBarberId!,
        barberName: barberName,
        services: selectedServices,
        combos: selectedCombos,
      );

      debugPrint('Appointment created with ID: $appointmentId');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cita confirmada exitosamente')),
      );

      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error creating appointment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al confirmar cita: ${e.toString()}')),
      );
    }
  }
}