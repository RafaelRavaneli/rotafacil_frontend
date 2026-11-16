import '../common/legal_document_screen.dart';
import '../../navigation/auth_page_route.dart';
import '../../navigation/app_routes.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/auth_scaffold.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'profile_choice_screen.dart';
import 'login_screen.dart';

/// Boas-vindas com o visual do Figma. Textos, ícones, botões e destinos são
/// os mesmos do original; só o layout e as cores mudaram.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const _ink = Color(0xFF2F4A1E);

  void _open(BuildContext context, WidgetBuilder builder) {
    if (!AppRoutes.canPush(context)) return;
    Navigator.push(context, AuthPageRoute(builder: builder));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/auth_background.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            excludeFromSemantics: true,
          ),
          // Escurece a parte de baixo para o texto claro ter contraste.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00243A18),
                  Color(0x00243A18),
                  Color(0xB3243A18),
                ],
                stops: [0, .42, 1],
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              // O ConstrainedBox(maxWidth) fica FORA do IntrinsicHeight para que
              // a altura seja medida na largura real (até 420). Antes ficava
              // dentro: em telas largas e baixas a altura era medida com a
              // largura da tela e o conteúdo estourava embaixo.
              builder: (context, constraints) => SingleChildScrollView(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                      maxWidth: 420,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(28, 16, 28, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // O PNG da marca tem margem interna; o corte de
                            // altura aproxima a logo do texto, como no Figma.
                            const Align(
                              heightFactor: .74,
                              child: AppLogo(large: true),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Roteiros e aventuras\npara todos os caminhos.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _ink,
                                fontSize: 18,
                                height: 1.4,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            const SizedBox(height: 24),
                            const _Benefit(
                              icon: Icons.hiking_rounded,
                              text: 'Explore roteiros incríveis',
                            ),
                            const SizedBox(height: 18),
                            const _Benefit(
                              icon: Icons.group_outlined,
                              text:
                                  'Encontre atividades com guias responsáveis',
                            ),
                            const SizedBox(height: 18),
                            const _Benefit(
                              icon: Icons.favorite_border_rounded,
                              text: 'Viva experiências memoráveis',
                            ),
                            const SizedBox(height: 28),
                            FilledButton(
                              onPressed: () => _open(
                                context,
                                (_) => const ProfileChoiceScreen(),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: AuthScaffold.olive,
                                foregroundColor: AppColors.paper,
                                minimumSize: const Size.fromHeight(52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              child: const Text('Criar conta'),
                            ),
                            const SizedBox(height: 8),
                            // Botão de verdade (antes era só um link sublinhado):
                            // quem já tem conta é a maioria dos acessos.
                            OutlinedButton(
                              onPressed: () =>
                                  _open(context, (_) => const LoginScreen()),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.paper,
                                // O tema dá fundo claro aos botões com borda; aqui o
                                // texto é claro, então o fundo é escuro e translúcido.
                                backgroundColor: Colors.black.withValues(
                                  alpha: .28,
                                ),
                                minimumSize: const Size.fromHeight(52),
                                side: const BorderSide(
                                  color: AppColors.paper,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              child: const Text('Fazer login'),
                            ),
                            const LegalLinks(light: true, stacked: true),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
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
              shadows: [Shadow(color: Color(0x66000000), blurRadius: 4)],
            ),
          ),
        ),
      ],
    );
  }
}
