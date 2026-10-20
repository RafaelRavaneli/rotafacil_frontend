import '../../navigation/auth_page_route.dart';
import '../../widgets/auth_scaffold.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'profile_choice_screen.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'RotaFácil',
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Roteiros e aventuras\npara todos os caminhos.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.paper,
              fontSize: 18,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 32),
          const _Benefit(
            icon: Icons.hiking_rounded,
            text: 'Explore roteiros incríveis',
          ),
          const SizedBox(height: 18),
          const _Benefit(
            icon: Icons.group_outlined,
            text: 'Encontre atividades com guias responsáveis',
          ),
          const SizedBox(height: 18),
          const _Benefit(
            icon: Icons.favorite_border_rounded,
            text: 'Viva experiências memoráveis',
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () => Navigator.push(
              context,
              AuthPageRoute(builder: (_) => const ProfileChoiceScreen()),
            ),
            child: const Text('Criar conta'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              AuthPageRoute(builder: (_) => const LoginScreen()),
            ),
            child: const Text(
              'Fazer login',
              style: TextStyle(color: AppColors.paper),
            ),
          ),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.white, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
