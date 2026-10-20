import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class LegalDocuments {
  static Map<String, dynamic>? _documents;
  static Future<Map<String, dynamic>> load() =>
      _documents == null ? _load() : SynchronousFuture(_documents!);
  static Future<Map<String, dynamic>> _load() async {
    final documents = Map<String, dynamic>.from(
      jsonDecode(
            await rootBundle.loadString('assets/data/legal_documents.json'),
          )
          as Map,
    );
    _documents = documents;
    return documents;
  }

  static Future<Map<String, dynamic>> acceptance() async {
    final documents = await load();
    return {
      'aceite_termos': true,
      'ciencia_privacidade': true,
      'termos_versao': documents['termos']['version'],
      'privacidade_versao': documents['privacidade']['version'],
    };
  }
}
