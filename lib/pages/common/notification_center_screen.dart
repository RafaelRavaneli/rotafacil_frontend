import '../../utils/run_action.dart';
import 'settings/notifications_screen.dart';
import '../../widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import '../../state/app_store.dart';
import '../../theme/app_colors.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  bool loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refresh();
    });
  }

  Future<void> _refresh() async {
    if (loading || !AppStore.instance.useBackend) return;
    setState(() => loading = true);
    try {
      await runAction(context, AppStore.instance.refreshNotifications);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackLocation: '/perfil'),
        title: const Text(
          'Notificações',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Preferências de notificações',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const NotificationsScreen(),
              ),
            ),
          ),
          IconButton(
            onPressed: loading ? null : _refresh,
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh_rounded),
          ),
          TextButton(
            onPressed: () => runAction(context, store.markAllNotificationsRead),
            child: const Text('Marcar lidas'),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          if (store.notifications.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text('Nenhuma notificação por enquanto.'),
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
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
                  onTap: () => runAction(
                    context,
                    () => store.markNotificationRead(item),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
