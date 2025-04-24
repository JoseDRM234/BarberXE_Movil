
import 'package:barber_xe/controllers/services_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barber_xe/models/service_model.dart';

class ServiceManagementDialog extends StatefulWidget {
  final Service? serviceToEdit;

  const ServiceManagementDialog({super.key, this.serviceToEdit});

  @override
  State<ServiceManagementDialog> createState() => _ServiceManagementDialogState();
}

class _ServiceManagementDialogState extends State<ServiceManagementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  
  String? _selectedCategory;
  bool _isCombo = false;
  final List<String> _categories = ['Corte', 'Barba', 'Facial', 'Combo', 'Otro'];

  @override
  void initState() {
    super.initState();
    if (widget.serviceToEdit != null) {
      _initializeFormWithServiceData();
    }
  }

  void _initializeFormWithServiceData() {
    final service = widget.serviceToEdit!;
    _nameController.text = service.name;
    _descriptionController.text = service.description;
    _priceController.text = service.price.toString();
    _durationController.text = service.duration.toString();
    _selectedCategory = service.category;
    _isCombo = service.isCombo;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.serviceToEdit == null 
                  ? 'Agregar Nuevo Servicio' 
                  : 'Editar Servicio',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            _buildNameField(),
            _buildDescriptionField(),
            _buildPriceField(),
            _buildDurationField(),
            _buildCategoryDropdown(),
            _buildComboCheckbox(),
            const SizedBox(height: 20),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(labelText: 'Nombre del servicio'),
      validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(labelText: 'Descripción'),
      maxLines: 2,
    );
  }

  Widget _buildPriceField() {
    return TextFormField(
      controller: _priceController,
      decoration: const InputDecoration(labelText: 'Precio'),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value?.isEmpty ?? true) return 'Campo requerido';
        if (double.tryParse(value!) == null) return 'Ingrese un número válido';
        return null;
      },
    );
  }

  Widget _buildDurationField() {
    return TextFormField(
      controller: _durationController,
      decoration: const InputDecoration(labelText: 'Duración (minutos)'),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value?.isEmpty ?? true) return 'Campo requerido';
        if (int.tryParse(value!) == null) return 'Ingrese un número válido';
        return null;
      },
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      items: _categories.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Text(category),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value;
          _isCombo = value == 'Combo';
        });
      },
      decoration: const InputDecoration(labelText: 'Categoría'),
      validator: (value) => value == null ? 'Seleccione una categoría' : null,
    );
  }

  Widget _buildComboCheckbox() {
    return CheckboxListTile(
      title: const Text('Es un combo'),
      value: _isCombo,
      onChanged: (value) => setState(() => _isCombo = value ?? false),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () => _saveService(context),
          child: Text(widget.serviceToEdit == null ? 'Agregar' : 'Guardar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
          ),
        ),
      ],
    );
  }

  Future<void> _saveService(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final serviceController = Provider.of<ServiceController>(context, listen: false);
      
      final service = Service(
        id: widget.serviceToEdit?.id ?? '',
        name: _nameController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        duration: int.parse(_durationController.text),
        category: _selectedCategory ?? 'Otro',
        isCombo: _isCombo,
        isActive: true,
      );
      
      try {
        if (widget.serviceToEdit != null) {
          await serviceController.updateService(service);
        } else {
          await serviceController.addService(service);
        }
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }
}