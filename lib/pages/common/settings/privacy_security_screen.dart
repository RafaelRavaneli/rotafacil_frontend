import '../../auth/verify_email_screen.dart';
import '../legal_document_screen.dart';
import '../../../config/app_config.dart';
import '../../../navigation/auth_page_route.dart';
import '../../../widgets/app_back_button.dart';
import '../../../utils/cadastur_validator.dart';
import '../../../utils/date_time_format.dart';
import '../../../widgets/cadastur_fields.dart';
import 'package:flutter/material.dart';
import '../../../services/auth_gateway.dart';
import '../../../services/notification_service.dart';
import '../../../services/session_service.dart';
import '../../../state/app_store.dart';
import '../../../theme/app_colors.dart';
import '../../../models/user_role.dart';
import '../../../utils/document_validator.dart';
import '../../../utils/role_utils.dart';
import '../../../utils/run_action.dart';
import '../../auth/welcome_screen.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key, required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackLocation: '/perfil'),
        title: const Text(
          'Privacidade e segurança',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const LegalLinks(),
              SwitchListTile.adaptive(
                value: store.profileVisible,
                onChanged: store.setProfileVisible,
                title: const Text('Perfil visível'),
                subtitle: const Text(
                  'Controla a visibilidade das informações públicas do perfil.',
                ),
              ),
              if (AppConfig.useBackend)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    store.userForRole(role).emailConfirmed
                        ? Icons.mark_email_read_outlined
                        : Icons.mark_email_unread_outlined,
                  ),
                  title: Text(
                    store.userForRole(role).emailConfirmed
                        ? 'E-mail confirmado'
                        : 'Confirmar e-mail',
                  ),
                  subtitle: Text(store.userForRole(role).email),
                  onTap: store.userForRole(role).emailConfirmed
                      ? null
                      : () async {
                          final verified = await Navigator.push<bool>(
                            context,
                            AuthPageRoute<bool>(
                              builder: (_) => VerifyEmailScreen(
                                initialEmail: store.userForRole(role).email,
                              ),
                            ),
                          );
                          if (verified == true && context.mounted) {
                            await runAction(context, store.refreshBackend);
                          }
                        },
                ),
              const Divider(height: 30),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.password_rounded,
                  color: AppColors.green700,
                ),
                title: const Text(
                  'Alterar senha',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => _PasswordDialog(role: role),
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.devices_outlined,
                  color: AppColors.green700,
                ),
                title: const Text(
                  'Sessão atual',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  SessionService.instance.email ?? 'Sessão local ativa',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Sessão atual'),
                      content: Text(
                        'Perfil: $role\nE-mail: ${SessionService.instance.email ?? 'local'}\nToken de API: ${SessionService.instance.token == null ? 'não utilizado no modo local' : 'armazenado na sessão'}',
                      ),
                      actions: [
                        FilledButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              if (store.useBackend)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.manage_accounts_outlined,
                    color: AppColors.green700,
                  ),
                  title: const Text(
                    'Alterar tipo da conta',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Text(
                    'Exige novo login e não permite reservas ativas.',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) =>
                          _ChangeAccountTypeDialog(currentRole: role),
                    );
                  },
                ),
              const Divider(height: 30),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.delete_forever_outlined,
                  color: Colors.red,
                ),
                title: const Text(
                  'Excluir conta',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: const Text(
                  'A exclusão é bloqueada enquanto houver reservas ativas.',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => _DeleteAccountDialog(role: role),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChangeAccountTypeDialog extends StatefulWidget {
  const _ChangeAccountTypeDialog({required this.currentRole});

  final String currentRole;

  @override
  State<_ChangeAccountTypeDialog> createState() =>
      _ChangeAccountTypeDialogState();
}

class _ChangeAccountTypeDialogState extends State<_ChangeAccountTypeDialog> {
  final document = TextEditingController();
  final cadastur = TextEditingController();
  final cadasturValidity = TextEditingController();
  late UserRole selected;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    final current = normalizeRoleKey(widget.currentRole);
    selected = current == 'usuario' ? UserRole.guide : UserRole.tourist;
  }

  @override
  void dispose() {
    document.dispose();
    cadastur.dispose();
    cadasturValidity.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final needsDocument = selected != UserRole.tourist;
    if (needsDocument &&
        !DocumentValidator.isValidForRole(selected.title, document.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Informe um ${DocumentValidator.labelForRole(selected.title)} válido.',
          ),
        ),
      );
      return;
    }

    if (needsDocument) {
      final error = CadasturValidator.error(cadastur.text);
      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
        return;
      }
    }
    setState(() => loading = true);
    final changed = await runAction(
      context,
      () => AppStore.instance.changeAccountType(
        type: selected.apiValue,
        cadasturNumber: needsDocument
            ? CadasturValidator.normalize(cadastur.text)
            : null,
        cadasturValidUntil: needsDocument
            ? (parseAppDateTime(
                    cadasturValidity.text,
                  )?.toIso8601String().split('T').first ??
                  '')
            : null,
        document: needsDocument
            ? DocumentValidator.digitsOnly(document.text)
            : null,
      ),
    );
    if (!mounted) return;
    if (!changed) {
      setState(() => loading = false);
      return;
    }

    await NotificationService.instance.unregisterOnLogout();
    await SessionService.instance.clear();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = normalizeRoleKey(widget.currentRole);
    final options = UserRole.values
        .where((item) => item.apiValue != current)
        .toList();
    final needsDocument = selected != UserRole.tourist;
    return AlertDialog(
      title: const Text('Alterar tipo da conta'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Atividades e vínculos do perfil atual serão encerrados. Reservas históricas permanecem.',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<UserRole>(
              initialValue: selected,
              items: options
                  .map(
                    (item) =>
                        DropdownMenuItem(value: item, child: Text(item.title)),
                  )
                  .toList(),
              onChanged: loading
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() {
                        selected = value;
                        document.clear();
                      });
                    },
              decoration: const InputDecoration(labelText: 'Novo tipo'),
            ),
            if (needsDocument) ...[
              const SizedBox(height: 12),
              TextField(
                controller: document,
                enabled: !loading,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: DocumentValidator.labelForRole(selected.title),
                ),
              ),
              const SizedBox(height: 12),
              CadasturFields(
                number: cadastur,
                validUntil: cadasturValidity,
                enabled: !loading,
              ),
            ],
            const SizedBox(height: 12),
            const Text('Após a alteração, faça login novamente.'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: loading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: loading ? null : _save,
          child: Text(loading ? 'Alterando...' : 'Confirmar alteração'),
        ),
      ],
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({required this.role});

  final String role;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final confirmation = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    confirmation.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    setState(() => loading = true);
    final deleted = await runAction(
      context,
      () => AppStore.instance.deleteCurrentAccount(widget.role),
    );
    if (!mounted) return;
    if (!deleted) {
      setState(() => loading = false);
      return;
    }

    await NotificationService.instance.unregisterOnLogout();
    await SessionService.instance.clear();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final confirmed = confirmation.text.trim().toUpperCase() == 'EXCLUIR';
    return AlertDialog(
      title: const Text('Excluir conta?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Esta ação remove o perfil e encerra a sessão. Reservas históricas são preservadas. Atividades próprias saem do catálogo.',
          ),
          const SizedBox(height: 16),
          const Text('Digite EXCLUIR para confirmar.'),
          const SizedBox(height: 8),
          TextField(
            controller: confirmation,
            enabled: !loading,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Confirmação'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: loading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: loading || !confirmed ? null : _delete,
          child: Text(loading ? 'Excluindo...' : 'Excluir conta'),
        ),
      ],
    );
  }
}

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog({required this.role});
  final String role;

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final current = TextEditingController();
  final next = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    current.dispose();
    next.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (current.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Informe sua senha atual.')));
      return;
    }
    if (next.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A nova senha deve ter pelo menos 6 caracteres.'),
        ),
      );
      return;
    }
    setState(() => loading = true);
    final ok = await runAction(
      context,
      () => AuthGateway.instance.changePassword(
        role: widget.role,
        currentPassword: current.text,
        newPassword: next.text,
      ),
    );
    if (!mounted) return;
    setState(() => loading = false);
    if (!ok) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Senha alterada com sucesso.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Alterar senha'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: current,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Senha atual'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: next,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Nova senha'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: loading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: loading ? null : _save,
          child: Text(loading ? 'Salvando...' : 'Salvar'),
        ),
      ],
    );
  }
}
