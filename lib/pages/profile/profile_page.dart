import 'package:barber_xe/controllers/profile_controller.dart';
import 'package:barber_xe/main.dart';
import 'package:barber_xe/pages/profile/widgets/admin_panel.dart';
import 'package:barber_xe/pages/profile/widgets/profile_form.dart';
import 'package:barber_xe/pages/profile/widgets/profile_header.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mi Perfil',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
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
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            );
          }
          
          if (controller.currentUser == null) {
            return Center(
              child: Text(
                'No se pudo cargar el perfil',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
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
    if (controller.isEditing) {
      return const SizedBox.shrink();
    }

    return FilledButton(
      onPressed: () {
        controller.toggleEditMode();
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
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          letterSpacing: 1.2,
          color: Colors.white,
        ),
      ),
    );
  }
}