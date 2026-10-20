import 'package:flutter/material.dart';
import '../../services/auth_gateway.dart';
import '../../theme/app_colors.dart';
import '../../utils/auth_error_message.dart';
import '../../widgets/auth_scaffold.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({
    super.key,
    this.initialEmail = '',
    this.initiallySent = false,
    this.returnToLogin = false,
    this.gateway,
  });
  final String initialEmail;
  final bool initiallySent;
  final bool returnToLogin;
  final AuthGateway? gateway;
  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  late final email = TextEditingController(text: widget.initialEmail);
  bool loading = false;
  late bool sent = widget.initiallySent;
  DateTime? nextSend;
  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (loading) return;
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um e-mail válido.')),
      );
      return;
    }
    if (nextSend != null && DateTime.now().isBefore(nextSend!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aguarde um minuto antes de reenviar o link.'),
        ),
      );
      return;
    }
    setState(() => loading = true);
    try {
      await (widget.gateway ?? AuthGateway.instance).requestEmailConfirmation(
        email.text,
      );
      if (!mounted) return;
      setState(() {
        sent = true;
        nextSend = DateTime.now().add(const Duration(minutes: 1));
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthScaffold(
    title: 'Confirmar e-mail',
    body: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          sent
              ? 'Se o endereço precisar de confirmação, enviaremos um link. Abra o e-mail e toque no link para confirmar e entrar. Confira também o spam. O link vale por 30 minutos.'
              : 'Receba um link para confirmar seu e-mail e entrar na sua conta.',
          style: const TextStyle(color: AppColors.paper),
        ),
        const SizedBox(height: 20),
        AuthLabeledField(
          label: 'E-mail',
          child: TextField(
            controller: email,
            enabled: !loading,
            style: const TextStyle(color: AppColors.ink),
            keyboardType: TextInputType.emailAddress,
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: loading ? null : _send,
          child: Text(
            loading
                ? 'Aguarde...'
                : sent
                ? 'Reenviar link'
                : 'Enviar link',
          ),
        ),
      ],
    ),
  );
}
