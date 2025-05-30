import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:barber_xe/models/barber_model.dart';

class BarberCard extends StatefulWidget {
  final Barber barber;
  final Function(double)? onRatingAdded;
  final Function()? onStatusToggled;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool readOnlyRating;
  final bool isAdmin;
  final Color? backgroundColor;
  final Color? accentColor;

  const BarberCard({
    super.key,
    required this.barber,
    this.onRatingAdded,
    this.onStatusToggled,
    this.onEdit,
    this.onDelete,
    this.readOnlyRating = false,
    this.isAdmin = false,
    this.backgroundColor,
    this.accentColor,
  });

  @override
  State<BarberCard> createState() => _BarberCardState();
}

class _BarberCardState extends State<BarberCard> {
  bool _isSubmittingRating = false;
  bool _isTogglingStatus = false;

  final Map<int, String> daysMap = {
    0: 'Lun',
    1: 'Mar',
    2: 'Mié',
    3: 'Jue',
    4: 'Vie',
    5: 'Sáb',
    6: 'Dom',
  };

  String _getDayName(int day) {
    return daysMap[day] ?? 'Día $day';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveAccentColor = widget.accentColor ?? theme.primaryColor;
    final effectiveBackgroundColor = widget.backgroundColor ?? Colors.white;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: effectiveBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(effectiveAccentColor),
            const SizedBox(height: 16),
            _buildRatingSection(effectiveAccentColor),
            if (widget.barber.shortDescription.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                widget.barber.shortDescription,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
            const SizedBox(height: 16),
            _buildScheduleSection(effectiveAccentColor),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color accentColor) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: accentColor,
              width: 2,
            ),
          ),
          child: CircleAvatar(
            radius: 30,
            backgroundImage: widget.barber.photoUrl != null 
                ? NetworkImage(widget.barber.photoUrl!) 
                : null,
            child: widget.barber.photoUrl == null 
                ? Icon(
                    Icons.person,
                    size: 30,
                    color: accentColor,
                  ) 
                : null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.barber.name,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              _buildStatusChip(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.barber.status == 'active'
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        widget.barber.status == 'active' ? 'ACTIVO' : 'INACTIVO',
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: widget.barber.status == 'active' ? Colors.green : Colors.red,
        ),
      ),
    );
  }

  Widget _buildRatingSection(Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Calificación:',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),
            if (widget.barber.totalRatings > 0)
              Text(
                '(${widget.barber.totalRatings} ${widget.barber.totalRatings == 1 ? 'calificación' : 'calificaciones'})',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStarsSection(accentColor),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.barber.rating.toStringAsFixed(1),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
                // Iconos de administración debajo del porcentaje
                if (widget.isAdmin) ...[
                  const SizedBox(height: 8),
                  _buildAdminIconsRow(accentColor),
                ],
              ],
            ),
          ],
        ),
        if (_isSubmittingRating) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text(
                'Guardando calificación...',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAdminIconsRow(Color accentColor) {
    List<Widget> adminIcons = [];

    // Icono de editar
    if (widget.onEdit != null) {
      adminIcons.add(
        _buildAdminIcon(
          icon: Icons.edit_outlined,
          color: accentColor,
          onTap: widget.onEdit!,
          tooltip: 'Editar',
        ),
      );
    }

    // Icono de eliminar
    if (widget.onDelete != null) {
      adminIcons.add(
        _buildAdminIcon(
          icon: Icons.delete_outline,
          color: Colors.red,
          onTap: widget.onDelete!,
          tooltip: 'Eliminar',
        ),
      );
    }

    // Icono de cambiar estado
    if (widget.onStatusToggled != null) {
      if (_isTogglingStatus) {
        adminIcons.add(
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        );
      } else {
        adminIcons.add(
          _buildAdminIcon(
            icon: widget.barber.status == 'active' 
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: widget.barber.status == 'active' 
                ? Colors.orange 
                : Colors.green,
            onTap: _handleStatusToggle,
            tooltip: widget.barber.status == 'active' ? 'Desactivar' : 'Activar',
          ),
        );
      }
    }

    if (adminIcons.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: adminIcons.map((icon) {
        int index = adminIcons.indexOf(icon);
        return Row(
          children: [
            icon,
            if (index < adminIcons.length - 1) const SizedBox(width: 4),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildAdminIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildStarsSection(Color accentColor) {
    if (widget.readOnlyRating || widget.isAdmin) {
      return _buildStaticStars(accentColor);
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStaticStars(accentColor),
          const SizedBox(height: 8),
          Text(
            'Toca para calificar:',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          _buildInteractiveStars(accentColor),
        ],
      );
    }
  }

  Widget _buildStaticStars(Color accentColor) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < widget.barber.rating.floor() 
              ? Icons.star
              : (index < widget.barber.rating ? Icons.star_half : Icons.star_border),
          color: accentColor,
          size: 20,
        );
      }),
    );
  }

  Widget _buildInteractiveStars(Color accentColor) {
    return Row(
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: _isSubmittingRating ? null : () => _handleRating(index + 1.0),
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              Icons.star_border,
              color: _isSubmittingRating 
                  ? Colors.grey.shade400 
                  : accentColor.withOpacity(0.7),
              size: 24,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildScheduleSection(Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: accentColor),
            const SizedBox(width: 8),
            Text(
              'Días:',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: widget.barber.workingDays.map((day) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accentColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                _getDayName(day),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: accentColor,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.access_time, size: 18, color: accentColor),
            const SizedBox(width: 8),
            Text(
              '${widget.barber.workingHours['start']} - ${widget.barber.workingHours['end']}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handleRating(double rating) async {
    if (widget.onRatingAdded == null || _isSubmittingRating) return;

    setState(() => _isSubmittingRating = true);

    try {
      await widget.onRatingAdded!(rating);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Calificación de $rating estrellas agregada',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
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
    } finally {
      if (mounted) {
        setState(() => _isSubmittingRating = false);
      }
    }
  }

  Future<void> _handleStatusToggle() async {
    if (widget.onStatusToggled == null || _isTogglingStatus) return;

    setState(() => _isTogglingStatus = true);

    try {
      await widget.onStatusToggled!();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Estado cambiado a ${widget.barber.status == 'active' ? 'inactivo' : 'activo'}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al cambiar estado',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTogglingStatus = false);
      }
    }
  }
}