import 'package:flutter/material.dart';
import '../../services/community_api.dart';
import '../../services/session_service.dart';
import '../../state/app_store.dart';
import '../../utils/auth_error_message.dart';

class RemoteGuidesScreen extends StatefulWidget {
  const RemoteGuidesScreen({super.key, this.api});
  final CommunityApi? api;
  @override
  State<RemoteGuidesScreen> createState() => _RemoteGuidesState();
}

class _RemoteGuidesState extends State<RemoteGuidesScreen> {
  late final api = widget.api ?? CommunityApi();
  late Future<List<List<Map<String, dynamic>>>> data;
  bool busy = false;
  bool get agency => SessionService.instance.role == 'agencia';
  @override
  void initState() {
    super.initState();
    data = load();
  }

  Future<List<List<Map<String, dynamic>>>> load() async {
    final owner = SessionService.instance.userId;
    final result = await Future.wait([
      api.list('/api/convites-guias'),
      if (agency) api.list('/api/guias'),
    ]);
    if (mounted && agency && owner == SessionService.instance.userId) {
      AppStore.instance.syncAgencyGuides(result.first);
    }
    return result;
  }

  void reload() {
    setState(() {
      data = load();
    });
  }

  Future<void> action(Future<void> Function() perform) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await perform();
      if (!mounted) return;
      reload();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Atualizado com sucesso.')));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(agency ? 'Guias e convites' : 'Convites de agências'),
      actions: [
        IconButton(
          onPressed: reload,
          tooltip: 'Atualizar',
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<List<List<Map<String, dynamic>>>>(
      future: data,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(authErrorMessage(snapshot.error!)),
                TextButton(
                  onPressed: reload,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          );
        }
        final invites = snapshot.data!.first;
        final guides = agency ? snapshot.data![1] : <Map<String, dynamic>>[];
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Convites',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (invites.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Nenhum convite.'),
              ),
            for (final invite in invites)
              Card(
                child: ListTile(
                  title: Text(
                    (agency ? invite['nome_guia'] : invite['nome_agencia'])
                        .toString(),
                  ),
                  subtitle: Text(invite['status'].toString()),
                  trailing: !agency && invite['status'] == 'pendente'
                      ? Wrap(
                          children: [
                            IconButton(
                              tooltip: 'Aceitar',
                              onPressed: busy
                                  ? null
                                  : () => action(
                                      () => api.answer(
                                        invite['id'].toString(),
                                        'aceito',
                                      ),
                                    ),
                              icon: const Icon(Icons.check),
                            ),
                            IconButton(
                              tooltip: 'Recusar',
                              onPressed: busy
                                  ? null
                                  : () => action(
                                      () => api.answer(
                                        invite['id'].toString(),
                                        'recusado',
                                      ),
                                    ),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
            if (agency) ...[
              const SizedBox(height: 20),
              const Text(
                'Guias disponíveis',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              if (guides.isEmpty) const Text('Nenhum guia cadastrado.'),
              for (final guide in guides)
                ListTile(
                  title: Text(guide['nome']?.toString() ?? 'Guia'),
                  subtitle: Text(
                    '${guide['cidade'] ?? ''} ${guide['estado'] ?? ''}',
                  ),
                  trailing: TextButton(
                    onPressed:
                        busy || invites.any((i) => i['id_guia'] == guide['id'])
                        ? null
                        : () => action(() async {
                            await api.create('/api/convites-guias', {
                              'id_guia': guide['id'],
                            });
                          }),
                    child: const Text('Convidar'),
                  ),
                ),
            ],
          ],
        );
      },
    ),
  );
}
