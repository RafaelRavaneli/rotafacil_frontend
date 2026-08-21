import 'package:flutter/material.dart';

import '../services/agendamento_service.dart';
import '../utils/pallete.dart';

class DetalhesTrilhaScreen extends StatelessWidget {
  const DetalhesTrilhaScreen({
    super.key,
    required this.nome,
    required this.descricao,
    required this.cidade,
    required this.estado,
    required this.dificuldade,
    required this.pontoEncontro,
    required this.data,
  });

  final String nome;
  final String descricao;
  final String cidade;
  final String estado;
  final String dificuldade;
  final String pontoEncontro;
  final String data;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallete.pearl,
      appBar: AppBar(
        backgroundColor: Pallete.herb,
        foregroundColor: Pallete.white,
        elevation: 0,
        title: const Text(
          'Detalhes da Trilha',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 220,
              color: Pallete.inputBorder,
              child: const Icon(
                Icons.landscape_outlined,
                size: 90,
                color: Pallete.herb,
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nome,
                    style: const TextStyle(
                      color: Pallete.moss,
                      fontSize: 28,
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
                        '$cidade - $estado',
                        style: const TextStyle(
                          color: Pallete.moss,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: _infoCard(
                          icon: Icons.hiking,
                          titulo: 'Dificuldade',
                          valor: dificuldade,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _infoCard(
                          icon: Icons.calendar_month_outlined,
                          titulo: 'Data',
                          valor: data,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    'Sobre a trilha',
                    style: TextStyle(
                      color: Pallete.moss,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    descricao,
                    style: const TextStyle(
                      color: Pallete.moss,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    'Ponto de encontro',
                    style: TextStyle(
                      color: Pallete.moss,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Pallete.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Pallete.inputBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          color: Pallete.herb,
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: Text(
                            pontoEncontro,
                            style: const TextStyle(
                              color: Pallete.moss,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 35),

                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (dialogContext) {
                            return AlertDialog(
                              title: const Text(
                                'Confirmar agendamento',
                              ),
                              content: Text(
                                'Deseja participar da trilha "$nome"?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(dialogContext);
                                  },
                                  child: const Text('Cancelar'),
                                ),

                                ElevatedButton(
                                  onPressed: () async {
                                    final adicionado =
                                        await AgendamentoService
                                            .adicionarAgendamento(
                                      trilha: nome,
                                      cidade: cidade,
                                      estado: estado,
                                      data: data,
                                      dificuldade: dificuldade,
                                      pontoEncontro: pontoEncontro,
                                    );

                                    if (!context.mounted) return;

                                    Navigator.pop(dialogContext);

                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          adicionado
                                              ? 'Trilha agendada com sucesso!'
                                              : 'Essa trilha já está nos seus agendamentos.',
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Pallete.herb,
                                    foregroundColor: Pallete.white,
                                  ),
                                  child: const Text('Confirmar'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Pallete.herb,
                        foregroundColor: Pallete.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Agendar trilha',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String titulo,
    required String valor,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Pallete.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Pallete.inputBorder,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Pallete.herb,
          ),

          const SizedBox(height: 8),

          Text(
            titulo,
            style: const TextStyle(
              color: Pallete.moss,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            valor,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Pallete.moss,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}