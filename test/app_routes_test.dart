import 'package:flutter_test/flutter_test.dart';
import 'package:rotafacil/navigation/app_routes.dart';

void main() {
  test('URL interna seleciona aba correta para cada perfil', () {
    expect(AppRoutes.tabIndex('/favoritos', 'turista'), 1);
    expect(AppRoutes.tabIndex('/reservas', 'usuario'), 2);
    expect(AppRoutes.tabIndex('/agenda', 'guia'), 2);
    expect(AppRoutes.tabIndex('/guias', 'agencia'), 2);
    expect(AppRoutes.tabIndex('/agenda', 'agencia'), 3);
    expect(AppRoutes.tabIndex('/perfil', 'agencia'), 4);
  });

  test('URL desconhecida volta para aba inicial sem perder perfil', () {
    expect(AppRoutes.tabIndex('/nao-existe', 'turista'), 0);
    expect(AppRoutes.homeForRole('guia'), '/painel');
    expect(AppRoutes.homeForRole('agencia'), '/painel');
  });

  test('URLs de detalhes preservam identificadores especiais', () {
    expect(AppRoutes.trail('rota 1'), '/roteiro/rota%201');
    expect(AppRoutes.booking('reserva/1'), '/reserva/reserva%2F1');
    expect(AppRoutes.editTrail('rota 1'), '/roteiros/rota%201/editar');
  });
}
