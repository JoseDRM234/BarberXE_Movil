import 'package:flutter/material.dart';

class NotificationAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int unreadCount;
  final VoidCallback onMarkAllRead;
  final VoidCallback onOpenFilters;
  final Color backgroundColor;
  final Color iconColor;

  const NotificationAppBar({
    super.key,
    required this.unreadCount,
    required this.onMarkAllRead,
    required this.onOpenFilters,
    this.backgroundColor = const Color(0xFF105DFB),
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications, color: iconColor),
          const SizedBox(width: 12),
          Text(
            'Notificaciones',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: iconColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (unreadCount > 0) ...[
            const SizedBox(width: 12),
            Badge(
              label: Text(unreadCount.toString()),
              backgroundColor: Colors.red,
              textColor: Colors.white,
            ),
          ],
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.done_all, color: iconColor),
          onPressed: onMarkAllRead,
          tooltip: 'Marcar todas como leídas',
        ),
        IconButton(
          icon: Icon(Icons.filter_list, color: iconColor),
          onPressed: onOpenFilters,
          tooltip: 'Filtrar notificaciones',
        ),
      ],
      centerTitle: true,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}