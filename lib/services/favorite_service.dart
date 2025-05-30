import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> toggleFavorite(String userId, String barberId) async {
    final userRef = _db.collection('users').doc(userId);
    
    try {
      await _db.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        
        // Manejo seguro del campo favoriteBarbers
        final currentFavorites = _safeGetFavorites(userDoc);
        
        if (currentFavorites.contains(barberId)) {
          transaction.update(userRef, {
            'favoriteBarbers': FieldValue.arrayRemove([barberId]),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.update(userRef, {
            'favoriteBarbers': FieldValue.arrayUnion([barberId]),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      print('Error en toggleFavorite: $e');
      throw Exception('No se pudo actualizar los favoritos');
    }
  }

  Future<List<String>> getUserFavorites(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      return _safeGetFavorites(doc);
    } catch (e) {
      print('Error en getUserFavorites: $e');
      return [];
    }
  }

  // Método privado para manejo seguro de los favoritos
  List<String> _safeGetFavorites(DocumentSnapshot doc) {
    try {
      if (!doc.exists) return [];
      
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return [];
      
      // Verificamos que el campo exista y sea una lista
      if (!data.containsKey('favoriteBarbers')) return [];
      
      final favorites = data['favoriteBarbers'];
      if (favorites is! List) return [];
      
      return List<String>.from(favorites.whereType<String>());
    } catch (e) {
      print('Error al obtener favoritos: $e');
      return [];
    }
  }

  // Método opcional para inicializar el campo si no existe
  Future<void> initializeFavoritesField(String userId) async {
    await _db.collection('users').doc(userId).set({
      'favoriteBarbers': [],
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}