
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barber_xe/controllers/services_controller.dart';
import 'package:barber_xe/models/service_model.dart';

class ServicePage extends StatefulWidget {
  final BarberService? service;

  const ServicePage({super.key, this.service});

  @override
  State<ServicePage> createState() => _ServicePageState();
}

class _ServicePageState extends State<ServicePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _durationController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.service?.name ?? '');
    _descController = TextEditingController(text: widget.service?.description ?? '');
    _priceController = TextEditingController(
      text: widget.service?.price.toString() ?? '');
    _durationController = TextEditingController(
      text: widget.service?.duration.toString() ?? '');
  }

  Future<void> _saveService() async {
    if (_formKey.currentState!.validate()) {
      final controller = Provider.of<ServiceController>(context, listen: false);
      
      final newService = BarberService(
        id: widget.service?.id ?? '',
        name: _nameController.text,
        description: _descController.text,
        price: double.parse(_priceController.text),
        duration: int.parse(_durationController.text),
        category: 'hair', // Puedes agregar un selector de categoría
      );

      try {
        if (widget.service != null) {
          await controller.updateService(newService);
        } else {
          await controller.addService(newService);
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
        title: Text(widget.service != null ? 'Editar Servicio' : 'Nuevo Servicio'),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _saveService)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre del Servicio'),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 20), // Espacio agregado
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 3,
              ),
              const SizedBox(height: 20), // Espacio agregado
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Precio'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Campo requerido';
                  if (double.tryParse(value) == null) return 'Número inválido';
                  return null;
                },
              ),
              const SizedBox(height: 20), // Espacio agregado
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(labelText: 'Duración (minutos)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Campo requerido';
                  if (int.tryParse(value) == null) return 'Número inválido';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}