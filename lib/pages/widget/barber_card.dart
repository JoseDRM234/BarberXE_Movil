// widgets/barber_card.dart
import 'package:flutter/material.dart';
import 'package:barber_xe/models/barber_model.dart';

class BarberCard extends StatefulWidget {
  final Barber barber;
  final ValueChanged<double>? onRatingChanged; // Opcional para admin
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool readOnlyRating; // Nuevo parámetro para bloquear rating

  const BarberCard({
    super.key,
    required this.barber,
    this.onRatingChanged,
    this.onEdit,
    this.onDelete,
    this.readOnlyRating = false, // Por defecto no es de solo lectura
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

  @override
  Widget build(BuildContext context) {
    final daysMap = {
      0: 'Lunes',
      1: 'Martes',
      2: 'Miércoles',
      3: 'Jueves',
      4: 'Viernes',
      5: 'Sábado',
      6: 'Domingo',
    };

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: widget.barber.photoUrl != null 
                      ? NetworkImage(widget.barber.photoUrl!) 
                      : null,
                  child: widget.barber.photoUrl == null 
                      ? const Icon(Icons.person) 
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.barber.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Estado: ${widget.barber.status}',
                        style: TextStyle(
                          color: widget.barber.status == 'active' 
                              ? Colors.green 
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: widget.onEdit,
                  ),
                if (widget.onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: widget.onDelete,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Mostrar siempre las estrellas pero con diferente comportamiento
            _buildRatingDisplay(),
            
            const SizedBox(height: 12),
            if (widget.barber.shortDescription.isNotEmpty)
              Text(widget.barber.shortDescription),
            const SizedBox(height: 12),
            Text(
              'Días: ${widget.barber.workingDays.map((day) => daysMap[day]).join(', ')}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Horario: ${widget.barber.workingHours['start']} - ${widget.barber.workingHours['end']}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Estrellas
        if (widget.readOnlyRating) 
          _buildStaticStars()
        else 
          _buildInteractiveStars(),
        // Mostrar el valor numérico
        Text(' (${_currentRating.toStringAsFixed(1)})'),
      ],
    );
  }

  Widget _buildStaticStars() {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < _currentRating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 24,
        );
      }),
    );
  }

  Widget _buildInteractiveStars() {
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
            color: Colors.amber,
            size: 24,
          ),
        );
      }),
    );
  }
}