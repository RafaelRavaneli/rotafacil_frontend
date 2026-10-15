import '../../widgets/backend_refresh.dart';
import 'package:flutter/material.dart';
import '../../state/app_store.dart';
import '../../theme/app_colors.dart';
import '../../widgets/booking_summary_card.dart';
import 'booking_details_screen.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key, required this.role, this.onRefresh});
  final String role;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return BackendRefresh(
      onRefresh: onRefresh,
      child: SafeArea(
        child: AnimatedBuilder(
          animation: store,
          builder: (context, _) {
            final normalized = role.toLowerCase();
            final list = store.bookings.where((booking) {
              if (normalized == 'turista') return booking.roleView == 'turista';
              if (normalized == 'guia') {
                return booking.roleView == 'guia' ||
                    booking.roleView == 'turista';
              }
              return true;
            }).toList();
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(
                      normalized == 'turista' ? 'Minhas reservas' : 'Reservas',
                      style: const TextStyle(
                        color: AppColors.forest,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Acompanhe suas atividades e consulte os detalhes de cada reserva.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 20),
                    if (list.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('Nenhuma reserva disponível.'),
                        ),
                      ),
                    ...list.map(
                      (booking) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: BookingSummaryCard(
                          booking: booking,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  BookingDetailsScreen(bookingId: booking.id),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
