import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'trail.dart';

class PackingItem {
  const PackingItem({
    required this.id,
    required this.name,
    required this.requiredItem,
    required this.checked,
  });
  final String id;
  final String name;
  final bool requiredItem;
  final bool checked;
}

class PackingChecklist {
  const PackingChecklist({required this.items, required this.editable});
  final List<PackingItem> items;
  final bool editable;
  int get prepared => items.where((item) => item.checked).length;
  int get requiredRemaining =>
      items.where((item) => item.requiredItem && !item.checked).length;

  static String itemId(String name) => sha256
      .convert(
        utf8.encode(name.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase()),
      )
      .toString();

  factory PackingChecklist.fromJson(Map<String, dynamic> json) {
    if (json['itens'] is! List || json['editavel'] is! bool) {
      throw const FormatException('Resposta inválida do checklist.');
    }
    return PackingChecklist(
      editable: json['editavel'] == true,
      items: [
        for (final item in json['itens'] as List)
          PackingItem(
            id: item['id'] as String,
            name: item['nome'] as String,
            requiredItem: item['obrigatorio'] == true,
            checked: item['marcado'] == true,
          ),
      ],
    );
  }

  factory PackingChecklist.fromTrail(
    Trail trail, {
    Map<String, dynamic> checked = const {},
    bool editable = false,
  }) {
    final items = <PackingItem>[];
    final seen = <String>{};
    for (final requiredItem in [true, false]) {
      for (final rawName
          in requiredItem ? trail.requiredItems : trail.recommendedItems) {
        final name = rawName.trim().replaceAll(RegExp(r'\s+'), ' ');
        final id = itemId(name);
        if (name.isEmpty || !seen.add(id)) continue;
        items.add(
          PackingItem(
            id: id,
            name: name,
            requiredItem: requiredItem,
            checked: checked[id] == true,
          ),
        );
      }
    }
    return PackingChecklist(items: items, editable: editable);
  }
}
