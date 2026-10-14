import 'package:flutter/material.dart';
import '../common/operator_dashboard.dart';

class GuideDashboardTab extends StatelessWidget {
  const GuideDashboardTab({super.key});

  @override
  Widget build(BuildContext context) =>
      const OperatorDashboard(isAgency: false);
}
