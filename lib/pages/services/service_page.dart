import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:barber_xe/controllers/services_controller.dart';
import 'package:barber_xe/models/service_model.dart';
import 'package:barber_xe/services/storage_service.dart';

class ServicePage extends StatefulWidget {
  final BarberService? service;

  const ServicePage({super.key, this.service});

  @override
  State<ServicePage> createState() => _ServicePageState();
}

class _ServicePageState extends State<ServicePage> {
  final _formKey = GlobalKey<FormState>();
  dynamic _imageFile;
  String? _imageUrl;
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
    _imageUrl = widget.service?.imageUrl;
  }

    Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      if (kIsWeb) { // Para versión web
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageFile = bytes;
        });
      } else { // Para móvil
        setState(() => _imageFile = File(pickedFile.path));
      }
    }
  }

  Future<void> _saveService() async {
    if (_formKey.currentState!.validate()) {
      final controller = Provider.of<ServiceController>(context, listen: false);
      final storage = Provider.of<StorageService>(context, listen: false);
      
      try {
        // Subir nueva imagen si existe
        print(_imageFile);
        if (_imageFile != null) {
          // Eliminar imagen anterior si existe
          if (widget.service?.imageUrl != null) {
            await storage.deleteImage(widget.service!.imageUrl!);
          }
          
          _imageUrl = await storage.uploadServiceImage(_imageFile);
        }

        final newService = BarberService(
          id: widget.service?.id ?? '',
          name: _nameController.text,
          description: _descController.text,
          price: double.parse(_priceController.text),
          duration: int.parse(_durationController.text),
          category: 'hair',
          imageUrl: _imageUrl ?? widget.service?.imageUrl,
        );

        if (widget.service != null) {
          await controller.updateService(newService);
        } else {
          await controller.addService(newService);
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
        title: Text(widget.service != null ? 'Editar Servicio' : 'Nuevo Servicio'),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _saveService)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildImageSection(),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre del Servicio'),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
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
              const SizedBox(height: 20),
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

  Widget _buildImageSection() {
    return Column(
      children: [
        if (_imageUrl != null || _imageFile != null)
          Container(
            width: 120, // Hacer contenedor cuadrado
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: _getImageProvider(),
                fit: BoxFit.cover,
              ),
            ),
          ),
        TextButton.icon(
          icon: const Icon(Icons.camera_alt),
          label: Text(_imageUrl == null 
              ? 'Agregar imagen'  // Corregir texto de combo a servicio
              : 'Cambiar imagen'),
          onPressed: _pickImage,
        ),
      ],
    );
  }

  ImageProvider _getImageProvider() {
    if (_imageUrl != null) return NetworkImage(_imageUrl!);
    if (kIsWeb) return MemoryImage(_imageFile as Uint8List);
    return FileImage(_imageFile as File);
  }
}