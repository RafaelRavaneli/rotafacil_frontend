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

  DateTime? nextSend;
  bool requested = false;
  bool loading = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    if (loading) return;
    final normalizedEmail = email.text.trim();

    if (AppConfig.useBackend) {
      if (nextSend != null && DateTime.now().isBefore(nextSend!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aguarde um minuto antes de reenviar o link.'),
          ),
        );
        return;
      }
      if (normalizedEmail.isEmpty) return;
      setState(() => loading = true);
      try {
        await AuthGateway.instance.requestPasswordReset(normalizedEmail);
        if (!mounted) return;
        setState(() {
          requested = true;
          nextSend = DateTime.now().add(const Duration(minutes: 1));
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Se o e-mail estiver cadastrado, você receberá um link. Abra o e-mail para definir uma nova senha.',
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
      largeLogo: true,
      body: ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(height: 8),
          const Text(
            AppConfig.useBackend
                ? 'Receba um link por e-mail para escolher uma nova senha e entrar na sua conta.'
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
          if (!AppConfig.useBackend)
            AuthLabeledField(
              label: 'Nova senha',
              child: TextField(
                controller: password,
                obscureText: true,
                style: const TextStyle(color: AppColors.ink),
              ),
            ),
          if (AppConfig.useBackend && requested)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Confira sua caixa de entrada e a pasta de spam. O link vale por 30 minutos.',
                style: TextStyle(color: AppColors.paper),
              ),
            ),
          const SizedBox(height: 20),
          Center(
            child: FilledButton(
              onPressed: loading ? null : _reset,
              style: FilledButton.styleFrom(
                minimumSize: const Size(160, 52),
                shape: const StadiumBorder(),
              ),
              child: Text(
                loading
                    ? 'Aguarde...'
                    : AppConfig.useBackend
                    ? (requested ? 'Reenviar link' : 'Enviar link')
                    : 'Redefinir senha',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
