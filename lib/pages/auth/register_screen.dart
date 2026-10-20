import '../../widgets/auth_scaffold.dart';
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
  bool credentialsStep = false;

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
      MaterialPageRoute(
        builder: (_) => LoginScreen(initialEmail: registration.email),
      ),
    );
  }

  void _continue() {
    if (nameController.text.trim().isEmpty ||
        (needsDocument &&
            !DocumentValidator.isValidForRole(
              widget.role.title,
              documentController.text,
            ))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            needsDocument
                ? 'Informe o nome e um $documentLabel válido para continuar.'
                : 'Informe seu nome para continuar.',
          ),
        ),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => credentialsStep = true);
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    String? hint,
    TextInputType? keyboard,
    bool secret = false,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFFD2FA87), fontSize: 13),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            enabled: !loading,
            keyboardType: keyboard,
            maxLength: maxLength,
            textCapitalization: maxLength == 2
                ? TextCapitalization.characters
                : TextCapitalization.none,
            obscureText: secret && obscure,
            style: const TextStyle(color: AppColors.ink, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              counterText: '',
              filled: true,
              fillColor: const Color(0xFFFFFEF7),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: Color(0xFFCFD5C4)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: Color(0xFFCFD5C4)),
              ),
              suffixIcon: secret
                  ? IconButton(
                      tooltip: obscure ? 'Mostrar senha' : 'Ocultar senha',
                      onPressed: loading
                          ? null
                          : () => setState(() => obscure = !obscure),
                      icon: Icon(
                        obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Cadastro • ${widget.role.title}',
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        reverseDuration: const Duration(milliseconds: 240),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: Column(
          key: ValueKey<bool>(credentialsStep),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!credentialsStep) ...[
              _field(
                widget.role == UserRole.agency
                    ? 'Razão Social'
                    : 'Nome completo',
                nameController,
              ),
              _field(
                'Telefone',
                phoneController,
                hint: '(00) 00000-0000',
                keyboard: TextInputType.phone,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _field('Cidade', cityController, hint: 'Maringá'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _field(
                      'UF',
                      stateController,
                      hint: 'PR',
                      maxLength: 2,
                    ),
                  ),
                ],
              ),
              if (needsDocument)
                _field(
                  documentLabel,
                  documentController,
                  hint: widget.role == UserRole.guide
                      ? '000.000.000-00'
                      : '00.000.000/0000-00',
                  keyboard: TextInputType.number,
                ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 100,
                  height: 42,
                  child: FilledButton(
                    onPressed: _continue,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4F682B),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      semanticLabel: 'Continuar',
                    ),
                  ),
                ),
              ),
            ] else ...[
              _field(
                'E-mail',
                emailController,
                keyboard: TextInputType.emailAddress,
              ),
              _field(
                'Senha',
                passwordController,
                hint: 'Mínimo de 6 caracteres',
                secret: true,
              ),
              CheckboxListTile(
                value: acceptTerms,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: const Color(0xFF4F682B),
                side: const BorderSide(color: Color(0xFFD2FA87)),
                title: const Text(
                  'Aceito os Termos de Uso e Política de Privacidade',
                  style: TextStyle(fontSize: 12, color: Color(0xFFFFFEF7)),
                ),
                onChanged: loading
                    ? null
                    : (value) => setState(() => acceptTerms = value ?? false),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: loading ? null : _create,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4F682B),
                ),
                child: Text(loading ? 'Criando...' : 'Criar conta'),
              ),
              TextButton(
                onPressed: loading
                    ? null
                    : () => setState(() => credentialsStep = false),
                child: const Text(
                  'Voltar aos dados',
                  style: TextStyle(color: Color(0xFFD2FA87)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
