import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:barber_xe/models/barber_model.dart';

class BarberCard extends StatefulWidget {
  final Barber barber;
  final ValueChanged<double>? onRatingChanged;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool readOnlyRating;
  final Color? backgroundColor;
  final Color? accentColor;

  const BarberCard({
    super.key,
    required this.barber,
    this.onRatingChanged,
    this.onEdit,
    this.onDelete,
    this.readOnlyRating = false,
    this.backgroundColor,
    this.accentColor,
  });

  @override
  State<BarberCard> createState() => _BarberCardState();
}

class _BarberCardState extends State<BarberCard> {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.barber.rating;
  }

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
    return daysMap[day] ?? 'Día $day'; // Valor por defecto si no existe
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveAccentColor = widget.accentColor ?? theme.primaryColor;
    final effectiveBackgroundColor = widget.backgroundColor ?? Colors.white;
    final isAdmin = widget.onEdit != null || widget.onDelete != null;

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
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: effectiveAccentColor,
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
                            color: effectiveAccentColor,
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
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
                            color: widget.barber.status == 'active'
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isAdmin)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.onEdit != null)
                        IconButton(
                          icon: Icon(
                            Icons.edit_outlined,
                            color: effectiveAccentColor,
                          ),
                          onPressed: widget.onEdit,
                        ),
                      if (widget.onDelete != null)
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: widget.onDelete,
                        ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildRatingDisplay(effectiveAccentColor),
            
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
            _buildScheduleSection(daysMap, effectiveAccentColor),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingDisplay(Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Calificación:',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            widget.readOnlyRating 
                ? _buildStaticStars(accentColor)
                : _buildInteractiveStars(accentColor),
            const SizedBox(width: 8),
            Text(
              _currentRating.toStringAsFixed(1),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStaticStars(Color accentColor) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < _currentRating.floor() 
              ? Icons.star
              : (index < _currentRating ? Icons.star_half : Icons.star_border),
          color: accentColor,
          size: 24,
        );
      }),
    );
  }

  Widget _buildInteractiveStars(Color accentColor) {
    return Row(
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () {
            if (widget.onRatingChanged != null) {
              final newRating = index + 1.0;
              setState(() => _currentRating = newRating);
              widget.onRatingChanged!(newRating);
            }
          },
          child: Icon(
            index < _currentRating ? Icons.star : Icons.star_border,
            color: accentColor,
            size: 24,
          ),
        );
      }),
    );
  }

  Widget _buildScheduleSection(Map<int, String> daysMap, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 18,
              color: accentColor,
            ),
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
            Icon(
              Icons.access_time,
              size: 18,
              color: accentColor,
            ),
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
}