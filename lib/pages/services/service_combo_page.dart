import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:barber_xe/controllers/services_controller.dart';
import 'package:barber_xe/models/service_combo.dart';
import 'package:barber_xe/pages/services/service_selection_page.dart';
import 'package:barber_xe/services/storage_service.dart';

class ServiceComboPage extends StatefulWidget {
  final ServiceCombo? combo;

  const ServiceComboPage({super.key, this.combo});

  @override
  State<ServiceComboPage> createState() => _ServiceComboPageState();
}

class _ServiceComboPageState extends State<ServiceComboPage> {
  final _formKey = GlobalKey<FormState>();
  dynamic _imageFile; // Corrección: quitar el ? innecesario
  String? _imageUrl;
  late TextEditingController _nameController;
  late TextEditingController _descController;
  List<String> _selectedServiceIds = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.combo?.name ?? '');
    _descController = TextEditingController(text: widget.combo?.description ?? '');
    _selectedServiceIds = widget.combo?.serviceIds ?? [];
    _imageUrl = widget.combo?.imageUrl;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 600,
      imageQuality: 85,
    );
    
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() => _imageFile = bytes);
      } else {
        setState(() => _imageFile = File(pickedFile.path));
      }
    }
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
      final storage = Provider.of<StorageService>(context, listen: false);

      try {
        String? newImageUrl;
        print(_imageFile);
        if (_imageFile != null) {
        // Eliminar imagen anterior si existe
        if (widget.combo?.imageUrl != null) {
          await storage.deleteImage(widget.combo!.imageUrl);
        }
        
        // Subir nueva imagen
        newImageUrl = await storage.uploadImage(
          _imageFile,
          folder: 'combos'
        );
      }

        final updatedCombo = ServiceCombo(
          id: widget.combo?.id ?? '',
          name: _nameController.text,
          description: _descController.text,
          totalPrice: widget.combo?.totalPrice ?? 0.0,
          discount: widget.combo?.discount ?? 0.0,
          totalDuration: widget.combo?.totalDuration ?? 0,
          serviceIds: _selectedServiceIds,
          imageUrl: newImageUrl ?? widget.combo?.imageUrl,
          isActive: widget.combo?.isActive ?? true,
          createdAt: widget.combo?.createdAt ?? DateTime.now(),
        );

        if (widget.combo != null) {
          await controller.updateCombo(updatedCombo);
        } else {
          await controller.addCombo(
            name: _nameController.text,
            description: _descController.text,
            serviceIds: _selectedServiceIds,
            discount: 0.0,
            imageUrl: newImageUrl,
          );
        }
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
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
      body: _buildFormContent(),
    );
  }

  Widget _buildFormContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            _buildImageSection(),
            const SizedBox(height: 20),
            _buildNameField(),
            const SizedBox(height: 20),
            _buildDescriptionField(),
            const SizedBox(height: 20),
            _buildSelectedServicesSection(),
            const SizedBox(height: 20),
            _buildServiceSelectionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    if (_imageFile != null) {
      // Mostrar imagen seleccionada localmente (web o móvil)
      return kIsWeb
          ? Image.memory(_imageFile, height: 200, fit: BoxFit.cover)
          : Image.file(_imageFile, height: 200, fit: BoxFit.cover);
    } else if (_imageUrl != null) {
      // Mostrar imagen desde la URL ya almacenada
      return Image.network(_imageUrl!, height: 200, fit: BoxFit.cover);
    } else {
      return GestureDetector(
        onTap: _pickImage,
        child: Container(
          height: 200,
          color: Colors.grey[200],
          child: const Center(child: Text("Selecciona una imagen")),
        ),
      );
    }
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(labelText: 'Nombre del Combo'),
      validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descController,
      decoration: const InputDecoration(labelText: 'Descripción'),
      maxLines: 3,
    );
  }

  Widget _buildServiceSelectionButton() {
    return ElevatedButton(
      onPressed: _selectServices,
      child: const Text('Seleccionar Servicios'),
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
            const Text('Servicios incluidos:', 
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...services.map((service) => ListTile(
              leading: service.imageUrl != null
                  ? CircleAvatar(
                      backgroundImage: NetworkImage(service.imageUrl!),
                      radius: 20,
                    )
                  : const CircleAvatar(
                      radius: 20,
                      child: Icon(Icons.cut),
                    ),
              title: Text(service.name),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(
                  () => _selectedServiceIds.remove(service.id)),
              ),
            )),
            if (services.isEmpty)
              const Text('No hay servicios seleccionados',
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
          ],
        );
      },
    );
  }
}