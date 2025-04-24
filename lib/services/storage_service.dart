import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  // Subir imagen genérica
  Future<String?> uploadImage({
    required File imageFile,
    required String folder, // Ejemplo: 'combos_images' o 'services_images'
  }) async {
    try {
      final fileName = _uuid.v4();
      final ref = _storage.ref().child('$folder/$fileName.jpg');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error al subir imagen: $e');
      return null;
    }
  }

  // Eliminar imagen genérica
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      print('Error al eliminar imagen: $e');
    }
  }

  // Subir imagen de perfil
  Future<String?> uploadProfileImage(String uid, XFile imageFile) async {
    try {
      final ref = _storage.ref().child('profile_images/$uid.jpg');
      await ref.putFile(File(imageFile.path));
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error al subir imagen de perfil: $e');
      return null;
    }
  }

  // Eliminar imagen de perfil
  Future<void> deleteProfileImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      print('Error al eliminar imagen de perfil: $e');
    }
  }
}
