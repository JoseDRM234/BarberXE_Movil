import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:barber_xe/models/appointment_model.dart';
import 'package:barber_xe/pages/widget/app_helpers.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            onLongPress: onLongPress,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado compacto
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isAdmin ? appointment.userName : appointment.barberName,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withOpacity(0.9),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppHelpers.getStatusColor(appointment.status),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Información compacta
                  _buildCompactInfoRow(
                    Icons.calendar_today_outlined,
                    DateFormat('dd/MM - HH:mm', 'es_ES').format(appointment.dateTime),
                    theme,
                  ),

                  _buildCompactInfoRow(
                    Icons.access_time_outlined,
                    '${appointment.duration} min',
                    theme,
                  ),

                  if (isAdmin)
                    _buildCompactInfoRow(
                      Icons.person_outline,
                      appointment.barberName,
                      theme,
                    ),

                  const SizedBox(height: 6),

                  // Servicios resumidos
                  Text(
                    _buildCompactServicesSummary(appointment),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Total compacto
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Total: ',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        '\$${priceFormatter.format(appointment.totalPrice)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactInfoRow(IconData icon, String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            icon, 
            size: 14, 
            color: Colors.grey[500],
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey[700],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _buildCompactServicesSummary(Appointment appointment) {
    final services = appointment.serviceNames.take(1).join(', ');
    final combos = appointment.comboNames.take(1).join(', ');
    final extraServices = appointment.serviceNames.length > 1 ? ' +${appointment.serviceNames.length - 1}' : '';
    final extraCombos = appointment.comboNames.length > 1 ? ' +${appointment.comboNames.length - 1}' : '';

    return '${services.isNotEmpty ? 'Serv: $services$extraServices' : ''}'
            '${services.isNotEmpty && combos.isNotEmpty ? ' • ' : ''}'
            '${combos.isNotEmpty ? 'Comb: $combos$extraCombos' : ''}';
  }
}