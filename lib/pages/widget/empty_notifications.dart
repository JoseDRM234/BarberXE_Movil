import 'package:flutter/material.dart';

class EmptyNotifications extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback? onRetry;

  const EmptyNotifications({
    super.key,
    this.title = 'Sin notificaciones',
    this.description = 'No tienes notificaciones nuevas.\nTe avisaremos cuando haya novedades.',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
                height: 1.4,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Recargar notificaciones'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}