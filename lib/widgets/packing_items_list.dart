import 'package:flutter/material.dart';
import '../models/trail.dart';
import '../models/packing_checklist.dart';

class PackingItemsList extends StatelessWidget {
  const PackingItemsList({super.key, required this.trail});
  final Trail trail;
  @override
  Widget build(BuildContext context) {
    final items = PackingChecklist.fromTrail(trail).items;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (items.isEmpty)
          const Text('Lista ainda não informada pelo responsável.'),
        for (final requiredItem in [true, false])
          if (items.any((item) => item.requiredItem == requiredItem)) ...[
            const SizedBox(height: 8),
            Text(
              requiredItem ? 'Itens obrigatórios' : 'Itens recomendados',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            for (final item in items.where(
              (item) => item.requiredItem == requiredItem,
            ))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  requiredItem
                      ? Icons.priority_high_rounded
                      : Icons.check_circle_outline,
                ),
                title: Text(item.name),
              ),
          ],
      ],
    );
  }
}
