import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../services/auth_gateway.dart';
import '../../services/notification_service.dart';
import '../../state/app_store.dart';
import '../../theme/app_colors.dart';
import '../agency/agency_shell.dart';
import '../guide/guide_shell.dart';
import '../tourist/tourist_shell.dart';
import 'forgot_password_screen.dart';
import 'profile_choice_screen.dart';
import '../../utils/auth_error_message.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscure = true;
  bool loading = false;

  @override
  void initState() {
    super.initState();

    emailController.text = widget.initialEmail;
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Preencha e-mail e senha.')));

      return;
    }

    setState(() => loading = true);

    late String resolvedRole;

    try {
      final result = await AuthGateway.instance.login(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (result == null) {
        setState(() => loading = false);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('E-mail ou senha inválidos.')));

        return;
      }

      resolvedRole = result.role.toLowerCase().trim();

      await AppStore.instance.refreshBackend();
      try {
        await NotificationService.instance.registerAfterLogin();
      } catch (_) {
        // Notificações opcionais não impedem o acesso à conta.
      }
    } catch (error) {
      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(authErrorMessage(error))));

      return;
    }

    if (!mounted) return;

    final Widget destination = switch (resolvedRole) {
      'guia' => const GuideShell(),
      'agencia' => const AgencyShell(),
      'usuario' => const TouristShell(),
      _ => throw StateError('Perfil não suportado.'),
    };

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => destination),
      (_) => false,
    );
  }

  String get demoText =>
      'Demonstração: thiago@email.com (turista), guia@email.com (guia) ou contato@aventuraprime.com (agência). Senha: 123456.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          children: [
            const SizedBox(height: 14),
            const Text(
              'Bem-vindo de volta! 👋',
              style: TextStyle(
                color: AppColors.green900,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -.7,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Entre com seu e-mail e senha para continuar.',
              style: TextStyle(color: AppColors.muted, fontSize: 13.5),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.username],
              decoration: const InputDecoration(
                labelText: 'E-mail',
                hintText: 'Seu e-mail cadastrado',
              ),
            ),

            const SizedBox(height: 14),
            TextField(
              controller: passwordController,
              obscureText: obscure,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'Senha',
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() => obscure = !obscure);
                  },
                  icon: Icon(
                    obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Esqueci minha senha',
                  style: TextStyle(
                    color: AppColors.green700,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            FilledButton(
              onPressed: loading ? null : _login,
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.white,
                      ),
                    )
                  : const Text('Entrar'),
            ),
            const SizedBox(height: 18),
            if (!AppConfig.useBackend)
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: AppColors.green100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  demoText,
                  style: const TextStyle(
                    color: AppColors.green900,
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Ainda não tem conta?',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfileChoiceScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Criar conta',
                    style: TextStyle(
                      color: AppColors.green700,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
