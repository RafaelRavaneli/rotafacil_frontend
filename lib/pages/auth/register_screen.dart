import 'package:flutter/material.dart';

import '../../models/user_role.dart';
import '../../services/auth_gateway.dart';
import '../../state/app_store.dart';
import '../../theme/app_colors.dart';
import '../../utils/document_validator.dart';
import 'login_screen.dart';
import '../../utils/auth_error_message.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.role});

  final UserRole role;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final passwordController = TextEditingController();
  final documentController = TextEditingController();

  bool acceptTerms = false;
  bool obscure = true;
  bool loading = false;

  bool get needsDocument {
    return widget.role == UserRole.guide || widget.role == UserRole.agency;
  }

  String get documentLabel {
    return widget.role == UserRole.guide ? 'CPF' : 'CNPJ';
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    cityController.dispose();
    stateController.dispose();
    passwordController.dispose();
    documentController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.length < 6 ||
        !acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Preencha nome, e-mail, senha com 6+ caracteres '
            'e aceite os termos.',
          ),
        ),
      );

      return;
    }

    if (needsDocument &&
        !DocumentValidator.isValidForRole(
          widget.role.title,
          documentController.text,
        )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$documentLabel inválido. '
            'Informe um $documentLabel válido para criar a conta.',
          ),
        ),
      );

      return;
    }

    setState(() => loading = true);

    late final AuthRegisterResult registration;

    try {
      registration = await AuthGateway.instance.register(
        role: widget.role,
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
        phone: phoneController.text.trim(),
        city: cityController.text.trim(),
        state: stateController.text.trim().toUpperCase(),
        document: documentController.text.trim(),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(authErrorMessage(error))));

      return;
    }

    if (!registration.fromBackend) {
      await AppStore.instance.updateUser(
        registration.role,
        name: registration.name,
        email: registration.email,
        phone: phoneController.text.trim(),
        city: cityController.text.trim(),
        state: stateController.text.trim().toUpperCase(),
        document: DocumentValidator.digitsOnly(documentController.text),
      );
    }

    if (!mounted) return;

    setState(() => loading = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen(role: widget.role)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
          children: [
            const Text(
              'Criar sua conta',
              style: TextStyle(
                color: AppColors.green900,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Perfil: ${widget.role.title}',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nome completo'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-mail'),
            ),
            if (needsDocument) ...[
              const SizedBox(height: 12),
              TextField(
                controller: documentController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: documentLabel,
                  helperText:
                      '$documentLabel obrigatório para ${widget.role.title.toLowerCase()}.',
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Telefone'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: cityController,
                    decoration: const InputDecoration(labelText: 'Cidade'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: stateController,
                    maxLength: 2,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'UF',
                      counterText: '',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: obscure,
              decoration: InputDecoration(
                labelText: 'Senha',
                helperText: 'Mínimo de 6 caracteres.',
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
            CheckboxListTile(
              value: acceptTerms,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.green700,
              title: const Text(
                'Aceito os Termos de Uso '
                'e Política de Privacidade',
                style: TextStyle(fontSize: 12),
              ),
              onChanged: (value) {
                setState(() => acceptTerms = value ?? false);
              },
            ),
            FilledButton(
              onPressed: loading ? null : _create,
              child: Text(loading ? 'Criando...' : 'Criar conta'),
            ),
          ],
        ),
      ),
    );
  }
}
