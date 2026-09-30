import 'package:flutter/material.dart';

import '../../services/notification_service.dart';
import '../../services/session_service.dart';
import '../../state/app_store.dart';
import '../../theme/app_colors.dart';
import '../../utils/document_validator.dart';
import '../../widgets/profile_avatar.dart';
import '../auth/welcome_screen.dart';
import '../agency/remote_guides_screen.dart';
import '../../utils/role_utils.dart';
import 'favorites_screen.dart';
import 'notification_center_screen.dart';
import 'settings/help_support_screen.dart';
import 'settings/notifications_screen.dart';
import 'settings/personal_data_screen.dart';
import 'settings/privacy_security_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key, this.role = 'Turista'});

  final String role;

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;

    return SafeArea(
      child: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final user = store.userForRole(role);

          final showDocument = user.document.isNotEmpty;

          return ListView(
            padding: const EdgeInsets.all(22),
            children: [
              const SizedBox(height: 10),
              Center(
                child: ProfileAvatar(
                  dataUrl: user.profileImageDataUrl,
                  radius: 46,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                user.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.green900,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.role,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              if (showDocument) ...[
                const SizedBox(height: 4),
                Text(
                  '${DocumentValidator.labelForRole(role)}: '
                  '${DocumentValidator.formatForRole(role, user.document)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
              const SizedBox(height: 28),
              _ProfileItem(
                icon: Icons.edit_outlined,
                title: 'Editar perfil',
                subtitle: 'Foto, nome, e-mail, telefone, cidade e documento',
                onTap: () => _open(context, PersonalDataScreen(role: role)),
              ),
              _ProfileItem(
                icon: Icons.person_outline_rounded,
                title: 'Dados pessoais',
                onTap: () => _open(context, PersonalDataScreen(role: role)),
              ),
              if (role.toLowerCase() == 'turista')
                _ProfileItem(
                  icon: Icons.favorite_border_rounded,
                  title: 'Trilhas favoritas',
                  onTap: () => _open(context, const FavoritesScreen()),
                ),
              _ProfileItem(
                icon: Icons.notifications_none_rounded,
                title: 'Notificações',
                subtitle: '${store.unreadNotifications} não lida(s)',
                onTap: () => _open(context, const NotificationsScreen()),
              ),
              _ProfileItem(
                icon: Icons.notifications_active_outlined,
                title: 'Central de notificações',
                onTap: () => _open(context, const NotificationCenterScreen()),
              ),
              _ProfileItem(
                icon: Icons.security_outlined,
                title: 'Privacidade e segurança',
                onTap: () => _open(context, PrivacySecurityScreen(role: role)),
              ),
              _ProfileItem(
                icon: Icons.help_outline_rounded,
                title: 'Ajuda e suporte',
                subtitle: 'Converse com a equipe RotaFácil',
                onTap: () => _open(context, HelpSupportScreen(role: role)),
              ),
              if (store.useBackend && normalizeRoleKey(role) == 'guia')
                _ProfileItem(
                  icon: Icons.business_outlined,
                  title: 'Convites de agências',
                  onTap: () => _open(context, const RemoteGuidesScreen()),
                ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () async {
                  await NotificationService.instance.unregisterOnLogout();

                  await SessionService.instance.clear();

                  if (!context.mounted) {
                    return;
                  }

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (_) => false,
                  );
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sair'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

class _ProfileItem extends StatelessWidget {
  const _ProfileItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.green700),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: const TextStyle(fontSize: 11.5)),
      trailing: const Icon(Icons.chevron_right_rounded),
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
    );
  }
}
