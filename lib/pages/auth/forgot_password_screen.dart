import 'package:flutter/material.dart';

import '../../models/user_role.dart';
import '../../services/local_auth_service.dart';
import '../../theme/app_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, required this.role});

  final UserRole role;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    if (email.text.trim().isEmpty || password.text.length < 6) {
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
      await LocalAuthService.instance.resetPassword(
        role: widget.role.title,
        email: email.text,
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
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => loading = false);
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
            'No modo local, a senha é atualizada neste dispositivo.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'E-mail'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Nova senha'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: loading ? null : _reset,
            child: Text(loading ? 'Salvando...' : 'Redefinir senha'),
          ),
        ],
      ),
    );
  }
}
