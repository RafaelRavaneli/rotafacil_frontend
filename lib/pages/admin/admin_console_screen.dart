import 'package:flutter/material.dart';
import '../../navigation/app_routes.dart';
import '../../services/session_service.dart';
import '../../services/notification_service.dart';
import '../../state/app_store.dart';
import '../../utils/controller_dialog.dart';
import '../../utils/date_time_format.dart';
import '../../utils/run_action.dart';
import '../auth/welcome_screen.dart';
import 'admin_verification_screen.dart';
import 'review_moderation_screen.dart';

class AdminConsoleScreen extends StatefulWidget {
  const AdminConsoleScreen({
    super.key,
    this.initialSection = 'contas',
    this.load,
    this.apply,
  });
  final String initialSection;
  final Future<List<Map<String, dynamic>>> Function(
    String,
    Map<String, String>,
  )?
  load;
  final Future<void> Function(String, String, String, String)? apply;
  @override
  State<AdminConsoleScreen> createState() => _AdminConsoleScreenState();
}

class _AdminConsoleScreenState extends State<AdminConsoleScreen>
    with WidgetsBindingObserver {
  static const sections = ['contas', 'roteiros', 'historico'];
  late String section;
  String state = 'todos';
  String type = 'todos';
  bool busy = false;
  final search = TextEditingController();
  late Future<List<Map<String, dynamic>>> future;
  bool get authorized => SessionService.instance.role?.toLowerCase() == 'admin';
  @override
  void initState() {
    super.initState();
    section = sections.contains(widget.initialSection)
        ? widget.initialSection
        : 'contas';
    WidgetsBinding.instance.addObserver(this);
    future = fetch();
  }

  Future<List<Map<String, dynamic>>> fetch() {
    if (!authorized) return Future.value([]);
    final filters = <String, String>{
      if (section != 'historico') 'estado': state,
      if (section != 'roteiros') 'tipo': type,
      if (search.text.trim().isNotEmpty)
        (section == 'historico' ? 'id_alvo' : 'q'): search.text.trim(),
    };
    return (widget.load ?? AppStore.instance.adminRows)(section, filters);
  }

  void reload() {
    setState(() {
      future = fetch();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState value) {
    if (value == AppLifecycleState.resumed && !busy) reload();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    search.dispose();
    super.dispose();
  }

  void select(int index) {
    setState(() {
      section = sections[index];
      state = 'todos';
      type = 'todos';
      search.clear();
      future = fetch();
    });
    AppRoutes.replaceBrowserLocation('/admin/$section');
  }

  Future<void> action(Map<String, dynamic> item, String choice) async {
    final controller = TextEditingController();
    final reason = await showControllerDialog<String>(
      context: context,
      controllers: [controller],
      builder: (context) => AlertDialog(
        title: Text('Confirmar: $choice'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'A ação será registrada. Contas e reservas existentes serão preservadas. Bloqueio ou suspensão impede novas operações.',
              ),
              TextField(
                controller: controller,
                maxLength: 500,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Motivo (3 a 500 caracteres)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().length >= 3) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (reason == null || !mounted) return;
    setState(() => busy = true);
    final saved = await runAction(
      context,
      () => (widget.apply ?? AppStore.instance.adminAction)(
        section,
        item['id'].toString(),
        choice,
        reason,
      ),
    );
    if (!mounted) return;
    setState(() => busy = false);
    if (saved) {
      reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ação administrativa aplicada.')),
      );
    }
  }

  Future<void> logout() async {
    await NotificationService.instance.unregisterOnLogout();
    await SessionService.instance.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!authorized) {
      return const Scaffold(
        body: Center(child: Text('Acesso administrativo necessário.')),
      );
    }
    final account = section == 'contas';
    final history = section == 'historico';
    final states = account
        ? {
            'todos': 'Todas',
            'ativas': 'Ativas',
            'bloqueadas': 'Bloqueadas',
            'verificadas': 'Verificadas',
            'nao_verificadas': 'Não verificadas',
          }
        : {
            'todos': 'Todos',
            'ativos': 'Ativos',
            'inativos': 'Inativos',
            'suspensos': 'Suspensos',
            'restritos': 'Responsável bloqueado',
          };
    final types = history
        ? {
            'todos': 'Todos',
            'conta': 'Contas',
            'roteiro': 'Roteiros',
            'documento': 'Documentos',
            'avaliacao': 'Avaliações',
          }
        : {
            'todos': 'Todos',
            'usuario': 'Turista',
            'guia': 'Guia',
            'agencia': 'Agência',
            'admin': 'Admin',
          };
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administração'),
        actions: [
          IconButton(
            tooltip: 'Verificação profissional',
            onPressed: () => AppRoutes.push(
              context,
              '/admin/documentos',
              (_) => const AdminVerificationScreen(),
            ),
            icon: const Icon(Icons.verified_user_outlined),
          ),
          IconButton(
            tooltip: 'Moderar avaliações',
            onPressed: () => AppRoutes.push(
              context,
              '/admin/avaliacoes',
              (_) => const ReviewModerationScreen(),
            ),
            icon: const Icon(Icons.rate_review_outlined),
          ),
          IconButton(
            tooltip: 'Atualizar',
            onPressed: busy ? null : reload,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Sair',
            onPressed: logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: search,
                  maxLength: 120,
                  onSubmitted: (_) => reload(),
                  decoration: InputDecoration(
                    labelText: history
                        ? 'Identificação do alvo'
                        : 'Buscar por nome, cidade ou e-mail',
                    suffixIcon: IconButton(
                      tooltip: 'Buscar',
                      onPressed: busy ? null : reload,
                      icon: const Icon(Icons.search),
                    ),
                  ),
                ),
                Row(
                  children: [
                    if (!history)
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('$section-state'),
                          initialValue: state,
                          decoration: const InputDecoration(
                            labelText: 'Situação',
                          ),
                          items: [
                            for (final entry in states.entries)
                              DropdownMenuItem(
                                value: entry.key,
                                child: Text(entry.value),
                              ),
                          ],
                          onChanged: busy
                              ? null
                              : (value) {
                                  state = value ?? state;
                                  reload();
                                },
                        ),
                      ),
                    if (!history && account) const SizedBox(width: 12),
                    if (account || history)
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('$section-type'),
                          initialValue: type,
                          decoration: const InputDecoration(labelText: 'Tipo'),
                          items: [
                            for (final entry in types.entries)
                              DropdownMenuItem(
                                value: entry.key,
                                child: Text(entry.value),
                              ),
                          ],
                          onChanged: busy
                              ? null
                              : (value) {
                                  type = value ?? type;
                                  reload();
                                },
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: TextButton(
                      onPressed: reload,
                      child: const Text(
                        'Não foi possível carregar. Tentar novamente',
                      ),
                    ),
                  );
                }
                final rows = snapshot.data ?? [];
                if (rows.isEmpty) {
                  return const Center(
                    child: Text('Nenhum registro neste filtro.'),
                  );
                }
                return ListView(
                  children: [
                    for (final item in rows)
                      Card(
                        margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (history) ...[
                                Text(
                                  '${item['tipo']} · ${item['acao']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text('Referência: ${item['id_alvo']}'),
                                Text('${item['motivo']}'),
                                Text(
                                  '${item['resultado']} · ${formatBrazilianDateTime(parseAppDateTime(item['criado_em']?.toString() ?? ''))}',
                                ),
                              ] else ...[
                                Text(
                                  '${item['nome'] ?? 'Sem nome'}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (account) ...[
                                  Text(
                                    '${item['email'] ?? ''} · ${item['tipo']}',
                                  ),
                                  Text(
                                    item['ativo'] == false
                                        ? 'Conta bloqueada'
                                        : 'Conta ativa',
                                  ),
                                  if (item['cadastur_numero'] != null)
                                    Text(
                                      'Cadastur: ${item['cadastur_numero']}',
                                    ),
                                  Text(
                                    item['verificado'] == true
                                        ? 'Perfil verificado'
                                        : 'Sem selo de verificação',
                                  ),
                                ] else ...[
                                  Text(
                                    '${item['cidade'] ?? ''} - ${item['estado'] ?? ''}',
                                  ),
                                  Text(
                                    item['bloqueado_moderacao'] == true
                                        ? 'Suspenso pela administração'
                                        : item['responsavel_bloqueado'] == true
                                        ? 'Responsável bloqueado'
                                        : item['ativo'] == false
                                        ? 'Inativo pelo organizador'
                                        : 'Ativo',
                                  ),
                                  const Text(
                                    'Suspender não cancela as reservas existentes.',
                                  ),
                                ],
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (account &&
                                        item['tipo'] != 'admin' &&
                                        item['id'] !=
                                            SessionService.instance.userId)
                                      OutlinedButton(
                                        onPressed: busy
                                            ? null
                                            : () => action(
                                                item,
                                                item['ativo'] == false
                                                    ? 'desbloquear'
                                                    : 'bloquear',
                                              ),
                                        child: Text(
                                          item['ativo'] == false
                                              ? 'Desbloquear'
                                              : 'Bloquear',
                                        ),
                                      ),
                                    if (account &&
                                        const [
                                          'guia',
                                          'agencia',
                                        ].contains(item['tipo']))
                                      OutlinedButton(
                                        onPressed: busy
                                            ? null
                                            : () => action(
                                                item,
                                                item['verificado'] == true
                                                    ? 'remover_verificacao'
                                                    : 'verificar',
                                              ),
                                        child: Text(
                                          item['verificado'] == true
                                              ? 'Remover selo'
                                              : 'Verificar perfil',
                                        ),
                                      ),
                                    if (!account)
                                      OutlinedButton(
                                        onPressed: busy
                                            ? null
                                            : () => action(
                                                item,
                                                item['bloqueado_moderacao'] ==
                                                        true
                                                    ? 'liberar'
                                                    : 'suspender',
                                              ),
                                        child: Text(
                                          item['bloqueado_moderacao'] == true
                                              ? 'Liberar'
                                              : 'Suspender',
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: sections.indexOf(section),
        onDestinationSelected: busy ? null : select,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            label: 'Contas',
          ),
          NavigationDestination(icon: Icon(Icons.terrain), label: 'Roteiros'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Histórico'),
        ],
      ),
    );
  }
}
