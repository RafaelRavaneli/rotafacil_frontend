import 'package:flutter/material.dart';

import '../../models/user_role.dart';
import '../../theme/app_colors.dart';
import '../../widgets/role_card.dart';
import 'register_screen.dart';

class ProfileChoiceScreen extends StatelessWidget {
  const ProfileChoiceScreen({super.key});

  void _choose(BuildContext context, UserRole role) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RegisterScreen(role: role)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
          children: [
            const SizedBox(height: 18),
            const Text(
              'Qual é o seu\nperfil?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.green900,
                fontSize: 29,
                height: 1.05,
                fontWeight: FontWeight.w900,
                letterSpacing: -.8,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Escolha um perfil para criar sua conta.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 28),
            RoleCard(
              role: UserRole.tourist,
              onTap: () => _choose(context, UserRole.tourist),
            ),
            const SizedBox(height: 12),
            RoleCard(
              role: UserRole.guide,
              onTap: () => _choose(context, UserRole.guide),
            ),
            const SizedBox(height: 12),
            RoleCard(
              role: UserRole.agency,
              onTap: () => _choose(context, UserRole.agency),
            ),
            const SizedBox(height: 38),
            const Text(
              'Guia: CPF obrigatório. Agência: CNPJ obrigatório.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 11.5),
            ),
          ],
        ),
      ),
    );
  }
}
