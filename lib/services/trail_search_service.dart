import '../models/trail.dart';
import 'api_client.dart';

class TrailSearchResult {
  const TrailSearchResult(this.trail, this.distanceKm);
  final Trail trail;
  final double? distanceKm;
}

class TrailSearchPage {
  const TrailSearchPage(this.items, this.total, this.nextPage);
  final List<TrailSearchResult> items;
  final int total;
  final int? nextPage;
}

class TrailSearchService {
  TrailSearchService({ApiClient? api}) : api = api ?? ApiClient.instance;
  final ApiClient api;

  Future<TrailSearchPage> search(
    Map<String, String> filters, {
    int page = 1,
  }) async {
    final json = Map<String, dynamic>.from(
      await api.get(
            '/api/trilhas/busca',
            queryParameters: {...filters, 'pagina': '$page', 'tamanho': '30'},
          )
          as Map,
    );
    return TrailSearchPage(
      (json['itens'] as List).map((raw) {
        final row = Map<String, dynamic>.from(raw as Map);
        return TrailSearchResult(
          Trail.fromJson(row),
          (row['distancia_usuario_km'] as num?)?.toDouble(),
        );
      }).toList(),
      json['total'] as int,
      json['proxima_pagina'] as int?,
    );
  }
}
