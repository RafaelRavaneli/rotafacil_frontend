import 'package:flutter/material.dart';
import '../../services/session_service.dart';
import 'admin_console_screen.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key, this.initialSection = 'contas'});
  final String initialSection;
  @override
  Widget build(BuildContext context) =>
      SessionService.instance.role?.toLowerCase() == 'admin'
      ? AdminConsoleScreen(initialSection: initialSection)
      : const Scaffold(
          body: Center(child: Text('Acesso administrativo necessário.')),
        );
}
