import 'package:flutter/foundation.dart';

/// Áreas de dados do [AppStore]. Cada tela escuta só as áreas que usa, em vez
/// de reconstruir a cada mudança de qualquer dado do aplicativo.
enum StoreArea {
  /// Dados do usuário logado (turista, guia ou agência).
  profile,

  /// Catálogo de roteiros.
  trails,

  /// Reservas e o resumo do painel do operador.
  bookings,

  /// Roteiros favoritos.
  favorites,

  /// Central de notificações.
  notifications,

  /// Preferências do dispositivo (avisos, visibilidade do perfil).
  settings,

  /// Guias vinculados à agência.
  guides,
}

class _AreaNotifier extends ChangeNotifier {
  void bump() => notifyListeners();
}

/// Canais de notificação por área para um store baseado em [ChangeNotifier].
///
/// - `watch(StoreArea.favorites)` devolve um [Listenable] que só dispara quando
///   os favoritos mudam. Use em `AnimatedBuilder`/`ListenableBuilder`.
/// - Quem escuta o store inteiro (`animation: store`) continua recebendo todas
///   as mudanças, como antes. A migração das telas pode ser gradual.
mixin StoreAreas on ChangeNotifier {
  final Map<StoreArea, _AreaNotifier> _areaNotifiers = {
    for (final area in StoreArea.values) area: _AreaNotifier(),
  };
  final Map<int, Listenable> _mergedCache = {};

  /// [Listenable] que dispara quando qualquer uma das áreas informadas muda.
  /// O mesmo conjunto de áreas devolve sempre o mesmo objeto, então pode ser
  /// chamado dentro do `build` sem recriar a inscrição.
  Listenable watch(
    StoreArea first, [
    StoreArea? second,
    StoreArea? third,
    StoreArea? fourth,
  ]) {
    final areas = <StoreArea>{first, ?second, ?third, ?fourth};
    if (areas.length == 1) return _areaNotifiers[first]!;
    final key = areas.fold<int>(0, (mask, area) => mask | (1 << area.index));
    return _mergedCache.putIfAbsent(
      key,
      () => Listenable.merge([for (final area in areas) _areaNotifiers[area]!]),
    );
  }

  /// Avisa só as áreas que mudaram (e quem escuta o store inteiro).
  @protected
  void notifyAreas(Set<StoreArea> areas) {
    if (areas.isEmpty) return;
    for (final area in areas) {
      _areaNotifiers[area]!.bump();
    }
    super.notifyListeners();
  }

  /// Mudança sem área definida: avisa todas. É o comportamento antigo e o
  /// padrão seguro para trechos ainda não classificados.
  @override
  void notifyListeners() => notifyAreas(StoreArea.values.toSet());
}
