import 'package:barber_xe/pages/barber/Barber_Form.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:barber_xe/controllers/barber_controller.dart';
import 'package:barber_xe/controllers/profile_controller.dart';
import 'package:barber_xe/models/barber_model.dart';
import 'package:barber_xe/pages/widget/barber_card.dart';

class BarbersPage extends StatelessWidget {
  static const String routeName = '/barbers';
  
  const BarbersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isAdmin = Provider.of<ProfileController>(context, listen: false).isAdmin;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Barberos',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
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
        onSubmit: (newBarber, image) async {
          final success = await controller.addBarber(
            newBarber, 
            imageFile: image
          );
          
          if (success && context.mounted) {
            Navigator.of(context).pop(); // Cerrar el diálogo
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Barbero agregado exitosamente',
                  style: GoogleFonts.poppins(),
                ),
                backgroundColor: Colors.green,
              ),
            );
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error al agregar el barbero',
                  style: GoogleFonts.poppins(),
                ),
                backgroundColor: Colors.red,
              ),
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
      return Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).primaryColor,
        ),
      );
    }

    if (controller.errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Error: ${controller.errorMessage}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => controller.loadBarbers(),
              child: Text(
                'Reintentar',
                style: GoogleFonts.poppins(),
              ),
            ),
          ],
        ),
      );
    }

    if (controller.barbers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              color: Colors.grey,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay barberos registrados',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            if (isAdmin) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _showAddBarberDialog(context),
                icon: const Icon(Icons.add),
                label: Text(
                  'Agregar Barbero',
                  style: GoogleFonts.poppins(),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => controller.loadBarbers(),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: controller.barbers.length,
        itemBuilder: (context, index) {
          final barber = controller.barbers[index];
          return BarberCard(
            barber: barber,
            isAdmin: isAdmin,
            readOnlyRating: isAdmin,
            // Función para agregar calificaciones (solo para usuarios no admin)
            onRatingAdded: isAdmin 
                ? null 
                : (newRating) async {
                    final success = await controller.addRating(barber.id, newRating);
                    if (!success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error al agregar calificación',
                            style: GoogleFonts.poppins(),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
            // Función para cambiar estado (solo para admin)
            onStatusToggled: isAdmin 
                ? () async {
                    final success = await controller.toggleBarberStatus(barber.id);
                    if (!success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error al cambiar estado del barbero',
                            style: GoogleFonts.poppins(),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                : null,
            // Función para editar (solo para admin)
            onEdit: isAdmin ? () => _showEditBarberDialog(context, barber) : null,
            // Función para eliminar (solo para admin)
            onDelete: isAdmin ? () => _confirmDeleteBarber(context, barber) : null,
          );
        },
      ),
    );
  }

  void _showAddBarberDialog(BuildContext context) {
    final controller = Provider.of<BarberController>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => BarberFormDialog(
        onSubmit: (newBarber, image) async {
          final success = await controller.addBarber(
            newBarber, 
            imageFile: image
          );
          
          if (success && context.mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Barbero agregado exitosamente',
                  style: GoogleFonts.poppins(),
                ),
                backgroundColor: Colors.green,
              ),
            );
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error al agregar el barbero',
                  style: GoogleFonts.poppins(),
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
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
        onSubmit: (updatedBarber, image) async {
          final success = await controller.updateBarber(
            updatedBarber, 
            imageFile: image
          );
          
          if (success && context.mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Barbero actualizado exitosamente',
                  style: GoogleFonts.poppins(),
                ),
                backgroundColor: Colors.green,
              ),
            );
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error al actualizar el barbero',
                  style: GoogleFonts.poppins(),
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _confirmDeleteBarber(BuildContext context, Barber barber) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirmar eliminación',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de eliminar este barbero?',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: barber.photoUrl != null 
                        ? NetworkImage(barber.photoUrl!) 
                        : null,
                    child: barber.photoUrl == null 
                        ? const Icon(Icons.person, size: 20) 
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          barber.name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${barber.totalRatings} calificaciones',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Esta acción no se puede deshacer.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.red.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(color: Colors.grey[700]),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              backgroundColor: Colors.red.shade50,
            ),
            child: Text(
              'Eliminar',
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text(
                'Eliminando barbero...',
                style: GoogleFonts.poppins(),
              ),
            ],
          ),
        ),
      );

      final success = await Provider.of<BarberController>(
        context,
        listen: false,
      ).deleteBarber(barber.id);

      if (context.mounted) {
        Navigator.of(context).pop(); // Cerrar diálogo de carga

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success 
                  ? 'Barbero eliminado exitosamente'
                  : 'Error al eliminar el barbero',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}