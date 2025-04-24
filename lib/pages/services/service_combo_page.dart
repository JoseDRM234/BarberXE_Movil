import 'package:barber_xe/controllers/services_controller.dart';
import 'package:barber_xe/models/service_combo.dart';
import 'package:barber_xe/pages/services/service_selection_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ServiceComboPage extends StatefulWidget {
  final ServiceCombo? combo;

  const ServiceComboPage({super.key, this.combo});

  @override
  State<ServiceComboPage> createState() => _ServiceComboPageState();
}

class _ServiceComboPageState extends State<ServiceComboPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  List<String> _selectedServiceIds = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.combo?.name ?? '');
    _descController = TextEditingController(text: widget.combo?.description ?? '');
    _selectedServiceIds = widget.combo?.serviceIds ?? [];
  }

  Future<void> _selectServices() async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceSelectionPage(
          initialSelectedIds: _selectedServiceIds,
          isCombo: true,
        ),
      ),
    );

    if (result != null) {
      setState(() => _selectedServiceIds = result);
    }
  }

  Future<void> _saveCombo() async {
    if (_formKey.currentState!.validate()) {
      final controller = Provider.of<ServiceController>(context, listen: false);
      
      try {
        if (widget.combo != null) {
          await controller.updateCombo(
            widget.combo!.copyWith(
              name: _nameController.text,
              description: _descController.text,
              serviceIds: _selectedServiceIds,
            ),
          );
        } else {
          await controller.addCombo(
            name: _nameController.text,
            description: _descController.text,
            serviceIds: _selectedServiceIds,
            discount: 0.0,
          );
        }
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.combo != null ? 'Editar Combo' : 'Nuevo Combo'),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _saveCombo)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre del Combo'),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 20), // Espacio agregado
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 3,
              ),
              const SizedBox(height: 20), // Espacio agregado
              _buildSelectedServicesSection(),
              const SizedBox(height: 20), // Espacio agregado
              ElevatedButton(
                onPressed: _selectServices,
                child: const Text('Seleccionar Servicios'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedServicesSection() {
    return Consumer<ServiceController>(
      builder: (context, controller, _) {
        final services = controller.services
            .where((s) => _selectedServiceIds.contains(s.id))
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Servicios incluidos:'),
            ...services.map((service) => ListTile(
              title: Text(service.name),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(
                  () => _selectedServiceIds.remove(service.id)),
              ),
            )),
            if (services.isEmpty)
              const Text('No hay servicios seleccionados',
                style: TextStyle(color: Colors.grey)),
          ],
        );
      },
    );
  }
}