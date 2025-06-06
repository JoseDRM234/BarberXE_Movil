import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final accentColor = theme.primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isCombo ? 200 : 140,
        margin: const EdgeInsets.only(right: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? accentColor : Colors.grey.withOpacity(0.2),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10.0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SizedBox(
                height: isCombo ? 220 : 170,
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildImageSection(context),
                        _buildContentSection(context, accentColor),
                      ],
                    ),
                    if (isSelected) _buildSelectionIndicator(accentColor),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: Container(
        height: isCombo ? 120 : 80,
        color: Colors.grey.withOpacity(0.1),
        child: Stack(
          children: [
            if (imageUrl != null)
              Opacity(
                opacity: 0.9,
                child: Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => _buildPlaceholderIcon(),
                ),
              )
            else
              _buildPlaceholderIcon(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Opacity(
      opacity: 0.7,
      child: Center(
        child: Icon(
          isCombo ? Icons.album : Icons.cut,
          size: isCombo ? 40 : 30,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _buildContentSection(BuildContext context, Color accentColor) {
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
                  style: GoogleFonts.poppins(
                    fontSize: isCombo ? 16 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withOpacity(0.9),
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
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        description!,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: accentColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else
                    Opacity(
                      opacity: 0.8,
                      child: Text(
                        description!,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: isCombo ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 2,
                  child: Opacity(
                    opacity: 0.9,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCombo)
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                        if (isCombo) const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${duration ~/ 60}h ${duration % 60}min',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        color: accentColor.withOpacity(0.9),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionIndicator(Color accentColor) {
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: accentColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
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