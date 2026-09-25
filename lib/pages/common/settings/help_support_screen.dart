import 'package:flutter/material.dart';

import '../../../state/app_store.dart';
import '../../../theme/app_colors.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key, required this.role});

  final String role;

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final message = TextEditingController();
  final scrollController = ScrollController();

  @override
  void dispose() {
    message.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = message.text.trim();

    if (text.isEmpty) return;

    message.clear();

    await AppStore.instance.sendSupportMessage(
      userRole: widget.role,
      text: text,
    );

    await AppStore.instance.addNotification(
      title: 'Mensagem enviada ao suporte',
      body: 'A equipe RotaFácil recebeu sua solicitação.',
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mensagem enviada ao suporte.')),
    );

    _scrollToBottom();
  }

  Future<void> _replyAsSupport() async {
    final reply = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Responder como suporte',
                style: TextStyle(
                  color: AppColors.green900,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Modo de demonstração: permite testar '
                'o fluxo completo de atendimento sem criar '
                'um quarto tipo de usuário.',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: reply,
                autofocus: true,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Resposta do suporte',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () async {
                  final text = reply.text.trim();

                  if (text.isEmpty) {
                    return;
                  }

                  await AppStore.instance.replyAsSupport(
                    userRole: widget.role,
                    text: text,
                  );

                  if (!sheetContext.mounted) {
                    return;
                  }

                  Navigator.pop(sheetContext);
                },
                icon: const Icon(Icons.support_agent_rounded),
                label: const Text('Enviar resposta'),
              ),
            ],
          ),
        );
      },
    );

    reply.dispose();

    if (!mounted) return;

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ajuda e suporte',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Responder como suporte',
            onPressed: _replyAsSupport,
            icon: const Icon(Icons.support_agent_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: store,
              builder: (context, _) {
                final conversation = store.supportConversationForRole(
                  widget.role,
                );

                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    const _Faq(
                      question: 'Como funciona o agendamento?',
                      answer:
                          'Abra uma trilha, toque em Agendar trilha '
                          'e confirme. A reserva ficará na aba '
                          'Agendamentos.',
                    ),
                    const _Faq(
                      question: 'Como uma agência adiciona um guia?',
                      answer:
                          'Na aba Guias, use Convidar guia, '
                          'informe nome, e-mail e especialidade. '
                          'Depois é possível ativar ou remover.',
                    ),
                    const _Faq(
                      question: 'Como cadastrar e editar uma trilha?',
                      answer:
                          'Guias e agências usam a aba Trilhas. '
                          'É possível adicionar foto, localização, '
                          'data, dificuldade, preço e editar depois.',
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Conversa com o suporte',
                            style: TextStyle(
                              color: AppColors.green900,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.green100,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: const Text(
                            'Equipe RotaFácil',
                            style: TextStyle(
                              color: AppColors.green700,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (conversation.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.green100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'Envie uma mensagem e ela aparecerá aqui. '
                          'Use o ícone de atendente no topo para '
                          'simular a resposta da equipe de suporte.',
                          style: TextStyle(
                            color: AppColors.green900,
                            fontSize: 12,
                            height: 1.45,
                          ),
                        ),
                      )
                    else
                      ...conversation.map((item) {
                        final fromSupport = item.fromSupport;

                        return Align(
                          alignment: fromSupport
                              ? Alignment.centerLeft
                              : Alignment.centerRight,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 330),
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: fromSupport
                                  ? AppColors.paper
                                  : AppColors.green700,
                              borderRadius: BorderRadius.circular(16),
                              border: fromSupport
                                  ? Border.all(color: AppColors.border)
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fromSupport ? 'Suporte RotaFácil' : 'Você',
                                  style: TextStyle(
                                    color: fromSupport
                                        ? AppColors.green700
                                        : AppColors.white.withValues(alpha: .8),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.text,
                                  style: TextStyle(
                                    color: fromSupport
                                        ? AppColors.ink
                                        : AppColors.white,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              decoration: const BoxDecoration(
                color: AppColors.paper,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: message,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Descreva sua dúvida...',
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _send,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Faq extends StatelessWidget {
  const _Faq({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            answer,
            style: const TextStyle(color: AppColors.muted, height: 1.45),
          ),
        ),
      ],
    );
  }
}
