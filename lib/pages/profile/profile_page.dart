import 'package:barber_xe/controllers/profile_controller.dart';
import 'package:barber_xe/main.dart';
import 'package:barber_xe/pages/profile/widgets/admin_panel.dart';
import 'package:barber_xe/pages/profile/widgets/profile_form.dart';
import 'package:barber_xe/pages/profile/widgets/profile_header.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<ProfileController>(context, listen: false);
      controller.loadCurrentUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        centerTitle: true,
        backgroundColor: Colors.black, // AppBar en color negro
        foregroundColor: Colors.white, // Iconos y texto en blanco
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              final controller = Provider.of<ProfileController>(context, listen: false);
              await controller.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const AuthChecker()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Consumer<ProfileController>(
        builder: (context, controller, _) {
          if (controller.isLoading && controller.currentUser == null) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (controller.currentUser == null) {
            return Center(
              child: Text(
                'No se pudo cargar el perfil',
                style: theme.textTheme.bodyLarge,
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const ProfileHeader(),
                const SizedBox(height: 24),
                ProfileForm(formKey: GlobalKey<FormState>()),
                if (controller.isAdmin) const AdminPanel(),
                const SizedBox(height: 20),
                _buildEditSaveButton(controller, context),
              ],
            ),
          );
        },
      ),
    );
  }

 Widget _buildEditSaveButton(ProfileController controller, BuildContext context) {
  final theme = Theme.of(context);

  if (controller.isEditing) {
    // No mostramos el botón cuando está en modo edición
    return const SizedBox.shrink();
  }

  // Mostrar solo el botón "EDITAR PERFIL"
  return FilledButton(
    onPressed: () {
      controller.toggleEditMode(); // Cambia a modo edición
    },
    style: FilledButton.styleFrom(
      backgroundColor: Colors.grey[800],
      minimumSize: const Size(double.infinity, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    child: Text(
      'EDITAR PERFIL',
      style: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: Colors.white,
      ),
    ),
  );
}

}