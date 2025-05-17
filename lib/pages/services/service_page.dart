import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

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
    if (kIsWeb) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageFile = bytes;
        _imageUrl = null; // limpiar URL para mostrar la nueva imagen local
      });
    } else {
      setState(() {
        _imageFile = File(pickedFile.path);
        _imageUrl = null; // limpiar URL para mostrar la nueva imagen local
      });
    }
  }
}


  Future<void> _saveService() async {
    if (_formKey.currentState!.validate()) {
      final controller = Provider.of<ServiceController>(context, listen: false);
      final storage = Provider.of<StorageService>(context, listen: false);

      try {
        if (_imageFile != null) {
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
    final textStyle = GoogleFonts.poppins(fontSize: 16);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.service != null ? 'Editar Servicio' : 'Nuevo Servicio',
          style: GoogleFonts.poppins(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildImageSection(),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _nameController,
                label: 'Nombre del Servicio',
                icon: Icons.cut,
                validator: (value) =>
                    value!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _descController,
                label: 'Descripción',
                icon: Icons.description,
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _priceController,
                label: 'Precio',
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Campo requerido';
                  if (double.tryParse(value) == null) return 'Número inválido';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _durationController,
                label: 'Duración (minutos)',
                icon: Icons.timer,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Campo requerido';
                  if (int.tryParse(value) == null) return 'Número inválido';
                  return null;
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: Text('Guardar Servicio', style: GoogleFonts.poppins(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _saveService,
                ),
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
      GestureDetector(
        onTap: _pickImage,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.grey[200],
            ),
            child: (_imageUrl != null || _imageFile != null)
                ? Image(
                    image: _getImageProvider(),
                    fit: BoxFit.cover,
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Agregar imagen', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
          ),
        ),
      ),
      const SizedBox(height: 10)
    ],
  );
}

Widget _buildTextField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  TextInputType? keyboardType,
  int maxLines = 1,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    maxLines: maxLines,
    validator: validator,
    style: GoogleFonts.poppins(
      fontSize: 15,
      color: Colors.black87,
      fontWeight: FontWeight.w500,
    ),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(
        color: Colors.grey[600],
        fontWeight: FontWeight.w400,
        fontSize: 14,
      ),
      prefixIcon: Icon(icon, color: Colors.grey[500], size: 20),
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.black87.withOpacity(0.7), width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    ),
  );
}


  ImageProvider _getImageProvider() {
    if (_imageUrl != null) return NetworkImage(_imageUrl!);
    if (kIsWeb) return MemoryImage(_imageFile as Uint8List);
    return FileImage(_imageFile as File);
  }
}
