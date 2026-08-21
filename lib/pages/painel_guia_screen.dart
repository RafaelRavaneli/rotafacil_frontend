import 'package:flutter/material.dart';

import '../utils/pallete.dart';
import 'formulario_trilha_screen.dart';

class PainelGuiaScreen extends StatelessWidget {
  const PainelGuiaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> trilhas = [
      {
        'nome': 'Trilha da Cachoeira',
        'cidade': 'Maringá - PR',
        'data': '25/08/2026',
        'dificuldade': 'Moderada',
      },
      {
        'nome': 'Trilha do Mirante',
        'cidade': 'Londrina - PR',
        'data': '02/09/2026',
        'dificuldade': 'Fácil',
      },
    ];

    return Scaffold(
      backgroundColor: Pallete.pearl,
      appBar: AppBar(
        backgroundColor: Pallete.herb,
        foregroundColor: Pallete.white,
        elevation: 0,
        title: const Text(
          'Painel do Guia',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Minhas trilhas',
                style: TextStyle(
                  color: Pallete.moss,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Gerencie as trilhas criadas por você.',
                style: TextStyle(color: Pallete.moss, fontSize: 16),
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FormularioTrilhaScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'Criar nova trilha',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Pallete.herb,
                    foregroundColor: Pallete.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              Expanded(
                child: trilhas.isEmpty
                    ? const Center(
                        child: Text(
                          'Você ainda não criou nenhuma trilha.',
                          style: TextStyle(color: Pallete.moss, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: trilhas.length,
                        itemBuilder: (context, index) {
                          final trilha = trilhas[index];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Pallete.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Pallete.inputBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  trilha['nome']!,
                                  style: const TextStyle(
                                    color: Pallete.moss,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 12),

                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      color: Pallete.herb,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      trilha['cidade']!,
                                      style: const TextStyle(
                                        color: Pallete.moss,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_month_outlined,
                                      color: Pallete.herb,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      trilha['data']!,
                                      style: const TextStyle(
                                        color: Pallete.moss,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                Row(
                                  children: [
                                    const Icon(
                                      Icons.hiking,
                                      color: Pallete.herb,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      trilha['dificuldade']!,
                                      style: const TextStyle(
                                        color: Pallete.moss,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 18),

                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const FormularioTrilhaScreen(),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.edit_outlined),
                                        label: const Text('Editar'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Pallete.herb,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 10),

                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: const Text(
                                                  'Excluir trilha',
                                                ),
                                                content: Text(
                                                  'Deseja excluir "${trilha['nome']}"?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                    },
                                                    child: const Text(
                                                      'Cancelar',
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);

                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'Trilha excluída!',
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    child: const Text(
                                                      'Excluir',
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                        icon: const Icon(Icons.delete_outline),
                                        label: const Text('Excluir'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Pallete.moss,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
