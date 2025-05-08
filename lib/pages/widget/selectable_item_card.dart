import 'package:flutter/material.dart';

class SelectableItemCard extends StatelessWidget {
  final String title;
  final double price;
  final String? imageUrl;
  final int duration;
  final String? description;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isCombo;
  final bool showCategory;

  const SelectableItemCard({
    super.key,
    required this.title,
    required this.price,
    this.imageUrl,
    required this.duration,
    this.description,
    required this.isSelected,
    required this.onTap,
    this.isCombo = false,
    this.showCategory = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isCombo ? 200 : 140,
        margin: const EdgeInsets.only(right: 12),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? theme.primaryColor : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Container(
            height: isCombo ? 220 : 170,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageSection(),
                    _buildContentSection(context),
                  ],
                ),
                if (isSelected) _buildSelectionIndicator(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: Container(
        height: isCombo ? 120 : 80,
        color: Colors.grey.shade200,
        child: imageUrl != null
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
              )
            : Icon(
                isCombo ? Icons.album : Icons.cut,
                size: isCombo ? 40 : 30,
                color: Colors.grey,
              ),
      ),
    );
  }

  Widget _buildContentSection(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isCombo ? 16 : 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (description != null) ...[
                  const SizedBox(height: 6),
                  if (showCategory)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        description!,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else
                    Text(
                      description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      maxLines: isCombo ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 2, // Prioriza espacio para la duración
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isCombo)
                        const Icon(Icons.access_time, 
                          size: 16, 
                          color: Colors.grey,
                        ),
                      if (isCombo) const SizedBox(width: 2), // Reducimos el espacio
                      Expanded(
                        child: Text(
                          '${duration ~/ 60}h ${duration % 60}min', // Formato mejorado
                          style: TextStyle(
                            fontSize: 10, // Tamaño reducido
                            color: Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1, // Espacio para el precio
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12, // Tamaño reducido
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionIndicator(ThemeData theme) {
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: theme.primaryColor,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }
}