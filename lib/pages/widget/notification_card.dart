import 'package:barber_xe/models/NotificationType_model.dart';
import 'package:barber_xe/models/notification_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Duration dismissThreshold;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDelete,
    this.dismissThreshold = const Duration(milliseconds: 200),
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id!),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) => _confirmDismiss(context, direction),
      background: _buildDismissBackground(),
      secondaryBackground: _buildDeleteBackground(),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        elevation: notification.isRead ? 2 : 4,
        color: notification.isRead ? Colors.grey[50] : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: notification.isRead 
                ? Colors.grey.shade200 
                : _typeColor.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                _buildContent(),
                const SizedBox(height: 12),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _typeColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(_typeIcon, color: _typeColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            notification.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: notification.isRead ? Colors.grey[600] : Colors.black,
            ),
          ),
        ),
        if (!notification.isRead) ...[
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildContent() {
    return Text(
      notification.description,
      style: TextStyle(
        color: notification.isRead ? Colors.grey[600] : Colors.grey[800],
        fontSize: 14,
        height: 1.4,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(
          _formattedTime,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: _typeColor,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(_actionText.toUpperCase()),
        ),
      ],
    );
  }

  Color get _typeColor {
    switch (notification.type) {
      case NotificationType.REMINDER_24H:
      case NotificationType.REMINDER_1H:
        return const Color(0xFFFF8C00);
      case NotificationType.APPOINTMENT_CHANGE:
        return const Color(0xFF2196F3);
      case NotificationType.PROMOTION:
        return const Color(0xFFFFD700);
      case NotificationType.FAVORITE_BARBER_AVAILABLE:
        return const Color(0xFF4CAF50);
    }
  }

  IconData get _typeIcon {
    switch (notification.type) {
      case NotificationType.REMINDER_24H:
      case NotificationType.REMINDER_1H:
        return Icons.alarm;
      case NotificationType.APPOINTMENT_CHANGE:
        return Icons.edit_calendar;
      case NotificationType.PROMOTION:
        return Icons.local_offer;
      case NotificationType.FAVORITE_BARBER_AVAILABLE:
        return Icons.person;
    }
  }

  String get _actionText {
    switch (notification.type) {
      case NotificationType.REMINDER_24H:
      case NotificationType.REMINDER_1H:
        return 'Ver cita';
      case NotificationType.APPOINTMENT_CHANGE:
        return 'Ver cambios';
      case NotificationType.PROMOTION:
        return 'Aprovechar';
      case NotificationType.FAVORITE_BARBER_AVAILABLE:
        return 'Agendar';
    }
  }

  String get _formattedTime {
    final now = DateTime.now();
    final difference = now.difference(notification.createdAt);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(notification.createdAt);
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(notification.createdAt);
    }
    return DateFormat('dd/MM/yyyy').format(notification.createdAt);
  }

  Widget _buildDismissBackground() {
    return Container(
      color: Colors.blue.shade50,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 20),
      child: const Icon(Icons.check, color: Colors.blue),
    );
  }

  Widget _buildDeleteBackground() {
    return Container(
      color: Colors.red.shade50,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Icon(Icons.delete, color: Colors.red),
    );
  }

  Future<bool?> _confirmDismiss(BuildContext context, DismissDirection direction) async {
    if (direction == DismissDirection.endToStart) {
      return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Eliminar notificación'),
          content: const Text('¿Estás seguro de eliminar esta notificación?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    }
    return true; // Permitir dismiss en otras direcciones sin confirmación
  }
}