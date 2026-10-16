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
import 'professional_documents_screen.dart';
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
          final normalizedRole = normalizeRoleKey(role);
          final activityCount = normalizedRole == 'turista'
              ? store.bookings
                    .where((item) => item.roleView == 'turista')
                    .length
              : store.managedTrails.length;
          final activityLabel = normalizedRole == 'turista'
              ? 'reservas'
              : 'roteiros';

          return ListView(
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 34),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Perfil',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  Material(
                    color: AppColors.white,
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'Notificações',
                      onPressed: () =>
                          _open(context, const NotificationCenterScreen()),
                      icon: Badge(
                        isLabelVisible: store.unreadNotifications > 0,
                        label: Text('${store.unreadNotifications}'),
                        child: const Icon(Icons.notifications_none_rounded),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ProfileAvatar(
                      dataUrl: user.profileImageDataUrl,
                      radius: 46,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.role,
                            style: const TextStyle(color: AppColors.muted),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            '$activityCount $activityLabel',
                            style: const TextStyle(
                              color: AppColors.forest,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (showDocument) ...[
                const SizedBox(height: 12),
                Text(
                  '${DocumentValidator.labelForRole(role)}: '
                  '${DocumentValidator.formatForRole(role, user.document)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
              const SizedBox(height: 30),
              const Text(
                'Conta',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
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
                  title: 'Roteiros favoritos',
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
              if (store.useBackend &&
                  {'guia', 'agencia'}.contains(normalizeRoleKey(role)))
                _ProfileItem(
                  icon: Icons.badge_outlined,
                  title: 'Documentos profissionais',
                  subtitle: 'Envio privado e acompanhamento da análise',
                  onTap: () =>
                      _open(context, const ProfessionalDocumentsScreen()),
                ),
              _ProfileItem(
                icon: Icons.help_outline_rounded,
                title: 'Ajuda',
                subtitle: 'Orientações para usar o aplicativo',
                onTap: () => _open(context, HelpSupportScreen(role: role)),
              ),
              if (store.useBackend && normalizeRoleKey(role) == 'guia')
                _ProfileItem(
                  icon: Icons.business_outlined,
                  title: 'Convites de agências',
                  onTap: () => _open(context, const RemoteGuidesScreen()),
                ),
              const SizedBox(height: 24),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: .6)),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.ink),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: subtitle == null
            ? null
            : Text(subtitle!, style: const TextStyle(fontSize: 11.5)),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.muted,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
        onTap: onTap,
      ),
    );
  }
}
