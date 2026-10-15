import 'package:flutter/material.dart';
import '../common/operator_dashboard.dart';

class GuideDashboardTab extends StatelessWidget {
  const GuideDashboardTab({super.key, this.onOpenBookings});
  final VoidCallback? onOpenBookings;

  @override
  Widget build(BuildContext context) =>
      OperatorDashboard(isAgency: false, onOpenBookings: onOpenBookings);
}
