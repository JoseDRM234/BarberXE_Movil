import 'package:barber_xe/pages/barber/Barber_Form.dart';
import 'package:barber_xe/services/favorite_service.dart';
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
    return Scaffold(
      body: const _BarberList(),
    );
  }
}

class _BarberList extends StatefulWidget {
  const _BarberList();

  @override
  State<_BarberList> createState() => _BarberListState();
}

class _BarberListState extends State<_BarberList> {
  final FavoriteService _favoriteService = FavoriteService();
  List<String> _favoriteBarbers = [];
  bool _showOnlyFavorites = false;
  bool _isLoadingFavorites = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadFavorites();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BarberController>(context, listen: false).loadBarbers();
    });
  }

  Future<void> _loadFavorites() async {
    if (_isLoadingFavorites) return;
    
    setState(() => _isLoadingFavorites = true);
    try {
      final user = Provider.of<ProfileController>(context, listen: false).currentUser;
      if (user != null) {
        _favoriteBarbers = await _favoriteService.getUserFavorites(user.uid);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingFavorites = false);
      }
    }
  }

  Future<void> _toggleFavorite(String barberId) async {
    final user = Provider.of<ProfileController>(context, listen: false).currentUser;
    if (user != null) {
      await _favoriteService.toggleFavorite(user.uid, barberId);
      await _loadFavorites();
    }
  }

  List<Barber> _getFilteredBarbers(List<Barber> allBarbers) {
    if (_showOnlyFavorites) {
      return allBarbers.where((barber) => _favoriteBarbers.contains(barber.id)).toList();
    }
    return allBarbers;
  }

  // Método centralizado para refrescar datos
  Future<void> _refreshData() async {
    await Future.wait([
      Provider.of<BarberController>(context, listen: false).loadBarbers(),
      _loadFavorites(),
    ]);
  }

  void _showAddBarberDialog(BuildContext context) {
    final controller = Provider.of<BarberController>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => BarberFormDialog(
        onSubmit: (newBarber, image) async {
          final success = await controller.addBarber(newBarber, imageFile: image);
          
          if (success && context.mounted) {
            Navigator.of(context).pop();
            // Refrescar datos después de agregar
            await _refreshData();
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

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<BarberController>(context);
    final isAdmin = Provider.of<ProfileController>(context, listen: false).isAdmin;
    final filteredBarbers = _getFilteredBarbers(controller.barbers);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _showOnlyFavorites ? 'Barberos Favoritos' : 'Todos los Barberos',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          if (!isAdmin) // Solo mostrar toggle de favoritos para no-admins
            IconButton(
              icon: Icon(
                _showOnlyFavorites ? Icons.star : Icons.star_border,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _showOnlyFavorites = !_showOnlyFavorites;
                });
              },
              tooltip: _showOnlyFavorites ? 'Mostrar todos' : 'Mostrar solo favoritos',
            ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () => _showAddBarberDialog(context),
            ),
        ],
      ),
      body: _buildBody(controller, filteredBarbers, isAdmin),
    );
  }

  Widget _buildBody(BarberController controller, List<Barber> barbers, bool isAdmin) {
    if (controller.isLoading || _isLoadingFavorites) {
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

    if (barbers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _showOnlyFavorites ? Icons.star_border : Icons.people_outline,
              color: Colors.grey,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _showOnlyFavorites 
                  ? 'No tienes barberos favoritos' 
                  : 'No hay barberos registrados',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            if (isAdmin && !_showOnlyFavorites) ...[
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
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: barbers.length,
        itemBuilder: (context, index) {
          final barber = barbers[index];
          final isFavorite = _favoriteBarbers.contains(barber.id);

          return BarberCard(
            barber: barber,
            isAdmin: isAdmin,
            readOnlyRating: isAdmin,
            isFavorite: isFavorite,
            onFavoritePressed: isAdmin ? null : () => _toggleFavorite(barber.id),
            onRatingAdded: isAdmin
                ? null
                : (newRating) async {
                    final success = await controller.addRating(barber.id, newRating);
                    if (success && mounted) {
                      setState(() {
                        // Refrescar solo el barbero calificado localmente
                        final updatedBarber = controller.barbers.firstWhere(
                            (b) => b.id == barber.id,
                            orElse: () => barber);
                        barbers[index] = updatedBarber;
                      });
                    } else {
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
            onEdit: isAdmin ? () => _showEditBarberDialog(context, barber) : null,
            onDelete: isAdmin ? () => _confirmDeleteBarber(context, barber) : null,
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

        if (success) {
          // Refrescar datos después de eliminar
          await _refreshData();
        }

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