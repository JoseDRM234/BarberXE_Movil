import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:barber_xe/models/barber_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';

class BarberFormDialog extends StatefulWidget {
  final Barber? barber;
  final Function(Barber) onSubmit;

  const BarberFormDialog({super.key, this.barber, required this.onSubmit});

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
      text: widget.barber?.shortDescription ?? '',
    );
    _startTimeController = TextEditingController(
      text: widget.barber?.workingHours['start'] ?? '09:00',
    );
    _endTimeController = TextEditingController(
      text: widget.barber?.workingHours['end'] ?? '18:00',
    );
    _status = widget.barber?.status ?? 'active';
    _selectedDays = widget.barber?.workingDays ?? [];
    _photoUrl = widget.barber?.photoUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 24),
                    color: const Color.fromARGB(255, 0, 0, 0),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Center(
                  child: Text(
                    widget.barber == null
                        ? 'Agregar Barbero'
                        : 'Editar Barbero',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Sección de imagen
                _buildImageSection(),
                const SizedBox(height: 20),

                // Campo de nombre
                _buildTextField(
                  controller: _nameController,
                  label: 'Nombre completo',
                  icon: Icons.person,
                  validator: (value) => value!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),

                // Selector de estado
                _buildStatusDropdown(),
                const SizedBox(height: 16),

                // Días de trabajo
                Text(
                  'Días de trabajo:',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                _buildDaySelection(),
                const SizedBox(height: 16),

                // Horario
                Text(
                  'Horario de trabajo:',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _startTimeController,
                        label: 'Hora inicio',
                        icon: Icons.access_time,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _endTimeController,
                        label: 'Hora fin',
                        icon: Icons.access_time,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Descripción
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Descripción breve',
                  icon: Icons.description,
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // Botón de guardar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save, size: 20),
                    label: Text(
                      'Guardar Barbero',
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _submitForm,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child:
                    (_photoUrl != null || _imageFile != null)
                        ? Image(
                          image:
                              _imageFile != null
                                  ? FileImage(_imageFile!)
                                  : NetworkImage(_photoUrl!) as ImageProvider,
                          fit: BoxFit.cover,
                        )
                        : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Agregar foto',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySelection() {
    final days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return Wrap(
      spacing: 8,
      children: List.generate(7, (index) {
        return ChoiceChip(
          label: Text(
            days[index],
            style: GoogleFonts.poppins(
              color:
                  _selectedDays.contains(index) ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          selected: _selectedDays.contains(index),
          selectedColor: Colors.black,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedDays.add(index);
              } else {
                _selectedDays.remove(index);
              }
            });
          },
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        );
      }),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: _status,
      items: [
        DropdownMenuItem(
          value: 'active',
          child: Text(
            'Activo',
            style: GoogleFonts.poppins(
              color: Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        DropdownMenuItem(
          value: 'inactive',
          child: Text(
            'Inactivo',
            style: GoogleFonts.poppins(
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
      onChanged: (value) => setState(() => _status = value!),
      style: GoogleFonts.poppins(
        fontSize: 15,
        color: Colors.black87,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: 'Estado',
        labelStyle: GoogleFonts.poppins(
          color: Colors.grey[600],
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
        prefixIcon: Icon(
          Icons.circle,
          color: _status == 'active' ? Colors.green : Colors.red,
          size: 20,
        ),
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Colors.black87.withOpacity(0.7),
            width: 1.2,
          ),
        ),
      ),
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
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Colors.black87.withOpacity(0.7),
            width: 1.2,
          ),
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
        rating: 0.0,
        shortDescription: _descriptionController.text,
        photoUrl: _photoUrl,
      );
      widget.onSubmit(barber);
      Navigator.pop(context);
    }
  }
}
