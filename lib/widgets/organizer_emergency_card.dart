import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/trail.dart';

class OrganizerEmergencyCard extends StatelessWidget {
  const OrganizerEmergencyCard({super.key, required this.trail});
  final Trail trail;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Emergência: contato do organizador',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      SelectableText(
        trail.organizerEmergencyPhone.trim().isEmpty
            ? 'Telefone não informado'
            : trail.organizerEmergencyPhone,
      ),
      Text(
        trail.emergencyInstructions.trim().isEmpty
            ? 'Instruções não informadas'
            : trail.emergencyInstructions,
      ),
      if (trail.organizerEmergencyPhone.trim().isNotEmpty)
        OutlinedButton.icon(
          icon: const Icon(Icons.phone_outlined),
          label: const Text('Ligar para o organizador'),
          onPressed: () async {
            final phone = trail.organizerEmergencyPhone.replaceAll(
              RegExp(r'[^0-9+]'),
              '',
            );
            var opened = false;
            try {
              opened = await launchUrl(Uri(scheme: 'tel', path: phone));
            } catch (_) {
              opened = false;
            }
            if (!opened && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Não foi possível abrir a ligação. Use o telefone informado.',
                  ),
                ),
              );
            }
          },
        ),
    ],
  );
}
