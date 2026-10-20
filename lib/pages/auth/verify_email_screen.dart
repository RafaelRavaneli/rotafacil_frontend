import 'package:flutter/material.dart';
import '../../navigation/auth_page_route.dart';
import '../../services/auth_gateway.dart';
import '../../theme/app_colors.dart';
import '../../utils/auth_error_message.dart';
import '../../widgets/auth_scaffold.dart';
import 'login_screen.dart';

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
  final code = TextEditingController();
  bool loading = false;
  late bool sent = widget.initiallySent;
  DateTime? nextSend;
  @override
  void dispose() {
    email.dispose();
    code.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool send}) async {
    if (loading) return;
    final normalizedEmail = email.text.trim().toLowerCase();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(normalizedEmail) ||
        (!send && code.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Informe um e-mail válido e o código recebido para confirmar.',
          ),
        ),
      );
      return;
    }
    if (send && nextSend != null && DateTime.now().isBefore(nextSend!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aguarde um minuto antes de reenviar o código.'),
        ),
      );
      return;
    }
    setState(() => loading = true);
    try {
      final gateway = widget.gateway ?? AuthGateway.instance;
      if (send) {
        await gateway.requestEmailConfirmation(normalizedEmail);
        if (!mounted) return;
        setState(() {
          sent = true;
          nextSend = DateTime.now().add(const Duration(minutes: 1));
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Se o endereço precisar de confirmação, enviaremos um código. Confira também a pasta de spam.',
            ),
          ),
        );
      } else {
        await gateway.confirmEmail(normalizedEmail, code.text);
        if (!mounted) return;
        if (widget.returnToLogin) {
          Navigator.pushReplacement(
            context,
            AuthPageRoute<void>(
              builder: (_) => LoginScreen(initialEmail: normalizedEmail),
            ),
          );
        } else {
          Navigator.pop(context, true);
        }
      }
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
              ? 'Copie o código recebido por e-mail. Ele vale por 30 minutos.'
              : 'Envie um código para confirmar que este e-mail pertence a você.',
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
        const SizedBox(height: 14),
        AuthLabeledField(
          label: 'Código recebido por e-mail',
          child: TextField(
            controller: code,
            enabled: !loading,
            style: const TextStyle(color: AppColors.ink),
            autocorrect: false,
            enableSuggestions: false,
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: loading ? null : () => _submit(send: false),
          child: Text(loading ? 'Aguarde...' : 'Confirmar e-mail'),
        ),
        TextButton(
          onPressed: loading ? null : () => _submit(send: true),
          child: Text(sent ? 'Reenviar código' : 'Enviar código'),
        ),
      ],
    ),
  );
}
