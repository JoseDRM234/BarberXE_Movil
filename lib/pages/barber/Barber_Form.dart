// pages/barbers/barber_form_dialog.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:barber_xe/models/barber_model.dart';
import 'dart:io';

class BarberFormDialog extends StatefulWidget {
  final Barber? barber;
  final Function(Barber) onSubmit;

  const BarberFormDialog({
    super.key,
    this.barber,
    required this.onSubmit,
  });

  @override
  State<BarberFormDialog> createState() => _BarberFormDialogState();
}

class _BarberFormDialogState extends State<BarberFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _startTimeController;
  late TextEditingController _endTimeController;
  String _status = 'active';
  List<int> _selectedDays = [];
  File? _imageFile;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.barber?.name ?? '');
    _descriptionController = TextEditingController(
        text: widget.barber?.shortDescription ?? '');
    _startTimeController = TextEditingController(
        text: widget.barber?.workingHours['start'] ?? '09:00');
    _endTimeController = TextEditingController(
        text: widget.barber?.workingHours['end'] ?? '18:00');
    _status = widget.barber?.status ?? 'active';
    _selectedDays = widget.barber?.workingDays ?? [];
    _photoUrl = widget.barber?.photoUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.barber == null ? 'Agregar Barbero' : 'Editar Barbero',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Sección de imagen
                _buildImageSection(),
                const SizedBox(height: 20),
                
                // Campo de nombre
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre completo',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (value) => value!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                
                // Selector de estado
                DropdownButtonFormField<String>(
                  value: _status,
                  items: const [
                    DropdownMenuItem(
                      value: 'active',
                      child: Text('Activo', style: TextStyle(color: Colors.green)),
                    ),
                    DropdownMenuItem(
                      value: 'inactive',
                      child: Text('Inactivo', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                  onChanged: (value) => setState(() => _status = value!),
                  decoration: InputDecoration(
                    labelText: 'Estado',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Días de trabajo
                const Text(
                  'Días de trabajo:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                _buildDaySelection(),
                const SizedBox(height: 16),
                
                // Horario
                const Text(
                  'Horario de trabajo:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _startTimeController,
                        decoration: InputDecoration(
                          labelText: 'Hora inicio',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _endTimeController,
                        decoration: InputDecoration(
                          labelText: 'Hora fin',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Descripción
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Descripción breve',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                
                // Botones de acción
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _submitForm,
                        child: const Text(
                          'Guardar',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[200],
                border: Border.all(color: Colors.grey[300]!, width: 2),
                image: _imageFile != null
                    ? DecorationImage(
                        image: FileImage(_imageFile!),
                        fit: BoxFit.cover,
                      )
                    : _photoUrl != null
                        ? DecorationImage(
                            image: NetworkImage(_photoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
              ),
              child: _imageFile == null && _photoUrl == null
                  ? const Icon(Icons.person, size: 50, color: Colors.grey)
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  onPressed: _pickImage,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _pickImage,
          child: const Text(
            'Cambiar foto',
            style: TextStyle(color: Colors.black54),
          ),
        ),
      ],
    );
  }

  Widget _buildDaySelection() {
    final days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return Wrap(
      spacing: 8,
      children: List.generate(7, (index) {
        return ChoiceChip(
          label: Text(days[index]),
          selected: _selectedDays.contains(index),
          selectedColor: Colors.black,
          labelStyle: TextStyle(
            color: _selectedDays.contains(index) ? Colors.white : Colors.black,
          ),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedDays.add(index);
              } else {
                _selectedDays.remove(index);
              }
            });
          },
        );
      }),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final barber = Barber(
        id: widget.barber?.id ?? '',
        name: _nameController.text,
        status: _status,
        workingDays: _selectedDays,
        workingHours: {
          'start': _startTimeController.text,
          'end': _endTimeController.text,
        },
        rating: 0.0, // Inicializado en 0, se calificará después
        shortDescription: _descriptionController.text,
        photoUrl: _photoUrl, // Aquí deberías subir el archivo _imageFile si existe
      );
      widget.onSubmit(barber);
      Navigator.pop(context);
    }
  }
}