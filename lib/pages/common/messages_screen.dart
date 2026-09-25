import 'package:flutter/material.dart';

import '../../models/guide.dart';
import '../../state/app_store.dart';
import '../../theme/app_colors.dart';
import '../../widgets/network_image_box.dart';
import '../../widgets/profile_avatar.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key, required this.role, this.targetGuide});

  final String role;
  final GuideProfile? targetGuide;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final controller = TextEditingController();
  final scrollController = ScrollController();

  String get currentRole {
    return AppStore.instance.normalizeRole(widget.role);
  }

  String get counterpartRole {
    if (currentRole == 'guia') {
      return 'turista';
    }

    return 'guia';
  }

  String get counterpartTitle {
    if (counterpartRole == 'guia') {
      return 'Guia';
    }

    return 'Turista';
  }

  String get conversationGuideName {
    return widget.targetGuide?.name ?? AppStore.instance.guide.name;
  }

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = controller.text.trim();

    if (text.isEmpty) return;

    controller.clear();

    await AppStore.instance.sendDirectMessage(
      senderRole: currentRole,
      recipientRole: counterpartRole,
      guideName: conversationGuideName,
      text: text,
    );

    if (!mounted) return;

    await Future<void>.delayed(const Duration(milliseconds: 40));

    if (scrollController.hasClients) {
      await scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    final counterpart = store.userForRole(counterpartRole);
    final selectedGuide = widget.targetGuide;

    final displayName = selectedGuide?.name ?? counterpart.name;

    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            decoration: const BoxDecoration(
              color: AppColors.paper,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                if (selectedGuide != null)
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: NetworkImageBox(
                      url: selectedGuide.imageUrl,
                      borderRadius: 24,
                    ),
                  )
                else
                  ProfileAvatar(
                    dataUrl: counterpart.profileImageDataUrl,
                    radius: 22,
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: AppColors.green900,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Conversa com $counterpartTitle',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selectedGuide?.verified ?? (counterpartRole == 'guia'))
                  const Icon(
                    Icons.verified_rounded,
                    color: AppColors.green700,
                    size: 18,
                  ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: store,
              builder: (context, _) {
                final messages = store.conversationBetween(
                  currentRole,
                  counterpartRole,
                  guideName: conversationGuideName,
                );

                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Text(
                        'Nenhuma mensagem com $displayName ainda.\n'
                        'Envie a primeira mensagem.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(18),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final sentByMe = message.senderRole == currentRole;

                    return Align(
                      alignment: sentByMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 320),
                        margin: const EdgeInsets.only(bottom: 9),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: sentByMe
                              ? AppColors.green700
                              : AppColors.paper,
                          borderRadius: BorderRadius.circular(16),
                          border: sentByMe
                              ? null
                              : Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.text,
                              style: TextStyle(
                                color: sentByMe
                                    ? AppColors.white
                                    : AppColors.ink,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _timeLabel(message.createdAt),
                              style: TextStyle(
                                color: sentByMe
                                    ? AppColors.white.withValues(alpha: .75)
                                    : AppColors.muted,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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
                      controller: controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        hintText: 'Mensagem para $displayName...',
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

  String _timeLabel(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
