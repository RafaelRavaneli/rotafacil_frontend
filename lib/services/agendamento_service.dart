import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AgendamentoService {
  static const String _chaveAgendamentos = 'agendamentos';

  static Future<List<Map<String, String>>> listarAgendamentos() async {
    final prefs = await SharedPreferences.getInstance();

    final dados = prefs.getString(_chaveAgendamentos);

    if (dados == null || dados.isEmpty) {
      return [];
    }

    final listaDecodificada = jsonDecode(dados) as List;

    return listaDecodificada
        .map(
          (item) => Map<String, String>.from(item),
        )
        .toList();
  }

  static Future<bool> adicionarAgendamento({
    required String trilha,
    required String cidade,
    required String estado,
    required String data,
    required String dificuldade,
    required String pontoEncontro,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final agendamentos = await listarAgendamentos();

    final jaExiste = agendamentos.any(
      (item) =>
          item['trilha'] == trilha &&
          item['data'] == data,
    );

    if (jaExiste) {
      return false;
    }

    agendamentos.add({
      'trilha': trilha,
      'cidade': cidade,
      'estado': estado,
      'data': data,
      'dificuldade': dificuldade,
      'pontoEncontro': pontoEncontro,
      'status': 'Confirmado',
    });

    await prefs.setString(
      _chaveAgendamentos,
      jsonEncode(agendamentos),
    );

    return true;
  }

  static Future<void> removerAgendamento({
    required String trilha,
    required String data,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final agendamentos = await listarAgendamentos();

    agendamentos.removeWhere(
      (item) =>
          item['trilha'] == trilha &&
          item['data'] == data,
    );

    await prefs.setString(
      _chaveAgendamentos,
      jsonEncode(agendamentos),
    );
  }
}