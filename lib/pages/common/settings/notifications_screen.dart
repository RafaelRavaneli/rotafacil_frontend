import 'package:flutter/material.dart';
import '../../../services/notification_service.dart';
import '../../../state/app_store.dart';
import '../../../theme/app_colors.dart';
import '../notification_center_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  Future<void> _togglePush(BuildContext context, bool value) async {
    final store = AppStore.instance;
    await store.setPushNotifications(value);
    if (!value) return;

    final settings = await NotificationService.instance.requestPermission();
    if (!context.mounted) return;

    if (settings == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Firebase ainda não está configurado. O app continua funcionando e as notificações locais permanecem ativas.',
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
        title: const Text('Notificações', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([store, notifications]),
        builder: (context, _) {
          final token = notifications.token;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SwitchListTile.adaptive(
                value: store.pushNotifications,
                onChanged: (value) => _togglePush(context, value),
                title: const Text('Notificações do aplicativo'),
                subtitle: const Text(
                  'Pede permissão ao dispositivo e ativa o Firebase Cloud Messaging quando configurado.',
                ),
              ),
              SwitchListTile.adaptive(
                value: store.bookingNotifications,
                onChanged: store.setBookingNotifications,
                title: const Text('Agendamentos'),
                subtitle: const Text('Confirmações, cancelamentos e lembretes.'),
              ),
              SwitchListTile.adaptive(
                value: store.marketingNotifications,
                onChanged: store.setMarketingNotifications,
                title: const Text('Novidades e recomendações'),
                subtitle: const Text('Sugestões de novas trilhas e experiências.'),
              ),
              const Divider(height: 30),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  notifications.firebaseReady
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_off_outlined,
                  color: notifications.firebaseReady
                      ? AppColors.green700
                      : AppColors.muted,
                ),
                title: Text(
                  notifications.firebaseReady
                      ? 'Firebase conectado'
                      : 'Firebase não configurado',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text('Permissão: ${notifications.permissionLabel}'),
              ),
              if (token != null && token.isNotEmpty)
                SelectableText(
                  'Token do dispositivo:\n${token.length > 70 ? '${token.substring(0, 70)}...' : token}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () async {
                  await notifications.registerAfterLogin();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        notifications.token == null
                            ? 'Não foi possível obter o token. Confira a configuração do Firebase.'
                            : 'Token FCM capturado e sincronização executada.',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Solicitar permissão e capturar token'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  await store.addNotification(
                    title: 'Notificação de teste',
                    body: 'As notificações internas do RotaFácil estão funcionando.',
                  );

                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notificação de teste criada.'),
                    ),
                  );
                },
                icon: const Icon(Icons.science_outlined),
                label: const Text('Gerar notificação de teste'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationCenterScreen()),
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
