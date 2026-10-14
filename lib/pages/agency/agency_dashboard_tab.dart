import 'package:flutter/material.dart';
import '../common/operator_dashboard.dart';

class AgencyDashboardTab extends StatelessWidget {
  const AgencyDashboardTab({super.key});

  @override
  Widget build(BuildContext context) => const OperatorDashboard(isAgency: true);
}
