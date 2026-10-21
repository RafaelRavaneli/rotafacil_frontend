import 'package:flutter/material.dart';
import '../../state/app_store.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/reviews_panel.dart';

class ProfessionalProfileScreen extends StatefulWidget {
  const ProfessionalProfileScreen({super.key, required this.id});
  final String id;
  @override
  State<ProfessionalProfileScreen> createState() =>
      _ProfessionalProfileScreenState();
}

class _ProfessionalProfileScreenState extends State<ProfessionalProfileScreen> {
  late Future<Map<String, dynamic>> future;
  @override
  void initState() {
    super.initState();
    future = AppStore.instance.professionalProfile(widget.id);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const AppBackButton(),
      title: const Text('Perfil do organizador'),
      actions: [
        IconButton(
          tooltip: 'Atualizar perfil',
          icon: const Icon(Icons.refresh),
          onPressed: () {
            setState(() {
              future = AppStore.instance.professionalProfile(widget.id);
            });
          },
        ),
      ],
    ),
    body: FutureBuilder<Map<String, dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: () {
                setState(() {
                  future = AppStore.instance.professionalProfile(widget.id);
                });
              },
              child: const Text('Falha ao carregar perfil. Tentar novamente'),
            ),
          );
        }
        final profile = snapshot.data!;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  '${profile['nome'] ?? 'Organizador'}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(profile['tipo'] == 'agencia' ? 'Agência' : 'Guia'),
                Text('${profile['cidade'] ?? ''} - ${profile['estado'] ?? ''}'),
                if (profile['verificado'] == true)
                  const Text('Perfil verificado'),
                Text(
                  (profile['total_avaliacoes'] ?? 0) == 0
                      ? 'Ainda sem avaliações'
                      : '${profile['nota_media']}/5 · ${profile['total_avaliacoes']} avaliações',
                ),
                Text('${profile['descricao_profissional'] ?? ''}'),
                const SizedBox(height: 20),
                ReviewsPanel(
                  id: widget.id,
                  professional: true,
                  role: profile['tipo']?.toString() ?? '',
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
