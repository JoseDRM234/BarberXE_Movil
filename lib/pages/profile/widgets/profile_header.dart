import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart'; // Asegúrate de importar esto
import '../../../controllers/profile_controller.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  Future<void> _pickImage(BuildContext context) async {
    final controller = Provider.of<ProfileController>(context, listen: false);
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      await controller.uploadProfileImage(pickedFile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ProfileController>(context);
    final user = controller.currentUser;
    final isEditing = controller.isEditing;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1.5,
                  ),
                  image: user?.photoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(user!.photoUrl!),
                          fit: BoxFit.cover,
                        )
                      : const DecorationImage(
                          image: AssetImage('assets/default_avatar.png'),
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              if (isEditing)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: InkWell(
                    onTap: () => _pickImage(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            user?.fullName ?? 'Sin nombre',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user?.email ?? '',
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: Colors.grey.shade600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}