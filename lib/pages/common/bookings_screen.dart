import 'package:flutter/material.dart';
import '../../models/local_booking.dart';
import '../../state/app_store.dart';
import '../../theme/app_colors.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key, required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;

    return SafeArea(
      child: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final normalized = role.toLowerCase();
          final list = store.bookings.where((booking) {
            if (normalized == 'turista') {
              return booking.roleView == 'turista';
            }
            if (normalized == 'guia') {
              return booking.roleView == 'guia' ||
                  booking.roleView == 'turista';
            }
            return true;
          }).toList();

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    normalized == 'turista'
                        ? 'Meus agendamentos'
                        : 'Agendamentos',
                    style: const TextStyle(
                      color: AppColors.green900,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              if (list.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: Text('Nenhum agendamento encontrado.')),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  sliver: SliverList.separated(
                    itemCount: list.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return _BookingCard(booking: list[index]);
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking});
  final LocalBooking booking;

  @override
  Widget build(BuildContext context) {
    final cancelled = booking.status == 'Cancelado';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.trailName,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                booking.status,
                style: TextStyle(
                  color: cancelled ? AppColors.red : AppColors.green700,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            booking.personName,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            booking.date,
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            'Valor: R\$ ${booking.valuePaid.toStringAsFixed(2)}',
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
          if (!cancelled) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Cancelar agendamento?'),
                    content: Text(booking.trailName),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Voltar'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text('Cancelar'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await AppStore.instance.cancelBooking(booking);
                }
              },
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancelar agendamento'),
            ),
          ],
        ],
      ),
    );
  }
}
