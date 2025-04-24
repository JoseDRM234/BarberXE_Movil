import 'package:barber_xe/models/service_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barber_xe/controllers/services_controller.dart';

class ServiceSelectionPage extends StatefulWidget {
  final List<String> initialSelectedIds;
  final bool isCombo;

  const ServiceSelectionPage({
    super.key,
    required this.initialSelectedIds,
    this.isCombo = false
  });

  @override
  State<ServiceSelectionPage> createState() => _ServiceSelectionPageState();
}

class _ServiceSelectionPageState extends State<ServiceSelectionPage> {
  late List<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.initialSelectedIds);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ServiceController>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isCombo ? 'Seleccionar Servicios para Combo' : 'Seleccionar Servicios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => Navigator.pop(context, _selectedIds),
          )
        ],
      ),
      body: _buildContent(controller),
    );
  }

  Widget _buildContent(ServiceController controller) {
    return FutureBuilder<List<BarberService>>(
      future: controller.getActiveServices(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final service = snapshot.data![index];
            return CheckboxListTile(
              title: Text(service.name),
              subtitle: Text('\$${service.price} - ${service.duration} min'),
              value: _selectedIds.contains(service.id),
              onChanged: (value) => _handleSelection(service.id, value!),
            );
          },
        );
      },
    );
  }

  void _handleSelection(String serviceId, bool selected) {
    setState(() {
      if (selected) {
        _selectedIds.add(serviceId);
      } else {
        _selectedIds.remove(serviceId);
      }
    });
  }
}