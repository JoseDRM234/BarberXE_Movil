import 'dart:ui';

import 'package:barber_xe/pages/auth/widgets/Active_button.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:barber_xe/controllers/profile_controller.dart';
import 'package:barber_xe/controllers/services_controller.dart';
import 'package:barber_xe/models/service_model.dart';

class ServiceCard extends StatelessWidget {
  final BarberService service;
  final VoidCallback? onEdit;

  const ServiceCard({
    super.key, 
    required this.service,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = Provider.of<ProfileController>(context, listen: false).isAdmin;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10.0,
            spreadRadius: 0.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 5.0,
            sigmaY: 5.0,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fila superior
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Imagen del servicio
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.withOpacity(0.08),
                        ),
                        child: service.imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Opacity(
                                  opacity: 0.9,
                                  child: Image.network(
                                    service.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _buildPlaceholderIcon(),
                                  ),
                                ),
                              )
                            : _buildPlaceholderIcon(),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Detalles
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service.name,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black.withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '\$${service.price.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Descripción
                  Opacity(
                    opacity: 0.8,
                    child: Text(
                      service.description,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Fila inferior
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Duración
                      Opacity(
                        opacity: 0.9,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.grey[600]!.withOpacity(0.9),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${service.duration} min',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey[600]!.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Acciones de admin
                      if (isAdmin) _buildAdminActions(context),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Opacity(
      opacity: 0.7,
      child: Center(
        child: Icon(
          Icons.cut,
          size: 30,
          color: Colors.grey[300],
        ),
      ),
    );
  }

  Widget _buildAdminActions(BuildContext context) {
    final serviceController = Provider.of<ServiceController>(context, listen: false);

    return Opacity(
      opacity: 0.9,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botón de estado
          ActiveToggleButton(
            isActive: service.isActive,
            onChanged: (newValue) async {
              final updatedService = service.copyWith(isActive: newValue);
              await serviceController.updateService(updatedService);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      newValue ? 'Servicio activado' : 'Servicio desactivado',
                      style: GoogleFonts.poppins(),
                    ),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
          ),
          
          const SizedBox(width: 8),
          
          // Botón de edición
          IconButton(
            icon: Icon(Icons.edit, size: 20),
            color: Colors.blue[600]!.withOpacity(0.9),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: onEdit,
          ),
          
          // Botón de eliminación
          IconButton(
            icon: Icon(Icons.delete, size: 20),
            color: Colors.red[500]!.withOpacity(0.9),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: () => _deleteService(context),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteService(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.96),
        title: Text(
          'Confirmar eliminación',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black.withOpacity(0.9),
          ),
        ),
        content: Text(
          '¿Estás seguro de eliminar este servicio?',
          style: GoogleFonts.poppins(
            color: Colors.black.withOpacity(0.8),
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(
                color: Colors.grey[700]!.withOpacity(0.9),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Eliminar',
              style: GoogleFonts.poppins(
                color: Colors.red.withOpacity(0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final serviceController = Provider.of<ServiceController>(context, listen: false);
      try {
        await serviceController.deleteService(service.id);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error al eliminar: $e',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.red.withOpacity(0.9),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    }
  }
}