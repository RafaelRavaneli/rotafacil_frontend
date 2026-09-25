import 'package:flutter/material.dart';
import '../../../services/local_auth_service.dart';
import '../../../services/session_service.dart';
import '../../../state/app_store.dart';
import '../../../theme/app_colors.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key, required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return Scaffold(
      appBar: AppBar(
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
              SwitchListTile.adaptive(
                value: store.profileVisible,
                onChanged: store.setProfileVisible,
                title: const Text('Perfil visível'),
                subtitle: const Text(
                  'Controla a visibilidade das informações públicas do perfil.',
                ),
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
            ],
          );
        },
      ),
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
    if (next.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A nova senha deve ter pelo menos 6 caracteres.'),
        ),
      );
      return;
    }
    setState(() => loading = true);
    final ok = await LocalAuthService.instance.changePassword(
      role: widget.role,
      currentPassword: current.text,
      newPassword: next.text,
    );
    if (!mounted) return;
    setState(() => loading = false);
    if (!ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Senha atual incorreta.')));
      return;
    }
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
