import 'package:flutter/material.dart';
import '../../services/community_api.dart';
import '../../services/session_service.dart';
import '../../utils/auth_error_message.dart';
import '../../utils/role_utils.dart';

class RemoteConversationsScreen extends StatefulWidget {
  const RemoteConversationsScreen({super.key, this.support = false, this.api});
  final bool support;
  final CommunityApi? api;
  @override
  State<RemoteConversationsScreen> createState() => _RemoteConversationsState();
}

class _RemoteConversationsState extends State<RemoteConversationsScreen> {
  late final api = widget.api ?? CommunityApi();
  late Future<List<Map<String, dynamic>>> entries;
  bool creating = false;
  String get path => widget.support ? '/api/suporte' : '/api/conversas';
  @override
  void initState() {
    super.initState();
    entries = api.list(path);
  }

  void reload() {
    setState(() {
      entries = api.list(path);
    });
  }

  String title(Map<String, dynamic> item) {
    if (widget.support) return item['assunto']?.toString() ?? 'Atendimento';
    final names = item['nomes'] as Map? ?? {};
    final other = names.entries.where(
      (entry) => entry.key != SessionService.instance.userId,
    );
    return other.isEmpty ? 'Conversa' : other.first.value.toString();
  }

  Future<void> open(Map<String, dynamic> item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RemoteMessagesScreen(
          path: '$path/${Uri.encodeComponent(item['id'].toString())}/mensagens',
          title: title(item),
          api: api,
        ),
      ),
    );
    if (mounted) reload();
  }

  Future<void> create() async {
    if (creating) return;
    setState(() => creating = true);
    try {
      Map<String, dynamic>? result;
      if (widget.support) {
        final draft = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (_) => const _SupportDraft(),
        );
        if (draft != null) result = await api.create(path, draft);
      } else {
        final guides = await api.list('/api/guias');
        if (!mounted) return;
        final guide = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (dialog) => SimpleDialog(
            title: const Text('Conversar com um guia'),
            children: guides.isEmpty
                ? [
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Nenhum guia disponível.'),
                    ),
                  ]
                : guides
                      .map(
                        (guide) => SimpleDialogOption(
                          onPressed: () => Navigator.pop(dialog, guide),
                          child: Text(guide['nome']?.toString() ?? 'Guia'),
                        ),
                      )
                      .toList(),
          ),
        );
        if (guide != null) {
          result = await api.create(path, {'id_guia': guide['id']});
        }
      }
      if (result != null && mounted) {
        await open(result);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => creating = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.support ? 'Ajuda e suporte' : 'Mensagens'),
      actions: [
        IconButton(
          onPressed: reload,
          tooltip: 'Atualizar',
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    floatingActionButton:
        widget.support ||
            normalizeRoleKey(SessionService.instance.role) == 'turista'
        ? FloatingActionButton.extended(
            onPressed: creating ? null : create,
            icon: const Icon(Icons.add),
            label: Text(
              creating
                  ? 'Aguarde...'
                  : widget.support
                  ? 'Novo atendimento'
                  : 'Nova conversa',
            ),
          )
        : null,
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: entries,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _Retry(
            message: authErrorMessage(snapshot.error!),
            retry: reload,
          );
        }
        final data = snapshot.data ?? [];
        if (data.isEmpty) {
          return Center(
            child: Text(
              widget.support
                  ? 'Nenhum atendimento aberto.'
                  : 'Nenhuma conversa ainda.',
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 96),
          itemCount: data.length,
          itemBuilder: (context, index) => ListTile(
            leading: Icon(
              widget.support ? Icons.support_agent : Icons.chat_bubble_outline,
            ),
            title: Text(title(data[index])),
            subtitle: widget.support
                ? Text(data[index]['status'].toString())
                : null,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => open(data[index]),
          ),
        );
      },
    ),
  );
}

class RemoteMessagesScreen extends StatefulWidget {
  const RemoteMessagesScreen({
    super.key,
    required this.path,
    required this.title,
    required this.api,
  });
  final String path;
  final String title;
  final CommunityApi api;
  @override
  State<RemoteMessagesScreen> createState() => _RemoteMessagesState();
}

class _RemoteMessagesState extends State<RemoteMessagesScreen> {
  final input = TextEditingController();
  late Future<List<Map<String, dynamic>>> entries;
  bool sending = false;
  String? sendError;
  @override
  void initState() {
    super.initState();
    entries = widget.api.list(widget.path);
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  void reload() {
    setState(() {
      entries = widget.api.list(widget.path);
    });
  }

  Future<void> send() async {
    final text = input.text.trim();
    if (text.isEmpty || sending) return;
    setState(() {
      sending = true;
      sendError = null;
    });
    try {
      await widget.api.create(widget.path, {'texto': text});
      if (!mounted) return;
      input.clear();
      reload();
    } catch (error) {
      if (mounted) {
        setState(() => sendError = authErrorMessage(error));
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.title),
      actions: [
        IconButton(
          onPressed: reload,
          tooltip: 'Atualizar mensagens',
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: entries,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _Retry(
                    message: authErrorMessage(snapshot.error!),
                    retry: reload,
                  );
                }
                final data = snapshot.data ?? [];
                if (data.isEmpty) {
                  return const Center(
                    child: Text('Envie a primeira mensagem.'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final item = data[index];
                    final mine =
                        item['id_autor'] == SessionService.instance.userId;
                    return Align(
                      alignment: mine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Card(
                        color: mine
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['atendente'] == true
                                    ? 'Equipe de suporte'
                                    : item['nome_autor']?.toString() ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(item['texto']?.toString() ?? ''),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (sendError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                sendError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: input,
                    enabled: !sending,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 2000,
                    decoration: const InputDecoration(
                      hintText: 'Escreva sua mensagem',
                      counterText: '',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: sending ? null : send,
                  tooltip: 'Enviar',
                  icon: sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _Retry extends StatelessWidget {
  const _Retry({required this.message, required this.retry});
  final String message;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          TextButton(onPressed: retry, child: const Text('Tentar novamente')),
        ],
      ),
    ),
  );
}

class _SupportDraft extends StatefulWidget {
  const _SupportDraft();
  @override
  State<_SupportDraft> createState() => _SupportDraftState();
}

class _SupportDraftState extends State<_SupportDraft> {
  final subject = TextEditingController();
  final text = TextEditingController();
  @override
  void dispose() {
    subject.dispose();
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Novo atendimento'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: subject,
            maxLength: 120,
            decoration: const InputDecoration(labelText: 'Assunto'),
          ),
          TextField(
            controller: text,
            maxLength: 2000,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Como podemos ajudar?',
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
          if (subject.text.trim().isNotEmpty && text.text.trim().isNotEmpty) {
            Navigator.pop(context, {
              'assunto': subject.text.trim(),
              'texto': text.text.trim(),
            });
          }
        },
        child: const Text('Enviar'),
      ),
    ],
  );
}
