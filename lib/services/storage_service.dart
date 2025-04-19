import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadProfileImage(String uid, XFile image) async {
    try {
      final ref = _storage.ref().child('profile_images/$uid');
      await ref.putFile(File(image.path));
      return await ref.getDownloadURL();
    } catch (e) {
      print("Error al subir imagen: $e");
      return null;
    }
  }

  Future<void> deleteProfileImage(String? url) async {
    if (url != null) {
      try {
        await _storage.refFromURL(url).delete();
      } catch (e) {
        print("Error al eliminar imagen: $e");
      }
    }
  }
}