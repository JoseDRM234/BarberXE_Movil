// pages/home/widgets/service_card.dart
import 'package:barber_xe/controllers/profile_controller.dart';
import 'package:barber_xe/controllers/services_controller.dart';
import 'package:barber_xe/pages/widget/service_management_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barber_xe/models/service_model.dart';

class ServiceCard extends StatelessWidget {
  final BarberService service; // Cambiaría si decides trabajar con combo aquí también

  const ServiceCard({super.key, required this.service});

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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit, size: 20),
          onPressed: () => _editService(context),
        ),
        IconButton(
          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
          onPressed: () => _deleteService(context),
        ),
      ],
    );
  }

  void _editService(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ServiceManagementDialog(serviceToEdit: service),
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
