import 'package:barber_xe/controllers/services_controller.dart';
import 'package:barber_xe/models/service_combo.dart';
import 'package:barber_xe/models/service_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ComboCard extends StatelessWidget {
  final ServiceCombo combo;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? accentColor;

  const ComboCard({
    super.key, 
    required this.combo,
    this.onTap,
    this.backgroundColor,
    this.textColor,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final serviceController = Provider.of<ServiceController>(context, listen: false);
    
    final effectiveBackgroundColor = backgroundColor ?? 
        (isDarkMode ? Colors.grey[850] : Colors.white);
    final effectiveTextColor = textColor ?? 
        (isDarkMode ? Colors.white : Colors.grey[800]);
    final effectiveAccentColor = accentColor ?? theme.primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: effectiveBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FutureBuilder<List<BarberService>>(
          future: serviceController.getServicesForCombo(combo),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState(effectiveAccentColor);
            }

            if (snapshot.hasError) {
              return _buildErrorState();
            }

            final services = snapshot.data ?? [];
            return _buildComboContent(
              context, 
              combo, 
              services, 
              effectiveTextColor!, 
              effectiveAccentColor,
              effectiveBackgroundColor!,
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState(Color accentColor) {
    return Center(
      child: CircularProgressIndicator(
        color: accentColor,
      ),
    );
  }

  Widget _buildErrorState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red),
          SizedBox(height: 8),
          Text('Error al cargar el combo'),
        ],
      ),
    );
  }

  Widget _buildComboContent(
    BuildContext context,
    ServiceCombo combo,
    List<BarberService> services,
    Color textColor,
    Color accentColor,
    Color backgroundColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Imagen del combo
        _buildComboImage(combo),
        
        // Contenido
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre y precio
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        combo.name,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '\$${combo.totalPrice.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Duración y descripción
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 18,
                      color: accentColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${combo.totalDuration ~/ 60}h ${combo.totalDuration % 60}min',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Descripción
                if (combo.description.isNotEmpty)
                  Text(
                    combo.description,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: textColor.withOpacity(0.8),
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Servicios incluidos
                if (services.isNotEmpty) ...[
                  Text(
                    'SERVICIOS INCLUIDOS:',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...services.map((service) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 18,
                          color: accentColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            service.name,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: textColor.withOpacity(0.9),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
                
                const Spacer(),
                
                // Botón de reserva
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 2,
                    ),
                    onPressed: () {}, // Mantener para reservas
                    child: Text(
                      'RESERVAR COMBO',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComboImage(ServiceCombo combo) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Container(
        height: 140,
        width: double.infinity,
        color: Colors.grey[200],
        child: combo.imageUrl != null
            ? Image.network(
                combo.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
              )
            : _buildPlaceholderImage(),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Center(
      child: Icon(
        Icons.photo_library,
        size: 50,
        color: Colors.grey[400],
      ),
    );
  }
}