import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';
import 'profile_choice_screen.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const _hero =
      'https://images.unsplash.com/photo-1464278533981-50106e6176b1?auto=format&fit=crop&w=1200&q=88';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            _hero,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Container(color: AppColors.green800),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66FFFFFF),
                  Color(0x22000000),
                  Color(0xD91A3E2A),
                ],
                stops: [0, .5, 1],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 34, 24, 22),
              child: Column(
                children: [
                  const AppLogo(large: true, showName: false),
                  const SizedBox(height: 12),
                  const Text(
                    'RotaFácil',
                    style: TextStyle(
                      color: AppColors.green900,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
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
                    text: 'Conecte-se com guias e outros aventureiros',
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
                        backgroundColor: AppColors.white.withValues(alpha: .14),
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
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
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
