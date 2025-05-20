import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:barber_xe/models/appointment_model.dart';
import 'package:barber_xe/pages/widget/app_helpers.dart';

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final bool isAdmin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const AppointmentCard({
    super.key,
    required this.appointment,
    this.isAdmin = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final priceFormatter = NumberFormat("#,###", "es_ES");

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12), // ↓ más compacto
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(10), // ↓ padding más reducido
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isAdmin ? appointment.userName : appointment.barberName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppHelpers.getStatusColor(appointment.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppHelpers.getStatusColor(appointment.status),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      AppHelpers.getStatusText(appointment.status),
                      style: TextStyle(
                        color: AppHelpers.getStatusColor(appointment.status),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Fecha y duración
              _buildInfoRow(Icons.calendar_today,
                DateFormat('EEE, d MMM - HH:mm', 'es_ES').format(appointment.dateTime)),

              _buildInfoRow(Icons.access_time, '${appointment.duration} min'),

              if (isAdmin)
                _buildInfoRow(Icons.person, appointment.barberName),

              const SizedBox(height: 4),

              // Servicios y combos
              Text(
                _buildServicesSummary(appointment),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 6),

              // Total más arriba y claro
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'Total: ',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                  Text(
                    '\$${priceFormatter.format(appointment.totalPrice)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.grey),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  String _buildServicesSummary(Appointment appointment) {
    final services = appointment.serviceNames.take(2).join(', ');
    final combos = appointment.comboNames.take(2).join(', ');
    final extraServices = appointment.serviceNames.length > 2 ? ' +${appointment.serviceNames.length - 2}' : '';
    final extraCombos = appointment.comboNames.length > 2 ? ' +${appointment.comboNames.length - 2}' : '';

    return '${services.isNotEmpty ? 'Servicios: $services$extraServices' : ''}'
            '${services.isNotEmpty && combos.isNotEmpty ? '\n' : ''}'
            '${combos.isNotEmpty ? 'Combos: $combos$extraCombos' : ''}';
  }
}
