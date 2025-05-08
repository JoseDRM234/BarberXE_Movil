import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  

  // Subir imagen genérica
  Future<String?> uploadServiceImage(dynamic imageFile) async {
    try {
      final ref = _storage.ref()
        .child('services_images')
        .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      if (kIsWeb) {
        await ref.putData(imageFile as Uint8List);
      } else {
        await ref.putFile(imageFile as File);
      }
      
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error al subir imagen: $e');
      return null;
    }
  }

  Future<String?> uploadComboImage(dynamic imageFile) async {
      return uploadImage(imageFile, folder: 'combos_images'); // ✅ Usa el método correcto
  }

    Future<String?> uploadBarberImage(dynamic imageFile) async {
      return uploadImage(imageFile, folder: 'barber_images'); // ✅ Usa el método correcto
  }

  Future<String?> uploadImage(dynamic imageFile, {String? folder}) async {
    try {
      final ref = _storage.ref().child(
        '${folder ?? 'general'}/${DateTime.now().millisecondsSinceEpoch}.jpg'
      );

      if (kIsWeb) {
        await ref.putData(imageFile as Uint8List);
      } else {
        await ref.putFile(imageFile as File);
      }
      
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error al subir imagen: $e');
      return null;
    }
  }

  // Eliminar imagen genérica
  Future<void> deleteImage(String? url) async {
    if (url == null) return;
    try {
      await _storage.refFromURL(url).delete();
    } catch (e) {
      print('Error eliminando imagen: $e');
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
