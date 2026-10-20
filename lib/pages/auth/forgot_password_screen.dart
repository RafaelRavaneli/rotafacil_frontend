import '../../widgets/auth_scaffold.dart';
import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../services/auth_gateway.dart';
import '../../theme/app_colors.dart';
import '../../utils/auth_error_message.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final email = TextEditingController();
  final password = TextEditingController();

  final code = TextEditingController();
  bool requested = false;
  bool loading = false;

  @override
  void dispose() {
    code.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    final normalizedEmail = email.text.trim();

    if (AppConfig.useBackend && !requested) {
      if (normalizedEmail.isEmpty) return;
      setState(() => loading = true);
      try {
        await AuthGateway.instance.requestPasswordReset(normalizedEmail);
        if (!mounted) return;
        setState(() => requested = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Se o e-mail estiver cadastrado, você receberá um código.',
            ),
          ),
        );
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
        }
      } finally {
        if (mounted) setState(() => loading = false);
      }
      return;
    }
    if (normalizedEmail.isEmpty || password.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Informe o e-mail e uma nova senha com pelo menos 6 caracteres.',
          ),
        ),
      );

      return;
    }

    setState(() => loading = true);

    try {
      await AuthGateway.instance.resetPassword(
        email: normalizedEmail,
        newPassword: password.text,
        token: code.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha redefinida com sucesso.')),
      );

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Recuperar senha',
      body: ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(height: 8),
          const Text(
            AppConfig.useBackend
                ? 'Solicite o código por e-mail e use-o para definir sua nova senha.'
                : 'Informe seu e-mail e escolha uma nova senha.',
            style: TextStyle(color: AppColors.paper),
          ),
          const SizedBox(height: 24),
          AuthLabeledField(
            label: 'E-mail',
            child: TextField(
              style: const TextStyle(color: AppColors.ink),
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(),
            ),
          ),
          const SizedBox(height: 12),
          if (AppConfig.useBackend && requested)
            AuthLabeledField(
              label: 'Código recebido por e-mail',
              child: TextField(
                style: const TextStyle(color: AppColors.ink),
                controller: code,
                decoration: const InputDecoration(),
              ),
            ),
          if (!AppConfig.useBackend || requested)
            AuthLabeledField(
              label: 'Nova senha',
              child: TextField(
                style: const TextStyle(color: AppColors.ink),
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(),
              ),
            ),
          if (AppConfig.useBackend && requested)
            TextButton(
              onPressed: loading
                  ? null
                  : () => setState(() {
                      requested = false;
                      code.clear();
                    }),
              child: const Text('Solicitar outro código'),
            ),
          if (AppConfig.useBackend && !requested)
            TextButton(
              onPressed: () => setState(() => requested = true),
              child: const Text('Já tenho um código'),
            ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: loading ? null : _reset,
            child: Text(
              loading
                  ? 'Aguarde...'
                  : AppConfig.useBackend && !requested
                  ? 'Enviar código'
                  : 'Redefinir senha',
            ),
          ),
        ],
      ),
    );
  }
}
