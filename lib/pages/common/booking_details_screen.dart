import 'package:flutter/material.dart';
import '../../models/local_booking.dart';
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
                  if (!BookingStatus.isCancelled(booking.status)) ...[
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
