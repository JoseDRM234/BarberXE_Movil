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
    // Cargar el perfil automáticamente al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<ProfileController>(context, listen: false);
      controller.loadCurrentUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ProfileController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await controller.logout();
              // Forzar recarga completa
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
            return const Center(
              child: Text('No se pudo cargar el perfil'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const ProfileHeader(),
                const SizedBox(height: 20),
                ProfileForm(formKey: GlobalKey<FormState>()),
                if (controller.isAdmin) const AdminPanel(),
              ],
            ),
          );
        },
      ),
    );
  }
}