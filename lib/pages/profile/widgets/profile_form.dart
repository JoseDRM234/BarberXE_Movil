import 'package:barber_xe/models/user_model.dart';
import 'package:barber_xe/pages/widget/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/profile_controller.dart';
import '../../../models/profile_data.dart' as model;

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
    // Recargar datos cuando el usuario cambie
    final user = Provider.of<ProfileController>(context).currentUser;
    if (user != null) {
      _updateControllers(user);
    }
  }

  void _loadUserData() {
  final user = Provider.of<ProfileController>(context, listen: false).currentUser;
  if (user != null) {
    _nombreController.text = user.nombre ?? '';
    _apellidoController.text = user.apellido ?? '';
    _telefonoController.text = user.telefono ?? '';
  }
}

  void _updateControllers(UserModel user) {
    _nombreController.text = user.nombre ?? '';
    _apellidoController.text = user.apellido ?? '';
    _telefonoController.text = user.telefono ?? '';
  }

  // Método para obtener los datos del formulario
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

    return Form(
      key: widget.formKey,
      onWillPop: () async {
        if (isEditing) {
          final shouldPop = await _showDiscardChangesDialog(context);
          if (shouldPop) {
            controller.toggleEditMode();
          }
          return false;
        }
        return true;
      },
      child: Column(
        children: [
          CustomTextField(
            controller: _nombreController,
            label: 'Nombre',
            icon: Icons.person,
            enabled: isEditing,
            validator: (value) {
              if (isEditing && (value == null || value.isEmpty)) {
                return 'Ingrese su nombre';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _apellidoController,
            label: 'Apellido',
            icon: Icons.person_outline,
            enabled: isEditing,
            validator: (value) {
              if (isEditing && (value == null || value.isEmpty)) {
                return 'Ingrese su apellido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _telefonoController,
            label: 'Teléfono',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            enabled: isEditing,
            validator: (value) {
              if (isEditing && value != null && value.isNotEmpty && !RegExp(r'^[0-9]{10,15}$').hasMatch(value)) {
                return 'Ingrese un teléfono válido (10-15 dígitos)';
              }
              return null;
            },
          ),
          if (isEditing) ...[
            const SizedBox(height: 24),
            const Text(
              'Cambiar Contraseña',
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _passwordController,
              label: 'Nueva Contraseña',
              icon: Icons.lock,
              obscureText: true,
              validator: (value) {
                if (isEditing && value != null && value.isNotEmpty && value.length < 6) {
                  return 'La contraseña debe tener al menos 6 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'Dejar en blanco para no cambiar',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Future<bool> _showDiscardChangesDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descartar cambios'),
        content: const Text('¿Estás seguro de que quieres descartar los cambios?'),
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