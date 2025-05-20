import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActiveToggleButton extends StatelessWidget {
  final bool isActive;
  final Function(bool) onChanged;
  final double iconSize;

  const ActiveToggleButton({
    Key? key,
    required this.isActive,
    required this.onChanged,
    this.iconSize = 40,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        isActive ? Icons.toggle_on : Icons.toggle_off,
        color: isActive ? Colors.green : Colors.red,
        size: iconSize,
      ),
      splashRadius: iconSize * 0.7, // Reduce el área del efecto splash
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(minWidth: iconSize, minHeight: iconSize),
      onPressed: () => onChanged(!isActive),
    );
  }
}