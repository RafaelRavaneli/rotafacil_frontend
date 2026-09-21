import 'package:flutter/material.dart';

import '../../models/user_role.dart';
import '../../services/auth_gateway.dart';
import '../../services/notification_service.dart';
import '../../state/app_store.dart';
import '../../theme/app_colors.dart';
import '../../utils/document_validator.dart';
import '../agency/agency_shell.dart';
import '../guide/guide_shell.dart';
import '../tourist/tourist_shell.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.role,
  });

  final UserRole role;

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController =
      TextEditingController();
  final passwordController =
      TextEditingController();
  final documentController =
      TextEditingController();

  bool obscure = true;
  bool loading = false;

  bool get needsDocument {
    return widget.role == UserRole.guide ||
        widget.role == UserRole.agency;
  }

  String get documentLabel {
    return widget.role == UserRole.guide
        ? 'CPF'
        : 'CNPJ';
  }

  @override
  void initState() {
    super.initState();

    final user =
        AppStore.instance.userForRole(
      widget.role.title,
    );

    emailController.text = user.email;

    if (needsDocument) {
      documentController.text =
          DocumentValidator.formatForRole(
        widget.role.title,
        user.document,
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    documentController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email =
        emailController.text.trim();
    final password =
        passwordController.text;
    final document =
        documentController.text.trim();

    if (email.isEmpty ||
        password.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Preencha e-mail e senha.',
          ),
        ),
      );

      return;
    }

    if (needsDocument &&
        !DocumentValidator.isValidForRole(
          widget.role.title,
          document,
        )) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '$documentLabel inválido. '
            'Informe um $documentLabel válido para entrar.',
          ),
        ),
      );

      return;
    }

    setState(() => loading = true);

    String resolvedRole =
        widget.role.apiValue;

    try {
      final result =
          await AuthGateway.instance.login(
        selectedRole: widget.role,
        email: email,
        password: password,
        document: document,
      );

      if (!mounted) return;

      if (result == null) {
        setState(() => loading = false);

        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              needsDocument
                  ? 'E-mail, senha ou $documentLabel incorretos.'
                  : 'E-mail ou senha inválidos.',
            ),
          ),
        );

        return;
      }

      resolvedRole =
          result.role.toLowerCase().trim();

      await NotificationService.instance
          .registerAfterLogin();
    } catch (error) {
      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            error.toString(),
          ),
        ),
      );

      return;
    }

    if (!mounted) return;

    final Widget destination =
        switch (resolvedRole) {
      'guia' => const GuideShell(),
      'agencia' => const AgencyShell(),
      _ => const TouristShell(),
    };

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => destination,
      ),
      (_) => false,
    );
  }

  String get demoText {
    if (widget.role == UserRole.guide) {
      return 'Demonstração: senha 123456 • '
          'CPF 529.982.247-25';
    }

    if (widget.role == UserRole.agency) {
      return 'Demonstração: senha 123456 • '
          'CNPJ 11.222.333/0001-81';
    }

    return 'Demonstração: use o e-mail preenchido '
        'e a senha 123456.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding:
              const EdgeInsets.fromLTRB(
            24,
            12,
            24,
            32,
          ),
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
            Text(
              'Entre para continuar como '
              '${widget.role.title.toLowerCase()}.',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: emailController,
              keyboardType:
                  TextInputType.emailAddress,
              decoration:
                  const InputDecoration(
                labelText: 'E-mail',
              ),
            ),
            if (needsDocument) ...[
              const SizedBox(height: 14),
              TextField(
                controller:
                    documentController,
                keyboardType:
                    TextInputType.number,
                decoration: InputDecoration(
                  labelText: documentLabel,
                  helperText:
                      '$documentLabel obrigatório para o acesso.',
                  prefixIcon: const Icon(
                    Icons.badge_outlined,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            TextField(
              controller:
                  passwordController,
              obscureText: obscure,
              decoration: InputDecoration(
                labelText: 'Senha',
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(
                      () => obscure = !obscure,
                    );
                  },
                  icon: Icon(
                    obscure
                        ? Icons
                            .visibility_outlined
                        : Icons
                            .visibility_off_outlined,
                  ),
                ),
              ),
            ),
            Align(
              alignment:
                  Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ForgotPasswordScreen(
                        role: widget.role,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Esqueci minha senha',
                  style: TextStyle(
                    color:
                        AppColors.green700,
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ),
            FilledButton(
              onPressed:
                  loading ? null : _login,
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color:
                            AppColors.white,
                      ),
                    )
                  : const Text('Entrar'),
            ),
            const SizedBox(height: 18),
            Container(
              padding:
                  const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color:
                    AppColors.green100,
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
              child: Text(
                demoText,
                style: const TextStyle(
                  color:
                      AppColors.green900,
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                const Text(
                  'Ainda não tem conta?',
                  style: TextStyle(
                    color:
                        AppColors.muted,
                    fontSize: 12,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            RegisterScreen(
                          role: widget.role,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'Criar conta',
                    style: TextStyle(
                      color:
                          AppColors.green700,
                      fontWeight:
                          FontWeight.w800,
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
