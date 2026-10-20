import 'package:flutter/material.dart';
import '../../widgets/auth_scaffold.dart';
import '../../theme/app_colors.dart';
import '../../services/auth_gateway.dart';
import '../../services/session_service.dart';
import '../../navigation/app_routes.dart';
import '../../navigation/authenticated_navigation.dart';
import '../../utils/auth_error_message.dart';

class AccountLinkScreen extends StatefulWidget {
  const AccountLinkScreen({
    super.key,
    required this.email,
    required this.token,
    this.recoverPassword = false,
    this.gateway,
    this.onAuthenticated,
  });
  final String email;
  final String token;
  final bool recoverPassword;
  final AuthGateway? gateway;
  final Future<void> Function(String role)? onAuthenticated;
  @override
  State<AccountLinkScreen> createState() => _AccountLinkScreenState();
}

class _AccountLinkScreenState extends State<AccountLinkScreen> {
  final password = TextEditingController();
  final repeatPassword = TextEditingController();
  bool loading = false;
  bool authenticated = false;
  String? error;
  @override
  void initState() {
    super.initState();
    // O segredo permanece apenas na memória desta tela, nunca no histórico.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AppRoutes.replaceBrowserLocation(
          widget.recoverPassword ? '/redefinir-senha' : '/confirmar-email',
        );
      }
    });
  }

  @override
  void dispose() {
    password.dispose();
    repeatPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (loading) return;
    if (!authenticated &&
        (widget.token.length < 20 ||
            widget.token.length > 128 ||
            (!widget.recoverPassword && widget.email.isEmpty))) {
      setState(
        () => error = 'Link inválido ou incompleto. Solicite um novo link.',
      );
      return;
    }
    if (!authenticated &&
        widget.recoverPassword &&
        (password.text.length < 6 ||
            password.text.length > 128 ||
            password.text != repeatPassword.text)) {
      setState(
        () => error = 'Informe e repita a mesma senha, com 6 a 128 caracteres.',
      );
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final gateway = widget.gateway ?? AuthGateway.instance;
      if (!authenticated) {
        if (widget.recoverPassword) {
          await gateway.resetPasswordAndLogin(
            token: widget.token,
            newPassword: password.text,
          );
        } else {
          await gateway.confirmEmailAndLogin(widget.email, widget.token);
        }
        authenticated = true;
        password.clear();
        repeatPassword.clear();
      }
      if (!mounted) return;
      final role = SessionService.instance.role!;
      if (widget.onAuthenticated != null) {
        await widget.onAuthenticated!(role);
      } else {
        await enterAuthenticatedHome(context, role);
      }
    } catch (exception) {
      if (mounted) setState(() => error = authErrorMessage(exception));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthScaffold(
    title: widget.recoverPassword ? 'Definir nova senha' : 'Confirmar e-mail',
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          authenticated
              ? 'Conta confirmada. Continue para a Home.'
              : widget.recoverPassword
              ? 'Escolha sua nova senha. Após confirmar, você entrará na sua conta.'
              : 'Confirme seu e-mail para entrar na sua conta.',
          style: const TextStyle(color: AppColors.paper),
        ),
        if (widget.email.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              widget.email,
              style: const TextStyle(color: AppColors.paper),
            ),
          ),
        if (widget.recoverPassword && !authenticated) ...[
          AuthLabeledField(
            label: 'Nova senha',
            child: TextField(
              controller: password,
              enabled: !loading,
              obscureText: true,
              style: const TextStyle(color: AppColors.ink),
              autofillHints: const [AutofillHints.newPassword],
            ),
          ),
          const SizedBox(height: 12),
          AuthLabeledField(
            label: 'Confirmar nova senha',
            child: TextField(
              controller: repeatPassword,
              enabled: !loading,
              obscureText: true,
              style: const TextStyle(color: AppColors.ink),
            ),
          ),
        ],
        if (error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(error!, style: const TextStyle(color: AppColors.paper)),
          ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: loading ? null : _submit,
          child: Text(
            loading
                ? 'Aguarde...'
                : authenticated
                ? 'Continuar para a Home'
                : widget.recoverPassword
                ? 'Salvar senha e entrar'
                : 'Confirmar e entrar',
          ),
        ),
        TextButton(
          onPressed: loading
              ? null
              : () => Navigator.pushReplacementNamed(
                  context,
                  widget.recoverPassword
                      ? '/recuperar-senha'
                      : '/verificar-email',
                ),
          child: const Text('Solicitar novo link'),
        ),
        TextButton(
          onPressed: loading
              ? null
              : () => Navigator.pushReplacementNamed(context, '/login'),
          child: const Text('Ir para o login'),
        ),
      ],
    ),
  );
}
