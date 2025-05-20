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
        onSubmit: (newBarber, image) async { // Ahora recibe 2 parámetros
          final success = await controller.addBarber(
            newBarber, 
            imageFile: image // Pasar la imagen al controlador
          );
          
          if (success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Barbero agregado exitosamente',
                  style: GoogleFonts.poppins(),
                ),
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
        child: Text(
          'Error: ${controller.errorMessage}',
          style: GoogleFonts.poppins(),
        ),
      );
    }

    if (controller.barbers.isEmpty) {
      return Center(
        child: Text(
          'No hay barberos registrados',
          style: GoogleFonts.poppins(),
        ),
      );
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
                      SnackBar(
                        content: Text(
                          'Calificación actualizada a $newRating estrellas',
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                    );
                  }
                },
            onEdit: isAdmin ? () => _showEditBarberDialog(context, barber) : null,
            onDelete: isAdmin ? () => _confirmDeleteBarber(context, barber.id) : null,
            readOnlyRating: isAdmin,
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
      onSubmit: (updatedBarber, image) async { // Ahora recibe 2 parámetros
        final success = await controller.updateBarber(
          updatedBarber, 
          imageFile: image // Pasar la imagen al controlador
        );
        
        if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Barbero actualizado exitosamente',
                style: GoogleFonts.poppins(),
              ),
            ),
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
        title: Text(
          'Confirmar eliminación',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '¿Estás seguro de eliminar este barbero?',
          style: GoogleFonts.poppins(),
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
            child: Text(
              'Eliminar',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
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
          SnackBar(
            content: Text(
              'Error al eliminar el barbero',
              style: GoogleFonts.poppins(),
            ),
          ),
        );
      }
    }
  }
}