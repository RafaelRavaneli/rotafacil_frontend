import 'package:flutter/material.dart';

import '../utils/pallete.dart';
import 'create_account_screen.dart';

class EscolhaPerfilScreen extends StatelessWidget {
  const EscolhaPerfilScreen({super.key});

  void _abrirCadastro(
    BuildContext context,
    String tipoPerfil,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateAccountScreen(
          tipoPerfilInicial: tipoPerfil,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallete.pearl,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              left: -80,
              right: -80,
              bottom: -160,
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Pallete.inputBorder,
                  borderRadius: BorderRadius.circular(200),
                ),
              ),
            ),

            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                24,
                35,
                24,
                35,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 15),

                  Container(
                    width: 105,
                    height: 105,
                    decoration: BoxDecoration(
                      color: Pallete.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Pallete.herb,
                        width: 4,
                      ),
                    ),
                    child: const Icon(
                      Icons.explore,
                      size: 58,
                      color: Pallete.herb,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'RotaFácil',
                    style: TextStyle(
                      color: Pallete.moss,
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Conectando pessoas a novos caminhos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Pallete.moss,
                      fontSize: 17,
                    ),
                  ),

                  const SizedBox(height: 40),

                  const Text(
                    'Como você deseja continuar?',
                    style: TextStyle(
                      color: Pallete.moss,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 22),

                  _cardPerfil(
                    context,
                    titulo: 'Sou Turista',
                    descricao:
                        'Quero explorar trilhas, encontrar guias e viver novas experiências.',
                    icon: Icons.hiking,
                    tipoPerfil: 'turista',
                  ),

                  const SizedBox(height: 16),

                  _cardPerfil(
                    context,
                    titulo: 'Sou Guia',
                    descricao:
                        'Quero criar trilhas, compartilhar experiências e gerenciar passeios.',
                    icon: Icons.flag_outlined,
                    tipoPerfil: 'guia',
                  ),

                  const SizedBox(height: 16),

                  _cardPerfil(
                    context,
                    titulo: 'Sou Agência',
                    descricao:
                        'Quero gerenciar trilhas, guias e agendamentos da minha agência.',
                    icon: Icons.business_outlined,
                    tipoPerfil: 'agencia',
                  ),

                  const SizedBox(height: 35),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardPerfil(
    BuildContext context, {
    required String titulo,
    required String descricao,
    required IconData icon,
    required String tipoPerfil,
  }) {
    return InkWell(
      onTap: () {
        _abrirCadastro(
          context,
          tipoPerfil,
        );
      },
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Pallete.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Pallete.inputBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.05,
              ),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: Pallete.pearl,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                icon,
                size: 38,
                color: Pallete.herb,
              ),
            ),

            const SizedBox(width: 18),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      color: Pallete.moss,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    descricao,
                    style: const TextStyle(
                      color: Pallete.moss,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            const Icon(
              Icons.chevron_right,
              color: Pallete.herb,
              size: 30,
            ),
          ],
        ),
      ),
    );
  }
}