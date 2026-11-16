import '../../navigation/auth_page_route.dart';
import '../../navigation/app_routes.dart';
import '../../widgets/auth_scaffold.dart';
import 'package:flutter/material.dart';

import '../../models/user_role.dart';
import '../../theme/app_colors.dart';
import '../../widgets/role_card.dart';
import 'register_screen.dart';

class ProfileChoiceScreen extends StatefulWidget {
  const ProfileChoiceScreen({super.key});

  @override
  State<ProfileChoiceScreen> createState() => _ProfileChoiceScreenState();
}

class _ProfileChoiceScreenState extends State<ProfileChoiceScreen> {
  UserRole? _selected;

  Future<void> _choose(UserRole role) async {
    if (!AppRoutes.canPush(context)) return;
    // Marca o perfil escolhido (estado do Figma) e abre o cadastro direto.
    setState(() => _selected = role);
    await Navigator.push(
      context,
      AuthPageRoute(builder: (_) => RegisterScreen(role: role)),
    );
    // Ao voltar, a escolha começa limpa de novo.
    if (mounted) setState(() => _selected = null);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Criar conta',
      largeLogo: true,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Escolha um perfil para criar sua conta.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.paper, fontSize: 13),
          ),
          const SizedBox(height: 18),
          for (final role in UserRole.values) ...[
            RoleCard(
              role: role,
              selected: _selected == role,
              dimmed: _selected != null && _selected != role,
              onTap: () => _choose(role),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 4),
          const Text(
            'Guia: CPF obrigatório. Agência: CNPJ obrigatório.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.paper, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}
