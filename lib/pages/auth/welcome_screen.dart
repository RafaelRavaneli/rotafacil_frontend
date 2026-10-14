import '../../widgets/auth_scaffold.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';
import 'profile_choice_screen.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      welcome: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 34, 24, 22),
                  child: Column(
                    children: [
                      const AppLogo(large: true),
                      const SizedBox(height: 4),
                      const Text(
                        'Trilhas e aventuras\npara todos os caminhos.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.green900,
                          fontSize: 15,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      const _Benefit(
                        icon: Icons.hiking_rounded,
                        text: 'Explore trilhas incríveis',
                      ),
                      const SizedBox(height: 12),
                      const _Benefit(
                        icon: Icons.group_outlined,
                        text: 'Encontre atividades com guias responsáveis',
                      ),
                      const SizedBox(height: 12),
                      const _Benefit(
                        icon: Icons.favorite_border_rounded,
                        text: 'Viva experiências memoráveis',
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProfileChoiceScreen(),
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.white.withValues(
                              alpha: .14,
                            ),
                            foregroundColor: AppColors.white,
                            side: BorderSide(
                              color: AppColors.white.withValues(alpha: .42),
                            ),
                          ),
                          child: const Text('Criar conta'),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Fazer login',
                          style: TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
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
