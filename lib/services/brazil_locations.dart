import 'dart:convert';
import 'package:flutter/services.dart';

class BrazilState {
  const BrazilState(this.uf, this.name, this.cities);
  final String uf;
  final String name;
  final List<String> cities;
}

class BrazilLocations {
  static Future<List<BrazilState>>? _loaded;
  static Future<List<BrazilState>> load() => _loaded ??= _load();

  static Future<List<BrazilState>> _load() async {
    try {
      final data =
          jsonDecode(
                await rootBundle.loadString(
                  'assets/data/brazil_locations.json',
                ),
              )
              as Map<String, dynamic>;
      return (data['states'] as List)
          .map(
            (s) => BrazilState(
              s['uf'] as String,
              s['name'] as String,
              List<String>.from(s['cities'] as List),
            ),
          )
          .toList();
    } catch (_) {
      _loaded = null;
      rethrow;
    }
  }

  static String normalize(String value) {
    const from = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const to = 'aaaaaeeeeiiiiooooouuuuc';
    var text = value.trim().toLowerCase();
    for (var i = 0; i < from.length; i++) {
      text = text.replaceAll(from[i], to[i]);
    }
    return text;
  }

  static BrazilState? findState(List<BrazilState> states, String value) {
    final query = normalize(value);
    for (final state in states) {
      if (normalize(state.uf) == query || normalize(state.name) == query) {
        return state;
      }
    }
    return null;
  }
}
