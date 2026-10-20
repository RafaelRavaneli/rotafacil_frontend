# Checkpoint: finalização de saídas e navegação de volta

## Finalização

A API recebe o identificador da saída, inclusive identificadores antigos com prefixo `legacy-`, e a data no formato AAAA-MM-DD. O backend normaliza datas com horário de clientes anteriores.

Reservas antigas sem `id_data` podem ser associadas à saída pelo dia apenas quando não há duas saídas nesse dia. Reservas com identificador são finalizadas exclusivamente pela saída correspondente. Reservas canceladas e de outras saídas permanecem inalteradas.

Backend: commit `b97e12f`. Frontend: commit `2e4b8e0`.

## Navegação compartilhada

`AppRoutes.back` e `AppBackButton` preservam a pilha existente e respeitam `PopScope`. Quando não há histórico, substituem a tela por um destino válido.

Aplicado em inscritos, formulário de roteiro (inclusive após salvar), detalhes de roteiro e reserva, busca, perfil do guia, documentos profissionais, notificações, ajuda, privacidade e edição de perfil. Convites usam o mesmo botão. A aba principal de guias da agência não ganha um botão de volta desnecessário.

Destinos sem histórico: gestão de roteiro volta a `/roteiros`; reserva volta a `/reservas` para turistas e `/agenda` para operadores; configurações voltam a `/perfil`; demais detalhes usam a página inicial do perfil. O aviso para descartar alterações do perfil permanece ativo. Botões de fechar diálogos e seletores continuam fechando somente a janela correspondente.

## Validação

- 80 testes do frontend passaram; 2 testes já estavam ignorados.
- 78 testes do backend passaram.
- Testes específicos cobrem datas antigas, identificador legacy, separação de saídas no mesmo dia, volta sem histórico por perfil, preservação da tela anterior e bloqueio por dados não salvos.

Alterações locais. Publicação pendente.
