import 'package:barber_xe/controllers/profile_controller.dart';
import 'package:barber_xe/controllers/services_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barber_xe/models/service_model.dart';

class ServiceCard extends StatelessWidget {
  final BarberService service;
  final VoidCallback? onEdit; // Parámetro añadido

  const ServiceCard({
    super.key, 
    required this.service,
    this.onEdit, // Añadir al constructor
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = Provider.of<ProfileController>(context, listen: false).isAdmin;
    
    return Card(
      child: ListTile(
        title: Text(service.name),
        subtitle: Text(service.description),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('\$${service.price.toStringAsFixed(2)}'),
            if (isAdmin) _buildAdminActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminActions(BuildContext context) {
  return Container(
    constraints: const BoxConstraints(maxHeight: 40), // Altura máxima
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit),
          iconSize: 18, // Tamaño reducido
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          onPressed: onEdit,
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          iconSize: 18, // Tamaño reducido
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
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de eliminar este servicio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final serviceController = Provider.of<ServiceController>(context, listen: false);
      try {
        await serviceController.deleteService(service.id);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e')),
        );
      }
    }
  }
}