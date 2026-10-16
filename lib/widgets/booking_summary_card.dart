import 'package:flutter/material.dart';
import '../models/local_booking.dart';
import '../theme/app_colors.dart';

class BookingSummaryCard extends StatelessWidget {
  const BookingSummaryCard({
    super.key,
    required this.booking,
    required this.onTap,
  });
  final LocalBooking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.white,
      elevation: 1,
      shadowColor: AppColors.shadow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.sage,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.hiking_rounded,
                      color: AppColors.forest,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      booking.trailName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: AppColors.muted),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: BookingStatus.isCancelled(booking.status)
                          ? AppColors.red.withValues(alpha: .08)
                          : AppColors.sage,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      booking.status,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: BookingStatus.isCancelled(booking.status)
                            ? AppColors.red
                            : AppColors.forest,
                      ),
                    ),
                  ),
                  Text(
                    booking.date.isEmpty ? 'Data não informada' : booking.date,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
              if (booking.personName.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  booking.personName,
                  style: const TextStyle(color: AppColors.ink, fontSize: 13),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                'Valor declarado: R\$ ${booking.valuePaid.toStringAsFixed(2).replaceAll('.', ',')}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ver detalhes da reserva',
                style: TextStyle(
                  color: AppColors.forest,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
