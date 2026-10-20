import 'package:flutter/material.dart';
import '../common/operator_dashboard.dart';

class GuideDashboardTab extends StatelessWidget {
  const GuideDashboardTab({super.key, this.onOpenTrails});
  final VoidCallback? onOpenTrails;

  @override
  Widget build(BuildContext context) =>
      OperatorDashboard(isAgency: false, onOpenTrails: onOpenTrails);
}
