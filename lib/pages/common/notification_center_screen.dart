import 'package:flutter/material.dart';
import '../../state/app_store.dart';
import '../../theme/app_colors.dart';

class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notificações',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          TextButton(
            onPressed: store.markAllNotificationsRead,
            child: const Text('Marcar lidas'),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          if (store.notifications.isEmpty) {
            return const Center(
              child: Text('Nenhuma notificação por enquanto.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: store.notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = store.notifications[index];
              return ListTile(
                tileColor: item.read ? AppColors.paper : AppColors.green100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: const Icon(
                  Icons.notifications_active_outlined,
                  color: AppColors.green700,
                ),
                title: Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(item.body),
                trailing: item.read
                    ? null
                    : const Icon(
                        Icons.circle,
                        size: 9,
                        color: AppColors.green700,
                      ),
                onTap: () => store.markNotificationRead(item),
              );
            },
          );
        },
      ),
    );
  }
}
