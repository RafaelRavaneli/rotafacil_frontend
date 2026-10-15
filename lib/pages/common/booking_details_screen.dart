import 'package:flutter/material.dart';
import '../../models/local_booking.dart';
import '../../models/trail_experience.dart';
import '../../services/session_service.dart';
import '../../state/app_store.dart';
import '../../theme/app_colors.dart';
import '../../utils/run_action.dart';
import '../../widgets/network_image_box.dart';

class BookingDetailsScreen extends StatefulWidget {
  const BookingDetailsScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  bool cancelling = false;
  bool acting = false;

  Future<void> _cancel(LocalBooking booking) async {
    if (cancelling) return;
    setState(() => cancelling = true);
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Cancelar reserva?'),
          content: Text(
            'Confirme o cancelamento da reserva para ${booking.trailName}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Manter reserva'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Confirmar cancelamento'),
            ),
          ],
        ),
      );
      if (confirm != true || !mounted) return;
      final saved = await runAction(
        context,
        () => AppStore.instance.cancelBooking(booking),
      );
      if (saved && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Reserva cancelada.')));
      }
    } finally {
      if (mounted) setState(() => cancelling = false);
    }
  }

  Future<void> _checkIn(LocalBooking booking) async {
    if (acting) return;
    setState(() => acting = true);
    try {
      final saved = await runAction(
        context,
        () => AppStore.instance.checkInBooking(booking),
      );
      if (saved && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check-in realizado. Boa trilha!')),
        );
      }
    } finally {
      if (mounted) setState(() => acting = false);
    }
  }

  Future<void> _checkOut(LocalBooking booking) async {
    if (acting) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Concluir atividade?'),
        content: const Text(
          'O check-out registra que a participação foi concluída.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Fazer check-out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => acting = true);
    try {
      final saved = await runAction(
        context,
        () => AppStore.instance.checkOutBooking(booking),
      );
      if (saved && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Atividade concluída.')));
      }
    } finally {
      if (mounted) setState(() => acting = false);
    }
  }

  Future<void> _review(LocalBooking booking) async {
    var rating = 5;
    final comment = TextEditingController();
    final data = await showDialog<(int, String)?>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Avaliar trilha'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                children: List.generate(
                  5,
                  (index) => IconButton(
                    tooltip: '${index + 1} estrela${index == 0 ? '' : 's'}',
                    onPressed: () => setDialogState(() => rating = index + 1),
                    icon: Icon(
                      index < rating ? Icons.star_rounded : Icons.star_border,
                      color: AppColors.earth,
                    ),
                  ),
                ),
              ),
              TextField(
                controller: comment,
                maxLength: 500,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Comentário',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, (rating, comment.text.trim())),
              child: const Text('Publicar avaliação'),
            ),
          ],
        ),
      ),
    );
    comment.dispose();
    if (data == null || !mounted) return;
    final saved = await runAction(
      context,
      () => AppStore.instance.reviewTrail(
        trailId: booking.trailId,
        rating: data.$1,
        comment: data.$2,
      ),
    );
    if (saved && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Avaliação publicada.')));
    }
  }

  Future<void> _showEmergency(LocalBooking booking) async {
    final EmergencyContact? contact = await runValueAction<EmergencyContact>(
      context,
      () => AppStore.instance.emergencyContactFor(booking.personId),
    );
    if (contact == null || !mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Contato de emergência'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Information(label: 'Participante', value: contact.participantName),
            _Information(
              label: 'Telefone do participante',
              value: contact.participantPhone,
            ),
            _Information(label: 'Contato', value: contact.contactName),
            _Information(
              label: 'Telefone de emergência',
              value: contact.contactPhone,
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da reserva')),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final booking = store.bookings
              .where((b) => b.id == widget.bookingId)
              .firstOrNull;
          if (booking == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Esta reserva não está disponível. Volte para consultar suas reservas.',
                ),
              ),
            );
          }
          final trail = store.trails
              .where((t) => t.id == booking.trailId)
              .firstOrNull;
          final role = SessionService.instance.role?.toLowerCase() ?? '';
          final isOperator = role == 'guia' || role == 'agencia';
          final normalizedStatus = BookingStatus.normalize(booking.status);
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                children: [
                  if (trail != null && trail.imageUrl.isNotEmpty) ...[
                    SizedBox(
                      height: 210,
                      child: NetworkImageBox(
                        url: trail.imageUrl,
                        borderRadius: 22,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Text(
                    booking.trailName,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.forest,
                    ),
                  ),
                  if (trail != null)
                    Text(
                      trail.location,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Resumo da reserva',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _Information(
                            label: 'Identificação',
                            value: booking.id,
                          ),
                          _Information(
                            label: 'Situação',
                            value: booking.status,
                          ),
                          _Information(label: 'Data', value: booking.date),
                          _Information(
                            label: 'Nome registrado',
                            value: booking.personName,
                          ),
                          _Information(
                            label: 'Responsável pela trilha',
                            value: trail?.guideName == 'Guia responsável'
                                ? ''
                                : (trail?.guideName ?? ''),
                          ),
                          _Information(
                            label: 'Valor declarado',
                            value:
                                'R\$ ${booking.valuePaid.toStringAsFixed(2).replaceAll('.', ',')}',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'O valor declarado não comprova pagamento. O aplicativo não realiza cobrança online.',
                    style: TextStyle(color: AppColors.muted, height: 1.5),
                  ),
                  if (trail == null) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Os dados atuais da trilha não estão disponíveis. Os dados da reserva foram preservados.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ],
                  if (BookingStatus.isConfirmed(booking.status)) ...[
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: acting ? null : () => _checkIn(booking),
                      icon: const Icon(Icons.login_rounded),
                      label: Text(acting ? 'Registrando...' : 'Fazer check-in'),
                    ),
                  ],
                  if (normalizedStatus == 'Em andamento') ...[
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: acting ? null : () => _checkOut(booking),
                      icon: const Icon(Icons.logout_rounded),
                      label: Text(
                        acting ? 'Registrando...' : 'Fazer check-out',
                      ),
                    ),
                  ],
                  if (normalizedStatus == 'Concluído' && !isOperator) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _review(booking),
                      icon: const Icon(Icons.star_outline_rounded),
                      label: const Text('Avaliar trilha'),
                    ),
                  ],
                  if (isOperator &&
                      booking.personId.isNotEmpty &&
                      BookingStatus.isActive(booking.status)) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _showEmergency(booking),
                      icon: const Icon(Icons.emergency_outlined),
                      label: const Text('Contato de emergência'),
                    ),
                  ],
                  if (BookingStatus.canCancel(booking.status)) ...[
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: cancelling ? null : () => _cancel(booking),
                      icon: const Icon(Icons.cancel_outlined),
                      label: Text(
                        cancelling ? 'Cancelando...' : 'Cancelar reserva',
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
}

class _Information extends StatelessWidget {
  const _Information({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 3),
        SelectableText(
          value.trim().isEmpty ? 'Não informado' : value,
          style: const TextStyle(
            color: AppColors.forest,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
