import 'package:flutter/material.dart';
import 'package:barber_xe/models/service_model.dart';

class ServiceCard extends StatelessWidget {
  final Service service;
  final VoidCallback? onReserve;

  const ServiceCard({
    super.key,
    required this.service,
    this.onReserve,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
      height: 100, // Altura más compacta
      margin: const EdgeInsets.only(bottom: 12), // Espaciado entre cards
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Sección de imagen
          Container(
            width: 90, // Ancho fijo para la imagen
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(10),
              ),
              color: Colors.grey[200],
            ),
            child: service.imageUrl != null
                ? ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(10),
                    ),
                    child: Image.network(
                      service.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholderIcon(),
                    ),
                  )
                : _buildPlaceholderIcon(),
          ),
          
          // Sección de contenido
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Nombre y precio
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          service.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.brown[800],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '\$${service.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 6),
                  
                  // Descripción y duración
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          service.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: theme.primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${service.duration} min',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Botón de reserva
                  /*SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: onReserve,
                      child: const Text(
                        'RESERVAR',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),*/
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return const Center(
      child: Icon(
        Icons.photo,
        color: Colors.grey,
        size: 30,
      ),
    );
  }
}