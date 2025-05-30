import 'package:barber_xe/controllers/auth_controller.dart';
import 'package:barber_xe/controllers/notification_controller.dart';
import 'package:barber_xe/models/NotificationFilter_model.dart';
import 'package:barber_xe/models/NotificationType_model.dart';
import 'package:barber_xe/models/notification_model.dart';
import 'package:barber_xe/pages/widget/empty_notifications.dart';
import 'package:barber_xe/pages/widget/loading_indicator.dart';
import 'package:barber_xe/pages/widget/notification_app_bar.dart';
import 'package:barber_xe/pages/widget/notification_card.dart';
import 'package:barber_xe/pages/widget/notification_filter_chips.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late String _userId;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authController = context.read<AuthController>();
      final notificationController = context.read<NotificationController>();
      
      _userId = authController.currentUser?.uid ?? '';
      
      if (_userId.isNotEmpty) {
        await notificationController.initialize(_userId);
        setState(() => _initialized = true);
      } else {
        setState(() => _initialized = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: NotificationAppBar(
        unreadCount: context.select<NotificationController, int>(
            (controller) => controller.unreadCount),
        onMarkAllRead: () => _markAllAsRead(context),
        onOpenFilters: () => _showFilterDialog(context),
      ),
      body: Consumer<NotificationController>(
        builder: (context, controller, _) {
          if (controller.isLoading) return const LoadingIndicator();
          
          if (controller.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text('Error cargando notificaciones',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextButton(
                    // CORRECCIÓN: Usar refresh en lugar de loadNotifications
                    onPressed: () => controller.refresh(_userId),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (controller.notifications.isEmpty) {
            return const EmptyNotifications();
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: NotificationFilterChips(
                  currentFilter: controller.currentFilter,
                  // CORRECCIÓN: Usar applyFilter en lugar de filterNotifications
                  onFilterChanged: (filter) => controller.applyFilter(_userId, filter),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  // CORRECCIÓN: Usar refresh en lugar de refreshNotifications
                  onRefresh: () => controller.refresh(_userId),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: controller.notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final notification = controller.notifications[index];
                      return NotificationCard(
                        notification: notification,
                        onTap: () => _handleNotificationTap(context, notification),
                        onDelete: () => controller.deleteNotification(notification.id!),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _markAllAsRead(BuildContext context) {
    final controller = context.read<NotificationController>();
    controller.markAllAsRead(_userId);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Todas las notificaciones marcadas como leídas'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    final controller = context.read<NotificationController>();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filtrar notificaciones'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Estado:'),
              ...['Todas', 'Leídas', 'No leídas'].map((status) {
                return RadioListTile<String>(
                  title: Text(status),
                  value: status,
                  groupValue: controller.currentFilter.isRead == null
                      ? 'Todas'
                      : controller.currentFilter.isRead!
                          ? 'Leídas'
                          : 'No leídas',
                  onChanged: (value) {
                    final newFilter = controller.currentFilter.copyWith(
                      isRead: value == 'Todas'
                          ? null
                          : value == 'Leídas',
                    );
                    // CORRECCIÓN: Usar applyFilter en lugar de generateTestNotification
                    controller.applyFilter(_userId, newFilter);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _handleNotificationTap(BuildContext context, NotificationModel notification) {
    final controller = context.read<NotificationController>();
    
    if (!notification.isRead) {
      controller.markAsRead(notification.id!);
    }
    
    switch (notification.type) {
      case NotificationType.REMINDER_24H:
      case NotificationType.REMINDER_1H:
        Navigator.pushNamed(context, '/appointment-details',
            arguments: notification.data['appointmentId']);
        break;
      case NotificationType.APPOINTMENT_CHANGE:
        Navigator.pushNamed(context, '/appointment-changes',
            arguments: notification.data['appointmentId']);
        break;
      case NotificationType.PROMOTION:
        Navigator.pushNamed(context, '/promotion-details',
            arguments: notification.data['promotionId']);
        break;
      case NotificationType.FAVORITE_BARBER_AVAILABLE:
        Navigator.pushNamed(context, '/schedule',
            arguments: notification.data['barberId']);
        break;
    }
  }
}