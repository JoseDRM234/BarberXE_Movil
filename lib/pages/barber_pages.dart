// pages/barbers/barbers_page.dart
import 'package:barber_xe/pages/Barber_Form.dart';
import 'package:barber_xe/pages/widget/barber_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barber_xe/controllers/barber_controller.dart';
import 'package:barber_xe/controllers/profile_controller.dart';
import 'package:barber_xe/models/barber_model.dart';

class BarbersPage extends StatelessWidget {
  static const String routeName = '/barbers';
  
  const BarbersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isAdmin = Provider.of<ProfileController>(context, listen: false).isAdmin;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barberos'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () => _showAddBarberDialog(context),
            ),
        ],
      ),
      body: const _BarberList(),
    );
  }

  void _showAddBarberDialog(BuildContext context) {
    final controller = Provider.of<BarberController>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => BarberFormDialog(
        onSubmit: (newBarber) async {
          final success = await controller.addBarber(newBarber);
          if (success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Barbero agregado exitosamente')),
            );
          }
        },
      ),
    );
  }
}

class _BarberList extends StatefulWidget {
  const _BarberList();

  @override
  State<_BarberList> createState() => _BarberListState();
}

class _BarberListState extends State<_BarberList> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BarberController>(context, listen: false).loadBarbers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<BarberController>(context);
    final isAdmin = Provider.of<ProfileController>(context, listen: false).isAdmin;

    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.errorMessage.isNotEmpty) {
      return Center(child: Text('Error: ${controller.errorMessage}'));
    }

    if (controller.barbers.isEmpty) {
      return const Center(child: Text('No hay barberos registrados'));
    }

    return RefreshIndicator(
      onRefresh: () => controller.loadBarbers(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.barbers.length,
        itemBuilder: (context, index) {
          final barber = controller.barbers[index];
          return BarberCard(
          barber: barber,
          onRatingChanged: isAdmin 
              ? null 
              : (newRating) async {
                final updatedBarber = barber.copyWith(rating: newRating);
                final success = await controller.updateBarber(updatedBarber);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Calificación actualizada a $newRating estrellas')),
                  );
                }
              },
          onEdit: isAdmin ? () => _showEditBarberDialog(context, barber) : null,
          onDelete: isAdmin ? () => _confirmDeleteBarber(context, barber.id) : null,
          readOnlyRating: isAdmin, // Admin ve las estrellas pero no puede cambiarlas
          );
        },
      ),
    );
  }

  void _showEditBarberDialog(BuildContext context, Barber barber) {
    final controller = Provider.of<BarberController>(context, listen: false);
  
    showDialog(
      context: context,
      builder: (context) => BarberFormDialog(
        barber: barber,
        onSubmit: (updatedBarber) async {
          final success = await controller.updateBarber(updatedBarber);
          if (success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Barbero actualizado exitosamente')),
            );
          }
        },
      ),
    );
  }

  Future<void> _confirmDeleteBarber(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de eliminar este barbero?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await Provider.of<BarberController>(
        context,
        listen: false,
      ).deleteBarber(id);

      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar el barbero')),
        );
      }
    }
  }
}