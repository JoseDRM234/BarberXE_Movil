import 'package:barber_xe/models/profile_data.dart';
import 'package:barber_xe/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/profile_controller.dart';

class ProfileForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  const ProfileForm({super.key, required this.formKey});

  @override
  ProfileFormState createState() => ProfileFormState();
}

class ProfileFormState extends State<ProfileForm> {
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserData();
  }

  void _loadUserData() {
    final user = Provider.of<ProfileController>(context, listen: false).currentUser;
    if (user != null) {
      _updateControllers(user);
    }
  }

  void _updateControllers(UserModel user) {
    _nombreController.text = user.nombre ?? '';
    _apellidoController.text = user.apellido ?? '';
    _telefonoController.text = user.telefono ?? '';
  }

  ProfileData getProfileData() {
    return ProfileData(
      nombre: _nombreController.text.trim(),
      apellido: _apellidoController.text.trim(),
      telefono: _telefonoController.text.trim(),
      password: _passwordController.text.isNotEmpty 
          ? _passwordController.text.trim() 
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ProfileController>(context);
    final isEditing = controller.isEditing;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: widget.formKey,
          onWillPop: () async => _handleWillPop(context, controller, isEditing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(controller, isEditing),
              const SizedBox(height: 24),
              _buildPersonalInfoSection(isEditing),
              if (isEditing) _buildPasswordSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(ProfileController controller, bool isEditing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Información personal',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        if (isEditing)
          TextButton.icon(
            icon: const Icon(Icons.save_rounded, size: 20, color: Colors.black),
            label: const Text('Guardar', style: TextStyle(color: Colors.black)),
            style: TextButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              if (widget.formKey.currentState!.validate()) {
                controller.updateProfile(getProfileData());
              }
            },
          ),
      ],
    );
  }

  Widget _buildPersonalInfoSection(bool isEditing) {
    return Column(
      children: [
        _buildTextField(
          controller: _nombreController,
          label: 'Nombre',
          icon: Icons.person_outline_rounded,
          enabled: isEditing,
          validator: (value) => _validateRequiredField(value, isEditing),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _apellidoController,
          label: 'Apellido',
          icon: Icons.person_outline_rounded,
          enabled: isEditing,
          validator: (value) => _validateRequiredField(value, isEditing),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _telefonoController,
          label: 'Teléfono',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          enabled: isEditing,
          validator: (value) => _validatePhoneField(value, isEditing),
        ),
      ],
    );
  }

  Widget _buildPasswordSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Cambiar contraseña',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _passwordController,
          label: 'Nueva contraseña',
          icon: Icons.lock_outline_rounded,
          obscureText: true,
          validator: (value) => _validatePasswordField(value),
        ),
        const SizedBox(height: 8),
        const Text(
          'Dejar en blanco para mantener la actual',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: !enabled,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      validator: validator,
    );
  }

  String? _validateRequiredField(String? value, bool isEditing) {
    if (isEditing && (value == null || value.isEmpty)) {
      return 'Este campo es requerido';
    }
    return null;
  }

  String? _validatePhoneField(String? value, bool isEditing) {
    if (isEditing && value != null && value.isNotEmpty && !RegExp(r'^[0-9]{10,15}$').hasMatch(value)) {
      return 'Teléfono inválido (10-15 dígitos)';
    }
    return null;
  }

  String? _validatePasswordField(String? value) {
    if (value != null && value.isNotEmpty && value.length < 6) {
      return 'Mínimo 6 caracteres';
    }
    return null;
  }

  Future<bool> _handleWillPop(BuildContext context, ProfileController controller, bool isEditing) async {
    if (isEditing) {
      final shouldPop = await _showDiscardChangesDialog(context);
      if (shouldPop) {
        controller.toggleEditMode();
      }
      return false;
    }
    return true;
  }

  Future<bool> _showDiscardChangesDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descartar cambios', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('¿Estás seguro de que quieres descartar los cambios no guardados?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Descartar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}