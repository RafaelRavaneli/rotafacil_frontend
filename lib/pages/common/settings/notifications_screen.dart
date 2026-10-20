import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../utils/run_action.dart';
import '../../../widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import '../../../services/notification_service.dart';
import '../../../state/app_store.dart';
import '../notification_center_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  Future<void> _togglePush(BuildContext context, bool value) async {
    final store = AppStore.instance;
    await store.setPushNotifications(value);
    if (!value) {
      await NotificationService.instance.unregisterOnLogout();
      return;
    }

    final settings = await NotificationService.instance.requestPermission();
    if (!context.mounted) return;

    if (settings == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível ativar as notificações neste dispositivo. Você pode acompanhar os avisos na central de notificações.',
          ),
        ),
      );
      return;
    }

    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Permissão de notificações negada. Libere o acesso nas configurações do navegador ou dispositivo. Os avisos continuam disponíveis na central.',
          ),
        ),
      );
      return;
    }
    await NotificationService.instance.registerAfterLogin();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    final notifications = NotificationService.instance;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackLocation: '/perfil'),
        title: const Text(
          'Notificações',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([store, notifications]),
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SwitchListTile.adaptive(
                value: store.pushNotifications,
                onChanged: (value) =>
                    runAction(context, () => _togglePush(context, value)),
                title: const Text('Notificações do aplicativo'),
                subtitle: const Text(
                  'Receba avisos do RotaFácil neste dispositivo.',
                ),
              ),
              SwitchListTile.adaptive(
                value: store.bookingNotifications,
                onChanged: (value) => runAction(
                  context,
                  () => store.setBookingNotifications(value),
                ),
                title: const Text('Agendamentos'),
                subtitle: const Text(
                  'Confirmações, cancelamentos e lembretes.',
                ),
              ),
              SwitchListTile.adaptive(
                value: store.marketingNotifications,
                onChanged: (value) => runAction(
                  context,
                  () => store.setMarketingNotifications(value),
                ),
                title: const Text('Novidades e recomendações'),
                subtitle: const Text(
                  'Sugestões de novos roteiros e experiências.',
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationCenterScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.notifications_none_rounded),
                label: const Text('Abrir central de notificações'),
              ),
            ],
          );
        },
      ),
    );
  }
}
