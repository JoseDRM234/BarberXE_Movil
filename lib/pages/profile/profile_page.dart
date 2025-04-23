import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/profile_controller.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_form.dart';
import 'widgets/admin_panel.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final GlobalKey<FormState> profileFormKey = GlobalKey<FormState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Provider.of<ProfileController>(context, listen: false).logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
          Consumer<ProfileController>(
            builder: (context, controller, _) {
              return IconButton(
                icon: Icon(controller.isEditing ? Icons.save : Icons.edit),
                onPressed: () async {
                if (controller.isEditing) {
                  if (profileFormKey.currentState?.validate() ?? false) {
                    final profileForm = context.findAncestorStateOfType<ProfileFormState>();
                    if (profileForm != null) {
                      final profileData = profileForm.getProfileData();
                      await controller.updateProfile(profileData);
                    }
                  }
                } else {
                  controller.toggleEditMode();
                }
              },
              );
            },
          ),
        ],
      ),
      body: Consumer<ProfileController>(
        builder: (context, controller, _) {
          if (controller.currentUser == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.currentUser == null) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Error al cargar el perfil'),
                ElevatedButton(
                  onPressed: controller.loadCurrentUser,
                  child: const Text('Reintentar'),
                ),
              ],
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const ProfileHeader(),
                const SizedBox(height: 20),
                ProfileForm(formKey: profileFormKey),
                if (controller.isAdmin) const AdminPanel(),
              ],
            ),
          );
        },
      ),
    );
  }
}