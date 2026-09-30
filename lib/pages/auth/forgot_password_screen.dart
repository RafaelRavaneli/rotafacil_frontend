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
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Redefinir senha',
            style: TextStyle(
              color: AppColors.green900,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            AppConfig.useBackend
                ? 'Solicite o código por e-mail e use-o para definir sua nova senha.'
                : 'Informe seu e-mail e escolha uma nova senha.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'E-mail'),
          ),
          const SizedBox(height: 12),
          if (AppConfig.useBackend)
            TextField(
              controller: code,
              decoration: const InputDecoration(
                labelText: 'Código recebido por e-mail',
              ),
            ),
          if (!AppConfig.useBackend || requested)
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Nova senha'),
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
