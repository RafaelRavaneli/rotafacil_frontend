import 'package:flutter/material.dart';
import '../utils/pallete.dart';
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
              decoration: InputDecoration(
                hintText: 'Buscar trilhas, guias...',
                prefixIcon: const Icon(Icons.search, color: Pallete.herb),
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

            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: Pallete.herb,
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    'Descubra novos lugares 🌿',
                    style: TextStyle(
                      color: Pallete.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
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
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Pallete.inputBorder,
                    child: Icon(Icons.person, color: Pallete.herb),
                  ),
                  SizedBox(width: 15),
                  Text(
                    'Guias disponíveis hoje',
                    style: TextStyle(
                      color: Pallete.moss,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
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
}
