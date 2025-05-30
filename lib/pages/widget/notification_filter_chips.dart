import 'package:barber_xe/models/NotificationFilter_model.dart';
import 'package:barber_xe/models/NotificationType_model.dart';
import 'package:flutter/material.dart';


class NotificationFilterChips extends StatelessWidget {
  final NotificationFilter currentFilter;
  final ValueChanged<NotificationFilter> onFilterChanged;
  final Color selectedColor;
  final Color backgroundColor;

  const NotificationFilterChips({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
    this.selectedColor = const Color(0xFF105DFB),
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildChip('Todas', null),
          ...NotificationType.values.map((type) => _buildTypeChip(type)),
        ],
      ),
    );
  }

  Widget _buildChip(String label, NotificationType? type) {
    final isSelected = currentFilter.type == type;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) => onFilterChanged(
          currentFilter.copyWith(type: selected ? type : null),
        ),
        selectedColor: selectedColor,
        backgroundColor: backgroundColor,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[700],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildTypeChip(NotificationType type) {
    return _buildChip(_typeLabel(type), type);
  }

  String _typeLabel(NotificationType type) {
    switch (type) {
      case NotificationType.REMINDER_24H:
      case NotificationType.REMINDER_1H:
        return 'Recordatorios';
      case NotificationType.APPOINTMENT_CHANGE:
        return 'Cambios';
      case NotificationType.PROMOTION:
        return 'Promociones';
      case NotificationType.FAVORITE_BARBER_AVAILABLE:
        return 'Favoritos';
    }
  }
}