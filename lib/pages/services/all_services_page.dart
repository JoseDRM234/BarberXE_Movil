import 'package:barber_xe/controllers/appointment_controller.dart';
import 'package:barber_xe/controllers/services_controller.dart';
import 'package:barber_xe/pages/widget/selectable_item_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AllServicesPage extends StatefulWidget {
  final List<String> selectedIds;
  
  const AllServicesPage({super.key, required this.selectedIds});

  @override
  State<AllServicesPage> createState() => _AllServicesPageState();
}

class _AllServicesPageState extends State<AllServicesPage> {
  late List<String> _selectedIds;
  String? _selectedCategory;
  String? _selectedSort;

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.selectedIds);
  }

  void _toggleSelection(String serviceId) {
    setState(() {
      if (_selectedIds.contains(serviceId)) {
        _selectedIds.remove(serviceId);
      } else {
        _selectedIds.add(serviceId);
      }
    });
  }

  void _confirmSelection() {
    final appointmentController = context.read<AppointmentController>();
    appointmentController
      ..clearServices()
      ..addMultipleServices(_selectedIds);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ServiceController>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todos los Servicios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _confirmSelection,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildFilters(context, controller),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: controller.services.map((service) {
                return SizedBox(
                  width: MediaQuery.of(context).size.width * 0.45,
                  child: SelectableItemCard(
                    title: service.name,
                    price: service.price,
                    duration: service.duration,
                    imageUrl: service.imageUrl,
                    isSelected: _selectedIds.contains(service.id),
                    onTap: () => _toggleSelection(service.id),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context, ServiceController controller) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Categoría',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Todas las categorías')),
              ...controller.categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
            ],
            onChanged: (value) {
              setState(() => _selectedCategory = value);
              controller.filterByCategory(value);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedSort,
            decoration: const InputDecoration(
              labelText: 'Ordenar por',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Predeterminado')),
              DropdownMenuItem(value: 'price_asc', child: Text('Precio: Menor a Mayor')),
              DropdownMenuItem(value: 'price_desc', child: Text('Precio: Mayor a Menor')),
              DropdownMenuItem(value: 'duration_asc', child: Text('Duración: Corto a Largo')),
              DropdownMenuItem(value: 'duration_desc', child: Text('Duración: Largo a Corto')),
            ],
            onChanged: (value) {
              setState(() => _selectedSort = value);
              controller.setSorting(value);
            },
          ),
        ),
      ],
    );
  }
}