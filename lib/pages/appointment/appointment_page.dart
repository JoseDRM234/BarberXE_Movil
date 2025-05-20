import 'package:barber_xe/controllers/barber_controller.dart';
import 'package:barber_xe/models/barber_model.dart';
import 'package:barber_xe/pages/services/all_combos_page.dart';
import 'package:barber_xe/pages/services/all_services_page.dart';
import 'package:barber_xe/pages/widget/BusyTimeList.dart';
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
  int? _cachedBarberDay;
  Future<List<Barber>>? _barbersFuture;
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
    final barberController = Provider.of<BarberController>(context);
    final totalPrice = appointmentController.calculateTotalPrice();

    if (appointmentController.selectedDate != null) {
      final currentDay = appointmentController.selectedDate!.weekday - 1;
      if (currentDay != _cachedBarberDay) {
        _cachedBarberDay = currentDay;
        _barbersFuture = barberController.getBarbersByDay(currentDay);
      }
    }

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
            _buildBarberSelection(_barbersFuture),
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

  Widget _buildBarberSelection(Future<List<Barber>>? barbersFuture) {
  final controller = Provider.of<AppointmentController>(context);
  
  if (controller.selectedDate == null) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Text('Selecciona una fecha primero'),
    );
  }

  return FutureBuilder<List<Barber>>(
    future: barbersFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Error al cargar barberos',
            style: TextStyle(color: Colors.red[700]),
          ),
        );
      }

      final barbers = snapshot.data ?? [];

      if (barbers.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'No hay barberos disponibles este día',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 12),
            child: Row(
              children: [
                const Icon(Icons.content_cut, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Elige tu Barbero',
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: barbers.length,
              itemBuilder: (context, index) {
                final barber = barbers[index];
                final isSelected = controller.selectedBarberId == barber.id;
                
                return GestureDetector(
                  onTap: () {
                    controller.setSelectedBarber(barber.id, barber.name);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    width: 145,
                    decoration: BoxDecoration(
                      gradient: isSelected 
                          ? LinearGradient(
                              colors: [
                                Theme.of(context).primaryColor.withOpacity(0.2),
                                Theme.of(context).primaryColor.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected 
                              ? Theme.of(context).primaryColor.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.1),
                          blurRadius: isSelected ? 8 : 4,
                          spreadRadius: isSelected ? 1 : 0,
                          offset: Offset(0, isSelected ? 3 : 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Foto y badge de selección
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(14),
                                topRight: Radius.circular(14),
                              ),
                              child: Container(
                                height: 110,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.grey.shade300,
                                      Colors.grey.shade200,
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                                child: barber.photoUrl != null && barber.photoUrl!.isNotEmpty
                                  ? Image.network(
                                      barber.photoUrl!,
                                      height: 110,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded /
                                                    loadingProgress.expectedTotalBytes!
                                                : null,
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) => 
                                        const Center(
                                          child: Icon(Icons.person, size: 50, color: Colors.white),
                                        ),
                                    )
                                  : const Center(
                                      child: Icon(Icons.person, size: 50, color: Colors.white),
                                    ),
                              ),
                            ),
                            if (isSelected)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        
                        // Información del barbero - Aquí está el problema
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                barber.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isSelected 
                                      ? Theme.of(context).primaryColor 
                                      : Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 16),
                                  Text(
                                    " ${barber.rating.toStringAsFixed(1)}",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              
                              // Botón de ver perfil
                              InkWell(
                                onTap: () => _showBarberDetails(context, barber),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(context).primaryColor.withOpacity(0.9)
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.account_circle_outlined,
                                        size: 12,
                                        color: isSelected ? Colors.white : Colors.grey[700],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Ver perfil',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: isSelected ? Colors.white : Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    },
  );
}

void _showBarberDetails(BuildContext context, Barber barber) {
  // Formatear las horas de trabajo
  final startHour = barber.workingHours['start'] ?? '09:00';
  final endHour = barber.workingHours['end'] ?? '18:00';
  
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabecera con foto y datos principales
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Foto del barbero
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: barber.photoUrl != null && barber.photoUrl!.isNotEmpty
                    ? Image.network(
                        barber.photoUrl!,
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 100,
                          width: 100,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.person, size: 50, color: Colors.grey),
                        ),
                      )
                    : Container(
                        height: 100,
                        width: 100,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.person, size: 50, color: Colors.grey),
                      ),
                ),
                const SizedBox(width: 16),
                
                // Información del barbero
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        barber.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Status
                      Row(
                        children: [
                          Icon(
                            Icons.circle,
                            color: barber.status == 'active' ? Colors.green : Colors.grey,
                            size: 12,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            barber.status == 'active' ? 'Disponible' : 'No disponible',
                            style: TextStyle(
                              fontSize: 14,
                              color: barber.status == 'active' ? Colors.green : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Rating
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            barber.rating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Descripción
            if (barber.shortDescription.isNotEmpty) ...[
              const Text(
                'Descripción',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                barber.shortDescription,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
            ],
            
            // Horario de trabajo
            const Text(
              'Horario',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  '$startHour - $endHour',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Días de trabajo
            const Text(
              'Días disponibles',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildWorkDays(barber.workingDays),
            
            const SizedBox(height: 24),
            
            // Botón para seleccionar al barbero
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Provider.of<AppointmentController>(context, listen: false)
                    .setSelectedBarber(barber.id, barber.name);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Seleccionar Barbero',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildWorkDays(List<int> workingDays) {
  final daysNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: List.generate(7, (index) {
      final isWorkDay = workingDays.contains(index);
      
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isWorkDay ? Colors.green.shade100 : Colors.grey.shade200,
          border: Border.all(
            color: isWorkDay ? Colors.green : Colors.grey.shade400,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            daysNames[index],
            style: TextStyle(
              color: isWorkDay ? Colors.green.shade800 : Colors.grey.shade600,
              fontWeight: isWorkDay ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
      );
    }),
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
      // Verificar disponibilidad
      final isAvailable = await controller.checkAvailability(
        barberId: controller.selectedBarberId!,
        dateTime: appointmentDateTime,
        duration: duration,
      );

      if (!isAvailable) {

        final busyPeriods = await controller.getBusyPeriods(
          controller.selectedBarberId!,
          appointmentDateTime,
        );
        final nextAvailable = await _findNextAvailableSlot(
          barberId: controller.selectedBarberId!,
          originalDate: appointmentDateTime,
          duration: duration,
        );
        
        await _showAvailabilityErrorDialog(nextAvailable, busyPeriods);
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

  Future<DateTime?> _findNextAvailableSlot({
    required String barberId,
    required DateTime originalDate,
    required int duration,
  }) async {
    final barberController = context.read<BarberController>();
    final appointmentService = AppointmentService();
    
    try {
      final barber = await barberController.getBarberDetails(barberId);
      DateTime currentDate = originalDate;
      
      // Buscar en los próximos 7 días
      for (int i = 0; i < 7; i++) {
        final day = currentDate.weekday - 1;
        
        if (barber.workingDays.contains(day)) {
          final availableTime = await appointmentService.findAvailableTimeInDay(
            barber: barber,
            date: currentDate,
            duration: duration,
          );
          
          if (availableTime != null) return availableTime;
        }
        
        currentDate = currentDate.add(const Duration(days: 1));
      }
      return null;
    } catch (e) {
      debugPrint('Error buscando próximo horario: $e');
      return null;
    }
  }

  Future<void> _showAvailabilityErrorDialog(
    DateTime? nextAvailable, 
    List<Map<String, DateTime>> busyPeriods
  ) async {
    final theme = Theme.of(context);
    
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: 400,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Horario no disponible', 
                style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Citas existentes:'),
                      const SizedBox(height: 12),
                      BusyTimeList(busyPeriods: busyPeriods),
                      if (nextAvailable != null) ...[
                        const SizedBox(height: 24),
                        _NextAvailableSlot(nextAvailable: nextAvailable),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _DialogActions(nextAvailable: nextAvailable),
            ],
          ),
        ),
      ),
    );
  }
}
class _NextAvailableSlot extends StatelessWidget {
  final DateTime nextAvailable;

  const _NextAvailableSlot({required this.nextAvailable});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE dd/MM', 'es_ES').format(nextAvailable),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                DateFormat('HH:mm').format(nextAvailable),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DialogActions extends StatelessWidget {
  final DateTime? nextAvailable;

  const _DialogActions({this.nextAvailable});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        if (nextAvailable != null)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AppointmentController>()
                .scheduleToDateTime(nextAvailable!);
            },
            child: const Text('Usar horario'),
          ),
      ],
    );
  }
}