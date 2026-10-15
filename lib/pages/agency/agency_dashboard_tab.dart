import 'package:flutter/material.dart';
import '../common/operator_dashboard.dart';

class AgencyDashboardTab extends StatelessWidget {
  const AgencyDashboardTab({super.key, this.onOpenBookings});
  final VoidCallback? onOpenBookings;

  @override
  Widget build(BuildContext context) =>
      OperatorDashboard(isAgency: true, onOpenBookings: onOpenBookings);
}
