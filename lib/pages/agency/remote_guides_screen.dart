import 'package:flutter/material.dart';
import '../../services/community_api.dart';
import '../../services/session_service.dart';
import '../../state/app_store.dart';
import '../../theme/app_colors.dart';
import '../../utils/auth_error_message.dart';
import '../../widgets/guide_catalog_card.dart';

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
  String? activeId;
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
    final next = load();
    setState(() {
      data = next;
    });
  }

  Future<void> _confirm({
    required String id,
    required String name,
    required String title,
    required String description,
    required String confirmLabel,
    required String success,
    required Future<void> Function() perform,
  }) async {
    if (busy) return;
    setState(() {
      busy = true;
      activeId = id;
    });
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text('$name\n\n$description'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Voltar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(confirmLabel),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      await perform();
      if (!mounted) return;
      reload();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(success)));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
      }
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
          activeId = null;
        });
      }
    }
  }

  Widget _invitation(Map<String, dynamic> invite) {
    final id = invite['id']?.toString() ?? '';
    final name =
        (agency ? invite['nome_guia'] : invite['nome_agencia'])?.toString() ??
        (agency ? 'Guia' : 'Agência');
    final status = invite['status']?.toString() ?? 'Situação não informada';
    return GuideCatalogCard(
      name: name,
      status: status,
      subtitle: agency
          ? 'Convite enviado pela sua agência'
          : 'Convite recebido de uma agência',
      actions: [
        if (!agency && status == 'pendente') ...[
          FilledButton.icon(
            onPressed: busy || id.isEmpty
                ? null
                : () => _confirm(
                    id: id,
                    name: name,
                    title: 'Aceitar convite?',
                    description: 'Confirme o vínculo com esta agência.',
                    confirmLabel: 'Confirmar aceite',
                    success: 'Convite aceito.',
                    perform: () => api.answer(id, 'aceito'),
                  ),
            icon: const Icon(Icons.check),
            label: Text(busy && activeId == id ? 'Aguarde...' : 'Aceitar'),
          ),
          OutlinedButton.icon(
            onPressed: busy || id.isEmpty
                ? null
                : () => _confirm(
                    id: id,
                    name: name,
                    title: 'Recusar convite?',
                    description: 'O convite ficará registrado como recusado.',
                    confirmLabel: 'Confirmar recusa',
                    success: 'Convite recusado.',
                    perform: () => api.answer(id, 'recusado'),
                  ),
            icon: const Icon(Icons.close),
            label: const Text('Recusar'),
          ),
        ],
      ],
    );
  }

  Widget _guide(
    Map<String, dynamic> guide,
    List<Map<String, dynamic>> invites,
  ) {
    final id = guide['id']?.toString() ?? '';
    final name = guide['nome']?.toString() ?? 'Guia';
    final existing = invites
        .where((i) => i['id_guia']?.toString() == id)
        .firstOrNull;
    final location = [
      guide['cidade'],
      guide['estado'],
    ].where((v) => v != null && v.toString().trim().isNotEmpty).join(' · ');
    return GuideCatalogCard(
      name: name,
      subtitle: location,
      photoUrl: guide['foto_url']?.toString(),
      verified: guide['verificado'] == true,
      status: existing?['status']?.toString(),
      actions: [
        if (existing == null)
          OutlinedButton.icon(
            onPressed: busy || id.isEmpty
                ? null
                : () => _confirm(
                    id: id,
                    name: name,
                    title: 'Convidar guia?',
                    description: 'O guia poderá aceitar ou recusar o convite.',
                    confirmLabel: 'Enviar convite',
                    success: 'Convite enviado.',
                    perform: () async {
                      await api.create('/api/convites-guias', {'id_guia': id});
                    },
                  ),
            icon: const Icon(Icons.person_add_outlined),
            label: Text(busy && activeId == id ? 'Enviando...' : 'Convidar'),
          ),
        if (existing?['status'] == 'recusado')
          const Text(
            'Reenvio de convite ainda não está disponível.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(agency ? 'Guias e convites' : 'Convites de agências'),
      actions: [
        IconButton(
          onPressed: busy ? null : reload,
          tooltip: 'Atualizar',
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<List<List<Map<String, dynamic>>>>(
      future: data,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Carregando guias e convites...'),
              ],
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: GuideCollectionNotice(
                  title: 'Não foi possível carregar',
                  message: authErrorMessage(snapshot.error!),
                  action: OutlinedButton.icon(
                    onPressed: reload,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar novamente'),
                  ),
                ),
              ),
            ),
          );
        }
        final invites = snapshot.data!.first;
        final guides = agency ? snapshot.data![1] : <Map<String, dynamic>>[];
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  agency
                      ? 'Encontre guias para suas trilhas'
                      : 'Parcerias para suas trilhas',
                  style: const TextStyle(
                    color: AppColors.forest,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  agency
                      ? 'Consulte o catálogo e acompanhe a resposta dos guias.'
                      : 'Confira as agências que convidaram você e escolha como responder.',
                  style: const TextStyle(color: AppColors.muted, height: 1.5),
                ),
                const SizedBox(height: 24),
                _Section(
                  title: agency ? 'Convites enviados' : 'Convites recebidos',
                  count: invites.length,
                ),
                const SizedBox(height: 12),
                if (invites.isEmpty)
                  GuideCollectionNotice(
                    title: 'Nenhum convite.',
                    message: agency
                        ? 'Escolha um guia no catálogo abaixo para enviar o primeiro convite.'
                        : 'Quando uma agência enviar um convite, ele aparecerá aqui.',
                  ),
                ...invites.map(
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _invitation(i),
                  ),
                ),
                if (agency) ...[
                  const SizedBox(height: 24),
                  _Section(title: 'Catálogo de guias', count: guides.length),
                  const SizedBox(height: 6),
                  const Text(
                    'Os guias do catálogo não são necessariamente vinculados à sua agência.',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (guides.isEmpty)
                    const GuideCollectionNotice(
                      title: 'Nenhum guia cadastrado.',
                      message:
                          'Atualize esta tela para consultar novos cadastros.',
                    ),
                  ...guides.map(
                    (g) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _guide(g, invites),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.count});
  final String title;
  final int count;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.forest,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Text(
        '$count',
        style: const TextStyle(
          color: AppColors.muted,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}
