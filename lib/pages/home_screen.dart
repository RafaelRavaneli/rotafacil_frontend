import 'package:flutter/material.dart';

import '../utils/pallete.dart';

import 'busca_filtros_screen.dart';
import 'detalhes_trilha_screen.dart';
import 'meus_agendamentos_screen.dart';
import 'perfil_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallete.pearl,
      appBar: AppBar(
        backgroundColor: Pallete.herb,
        elevation: 0,
        title: const Text(
          'RotaFácil',
          style: TextStyle(color: Pallete.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bom dia!',
              style: TextStyle(
                color: Pallete.moss,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'O que vamos explorar hoje?',
              style: TextStyle(color: Pallete.moss, fontSize: 17),
            ),

            const SizedBox(height: 25),

            // Barra de pesquisa
            TextField(
              readOnly: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BuscaFiltrosScreen(),
                  ),
                );
              },
              decoration: InputDecoration(
                hintText: 'Buscar trilhas...',
                prefixIcon: const Icon(Icons.search, color: Pallete.herb),
                suffixIcon: const Icon(Icons.tune, color: Pallete.herb),
                filled: true,
                fillColor: Pallete.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'Trilhas em destaque',
              style: TextStyle(
                color: Pallete.moss,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            // Destaque principal
            InkWell(
              onTap: () {
                _abrirDetalhes(
                  context,
                  nome: 'Trilha da Cachoeira',
                  descricao:
                      'Passeio por uma trilha cercada por natureza, com percurso agradável e visita a uma cachoeira.',
                  cidade: 'Maringá',
                  estado: 'PR',
                  dificuldade: 'Moderada',
                  pontoEncontro: 'Parque Municipal',
                  data: '25/08/2026',
                );
              },
              borderRadius: BorderRadius.circular(25),
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: Pallete.herb,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Trilha da Cachoeira 🌿',
                        style: TextStyle(
                          color: Pallete.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Maringá - PR • Moderada',
                        style: TextStyle(color: Pallete.pearl, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Mais trilhas
            _trilhaCard(
              context,
              nome: 'Trilha do Mirante',
              cidade: 'Londrina',
              estado: 'PR',
              dificuldade: 'Fácil',
              data: '02/09/2026',
              descricao:
                  'Trilha leve com vista panorâmica, ideal para quem busca um passeio tranquilo.',
              pontoEncontro: 'Entrada do Parque',
            ),

            const SizedBox(height: 15),

            _trilhaCard(
              context,
              nome: 'Trilha da Serra',
              cidade: 'Apucarana',
              estado: 'PR',
              dificuldade: 'Difícil',
              data: '10/09/2026',
              descricao:
                  'Percurso com subidas e trechos mais intensos, indicado para pessoas com experiência.',
              pontoEncontro: 'Centro de Visitantes',
            ),

            const SizedBox(height: 30),

            const Text(
              'Guias disponíveis',
              style: TextStyle(
                color: Pallete.moss,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Pallete.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Pallete.inputBorder),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Pallete.inputBorder,
                    child: Icon(Icons.person, color: Pallete.herb),
                  ),

                  SizedBox(width: 15),

                  Expanded(
                    child: Text(
                      'Guias disponíveis hoje',
                      style: TextStyle(
                        color: Pallete.moss,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  Icon(Icons.chevron_right, color: Pallete.herb),
                ],
              ),
            ),

            const SizedBox(height: 25),
          ],
        ),
      ),

      // Navegação inferior
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Pallete.herb,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BuscaFiltrosScreen(),
              ),
            );
          }

          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MeusAgendamentosScreen(),
              ),
            );
          }

          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PerfilScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: 'Trilhas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            label: 'Agenda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  void _abrirDetalhes(
    BuildContext context, {
    required String nome,
    required String descricao,
    required String cidade,
    required String estado,
    required String dificuldade,
    required String pontoEncontro,
    required String data,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetalhesTrilhaScreen(
          nome: nome,
          descricao: descricao,
          cidade: cidade,
          estado: estado,
          dificuldade: dificuldade,
          pontoEncontro: pontoEncontro,
          data: data,
        ),
      ),
    );
  }

  Widget _trilhaCard(
    BuildContext context, {
    required String nome,
    required String cidade,
    required String estado,
    required String dificuldade,
    required String data,
    required String descricao,
    required String pontoEncontro,
  }) {
    return InkWell(
      onTap: () {
        _abrirDetalhes(
          context,
          nome: nome,
          descricao: descricao,
          cidade: cidade,
          estado: estado,
          dificuldade: dificuldade,
          pontoEncontro: pontoEncontro,
          data: data,
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Pallete.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Pallete.inputBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration(
                color: Pallete.inputBorder,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.landscape_outlined,
                color: Pallete.herb,
                size: 38,
              ),
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nome,
                    style: const TextStyle(
                      color: Pallete.moss,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    '$cidade - $estado',
                    style: const TextStyle(color: Pallete.moss),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    '$dificuldade • $data',
                    style: const TextStyle(
                      color: Pallete.herb,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right, color: Pallete.herb),
          ],
        ),
      ),
    );
  }
}
