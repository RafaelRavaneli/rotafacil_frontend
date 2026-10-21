import '../../utils/controller_dialog.dart';
import 'professional_profile_screen.dart';
import '../../widgets/organizer_emergency_card.dart';
import '../../navigation/app_routes.dart';
import '../../widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_config.dart';
import '../../models/local_booking.dart';
import '../../models/trail_experience.dart';
import '../../services/session_service.dart';
import '../../state/app_store.dart';
import '../../theme/app_colors.dart';
import '../../utils/date_time_format.dart';
import '../../utils/run_action.dart';
import '../../widgets/network_image_box.dart';
import '../../widgets/trail_weather_card.dart';
import '../../widgets/personal_checklist_card.dart';
import '../../widgets/packing_items_list.dart';

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
          const SnackBar(content: Text('Check-in realizado. Bom roteiro!')),
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

  Future<void> _review(LocalBooking booking, {bool editing = false}) async {
    TrailReview? existing;
    if (editing) {
      existing = await runValueAction<TrailReview>(
        context,
        () => AppStore.instance.ownReview(booking.id),
      );
      if (existing == null || !mounted) return;
      if (!existing.editable) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sua avaliação'),
            content: SingleChildScrollView(
              child: Text(
                '${existing!.comment}\n\n${existing.moderationStatus == 'oculta' ? 'Avaliação ocultada pela moderação.' : 'Prazo de edição encerrado.'}',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
            ],
          ),
        );
        return;
      }
    }
    var trailRating = existing?.rating ?? 0;
    var guideRating = existing?.guideRating ?? 0;
    var agencyRating = existing?.agencyRating ?? 0;
    final comment = TextEditingController(text: existing?.comment);
    final data = await showControllerDialog<(int, int, int?, String)?>(
      controllers: [comment],
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Avaliar experiência'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edição disponível por 7 dias após o primeiro envio. Notas de 0 a 5. Avaliações ocultadas não podem ser editadas.',
                ),
                _RatingSelector(
                  label: 'Roteiro',
                  value: trailRating,
                  onChanged: (value) =>
                      setDialogState(() => trailRating = value),
                ),
                _RatingSelector(
                  label: 'Guia',
                  value: guideRating,
                  onChanged: (value) =>
                      setDialogState(() => guideRating = value),
                ),
                if (booking.agencyId.isNotEmpty)
                  _RatingSelector(
                    label: booking.agencyName.isEmpty
                        ? 'Agência'
                        : booking.agencyName,
                    value: agencyRating,
                    onChanged: (value) =>
                        setDialogState(() => agencyRating = value),
                  ),
                const SizedBox(height: 8),
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, (
                trailRating,
                guideRating,
                booking.agencyId.isEmpty ? null : agencyRating,
                comment.text.trim(),
              )),
              child: Text(editing ? 'Salvar avaliação' : 'Publicar avaliação'),
            ),
          ],
        ),
      ),
    );
    if (data == null || !mounted) return;
    final saved = await runAction(
      context,
      () => editing
          ? AppStore.instance.editReview(existing!.id, {
              'nota': data.$1,
              'nota_guia': data.$2,
              if (data.$3 != null) 'nota_agencia': data.$3,
              'comentario': data.$4,
            })
          : AppStore.instance.reviewTrail(
              bookingId: booking.id,
              trailId: booking.trailId,
              trailRating: data.$1,
              guideRating: data.$2,
              agencyRating: data.$3,
              comment: data.$4,
            ),
    );
    if (saved && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Avaliação publicada.')));
    }
  }

  Future<void> _contactResponsible(LocalBooking booking) async {
    var phone = booking.contactPhone.replaceAll(RegExp(r'\D'), '');
    if (phone.length == 10 || phone.length == 11) phone = '55$phone';
    if (phone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('O responsável não informou WhatsApp.')),
        );
      }
      return;
    }
    final uri = Uri.https('wa.me', '/$phone', {
      'text':
          'Olá! Minha reserva no roteiro ${booking.trailName} foi confirmada. Identificação: ${booking.id}.',
    });
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
      );
    }
  }

  Future<void> _showEmergency(LocalBooking booking) async {
    final EmergencyContact? contact = await runValueAction<EmergencyContact>(
      context,
      () => AppStore.instance.emergencyContactFor(
        booking.personId,
        bookingId: booking.id,
      ),
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
            _Information(label: 'Relação', value: contact.relation),
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
      appBar: AppBar(
        leading: AppBackButton(fallbackLocation: AppRoutes.bookingListLocation),
        title: const Text('Detalhes da reserva'),
      ),
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
          final departure = trail?.effectiveDepartures
              .where(
                (item) => booking.departureId.isNotEmpty
                    ? item.id == booking.departureId
                    : formatBrazilianDate(item.startsAt.toIso8601String()) ==
                          formatBrazilianDate(booking.date),
              )
              .firstOrNull;
          final start =
              parseAppDateTime(booking.startsAt) ?? departure?.startsAt;
          final end = parseAppDateTime(booking.endsAt) ?? departure?.endsAt;
          final weatherDate = start ?? parseAppDateTime(booking.date);
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
                          _Information(
                            label: 'Data',
                            value: formatBrazilianDate(booking.date),
                          ),
                          _Information(
                            label: 'Nome registrado',
                            value: booking.personName,
                          ),
                          _Information(
                            label: booking.agencyId.isNotEmpty
                                ? 'Agência responsável pelo roteiro'
                                : 'Responsável pelo roteiro',
                            value: booking.agencyId.isNotEmpty
                                ? booking.agencyName
                                : trail?.guideName == 'Guia responsável'
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
                  _Information(
                    label: 'Início',
                    value: formatBrazilianDateTime(start),
                  ),
                  _Information(
                    label: 'Término',
                    value: formatBrazilianDateTime(end),
                  ),
                  if (trail != null) ...[
                    OrganizerEmergencyCard(trail: trail),
                    const SizedBox(height: 12),
                    _Information(
                      label: 'Ponto de encontro',
                      value: trail.meetingPoint,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'O que levar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isOperator || role == 'admin')
                      PackingItemsList(trail: trail)
                    else
                      PersonalChecklistCard(
                        key: ValueKey('packing-${booking.id}'),
                        booking: booking,
                        trail: trail,
                      ),
                    if (trail.latitude != null && trail.longitude != null)
                      OutlinedButton.icon(
                        onPressed: () => runAction(context, () async {
                          final opened = await launchUrl(
                            Uri.https('www.google.com', '/maps/dir/', {
                              'api': '1',
                              'destination':
                                  '${trail.latitude},${trail.longitude}',
                              'travelmode': 'driving',
                            }),
                            mode: LaunchMode.externalApplication,
                          );
                          if (!opened) {
                            throw StateError(
                              'Não foi possível abrir o Google Maps.',
                            );
                          }
                        }),
                        icon: const Icon(Icons.directions_outlined),
                        label: const Text('Abrir rota no Google Maps'),
                      ),
                    const SizedBox(height: 12),
                    TrailWeatherCard(trail: trail, date: weatherDate),
                    const SizedBox(height: 14),
                  ],
                  const Text(
                    'O valor declarado não comprova pagamento. O aplicativo não realiza cobrança online.',
                    style: TextStyle(color: AppColors.muted, height: 1.5),
                  ),
                  if (trail == null) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Os dados atuais do roteiro não estão disponíveis. Os dados da reserva foram preservados.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ],
                  if (AppConfig.enableCheckInCheckout &&
                      isOperator &&
                      BookingStatus.isConfirmed(booking.status)) ...[
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: acting ? null : () => _checkIn(booking),
                      icon: const Icon(Icons.login_rounded),
                      label: Text(acting ? 'Registrando...' : 'Fazer check-in'),
                    ),
                  ],
                  if (AppConfig.enableCheckInCheckout &&
                      isOperator &&
                      normalizedStatus == 'Em andamento') ...[
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: acting ? null : () => _checkOut(booking),
                      icon: const Icon(Icons.logout_rounded),
                      label: Text(
                        acting ? 'Registrando...' : 'Fazer check-out',
                      ),
                    ),
                  ],
                  if (!isOperator &&
                      BookingStatus.isConfirmed(booking.status)) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _contactResponsible(booking),
                      icon: const Icon(Icons.chat_outlined),
                      label: Text(booking.contactLabel),
                    ),
                  ],
                  if (!isOperator &&
                      (BookingStatus.isConfirmed(booking.status) ||
                          normalizedStatus == 'Em andamento') &&
                      start != null &&
                      end != null &&
                      !DateTime.now().isBefore(
                        start.subtract(const Duration(hours: 24)),
                      ) &&
                      !DateTime.now().isAfter(end)) ...[
                    const SizedBox(height: 12),
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.star_outline_rounded),
                      title: Text('Avaliação disponível após a conclusão'),
                      subtitle: Text(
                        'O responsável precisa finalizar esta saída para você avaliar o roteiro, o guia e a agência.',
                      ),
                    ),
                  ],
                  if (booking.agencyId.isNotEmpty)
                    TextButton(
                      onPressed: () => AppRoutes.push(
                        context,
                        '/profissional/${Uri.encodeComponent(booking.agencyId)}',
                        (_) => ProfessionalProfileScreen(id: booking.agencyId),
                      ),
                      child: const Text('Ver perfil e avaliações da agência'),
                    ),
                  if (normalizedStatus == 'Concluído' &&
                      !isOperator &&
                      !booking.evaluated) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _review(booking),
                      icon: const Icon(Icons.star_outline_rounded),
                      label: const Text('Avaliar roteiro, guia e agência'),
                    ),
                  ],
                  if (normalizedStatus == 'Concluído' &&
                      !isOperator &&
                      booking.evaluated) ...[
                    const SizedBox(height: 12),
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.check_circle_outline),
                      title: Text('Avaliação enviada'),
                    ),
                    OutlinedButton(
                      onPressed: () => _review(booking, editing: true),
                      child: const Text('Ver ou editar avaliação'),
                    ),
                  ],
                  if (isOperator &&
                      booking.personId.isNotEmpty &&
                      (BookingStatus.isConfirmed(booking.status) ||
                          normalizedStatus == 'Em andamento') &&
                      start != null &&
                      end != null &&
                      !DateTime.now().isBefore(
                        start.subtract(const Duration(hours: 24)),
                      ) &&
                      !DateTime.now().isAfter(end)) ...[
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

class _RatingSelector extends StatelessWidget {
  const _RatingSelector({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Text('$value/5'),
          ],
        ),
        Wrap(
          spacing: 0,
          children: [
            IconButton(
              tooltip: '0 estrelas',
              onPressed: () => onChanged(0),
              icon: Icon(
                Icons.star_outline_rounded,
                color: value == 0 ? AppColors.earth : AppColors.muted,
              ),
            ),
            ...List.generate(
              5,
              (index) => IconButton(
                tooltip: '${index + 1} estrela${index == 0 ? '' : 's'}',
                onPressed: () => onChanged(index + 1),
                icon: Icon(
                  index < value ? Icons.star_rounded : Icons.star_border,
                  color: AppColors.earth,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
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
