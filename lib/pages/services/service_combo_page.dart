import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

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
  dynamic _imageFile;
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

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
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
          _imageUrl = null;
        });
      } else {
        setState(() {
          _imageFile = File(pickedFile.path);
          _imageUrl = null;
        });
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
        
        if (_imageFile != null) {
          // Eliminar imagen anterior si existe
          if (widget.combo?.imageUrl != null) {
            await storage.deleteImage(widget.combo!.imageUrl!);
          }
          
          // Subir nueva imagen
          newImageUrl = await storage.uploadServiceImage(_imageFile);
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
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.combo != null ? 'Editar Combo' : 'Nuevo Combo',
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
                label: 'Nombre del Combo',
                icon: Icons.assignment,
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _descController,
                label: 'Descripción',
                icon: Icons.description,
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              _buildServiceSelectionButton(),
              const SizedBox(height: 20),
              _buildSelectedServicesSection(),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: Text('Guardar Combo', style: GoogleFonts.poppins(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _saveCombo,
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
                  : const Column(
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

  Widget _buildServiceSelectionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.add_circle_outline),
        label: Text('Seleccionar Servicios', style: GoogleFonts.poppins()),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[100],
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.grey[300]!),
          ),
        ),
        onPressed: _selectServices,
      ),
    );
  }

  Widget _buildSelectedServicesSection() {
    return Consumer<ServiceController>(
      builder: (context, controller, _) {
        final services = controller.services
            .where((s) => _selectedServiceIds.contains(s.id))
            .toList();

        if (services.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'No hay servicios seleccionados',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Servicios incluidos (${services.length}):',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            ...services.map((service) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: service.imageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(service.imageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: service.imageUrl == null ? Colors.grey[200] : null,
                    ),
                    child: service.imageUrl == null
                        ? const Icon(Icons.cut, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${service.price.toStringAsFixed(2)} • ${service.duration} min',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => setState(
                      () => _selectedServiceIds.remove(service.id)),
                  ),
                ],
              ),
            )),
          ],
        );
      },
    );
  }

  ImageProvider _getImageProvider() {
    if (_imageUrl != null) return NetworkImage(_imageUrl!);
    if (kIsWeb) return MemoryImage(_imageFile as Uint8List);
    return FileImage(_imageFile as File);
  }
}