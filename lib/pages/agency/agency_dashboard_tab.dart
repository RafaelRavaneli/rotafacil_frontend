import 'package:flutter/material.dart';
import '../common/operator_dashboard.dart';

class AgencyDashboardTab extends StatelessWidget {
  const AgencyDashboardTab({super.key, this.onOpenTrails});
  final VoidCallback? onOpenTrails;

  @override
  Widget build(BuildContext context) =>
      OperatorDashboard(isAgency: true, onOpenTrails: onOpenTrails);
}
