import 'package:flutter/material.dart';

import '../utils/pallete.dart';

class MeusAgendamentosScreen extends StatelessWidget {
  const MeusAgendamentosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dados temporários para montar a interface.
    // Depois eles poderão vir do backend.
    final List<Map<String, String>> agendamentos = [
      {
        'trilha': 'Trilha da Cachoeira',
        'guia': 'Carlos Silva',
        'data': '25/08/2026',
        'horario': '08:00',
        'status': 'Confirmado',
      },
      {
        'trilha': 'Trilha do Mirante',
        'guia': 'Mariana Souza',
        'data': '02/09/2026',
        'horario': '09:30',
        'status': 'Confirmado',
      },
    ];

    return Scaffold(
      backgroundColor: Pallete.pearl,
      appBar: AppBar(
        backgroundColor: Pallete.herb,
        foregroundColor: Pallete.white,
        elevation: 0,
        title: const Text(
          'Meus Agendamentos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: agendamentos.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 70,
                    color: Pallete.herb,
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Você ainda não possui agendamentos.',
                    style: TextStyle(
                      color: Pallete.moss,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: agendamentos.length,
              itemBuilder: (context, index) {
                final agendamento = agendamentos[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Pallete.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Pallete.inputBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agendamento['trilha']!,
                        style: const TextStyle(
                          color: Pallete.moss,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 15),

                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            color: Pallete.herb,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Guia: ${agendamento['guia']}',
                            style: const TextStyle(
                              color: Pallete.moss,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            color: Pallete.herb,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            agendamento['data']!,
                            style: const TextStyle(
                              color: Pallete.moss,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Pallete.herb,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            agendamento['horario']!,
                            style: const TextStyle(
                              color: Pallete.moss,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Pallete.pearl,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          agendamento['status']!,
                          style: const TextStyle(
                            color: Pallete.herb,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}