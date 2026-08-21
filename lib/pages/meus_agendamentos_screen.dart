import 'package:flutter/material.dart';

import '../services/agendamento_service.dart';
import '../utils/pallete.dart';

class MeusAgendamentosScreen extends StatefulWidget {
  const MeusAgendamentosScreen({super.key});

  @override
  State<MeusAgendamentosScreen> createState() => _MeusAgendamentosScreenState();
}

class _MeusAgendamentosScreenState extends State<MeusAgendamentosScreen> {
  List<Map<String, String>> agendamentos = [];

  bool carregando = true;

  @override
  void initState() {
    super.initState();

    carregarAgendamentos();
  }

  Future<void> carregarAgendamentos() async {
    final lista = await AgendamentoService.listarAgendamentos();

    if (!mounted) return;

    setState(() {
      agendamentos = lista;
      carregando = false;
    });
  }

  Future<void> removerAgendamento(Map<String, String> agendamento) async {
    await AgendamentoService.removerAgendamento(
      trilha: agendamento['trilha']!,
      data: agendamento['data']!,
    );

    await carregarAgendamentos();

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Agendamento removido.')));
  }

  void confirmarRemocao(Map<String, String> agendamento) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancelar agendamento'),
          content: Text(
            'Deseja cancelar o agendamento da trilha "${agendamento['trilha']}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Não'),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                removerAgendamento(agendamento);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Pallete.herb,
                foregroundColor: Pallete.white,
              ),
              child: const Text('Sim, cancelar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallete.pearl,
      appBar: AppBar(
        backgroundColor: Pallete.herb,
        foregroundColor: Pallete.white,
        elevation: 0,
        title: const Text(
          'Meus Agendamentos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator(color: Pallete.herb))
          : agendamentos.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(25),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      size: 75,
                      color: Pallete.herb,
                    ),

                    SizedBox(height: 20),

                    Text(
                      'Nenhuma trilha agendada',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Pallete.moss,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 8),

                    Text(
                      'Quando você agendar uma trilha, ela aparecerá aqui.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Pallete.moss, fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: carregarAgendamentos,
              child: ListView.builder(
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
                      border: Border.all(color: Pallete.inputBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          agendamento['trilha'] ?? 'Trilha',
                          style: const TextStyle(
                            color: Pallete.moss,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 15),

                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: Pallete.herb,
                            ),

                            const SizedBox(width: 8),

                            Expanded(
                              child: Text(
                                '${agendamento['cidade']} - ${agendamento['estado']}',
                                style: const TextStyle(color: Pallete.moss),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_outlined,
                              color: Pallete.herb,
                            ),

                            const SizedBox(width: 8),

                            Text(
                              agendamento['data'] ?? '',
                              style: const TextStyle(color: Pallete.moss),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            const Icon(Icons.hiking, color: Pallete.herb),

                            const SizedBox(width: 8),

                            Text(
                              agendamento['dificuldade'] ?? '',
                              style: const TextStyle(color: Pallete.moss),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.place_outlined,
                              color: Pallete.herb,
                            ),

                            const SizedBox(width: 8),

                            Expanded(
                              child: Text(
                                agendamento['pontoEncontro'] ?? '',
                                style: const TextStyle(color: Pallete.moss),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        Row(
                          children: [
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
                                agendamento['status'] ?? 'Confirmado',
                                style: const TextStyle(
                                  color: Pallete.herb,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            const Spacer(),

                            TextButton.icon(
                              onPressed: () {
                                confirmarRemocao(agendamento);
                              },
                              icon: const Icon(Icons.cancel_outlined),
                              label: const Text('Cancelar'),
                              style: TextButton.styleFrom(
                                foregroundColor: Pallete.moss,
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
    );
  }
}
